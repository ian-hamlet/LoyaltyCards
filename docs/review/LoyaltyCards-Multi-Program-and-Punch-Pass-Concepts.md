# LoyaltyCards — Multi-Program Cards & Negative-Stamp Punch Passes

*Captured 26 August 2026 — for later review and inclusion in the project plan*

Two feature ideas discussed and assessed for feasibility against the current architecture, then deferred. Not implemented. Recorded here so they don't need to be re-derived from scratch next time.

Context for both: this app is fully peer-to-peer and offline — no server, no Firestore. Each Card and Stamp lives as a row in a device-local SQLite database, and stamps move between apps only via cryptographically signed, hash-chained QR tokens (see `docs/technical/DATABASE_SCHEMA.md`, REQ-015). Both ideas were reviewed against that model, not a generic backend one.

---

## Idea 1: Multiple card types per supplier, with typed vs. wildcard stamps

**The idea:** a supplier issues several parallel stamp cards (e.g. "drinks" and "cakes"), and a stamp scan is either generic (goes onto whichever card of that supplier has space) or typed (goes only onto the matching card type).

**Feasibility: medium.** More aligned with the grain of the existing code than expected:

- A customer can already hold multiple cards for the same supplier — not an edge case, it's load-bearing today. The "overflow" mechanism auto-splits stamps across cards for a business (`source/customer_app/lib/controllers/qr_scanner_controller.dart:706-946`).
- Express/Simple Mode stamps are already "generic": they carry a placeholder card id and get routed to whichever card for that `businessId` has space (`qr_scanner_controller.dart:349-374`, `CardRepository.findCardWithSpace()`). That routing-by-businessId is essentially the "wildcard stamp" concept already, in miniature. Extending it to route by `businessId + programId` for typed stamps, or `businessId` alone for wildcard stamps, is a natural generalization of code that already exists.

What it would actually cost:

- `Business` is a hard singleton today — one row per install, fetched with `maps.first`, no `WHERE` clause (`source/supplier_app/lib/services/business_repository.dart:11-17`). Distinct card types means a new `programs` table under the business, and an audit of every call site that assumes exactly one business row.
- Every signed token type (`CardIssueToken`, `StampToken`, `CardStampRequestToken`, redemption tokens — all in `source/shared/lib/models/qr_tokens.dart`) would need a `programId` field, i.e. a signed-format/versioning change.
- QR payload size is already a known constraint in this codebase — the practical stamp ceiling is ~12 despite a configured ceiling of 100, purely from QR capacity (see DEFECT_TRACKER TEST-020/021). Any new field on every token type competes with that same tight budget.

**Bottom line:** a real feature, not a patch, but the stamp-routing semantics you'd want are close to something that already exists. Biggest cost is the singleton-business refactor and token schema/versioning, not the routing logic itself.

---

## Idea 2: Full card as seat-booking credits, redeemed via a "negative stamp" scan

**The idea:** a supplier issues a customer a full card representing prepaid seat/work-space credits; each time the seat is used, staff scan a "negative stamp" that decrements one credit from the card, instead of the usual increment.

**Feasibility: low-to-medium — better framed as a new card mode than an extension of the existing stamp card.** It runs directly against invariants that are enforced on purpose, not gaps that happen to be missing:

- Stamps are stored as a hash-chained, append-only ledger — each stamp's signature incorporates the previous stamp's hash. `CardRepository._validateCard()` actively enforces `stampsCollected >= 0`; non-negativity is an asserted invariant, not an oversight.
- There's no "debit" token anywhere in the token model — every existing token either adds a stamp or confirms redemption of an already-completed card. A negative stamp would be a new signed-token type with no precedent, and it inverts the ascending-sequence assumption baked into `CryptoUtils.verifyRedemptionStampChain`.
- One encouraging precedent: `StampRepository` does have a raw `deleteStamp`, currently used internally only by the overflow-relocation logic (delete-and-reinsert on a different card). So "remove a stamp" isn't unthinkable at the storage layer — but exposing it as a supplier-facing, signed, auditable decrement is real design work, not just wiring up the existing method.
- The bigger issue is semantic: this isn't really a loyalty card (accumulate → redeem → reset) any more, it's a prepaid punch-pass (issue N credits → deplete → renew), with different UX (progress-bar-up vs. balance-counting-down) and different redemption logic. Current redemption requires `stampsCollected >= stampsRequired` and fires once, on completion (`source/supplier_app/lib/controllers/supplier_redeem_card_controller.dart:296`).
- One thing that already helps: REQ-022 multi-denomination stamps let a supplier credit N stamps in a single signed scan — that covers most of "sell someone a 10-visit pass in one scan" for free.

**Bottom line:** worth pursuing eventually, but as a parallel "punch pass" card mode that reuses the existing crypto/signing/QR plumbing, rather than as negative deltas bolted onto the existing stamp card. Retrofitting decrements onto an invariant-enforcing, append-only model is more disruptive than the feature description suggests.

---

## Also noticed in passing

`docs/project-management/Requirements/REQ-012_Card_Redemption_Reset.md` describes a reset-to-zero redemption design that was actually superseded by "mark redeemed + issue new card" (see `CardRepository.markCardAsRedeemed()` and the auto-new-card logic in `qr_scanner_controller.dart:1027-1067`). That doc is stale — unrelated to the two ideas above, but worth a cleanup pass sometime.
