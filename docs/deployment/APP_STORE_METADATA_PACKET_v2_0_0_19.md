# App Store Metadata Packet (v2.0.0+19)

**Status: SUBMITTED FOR REVIEW 2026-07-28.** Both apps were submitted to App Store Connect at version 2.0.0, build 19, using the content below (the shortened descriptions, not the original longer draft this file started with). This is now a record of what was actually submitted, not just a draft.

Use this file as copy/paste source for App Store Connect listing fields.

**Supersedes:** `APP_STORE_METADATA_PACKET_v1_0_2_8.md`. Changes from that version: renamed "Simple Mode" to "Express Mode" throughout (the app itself was renamed earlier and this packet was missed), expanded both descriptions with a clearer explanation of why there are two apps and a compact real-world example per operation mode (previously the mode explanation was a single line with no context for why you'd pick one over the other), and set the Marketing URL to the new About page. Pricing/copyright/phone/age-rating decisions carried forward unchanged from the prior packet.

---

## Shared Listing Values

- Release Version: 2.0.0
- Build: 19
- Primary Language: English (US)
- Privacy Policy URL: https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html
- Terms of Service URL: https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html
- Support URL: https://ian-hamlet.github.io/LoyaltyCards/support/
- Accessibility Statement (not an App Store Connect field, linked from the site): https://ian-hamlet.github.io/LoyaltyCards/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: https://ian-hamlet.github.io/LoyaltyCards/user/about.html — explains the two-app pairing and Express/Secure Mode choice with examples; previously left blank/unset in the prior packet

**Status:** Legal/support URLs unchanged from the prior packet and still live. The new About page (`site/user/about.html`) needs a real deploy of `site/` before the Marketing URL is live — confirm it resolves before entering it into App Store Connect.

---

## Customer App (LoyaltyCards - Digital Stamps)

### Basic Info
- App Name: LoyaltyCards - Digital Stamps
- Bundle ID: com.ianhamlet.loyaltycards.customerApp
- SKU: loyaltycards-customer-001
- Primary Category: Lifestyle
- Secondary Category: Shopping (optional)

### Subtitle (30 chars max)
Collect stamps, earn rewards

### Promotional Text (170 chars max)
Digital loyalty cards for your favorite businesses. Collect stamps, earn rewards. No signup required. Fast, private, secure.

### Keywords (100 chars max)
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card

### Description
Transform your wallet with LoyaltyCards - the simplest way to collect stamps and earn rewards at your favorite local businesses.

WHY LOYALTYCARDS?

- Zero Signup - Scan a QR code and start collecting instantly
- Complete Privacy - No email, no phone number, no tracking
- Works Offline - No internet connection required
- Secure by Design - Cryptographically verified stamps prevent fraud

HOW IT WORKS

1. Business shows you a QR code
2. You scan it with LoyaltyCards
3. Collect stamps each visit
4. Get your reward when complete

TWO APPS, ONE SYSTEM

LoyaltyCards is your wallet. Businesses use a separate app, LoyaltyCards Business, to issue and manage cards - no shared server, no account, just a QR code scanned directly between your phone and theirs.

Some businesses use Express Mode (instant, self-scan) and others use Secure Mode (cryptographically signed, business validates each stamp) - you'll see both in your wallet, with no setup needed on your end either way.

PRIVACY FIRST

No email, no phone number, no account, no tracking. Your loyalty cards stay on your device.

PERFECT FOR

Coffee shops, restaurants, retail stores, salons, spas, and any business offering loyalty rewards.

Download LoyaltyCards today and start earning rewards.

### App Review Notes (Customer)
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

### Subtitle (30 chars max)
Digital loyalty card system

### Promotional Text (170 chars max)
Run your loyalty program with zero monthly fees. Issue digital stamp cards to customers. Works offline. No customer data collection. Perfect for small businesses.

### Keywords (100 chars max)
loyalty program,small business,coffee shop,rewards,stamps,qr code,point of sale,customer retention

### Description
Transform your customer loyalty program with LoyaltyCards Business - the zero-cost alternative to expensive loyalty systems.

WHY LOYALTYCARDS BUSINESS?

- Zero Monthly Fees - No subscriptions, no hidden costs
- No Customer Data Collection - Privacy-first design
- Works Offline - No internet connection required
- Multi-Device Support - Use on multiple iPads/iPhones

TWO APPS, ONE SYSTEM

You issue and manage cards here; customers hold them in a separate, free companion app (LoyaltyCards). No shared server or account - each card is created and stamped directly on the customer's phone via QR code.

CHOOSE YOUR MODE

- Express Mode: print one reusable QR code, customers self-serve in about 2 seconds. Best for high-volume, lower-value rewards.
- Secure Mode: generate a fresh, cryptographically signed QR code per stamp from your device. Slightly slower, but every stamp is tamper-proof. Best for higher-value rewards.

Both work fully offline. You can't switch modes later without a full reset, so choose based on your typical reward value.

MULTI-DEVICE SUPPORT

Back up your configuration with one QR scan and clone it to additional devices (registers, staff phones) - all issuing stamps for the same program.

PRIVACY FOCUSED

No customer emails, phone numbers, or personal data collected - ever.

PERFECT FOR

Coffee shops, restaurants, retail stores, salons, spas, farmers markets, and any small business wanting loyal customers.

Download LoyaltyCards Business and start building customer loyalty today.

### App Review Notes (Supplier)
This app is the business side of a two-app system and is reviewed together with LoyaltyCards (customer app) - this app issues and manages cards, the customer app holds them. No login is required on either app, and no backend account exists - all features are offline-capable.

To review the full flow: create a test business (Express Mode is fastest to review - no time-limited QR codes involved), then install LoyaltyCards on a second device or the Simulator to scan the "issue card" and "add stamp" QR codes this app displays. Secure Mode exercises the same flow but generates a freshly signed, time-limited QR code per stamp instead of a static reusable one.

---

## Decisions (carried forward, unchanged from v1_0_2_8)

- [x] **Pricing:** both apps Free — confirmed by the developer.
- [x] **Copyright line:** `© 2026 Ian Hamlet`
- [x] **App Review contact phone:** 07968135909
- [x] **Age Rating questionnaire:** Draft answers (all "None", expected 4+) are in `APP_STORE_SUBMISSION_CHECKLIST.md` — still accurate, just needs to be entered in App Store Connect.

**Still needs entering into the actual App Store Connect UI** — these are decided/drafted here, not yet live in ASC.
