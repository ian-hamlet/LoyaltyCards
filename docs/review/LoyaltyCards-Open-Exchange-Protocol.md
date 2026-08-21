# LoyaltyCards — Toward an Open, Two-Tier Exchange Protocol

*Captured 21 August 2026 — for later review and inclusion in the project plan*

## Context

Two related generalizations, both grounded in the actual current code (`source/shared/lib/models/qr_tokens.dart`, `business.dart`, `supplier_config_backup.dart`, `utils/crypto_utils.dart`, `utils/signature_format.dart`):

1. **Two-tier trust** — the current "clone to a trusted device" mechanism is single-tenant (one owner, many devices, one shared private key). A "business zone" — several independently-owned shops sharing a scheme — needs a genuinely different, second tier of trust, not more of the same mechanism.
2. **A fixed, publishable exchange format** — the current QR payload format works, but several of its choices are implicit/homegrown rather than documented standards, which is fine with one implementer and a real barrier to a second one.

Both stay inside the founding constraint from the earlier project-plan note: no recurring cost, nothing that needs to run continuously. Everything below is either a document (a spec) or a data-model change — no server, ever.

---

## Part 1 — What the current model actually is

`Business` = one ECDSA P-256 keypair (`id`, `publicKey`, `privateKey`). `SupplierConfigBackup.createCloneQR` copies `privateKey` verbatim into a backup, integrity-checked with an HMAC key *derived from that same private key* (HKDF over the private key bytes). This is a good design for its actual purpose — proving "this backup was made by whoever holds the real private key," so an owner can safely move their own identity between their own devices.

It has no concept of a second party. There is exactly one key per `businessId`, and identity *is* possession of that key. That's why naively "sharing a scheme" across independent shops today would mean literally handing them all the same private key — which collapses accountability (any member can mint unlimited stamps for the whole group, indistinguishably) and makes removing a bad actor require regenerating and redistributing a new key to every innocent remaining member.

## Part 2 — A second trust tier: zone membership certificates

The standard, well-understood fix for "prove this party is vouched for by an authority, without asking the authority live" is a delegation certificate — the offline equivalent of a small certificate authority. It adds a second tier on top of the existing one without changing it.

### New identity: the zone

- A zone (a market, a high-street association, a co-op, a shared "loyalty network" of otherwise-unrelated independent shops) generates its own ECDSA keypair once, exactly the way a business does today. This is one extra keypair, held by whoever organizes the zone — not a new kind of infrastructure.

### New claim type: `zone_membership_certificate`

A signed statement from the zone key, vouching for one member business's own (unchanged) keypair:

```
{
  "type": "zone_membership_certificate",
  "specVersion": "1.0",
  "zoneId": "...",
  "zoneName": "...",
  "zonePublicKey": "...",
  "memberBusinessId": "...",
  "memberPublicKey": "...",
  "issuedAt": 1234567890000,
  "expiresAt": 1234567890000,
  "signature": "..."   // zone private key signs everything above
}
```

- The member keeps issuing stamps signed with its **own** key, exactly as today — nothing about a single business's normal operation changes.
- The member's `CardIssueToken` / `StampToken` optionally carries this certificate alongside its own signature.
- A verifier (customer app, or another zone member checking a shared-card redemption) checks **two** signatures instead of one: the stamp against `memberPublicKey` (proves *this shop* issued it), then the certificate against `zonePublicKey` (proves the zone organizer vouched for *this shop*, and that the vouching hasn't expired).

### What this buys

- **Accountability is preserved.** Every stamp is still attributable to the specific shop that issued it — nothing is pooled into one indistinguishable shared identity.
- **Blast radius is contained.** One member behaving badly doesn't expose or invalidate any other member's key.
- **A business can belong to zero, one, or several zones** simultaneously, each represented by its own certificate — a shop's own identity is unaffected either way.
- **No new infrastructure.** Certificates are just another signed JSON blob, distributed the same way everything else is — printed, emailed, embedded in a QR, bundled into existing tokens.

### What this doesn't solve — say so plainly

**Revocation is soft.** There's no live server to ask "is this certificate still valid right now," so a removed member's certificate stays technically valid until its own `expiresAt` lapses — the organizer can refuse to *renew* it, but can't instantly kill it. Mitigate by keeping zone certificates short-lived (e.g. renewed every few weeks via the same channel the organizer already uses to communicate with members) rather than by trying to engineer live revocation — that would reintroduce exactly the server dependency this whole design avoids. This should be documented as a known, accepted property of staying serverless, the same way Express Mode's rate-limit (not cryptography) is already documented as a conscious trade-off rather than a flaw.

---

## Part 3 — Fixing the generic exchange for outside implementers

The current format works perfectly well — it's only ever been read by code from this same repository. Opening it up means replacing a few homegrown choices with boring, standard ones, so a developer with an off-the-shelf ECDSA library in any language can implement it without archaeology.

### What's implicit today, and the standard replacement

| Today (homegrown) | Found in | Standard replacement |
|---|---|---|
| Public key = custom `[xLen 4B][xBytes][yLen 4B][yBytes]`, base64 | `CryptoUtils.decodePublicKey` | SEC1 uncompressed point (`0x04 \|\| X \|\| Y`) or SPKI/DER, base64url |
| Signature = custom `[rLen 4B][rBytes][sLen 4B][sBytes]`, base64 | `CryptoUtils.verifySignature` | DER `ECDSA-Sig-Value` **or** fixed-width raw `r‖s` (IEEE P1363), base64url — either is fine, just needs to be picked and documented |
| Signed data = hand-built colon-joined string, e.g. `cardId:stampNumber:timestampMs:previousHash:stampCount:expiryDate:scanInterval` | `SignatureFormat.stampChainData` | Canonical JSON (RFC 8785 JSON Canonicalization Scheme) over an explicit field list — removes any ambiguity about delimiters or field order, and is exactly what caused the V-010/V-011 signed-field omission bugs in the first place |
| No envelope-level version field (versioning is per-field, via nullable-and-defaulted properties) | `qr_tokens.dart` throughout | Explicit `"specVersion": "1.0"` on every token, with a documented rule: unknown fields are ignored, unknown `specVersion` majors are rejected with a clear "unsupported version" error rather than silently misparsed |
| Token type registry is an implicit `switch` (`card_issue`, `card_stamp_request`, `stamp_token`, `redemption_request`, `redemption_token`) with an already-graceful `default: return null` | `QRToken.fromQRString` | Formalize as a documented, open registry — new types (e.g. `zone_membership_certificate`, or future claim types from the earlier generalization document) can be added without breaking old readers, exactly because the fallback is already "ignore, don't crash" |
| Transport encoding differs by token (plain JSON for most tokens, gzip + Base45 + QR alphanumeric mode for the bulkier redemption QR via `RedemptionQrCodec`) | `redemption_qr_codec.dart`, `alphanumeric_qr.dart`, `base45.dart` | One documented rule for every token: canonical JSON payload → gzip if over N bytes → Base45 → QR alphanumeric mode. Removes the need for an implementer to guess which encoding a given `type` uses |

### Skeleton of a minimal spec document

A first version doesn't need to be long — mostly writing down what's already true and closing the ambiguous edges:

1. **Identity** — what a business/issuer is (a P-256 keypair + a businessId), and the explicit trust model already in effect: trust-on-first-scan of the public key embedded in a `card_issue` token, with no external validation. Worth stating outright rather than leaving implicit, so a third-party implementer doesn't accidentally "fix" it into something weaker or stronger without realizing it's a deliberate choice.
2. **Envelope** — `specVersion`, `type`, `timestamp`, and the forward-compatibility rule (unknown fields ignored; unknown type or unsupported major version rejected cleanly).
3. **Type registry** — one section per token type, each with its required/optional fields and its exact signing input, in canonical JSON form.
4. **Crypto primitives** — curve (P-256), hash (SHA-256), and the two standard encodings chosen above for keys and signatures.
5. **Transport** — the one documented QR encoding rule for every token type.
6. **Extensions** — how the zone membership certificate (Part 2) and any future generalized claim types (see the earlier generalization document) attach to existing tokens without breaking a reader that doesn't understand them.

---

## Part 4 — What stays exactly as it is

Nothing here changes how a single independent shop uses the app today. A business with no zone certificate behaves identically to now. The standardized encodings are a like-for-like swap (same curve, same hash, same trust decisions) — just written down and expressed in formats a stranger's code can parse, rather than formats that happen to work because one team wrote both ends. No server is introduced anywhere in this document.

## Suggested next step

Treat this as a v2 wire-format proposal: write the actual spec document (Part 3's skeleton) against the *current* field set first — that alone is valuable even with only your own two apps as implementers, since it's what future-you (or a contributor) checks a change against instead of re-deriving intent from scattered code comments (`V-010`, `V-011`, `TEST-016` through `TEST-022`) the way it has to be done today. The zone certificate (Part 2) is a genuinely new capability and probably belongs as a second, separate pass once the base spec is solid.
