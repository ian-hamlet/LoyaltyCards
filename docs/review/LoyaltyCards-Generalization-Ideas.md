# LoyaltyCards — Generalizing the Customer App as a P2P Wallet

*Captured 21 August 2026 — for later review and inclusion in the project plan*

## The driver, stated plainly

This isn't a growth-stage product decision — it's a mission constraint, and it should be treated as one when any of the ideas below get evaluated later:

- The point of the app is to be **an enabler for small, independent shops** — the kind that currently only have physical punch cards (a real, present gap: "my own local has card versions but I lack a physical wallet").
- Small/independent shops need **help, not more cost**. Every existing competitor in this space (see the earlier competitive assessment) solves the loyalty-card problem by charging the shop a monthly fee.
- There's no income motive here — this is being given away.
- The one thing that must not happen: **a backend server**, because a server is a recurring cost that exists the moment it's switched on, whether or not anyone is using it. That's the opposite of "give something away using spare time."

**Litmus test for every idea below and every future idea:** *does this require anything to run continuously, anywhere, that costs money regardless of usage?* If yes, it's out of scope, no matter how useful — that was the conclusion on Apple Wallet integration (requires a web service + APNs + device registration to update a pass), and it applies just as hard here. Everything in this document was chosen because it stays on-device and P2P, exactly like the existing stamp-card mechanism.

---

## Why generalize at all

The current architecture already generalizes further than "stamps," even though it's only used for stamps today. The actual primitive is: **two devices exchange a signed, timestamped claim over a QR code, verified locally, with no server and no identity involved.** That's a wallet for *any* small, verifiable claim a shop wants to hand a customer — stamps are just the first use of it.

Widening what the app *does* with that primitive is also how it stops being a two-app niche product and starts being useful to a shop and a customer on day one, before either side has heard of "LoyaltyCards."

---

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

### 4. Rewarded referrals, reusing the existing Sharing feature

"Tell a Business" / "Tell a Friend" already exist. Generalizing #2 means a referral becomes just another claim type: a shop can optionally issue a small reward (e.g. +1 stamp) to both people on a successful introduction.

- **Zero recurring cost:** entirely reuses the existing sharing UI and the generalized claim mechanism above.
- **Helps adoption without paid marketing:** independent shops competing with chains usually can't afford referral/marketing tooling either — this gives them a free one.

### 5. Shared/consortium cards for a market, high street, or co-op

Multiple small businesses (a market, a BID, a group of independent shops that already informally cross-refer customers) share one verifying key, so a single card accumulates stamps across several physical outlets that all trust that key.

- **Zero recurring cost:** still pure P2P — the "sharing" is just multiple Supplier-app installs configured with the same key, not a shared server.
- **Note, not a cost concern but a real one:** this needs a bit of manual coordination (agreeing and distributing the shared key, deciding how redemption/cost-sharing works between shops) — a people problem, not an infrastructure one, so it doesn't conflict with the zero-cost principle, but it's more setup friction than the other ideas and probably a later-stage addition once the basics are proven.

---

## One idea to explicitly rule out

**Stored monetary value (gift cards / store credit).** Flagged in the earlier discussion and worth recording clearly here: this looks like a natural extension but isn't compatible with the founding constraint. A signed voucher for "a free coffee" is low-stakes if forged or double-spent — a shop absorbs the occasional loss. A signed token representing *money* is a different risk entirely: without a shared ledger, nothing stops the same voucher being redeemed twice at two different tills before either one knows about the other. Solving that properly needs a real-time shared source of truth — i.e. a backend — which is precisely the recurring cost this whole project exists to avoid. **Leave this out**, not because it's technically hard, but because solving it properly would compromise the one principle that makes the project free to run.

---

## Suggested order to actually build these

If any of this moves from "idea" to "project plan," the standalone barcode mode (#1) is the one with an argument for going first — it's the one aimed squarely at the original motivation (the local shop with only a physical card), and it removes the two-sided adoption barrier that everything else still assumes is solved. The generic claim-type change (#2) is the cheapest to build since it reuses tested crypto code rather than adding new logic, and unlocks #4 as a near-free follow-on. The open spec (#3) and consortium cards (#5) are best treated as later-stage, once the core app has proven itself with real independent shops.
