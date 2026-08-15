# App Store Metadata Packet (v2.0.3+23)

**Status: Built, uploaded, and TestFlight-tested - not yet entered into ASC or submitted for review.** This is the version that actually applies the Category and Subtitle corrections found on 2026-08-10 - both required a new app version to take effect, since ASC doesn't allow editing Category, App Name, or Subtitle on a live version in place. It also ships a real feature: a new Settings "Sharing" section (Tell a Business / Tell a Friend) in both apps, plus a Home-screen shortcut icon in the supplier app, and two bug fixes found during TestFlight-prep testing - all confirmed working during TestFlight testing 2026-08-15. What's New text below reflects all of it. Next step: paste this content into App Store Connect and submit for review.

Use this file as copy/paste source for App Store Connect listing fields.

**Supersedes:** `APP_STORE_METADATA_PACKET_v2_0_3_22.md`, which never produced an uploaded build - build-only bump, same version (2.0.3). Changes from that version:
- Two bug fixes landed: Express Mode stamps were being routed to the newest card for a business instead of one that already had progress and room (customer app); Clone/Recovery Backup screens briefly showed a false "failed" error on open (supplier app). See `CHANGELOG.md`'s `[2.0.3+23]` entry for full detail.
- Build bumped to 23; everything else (Category/Subtitle corrections, Sharing feature, Description, App Review Notes) carried forward unchanged from the v2_0_3_22 packet - see that file's own "Supersedes" note for what changed relative to v2.0.2+21.

---

## Shared Listing Values

- Release Version: 2.0.3
- Build: 23
- Primary Language: English (UK)
- Privacy Policy URL: https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html
- Terms of Service URL: https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html
- Support URL: https://ian-hamlet.github.io/LoyaltyCards/support/
- Accessibility Statement (not an App Store Connect field, linked from the site): https://ian-hamlet.github.io/LoyaltyCards/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: https://ian-hamlet.github.io/LoyaltyCards/user/about.html

**Status:** All shared values unchanged from the prior packet.

---

## Customer App (LoyaltyCards Customer Wallet)

### Basic Info
- App Name: LoyaltyCards Customer Wallet
- Bundle ID: com.ianhamlet.loyaltycards.customerApp
- SKU: loyaltycards-customer-2026
- Primary Category: **Lifestyle** — applies the correction found 2026-08-10 (ASC currently shows Food & Drink)
- Secondary Category: **Shopping** — already matches what's live in ASC, no change

### Subtitle (30 chars max)
No signup, just stamps

### What's New in This Version
New: Settings → Sharing has "Tell a Business" and "Tell a Friend" - each shows a QR code and a share link so you can point someone straight to the companion Business app or invite a friend to LoyaltyCards. Also fixed a bug where a stamp could land on the wrong card when you had more than one active card for the same business.

### Promotional Text (170 chars max) - unchanged
Free companion app for LoyaltyCards Business. Scan a shop's code to collect digital stamps - no signup, nothing stored, works offline.

### Keywords (100 chars max) - unchanged
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card

### Description - unchanged from v2.0.2+21
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
This build adds a new "Sharing" section to Settings ("Tell a Business" and "Tell a Friend," each a QR code plus a native share-sheet link pointing at the other app's or a friend's copy of this app's App Store listing - no account, network call, or personal data involved). It also corrects the App Store listing's Category (was Food & Drink, now Lifestyle/Shopping) and Subtitle (was blank), and adds a link to the companion app's listing in the description. It is submitted alongside LoyaltyCards Business version 2.0.3, which has the equivalent feature and metadata corrections - the two apps are versioned together as a paired system.

This app is one side of a two-app system and is tested together with LoyaltyCards Business (the Business app issues cards; this app holds them). No login is required on either app, and no backend account exists - all features are offline-capable, since the two apps communicate only via QR code scanned directly between devices.

To review the full flow: install LoyaltyCards Business on a second device or the Simulator, create a test business in Express Mode (fastest to test - no time-limited QR codes involved), issue a card from the Business app, and scan it with this app. Secure Mode exercises the same flow but with cryptographically signed, time-limited QR codes generated per stamp from the Business app.

To review the new Sharing feature: Settings → Sharing → tap either "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

---

## Supplier App (LoyaltyCards Business)

### Basic Info
- App Name: LoyaltyCards Business
- Bundle ID: com.ianhamlet.loyaltycards.supplierApp
- SKU: loyaltycards-supplier-2026
- Primary Category: **Business** — applies the correction found 2026-08-10 (ASC currently shows Food & Drink, a poor fit for a B2B loyalty-management tool)
- Secondary Category: **Productivity** — applies the correction found 2026-08-10 (ASC currently shows Shopping)

### Subtitle (30 chars max)
Free loyalty program for shops

### What's New in This Version
New: Settings → Sharing has "Tell a Business" and "Tell a Friend" - each shows a QR code and a share link, so you can point another shop owner to this app or a customer to the companion wallet app in one tap. Tell a Friend also has a shortcut icon right on the Home screen for quick access at checkout. Also fixed a brief false error when opening Clone to Another Device or Create Recovery Backup.

### Promotional Text (170 chars max) - unchanged
A free pair of apps that help small shops run a simple digital stamp card - no fees, no accounts. Customers need the companion LoyaltyCards app on their own phone.

### Keywords (100 chars max) - unchanged
loyalty program,small business,coffee shop,rewards,stamps,qr code,point of sale,customer retention

### Description - unchanged from v2.0.2+21
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
This build adds a new "Sharing" section to Settings ("Tell a Business" and "Tell a Friend," each a QR code plus a native share-sheet link - no account, network call, or personal data involved), plus a matching shortcut icon on the Home screen for Tell a Friend. It also corrects the App Store listing's Category (was Food & Drink, a poor fit for a B2B loyalty-management tool - now Business/Productivity) and Subtitle (was purely descriptive, now leads with the app's zero-cost differentiator), and adds a link to the companion app's listing in the description. It is submitted alongside LoyaltyCards version 2.0.3, which has the equivalent feature and metadata corrections - the two apps are versioned together as a paired system.

This app is the business side of a two-app system and is reviewed together with LoyaltyCards (customer app) - this app issues and manages cards, the customer app holds them. No login is required on either app, and no backend account exists - all features are offline-capable.

To review the full flow: create a test business (Express Mode is fastest to review - no time-limited QR codes involved), then install LoyaltyCards on a second device or the Simulator to scan the "issue card" and "add stamp" QR codes this app displays. Secure Mode exercises the same flow but generates a freshly signed, time-limited QR code per stamp instead of a static reusable one.

To review the new Sharing feature: either tap the person icon in the Home screen's top bar, or go to Settings → Sharing → "Tell a Business" or "Tell a Friend" - both show a QR code and a "Share the Link" button that opens the standard iOS share sheet with a plain-text link. No account, camera permission, or network access is required for this feature.

---

## Decisions (carried forward, unchanged from v2_0_0_19)

- [x] **Pricing:** both apps Free — confirmed by the developer.
- [x] **Copyright line:** `© 2026 Ian Hamlet`
- [x] **App Review contact phone:** 07968135909
- [x] **Age Rating questionnaire:** Draft answers (all "None", expected 4+) are in `APP_STORE_SUBMISSION_CHECKLIST.md` — still accurate, just needs to be entered in App Store Connect.

**Still needs entering into the actual App Store Connect UI** — these are decided/drafted here, not yet live in ASC.
