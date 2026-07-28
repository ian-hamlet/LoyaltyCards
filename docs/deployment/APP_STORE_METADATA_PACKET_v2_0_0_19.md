# App Store Metadata Packet (v2.0.0+19)

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
- Always Available - Your loyalty cards never leave home

HOW IT WORKS

1. Business shows you a QR code
2. You scan it with LoyaltyCards
3. Collect stamps each visit
4. Get your reward when complete

TWO APPS, ONE SYSTEM

LoyaltyCards is one half of a pair: this app is your wallet, and businesses use a separate companion app (LoyaltyCards Business) to issue and manage cards. There's no shared server connecting them - your phone and the business's device talk directly through the QR code you scan, and nothing is sent anywhere else. You only ever need this app; the business handles the other side.

EXPRESS OR SECURE - THE BUSINESS DECIDES

Each business chooses how their card works:
- Express Mode: scan a printed QR code yourself, stamp added in about 2 seconds. Fast and self-service, like a physical punch card.
- Secure Mode: the business generates a fresh, cryptographically signed QR code for each stamp from their own device. Slightly slower, but every stamp is provably genuine.

Example: your regular coffee shop might use Express Mode for a $5 coffee reward, while a spa offering a $200 service uses Secure Mode - you'll see both kinds of cards side by side in the same wallet, with no setup required on your end either way.

PERFECT FOR

- Coffee shops and cafes
- Restaurants and food trucks
- Retail stores and boutiques
- Salons and spas
- Any business offering loyalty rewards

PRIVACY FIRST

We don't collect your personal information. Period. No email, no phone number, no account creation, no tracking, no data sharing. Your loyalty cards stay on your device.

SMALL BUSINESS FRIENDLY

Works perfectly with our companion app, LoyaltyCards Business, designed for small businesses who want to run loyalty programs without expensive systems or monthly fees.

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
- Setup in 60 Seconds - Start issuing cards immediately

TWO APPS, ONE SYSTEM

This app is the business side of a pair: you use it to issue and manage loyalty cards, and your customers use a separate, free companion app (LoyaltyCards) to hold them. There's no shared server or account linking the two - each customer's card is created directly on their phone when they scan a QR code you show them, and stamps are added the same way on every visit. You never see personal information, because none is ever collected.

CHOOSE YOUR MODE

- Express Mode: print a reusable QR code once, customers self-serve. Fastest option (about 2 seconds per stamp), no equipment needed beyond a printed code. A configurable cooldown (5-60 seconds) between stamps discourages casual abuse. Best for high-volume, lower-value rewards - think a coffee shop's "buy 10, get 1 free."
- Secure Mode: generate a fresh, cryptographically signed QR code for every stamp from your own device. Slightly slower (5-10 seconds) and needs a phone or tablet at checkout, but every stamp is tamper-proof and redemption requires you to scan and validate the customer's card. Best for higher-value rewards where fraud resistance matters more than raw speed - a spa or boutique offering a $50-200 reward, for example.

Both modes work completely offline and cost nothing to run. You can't switch modes on an existing setup without a full reset, so it's worth choosing based on your typical reward value and how fast you need checkout to be.

PERFECT FOR

- Coffee shops and cafes
- Restaurants and food trucks
- Retail stores and boutiques
- Salons and spas
- Farmers markets and pop-ups
- Any small business wanting loyal customers

HOW IT WORKS

1. Configure your stamp card (business name, stamps required)
2. Show customers your QR code
3. They scan with LoyaltyCards app (free download)
4. Issue stamps each visit with one scan
5. Scan their redemption QR when card is complete

MULTI-DEVICE SUPPORT

Run your loyalty program across multiple devices:
- Backup your configuration with one QR scan
- Clone to new devices (registers, iPads, staff phones)
- All devices issue stamps for the same program

SIMPLE COUNTERS, BY DESIGN

Track the basics without invasive tracking:
- Lifetime totals for cards issued, stamps given, and redemptions
- No customer profiles, no behavior tracking, nothing to mine
- Deliberately simple - because we never collect the customer data a fuller dashboard would require in the first place

PRIVACY FOCUSED

Unlike traditional loyalty systems, you don't collect customer emails, phone numbers, or personal information. Customers appreciate the privacy, and you avoid GDPR complexity.

NO ONGOING COSTS

Other loyalty systems often charge monthly subscriptions and setup fees. LoyaltyCards Business is completely free, with zero ongoing costs.

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
