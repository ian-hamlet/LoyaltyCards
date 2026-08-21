# App Store Metadata Packet (v2.2.0+30)

**Status: 🔵 IN DEVELOPMENT, 2026-08-22.** Not yet built, uploaded, or submitted. Minor version bump (2.1.1 -> 2.2.0) - the editable scan cooldown is a genuine capability increase, not a build-only or patch change.

**Positioning update applied 2026-08-22** from `docs/marketing/POSITIONING_UPDATE_PLAN_2026-08-21.md` (informed by `docs/marketing/COMPETITIVE_ASSESSMENT_2026-08-21.md`) - Subtitle, Promotional Text, and Description below now lead with the architecture claim ("no server, no data, ever") rather than convenience. See each field below for what changed vs. v2.1.1+29.

Use this file as the single copy/paste source for App Store Connect listing fields.

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_1_1_29.md` (the current live version) for App Store submission purposes.

**Minor version bump (2.1.1+29 -> 2.2.0+30)** - adds the editable scan cooldown feature (Supplier app) and the positioning update described above.

---

## Shared Listing Values

- Release Version: 2.2.0
- Build: 30
- Primary Language: English (UK)
- Privacy Policy URL: https://loyaltycards-site.pages.dev/legal/privacy-policy.html
- Terms of Service URL: https://loyaltycards-site.pages.dev/legal/terms-of-service.html
- Support URL: https://loyaltycards-site.pages.dev/support/
- Accessibility Statement (not an App Store Connect field, linked from the site): https://loyaltycards-site.pages.dev/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: https://loyaltycards-site.pages.dev/user/about.html

**Status:** Unchanged from v2.1.1+29, all confirmed live in ASC. **Note:** these are already the Cloudflare Pages URLs in this document, but ASC's own URL fields still point at the old `ian-hamlet.github.io` host as of v2.1.1+29 - see `docs/project-management/CLOUDFLARE_MIGRATION_COMPLETION_PLAN.md`. Updating ASC's URL fields to match is part of that separate, already-tracked plan - worth doing alongside this release's ASC metadata entry, since it's exactly the "next release" that plan was waiting for.

---

## Customer App (LoyaltyCards Customer Wallet)

### Basic Info
- App Name: LoyaltyCards Customer Wallet
- Bundle ID: com.ianhamlet.loyaltycards.customerApp
- SKU: loyaltycards-customer-2026
- Primary Category: Lifestyle
- Secondary Category: Shopping

### Subtitle (30 chars max)
No server. No data. Ever.

*(was: "No signup, just stamps" — sold convenience, which every wallet-pass competitor also claims; this sells the architecture, the claim competitors can't easily copy)*

### What's New in This Version
Improved reliability of the companion app pairing. (No customer-facing functional change this release - the update is on the Supplier app side; see that app's What's New below.)

### Promotional Text (170 chars max)
Free companion app for LoyaltyCards Business. Scan a shop's code to collect stamps - no account, no cloud, nothing to breach. Runs fully offline, on your device only.

*(was: "...no signup, nothing stored, works offline." — "nothing to breach" reframes privacy from a policy promise to a structural fact: there is no server to breach)*

### Keywords (100 chars max)
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card

*(unchanged — already covers privacy and offline within 3 characters of the limit)*

### Description
LoyaltyCards is the free companion app for shops using LoyaltyCards Business. If a shop you visit uses it, you can collect digital stamp cards on your own phone instead of paper ones.

WHAT TO EXPECT

This isn't a directory or a marketplace - there's nothing to browse. You'll only use this app if a shop you already visit shows you a QR code and asks you to scan it.

HOW IT WORKS

1. A shop shows you a QR code
2. You scan it with LoyaltyCards
3. Collect a stamp each visit
4. Show your completed card to redeem your reward

WHY THIS ISN'T LIKE OTHER LOYALTY APPS

Most loyalty apps still run on a company's server somewhere - even the ones that don't ask you to sign up. LoyaltyCards doesn't have a server. Your stamp cards are created and updated only when your phone talks directly to the shop's device over a scanned QR code. There's no database to breach, no account to hack, and nothing about your visits to piece together - because none of it exists anywhere but your phone.

WHO IT'S FOR

Built with small, independent shops in mind - cafes, salons, and similar businesses that want to run a simple stamp card without paying for a loyalty platform or collecting your data to do it.

Some shops use Express Mode, where you self-serve and the shop simply checks your card before redeeming it. Others use Secure Mode, where each stamp is cryptographically signed and verified by the shop's device. You'll see both in your wallet - no setup needed either way.

PRIVACY

No signup, no email, no phone number, no account, no tracking. Nothing about you is collected or sent anywhere - your cards are stored only on your device and exchanged directly with the shop's device over a scanned QR code.

Run a shop and want to offer this? Get LoyaltyCards Business here: https://apple.co/4hFWKsh

Download LoyaltyCards and start collecting.

### App Review Notes (Customer)
This app is one side of a two-app system and is tested together with LoyaltyCards Business (the Business app issues cards; this app holds them). No login is required on either app, and no backend account exists - all features are offline-capable, since the two apps communicate only via QR code scanned directly between devices.

To review the full flow: install LoyaltyCards Business on a second device or the Simulator, create a test business in Express Mode (fastest to test - no time-limited QR codes involved), issue a card from the Business app, and scan it with this app. Secure Mode exercises the same flow but with cryptographically signed, time-limited QR codes generated per stamp from the Business app.

To review the Sharing feature: Settings → Sharing → tap either "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

This build (v2.2.0+30) has no functional change on the Customer app side - see the Supplier App's App Review Notes below for the one feature this release adds.

---

## Supplier App (LoyaltyCards Business)

### Basic Info
- App Name: LoyaltyCards Business
- Bundle ID: com.ianhamlet.loyaltycards.supplierApp
- SKU: loyaltycards-supplier-2026
- Primary Category: Business
- Secondary Category: Productivity

### Subtitle (30 chars max)
No server, no fees, no data

*(was: "Free loyalty program for shops" — accurate but generic; the new version states the three concrete things a shop owner is actually deciding between when comparing platforms)*

### What's New in This Version
Express Mode's scan cooldown can now be changed after setup, from Settings - previously it could only be set once, during initial business setup.

### Promotional Text (170 chars max)
A free pair of apps that help small shops run a simple digital stamp card - no fees, no accounts. Customers need the companion LoyaltyCards app on their own phone.

*(unchanged — already leads with "no fees, no accounts" and names the two-app model clearly)*

### Keywords (100 chars max)
loyalty program,small business,coffee shop,rewards,stamps,qr code,gdpr,no data,customer retention

*(was: "...point of sale..." — swapped for "gdpr,no data", targeting the GDPR-conscious EU small-business owner the assessment flagged as the strongest-fit customer; "point of sale" wasn't really what the app is and is a crowded term dominated by POS hardware/software brands)*

### Description
LoyaltyCards Business is a free way for small shops to run a digital stamp card, without the cost or complexity of a loyalty platform.

WHY LOYALTYCARDS BUSINESS?

- Free - no subscriptions, no fees, no hidden costs
- No customer data collected - nothing to store, nothing to protect
- Works offline - no internet connection required
- Use on multiple devices - registers, staff phones, whatever you already have

TWO APPS, ONE SYSTEM

This app is for the shop. Customers need the free companion app, LoyaltyCards, on their own phone to hold their cards - there's no shared server or account, each card is created and stamped directly between your device and theirs via QR code. Point your customers here to get it: https://apple.co/4bYdQ0T

CHOOSE YOUR MODE

- Express Mode: show one reusable QR code, customers self-serve in a couple of seconds, and you simply check the card before redeeming it. Best for quick, everyday visits.
- Secure Mode: generate a fresh, cryptographically signed QR code per stamp from your device. Slightly slower, but every stamp is verified. Best for higher-value rewards.

Both work fully offline. You can't switch modes later without a full reset, so choose based on what suits your shop.

MULTI-DEVICE SUPPORT

Back up your configuration with one QR scan and clone it to additional devices, all issuing stamps for the same program.

WHY NO BACKEND MATTERS

Most digital loyalty platforms store your customer list on their servers - which means their data breach becomes your data breach, and their pricing becomes your ongoing cost. LoyaltyCards Business has no server, so there's no customer database to protect, lose, or pay to maintain. If you're subject to GDPR or just don't want the liability, there's simply nothing to secure - because nothing customer-identifying is ever collected.

PRIVACY

No customer emails, phone numbers, or personal data collected - ever.

WHO IT'S FOR

Built with smaller, independent outlets in mind - cafes, salons, and similar shops that want to reward regular customers without paying for a loyalty platform.

Download LoyaltyCards Business and get started.

### App Review Notes (Supplier)
This app is the business side of a two-app system and is reviewed together with LoyaltyCards (customer app) - this app issues and manages cards, the customer app holds them. No login is required on either app, and no backend account exists - all features are offline-capable.

To review the full flow: create a test business (Express Mode is fastest to review - no time-limited QR codes involved), then install LoyaltyCards on a second device or the Simulator to scan the "issue card" and "add stamp" QR codes this app displays. Secure Mode exercises the same flow but generates a freshly signed, time-limited QR code per stamp instead of a static reusable one.

To review the Sharing feature: either tap the person icon in the Home screen's top bar, or go to Settings → Sharing → "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

This build (v2.2.0+30) adds one small feature: Settings now shows the Express Mode scan cooldown (how long a customer must wait between accepted stamp scans) and lets it be changed - previously this could only be set once, during initial business setup. To review: create an Express Mode business, go to Settings, tap "Scan Cooldown," and confirm the value can be adjusted and saved. This doesn't affect the core review flow described above.

---

## Decisions (carried forward, unchanged from v2_0_0_19)

- [x] **Pricing:** both apps Free — confirmed by the developer.
- [x] **Copyright line:** `© 2026 Ian Hamlet`
- [x] **App Review contact phone:** 07968135909
- [x] **Age Rating questionnaire:** all "None", expected 4+ — confirmed entered in ASC 2026-08-15.
- [x] **Release Date:** Manual release, both apps — confirmed set 2026-08-18, should still hold for this release but worth reconfirming in ASC before submitting.
