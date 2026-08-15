# Release Branches

## Purpose

Release branches preserve permanent snapshots of code deployed to TestFlight and App Store.

## Naming Convention

```
releases/v{version}-build{number}
```

Examples:
- `releases/v0.2.0-build4` - Initial TestFlight deployment
- `releases/v0.2.1-build7` - Bug fix release
- `releases/v1.0.0-build12` - First App Store production release

## Current Releases

### v2.0.3+24 - Build 24 (🟡 In Progress)
- **Date:** August 15, 2026
- **Platform:** Not yet built/uploaded
- **Branch:** develop (not yet on main or a releases branch)
- **Version:** 2.0.3+24
- **Status:** 🟡 In progress - supersedes v2.0.3+23, which is currently under App Store review and contains TEST-016 (see below). Once ready, this build should be built, tested, and submitted; v2.0.3+23 should not be released even if Apple approves it first, since it has the defect.
- **Focus:** Single critical bug fix, no new features
- **Major Changes:**
  - **Fixed TEST-016:** businesses configured with 3 or 4 required stamps could never issue a valid card - `CardIssueToken.isValid()` rejected `stampsRequired` below 5, but the onboarding slider allows a minimum of 3. Affected both Secure and Express Mode, since both share the same token/validation path. Found while investigating macOS build feasibility for the supplier app (see `feature/macos-supplier-port` - that work is unrelated and not part of this release). Full detail: `docs/project-management/DEFECT_TRACKER.md` TEST-016.
- **Next Steps:** Build both IPAs, upload via Transporter, verify via TestFlight, then submit for App Store review. Once main is fast-forwarded to develop for this build, decide whether to withdraw the v2.0.3+23 submission from Apple review or let it lapse/get superseded at release time.

### v2.0.3+23 - Build 23 (🟡 Submitted for App Store Review - superseded by v2.0.3+24, do not release)
- **Date:** August 15, 2026
- **Platform:** App Store Connect — submitted for App Store review, awaiting Apple's decision
- **Branch:** main, develop, `releases/v2.0.3-build23`
- **Version:** 2.0.3+23
- **Status:** 🟡 Built, uploaded via Transporter, tested via TestFlight (Sharing feature and both bug fixes confirmed working on-device), and submitted for App Store review 2026-08-15. Release set to **Manual** on both apps deliberately - the two apps review at different speeds, and manual release means neither goes live before the other is also approved.
- **Focus:** Companion-app/friend referral sharing (both apps), plus two bugs found during TestFlight-prep testing
- **Major Changes:**
  - **Sharing feature:** new Settings section in both apps, "Tell a Business" (QR + share link to LoyaltyCards Business) and "Tell a Friend" (QR + share link to LoyaltyCards) - built as a reusable `AppReferralScreen` widget in the shared package. Supplier app also gets a "Tell a Friend" shortcut icon on the Home screen's app bar.
  - **Fixed:** Express Mode stamps were routed to the newest card for a business instead of an older card with existing progress and room - `getAllCards().firstWhere(...)` always returns the most recently created match; fixed to use the existing `CardRepository.findCardWithSpace()` helper.
  - **Fixed:** Clone to Another Device and Create Recovery Backup screens briefly showed a false "failed" error on open - their loading flag started `false` but `initState()` kicks off async auth-then-generate work immediately, leaving a gap before the flag caught up. Started both `true` instead.
  - Category/Subtitle corrections (queued since v2.0.2+21 shipped) finalized as real submission content - see `APP_STORE_METADATA_PACKET_v2_0_3_23.md`. Also caught the customer app's Promotional Text, which turned out blank in ASC despite being documented as already-live.
- **Note:** v2.0.3+22 was build-bumped to +23 before ever producing an uploaded build, once the two bugs above were found during TestFlight-prep testing - see that packet's own superseded note.
- **Next Steps:** Monitor App Store review (typically 24-48 hours); once both apps are approved, manually release them together.

### v2.0.2+21 - Build 21 (🟢 LIVE ON THE APP STORE)
- **Date:** August 10, 2026
- **Platform:** App Store — **passed review and is now publicly available** (both apps). First public release of the project.
- **Branch:** main, develop, `releases/v2.0.2-build21`
- **Version:** 2.0.2+21
- **Status:** 🟢 LIVE — available for download on the App Store
- **Focus:** Fix v2.0.0+19's App Review rejection (CRASH-001) plus a Transporter-flagged deployment-target issue found while preparing that fix
- **Major Changes:**
  - CRASH-001: native `EXC_BAD_ACCESS` crash tapping Print on the supplier app's Stamp Setup screen, reported by App Review on an iPad Air 11" (M3). Fixed with a re-entrancy guard on all 6 print/share/save buttons across 3 screens, plus PDF-bytes validation ahead of every native print call. Full writeup: `docs/project-management/CRASH-001-stamp-print-race-condition.md`.
  - UI-001: unreadable dark-mode text on both apps' How It Works info panels.
  - Express Mode redemption copy clarified as an explicit witnessed handshake (customer app).
  - Raised `IPHONEOS_DEPLOYMENT_TARGET` from 13.0 to 15.0 in both apps - Transporter flagged 13.0 during the (never-completed) v2.0.1+20 upload attempt; Apple requires 15.0+ for all uploads starting Spring 2027.
- **Note:** v2.0.1+20 (2026-08-06) was prepared with the CRASH-001/UI-001 fixes but never uploaded - the deployment-target issue was caught first. Its metadata packet (`APP_STORE_METADATA_PACKET_v2_0_1_20.md`) is superseded by `APP_STORE_METADATA_PACKET_v2_0_2_21.md`, which is what's actually live.
- **Next Steps:** Monitor App Store Connect for crash reports/reviews now that the app is public; plan the next update cycle.

### v2.0.0+19 - Build 19 (🔴 Rejected by App Review)
- **Date:** July 28, 2026
- **Platform:** App Store Connect — first submission beyond TestFlight
- **Branch:** main, develop, `releases/v2.0.0-build19`
- **Version:** 2.0.0+19
- **Status:** 🔴 REJECTED 2026-08-05 — CRASH-001 (native crash tapping Print, supplier app). See v2.0.2+21 above — that build fixed it and is now live.
- **Focus:** Security/fraud fixes surfaced by a multi-role review pass, plus App Store readiness (metadata, public site, App Privacy disclosure)
- **Major Changes:**
  - **Breaking (v2.0.0+18):** QR token format changed (new signed fields from the security review) — pre-review printed QR codes fail signature verification against the new signed data. Acceptable since the app has never had real-world users.
  - Closed a critical redemption-inflation gap in Secure Mode chain verification (duplicate/replayed proof signatures, unused proof-count check) and a third instance of the additional-stamp signing-format bug
  - Fixed Express Mode repeat-customer lockout: re-scanning a supplier's QR after a card was redeemed was blocked forever; also fixed pre-applied "welcome stamps" being silently dropped on that repeat cycle
  - Renamed "Simple Mode" to "Express Mode" across all user-facing copy (in-app, docs, App Store metadata)
- **App Store Connect for this submission:**
  - Metadata (subtitle/promo text/keywords/description/App Review Notes) from `APP_STORE_METADATA_PACKET_v2_0_0_19.md`
  - Marketing URL set to the new `site/user/about.html` (two-app pairing + Express/Secure Mode explainer with case studies)
  - Customer app's App Privacy questionnaire updated to declare Device ID (Secure Mode redemption fraud-prevention signal) — supplier app unaffected
  - `Info.plist` `ITSAppUsesNonExemptEncryption` fix confirmed self-declaring correctly on this upload
- **Next Steps:** Monitor App Store review (typically 24-48 hours), respond to reviewer questions if any arise

### v1.0.1+7 - Build 7 (🟡 Release Candidate)
- **Date:** June 11, 2026
- **Platform:** App Store Submission Candidate
- **Branch:** develop
- **Version:** 1.0.1+7
- **Status:** 🟡 READY FOR FINAL VALIDATION
- **Focus:** App Store submission hardening and device-specific UI validation
- **Major Changes:**
  - Responsive stamp layout fixes for smaller screenshot simulator targets
  - Customer home card stamp display now width-aware with overflow wrapping
  - Customer detail stamp display aligned to the same responsive behavior
- **Testing:** Validated on iPhone 14 Pro and iPhone SE simulator targets
- **Next Steps:** Upload build 7, complete final App Store Connect metadata checks, submit for review

### v1.0.0+6 - Build 6 (🟡 Release Candidate)
- **Date:** June 11, 2026
- **Platform:** App Store Submission Candidate
- **Branch:** release branch pending final cut
- **Version:** 1.0.0+6
- **Status:** 🟡 READY FOR FINAL VALIDATION
- **Focus:** First public App Store release preparation
- **Major Changes:**
  - Version alignment across customer, supplier, and shared package metadata
  - App Store materials execution tracker added and activated
  - Submission documentation updated for v1.0.0 release train
- **Testing:** Final TestFlight validation in progress
- **Next Steps:** Upload build 6, complete App Store Connect metadata, submit for review

### v0.3.1+3 - Build 25 (🔄 In Development)
- **Date:** June 8, 2026
- **Platform:** Development (feature/minorupdate branch)
- **Branch:** feature/minorupdate → develop
- **Version:** 0.3.1+3
- **Status:** 🔄 IN DEVELOPMENT - QA Testing
- **Focus:** Bug Fixes and UX Improvements
- **Major Changes:**
  - **QR Scanner UX Fix:**
    - Added clear error messages when non-stamp QRs are scanned in stamp mode
    - Detects card-issuance QRs and suggests using Add Card instead
    - Added 2-second cooldown to prevent rapid error message retriggers
    - Consolidated error display to single inline message (removed duplicate snackbar)
  - **Previous Release Summary:** See v0.3.0+1 below
- **Testing:** Ready for device testing via Xcode
- **Next Steps:** Merge to develop, prepare for App Store submission

### v0.3.0+1 - Build 23 (✅ Released to TestFlight)
- **Date:** April 21, 2026
- **Platform:** TestFlight Production
- **Branch:** main, releases/v0.3.0-build01
- **Version:** 0.3.0+1
- **Status:** ✅ DEPLOYED - Active Testing
- **Focus:** Critical Security Fixes and Production Readiness
- **Major Changes:**
  - **CRITICAL Security Fixes:**
    - SEC-001: HKDF key derivation (replaced hardcoded HMAC key)
    - SEC-002: Constant-time comparison (prevents timing attacks)
    - ERROR-001: Comprehensive error handling in TransactionRepository
  - **Package Updates:**
    - device_info_plus: 11.5.0 → 13.1.0
    - local_auth: 2.3.0 → 3.0.1 (breaking changes handled)
    - share_plus: 10.1.4 → 12.0.2
  - **Bug Fixes:**
    - Multi-stamp token generation (real-time QR regeneration)
    - Text contrast issue (stamp history title)
  - **UX Improvements:**
    - Removed "Save to Photos" option (simplified backup workflows)
    - Enhanced smart routing documentation
- **Test Coverage:**
  - 264 automated tests (100% passing)
  - Shared: 131 tests (+16 security, +17 timeout tests)
  - Customer: 87 tests
  - Supplier: 46 tests
- **Documentation:**
  - Major reorganization into 8 logical categories
  - 69 documents organized with DOCUMENTATION_INDEX.md
  - Production readiness assessment completed
- **Technical Details:**
  - Customer App Database: v7 (stable)
  - Supplier App Database: v5 (stable)
  - Release branch: releases/v0.3.0-build01 (permanent snapshot)
- **Code Review:** Comprehensive production readiness assessment completed
- **Next Steps:** Gather TestFlight user feedback before App Store submission

### v0.2.1-build23 (Previous TestFlight)
- **Date:** April 18, 2026
- **Platform:** TestFlight (Internal Testing)
- **Branch:** develop
- **Version:** 0.2.1+23
- **Focus:** Feature flags for TestFlight testing
- **Changes:**
  - Re-enabled "Danger Zone" buttons for TestFlight testers
  - Customer: Delete All Data now visible (feature flag)
  - Supplier: Reset Business Configuration now visible (feature flag)
  - Added version management documentation
- **Note:** Before App Store release, disable feature flags

### v0.2.1-build22 (Testing Infrastructure)
- **Date:** April 18, 2026
- **Platform:** Development only (not deployed to TestFlight)
- **Branch:** develop
- **Version:** 0.2.1+22
- **Focus:** Internal quality improvements
- **Changes:**
  - Added 165 automated unit tests (115 shared, 33 customer, 17 supplier)
  - Created TESTING_STRATEGY.md documentation
  - Code cleanup: Removed unused code and debug logging
  - Updated all project documentation
- **Note:** Shared package tests not included in app builds

### v0.2.0-build21 (Security Enhancements)
- **Date:** April 13, 2026
- **Platform:** TestFlight (Superseded by Build 23)
- **Branch:** develop
- **Version:** 0.2.0+21
- **Focus:** Security vulnerability fixes (V-002, V-005)
- **New Features:**
  - Biometric authentication for private key access (Face ID/Touch ID)
  - Multi-device duplication detection and warnings
  - Device ID tracking for enhanced security
  - Customer app Face ID lock (optional privacy feature)
- **Database Changes:**
  - Customer DB: v5 → v6 (added device_id columns)
  - Supplier DB: v4 (unchanged)
- **Documentation:**
  - VULNERABILITIES.md (security assessment)
  - TERMS_OF_SERVICE.md (App Store compliance)
  - Updated USER_GUIDE.md and BUILD_21_TESTING_GUIDE.md
- **Apps:**
  - LoyaltyCards Customer Wallet (Customer)
  - LoyaltyCards Business (Supplier)

### v0.2.0-build15 (TestFlight Stable)
- **Date:** April 16, 2026
- **Platform:** TestFlight (Internal Testing)
- **Commit:** 26ab1c9
- **Branch:** releases/v0.2.0+15
- **Status:** ✅ Current TestFlight Build
- **Features:**
  - Regression testing complete
  - All critical defects fixed
  - Stable for internal pilot testing
- **Apps:**
  - LoyaltyCards Customer Wallet (Customer)
  - LoyaltyCards Business (Supplier)

### v0.2.0-build4 (TestFlight Initial)
- **Date:** April 14, 2026
- **Platform:** TestFlight (Internal Testing - Superseded)
- **Commit:** da1c19a
- **Status:** ⚠️ Superseded by Build 15
- **Features:**
  - Custom app icons
  - Dual operation modes (Simple & Secure)
  - Multi-device supplier support (backup & clone)
  - Privacy-first architecture
  - QR-based stamp issuance and redemption
- **Apps:**
  - LoyaltyCards Customer Wallet (Customer)
  - LoyaltyCards Business (Supplier)

## Workflow

### Creating a Release Branch

When deploying to TestFlight or App Store:

```bash
# From main branch (after merging develop)
git checkout main
git checkout -b releases/v{version}-build{number}
git push origin releases/v{version}-build{number}
git checkout develop
```

### Using Release Branches

**To check deployed code:**
```bash
git checkout releases/v0.2.0-build4
```

**To compare with current development:**
```bash
git diff releases/v0.2.0-build4 develop
```

**To see all releases:**
```bash
git branch -a | grep releases
```

## Branch Protection

Release branches should:
- ✅ Never be deleted
- ✅ Never have new commits (read-only snapshot)
- ✅ Always match what was uploaded to TestFlight/App Store

If you need to deploy a fix, create a **new release branch** with incremented build number.

## Tags vs Branches

We use **branches** instead of tags because:
- Easier to checkout and browse in most Git tools
- Clearer in GitHub UI
- Can include in pull request comparisons
- More visible in `git branch -a` output

## Future Releases

When creating new releases:

1. Work in `develop` branch
2. Increment version in `pubspec.yaml` files
3. Test thoroughly
4. Merge `develop` → `main`
5. Create release branch from `main`
6. Build and upload to TestFlight/App Store
7. Return to `develop` for continued work

**⚠️ Note on step 4 - merging to `main` publishes the public site immediately, ahead of the actual App Store release.** `.github/workflows/pages.yml` deploys `site/` on every push to `main` that touches it - there's no separate "publish" step. So the moment `main` is equalized, the public site's version stamps and feature descriptions (About page, User Guide, Supplier Setup Guide) go live describing the *in-progress* version, potentially days before App Review actually approves it and it's downloadable. This happened with v2.0.3+23: `main` was equalized once TestFlight testing confirmed the build worked, but the app itself wasn't submitted for review yet at that point. In practice this is low-risk (a version stamp or a feature description being slightly ahead of what's downloadable isn't seriously misleading), but it's worth knowing about - if a release ever needs the site to stay in lockstep with what's actually live, merge `develop` → `main` only once the App Store submission is approved and released, not as soon as testing passes.

---

**Current branch structure:**
- `main` - Production-ready code
- `develop` - Active development
- `releases/v*` - Deployment snapshots (read-only)
- `feature/*` - Feature development (temporary)
