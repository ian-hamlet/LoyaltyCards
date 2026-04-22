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
  - LoyaltyCards - Digital Stamps (Customer)
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
  - LoyaltyCards - Digital Stamps (Customer)
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
  - LoyaltyCards - Digital Stamps (Customer)
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

---

**Current branch structure:**
- `main` - Production-ready code
- `develop` - Active development
- `releases/v*` - Deployment snapshots (read-only)
- `feature/*` - Feature development (temporary)
