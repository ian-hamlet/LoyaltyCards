# App Store Metadata Packet (v2.0.2+21)

**Status: DRAFT - not yet submitted.** Supersedes `APP_STORE_METADATA_PACKET_v2_0_1_20.md` before that build was ever uploaded - Transporter flagged `IPHONEOS_DEPLOYMENT_TARGET = 13.0` during the 2.0.1+20 upload attempt (Apple requires 15.0+ for all App Store Connect uploads starting Spring 2027). Fixed by raising both apps' deployment target to 15.0; no app-facing behavior changed. All listing content below is otherwise identical to the 2.0.1+20 packet - it still describes the CRASH-001 print-crash fix, UI-001 dark mode fix, and Express Mode redemption copy clarification, since none of that shipped yet either.

Use this file as copy/paste source for App Store Connect listing fields.

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_0_1_20.md`. Only change from that version: Release Version/Build bumped to 2.0.2/21 throughout. Subtitle, What's New, Promotional Text, Keywords, Description, App Review Notes, and Decisions are all carried forward unchanged - see that packet's own "Supersedes" note for what changed relative to v2.0.0+19.

---

## Shared Listing Values

- Release Version: 2.0.2
- Build: 21
- Primary Language: English (US)
- Privacy Policy URL: https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html
- Terms of Service URL: https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html
- Support URL: https://ian-hamlet.github.io/LoyaltyCards/support/
- Accessibility Statement (not an App Store Connect field, linked from the site): https://ian-hamlet.github.io/LoyaltyCards/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: https://ian-hamlet.github.io/LoyaltyCards/user/about.html

**Status:** All shared values unchanged from the prior packet.

---

## Customer App (LoyaltyCards - Digital Stamps)

### Basic Info
- App Name: LoyaltyCards - Digital Stamps
- Bundle ID: com.ianhamlet.loyaltycards.customerApp
- SKU: loyaltycards-customer-001
- Primary Category: Lifestyle
- Secondary Category: Shopping (optional)

### Subtitle (30 chars max) - unchanged
Collect stamps, earn rewards

### What's New in This Version - unchanged from v2.0.1+20
Fixed unreadable text in dark mode on the How It Works screen, and clarified the wording on the card redemption screens.

### Promotional Text (170 chars max) - unchanged from v2.0.1+20
Free companion app for LoyaltyCards Business. Scan a shop's code to collect digital stamps - no signup, nothing stored, works offline.

### Keywords (100 chars max) - unchanged
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card

### Description - unchanged from v2.0.1+20
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

Download LoyaltyCards and start collecting.

### App Review Notes (Customer) - unchanged from v2.0.1+20
This update contains no functional changes to this app - only a dark mode text-contrast fix on the "How It Works" screen and clarified wording on the card redemption screens (making explicit that the supplier witnesses the redemption). It is being submitted alongside LoyaltyCards Business version 2.0.2, which contains an unrelated crash fix (see that app's notes) - the two apps are versioned together as a paired system.

This app is one side of a two-app system and is tested together with LoyaltyCards Business (the Business app issues cards; this app holds them). No login is required on either app, and no backend account exists - all features are offline-capable, since the two apps communicate only via QR code scanned directly between devices.

To review the full flow: install LoyaltyCards Business on a second device or the Simulator, create a test business in Express Mode (fastest to test - no time-limited QR codes involved), issue a card from the Business app, and scan it with this app. Secure Mode exercises the same flow but with cryptographically signed, time-limited QR codes generated per stamp from the Business app.

---

## Supplier App (LoyaltyCards Business)

### Basic Info
- App Name: LoyaltyCards Business
- Bundle ID: com.ianhamlet.loyaltycards.supplierApp
- SKU: loyaltycards-supplier-001
- Primary Category: Business
- Secondary Category: Productivity (optional)

### Subtitle (30 chars max) - unchanged
Digital loyalty card system

### What's New in This Version - unchanged from v2.0.1+20
Fixed a crash that could occur when tapping Print. Fixed unreadable text in dark mode on the How It Works screen.

### Promotional Text (170 chars max) - unchanged from v2.0.1+20
A free pair of apps that help small shops run a simple digital stamp card - no fees, no accounts. Customers need the companion LoyaltyCards app on their own phone.

### Keywords (100 chars max) - unchanged
loyalty program,small business,coffee shop,rewards,stamps,qr code,point of sale,customer retention

### Description - unchanged from v2.0.1+20
LoyaltyCards Business is a free way for small shops to run a digital stamp card, without the cost or complexity of a loyalty platform.

WHY LOYALTYCARDS BUSINESS?

- Free - no subscriptions, no fees, no hidden costs
- No customer data collected - nothing to store, nothing to protect
- Works offline - no internet connection required
- Use on multiple devices - registers, staff phones, whatever you already have

TWO APPS, ONE SYSTEM

This app is for the shop. Customers need the free companion app, LoyaltyCards, on their own phone to hold their cards - there's no shared server or account, each card is created and stamped directly between your device and theirs via QR code.

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

### App Review Notes (Supplier) - unchanged from v2.0.1+20
This build (2.0.2, build 21) fixes the crash reported in the previous review: tapping Print could cause the app to crash. Please see the reproduction and verification steps below - this note explains exactly what changed so it's easy to confirm the fix.

What caused it: a double-tap race condition. The Print and Share buttons on the Stamp Setup, Issue Card, and Recovery Backup screens had no protection against a second tap while the first print/share job was still starting - a fast repeat tap could fire two concurrent native print calls, which crashed.

What changed: every Print/Share/Save button in this app now disables itself immediately on the first tap and shows a loading indicator until that job completes, so a second tap during that window does nothing. We also added validation of the generated PDF data before it's handed to the native print API, as a defense-in-depth fix for a related but separate crash path in the same code.

How to verify: on the Stamp Setup or Issue Card screen, generate a QR code, then tap Print (or Share) rapidly several times in a row. The button should visibly disable/show a spinner on the first tap and stay disabled until the print or share sheet opens; repeated taps during that window should have no effect and the app should not crash. The same applies to the three buttons (Print Backup, Share via Email, Save to Files) on the Recovery Backup screen.

This app is the business side of a two-app system and is reviewed together with LoyaltyCards (customer app) - this app issues and manages cards, the customer app holds them. No login is required on either app, and no backend account exists - all features are offline-capable.

To review the full flow: create a test business (Express Mode is fastest to review - no time-limited QR codes involved), then install LoyaltyCards on a second device or the Simulator to scan the "issue card" and "add stamp" QR codes this app displays. Secure Mode exercises the same flow but generates a freshly signed, time-limited QR code per stamp instead of a static reusable one.

---

## Decisions (carried forward, unchanged from v2_0_0_19)

- [x] **Pricing:** both apps Free — confirmed by the developer.
- [x] **Copyright line:** `© 2026 Ian Hamlet`
- [x] **App Review contact phone:** 07968135909
- [x] **Age Rating questionnaire:** Draft answers (all "None", expected 4+) are in `APP_STORE_SUBMISSION_CHECKLIST.md` — still accurate, just needs to be entered in App Store Connect.

**Still needs entering into the actual App Store Connect UI** — these are decided/drafted here, not yet live in ASC.
