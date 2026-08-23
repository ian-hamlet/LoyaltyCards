# App Store Metadata Packet (v2.2.0+32)

**Status: 🟢 Submitted for App Store review, 2026-08-23.** Both apps built, uploaded to TestFlight, TestFlight-tested, metadata entered from this packet, and submitted for review the same day. Awaiting Apple's decision. **Build-only bump** (2.2.0+31 -> 2.2.0+32) - consolidates v2.2.0+30 and v2.2.0+31 below into the first actual build/submission under the 2.2.0 line (neither +30 nor +31 was ever built or uploaded), plus a round of real-device-found fixes since +31. Since this is the first 2.2.0 build to actually ship, "What's New" below covers everything back to the last live version, v2.1.1+29 - not just the delta since +31.

No positioning changes this release - Subtitle, Promotional Text, Keywords, and Description are unchanged from v2.2.0+30/+31 below. Only "What's New" and the App Review Notes change.

Use this file as the single copy/paste source for App Store Connect listing fields.

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_2_0_30.md` and `APP_STORE_METADATA_PACKET_v2_2_0_31.md` for App Store submission purposes - both were superseded before ever being built.

**Build-only bump (2.2.0+31 -> 2.2.0+32)** - adds a macOS desktop build for the Supplier app (dev/business convenience, not an App Store submission target - no App Store Connect changes result from it), a real-device-found fix for a `stampsRequired` increase not reaching the next card in one completion path, and test-suite quality fixes. See `docs/project-management/DEFECT_TRACKER.md` DECISION-021 and DECISION-022 for the full implementation record.

---

## Shared Listing Values

- Release Version: 2.2.0
- Build: 32
- Primary Language: English (UK)
- Privacy Policy URL: https://loyaltycards-site.pages.dev/legal/privacy-policy.html
- Terms of Service URL: https://loyaltycards-site.pages.dev/legal/terms-of-service.html
- Support URL: https://loyaltycards-site.pages.dev/support/
- Accessibility Statement (not an App Store Connect field, linked from the site): https://loyaltycards-site.pages.dev/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: https://loyaltycards-site.pages.dev/user/about.html

**Status:** Unchanged from v2.2.0+30/+31. ⚠️ Per `APP_STORE_SUBMISSION_CHECKLIST.md`, ASC's Privacy Policy/Terms/Support/Marketing URL fields for both apps still point at the old `ian-hamlet.github.io` host as of the 2026-08-21 Cloudflare Pages migration - re-enter the URLs above for both apps at submission time.

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

*(unchanged from v2.2.0+30/+31)*

### What's New in This Version
Improved reliability when a shop updates their card details or stamp requirement, and when the two apps pair. No new customer-visible feature this release - the updates are on the Supplier app side; see that app's What's New below.

### Promotional Text (170 chars max)
Free companion app for LoyaltyCards Business. Scan a shop's code to collect stamps - no account, no cloud, nothing to breach. Runs fully offline, on your device only.

*(unchanged from v2.2.0+30/+31)*

### Keywords (100 chars max)
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card

*(unchanged from v2.2.0+30/+31)*

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

This build (v2.2.0+32) has no new customer-visible feature - a shop's updated business name/icon/color now simply appears automatically the next time you scan, and a lower stamp requirement applies to your existing card the same way; a higher one only applies to your next card, including one completed via a normal stamp scan. Nothing new to interact with on this app's side - see the Supplier App's App Review Notes below for what to test.

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

*(unchanged from v2.2.0+30/+31)*

### What's New in This Version
Business Name, Icon, and Brand Color can now be edited anytime from Settings, alongside Stamps Required and the Express Mode scan cooldown (also now editable at any time, not just at setup). A new Audit Trail in Settings lets you review and share a history of every change.

### Promotional Text (170 chars max)
A free pair of apps that help small shops run a simple digital stamp card - no fees, no accounts. Customers need the companion LoyaltyCards app on their own phone.

*(unchanged from v2.2.0+30/+31)*

### Keywords (100 chars max)
loyalty program,small business,coffee shop,rewards,stamps,qr code,gdpr,no data,customer retention

*(unchanged from v2.2.0+30/+31)*

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

This build (v2.2.0+32) makes every Business Information field in Settings editable except Operation Mode: tap Business Name, Icon, Brand Color, Stamps Required, or (Express Mode only) the scan cooldown to change it, save, and confirm the Settings row updates immediately. It also adds a new "View Audit Trail" row at the bottom of Settings - open it to see a running log of the edits just made (and of any Recovery Backup/Clone/Restore actions), and confirm the Print/Share buttons produce a PDF. This doesn't affect the core issue-card/add-stamp review flow described above.

---

## Decisions (carried forward, unchanged from v2_0_0_19)

- [x] **Pricing:** both apps Free — confirmed by the developer.
- [x] **Copyright line:** `© 2026 Ian Hamlet`
- [x] **App Review contact phone:** 07968135909
- [x] **Age Rating questionnaire:** all "None", expected 4+ — confirmed entered in ASC 2026-08-15.
- [x] **Release Date:** Manual release, both apps — confirmed set 2026-08-18, should still hold for this release but worth reconfirming in ASC before submitting.
