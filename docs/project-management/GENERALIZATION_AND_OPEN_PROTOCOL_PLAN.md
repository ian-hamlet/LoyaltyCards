# LoyaltyCards — Generalization & Open Protocol Plan

**Source:** combined from `docs/review/LoyaltyCards-Generalization-Ideas.md` and `docs/review/LoyaltyCards-Open-Exchange-Protocol.md`, 2026-08-21. Both documents cover the same underlying direction - widening the app's P2P signed-claim primitive beyond "stamps" - so they're merged here: Part A is the broader idea set (what to build and why, ranked by mission fit), Part B is a deeper technical design for two of those ideas (the open spec and multi-business "zones") grounded directly in current code.

## The driver, stated plainly

This isn't a growth-stage product decision — it's a mission constraint, and it should be treated as one when any of the ideas below get evaluated later:

- The point of the app is to be **an enabler for small, independent shops** — the kind that currently only have physical punch cards (a real, present gap: "my own local has card versions but I lack a physical wallet").
- Small/independent shops need **help, not more cost**. Every existing competitor in this space (see `docs/marketing/COMPETITIVE_ASSESSMENT_2026-08-21.md`) solves the loyalty-card problem by charging the shop a monthly fee.
- There's no income motive here — this is being given away.
- The one thing that must not happen: **a backend server**, because a server is a recurring cost that exists the moment it's switched on, whether or not anyone is using it. That's the opposite of "give something away using spare time."

**Litmus test for every idea below and every future idea:** *does this require anything to run continuously, anywhere, that costs money regardless of usage?* If yes, it's out of scope, no matter how useful — that was the conclusion on Apple Wallet integration (requires a web service + APNs + device registration to update a pass), and it applies just as hard here. Everything below was chosen because it stays on-device and P2P, exactly like the existing stamp-card mechanism.

---

# Part A — Generalizing the Customer App as a P2P Wallet

## Why generalize at all

The current architecture already generalizes further than "stamps," even though it's only used for stamps today. The actual primitive is: **two devices exchange a signed, timestamped claim over a QR code, verified locally, with no server and no identity involved.** That's a wallet for *any* small, verifiable claim a shop wants to hand a customer — stamps are just the first use of it.

Widening what the app *does* with that primitive is also how it stops being a two-app niche product and starts being useful to a shop and a customer on day one, before either side has heard of "LoyaltyCards."

## Ideas, ranked by how directly they serve the mission

### 1. Standalone barcode/card storage mode — solves the actual adoption barrier

Let the Customer app also store a scanned copy of an **existing** physical loyalty card (barcode), the way Stocard or Kard do — no business-side app required.

- **Directly answers the stated gap:** "my own local has card versions but I lack a physical wallet" — this makes the app useful for *that* shop today, with zero cooperation needed from them.
- **Zero recurring cost:** pure local storage, identical to how cards are already stored.
- **Solves the cold-start problem:** today, nobody has a reason to install the Customer app until a shop they visit has already installed the Supplier app. A standalone wallet mode gives it value immediately, and a shop that later adopts the full Supplier app just makes an existing card in the wallet "smarter" (gains real stamps, crypto verification) rather than requiring a second install.

### 2. Generalize the signed payload from "stamp count" to a generic claim

The signed token is already `{business_id, count, timestamp, hash_chain, signature}`. Adding a `claim_type` field lets the same already-built, already-tested signing and verification logic cover:

- Digital vouchers / one-time discount codes
- Simple check-ins (a class, a community event, a co-op meeting)
- Proof-of-visit / digital receipts

- **Zero recurring cost:** no new infrastructure — this is a data-model and UI change on top of cryptography that already exists and is already tested.
- **Serves the mission directly:** a corner shop that doesn't want a "loyalty programme" as such might still want a free way to hand out a one-off discount voucher or track a simple sign-in sheet digitally. Same free tool, more reasons for a small business to bother installing it.

### 3. Publish the QR token format as a small, open, documented spec

Instead of the format being implicitly private to your two apps, write down the payload schema and signature scheme as a short public document (could live as a page on the existing static site, which already costs nothing extra to host).

- **Zero recurring cost:** publishing a document isn't a service — nothing runs, nothing is called, nothing needs uptime.
- **Multiplies the "give it away" act:** anyone — a till/EPOS vendor, another hobbyist developer, a local council digital-inclusion project — could implement a compatible issuer or reader without needing anything from you. This is the version of "give something away" that scales past your own spare time, because it doesn't require you to personally build every integration.
- **See Part B below** for a concrete technical design of this spec.

### 4. Rewarded referrals, reusing the existing Sharing feature

"Tell a Business" / "Tell a Friend" already exist. Generalizing #2 means a referral becomes just another claim type: a shop can optionally issue a small reward (e.g. +1 stamp) to both people on a successful introduction.

- **Zero recurring cost:** entirely reuses the existing sharing UI and the generalized claim mechanism above.
- **Helps adoption without paid marketing:** independent shops competing with chains usually can't afford referral/marketing tooling either — this gives them a free one.

### 5. Shared/consortium cards for a market, high street, or co-op

Multiple small businesses (a market, a BID, a group of independent shops that already informally cross-refer customers) share one verifying key, so a single card accumulates stamps across several physical outlets that all trust that key.

- **Zero recurring cost:** still pure P2P — the "sharing" is just multiple Supplier-app installs configured with the same key, not a shared server.
- **Note, not a cost concern but a real one:** this needs a bit of manual coordination (agreeing and distributing the shared key, deciding how redemption/cost-sharing works between shops) — a people problem, not an infrastructure one, so it doesn't conflict with the zero-cost principle, but it's more setup friction than the other ideas and probably a later-stage addition once the basics are proven.
- **See Part B below** for why "just share a key" is actually the wrong mechanism, and what to use instead.

## One idea to explicitly rule out

**Stored monetary value (gift cards / store credit).** Flagged in the earlier discussion and worth recording clearly here: this looks like a natural extension but isn't compatible with the founding constraint. A signed voucher for "a free coffee" is low-stakes if forged or double-spent — a shop absorbs the occasional loss. A signed token representing *money* is a different risk entirely: without a shared ledger, nothing stops the same voucher being redeemed twice at two different tills before either one knows about the other. Solving that properly needs a real-time shared source of truth — i.e. a backend — which is precisely the recurring cost this whole project exists to avoid. **Leave this out**, not because it's technically hard, but because solving it properly would compromise the one principle that makes the project free to run.

## Suggested order to actually build these

If any of this moves from "idea" to "project plan," the standalone barcode mode (#1) is the one with an argument for going first — it's the one aimed squarely at the original motivation (the local shop with only a physical card), and it removes the two-sided adoption barrier that everything else still assumes is solved. The generic claim-type change (#2) is the cheapest to build since it reuses tested crypto code rather than adding new logic, and unlocks #4 as a near-free follow-on. The open spec (#3) and consortium cards (#5) are best treated as later-stage, once the core app has proven itself with real independent shops.

---

# Part B — Toward an Open, Two-Tier Exchange Protocol

Two related generalizations, both grounded in the actual current code (`source/shared/lib/models/qr_tokens.dart`, `business.dart`, `supplier_config_backup.dart`, `utils/crypto_utils.dart`, `utils/signature_format.dart`) - a deeper technical treatment of ideas #3 and #5 above:

1. **Two-tier trust** — the current "clone to a trusted device" mechanism is single-tenant (one owner, many devices, one shared private key). A "business zone" (idea #5 above) needs a genuinely different, second tier of trust, not more of the same mechanism.
2. **A fixed, publishable exchange format** (idea #3 above) — the current QR payload format works, but several of its choices are implicit/homegrown rather than documented standards, which is fine with one implementer and a real barrier to a second one.

Both stay inside the founding constraint above: no recurring cost, nothing that needs to run continuously. Everything below is either a document (a spec) or a data-model change — no server, ever.

## B1 — What the current model actually is

`Business` = one ECDSA P-256 keypair (`id`, `publicKey`, `privateKey`). `SupplierConfigBackup.createCloneQR` copies `privateKey` verbatim into a backup, integrity-checked with an HMAC key *derived from that same private key* (HKDF over the private key bytes). This is a good design for its actual purpose — proving "this backup was made by whoever holds the real private key," so an owner can safely move their own identity between their own devices.

It has no concept of a second party. There is exactly one key per `businessId`, and identity *is* possession of that key. That's why naively "sharing a scheme" across independent shops today (idea #5) would mean literally handing them all the same private key — which collapses accountability (any member can mint unlimited stamps for the whole group, indistinguishably) and makes removing a bad actor require regenerating and redistributing a new key to every innocent remaining member.

## B2 — A second trust tier: zone membership certificates

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

## B3 — Fixing the generic exchange for outside implementers

The current format works perfectly well — it's only ever been read by code from this same repository. Opening it up means replacing a few homegrown choices with boring, standard ones, so a developer with an off-the-shelf ECDSA library in any language can implement it without archaeology.

### What's implicit today, and the standard replacement

| Today (homegrown) | Found in | Standard replacement |
|---|---|---|
| Public key = custom `[xLen 4B][xBytes][yLen 4B][yBytes]`, base64 | `CryptoUtils.decodePublicKey` | SEC1 uncompressed point (`0x04 \|\| X \|\| Y`) or SPKI/DER, base64url |
| Signature = custom `[rLen 4B][rBytes][sLen 4B][sBytes]`, base64 | `CryptoUtils.verifySignature` | DER `ECDSA-Sig-Value` **or** fixed-width raw `r‖s` (IEEE P1363), base64url — either is fine, just needs to be picked and documented |
| Signed data = hand-built colon-joined string, e.g. `cardId:stampNumber:timestampMs:previousHash:stampCount:expiryDate:scanInterval` | `SignatureFormat.stampChainData` | Canonical JSON (RFC 8785 JSON Canonicalization Scheme) over an explicit field list — removes any ambiguity about delimiters or field order, and is exactly what caused the V-010/V-011 signed-field omission bugs in the first place |
| No envelope-level version field (versioning is per-field, via nullable-and-defaulted properties) | `qr_tokens.dart` throughout | Explicit `"specVersion": "1.0"` on every token, with a documented rule: unknown fields are ignored, unknown `specVersion` majors are rejected with a clear "unsupported version" error rather than silently misparsed |
| Token type registry is an implicit `switch` (`card_issue`, `card_stamp_request`, `stamp_token`, `redemption_request`, `redemption_token`) with an already-graceful `default: return null` | `QRToken.fromQRString` | Formalize as a documented, open registry — new types (e.g. `zone_membership_certificate` from B2 above, or the generic claim types from Part A idea #2) can be added without breaking old readers, exactly because the fallback is already "ignore, don't crash" |
| Transport encoding differs by token (plain JSON for most tokens, gzip + Base45 + QR alphanumeric mode for the bulkier redemption QR via `RedemptionQrCodec`) | `redemption_qr_codec.dart`, `alphanumeric_qr.dart`, `base45.dart` | One documented rule for every token: canonical JSON payload → gzip if over N bytes → Base45 → QR alphanumeric mode. Removes the need for an implementer to guess which encoding a given `type` uses |

### Skeleton of a minimal spec document

A first version doesn't need to be long — mostly writing down what's already true and closing the ambiguous edges:

1. **Identity** — what a business/issuer is (a P-256 keypair + a businessId), and the explicit trust model already in effect: trust-on-first-scan of the public key embedded in a `card_issue` token, with no external validation. Worth stating outright rather than leaving implicit, so a third-party implementer doesn't accidentally "fix" it into something weaker or stronger without realizing it's a deliberate choice.
2. **Envelope** — `specVersion`, `type`, `timestamp`, and the forward-compatibility rule (unknown fields ignored; unknown type or unsupported major version rejected cleanly).
3. **Type registry** — one section per token type, each with its required/optional fields and its exact signing input, in canonical JSON form.
4. **Crypto primitives** — curve (P-256), hash (SHA-256), and the two standard encodings chosen above for keys and signatures.
5. **Transport** — the one documented QR encoding rule for every token type.
6. **Extensions** — how the zone membership certificate (B2) and any future generalized claim types (Part A idea #2) attach to existing tokens without breaking a reader that doesn't understand them.

## B4 — What stays exactly as it is

Nothing here changes how a single independent shop uses the app today. A business with no zone certificate behaves identically to now. The standardized encodings are a like-for-like swap (same curve, same hash, same trust decisions) — just written down and expressed in formats a stranger's code can parse, rather than formats that happen to work because one team wrote both ends. No server is introduced anywhere in this document.

## Suggested next step

Treat B3 as a v2 wire-format proposal: write the actual spec document (the B3 skeleton) against the *current* field set first — that alone is valuable even with only your own two apps as implementers, since it's what future-you (or a contributor) checks a change against instead of re-deriving intent from scattered code comments (`V-010`, `V-011`, `TEST-016` through `TEST-022`) the way it has to be done today. The zone certificate (B2) is a genuinely new capability and probably belongs as a second, separate pass once the base spec is solid. Both are lower-priority than the Part A ideas ranked #1-#2 above, which touch real users sooner.
