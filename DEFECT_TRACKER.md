Update# Defect Tracker - v0.2.0 Post-Testing

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
- **Status:** ✅ FIXED
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
- **Status:** ✅ FIXED
- **Priority:** CRITICAL
- **Files:** 
  - `customer_app/lib/services/qr_token_generator.dart` (20+ print statements)
  - `supplier_app/lib/services/key_manager.dart` (8+ statements)
  - `supplier_app/lib/services/supplier_database_helper.dart` (14+ statements)
  - `supplier_app/lib/screens/supplier/supplier_onboarding.dart` (11+ statements)
  - `customer_app/lib/services/database_helper.dart` (20+ statements)
  - `customer_app/lib/services/*_repository.dart` files
  - Additional files throughout both apps
- **Description:** 50+ debug print statements with exclamation marks expose system internals
- **Impact:**
  - Console spam makes real debugging difficult
  - Exposes internal operations (card IDs, database queries, key generation)
  - Performance degradation
- **Fix Implemented:** 
  - Created shared `AppLogger` utility with structured logging
  - Replaced ~80+ print() statements with AppLogger calls
  - Debug logs only appear in debug mode (kDebugMode)
  - Production shows only warnings and errors
  - Implemented per CR-011 recommendations
- **Estimated Effort:** 1-2 hours
- **Testing Required:** Verify apps still function without verbose logging
- **Assigned To:**
- **Target Build:** Build 5
- **Fix Date:** 2026-04-15

---

## 🟠 HIGH PRIORITY DEFECTS

### CR-003: Duplicated Cryptographic Verification Code
- **Source:** Code Review
- **Status:** ✅ FIXED
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
- **Status:** ✅ FIXED
- **Priority:** HIGH
- **Files:** 
  - `shared/lib/utils/crypto_utils.dart`
  - `supplier_app/lib/services/key_manager.dart`
  - `supplier_app/lib/services/qr_token_generator.dart`
  - `supplier_app/lib/services/stamp_signer.dart`
  - `supplier_app/lib/screens/supplier/supplier_redeem_card.dart`
- **Description:** Crypto errors return `false` without logging why verification failed
- **Impact:** Impossible to debug signature verification failures
- **Fix Implemented:**
  - Added error logging to all cryptographic operations
  - CryptoUtils.verifySignature() now logs verification failures
  - CryptoUtils._decodePublicKey() now logs decode failures
  - KeyManager.getPrivateKey() now logs retrieval/decode failures
  - KeyManager.getPublicKey() now logs retrieval failures
  - KeyManager.signData() now returns null on failure (was throwing)
  - KeyManager.decodePrivateKey() now returns null on failure with logging
  - All callers of signData() updated with null checks
  - Uses AppLogger for consistent error reporting
- **Estimated Effort:** 2 hours
- **Testing Required:** Verify error logging appears when crypto operations fail
- **Assigned To:**
- **Target Build:** Build 5
- **Fix Date:** 2026-04-15

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

### TEST-001: Inconsistent Version Numbers Across Files
- **Source:** Testing - Both
- **Status:** ✅ FIXED
- **Priority:** CRITICAL
- **Screen/Feature:** Version Management - All Apps
- **Description:** Version and build numbers are stored in multiple locations and not synchronized. The version.dart display string, customer_app pubspec.yaml, and supplier_app pubspec.yaml can all have different values, causing confusion about what version is actually deployed.
- **Reproduction Steps:**
  1. Check `03-Source/shared/lib/version.dart` - shows v0.2.0 (Build 4)
  2. Check `03-Source/customer_app/pubspec.yaml` - may show version: 0.2.0+4
  3. Check `03-Source/supplier_app/pubspec.yaml` - may show version: 0.2.0+4
  4. Launch app on device - About screen shows version from version.dart
  5. App Store Connect shows version from pubspec.yaml
  6. These can get out of sync during development
- **Expected Behavior:** Single source of truth for version/build, or automated sync mechanism
- **Actual Behavior:** Manual updates required in 3+ places, prone to human error
- **Impact:** 
  - Cannot verify which code version is deployed
  - TestFlight users may report bugs against wrong version
  - Confusion during debugging ("is this Build 4 or 5?")
  - Build numbers can be inconsistent between customer and supplier apps
- **Workaround:** Manually update all files each time, but error-prone
- **Fix Required:** 
  - **Option 1:** Single source in version.dart, read by pubspec.yaml files
  - **Option 2:** Build script that updates all locations from single config
  - **Option 3:** Pre-commit hook that validates versions match
  - **Option 4:** Move to constants.dart and generate version display string
- **Estimated Effort:** 2-3 hours
- **Assigned To:**
- **Target Build:** Build 5
- **Notes:** This affects deployment workflow and version tracking reliability. CRITICAL because it's our only way to verify correct version is installed on TestFlight devices.
- **Fix Applied:** 
  - Changed version.dart to use exact same format as pubspec.yaml (0.2.0+X)
  - All three files now use identical version string for easy comparison
  - Fixed customer app settings screen to display actual version from appVersion variable (was showing hardcoded "1.0.0 (Beta)")
  - Moved version display to App Information section in customer app
  - Build number incremented to 6
  - Both apps now correctly display 0.2.0+6 in settings
- **Commits:** ddce1d1, 4525807, 82b6a52

### TEST-002: Supplier App Backup/Export Not Working
- **Source:** Testing - Both (iPhone and iPad)
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **Screen/Feature:** Supplier App - Business Configuration Backup
- **Description:** Both backup export methods in supplier app are non-functional. "Save to File" doesn't open file picker/share sheet, and "Save to Photos" doesn't respond or prompt for photo library permission.
- **Reproduction Steps:**
  1. Open supplier app (iPhone or iPad)
  2. Create/select a business
  3. Go to business configuration/settings screen
  4. Tap "Save Configuration to File" button
  5. Nothing happens - no file picker or share sheet appears
  6. Go back and tap "Save to Photos" button
  7. Nothing happens - no permission prompt, no confirmation, no photo saved
  8. Test in both simple mode and secure mode - same behavior
- **Expected Behavior:** 
  - "Save to File" should open iOS share sheet with options to save/share QR backup
  - "Save to Photos" should prompt for photo library permission (if not granted), then save QR code image to Photos app
- **Actual Behavior:** 
  - Both buttons appear to do nothing
  - No error messages shown to user
  - No permission prompts appear
- **Impact:** 
  - Suppliers cannot backup their business configuration
  - Cannot clone business to another device (critical feature)
  - Lose all data if device is lost/replaced
  - Blocks multi-device testing scenarios
- **Workaround:** None - feature completely broken
- **Fix Required:** 
  - Check iOS permissions in Info.plist (NSPhotoLibraryAddUsageDescription)
  - Check share_plus package implementation
  - Check image_gallery_saver package implementation
  - Add error handling to show user what went wrong
  - Test on both iPhone and iPad (different share sheet behavior)
- **Estimated Effort:** 2-3 hours
- **Assigned To:**
- **Target Build:** Build 5
- **Notes:** This is a regression - feature worked during development. May be iOS 17 permission changes or TestFlight build configuration issue. High priority because it blocks business backup/recovery testing.

### TEST-003: Supplier Restore Business QR Scanner Issues
- **Source:** Testing - Both (iPhone and iPad)
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **Screen/Feature:** Supplier App - Restore Business from QR Code
- **Description:** QR scanner for restoring business configuration has multiple camera orientation/control issues. Camera orientation is incorrect, and camera control buttons (flip and rotate 90°) are non-functional. An information bar may be partially obscuring the buttons.
- **Reproduction Steps:**
  1. Open supplier app (iPhone or iPad)
  2. Navigate to "Restore Business" or "Import from QR Code" screen
  3. Camera opens but orientation is wrong (sideways or upside down)
  4. Tap "Flip Camera" button (front/back camera switch)
  5. Nothing happens - camera doesn't switch
  6. Tap "Rotate 90°" button
  7. Nothing happens - camera orientation doesn't change
  8. Notice information bar at top/bottom may be overlapping the buttons
  9. Same behavior on both iPhone and iPad
- **Expected Behavior:** 
  - Camera should open in correct orientation for device
  - Flip button should switch between front/rear cameras
  - Rotate 90° button should rotate camera view
  - All buttons should be clearly visible and tappable
- **Actual Behavior:** 
  - Camera opens in wrong orientation
  - Control buttons don't respond to taps
  - Information bar may be covering buttons (hit target issue)
  - User cannot adjust camera to scan backup QR codes
- **Impact:** 
  - Cannot restore business from backup QR code
  - Blocks multi-device business cloning
  - Recovery from backup impossible
  - Critical for disaster recovery scenario
- **Workaround:** Try different device orientations (portrait/landscape), but no guaranteed workaround
- **Fix Required:** 
  - Fix camera orientation detection/initialization
  - Debug button tap handlers (check z-index, hit testing)
  - Adjust layout to prevent information bar overlap
  - Test camera controls on both iPhone and iPad orientations
  - May need to adjust QR scanner widget constraints
- **Estimated Effort:** 2-3 hours
- **Assigned To:**
- **Target Build:** Build 5
- **Notes:** Related to QR scanning camera implementation. May share root cause with any other QR scanner issues. Critical because restoring from backup is key feature for business continuity.

### TEST-004: Customer QR Scanner Camera Controls Not Working
- **Source:** Testing - Both (iPhone and iPad)
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **Screen/Feature:** Customer App - QR Scanner (Add Card, Stamp Request)
- **Description:** Customer app QR scanner camera control buttons (flip and rotate 90°) are non-functional, preventing users from adjusting camera orientation to scan QR codes.
- **Reproduction Steps:**
  1. Open customer app (iPhone or iPad)
  2. Navigate to "Add Card" or show "Stamp Request" QR
  3. QR scanner opens
  4. Tap "Flip Camera" button to switch front/back camera
  5. Nothing happens - camera doesn't switch
  6. Tap "Rotate 90°" button
  7. Nothing happens - camera orientation doesn't change
  8. Same behavior on both iPhone and iPad
- **Expected Behavior:** 
  - Flip button should switch between front/rear cameras
  - Rotate 90° button should rotate camera view 90 degrees
  - Users can adjust camera to scan QR codes from different angles
- **Actual Behavior:** 
  - Both control buttons don't respond to taps
  - Camera orientation cannot be adjusted
  - Users stuck with default camera orientation
- **Impact:** 
  - Difficult to scan QR codes in certain orientations
  - Cannot switch to better camera (front vs rear)
  - Poor UX when scanning cards or showing stamps
- **Workaround:** Physically rotate device or QR code, but awkward
- **Fix Required:** 
  - Debug camera control button tap handlers
  - Check mobile_scanner package camera control implementation
  - May share root cause with TEST-003 (supplier scanner)
  - Test on both iPhone and iPad
- **Estimated Effort:** 2-3 hours
- **Assigned To:**
- **Target Build:** Build 5
- **Notes:** Same symptoms as TEST-003 in supplier app. Likely shared QR scanner component issue.

### TEST-005: Secure Mode Redemption Creates Duplicate Empty Cards
- **Source:** Testing - Both (iPhone and iPad)
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **Screen/Feature:** Customer App - Secure Mode Card Redemption
- **Description:** When redeeming a full card in secure mode, the system creates an additional empty card even when an existing partially-filled card already exists. This creates duplicate cards for the same business.
- **Reproduction Steps:**
  1. Open customer app in secure mode
  2. Have a card that received stamps causing overflow:
     - Original card had X stamps
     - Added stamps pushed total over stampsRequired
     - Overflow stamps created a new card (correct behavior)
  3. Fill the original card to completion
  4. Redeem the full card (show redemption QR to supplier)
  5. After redemption, check card list
  6. Notice a NEW empty card was created
  7. Now have: redeemed card + overflow card with stamps + NEW empty card
- **Expected Behavior:** 
  - On redemption, if an existing card with available space exists, use that
  - Only create new card if no cards with available space exist
  - Should have: redeemed card + overflow card (no new empty card)
- **Actual Behavior:** 
  - Always creates new empty card on redemption
  - Doesn't check for existing cards with space
  - Results in multiple cards for same business
- **Impact:** 
  - Card list clutter with duplicate business cards
  - Confusing UX - which card should I use?
  - Defeats purpose of overflow card logic
  - Not a blocker but poor user experience
- **Workaround:** Manually delete extra empty cards, but tedious
- **Fix Required:** 
  - Check card redemption logic in secure mode
  - Before creating new card, search for existing cards with space
  - Only create new card if needed
  - May need to refactor card creation logic in redemption handler
- **Estimated Effort:** 2-3 hours
- **Assigned To:**
- **Target Build:** Build 5
- **Notes:** Business logic issue in card lifecycle management. Related to overflow stamp handling.

### TEST-007: Simple Mode Stamp Rate Limit Too Short
- **Source:** Testing - Both (iPhone and iPad)
- **Status:** 📋 BACKLOG
- **Priority:** HIGH
- **Screen/Feature:** Customer App - Simple Mode Stamp Scanning
- **Description:** The rate limiter on stamp scanning in simple mode is too short (currently ~1 second), allowing rapid duplicate stamps. Rate limit should be ~5 seconds to prevent accidental double-stamping while remaining user-friendly.
- **Reproduction Steps:**
  1. Open customer app with simple mode card
  2. Show stamp request QR to supplier
  3. Immediately show QR again (within 1-2 seconds)
  4. Second stamp is added (or attempted)
  5. Too easy to accidentally get duplicate stamps
- **Expected Behavior:** 
  - In simple mode, enforce ~5 second cooldown between stamps
  - Show user-friendly message: "Please wait X seconds before next stamp"
  - Prevent accidental rapid double-stamping
  - Secure mode uses crypto validation (no rate limit needed)
- **Actual Behavior:** 
  - Rate limit is ~1 second (too short)
  - Easy to accidentally scan twice
  - No clear feedback on cooldown time
- **Impact:** 
  - Users can accidentally get duplicate stamps
  - Businesses may lose revenue to accidental double-stamps
  - Simple mode needs better fraud prevention
- **Workaround:** Manually wait between stamps, but error-prone
- **Fix Required:** 
  - **Immediate:** Change constant from 1000ms to 5000ms in rate_limiter.dart
  - **Better:** Make rate limit configurable per business (supplier preference)
  - **Suggested Implementation:**
    - Add `stampRateLimitSeconds` field to Business model (default: 5)
    - Supplier sets this during business creation/editing
    - Include in simple mode card issuance QR code data
    - Customer app reads from card metadata and enforces that business's rate limit
    - Allows businesses to set their own fraud prevention policy
  - **Configuration UI:** Add to supplier business setup screen:
    - "Stamp Rate Limit (seconds): [5] slider (1-30 range)"
    - "Time required between stamps to prevent accidental duplicates"
- **Estimated Effort:** 
  - Quick fix (constant change): 5 minutes
  - Full configurable solution: 2-3 hours
- **Assigned To:**
- **Target Build:** Build 5 (quick fix), Build 6-10 (configurable)
- **Notes:** Simple mode only - secure mode uses cryptographic signatures which prevent duplicate stamps inherently. This is a business policy setting that should be flexible per supplier.

### TEST-006: No Filter to Hide Redeemed Cards
- **Source:** Testing - Both (iPhone and iPad)
- **Status:** 📋 BACKLOG
- **Priority:** MEDIUM
- **Screen/Feature:** Customer App - Card List
- **Description:** Card list shows all cards including redeemed ones. No option to filter or hide redeemed cards, leading to clutter as users accumulate redeemed cards over time.
- **Reproduction Steps:**
  1. Open customer app
  2. View card list on home screen
  3. Notice redeemed cards are mixed with active cards
  4. No filter toggle, button, or menu option to hide redeemed cards
- **Expected Behavior:** 
  - Filter toggle or setting to hide/show redeemed cards
  - Default view could show only active cards
  - User can choose to view redeemed cards if desired
- **Actual Behavior:** 
  - All cards shown together
  - No way to hide redeemed cards
  - List becomes cluttered over time
- **Impact:** 
  - Poor UX as card count grows
  - Difficulty finding active cards
  - Visual clutter
  - Not blocking but degrades experience
- **Workaround:** Manually scroll past redeemed cards
- **Fix Required:** 
  - Add filter toggle to card list screen (e.g., "Show Redeemed Cards" switch)
  - Update card query to filter based on redemption status
  - Persist filter preference in local storage
  - Consider separate tabs: Active / Redeemed
- **Estimated Effort:** 1-2 hours
- **Assigned To:**
- **Target Build:** Build 10+
- **Notes:** Enhancement request. Improves UX but not critical for pilot testing.

---

## 📊 Defect Summary Statistics

### By Priority
- 🔴 CRITICAL: 2 (Code Review) + 1 (Testing) = **3 total**
- 🟠 HIGH: 4 (Code Review) + 5 (Testing) = **9 total**
- 🟡 MEDIUM: 4 (Code Review) + 1 (Testing) = **5 total**
- 🔵 LOW: 4 (Code Review) + 0 (Testing) = **4 total**
- **TOTAL: 21 defects tracked**

### By Status
- 📋 BACKLOG: 16
- 🚧 IN PROGRESS: 0
- ✅ FIXED: 5

### By Source
- Code Review: 14
- Testing: 7

### By Target Build
- Build 5 (Critical fixes): 9 defects (8 full fixes + 1 quick fix)
- Build 6-10 (High priority): 5 defects (4 code review + 1 configurable rate limit)
- Build 10+ (Medium priority): 5 defects
- Build 10+ (Medium priority): 4 defects
- v0.3.0 (Low priority): 4 defects

---

## 🎯 Release Planning

### Build 5 - Critical Bug Fixes
**Target Date:** [Set after testing complete]  
**Focus:** Fix showstopper bugs from code review

**Must Fix:**
- [x] TEST-001: Fix version number synchronization (FIXED - Build 5)
- [ ] CR-001: Fix public key encoding (30 min)
- [ ] CR-002: Remove debug logging (1-2 hrs)
- [ ] CR-005: Remove/complete TODO (15 min)
- [ ] TEST-001: Fix version number synchronization (2-3 hrs)
- [ ] TEST-002: Fix supplier backup/export functionality (2-3 hrs)
- [ ] TEST-003: Fix supplier restore QR scanner issues (2-3 hrs)
- [ ] TEST-004: Fix customer QR scanner camera controls (2-3 hrs)
- [ ] TEST-005: Fix secure mode duplicate card creation (2-3 hrs)
- [ ] TEST-007: Quick fix stamp rate limit to 5 seconds (5 min)

**Estimated Total Effort:** 13-18 hours  
**Testing Required:** Full regression + secure mode testing + version verification + backup/export testing + restore/camera testing + card lifecycle testing + rate limit testing

**Note:** TEST-007 full configurable solution (2-3 hrs) deferred to Build 6-10

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
