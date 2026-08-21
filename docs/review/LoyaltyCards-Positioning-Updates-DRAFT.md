# LoyaltyCards — Suggested Positioning & Listing Copy Updates

**DRAFT — for review on the Mac, not yet applied to App Store Connect or the repo**

> **Why these changes:** the competitive assessment found that LoyaltyCards' stamp-card mechanic is conventional (as it should be), but its architecture — no backend at all, zero personal data, selectable Express/Secure trust model, serverless key backup — is genuinely uncommon. The current listing copy (v2.1.1+29) already gestures at privacy but leads with convenience ("no signup"). These drafts push harder on the architecture claim itself ("no server exists"), which is the stronger, harder-to-copy claim.

## How to use this document

- These are drafts only — nothing has been changed in App Store Connect or in `docs/deployment/`.
- When back on the Mac, review each suggestion against `docs/deployment/APP_STORE_METADATA_PACKET_v2_1_1_29.md` (the current live copy) and, if you want to proceed, create the next versioned packet file following the existing naming convention.
- All suggested strings are within Apple's stated character limits (counts shown after each).
- Nothing here changes behaviour, pricing, or the Age Rating / Review Notes sections — only subtitle, promotional text, keywords, and description copy.

---

## Customer App — LoyaltyCards Customer Wallet

### Subtitle (30 chars max)

- **Current:** No signup, just stamps *(22 chars)*
- **Suggested:** No server. No data. Ever. *(26 chars)*

*Current subtitle sells convenience, which every wallet-pass competitor also claims. The suggested version sells the architecture — the claim competitors can't easily copy.*

### Promotional Text (170 chars max)

- **Current:** Free companion app for LoyaltyCards Business. Scan a shop's code to collect digital stamps - no signup, nothing stored, works offline. *(134 chars)*
- **Suggested:** Free companion app for LoyaltyCards Business. Scan a shop's code to collect stamps - no account, no cloud, nothing to breach. Runs fully offline, on your device only. *(166 chars)*

*"Nothing to breach" reframes privacy from a policy promise ("nothing stored") to a structural fact (there is no server to breach).*

### Keywords (100 chars max) — no change recommended

Current: `loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card` *(97 chars)*

*Already covers privacy and offline within 3 characters of the limit; not worth trimming another term to squeeze in "no account" or "serverless" — low search-volume trade for a real keyword lost.*

### Description — suggested addition

Keep the existing description as-is; insert one new section after "HOW IT WORKS" and before "WHO IT'S FOR":

> **WHY THIS ISN'T LIKE OTHER LOYALTY APPS**
>
> Most loyalty apps still run on a company's server somewhere - even the ones that don't ask you to sign up. LoyaltyCards doesn't have a server. Your stamp cards are created and updated only when your phone talks directly to the shop's device over a scanned QR code. There's no database to breach, no account to hack, and nothing about your visits to piece together - because none of it exists anywhere but your phone.

*Rationale: this is the single strongest, least-copyable claim from the assessment. It belongs in the body of the listing, not just the Promotional Text, since App Store search weighting favours the description for long-tail privacy-related queries.*

---

## Supplier App — LoyaltyCards Business

### Subtitle (30 chars max)

- **Current:** Free loyalty program for shops *(30 chars)*
- **Suggested:** No server, no fees, no data *(27 chars)*

*Current subtitle is accurate but generic ("free loyalty program" describes half the App Store). The suggestion states the three concrete things a shop owner is actually deciding between when comparing platforms.*

### Promotional Text (170 chars max) — no change recommended

*Current already leads with "no fees, no accounts" and names the two-app model clearly — it's doing the right job. Leave as-is.*

### Keywords (100 chars max) — suggested swap

- **Current:** `loyalty program,small business,coffee shop,rewards,stamps,qr code,point of sale,customer retention` *(98 chars)*
- **Suggested:** `loyalty program,small business,coffee shop,rewards,stamps,qr code,gdpr,no data,customer retention` *(97 chars)*

*Swaps "point of sale" (not really what the app is, and a crowded term dominated by POS hardware/software brands) for "gdpr" and "no data" - directly targets the GDPR-conscious EU small-business owner the assessment flagged as the strongest-fit customer.*

### Description — suggested addition

Insert one new section after "MULTI-DEVICE SUPPORT" and before "PRIVACY":

> **WHY NO BACKEND MATTERS**
>
> Most digital loyalty platforms store your customer list on their servers - which means their data breach becomes your data breach, and their pricing becomes your ongoing cost. LoyaltyCards Business has no server, so there's no customer database to protect, lose, or pay to maintain. If you're subject to GDPR or just don't want the liability, there's simply nothing to secure - because nothing customer-identifying is ever collected.

*Rationale: makes the GDPR-by-design claim concrete for a business owner evaluating platforms, rather than leaving it implicit in the existing "no customer data collected" bullet.*

---

## Not recommended to change

- App Review Notes — these are functional, not marketing copy; no changes needed.
- Category, pricing, Age Rating, copyright line — all confirmed and unrelated to this positioning question.
- The Express/Secure Mode explanation in both descriptions — already clear and accurate; the assessment's point is to make sure this dual-mode choice is visible at all (it is), not to rewrite it.

## Suggested next step on the Mac

If these land well on review, the natural place to apply them is a new `docs/deployment/APP_STORE_METADATA_PACKET_v2_1_1_30.md` (or next version), following the same "supersedes" pattern already used for prior packets - copy-editing only, no version/build bump required unless App Store Connect requires one for metadata-only changes.
