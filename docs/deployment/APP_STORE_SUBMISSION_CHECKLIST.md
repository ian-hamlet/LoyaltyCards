# App Store Submission Checklist

**LoyaltyCards v2.1.1+29**  
**Customer App:** LoyaltyCards Customer Wallet  
**Supplier App:** LoyaltyCards Business  
**Target Release:** 🟡 v2.1.1+29 in progress - v2.0.3+23 live but defective; v2.1.0+26, v2.1.0+27, and v2.1.1+28 all shipped to TestFlight but none has the TEST-022 fix  
**Last Updated:** August 17, 2026

**Status note:** 🟢 **v2.0.2+21 was live on the App Store** (shipped 2026-08-10 — see prior status below for that history), now superseded. 🟢 **v2.0.3+23 was submitted 2026-08-15, approved and released 2026-08-16** (both apps) - the Sharing feature and both bug fixes are confirmed working. Metadata from `APP_STORE_METADATA_PACKET_v2_0_3_23.md` entered into ASC, build 23 selected on both apps, Release was set to **Manual** on both (the two apps review at different speeds, so release was held until both were approved). **⚠️ This live build contains TEST-016** (businesses with 3 or 4 required stamps can't issue a valid card) - see `docs/project-management/DEFECT_TRACKER.md`. 🟡 **v2.1.0+26 fixed TEST-016 plus TEST-017 through TEST-020 and was built and uploaded to TestFlight**, but not submitted for App Store review before TEST-021 was found on that same TestFlight build - see `docs/project-management/DEFECT_TRACKER.md` TEST-021. 🟢 **v2.1.0+27 added TEST-021 and was built and uploaded to TestFlight** the night of 2026-08-16/17. 🟢 **v2.1.1+28 added DECISION-017 and was also built and uploaded to TestFlight**, real-device verified end-to-end - but that same testing round found TEST-022 (see below). 🟡 **v2.1.1+29 (current target) adds the TEST-022 fix** - build-only bump, not yet built/uploaded/submitted, since Apple won't allow re-uploading build 28 with different content. v2.0.4+24 and the interim test build v2.0.4+25 are both folded into the v2.1.x line and were never their own release candidates.

**Version history since v1.0.3+11** (the version this checklist was previously verified against): v1.6.0+16/+17 added app-wide biometric lock to the supplier app and required device auth before committing a business restore/clone, merged into `develop` via `feature/uireview`; v2.0.0+18 was a **major version bump** for a breaking QR token format change (new signed fields added during a security review mean pre-review printed QR codes fail signature verification against the new signed data — acceptable since the app has never had real-world users yet); v2.0.0+19 fixed a critical redemption-inflation gap and a repeat-customer lockout bug, renamed "Simple Mode" to "Express Mode" throughout all user-facing copy, and added the App Store metadata/public-site work described below — **submitted 2026-07-28, rejected for CRASH-001**; v2.0.1+20 fixed CRASH-001 (re-entrancy guard + PDF-bytes validation) and a dark-mode contrast bug (UI-001), but was never uploaded; v2.0.2+21 carried the same fixes plus the `IPHONEOS_DEPLOYMENT_TARGET` bump to 15.0 that Transporter required — **passed review and shipped 2026-08-10**; v2.0.3+22 added the App Store Category/Subtitle corrections found post-launch but never produced an uploaded build; v2.0.3+23 added the Sharing feature (Tell a Business / Tell a Friend, both apps) plus two bug fixes found during TestFlight-prep testing (Express Mode stamp routing, a false error on opening Clone/Recovery Backup screens) — **built, uploaded, TestFlight-tested, submitted for App Store review 2026-08-15, and approved and released 2026-08-16**, but contains TEST-016 (see below); v2.0.4+24 fixed TEST-016 but never shipped - folded into v2.1.0+26; v2.1.0+26 carried TEST-016 forward and added the real fix for a QR-capacity failure found while testing it (TEST-017: redemption QR could silently fail to render at high stamp counts; TEST-018: a related stamp-provenance bug found along the way; TEST-019: a clearer error message for an affected business; TEST-020: the actual fix - compact gzip+Base45+alphanumeric-mode QR encoding, raising the safe stamps-required ceiling from 10 to 12) - **minor version bump (2.0.4 -> 2.1.0), deliberate given the real capability increase** - **built and uploaded to TestFlight**, where TEST-021 was then found (the same QR-capacity failure, never fixed on the issue-card side); v2.1.0+27 added that fix and was itself built and uploaded to TestFlight; v2.1.1+28 added DECISION-017 (self-service recovery for an out-of-range business, closing the gap TEST-019 left open) - **patch version bump** - built and uploaded to TestFlight, real-device verified end-to-end, where that same testing surfaced TEST-022 (a cross-version compatibility regression from TEST-021); v2.1.1+29 (current) adds that fix - **build-only bump**, in progress.

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

**v2.0.3+23 (live on the App Store, superseded by v2.1.0+26) — complete, but contains TEST-016:**

- [x] **Final build number incremented** in pubspec.yaml (both apps) — `2.0.3+23`, confirmed in `source/{customer_app,supplier_app,shared}/pubspec.yaml`
- [x] **Version number confirmed** — v2.0.3+23 (version 2.0.3 unchanged from +22, build bumped only)
- [x] **All code merged to `main` branch** — `main`/`develop`/`releases/v2.0.3-build23` all equalized
- [x] **Release branch created** `releases/v2.0.3-build23`
- [x] **Archive builds completed** for v2.0.3+23 — built via `source/build_both_apps.sh`, both IPAs verified (valid zip, correct 2.0.3/23 embedded in Info.plist)
- [x] **IPA files uploaded to App Store Connect** via Transporter
- [x] **Build processing complete** in App Store Connect
- [x] **TestFlight testing completed** — Sharing feature and both bug fixes confirmed working on-device
- [x] **All automated tests passing** (shared 160, customer 128, supplier 80)
- [x] **`flutter analyze` clean**
- [x] **Critical bugs resolved (at submission time)** — both TestFlight-prep bugs fixed; TEST-016 not yet discovered, found afterward and is present in this live build
- [x] **Metadata entered into App Store Connect** — Category, Subtitle, Description, What's New, App Review Notes from `APP_STORE_METADATA_PACKET_v2_0_3_23.md` entered for both apps (also caught the customer app's Promotional Text, which turned out to be blank in ASC despite being documented as already-live)
- [x] **Submitted for App Store review** — both apps submitted 2026-08-15, Release set to Manual on both
- [x] **Approved and released** — approved by Apple and released 2026-08-16, live on the App Store
- ⚠️ **Contains TEST-016** — businesses with 3 or 4 required stamps can't issue a valid card. Fix in progress as v2.1.0+26 - build, test, and submit as soon as possible.

**v2.0.4+24 (superseded by v2.1.0+26, never built or uploaded):**

- TEST-016 fix only, folded into v2.1.0+26 below along with the interim test-only build v2.0.4+25. See v2.1.0+26 for the current checklist state.

**v2.1.0+26 (shipped to TestFlight, superseded by v2.1.0+27 for submission):**

- [x] **Final build number incremented** in pubspec.yaml (both apps) — `2.1.0+26` at the time
- [x] **Version number confirmed** — v2.1.0+26 (minor version bump from 2.0.4 -> 2.1.0, deliberate - see Version history above)
- [x] **All fixes complete on branch** `fix/TEST-017-redemption-qr-overflow` — TEST-016 (carried forward), TEST-017, TEST-018, TEST-019, TEST-020
- [x] **All code merged to `develop`** — 2026-08-16 (`c7b8e63`)
- [x] **Archive builds completed, IPA files uploaded to App Store Connect, build processing complete** — ⚠️ happened outside this checklist's tracked workflow (no record here of exactly when/how, or whether `develop` was merged to `main`/a release branch first) - confirmed only by the user testing against the live TestFlight build 2026-08-17
- [x] **Physical-device verification completed, including via this actual TestFlight build** — a 12-stamp Secure Mode card with 100% of its stamps arrived via overflow relocation redeems successfully (TEST-017/020, the worst case - see the engineered-scenario recipe in `docs/project-management/DEFECT_TRACKER.md` TEST-020); a 3/4-stamp business issues a working card end-to-end (TEST-016, confirmed 2026-08-17); the 20-stamp legacy business's Issue Card QR correctly shows the specific "supported range: 3-12" message (TEST-019) rather than a generic error, confirmed 2026-08-17; Express Mode spot-checked, no regressions; Recovery Backup restore onto a new Secure Mode business confirmed working.
- [x] **All automated tests passing** (shared 201, customer 131, supplier 81 at the time)
- [x] **`flutter analyze` clean**
- ⚠️ **Missing TEST-021** (found via this build's own TestFlight testing, afterward) — **do not submit this build for App Store review.** See v2.1.1+29 below.

**v2.1.0+27 (shipped to TestFlight, superseded by v2.1.1+29 for submission):**

- TEST-021 fix only, committed to git (`505d5f9`) and built/uploaded to TestFlight the night of 2026-08-16/17. Missing DECISION-017 and TEST-022, both added afterward. **Should not be submitted for App Store review as-is.**

**v2.1.1+28 (shipped to TestFlight, superseded by v2.1.1+29 for submission):**

- [x] **Final build number incremented** in pubspec.yaml (both apps) — `2.1.1+28` at the time
- [x] **Version number confirmed** — v2.1.1+28 (patch version bump from 2.1.0 - not build-only, since DECISION-017 is a genuine UX improvement; supersedes v2.1.0+27, which shipped TEST-021 alone to TestFlight)
- [x] **All fixes complete on this build** — TEST-016 through TEST-021 plus DECISION-017, on top of `fix/TEST-017-redemption-qr-overflow`'s prior work
- [x] **All code merged to `develop`** — TEST-016 through TEST-020 at 2026-08-16 (`c7b8e63`); TEST-021 at 2026-08-17 (`505d5f9`); DECISION-017 committed 2026-08-17 (`b467bae`)
- [x] **Archive builds completed, IPA files uploaded to App Store Connect, build processing complete** — ⚠️ happened outside this checklist's tracked workflow - confirmed by the user actively testing against the live TestFlight build
- [x] **Physical-device verification completed, including via this actual TestFlight build** — see v2.1.0+26 above for TEST-016/017/019/020; DECISION-017 real-device verified end-to-end across both matched (28/28) and mismatched (28/23) supplier/customer pairs - full log in `docs/testing/DECISION-017_LEGACY_BUSINESS_TEST_PLAN.md`
- [x] **All automated tests passing** (shared 211, customer 131, supplier 82 at the time)
- [x] **`flutter analyze` clean**
- ⚠️ **Missing TEST-022** (found via this build's own real-device testing, afterward - a cross-version compatibility regression TEST-021 introduced) — **do not submit this build for App Store review.** See v2.1.1+29 below.

**v2.1.1+29 (current) — in progress:**

- [x] **Final build number incremented** in pubspec.yaml (both apps) — `2.1.1+29`, confirmed in `source/{customer_app,supplier_app,shared}/pubspec.yaml`
- [x] **Version number confirmed** — v2.1.1+29 (build-only bump from 2.1.1 - not a version change, since this is a bug fix, not a new capability; supersedes v2.1.1+28, since Apple won't allow re-uploading build 28 with different content)
- [x] **All fixes complete** — TEST-016 through TEST-022 plus DECISION-017, on top of `fix/TEST-017-redemption-qr-overflow`'s prior work
- [x] **All code merged to `develop`** — TEST-016 through DECISION-017 as above; TEST-022 fix and this version bump pending commit as of this writing
- [ ] **`develop` merged to `main` branch**
- [ ] **Release branch created** `releases/v2.1.1-build29`
- [ ] **Archive builds completed** for v2.1.1+29 — use `source/build_both_apps.sh`
- [ ] **IPA files uploaded to App Store Connect** via Transporter
- [ ] **Build processing complete** in App Store Connect
- [x] **Physical-device verification completed** — see above for TEST-016 through DECISION-017; TEST-022 is automated-test verified (new widget tests in `supplier_issue_card_test.dart` confirming plain-JSON preference for both an ordinary in-range business and a freshly-reconfigured one) but not yet separately physical-device confirmed, since the fix was made after the TestFlight round that found it.
- [ ] **TestFlight testing completed for TEST-022 specifically** — needs a build that actually includes it, which doesn't exist yet.
- [x] **All automated tests passing** (shared 211, customer 131, supplier 83)
- [x] **`flutter analyze` clean**
- [x] **Critical bugs resolved** (TEST-016/017/018/019/021/022 fixed, TEST-020 supersedes TEST-017's interim mitigation, DECISION-017 closes the backward-compatibility gap TEST-019 left open; zero other CRITICAL/HIGH defects open)
- [ ] **Metadata entered into App Store Connect** — What's New only, from `APP_STORE_METADATA_PACKET_v2_1_1_29.md`; all other fields unchanged from v2.0.3+23 and already live
- [ ] **Submitted for App Store review**
- [ ] **v2.0.3+23 status** — already approved and released 2026-08-16; superseding it with this build is the priority now that the defect is live

---

### 📱 App Store Connect - Basic Information

#### Customer App: LoyaltyCards Customer Wallet

- [x] **App Name:** LoyaltyCards Customer Wallet — confirmed correct 2026-08-15, matches ASC
- [x] **Bundle ID:** `com.ianhamlet.loyaltycards.customerApp` — registered, verified
- [x] **SKU:** `loyaltycards-customer-2026` — corrected 2026-08-10 to match live ASC value (previously documented, incorrectly, as `loyaltycards-customer-001`)
- [x] **Primary Language:** English (UK) — corrected 2026-08-10 to match ASC (previously documented, incorrectly, as English (US))
- [x] **Primary Category:** Lifestyle — entered on the v2.0.3+23 version page 2026-08-15 (was Food & Drink)
- [x] **Secondary Category:** Shopping
- [x] **Content Rights:** confirmed

#### Supplier App: LoyaltyCards Business

- [x] **App Name:** LoyaltyCards Business — confirmed in ASC, matches
- [x] **Bundle ID:** `com.ianhamlet.loyaltycards.supplierApp` — registered, verified
- [x] **SKU:** `loyaltycards-supplier-2026` — corrected 2026-08-10 to match live ASC value (previously documented, incorrectly, as `loyaltycards-supplier-001`)
- [x] **Primary Language:** English (UK) — corrected 2026-08-10 to match ASC (previously documented, incorrectly, as English (US))
- [x] **Primary Category:** Business — entered on the v2.0.3+23 version page 2026-08-15 (was Food & Drink)
- [x] **Secondary Category:** Productivity
- [x] **Content Rights:** confirmed

---

### 📝 App Descriptions & Marketing

- [x] **Subtitle** — entered for both apps 2026-08-15 - see [`APP_STORE_METADATA_PACKET_v2_0_3_23.md`](APP_STORE_METADATA_PACKET_v2_0_3_23.md)
- [x] **Promotional Text, Keywords, Description, App Review Notes, What's New** — entered for both apps 2026-08-15, see [`APP_STORE_METADATA_PACKET_v2_0_3_23.md`](APP_STORE_METADATA_PACKET_v2_0_3_23.md). The customer app's Promotional Text was found blank in ASC despite being documented as already-live - worth remembering that "unchanged" in this doc doesn't guarantee it's actually live, always verify in ASC directly.
- [x] **Marketing URL:** `https://ian-hamlet.github.io/LoyaltyCards/user/about.html` (both apps) — unchanged, already correct

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
- [ ] **Release Date:** ⚠️ **Set to MANUAL release, not automatic.** The two apps are separate ASC submissions and routinely clear review at different speeds - if either is set to automatic release, it can go live while the other is still "In Review," which is a bad state for a paired system (e.g. a customer downloading the Sharing feature's "Tell a Business" flow before the Supplier app it points to has updated). Manual release lets you hold both approved builds and release them together once *both* have passed review.

#### Supplier App
- [x] **Price:** Free (no In-App Purchases) — set in ASC
- [x] **Availability:** All countries/regions
- [ ] **Release Date:** ⚠️ **Same as above - set to MANUAL release**, so this app doesn't go live before the Customer app (or vice versa) if their review times diverge.

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

**v2.0.2+21 (shipped) — complete:**

1. [x] **Upload build to App Store Connect** (via Transporter) — build 21
2. [x] **Select build** for Customer app submission — build 21
3. [x] **Select build** for Supplier app submission — build 21
4. [x] **Complete all required fields** in App Store Connect
5. [x] **Upload screenshots** for all required device sizes
6. [x] **Submit for review** — both apps resubmitted after the v2.0.0+19/CRASH-001 rejection
7. [x] **Monitor review status** — passed
8. [x] **Respond to App Review** if questions arise — n/a, resulted in approval
9. [x] **Release approved apps** — **live on the App Store**

**v2.0.3+23 (live on the App Store, superseded by v2.1.1+29) — complete, but contains TEST-016:**

1. [x] **Upload build to App Store Connect** (via Transporter) — build 23, both apps
2. [x] **Select build** for Customer app submission — build 23
3. [x] **Select build** for Supplier app submission — build 23
4. [x] **Complete all required fields** in App Store Connect — Category, Subtitle, Description, What's New, App Review Notes entered for both apps (see above)
5. [x] **Screenshots** — unchanged from v2.0.2+21, still accurate (no screens the 10 staged screenshots show have changed)
6. [x] **Submit for review** — both apps submitted 2026-08-15, Release set to Manual
7. [x] **Monitor review status** — approved 2026-08-16
8. [x] **Respond to App Review** if questions arise — n/a, approved without questions
9. [x] **Release approved apps** — both apps manually released 2026-08-16, live on the App Store. ⚠️ Contains TEST-016 - build/submit v2.1.1+29 as soon as possible.

**v2.1.0+26 (shipped to TestFlight only, never submitted for App Store review):**

1. [x] **Upload build to App Store Connect** (via Transporter) — build 26, both apps - happened outside this checklist's tracked workflow, confirmed only via the user testing the live TestFlight build 2026-08-17
2. [ ] **Select build** for Customer app submission — not submitted; superseded before this step (missing TEST-021 and DECISION-017)
3. [ ] **Select build** for Supplier app submission — same
4. [ ] **Complete all required fields** in App Store Connect
5. [ ] **Screenshots**
6. [ ] **Submit for review** — deliberately not done; see TEST-021 in `docs/project-management/DEFECT_TRACKER.md`
7. [ ] **Monitor review status**
8. [ ] **Respond to App Review** if questions arise
9. [ ] **Release approved apps**

**v2.1.0+27 (uploaded to TestFlight only, never submitted for App Store review, superseded by v2.1.1+29):**

1. [x] **Upload build to App Store Connect** (via Transporter) — build 27, both apps - the night of 2026-08-16/17, outside this checklist's tracked workflow
2. [ ] **Select build** for Customer app submission — not submitted; superseded before this step (missing DECISION-017 and TEST-022)
3. [ ] **Select build** for Supplier app submission — same
4. [ ] **Complete all required fields** in App Store Connect
5. [ ] **Screenshots**
6. [ ] **Submit for review** — deliberately not done
7. [ ] **Monitor review status**
8. [ ] **Respond to App Review** if questions arise
9. [ ] **Release approved apps**

**v2.1.1+28 (uploaded to TestFlight only, never submitted for App Store review, superseded by v2.1.1+29):**

1. [x] **Upload build to App Store Connect** (via Transporter) — build 28, both apps - outside this checklist's tracked workflow, confirmed by the user actively testing against it
2. [ ] **Select build** for Customer app submission — not submitted; superseded before this step (missing TEST-022)
3. [ ] **Select build** for Supplier app submission — same
4. [ ] **Complete all required fields** in App Store Connect
5. [ ] **Screenshots**
6. [ ] **Submit for review** — deliberately not done; see TEST-022 in `docs/project-management/DEFECT_TRACKER.md`
7. [ ] **Monitor review status**
8. [ ] **Respond to App Review** if questions arise
9. [ ] **Release approved apps**

**v2.1.1+29 (current) — in progress:**

1. [ ] **Upload build to App Store Connect** (via Transporter) — build 29, both apps
2. [ ] **Select build** for Customer app submission — build 29
3. [ ] **Select build** for Supplier app submission — build 29
4. [ ] **Complete all required fields** in App Store Connect — only What's New needs updating (`APP_STORE_METADATA_PACKET_v2_1_1_29.md`); everything else already live from v2.0.3+23
5. [ ] **Screenshots** — unchanged, no screens affected by these fixes (QR appearance is visually similar regardless of underlying encoding; DECISION-017's banner/dialog are new UI, but not part of the staged screenshot set)
6. [ ] **Submit for review**
7. [ ] **Monitor review status**
8. [ ] **Respond to App Review** if questions arise
9. [ ] **Release approved apps** — Manual release, same reasoning as v2.0.3+23

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

**Document Status:** 🟢 **v2.0.3+23 is LIVE ON THE APP STORE** (both apps), submitted 2026-08-15, approved and released 2026-08-16, superseding v2.0.2+21 (shipped 2026-08-10 — the project's first public release). ⚠️ **v2.0.3+23 contains TEST-016** (businesses with 3 or 4 required stamps can't issue a valid card) - fix shipped to **TestFlight as v2.1.0+26** (minor version bump, also fixes TEST-017 through TEST-020, a redemption QR-capacity failure found while testing TEST-016 and everything it surfaced along the way), but not submitted for App Store review since TEST-021 (the issue-card counterpart to TEST-017/020's fix) was found on that same TestFlight build. **v2.1.0+27** added TEST-021 and was built and uploaded to TestFlight. **v2.1.1+28** (patch version bump - DECISION-017 is a genuine UX improvement, not build-only) added a self-service fix for a business outside the supported stamps-required range, also built and uploaded to TestFlight, real-device verified end-to-end - see `docs/testing/DECISION-017_LEGACY_BUSINESS_TEST_PLAN.md`. That same testing found **TEST-022**, a cross-version compatibility regression from TEST-021. **v2.1.1+29** (build-only bump) adds that fix and is the actual submission candidate, not yet built or submitted. See `RELEASES.md` for the release-branch record and `docs/project-management/DEFECT_TRACKER.md` for the defects.  
**Maintained by:** Development Team  
**Last Updated:** August 17, 2026

---

**References:**
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Beta Testing Guide](https://developer.apple.com/testflight/)
