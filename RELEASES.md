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

### v0.3.0+1 (In Development - REQ-022)
- **Date:** April 20, 2026
- **Platform:** Development/Testing
- **Branch:** develop
- **Version:** 0.3.0+1
- **Focus:** REQ-022 - Enhanced Simple Mode with Multi-Denomination Stamps
- **Major Changes:**
  - **Flexible Stamp Denominations:** Any value from 1 to stampsRequired
  - **Expiry Policies:** None, Daily, Weekly, or Custom date
  - **Supplier-Specific Scan Intervals:** Configurable 5-60 seconds
  - **Token Generation UI:** Replaced single-stamp QR with denomination selector
  - **Annotated QR Images:** Clear visual labels (stamp count, expiry, business name)
  - **Multi-Stamp Processing:** Single scan can award multiple stamps
  - **Enhanced Distribution:** Save to Photos, Print, Email workflows
- **Technical Implementation:**
  - StampToken model: Added stampCount, expiryDate, scanInterval fields
  - Business model: Added configurable scanInterval (stored as seconds)
  - Database: Supplier DB upgraded to v5 (scan_interval_seconds column)
  - Customer app: Enhanced TokenValidator, RateLimiter with dynamic intervals
  - Supplier app: Redesigned Simple Mode stamp screen
  - Backward compatible: Old tokens continue to work (stampCount defaults to 1)
- **Test Coverage:**
  - Shared package: 131 tests (includes 18 new REQ-022 tests)
  - Customer app: 49 tests (includes 18 new REQ-022 tests)
  - All edge cases covered: expiry, stampCount validation, overflow, rate limits
- **Files Modified:**
  - Shared: 4 files (models, constants, tests)
  - Supplier app: 5 files (UI, database, services)
  - Customer app: 3 files (validation, rate limiting, scanning)
- **Documentation:**
  - REQ-022_IMPLEMENTATION_SUMMARY.md (comprehensive implementation guide)
  - Enhanced test files with REQ-022 test groups
- **Status:** ✅ Code complete, all tests passing
- **Next Steps:**
  - Simulator testing (token generation, multi-stamp scanning)
  - Physical device testing (printer output, QR scanning reliability)
  - TestFlight deployment after device validation

### v0.2.1-build23 (TestFlight - Previous)
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
