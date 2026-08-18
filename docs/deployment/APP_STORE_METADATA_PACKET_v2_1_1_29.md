# App Store Metadata Packet (v2.1.1+29)

**Status: 🟡 SUBMITTED FOR APP STORE REVIEW 2026-08-18** (both apps), awaiting Apple's decision. Built and delivered to TestFlight 2026-08-18; metadata confirmed and entered into App Store Connect 2026-08-18 (both apps' Promotional Text re-entered - both were found blank; Release Date confirmed set to Manual, both apps). Build-only bump - v2.1.1+28 was already built and uploaded to TestFlight before TEST-022 was found (via real-device testing of that exact build), and Apple doesn't allow re-uploading the same build number with different content.

Use this file as the single copy/paste source for App Store Connect listing fields - it's self-contained (pulls in the "unchanged" fields from `APP_STORE_METADATA_PACKET_v2_0_3_23.md` directly, rather than requiring you to flip between files mid-release, after that pattern caused the Promotional Text field to nearly get skipped twice).

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_1_1_28.md` (shipped to TestFlight with TEST-021 and DECISION-017, but not TEST-022) for App Store submission purposes. See `docs/project-management/DEFECT_TRACKER.md` TEST-022 for full detail.

**Build-only bump (2.1.1+28 -> 2.1.1+29), not a version change** - same feature set as v2.1.1+28 plus one additional bug fix (a cross-version compatibility regression TEST-021 introduced, invisible to any user running matched app versions).

---

## Shared Listing Values

- Release Version: 2.1.1
- Build: 29
- Primary Language: English (UK)
- Privacy Policy URL: https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html
- Terms of Service URL: https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html
- Support URL: https://ian-hamlet.github.io/LoyaltyCards/support/
- Accessibility Statement (not an App Store Connect field, linked from the site): https://ian-hamlet.github.io/LoyaltyCards/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: https://ian-hamlet.github.io/LoyaltyCards/user/about.html

**Status:** All shared values confirmed live in ASC, unchanged since v2.0.3+23.

---

## Customer App (LoyaltyCards Customer Wallet)

### Basic Info
- App Name: LoyaltyCards Customer Wallet
- Bundle ID: com.ianhamlet.loyaltycards.customerApp
- SKU: loyaltycards-customer-2026
- Primary Category: Lifestyle
- Secondary Category: Shopping

### Subtitle (30 chars max)
No signup, just stamps

### What's New in This Version
Fixed a bug where a business set up for 3 or 4 stamps couldn't issue a working card. Also improved reliability of adding and redeeming cards from a business using higher stamp counts.

### Promotional Text (170 chars max)
Free companion app for LoyaltyCards Business. Scan a shop's code to collect digital stamps - no signup, nothing stored, works offline.

**Status:** ✅ Confirmed and re-entered in ASC 2026-08-18. Kept here directly because this exact field was found blank in ASC once already (2026-08-15) despite being documented as live from a prior version.

### Keywords (100 chars max)
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card

### Description
LoyaltyCards is the free companion app for shops using LoyaltyCards Business. If a shop you visit uses it, you can collect digital stamp cards on your own phone instead of paper ones.

WHAT TO EXPECT

This isn't a directory or a marketplace - there's nothing to browse. You'll only use this app if a shop you already visit shows you a QR code and asks you to scan it.

HOW IT WORKS

1. A shop shows you a QR code
2. You scan it with LoyaltyCards
3. Collect a stamp each visit
4. Show your completed card to redeem your reward

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

This build (v2.1.1+29) is a reliability update - see the Supplier App's App Review Notes below for the specific issues fixed. None affect the core review flow described above.

---

## Supplier App (LoyaltyCards Business)

### Basic Info
- App Name: LoyaltyCards Business
- Bundle ID: com.ianhamlet.loyaltycards.supplierApp
- SKU: loyaltycards-supplier-2026
- Primary Category: Business
- Secondary Category: Productivity

### Subtitle (30 chars max)
Free loyalty program for shops

### What's New in This Version
Fixed a bug where setting up a business with 3 or 4 required stamps produced a card that customers couldn't add - affected both Express Mode and Secure Mode. Also improved reliability of issuing and redeeming cards for Secure Mode businesses with higher stamp counts, raised the maximum stamps required from 10 to 12, and added a way to fix a business's stamp count in-app if it's ever set outside the supported range.

### Promotional Text (170 chars max)
A free pair of apps that help small shops run a simple digital stamp card - no fees, no accounts. Customers need the companion LoyaltyCards app on their own phone.

**Status:** ✅ Confirmed and re-entered in ASC 2026-08-18. This field was also found blank in ASC - the same gap as the customer app's Promotional Text (found 2026-08-15), but for this field the check was only actually done now, for this submission.

### Keywords (100 chars max)
loyalty program,small business,coffee shop,rewards,stamps,qr code,point of sale,customer retention

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

PRIVACY

No customer emails, phone numbers, or personal data collected - ever.

WHO IT'S FOR

Built with smaller, independent outlets in mind - cafes, salons, and similar shops that want to reward regular customers without paying for a loyalty platform.

Download LoyaltyCards Business and get started.

### App Review Notes (Supplier)
This app is the business side of a two-app system and is reviewed together with LoyaltyCards (customer app) - this app issues and manages cards, the customer app holds them. No login is required on either app, and no backend account exists - all features are offline-capable.

To review the full flow: create a test business (Express Mode is fastest to review - no time-limited QR codes involved), then install LoyaltyCards on a second device or the Simulator to scan the "issue card" and "add stamp" QR codes this app displays. Secure Mode exercises the same flow but generates a freshly signed, time-limited QR code per stamp instead of a static reusable one.

To review the Sharing feature: either tap the person icon in the Home screen's top bar, or go to Settings → Sharing → "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

This build (v2.1.1+29) fixes five related issues found during internal testing, none reported by a real user (the app has minimal real-world usage so far):
1. Businesses configured for 3 or 4 required stamps (allowed by the onboarding slider) could never actually issue a working loyalty card - a validation bound elsewhere in the app didn't match the slider's own minimum.
2. In Secure Mode, redeeming a completed card with a higher stamp count (or one where stamps had been automatically moved between cards by the app's own overflow-handling logic) could occasionally fail to display a redemption code, with no error shown. This is now fixed by switching to a more compact code format for the redemption step; the maximum supported stamp count was raised from 10 to 12 as part of confirming the fix.
3. The same underlying issue as #2 could also affect issuing a new card with many stamps already applied at once (a manual catch-up scenario) - fixed the same way. Only reachable on a business set up before this update, since the current setup range (3-12 stamps) never produces enough pre-applied stamps to trigger it.
4. A business set up before this update, with a stamp count now outside the supported range, previously had no way to fix its own configuration short of a full data reset. The app now detects this on launch and offers a guided way to update the stamp count in place, without affecting any customer's existing card.
5. The fix for #3 initially had an unintended side effect: it changed the internal format of new-card QR codes in a way that a customer running an older app version couldn't read, showing a generic error when adding a card from an updated business. This is now fixed - the app uses the original, universally-compatible format whenever possible, only switching to the newer format for the rare oversized case #3 actually targets.

None of these affect the core review flow described above (Express Mode business setup, issuing a card, scanning to add stamps) - all are edge cases involving specific stamp-count configurations or app-version combinations.

---

## Decisions (carried forward, unchanged from v2_0_0_19)

- [x] **Pricing:** both apps Free — confirmed by the developer.
- [x] **Copyright line:** `© 2026 Ian Hamlet`
- [x] **App Review contact phone:** 07968135909
- [x] **Age Rating questionnaire:** all "None", expected 4+ — confirmed entered in ASC 2026-08-15.
- [x] **Release Date:** Manual release, both apps — confirmed set 2026-08-18.
