# Defect Tracker - v0.2.0 Post-Testing

**Current Version:** v0.2.0 (Build 4) - On TestFlight  
**Target Version:** v0.2.1 (Build 5+)  
**Last Updated:** April 15, 2026

---

## Overview

This document tracks defects from two sources:
1. **Code Review Defects** - Found during comprehensive code review
2. **Testing Defects** - Found during device testing on iPhone/iPad

**Status Definitions:**
- 🔴 **CRITICAL** - Blocks core functionality, security risk, or data loss
- 🟠 **HIGH** - Significant impact, should fix before wider release
- 🟡 **MEDIUM** - Noticeable issue, fix in next update
- 🔵 **LOW** - Minor issue, cosmetic, or enhancement
- ✅ **FIXED** - Implemented and tested
- 🚧 **IN PROGRESS** - Currently being worked on
- 📋 **BACKLOG** - Logged but not yet scheduled

---

## 🔴 CRITICAL DEFECTS

### CR-001: Broken Public Key Encoding in Card Issuance
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** CRITICAL
- **File:** `supplier_app/lib/services/stamp_signer.dart` (line 113-117)
- **Description:** `_encodePublicKey()` returns `publicKey.toString()` instead of proper base64 encoding. Outputs "Instance of 'ECPublicKey'" in QR codes.
- **Impact:** 
  - Secure mode card issuance broken
  - Customer app cannot verify supplier signatures
  - Simple mode unaffected (doesn't use public key)
- **Reproduction:**
  1. Create business in supplier app (secure mode)
  2. Issue card
  3. Scan QR in customer app
  4. Public key field contains garbage string
- **Fix Required:** Use KeyManager's existing `_encodePublicKey()` method
- **Estimated Effort:** 30 minutes
- **Testing Required:** Issue card in secure mode, verify signature validation works
- **Assigned To:** 
- **Target Build:** Build 5

### CR-002: Excessive Debug Logging in Production
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** CRITICAL
- **Files:** 
  - `customer_app/lib/services/qr_token_generator.dart` (20+ print statements)
  - `supplier_app/lib/services/key_manager.dart` (8+ statements)
  - `supplier_app/lib/services/supplier_database_helper.dart` (14+ statements)
  - `supplier_app/lib/screens/supplier/supplier_onboarding.dart` (11+ statements)
- **Description:** 50+ debug print statements with exclamation marks expose system internals
- **Impact:**
  - Console spam makes real debugging difficult
  - Exposes internal operations (card IDs, database queries, key generation)
  - Performance degradation
- **Fix Required:** Remove all debug print() calls or implement conditional logging
- **Estimated Effort:** 1-2 hours
- **Testing Required:** Verify apps still function without verbose logging
- **Assigned To:**
- **Target Build:** Build 5

---

## 🟠 HIGH PRIORITY DEFECTS

### CR-003: Duplicated Cryptographic Verification Code
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **Files:** `customer_app/lib/services/key_manager.dart`, `supplier_app/lib/services/key_manager.dart`
- **Description:** 30+ lines of identical signature verification code in both apps
- **Impact:** Security fixes must be applied twice, risk of divergence
- **Fix Required:** Extract to `shared/lib/utils/crypto_utils.dart`
- **Estimated Effort:** 2 hours
- **Assigned To:**
- **Target Build:** Build 6-10

### CR-004: Silent Failures in Security Operations
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **Files:** KeyManager in both apps
- **Description:** Crypto errors return `false` without logging why verification failed
- **Impact:** Impossible to debug signature verification failures
- **Fix Required:** Add error logging, return structured Result<T> type
- **Estimated Effort:** 2 hours
- **Assigned To:**
- **Target Build:** Build 6-10

### CR-005: Incomplete TODO in Production Code
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **File:** `customer_app/lib/screens/customer/customer_add_card.dart` (line 238)
- **Description:** `// TODO: Implement actual card creation from QR data`
- **Impact:** Unclear if feature is implemented or placeholder
- **Fix Required:** Remove TODO if implemented, or complete feature
- **Estimated Effort:** 15 minutes
- **Assigned To:**
- **Target Build:** Build 5

### CR-006: Missing Input Validation in Repositories
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **File:** `customer_app/lib/services/card_repository.dart` (line 48-60)
- **Description:** No validation before database insertion
- **Impact:** Invalid data could corrupt database
- **Fix Required:** Add assertions for required fields, valid ranges
- **Estimated Effort:** 1 hour
- **Assigned To:**
- **Target Build:** Build 6-10

---

## 🟡 MEDIUM PRIORITY DEFECTS

### CR-007: Card Issuance Logging Race Condition
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** MEDIUM
- **File:** `supplier_app/lib/screens/supplier/supplier_issue_card.dart` (line 42-50)
- **Description:** `_hasLoggedCardIssuance` flag only logs once per screen session
- **Impact:** Changing initial stamp count and regenerating QR doesn't re-log
- **Fix Required:** Track logged card IDs in Set or use DB deduplication
- **Estimated Effort:** 30 minutes
- **Assigned To:**
- **Target Build:** Build 10+

### CR-008: Hard-coded Security Constants
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** MEDIUM
- **Files:** `rate_limiter.dart`, `token_validator.dart`
- **Description:** Rate limits (1000ms, 30000ms) and token expiry times hard-coded
- **Impact:** Can't tune security parameters without code search
- **Fix Required:** Move to `shared/lib/constants/constants.dart`
- **Estimated Effort:** 30 minutes
- **Assigned To:**
- **Target Build:** Build 10+

### CR-009: Potential Camera Controller Memory Leak
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** MEDIUM
- **File:** `customer_app/lib/screens/customer/qr_scanner_screen.dart` (line 28-35)
- **Description:** Async operations may be pending during dispose()
- **Impact:** Memory accumulation with repeated scanner use
- **Fix Required:** Call `_controller.stop()` before `dispose()`
- **Estimated Effort:** 10 minutes
- **Assigned To:**
- **Target Build:** Build 10+

### CR-010: Database Version Inconsistency
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** MEDIUM
- **Description:** Customer app uses `AppConstants.databaseVersion`, supplier hard-codes `version: 4`
- **Impact:** Inconsistent version management
- **Fix Required:** Both use constants
- **Estimated Effort:** 15 minutes
- **Assigned To:**
- **Target Build:** Build 10+

---

## 🔵 LOW PRIORITY / ENHANCEMENTS

### CR-011: No Structured Logging Framework
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** LOW
- **Description:** All logging uses print() instead of proper framework
- **Fix Required:** Add `logger` package, create `AppLogger` utility
- **Estimated Effort:** 2 hours
- **Assigned To:**
- **Target Build:** v0.3.0

### CR-012: Test Data in Production Screens
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** LOW
- **File:** `customer_app/lib/screens/customer/customer_home.dart` (line 76-91)
- **Description:** `_addTestCard()` method creates test coffee shop
- **Fix Required:** Feature-flag or remove
- **Estimated Effort:** 15 minutes
- **Assigned To:**
- **Target Build:** v0.3.0

### CR-013: QR Code Size Defined Twice
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** LOW
- **Files:** `qr_code_size.dart`, `constants.dart`
- **Description:** Single source of truth violation
- **Fix Required:** Consolidate in one location
- **Estimated Effort:** 15 minutes
- **Assigned To:**
- **Target Build:** v0.3.0

### CR-014: Inconsistent Error Handling Patterns
- **Source:** Code Review
- **Status:** 📋 BACKLOG
- **Priority:** LOW
- **Description:** Mix of return false, return strings, throw exceptions
- **Fix Required:** Standardize with Result<T> pattern
- **Estimated Effort:** 4-6 hours
- **Assigned To:**
- **Target Build:** v0.3.0

---

## 🧪 TESTING DEFECTS

*Add defects found during device testing below*

### Format for New Defects:

```markdown
### TEST-XXX: [Short Description]
- **Source:** Testing - [iPhone/iPad/Both]
- **Status:** 📋 BACKLOG | 🚧 IN PROGRESS | ✅ FIXED
- **Priority:** CRITICAL | HIGH | MEDIUM | LOW
- **Screen/Feature:** [Where the issue occurs]
- **Description:** [Detailed description of the problem]
- **Reproduction Steps:**
  1. Step 1
  2. Step 2
  3. Step 3
- **Expected Behavior:** [What should happen]
- **Actual Behavior:** [What actually happens]
- **Screenshots/Logs:** [If available]
- **Workaround:** [If any exists]
- **Fix Required:** [What needs to be done]
- **Estimated Effort:** [Time estimate]
- **Assigned To:** [Developer name]
- **Target Build:** Build X
```

### Example Testing Defect:

### TEST-001: QR Scanner Crashes on iPad Pro
- **Source:** Testing - iPad
- **Status:** 📋 BACKLOG
- **Priority:** CRITICAL
- **Screen/Feature:** Customer App - QR Scanner
- **Description:** App crashes when opening QR scanner on iPad Pro 12.9"
- **Reproduction Steps:**
  1. Open customer app on iPad Pro
  2. Tap "Add Card" button
  3. App crashes immediately
- **Expected Behavior:** Camera opens with QR scanner overlay
- **Actual Behavior:** App crashes, returns to home screen
- **Screenshots/Logs:** [Attach crash log]
- **Workaround:** Use iPhone instead
- **Fix Required:** Check camera permissions and iPad camera orientation handling
- **Estimated Effort:** 1-2 hours
- **Assigned To:**
- **Target Build:** Build 5

---

## 📊 Defect Summary Statistics

### By Priority
- 🔴 CRITICAL: 2 (Code Review) + 0 (Testing) = **2 total**
- 🟠 HIGH: 4 (Code Review) + 0 (Testing) = **4 total**
- 🟡 MEDIUM: 4 (Code Review) + 0 (Testing) = **4 total**
- 🔵 LOW: 4 (Code Review) + 0 (Testing) = **4 total**
- **TOTAL: 14 defects tracked**

### By Status
- 📋 BACKLOG: 14
- 🚧 IN PROGRESS: 0
- ✅ FIXED: 0

### By Source
- Code Review: 14
- Testing: 0

### By Target Build
- Build 5 (Critical fixes): 3 defects
- Build 6-10 (High priority): 4 defects
- Build 10+ (Medium priority): 4 defects
- v0.3.0 (Low priority): 4 defects

---

## 🎯 Release Planning

### Build 5 - Critical Bug Fixes
**Target Date:** [Set after testing complete]  
**Focus:** Fix showstopper bugs from code review

**Must Fix:**
- [ ] CR-001: Fix public key encoding (30 min)
- [ ] CR-002: Remove debug logging (1-2 hrs)
- [ ] CR-005: Remove/complete TODO (15 min)
- [ ] [Add critical testing defects here]

**Estimated Total Effort:** 2-3 hours  
**Testing Required:** Full regression + secure mode testing

---

### Build 6-10 - High Priority Fixes
**Target Date:** [1 week after Build 5]  
**Focus:** Code quality and maintainability

**Must Fix:**
- [ ] CR-003: Extract crypto to shared utils (2 hrs)
- [ ] CR-004: Improve error logging (2 hrs)
- [ ] CR-006: Add repository validation (1 hr)
- [ ] [Add high priority testing defects here]

**Estimated Total Effort:** 5-6 hours  
**Testing Required:** Security testing, edge case testing

---

### v0.3.0 - Quality Improvements
**Target Date:** [Future]  
**Focus:** Technical debt and enhancements

**To Fix:**
- [ ] CR-007 through CR-014 (Medium/Low priority)
- [ ] Implement structured logging framework
- [ ] Standardize error handling
- [ ] Add unit tests
- [ ] Performance profiling

**Estimated Total Effort:** 20-30 hours

---

## 📝 Workflow

### 1. Log New Defect
- Add to appropriate section above (Critical/High/Medium/Low)
- Assign unique ID (CR-XXX for code review, TEST-XXX for testing)
- Include all relevant details
- Set priority and target build

### 2. Triage Weekly
- Review all BACKLOG items
- Adjust priorities based on user feedback
- Assign to builds/developers
- Update status

### 3. Fix Defect
- Change status to 🚧 IN PROGRESS
- Create feature branch: `fix/TEST-XXX-short-description`
- Implement fix
- Update version number in `shared/lib/version.dart`
- Commit with reference: `fix: TEST-XXX - Fixed crash on iPad Pro`

### 4. Test Fix
- Verify fix works as expected
- Run regression tests
- Test on both iPhone and iPad (where applicable)
- Update status to ✅ FIXED

### 5. Deploy Build
- Merge to develop
- Build IPA: `flutter build ipa --release`
- Upload to TestFlight via Transporter
- Update "Current Version" at top of this document
- Notify testers

### 6. Close Defect
- After successful TestFlight verification
- Move to "Fixed Defects" section (create if needed)
- Document which build fixed it

---

## 🔗 Related Documents

- [TESTFLIGHT_TESTING_GUIDE.md](TESTFLIGHT_TESTING_GUIDE.md) - Testing procedures
- [CODE_REVIEW_v0.2.0.md](CODE_REVIEW_v0.2.0.md) - Full code review report
- [03-Source/shared/lib/version.dart](03-Source/shared/lib/version.dart) - Version tracking
- `/memories/loyaltycards_technical_debt.md` - Permanent memory of issues

---

## 💡 Notes

- **Always update version.dart** when fixing defects
- **Test on both iPhone AND iPad** before marking as fixed
- **Document workarounds** for blocked testers
- **Link GitHub Issues** if using formal issue tracker
- **Keep this document updated** - it's the source of truth

---

**Last Updated:** April 15, 2026  
**Next Review:** After each testing cycle
