# App Store Submission Checklist

**LoyaltyCards v1.0.3+11**  
**Customer App:** LoyaltyCards - Digital Stamps  
**Supplier App:** LoyaltyCards Business  
**Target Release:** TBD  
**Last Updated:** July 21, 2026

**Status note:** This app has only ever been distributed via TestFlight beta — no version has gone further. An earlier internal tracker (`APP_STORE_MATERIALS_EXECUTION_TRACKER.md`) recorded a submission for v1.0.1+7 that did not actually happen (the required legal/support URLs didn't exist yet at the time). Treat every box below as unchecked-until-verified in App Store Connect directly, regardless of what any other document claims.

**Version history since v1.0.2+8** (the version most of this checklist's content was originally verified against): v1.0.2+8's first upload had an incorrect export compliance answer (see the Export Compliance section) and was superseded before submission; v1.0.2+9 was a build-number-only bump to dodge a Transporter conflict; v1.0.3+10 was a proper version bump, **built, uploaded to TestFlight, and confirmed running on physical hardware**; v1.0.3+11 (current) adds clearer Express-vs-Secure Mode guidance to supplier onboarding (see `supplier_onboarding.dart`): the mode selection radio tiles show `recommendedFor` text instead of a shorter description, a persistent always-visible warning explains the mode choice can't be changed without a full reset (and now points to the info icon / User Guide for more detail), and the tap-to-reveal info tooltip was expanded into a fuller side-by-side comparison (speed, equipment, fraud protection, recommended use case). Not yet built/uploaded as of this checklist update.

---

## Pre-Submission Requirements

### ✅ Code & Build Preparation

- [x] **Final build number incremented** in pubspec.yaml (both apps) — `1.0.3+11`, confirmed in `source/{customer_app,supplier_app,shared}/pubspec.yaml`
- [x] **Version number confirmed** — v1.0.3+11 is the current `develop`/`main` version
- [ ] **All code merged to `main` branch** — pending commit for this build (held back per explicit instruction while more changes land)
- [ ] **Release branch created** `releases/v1.0.3-build11` — not yet created (note: `releases/v1.0.3-build10` already exists as the snapshot for the previous, TestFlight-tested build)
- [ ] **Archive builds completed** for v1.0.3+11
  ```bash
  cd source/customer_app
  flutter clean && flutter pub get
  flutter build ipa --release
  
  cd ../supplier_app
  flutter clean && flutter pub get
  flutter build ipa --release
  ```
- [ ] **IPA files uploaded to App Store Connect** via Transporter
- [ ] **Build processing complete** in App Store Connect (10-15 min wait)
- [x] **All 264 automated tests passing** (131 shared + 87 customer + 46 supplier), verified 2026-07-21 against current `develop`/`main` — supersedes the "no build warnings" / "no compilation errors" items below as a stronger signal
- [x] **`flutter analyze` clean** on the changed onboarding file — no errors, only pre-existing-pattern deprecation info notices
- [ ] **TestFlight beta testing completed for *this* build** (v1.0.3+11 has not been built/uploaded yet; v1.0.3+10 was tested and confirmed on hardware, but this build has new changes since)
- [x] **Critical bugs resolved** (zero CRITICAL/HIGH defects open in `DEFECT_TRACKER.md`)

---

### 📱 App Store Connect - Basic Information

#### Customer App: LoyaltyCards - Digital Stamps

- [ ] **App Name:** LoyaltyCards - Digital Stamps (or "LoyaltyCards") — decided here, needs entering/confirming in ASC
- [ ] **Bundle ID:** `com.ianhamlet.loyaltycards.customerApp` — should already be registered (TestFlight beta ran under this bundle ID), verify in ASC
- [ ] **SKU:** `loyaltycards-customer-001`
- [ ] **Primary Language:** English (US)
- [ ] **Primary Category:** Lifestyle
- [ ] **Secondary Category:** Shopping (optional)
- [ ] **Content Rights:** Confirm you own or have licensed all content

#### Supplier App: LoyaltyCards Business

- [ ] **App Name:** LoyaltyCards Business — decided here, needs entering/confirming in ASC
- [ ] **Bundle ID:** `com.ianhamlet.loyaltycards.supplierApp` — should already be registered (TestFlight beta ran under this bundle ID), verify in ASC
- [ ] **SKU:** `loyaltycards-supplier-001`
- [ ] **Primary Language:** English (US)
- [ ] **Primary Category:** Business
- [ ] **Secondary Category:** Productivity (optional)
- [ ] **Content Rights:** Confirm you own or have licensed all content

---

### 📝 App Descriptions & Marketing

#### Customer App Description (Max 4000 characters)

**Subtitle (30 chars max):**
```
Collect stamps, earn rewards
```

**Promotional Text (170 chars, updatable without review):**
```
Digital loyalty cards for your favorite businesses. Collect stamps, earn rewards. No signup required. Fast, private, secure.
```

**Description:**
```
Transform your wallet with LoyaltyCards - the simplest way to collect stamps and earn rewards at your favorite local businesses.

WHY LOYALTYCARDS?

• Zero Signup - Scan a QR code and start collecting instantly
• Complete Privacy - No email, no phone number, no tracking
• Works Offline - No internet connection required
• Secure by Design - Cryptographically verified stamps prevent fraud
• Always Available - Your loyalty cards never leave home

HOW IT WORKS

1. Business shows you a QR code
2. You scan it with LoyaltyCards
3. Collect stamps each visit
4. Get your reward when complete

PERFECT FOR

• Coffee shops and cafes
• Restaurants and food trucks
• Retail stores and boutiques
• Salons and spas
• Any business offering loyalty rewards

PRIVACY FIRST

We don't collect your personal information. Period. No email, no phone number, no account creation, no tracking, no data sharing. Your loyalty cards stay on your device.

SIMPLE & SECURE MODES

Choose how you collect stamps:
• Simple Mode: Fast stamp collection (like physical cards)
• Secure Mode: Cryptographically verified stamps (fraud-proof)

SMALL BUSINESS FRIENDLY

Works perfectly with our companion app, LoyaltyCards Business, designed for small businesses who want to run loyalty programs without expensive systems or monthly fees.

Download LoyaltyCards today and start earning rewards!
```

**Keywords (100 chars max, comma-separated):**
```
loyalty,rewards,stamps,coffee,local business,qr code,privacy,offline,small business,punch card
```

---

#### Supplier App Description (Max 4000 characters)

**Subtitle (30 chars max):**
```
Digital loyalty card system
```

**Promotional Text (170 chars):**
```
Run your loyalty program with zero monthly fees. Issue digital stamp cards to customers. Works offline. No customer data collection. Perfect for small businesses.
```

**Description:**
```
Transform your customer loyalty program with LoyaltyCards Business - the zero-cost alternative to expensive loyalty systems.

WHY LOYALTYCARDS BUSINESS?

• $0 Monthly Fees - No subscriptions, no hidden costs
• No Customer Data Collection - Privacy-first design
• Works Offline - No internet connection required
• Multi-Device Support - Use on multiple iPads/iPhones
• No Customer App Required* - Customers use free LoyaltyCards app
• Setup in 60 Seconds - Start issuing cards immediately

PERFECT FOR

• Coffee shops and cafes
• Restaurants and food trucks
• Retail stores and boutiques
• Salons and spas
• Farmers markets and pop-ups
• Any small business wanting loyal customers

HOW IT WORKS

1. Configure your stamp card (business name, stamps required)
2. Show customers your QR code
3. They scan with LoyaltyCards app (free download)
4. Issue stamps each visit with one scan
5. Scan their redemption QR when card is complete

SIMPLE & SECURE MODES

• Simple Mode: Fast stamp issuance (trust-based, like physical cards)
• Secure Mode: Cryptographically signed stamps (fraud-proof digital signatures)

MULTI-DEVICE SUPPORT

Run your loyalty program across multiple devices:
• Backup your configuration with one QR scan
• Clone to new devices (registers, iPads, staff phones)
• All devices issue stamps for the same program

SIMPLE COUNTERS, BY DESIGN

Track the basics without invasive tracking:
• Lifetime totals for cards issued, stamps given, and redemptions
• No customer profiles, no behavior tracking, nothing to mine
• Deliberately simple - because we never collect the customer data a fuller dashboard would require in the first place

PRIVACY FOCUSED

Unlike traditional loyalty systems, you don't collect customer emails, phone numbers, or personal information. Customers appreciate the privacy, you avoid GDPR complexity.

NO ONGOING COSTS

Other loyalty systems charge:
• $29-$199/month subscriptions
• Per-transaction fees
• Setup fees
• Customer data storage fees

LoyaltyCards Business: Completely free, zero ongoing costs.

*Note: Customers need the free LoyaltyCards app to collect stamps.

Download LoyaltyCards Business and start building customer loyalty today!
```

**Keywords (100 chars max):**
```
loyalty program,small business,coffee shop,rewards,stamps,qr code,point of sale,customer retention
```

---

### 📸 Screenshots & App Previews

**Corrected requirement (2026-07-20):** the 6.7"/6.5"/5.5" three-tier system below is Apple's *old* policy. As of 2026, Apple only requires screenshots for the **6.9" display (1320 × 2868 px)** and auto-scales them for every other device size. See [`SCREENSHOT_CAPTURE_PLAN_v1_0_2_8.md`](SCREENSHOT_CAPTURE_PLAN_v1_0_2_8.md) for the corrected plan and sourcing. Total requirement: **5 screenshots per app (10 total), not 30.** Capturing on a physical iPhone 16 Pro Max (native 1320×2868 resolution), not a simulator.

#### Customer App Screenshots — 6.9" Display, 1320 × 2868 px

- [x] Screenshot 1: Wallet home with active loyalty cards
- [x] Screenshot 2: Card detail showing stamps collected
- [x] Screenshot 3: QR scanner ready to collect stamp (background blurred to remove real-world desk/keyboard content — see capture plan for method)
- [x] Screenshot 4: Redemption confirmation dialog (Express Mode's honesty/trust-based redemption — accurate to the actual flow, not a QR-display screen)
- [x] Screenshot 5: Card Detail scrolled to Stamp History

**Note (2026-07-20):** screen 5 originally said "Transaction history," assuming a Settings-level history screen. That screen was deliberately removed from the app on 2026-07-03 (`6f1ce7a`) — the only history view that exists is the per-card Stamp History shown here. See `docs/deployment/SCREENSHOT_CAPTURE_PLAN_v1_0_2_8.md` for full detail.

#### Supplier App Screenshots — 6.9" Display, 1320 × 2868 px

- [x] Screenshot 1: Business configuration/home screen
- [x] Screenshot 2: Issue card QR code
- [x] Screenshot 3: Stamp issuance screen
- [x] Screenshot 4: Recovery backup screen
- [x] Screenshot 5: Clone-to-another-device screen

**Note (2026-07-20):** the original plan called for a "Business analytics dashboard" screenshot, but there is no dashboard screen — the app only shows 3 lifetime counters (Issued/Stamped/Redeemed) inline on the home screen header, and only in Secure Mode. Swapped for a second backup/clone screenshot instead, since that feature works in both modes and doesn't require a Secure Mode setup detour just for a screenshot. See `docs/deployment/SCREENSHOT_CAPTURE_PLAN_v1_0_2_8.md` for the corrected shot list.

**All 10 screenshots captured, QA'd, and staged locally** in `screenshots/customer_app/` and `screenshots/supplier_app/` (2026-07-20) — not yet uploaded to App Store Connect.

**iPad:** optional, only needed if the app targets iPad as a distinct experience — not currently planned, skip unless that changes.

---

### 🎨 App Icon

- [x] **Icon files included** in Xcode asset catalog — 37 PNGs per app in `Assets.xcassets/AppIcon.appiconset/`, sizes 16px–1024px, verified present
- [x] **All required sizes present** (20pt - 1024pt)
- [x] **1024x1024 App Store icon has no transparency** — **fixed 2026-07-20:** all 74 icon files (37 × 2 apps) had an alpha channel, which Apple's App Store Connect hard-rejects on the large icon upload. Flattened to opaque via a PNG→JPEG(q100)→PNG round-trip through `sips` (mechanical fix, no visible change — verified by direct visual comparison before/after on both apps' 1024px icons). All 74 files confirmed `hasAlpha: no` after the fix, dimensions unchanged.
- [ ] **Icon follows guidelines** (no iOS UI elements) — ⚠️ minor, non-blocking: the source artwork has rounded corners and a drop shadow baked in (visible in both apps' icons) rather than being a plain edge-to-edge square; Apple applies its own corner mask on top regardless, so this isn't a rejection risk the way the alpha channel was, but it's not best practice either. Not fixed — would require new source art, out of scope for this pass.
- [x] **Customer & Supplier icons visually distinct** — orange wallet-with-cards (Customer) vs. orange QR-code-with-badge (Supplier), visually confirmed

---

### 📋 App Information

#### Age Rating Questionnaire

Answers decided (all consistent with actual app content), still need entering into ASC's questionnaire UI:

- [x] **Unrestricted Web Access:** No
- [x] **Alcohol, Tobacco, Drugs:** None
- [x] **Profanity or Crude Humor:** None
- [x] **Sexual Content or Nudity:** None
- [x] **Cartoon or Fantasy Violence:** None
- [x] **Realistic Violence:** None
- [x] **Medical/Treatment Information:** None
- [x] **Gambling:** None (loyalty stamps not considered gambling)
- [x] **Horror/Fear Themes:** None
- [ ] Entered into App Store Connect's actual questionnaire (both apps)

**Expected Rating:** 4+ (all ages)

---

#### Privacy Policy

- [x] **Privacy Policy URL:** live — https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html
  - Source: [docs/legal/PRIVACY_POLICY.md](../legal/PRIVACY_POLICY.md)
- [x] **Privacy Policy content accurate** — reviewed 2026-07-20, stale "Save to Photos" reference removed
- [x] **No data collection statement** clearly stated
- [x] **GDPR compliant** (privacy-first design)
- [ ] Paste this URL into App Store Connect (App Privacy section, both apps)

---

#### Terms of Service

- [x] **Terms of Service URL:** live — https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html
  - Source: [docs/legal/TERMS_OF_SERVICE.md](../legal/TERMS_OF_SERVICE.md)
- [x] **Terms cover both customer and supplier use**
- [x] **Fraud prevention disclaimers included**
- [x] **Liability/data-integrity disclaimers strengthened** (2026-07-20) — explicit "not liable for user input errors or falsified data" language, and an explicit statement that suppliers (not LoyaltyCards) are responsible for verifying presented card/stamp data before issuing rewards, same standard as a paper card
- [ ] Paste this URL into App Store Connect (both apps)

---

#### Support URL

- [x] **Support URL:** live — https://ian-hamlet.github.io/LoyaltyCards/support/
- [x] **Support contact method** — ian.hamlet@dotconnected.com; monitoring cadence still needs to be a real daily habit once live, not just documented
- [ ] Paste this URL into App Store Connect (both apps)

---

#### Marketing URL

- [ ] **Marketing URL:** Optional. Could point to https://ian-hamlet.github.io/LoyaltyCards/ (the new landing page) or be left blank — decide before submission

---

### 🔐 Export Compliance

Answers decided (see also `APP_REVIEW_PACKET_v1_0_2_8.md`):

- [x] **App uses encryption:** YES
  - ECDSA P-256 signatures (pointycastle)
  - SHA-256 hashing (crypto)
- [x] **Encryption is:** Exempt (standardized encryption, no proprietary algorithms)
- [x] **CCATS required:** NO (exempt under streamlined encryption)

**Recommended Answer:**
- Uses standard encryption (AES, RSA, ECDSA)
- No proprietary encryption
- Qualifies for Encryption Registration exemption

**Incident (2026-07-21):** the manual App Store Connect encryption question was initially answered incorrectly ("No encryption") on the first upload of v1.0.2+8 — factually wrong given the ECDSA/SHA-256 usage above. Root cause: neither app's `Info.plist` declared `ITSAppUsesNonExemptEncryption`, so Xcode/Transporter prompted for a manual answer on every upload instead of self-declaring. **Fixed:** added `ITSAppUsesNonExemptEncryption = false` (the correct value, since the app's encryption qualifies for exemption) to both `Info.plist` files. This makes future uploads self-declare correctly with no manual prompt.

- [x] **Info.plist fix applied** (both apps) — `ITSAppUsesNonExemptEncryption = false`
- [ ] **Rebuild and re-upload both apps** so the corrected declaration actually applies to the uploaded build (the plist fix only affects builds compiled after the change — the already-uploaded build still carries the wrong answer until replaced)
- [ ] **Export Compliance documentation** confirmed correct in App Store Connect (both apps) after re-upload

---

### 📞 Contact Information

- [x] **First Name:** Ian
- [x] **Last Name:** Hamlet
- [x] **Phone Number:** 07968135909
- [x] **Email Address:** ian.hamlet@dotconnected.com
- [x] **Demo Account:** Not applicable (no backend/accounts)

---

### 💰 Pricing & Availability

**Decided 2026-07-20:** both apps are Free. (Resolves the earlier conflict between `APP_STORE_MATERIALS_EXECUTION_TRACKER.md`, which recorded Free, and `V1_0_0_APP_STORE_LAUNCH_PLAN.md`, which had suggested a paid Supplier app — neither was ever actually set in App Store Connect. Marketing copy elsewhere in this document updated to match: "one-time purchase" language removed.)

#### Customer App
- [x] **Price:** Free (no In-App Purchases) — decided, not yet set in ASC
- [ ] **Availability:** All countries/regions
- [ ] **Release Date:** Automatic or manual release (choose one)

#### Supplier App
- [x] **Price:** Free (no In-App Purchases) — decided, not yet set in ASC
- [ ] **Availability:** All countries/regions
- [ ] **Release Date:** Automatic or manual release

---

### 🧪 App Review Information

#### Demo Instructions for Reviewers

**Customer App:**
```
HOW TO TEST:

1. Install both apps: "LoyaltyCards" (customer) and "LoyaltyCards Business" (supplier)

2. Configure Supplier App:
   - Open LoyaltyCards Business
   - Tap "Create New Business"
   - Business name: "Test Coffee Shop"
   - Stamps required: 5
   - Choose any color and icon
   - Mode: Simple Mode (easier testing)
   - Tap "Create Business"

3. Issue a Card to Customer:
   - In Supplier App, main screen shows "Issue Card" button
   - Tap "Issue Card"
   - Supplier app displays QR code
   - Switch to Customer app (LoyaltyCards)
   - Tap "Scan QR Code"
   - Scan the QR code from Supplier app (or screenshot and scan from Photos)
   - Card appears in Customer app

4. Add Stamps:
   - In Customer app, tap the card
   - Tap "Collect Stamp" button
   - Customer app displays QR code
   - Switch to Supplier app
   - Tap "Stamp Card" button
   - Choose "3 stamps" from picker
   - Tap "Generate Stamp QR"
   - Scan the customer's QR code with Supplier app
   - Stamps appear on customer's card

5. Redeem Card:
   - Repeat step 4 until card has 5/5 stamps
   - In Customer app, card shows "Ready to Redeem"
   - Tap card, tap "Show Redemption QR"
   - In Supplier app, tap "Redeem Card"
   - Scan customer's redemption QR
   - Card marked complete

NO NETWORK REQUIRED - All features work offline.
NO ACCOUNT REQUIRED - No login, signup, or personal information.
```

**Supplier App:**
```
See Customer App testing instructions above - both apps work together.

Additional Supplier Features:

MULTI-DEVICE BACKUP:
- Settings → Create Recovery Backup
- Displays QR code (biometric auth required on physical device)
- Can scan this QR on another device to clone configuration

ANALYTICS:
- Main screen shows statistics
  - Cards issued
  - Unique cards stamped
  - Total stamps given
  - Total redemptions
```

---

#### Contact Information for App Review

- [x] **Phone Number:** 07968135909
- [x] **Email Address:** ian.hamlet@dotconnected.com (checked daily during review — commit to this before submitting)
- [x] **Notes for Reviewers:**
```
This is a peer-to-peer (P2P) digital loyalty card system. No backend servers, no user accounts, no data collection.

Both apps (Customer and Supplier) work together via QR code scanning.

Biometric authentication (Face ID) only triggers on physical devices for sensitive operations. Simulator testing may show passcode fallback.

All features work offline. No internet connection required.

Please test both apps together following the demo instructions.
```

---

### ✅ Technical Requirements

- [ ] **iOS Minimum Version:** 13.0+ (confirmed in Info.plist)
- [ ] **Supported Devices:** iPhone, iPad
- [ ] **Supported Orientations:** Portrait (primary), landscape (supported)
- [ ] **App performs as expected** on all device sizes
- [ ] **No crashes during testing**
- [ ] **All UI elements accessible** (not cut off)
- [ ] **Loading states implemented** for all async operations
- [ ] **Error messages user-friendly** (not developer jargon)
- [ ] **Permissions requested with clear explanation:**
  - Camera (QR scanning): "Scan QR codes to collect stamps"
  - Face ID (Supplier only): "Authenticate to view private keys"
  - None required (all backup methods use standard iOS share sheet)

---

### 🔍 App Review Guidelines Compliance

#### Functionality
- [x] **App is complete** (not a demo or trial) — all core P2P flows implemented per DEFECT_TRACKER.md
- [x] **App is functional** (no placeholder content) — grepped both apps' screens for beta/placeholder/TODO-style text, none found
- [x] **No beta/test references** in UI or marketing text — verified 2026-07-20 via grep, none found
- [ ] **Buttons and features work as described** — needs the physical-device regression pass

#### Performance
- [ ] **App doesn't crash** during normal use — needs physical-device regression pass (cannot verify statically)
- [ ] **No memory leaks** detected — needs physical-device regression pass
- [ ] **Launch time < 3 seconds** — needs physical-device regression pass
- [ ] **Smooth scrolling** on all supported devices — needs physical-device regression pass

#### Business Model
- [x] **Business model clear** — both apps free, decided 2026-07-20
- [x] **No hidden costs** — nothing to purchase
- [x] **No subscription, no purchase at all** — fully free

#### Design
- [x] **Follows iOS design guidelines** — standard Flutter Material widgets throughout
- [x] **Native iOS look and feel**
- [x] **Consistent UI throughout**
- [x] **Dark mode support** — both apps follow system light/dark appearance (`ThemeMode.system`, real distinct ColorScheme objects); the specific text-legibility risk was checked and ruled out 2026-07-20 (see `docs/legal/ACCESSIBILITY_STATEMENT.md`). Some branded badges keep a fixed light background in dark mode — a style inconsistency, not a functional gap, and doesn't block submission.

#### Legal
- [x] **Privacy policy accurate** and accessible — live at https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html, reviewed 2026-07-20
- [x] **Terms of service** available — live at https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html, strengthened 2026-07-20
- [x] **No copyright infringement** (all content original or licensed)
- [x] **Complies with export regulations** — standard cryptography only, see Export Compliance section above

---

### 📦 Pre-Submission Final Checks

- [ ] **Run full regression test** on physical device
- [ ] **Test on oldest supported iOS** (iOS 13.0)
- [ ] **Test on smallest screen** (iPhone SE)
- [ ] **Test on largest screen** (iPhone Pro Max)
- [ ] **Test on iPad** (if supported)
- [ ] **Verify all QR scanning scenarios** work
- [ ] **Verify biometric auth** works (physical device only)
- [ ] **Test offline functionality** (airplane mode)
- [ ] **Review all error messages** for clarity
- [ ] **Check all navigation flows**
- [ ] **Verify Settings screens** display correctly
- [ ] **Test backup/restore** (Supplier app)
- [ ] **Verify privacy policy link** works

---

### 🚀 Submission Process

1. [ ] **Upload build to App Store Connect** (via Transporter)
2. [ ] **Select build** for Customer app submission
3. [ ] **Select build** for Supplier app submission
4. [ ] **Complete all required fields** in App Store Connect
5. [ ] **Upload screenshots** for all required device sizes
6. [ ] **Submit for review** (both apps simultaneously recommended)
7. [ ] **Monitor review status** (typically 24-48 hours)
8. [ ] **Respond to App Review** if questions arise (24-hour response time)
9. [ ] **Release approved apps** (manual or automatic)

---

### 📊 Post-Submission

- [ ] **Monitor App Store Connect** for review updates
- [ ] **Check email** for App Review messages
- [ ] **Prepare response** for potential rejection reasons:
  - Incomplete features → Explain P2P architecture
  - Crashes → Fix and resubmit
  - Missing demo → Provide detailed instructions
  - Privacy concerns → Reference privacy-first design
- [ ] **Plan for Day 1 support** inquiries
- [ ] **Monitor crash reports** in App Store Connect
- [ ] **Track download statistics**
- [ ] **Collect user feedback** for next update

---

### 🔄 Common Rejection Reasons & Mitigations

**"App requires both apps to function"**
- Mitigation: Customer app description clearly states "Works with LoyaltyCards Business"
- Response: "This is a two-sided marketplace (customers + suppliers), similar to Uber (riders + drivers)"

**"No backend/server"**
- Mitigation: Explain P2P architecture in review notes
- Response: "Peer-to-peer architecture, similar to AirDrop. No backend required."

**"Incomplete functionality in simulator"**
- Mitigation: Note that biometric auth requires physical device
- Response: "Face ID authentication requires physical device. All other features testable in simulator."

**"Privacy concerns"**
- Mitigation: Reference VULNERABILITIES.md and privacy-first design
- Response: "Zero data collection. No user accounts, emails, phone numbers, or tracking. Complete privacy."

---

## Quick Reference: Required URLs

All live as of 2026-07-20, hosted via GitHub Pages (see `.github/workflows/pages.yml` + `site/`):

1. **Privacy Policy:** https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html
   - Source: [docs/legal/PRIVACY_POLICY.md](../legal/PRIVACY_POLICY.md)
2. **Terms of Service:** https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html
   - Source: [docs/legal/TERMS_OF_SERVICE.md](../legal/TERMS_OF_SERVICE.md)
3. **Support:** https://ian-hamlet.github.io/LoyaltyCards/support/
   - Source: [docs/legal/SUPPORT_PAGE.md](../legal/SUPPORT_PAGE.md)
4. **Accessibility Statement** (not an ASC field, linked from the site): https://ian-hamlet.github.io/LoyaltyCards/legal/accessibility-statement.html
5. **Marketing (optional):** https://ian-hamlet.github.io/LoyaltyCards/ — decide whether to use this or leave blank

**Note:** the published HTML in `site/` was hand-converted from the Markdown sources above and is not auto-generated — any future edits to the Markdown need to be mirrored into the matching `site/**/*.html` file.

---

**Document Status:** 🟢 Ready for submission mechanics — legal/support infrastructure, all decisions (pricing: both apps Free, contact phone, copyright), and all 10 screenshots (captured, QA'd, staged locally) are done. The app has been running in TestFlight/demos for a while, so this phase is submission prep, not first-time validation — a final sanity pass on the actual build going up is still sensible but isn't a separate blocker. What's left is mechanical: confirm actual App Store Connect state (app records, Developer Program status), create the release branch, build/upload the IPAs, enter metadata + screenshots into ASC, and submit.  
**Maintained by:** Development Team  
**Last Updated:** July 20, 2026

---

**References:**
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Beta Testing Guide](https://developer.apple.com/testflight/)
