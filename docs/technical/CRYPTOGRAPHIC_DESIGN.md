# Cryptographic Design: Keys and Signing in Express and Secure Mode

**Last Updated:** 2026-07-25 (post feature/SecurityReview, V-010 through V-016)

---

## Overview

This document explains the actual cryptographic mechanics of LoyaltyCards' dual-mode
system: what key material exists, where it lives, what gets signed, and how that
differs between **Express Mode** (`OperationMode.simple`) and **Secure Mode**
(`OperationMode.secure`).

For the business-facing risk/trust framing (when to choose which mode, accepted
limitations, mitigations), see [SECURITY_MODEL.md](SECURITY_MODEL.md). This document
is the engineering companion: it describes what the code actually does, with file
references, so the two don't drift out of sync with each other or with reality.

**Terminology note:** the code's `OperationMode.simple` enum value displays to users
as "Express Mode" (`OperationModeExtension.displayName`,
`shared/lib/models/operation_mode.dart`). "Simple Mode" and "Express Mode" refer to
the same thing; this doc uses "Express Mode" throughout to match current UI copy.

**A note on "encryption":** despite the common phrase "encrypted QR code," QR
payloads in this app are never encrypted. They're plain JSON, base64/text-encoded,
readable by anyone who scans them. What the cryptography actually provides is
**digital signatures** — proof of authenticity and tamper-evidence, not
confidentiality. The one place real (symmetric, OS-level) encryption-at-rest applies
is private key storage in the device Keychain/Keystore, covered below.

---

## Key material

- Each **business** (supplier) generates a single **ECDSA key pair** on curve
  **P-256** (`ECCurve_secp256r1`), used with **SHA-256** digests, once at onboarding
  — regardless of which mode the business ultimately picks. Generation:
  `KeyManager.generateKeyPair()` (`source/supplier_app/lib/services/key_manager.dart`).
- The **private key** never leaves the supplier's device under normal operation. It's
  stored via `flutter_secure_storage` (iOS Keychain / Android Keystore) with iOS
  accessibility `first_unlock_this_device` — deliberately *not*
  `first_unlock`, so the key cannot migrate via an encrypted iTunes/iCloud device
  backup restore. The one legitimate path for the private key to leave the Keychain
  is the explicit, user-initiated, biometric-gated Recovery Backup / Clone Device QR
  flow (see V-002 in [VULNERABILITIES.md](../quality/VULNERABILITIES.md)).
- The **public key** travels inside the card-issuance QR code
  (`CardIssueToken.publicKey`) and is copied into the customer's local `cards` row
  (`business_public_key` column — see [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)).
  There is no PKI, certificate authority, or server. Trust is established on first
  contact: whichever public key arrives bundled in the QR you scan when adding a
  card is the key used to verify everything from that business from then on.
- **One key pair covers all of a business's cards, in both modes.** Mode is a
  per-card setting, not a key-pair property — a business can hold Express Mode and
  Secure Mode cards simultaneously, signed by the same key.

### Encoding format

Public keys and signatures use a custom, compact binary encoding for QR/JSON
transport:

```
[4-byte big-endian length][bytes] [4-byte big-endian length][bytes]
```

- Public key: `[len(x)][x-coordinate bytes][len(y)][y-coordinate bytes]`, base64-encoded.
- Signature: `[len(r)][r bytes][len(s)][s bytes]`, base64-encoded (standard ECDSA `(r, s)` pair).

Implemented in `KeyManager.encodePublicKey()` / `signData()` (supplier_app, signing
side) and `CryptoUtils._decodePublicKey()` / `verifySignature()`
(`shared/lib/utils/crypto_utils.dart`, verifying side, used by both apps).

---

## What gets signed, by mode

| Event | Express Mode | Secure Mode |
|---|---|---|
| **Card issuance** (business identity, name, branding, public key) | ✅ Signed and verified, always | ✅ Signed and verified, always |
| **Each stamp** | ❌ Not verified — signature field is present but never checked | ✅ Signed by the supplier's private key at scan time, hash-chained to the prior stamp, verified by the customer app on receipt |
| **Redemption** (supplier's proof a reward was granted) | ✅ Signed, always (customer keeps this as proof) | ✅ Signed, *and* the supplier independently re-verifies the entire stamp chain before signing |

Card issuance and redemption are cryptographically signed in **both** modes — that
much is non-negotiable. The mode only changes whether **individual stamps** get
verified.

### Card issuance (`CardIssueToken`)

Signed by `QRTokenGenerator.generateCardIssueToken()`
(`source/supplier_app/lib/services/qr_token_generator.dart`), always, over:

```
businessId:businessName:publicKey:stampsRequired:brandColor:cardId:timestamp:mode
```

(`CardIssueToken.getSignatureData()`, `shared/lib/models/qr_tokens.dart` — this
format is defined directly on the token class, unlike the stamp/redemption formats
below which live in the shared `SignatureFormat` class.)

Verified on the customer side by `TokenValidator.validateCardIssueToken()`
(`source/customer_app/lib/services/token_validator.dart`) in **both** modes — the
only difference is Express Mode tokens skip the 5-minute freshness/expiry check
(since Express Mode issuance QRs are static and reusable, not one-shot).

The `mode` field is itself part of the signed data (V-011 fix): previously it
wasn't, which meant a Secure Mode issuance token's mode field could be edited to
`"simple"` after signing — signature still verifies, but the resulting card
permanently downgrades to skip all future signature/hash-chain checks. Including
`mode` in the signed string closes that.

### Stamps

**Express Mode:** `qr_scanner_screen.dart`'s `_handleStampToken()` branches on
`card.mode` and, for `OperationMode.simple`, skips `TokenValidator.validateStampToken`
entirely — only expiry date and stamp count are checked, never the signature.
Stamp IDs/numbers/timestamps are synthesized client-side (since the QR is static
and reused), and `previousHash` is never populated (`null` — no chain exists).
This matches the design intent: Express Mode has no supplier device present at
each individual stamp event, so there's nothing live to sign.

**Secure Mode:** every stamp requires a fresh QR round-trip with the supplier's
device. `QRTokenGenerator.generateStampToken()` signs:

```
cardId:stampNumber:timestamp:previousHash:stampCount:expiryDate:scanInterval
```

(`SignatureFormat.stampChainData()`, `shared/lib/utils/signature_format.dart` — the
single source of truth for this format, shared between the signing call site above
and the verifying call site, `StampToken.getSignatureData()`). `previousHash` is the
**previous stamp's own signature** — each stamp cryptographically references the one
before it, forming a hash chain. Tampering with, reordering, or deleting a stamp
anywhere in the chain invalidates every stamp signed after it.

`stampCount`/`expiryDate`/`scanInterval` were added in the V-010 fix: previously a
single stamp token's `stampCount` wasn't part of the signed data, so tampering it
post-signing could mint many unverified stamp rows from one genuine scan.

The customer app verifies each stamp's signature and chain position via
`TokenValidator.validateStampToken()` as it's scanned.

### Redemption

Every redemption is signed by the supplier (`SignatureFormat.redemptionTokenData()`
→ `cardId:stampsRedeemed:timestampMs`), in both modes — the customer keeps this
signed `RedemptionToken` as proof the business granted the reward.

The difference is what the supplier checks *before* signing. In Express Mode,
redemption is intentionally honor-based: there are no per-stamp signatures to chain-
verify (Express stamps were never signed to begin with — see above), so the supplier
verifies visually (stamp history timestamps, face-to-face context — see
[SECURITY_MODEL.md](SECURITY_MODEL.md) for the mitigations this relies on).

In Secure Mode, before signing a redemption the supplier calls
`CryptoUtils.verifyRedemptionStampChain()` (`shared/lib/utils/crypto_utils.dart`),
which independently reconstructs and verifies the *entire* stamp chain from the
customer's claimed `stampProofs` (signature + timestamp pairs) against the
business's own public key:

```
for each stamp i (1-indexed):
  data = cardId:i:timestamp:previousHash:1::
  verify(data, stampProofs[i].signature, businessPublicKey)
  previousHash = stampProofs[i].signature   # becomes next iteration's previousHash
```

This is the V-012 fix: previously the redemption flow trusted the customer's
self-reported stamp count outright, with no cryptographic check at all — a
fabricated or replayed redemption request would be signed just as readily as a
genuine one. Now a Secure Mode redemption request that fails chain verification is
rejected outright (`supplier_redeem_card.dart`), and legacy/unsigned redemption
formats are refused for Secure Mode cards rather than silently accepted.

---

## Why this split is intentional, not a gap

Express Mode's lack of per-stamp signing is a deliberate trust/speed trade-off
(documented in depth, with accepted-risk framing, in
[SECURITY_MODEL.md](SECURITY_MODEL.md) as L-001/L-002/L-003) — it digitizes the same
trust model as a physical paper stamp card, where forgery is technically possible but
socially and economically discouraged. Secure Mode exists specifically for the cases
where that trade-off isn't acceptable (high-value rewards, low-trust environments),
and its cryptographic guarantees only hold because *every* stamp is signed and
chained, not just issuance and redemption.

---

## Related documents

- [SECURITY_MODEL.md](SECURITY_MODEL.md) — business-facing risk model, mode
  selection guidance, accepted limitations
- [../quality/VULNERABILITIES.md](../quality/VULNERABILITIES.md) — full
  vulnerability assessment, including V-010 through V-016 (the 2026-07-25 security
  review that hardened the signing formats and added redemption chain verification)
- [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) — `cards.business_public_key`,
  `stamps.signature`, `stamps.previous_hash` column definitions
