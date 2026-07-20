# App Store Metadata Packet (v1.0.2+8)

Use this file as copy/paste source for App Store Connect listing fields.

**Supersedes:** `APP_STORE_METADATA_PACKET_v1_0_0_6.md` (that build was never actually submitted — see `APP_STORE_MATERIALS_EXECUTION_TRACKER.md` for the corrected status). Content is unchanged from the v1.0.0+6 draft except version numbers and URLs; the underlying feature set/marketing claims were reviewed against the current `develop` branch (v1.0.2+8) and still hold.

---

## Shared Listing Values

- Release Version: 1.0.2
- Build: 8
- Primary Language: English (US)
- Privacy Policy URL: https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html *(live, verified)*
- Terms of Service URL: https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html *(live, verified)*
- Support URL: https://ian-hamlet.github.io/LoyaltyCards/support/ *(live, verified)*
- Accessibility Statement (not an App Store Connect field, linked from the site): https://ian-hamlet.github.io/LoyaltyCards/legal/accessibility-statement.html
- Support Contact Email: ian.hamlet@dotconnected.com
- Marketing URL: Optional — could point to https://ian-hamlet.github.io/LoyaltyCards/ (the landing page) if desired, otherwise leave blank

**Status:** All three required URLs are live, hosted via GitHub Pages from `site/` (deployed by `.github/workflows/pages.yml`), and verified returning HTTP 200. Source content lives in `docs/legal/PRIVACY_POLICY.md`, `docs/legal/TERMS_OF_SERVICE.md`, and `docs/legal/SUPPORT_PAGE.md` — the published HTML in `site/` was hand-converted from these, so any future edits to the Markdown need to be mirrored into the corresponding `site/**/*.html` file (and vice versa) to stay in sync.

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

PERFECT FOR

- Coffee shops and cafes
- Restaurants and food trucks
- Retail stores and boutiques
- Salons and spas
- Any business offering loyalty rewards

PRIVACY FIRST

We don't collect your personal information. Period. No email, no phone number, no account creation, no tracking, no data sharing. Your loyalty cards stay on your device.

SIMPLE AND SECURE MODES

Choose how you collect stamps:
- Simple Mode: Fast stamp collection (like physical cards)
- Secure Mode: Cryptographically verified stamps (fraud-proof)

SMALL BUSINESS FRIENDLY

Works perfectly with our companion app, LoyaltyCards Business, designed for small businesses who want to run loyalty programs without expensive systems or monthly fees.

Download LoyaltyCards today and start earning rewards.

### App Review Notes (Customer)
This app is one side of a two-app system and is tested together with LoyaltyCards Business. No login is required. No backend account is required. All features are offline-capable.

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

SIMPLE AND SECURE MODES

- Simple Mode: Fast stamp issuance (trust-based, like physical cards)
- Secure Mode: Cryptographically signed stamps (fraud-proof digital signatures)

MULTI-DEVICE SUPPORT

Run your loyalty program across multiple devices:
- Backup your configuration with one QR scan
- Clone to new devices (registers, iPads, staff phones)
- All devices issue stamps for the same program

BUSINESS ANALYTICS

Track your loyalty program performance:
- Cards issued today/this week/all time
- Stamps given out
- Cards redeemed
- Simple dashboard, no complicated reports

PRIVACY FOCUSED

Unlike traditional loyalty systems, you don't collect customer emails, phone numbers, or personal information. Customers appreciate the privacy, and you avoid GDPR complexity.

NO ONGOING COSTS

Other loyalty systems often charge monthly subscriptions and setup fees. LoyaltyCards Business is a one-time app purchase with zero ongoing costs.

Download LoyaltyCards Business and start building customer loyalty today.

### App Review Notes (Supplier)
This app is the business side of a two-app system and is reviewed together with LoyaltyCards (customer app). No login is required. No backend account is required. All features are offline-capable.

---

## Open Decisions Before This Packet Is Submission-Ready

- [ ] **Pricing:** `APP_STORE_MATERIALS_EXECUTION_TRACKER.md` records both apps as Free (decided 2026-06-11), but earlier planning docs suggested a paid Supplier app ($2.99). Confirm final price in App Store Connect before submission — the "NO ONGOING COSTS" / "one-time app purchase" language above assumes a non-zero one-time price; if Supplier ends up Free too, adjust that paragraph.
- [ ] **Copyright line:** Needs a real name/entity, e.g. `© 2026 Ian Hamlet`.
- [ ] **Age Rating questionnaire:** Draft answers (all "None", expected 4+) are in `APP_STORE_SUBMISSION_CHECKLIST.md` — still accurate, just needs to be entered in App Store Connect.
