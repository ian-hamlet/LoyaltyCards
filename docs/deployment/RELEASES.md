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

### v2.1.1+29 - Build 29 (🟡 Submitted for App Store review)
- **Date:** August 17-18, 2026
- **Platform:** Built and delivered to TestFlight 2026-08-18, real-device validated, metadata confirmed in ASC, **submitted for App Store review 2026-08-18** (both apps).
- **Branch:** `develop`/`main`/`releases/v2.1.1-build29` (all three at the same commit as of this submission - see the merge/release-branch record below)
- **Version:** 2.1.1+29
- **Status:** 🟡 Submitted for App Store review, awaiting Apple's decision. **Build-only bump** - v2.1.1+28 was already built and uploaded to TestFlight before TEST-022 was found via real-device testing of that exact build, and Apple doesn't allow re-uploading the same build number with different content. Real-device validation passed (`docs/testing/TEST-022_VALIDATION_TEST_PLAN.md`, `docs/testing/V2_1_1_BUILD29_VALIDATION.md`); ASC metadata confirmed (`docs/deployment/APP_STORE_METADATA_PACKET_v2_1_1_29.md`). Release set to **Manual** on both apps, same reasoning as v2.0.3+23.
- **Focus:** TEST-022 - the cross-version compatibility regression TEST-021 introduced - plus a quality-review cleanup pass (N-008/N-009/dead-code removal) that shipped in the same build.
- **Major Changes:**
  - **TEST-022:** TEST-021's compact issue-card QR encoding was unconditional (no size gate), breaking issuance for any customer app older than that fix - not just the rare high-initial-stamp-count case it was written for. Confirmed on a real device (supplier 27, customer 23). Fixed by preferring plain JSON whenever it fits (covers every initial-stamp count up to 16), falling back to compact encoding only for the genuine legacy edge case. Applied the same fix proactively to the redemption QR (TEST-020), which had the identical unconditional-encoding shape.
  - **DECISION-019:** consolidated the duplicated public-key decode routine (N-008) and error-cooldown constant (N-009) flagged in the 2026-08-17 magic numbers review; removed the confirmed-dead `AppConstants.issueIntervalMs`. Internal cleanup only, no user-facing behavior change - automated-test verified (full suite green across all three packages), no dedicated device test needed.
  - Full detail: `docs/project-management/DEFECT_TRACKER.md` TEST-022 and DECISION-019.
- **Next Steps:** Monitor App Store Connect for the review decision on both apps; release manually (together) once both are approved, same as v2.0.3+23.

### v2.1.1+28 - Build 28 (🟢 Shipped to TestFlight, superseded by v2.1.1+29 for submission)
- **Date:** August 17, 2026
- **Platform:** Built and uploaded to TestFlight - confirmed by the user actively testing against it.
- **Branch:** `develop` (`505d5f9` for TEST-021; DECISION-017 added afterward, before this build)
- **Version:** 2.1.1+28
- **Status:** 🟢 Shipped to TestFlight, not submitted for App Store review. Real-device verified end-to-end - full DECISION-017 flow tested across both matched (28/28) and mismatched (28 supplier/23 customer) supplier/customer pairs, including the old 20-stamp card continuing to stamp correctly after reconfiguration and a new card issuing cleanly from the fixed business. See `docs/testing/DECISION-017_LEGACY_BUSINESS_TEST_PLAN.md` for the full log. **Missing the TEST-022 fix** (found via this same testing round) - **should not be submitted for App Store review as-is**, use v2.1.1+29 above, now submitted for App Store review.
- **Major Changes:**
  - **TEST-021:** the same silent QR-capacity failure as TEST-017, never fixed on the issue-card side - a card issued with many pre-applied initial stamps could hit it too. Found via real-device testing of the v2.1.0+26 TestFlight build. Applied the same compact-encoding fix (`CardIssueQrCodec`) to the supplier app's on-screen, Print, and Share issue-card QR. (Already shipped to TestFlight in v2.1.0+27 too.)
  - **DECISION-017:** a business whose `stampsRequired` falls outside the supported range previously had no way to recover short of a full reset (wiping every customer's card). Turns out changing it going forward is safe (each existing card stores its own value at issuance). Supplier app now warns proactively on Home, blocks Issue Card from generating a doomed QR, and offers a scoped "Fix Now" flow (also in Settings) to reconfigure into range.
  - Full detail: `docs/project-management/DEFECT_TRACKER.md` TEST-021 and DECISION-017. TEST-022 was found afterward via testing this exact build - see v2.1.1+29 above.

### v2.1.0+27 - Build 27 (🟢 Shipped to TestFlight, superseded by v2.1.1+29 for submission)
- **Date:** August 17, 2026
- **Platform:** ⚠️ Built and uploaded to **TestFlight** the night of 2026-08-16/17 - this happened outside this document's tracked workflow, so there's no record here of exactly when/how (no `main` merge, release branch, or `build_both_apps.sh` run is logged). Confirmed by the user 2026-08-17.
- **Version:** 2.1.0+27 (committed to git as `505d5f9`)
- **Status:** 🟢 Shipped to TestFlight, not submitted for App Store review. Carried TEST-021 only - DECISION-017 and TEST-022 were added afterward. **Should not be submitted for App Store review as-is** - use v2.1.1+29 above, now submitted for App Store review, since this build is missing both.
- **Major Changes:** TEST-021 only - see v2.1.1+28 and v2.1.1+29 above, which carry this fix forward alongside DECISION-017 and TEST-022.

### v2.1.0+26 - Build 26 (🟡 Shipped to TestFlight, superseded by v2.1.1+29 for submission)
- **Date:** August 16, 2026
- **Platform:** ⚠️ Built and uploaded to **TestFlight** at some point after the TEST-016/017/018/019/020 code landed on `develop` (`c7b8e63`) - this happened outside this document's tracked workflow, so there's no record here of exactly when/how (no `main` merge, release branch, or `build_both_apps.sh` run is logged). Confirmed by the user testing against it directly 2026-08-17.
- **Branch:** `develop` at `c7b8e63` (TEST-016 through TEST-020 only - TEST-021, DECISION-017, and TEST-022 came afterward, see v2.1.1+29 above)
- **Version:** 2.1.0+26
- **Status:** 🟡 Shipped to TestFlight, not submitted for App Store review. Real-device verification passed, including via this actual TestFlight build (12-stamp Secure Mode card, 100% of stamps overflow-relocated, redeems successfully; a 3/4-stamp business issues a working card end-to-end; the TEST-019 out-of-range message confirmed against the 20-stamp legacy business; Express Mode and Recovery Backup restore spot-checked with no regressions). Minor version bump (2.0.4 -> 2.1.0) - deliberate, not a build-only bump, since raising the stamps-required ceiling is a real capability change. Supersedes v2.0.4+24 and the interim test-only build v2.0.4+25 (neither ever a real release candidate). Also supersedes v2.0.3+23, which is **live on the App Store** but contains TEST-016 and none of the fixes below. **Should not be submitted for App Store review as-is** - use v2.1.1+29 above, now submitted for App Store review, since this build is missing TEST-021, DECISION-017, and TEST-022.
- **Focus:** Redemption QR reliability - the real fix for the QR-capacity problem found while testing TEST-016, plus everything it surfaced along the way
- **Major Changes:**
  - **TEST-016** (carried forward from v2.0.4+24): businesses configured with 3 or 4 required stamps could never issue a valid card - `CardIssueToken.isValid()` rejected `stampsRequired` below 5, but the onboarding slider allows a minimum of 3.
  - **TEST-017:** a Secure Mode redemption QR bundles one signature per stamp; at high stamp counts the plain-JSON payload could exceed a QR code's maximum capacity, causing a silent blank-panel failure with no error shown. Interim fix (cap lowered to 10, fallback UI added) - superseded by TEST-020.
  - **TEST-018:** one of three overflow-relocation code paths omitted the provenance fields needed to verify a moved stamp's signature at redemption - fixed by centralizing relocated-stamp construction in `Stamp.relocateTo()`.
  - **TEST-019:** a business whose stored stamp count fell outside the supported range saw a generic, misleading "please try again" on every scan, forever - added a specific, actionable error message instead.
  - **TEST-020 (the real fix):** replaced the plain-JSON redemption QR encoding with gzip + Base45 (RFC 9285) + QR's alphanumeric encoding mode, plus an explicit version field. Raised the stamps-required ceiling from 10 to 12 - measured safe even at 100% overflow-relocated stamps (the worst case), verified against the real QR library. Also consolidated redemption-QR generation onto the existing `QRTokenGenerator`, fixing a real, separate bug found along the way (device-mismatch detection had silently been dropped from a duplicate hand-rolled implementation).
  - Full detail and measured payload sizes: `docs/project-management/DEFECT_TRACKER.md` TEST-017 through TEST-020.

### v2.0.4+24 - Build 24 (🟡 Superseded by v2.1.0+26 - never built or uploaded)
- **Date:** August 15, 2026
- **Version:** 2.0.4+24 (folded into v2.1.0+26 along with the interim test-only build v2.0.4+25)
- **Major Changes:** TEST-016 only - see v2.1.0+26 above, which carries this fix forward alongside TEST-017 through TEST-020.

### v2.0.3+23 - Build 23 (🟢 LIVE ON THE APP STORE)
- **Date:** August 15, 2026 (submitted); August 16, 2026 (approved and released)
- **Platform:** App Store — **passed review and is now publicly available** (both apps)
- **Branch:** main, develop, `releases/v2.0.3-build23`
- **Version:** 2.0.3+23
- **Status:** 🟢 LIVE — available for download on the App Store. Built, uploaded via Transporter, tested via TestFlight (Sharing feature and both bug fixes confirmed working on-device), submitted 2026-08-15, approved and released 2026-08-16. Release was set to **Manual** on both apps deliberately - the two apps review at different speeds, and manual release means neither goes live before the other is also approved.
- **⚠️ Known defect (TEST-016):** businesses configured with 3 or 4 required stamps cannot issue a valid card, in either Secure or Express Mode - see `docs/project-management/DEFECT_TRACKER.md`. Fixed in v2.1.0+26 (carried forward through v2.1.1+29, submitted for App Store review 2026-08-18 - see v2.1.1+29 above). Do not treat this build as fully correct despite being live.
- **Focus:** Companion-app/friend referral sharing (both apps), plus two bugs found during TestFlight-prep testing
- **Major Changes:**
  - **Sharing feature:** new Settings section in both apps, "Tell a Business" (QR + share link to LoyaltyCards Business) and "Tell a Friend" (QR + share link to LoyaltyCards) - built as a reusable `AppReferralScreen` widget in the shared package. Supplier app also gets a "Tell a Friend" shortcut icon on the Home screen's app bar.
  - **Fixed:** Express Mode stamps were routed to the newest card for a business instead of an older card with existing progress and room - `getAllCards().firstWhere(...)` always returns the most recently created match; fixed to use the existing `CardRepository.findCardWithSpace()` helper.
  - **Fixed:** Clone to Another Device and Create Recovery Backup screens briefly showed a false "failed" error on open - their loading flag started `false` but `initState()` kicks off async auth-then-generate work immediately, leaving a gap before the flag caught up. Started both `true` instead.
  - Category/Subtitle corrections (queued since v2.0.2+21 shipped) finalized as real submission content - see `APP_STORE_METADATA_PACKET_v2_0_3_23.md`. Also caught the customer app's Promotional Text, which turned out blank in ASC despite being documented as already-live.
- **Note:** v2.0.3+22 was build-bumped to +23 before ever producing an uploaded build, once the two bugs above were found during TestFlight-prep testing - see that packet's own superseded note.
- **Next Steps:** v2.1.1+29 (TEST-016 fix plus TEST-017 through TEST-022, DECISION-017, and DECISION-019) has been built, shipped to TestFlight, real-device validated, and submitted for App Store review (2026-08-18) - monitoring for Apple's decision is next.

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
