# App Store Submission Checklist

**LoyaltyCards v2.0.2+21**  
**Customer App:** LoyaltyCards - Digital Stamps  
**Supplier App:** LoyaltyCards Business  
**Target Release:** 🟢 LIVE ON THE APP STORE  
**Last Updated:** August 10, 2026

**Status note:** 🟢 **v2.0.2+21 passed App Review and is now publicly available on the App Store** (both apps) — the project's first public release. v2.0.0+19 was submitted 2026-07-28 and rejected for CRASH-001, a native crash tapping Print on the supplier app's Stamp Setup screen (full writeup: `docs/project-management/CRASH-001-stamp-print-race-condition.md`). v2.0.1+20 was prepared to fix it but never uploaded — Transporter flagged its `IPHONEOS_DEPLOYMENT_TARGET = 13.0` before the upload completed. v2.0.2+21 carried both the CRASH-001 fix and the deployment-target fix, and is what shipped. Metadata used for this version: `APP_STORE_METADATA_PACKET_v2_0_2_21.md`. This checklist is now historical - see "Post-Submission" below for what's next now that the app is live.

**Version history since v1.0.3+11** (the version this checklist was previously verified against): v1.6.0+16/+17 added app-wide biometric lock to the supplier app and required device auth before committing a business restore/clone, merged into `develop` via `feature/uireview`; v2.0.0+18 was a **major version bump** for a breaking QR token format change (new signed fields added during a security review mean pre-review printed QR codes fail signature verification against the new signed data — acceptable since the app has never had real-world users yet); v2.0.0+19 fixed a critical redemption-inflation gap and a repeat-customer lockout bug, renamed "Simple Mode" to "Express Mode" throughout all user-facing copy, and added the App Store metadata/public-site work described below — **submitted 2026-07-28, rejected for CRASH-001**; v2.0.1+20 fixed CRASH-001 (re-entrancy guard + PDF-bytes validation) and a dark-mode contrast bug (UI-001), but was never uploaded; v2.0.2+21 carried the same fixes plus the `IPHONEOS_DEPLOYMENT_TARGET` bump to 15.0 that Transporter required — **passed review and shipped 2026-08-10.**

---

## Pre-Submission Requirements

### ✅ Code & Build Preparation

**v2.0.0+19 (rejected submission, for the record):** all items below were true and checked for that build — final build number, version confirmed, merged to `main` at `02f82c7`, release branch `releases/v2.0.0-build19`, archived, uploaded, submitted 2026-07-28. Rejected for CRASH-001.

**v2.0.2+21 (shipped) — complete:**

- [x] **Final build number incremented** in pubspec.yaml (both apps) — `2.0.2+21`, confirmed in `source/{customer_app,supplier_app,shared}/pubspec.yaml`
- [x] **Version number confirmed** — v2.0.2+21
- [x] **All code merged to `main` branch** — `main`/`develop` equalized at `4004c08`
- [x] **Release branch created** `releases/v2.0.2-build21`
- [x] **Archive builds completed** for v2.0.2+21
  ```bash
  cd source/customer_app
  flutter clean && flutter pub get
  flutter build ipa --release
  
  cd ../supplier_app
  flutter clean && flutter pub get
  flutter build ipa --release
  ```
- [x] **IPA files uploaded to App Store Connect** via Transporter
- [x] **Build processing complete** in App Store Connect
- [x] **All automated tests passing** against current `develop`
- [x] **`flutter analyze` clean**
- [x] **Critical bugs resolved** (CRASH-001 fixed; zero other CRITICAL/HIGH defects open)
- [x] **Submitted for App Store review** — passed, **live on the App Store** as of 2026-08-10

---

### 📱 App Store Connect - Basic Information

#### Customer App: LoyaltyCards - Digital Stamps

- [x] **App Name:** LoyaltyCards - Digital Stamps — confirmed in ASC
- [x] **Bundle ID:** `com.ianhamlet.loyaltycards.customerApp` — registered, verified
- [x] **SKU:** `loyaltycards-customer-001`
- [x] **Primary Language:** English (US)
- [x] **Primary Category:** Lifestyle
- [x] **Secondary Category:** Shopping
- [x] **Content Rights:** confirmed

#### Supplier App: LoyaltyCards Business

- [x] **App Name:** LoyaltyCards Business — confirmed in ASC
- [x] **Bundle ID:** `com.ianhamlet.loyaltycards.supplierApp` — registered, verified
- [x] **SKU:** `loyaltycards-supplier-001`
- [x] **Primary Language:** English (US)
- [x] **Primary Category:** Business
- [x] **Secondary Category:** Productivity
- [x] **Content Rights:** confirmed

---

### 📝 App Descriptions & Marketing

- [x] **Subtitle, Promotional Text, Keywords, Description, App Review Notes, What's New** — see [`APP_STORE_METADATA_PACKET_v2_0_2_21.md`](APP_STORE_METADATA_PACKET_v2_0_2_21.md), the single source of truth for this content (this checklist previously duplicated it inline, which let a stale "Simple Mode" copy drift out of sync — don't re-duplicate it here again). Entered into ASC and live.
- [x] **Marketing URL:** `https://ian-hamlet.github.io/LoyaltyCards/user/about.html` (both apps)

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

**All 10 screenshots captured, QA'd, and staged locally** in `screenshots/customer_app/` and `screenshots/supplier_app/` (2026-07-20), uploaded to App Store Connect and included in the 2026-07-28 submission.

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
- [x] Entered into App Store Connect's actual questionnaire (both apps)

**Expected Rating:** 4+ (all ages)

---

#### Privacy Policy

- [x] **Privacy Policy URL:** live — https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html
  - Source: [docs/legal/PRIVACY_POLICY.md](../legal/PRIVACY_POLICY.md)
- [x] **Privacy Policy content accurate** — reviewed 2026-07-25, added disclosure of the
  hashed device identifier used for Secure Mode redemption fraud-prevention
  (see "Anti-Fraud Device Signal" section) — previously undisclosed, found by
  the App Store Compliance + Legal/Privacy reviews in
  [docs/quality/REVIEW_ROLES.md](../quality/REVIEW_ROLES.md)
- [x] **GDPR compliant** (privacy-first design)
- [x] **App Privacy questionnaire updated for the customer app** — declares **Device ID** (Purpose: App Functionality/fraud prevention, Linked to identity: No, Used for tracking: No), resulting label "Data Not Linked to You" instead of the stale "Data Not Collected". Supplier app's answer is unaffected ("Data Not Collected" remains accurate). Suggested answers were in [APP_REVIEW_PACKET_v1_0_2_8.md](APP_REVIEW_PACKET_v1_0_2_8.md#app-privacy-data-collection-suggested-answers).
- [x] Privacy Policy URL entered in App Store Connect (App Privacy section, both apps)

---

#### Terms of Service

- [x] **Terms of Service URL:** live — https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html
  - Source: [docs/legal/TERMS_OF_SERVICE.md](../legal/TERMS_OF_SERVICE.md)
- [x] **Terms cover both customer and supplier use**
- [x] **Fraud prevention disclaimers included**
- [x] **Liability/data-integrity disclaimers strengthened** (2026-07-20) — explicit "not liable for user input errors or falsified data" language, and an explicit statement that suppliers (not LoyaltyCards) are responsible for verifying presented card/stamp data before issuing rewards, same standard as a paper card
- [x] Entered into App Store Connect (both apps)

---

#### Support URL

- [x] **Support URL:** live — https://ian-hamlet.github.io/LoyaltyCards/support/
- [x] **Support contact method** — ian.hamlet@dotconnected.com; monitoring cadence still needs to be a real daily habit once live, not just documented
- [x] Entered into App Store Connect (both apps)

---

#### Marketing URL

- [x] **Marketing URL:** `https://ian-hamlet.github.io/LoyaltyCards/user/about.html` — the new About page explaining the two-app pairing and Express/Secure Mode with case studies. Entered into ASC for both apps.

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
- [x] **Rebuilt and uploaded both apps** at 2.0.0+19, well after the plist fix — self-declared correctly, no manual encryption prompt appeared on upload
- [x] **Export Compliance documentation** confirmed correct in App Store Connect (both apps)

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
- [x] **Price:** Free (no In-App Purchases) — set in ASC
- [x] **Availability:** All countries/regions
- [ ] **Release Date:** Automatic or manual release (choose one) — decide once review clears

#### Supplier App
- [x] **Price:** Free (no In-App Purchases) — set in ASC
- [x] **Availability:** All countries/regions
- [ ] **Release Date:** Automatic or manual release — decide once review clears

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
   - Mode: Express Mode (easier testing)
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

- [x] **iOS Minimum Version:** 15.0+ (raised from 13.0 on 2026-08-10, `IPHONEOS_DEPLOYMENT_TARGET` in both apps' `project.pbxproj` - Apple requires 15.0+ for all uploads starting Spring 2027, and Transporter had already started flagging 13.0 as a warning)
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
- [x] **Privacy policy accurate** and accessible — live at https://ian-hamlet.github.io/LoyaltyCards/legal/privacy-policy.html, reviewed 2026-07-25 (see the App Store Connect reminder under "Privacy Policy" above — the *policy* is now accurate, but the separately-entered ASC questionnaire still needs updating)
- [x] **Terms of service** available — live at https://ian-hamlet.github.io/LoyaltyCards/legal/terms-of-service.html, strengthened 2026-07-20
- [x] **No copyright infringement** (all content original or licensed)
- [x] **Complies with export regulations** — standard cryptography only, see Export Compliance section above

---

### 📦 Pre-Submission Final Checks

- [ ] **Run full regression test** on physical device
- [ ] **Test on oldest supported iOS** (iOS 15.0)
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

1. [x] **Upload build to App Store Connect** (via Transporter) — build 21
2. [x] **Select build** for Customer app submission — build 21
3. [x] **Select build** for Supplier app submission — build 21
4. [x] **Complete all required fields** in App Store Connect
5. [x] **Upload screenshots** for all required device sizes
6. [x] **Submit for review** — both apps resubmitted after the v2.0.0+19/CRASH-001 rejection
7. [x] **Monitor review status** — passed
8. [x] **Respond to App Review** if questions arise — n/a, resulted in approval
9. [x] **Release approved apps** — **live on the App Store**

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
5. **Marketing:** https://ian-hamlet.github.io/LoyaltyCards/user/about.html — in use, entered in ASC for both apps

**Note:** the published HTML in `site/` was hand-converted from the Markdown sources above and is not auto-generated — any future edits to the Markdown need to be mirrored into the matching `site/**/*.html` file.

---

**Document Status:** 🟢 **v2.0.2+21 is LIVE ON THE APP STORE** (both apps), as of 2026-08-10 — the project's first public release. v2.0.0+19 was rejected for CRASH-001 on 2026-08-05; v2.0.2+21 fixed it (plus a Transporter-flagged deployment-target issue) and passed review. This checklist's job is done for this release cycle — see `RELEASES.md` for the release-branch record and `docs/project-management/CRASH-001-stamp-print-race-condition.md` for the crash fix and its ongoing App Store Connect crash-monitoring follow-up.  
**Maintained by:** Development Team  
**Last Updated:** August 10, 2026

---

**References:**
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Beta Testing Guide](https://developer.apple.com/testflight/)
