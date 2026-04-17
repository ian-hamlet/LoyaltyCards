# Build 21 - Testing Guide

**Version:** 0.2.0+21  
**Focus:** Security vulnerability fixes (V-002, V-005)  
**Test Date:** _________________  
**Tester:** _________________  
**Devices:** _________________

---

## 🎯 Testing Objectives

1. Verify biometric authentication protects private keys (V-002)
2. Verify device mismatch detection and warnings (V-005)
3. Confirm database migration from Build 20 → Build 21
4. Regression test: Ensure existing features still work
5. Security validation: Verify fixes work as designed

---

## 📋 Pre-Test Setup

### Prerequisites
- [ ] Build 20 installed on Device A (iPhone/iPad)
- [ ] Build 21 compiled and ready to install
- [ ] Second device available (Device B) for multi-device testing
- [ ] Face ID/Touch ID enabled on test devices
- [ ] Test business configured in Supplier App (Build 20)
- [ ] Test customer cards in Customer App (Build 20)

### Upgrade Path Test
- [ ] Note: DO NOT uninstall Build 20 before installing Build 21
- [ ] Install Build 21 over Build 20 to test database migration
- [ ] Keep Device B at Build 20 initially (for device mismatch testing)

---

## 🔒 CRITICAL: V-002 Biometric Authentication Tests

### Test 1: Recovery Backup - Biometric Auth Required
**Time:** 5 minutes  
**Device:** Supplier App on Device A

**Steps:**
1. [ ] Open Supplier App (Build 21)
2. [ ] Navigate to Settings → Create Recovery Backup
3. [ ] **Expected:** Face ID/Touch ID prompt appears
4. [ ] **Prompt text:** "Authenticate to view recovery backup QR code containing your private key"
5. [ ] Cancel authentication (press Cancel button)
6. [ ] **Expected:** Warning message appears
7. [ ] **Expected:** Navigates back to Settings (no QR shown)
8. [ ] Navigate to Settings → Create Recovery Backup again
9. [ ] This time authenticate successfully (Face ID/Touch ID)
10. [ ] **Expected:** Recovery QR code displays
11. [ ] **Expected:** QR code is valid and scannable

**Pass Criteria:**
- ✅ Biometric prompt appears immediately
- ✅ Prompt text mentions "private key"
- ✅ Cancelling auth prevents QR display
- ✅ Successful auth shows QR code
- ✅ QR code works for recovery

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

### Test 2: Clone Device - Biometric Auth Required
**Time:** 5 minutes  
**Device:** Supplier App on Device A

**Steps:**
1. [ ] Open Supplier App (Build 21)
2. [ ] Navigate to Settings → Clone to Another Device
3. [ ] **Expected:** Face ID/Touch ID prompt appears
4. [ ] **Prompt text:** "Authenticate to generate device clone QR code containing your private key"
5. [ ] Cancel authentication
6. [ ] **Expected:** Warning message appears
7. [ ] **Expected:** Navigates back to Settings (no QR shown)
8. [ ] Navigate to Settings → Clone to Another Device again
9. [ ] Authenticate successfully
10. [ ] **Expected:** Clone QR code displays with 5-minute countdown
11. [ ] **Expected:** QR code is valid

**Pass Criteria:**
- ✅ Biometric prompt appears immediately
- ✅ Prompt text mentions "private key"
- ✅ Cancelling auth prevents QR display
- ✅ Successful auth shows QR code
- ✅ Countdown timer works

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

### Test 3: Biometric Auth - Fallback to Passcode
**Time:** 3 minutes  
**Device:** Device with passcode but no biometrics enabled

**Steps:**
1. [ ] Use device WITHOUT Face ID/Touch ID (or disable biometrics)
2. [ ] Open Supplier App
3. [ ] Navigate to Settings → Create Recovery Backup
4. [ ] **Expected:** Passcode prompt appears as fallback
5. [ ] Enter passcode
6. [ ] **Expected:** QR code displays after successful passcode entry

**Pass Criteria:**
- ✅ Gracefully falls back to passcode
- ✅ No crash or error
- ✅ QR displays after passcode authentication

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

## 🔄 CRITICAL: V-005 Device Mismatch Detection Tests

### Test 4: Database Migration - Device ID Capture
**Time:** 5 minutes  
**Device:** Customer App on Device A (upgrade from Build 20)

**Steps:**
1. [ ] Verify Build 20 installed with existing cards
2. [ ] Note number of cards: _______
3. [ ] Install Build 21 over Build 20 (upgrade install)
4. [ ] Open Customer App
5. [ ] **Expected:** App launches normally (no crash)
6. [ ] **Expected:** All existing cards visible
7. [ ] Open any existing card
8. [ ] **Expected:** Card displays correctly
9. [ ] Navigate to Settings → Database Info (if available)
10. [ ] Check database version: **Expected: 6**

**Pass Criteria:**
- ✅ App upgrades smoothly (no crash)
- ✅ All cards from Build 20 still present
- ✅ Card details display correctly
- ✅ Database version = 6

**Result:** ✅ PASS / ❌ FAIL  
**Cards Before:** _______ **Cards After:** _______  
**Notes:** _______________________________________________

---

### Test 5: New Card Creation - Device ID Tracking
**Time:** 5 minutes  
**Devices:** Supplier App (Device A), Customer App (Device A)

**Steps:**
1. [ ] Supplier App: Generate card issuance QR
2. [ ] Customer App: Scan QR to receive new card
3. [ ] **Expected:** Card added successfully
4. [ ] Note card name: _______________________
5. [ ] Complete card by collecting all stamps
6. [ ] Customer App: Open completed card
7. [ ] **Expected:** Card shows as complete
8. [ ] **Expected:** Redemption QR can be generated

**Pass Criteria:**
- ✅ Card creation works normally
- ✅ Device ID captured during creation (not visible to user)
- ✅ Card functions normally

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

### Test 6: Same Device Redemption - No Warning
**Time:** 5 minutes  
**Devices:** Same device for card creation and redemption

**Steps:**
1. [ ] Customer App (Device A): Open completed card from Test 5
2. [ ] Customer App: Show redemption QR code
3. [ ] Supplier App (Device A): Scan redemption QR
4. [ ] **Expected:** NO device mismatch warning
5. [ ] **Expected:** Standard redemption confirmation dialog
6. [ ] Accept redemption
7. [ ] **Expected:** Redemption token generated
8. [ ] Customer App: Scan redemption token
9. [ ] **Expected:** Card marked as redeemed

**Pass Criteria:**
- ✅ NO device mismatch warning (same device)
- ✅ Redemption flow works normally
- ✅ Card redeems successfully

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

### Test 7: Different Device Redemption - Warning Shown
**Time:** 10 minutes  
**Devices:** Device A (card created), Device B (redemption attempt)

**Setup:**
1. [ ] Device A (Customer App Build 21): Create and complete a new card
2. [ ] Device A: Back up to iCloud
3. [ ] Device B: Restore from same iCloud backup (or use device clone)
4. [ ] Device B: Verify same card appears

**Steps:**
1. [ ] Device B (Customer App): Open the completed card
2. [ ] Device B: Generate redemption QR code
3. [ ] Device A (Supplier App): Scan redemption QR from Device B
4. [ ] **CRITICAL:** Device mismatch warning dialog should appear
5. [ ] **Dialog Title:** "Device Mismatch"
6. [ ] **Dialog Icon:** ⚠️ Warning (orange)
7. [ ] **Dialog Text:** Mentions card created on different device
8. [ ] **Dialog Lists Scenarios:**
   - Customer got new phone
   - Customer restored from backup
   - Card cloned/duplicated (fraud)
9. [ ] **Dialog Buttons:** "Cancel" and "Proceed Anyway"

**Test Path A - Cancel:**
10. [ ] Press "Cancel"
11. [ ] **Expected:** Returns to scanner, no redemption token generated

**Test Path B - Proceed:**
12. [ ] Device A: Scan redemption QR again
13. [ ] This time press "Proceed Anyway"
14. [ ] **Expected:** Standard redemption confirmation appears
15. [ ] Generate redemption token
16. [ ] Device B: Scan redemption token
17. [ ] **Expected:** Card redeemed successfully

**Pass Criteria:**
- ✅ Device mismatch warning appears (different device)
- ✅ Warning dialog has correct text and options
- ✅ "Cancel" aborts redemption
- ✅ "Proceed Anyway" allows redemption to continue
- ✅ Supplier has discretion to accept or reject

**Result:** ✅ PASS / ❌ FAIL  
**Warning Appeared:** YES / NO  
**Notes:** _______________________________________________

---

### Test 8: Old Cards (Pre-Build 21) - No Warning
**Time:** 3 minutes  
**Devices:** Card from Build 20 (no device ID)

**Steps:**
1. [ ] Use card created in Build 20 (before device tracking)
2. [ ] Complete the card (if not already complete)
3. [ ] Generate redemption QR
4. [ ] Scan with Supplier App
5. [ ] **Expected:** NO device mismatch warning
6. [ ] **Reason:** Old cards have deviceId = null (backward compatible)

**Pass Criteria:**
- ✅ Old cards work without warnings
- ✅ Backward compatibility maintained

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

## 🔍 Regression Testing

### Test 9: Simple Mode - Basic Flow
**Time:** 10 minutes

1. [ ] Create business in Simple Mode
2. [ ] Issue card to customer (0 initial stamps)
3. [ ] Customer: Add stamp (scan supplier QR)
4. [ ] **Expected:** 5-second rate limit prevents duplicate
5. [ ] Customer: Complete card (collect all stamps)
6. [ ] Customer: Self-redeem card
7. [ ] **Expected:** Redemption date/time displayed
8. [ ] **Expected:** New card auto-created

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

### Test 10: Secure Mode - Full Workflow
**Time:** 15 minutes

1. [ ] Create business in Secure Mode
2. [ ] Issue card with 2 initial stamps
3. [ ] Customer: Verify 2 stamps display
4. [ ] Supplier: Generate stamp QR (2-minute expiry)
5. [ ] Customer: Scan stamp QR before expiry
6. [ ] **Expected:** Countdown timer visible
7. [ ] Complete card
8. [ ] Customer: Generate redemption QR
9. [ ] Supplier: Scan customer's redemption QR
10. [ ] **Expected:** Redemption confirmation dialog
11. [ ] Generate redemption token
12. [ ] Customer: Scan redemption token
13. [ ] **Expected:** Card redeemed, new card created

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

### Test 11: Camera Rotation Persistence (TEST-012)
**Time:** 5 minutes

1. [ ] Open QR scanner (any screen)
2. [ ] Rotate camera 90° or 180°
3. [ ] Close scanner
4. [ ] Open scanner again
5. [ ] **Expected:** Rotation remembered from previous session

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

### Test 12: Redemption UI - Floating Action Button (TEST-010)
**Time:** 5 minutes  
**Device:** iPhone with small screen

1. [ ] Customer App: Open completed card (Secure Mode)
2. [ ] **Expected:** "Scan Confirmation" button visible at bottom
3. [ ] **Expected:** Button always accessible (no scrolling needed)
4. [ ] Scroll page up/down
5. [ ] **Expected:** Floating button stays visible
6. [ ] Tap "Scan Confirmation" button
7. [ ] **Expected:** Opens scanner for redemption token

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

## 🛡️ Security Validation Tests

### Test 13: V-003 Verification - QR Screenshot Reuse
**Time:** 5 minutes  
**Mode:** Secure Mode

**Steps:**
1. [ ] Supplier App: Generate stamp QR
2. [ ] Take screenshot of QR code
3. [ ] Customer App: Scan live QR (first time)
4. [ ] **Expected:** Stamp added successfully
5. [ ] Customer App: Scan screenshot of same QR
6. [ ] **Expected:** Stamp NOT added (duplicate ID rejected)
7. [ ] Check stamp count
8. [ ] **Expected:** Only 1 stamp added (not 2)

**Pass Criteria:**
- ✅ First scan succeeds
- ✅ Second scan of same QR fails
- ✅ Duplicate prevented by database PRIMARY KEY

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

### Test 14: V-004 Verification - Rate Limiting
**Time:** 5 minutes  
**Mode:** Simple Mode

**Steps:**
1. [ ] Supplier App: Display stamp QR
2. [ ] Customer App: Scan QR (first scan)
3. [ ] **Expected:** Stamp added
4. [ ] Immediately scan same QR again (within 5 seconds)
5. [ ] **Expected:** Rate limit message appears
6. [ ] **Message:** "Please wait X seconds before next stamp"
7. [ ] Wait 5+ seconds
8. [ ] Scan QR again
9. [ ] **Expected:** New stamp added successfully

**Pass Criteria:**
- ✅ First scan works
- ✅ Rapid second scan blocked (< 5 seconds)
- ✅ Third scan works (after cooldown)

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _______________________________________________

---

## 📊 Test Summary

### Critical Tests (Must Pass)
- [ ] Test 1: Recovery Backup Auth
- [ ] Test 2: Clone Device Auth
- [ ] Test 4: Database Migration
- [ ] Test 7: Device Mismatch Warning

### High Priority Tests
- [ ] Test 5: New Card Device Tracking
- [ ] Test 6: Same Device (No Warning)
- [ ] Test 9: Simple Mode Workflow
- [ ] Test 10: Secure Mode Workflow

### Regression Tests
- [ ] Test 11: Camera Rotation
- [ ] Test 12: Redemption UI
- [ ] Test 13: QR Reuse Prevention
- [ ] Test 14: Rate Limiting

---

## 🐛 Issues Found

### Issue 1
**Test:** _______________  
**Severity:** CRITICAL / HIGH / MEDIUM / LOW  
**Description:** _______________________________________________  
**Steps to Reproduce:** _______________________________________________  
**Expected:** _______________________________________________  
**Actual:** _______________________________________________  
**Screenshots:** _______________________________________________

### Issue 2
**Test:** _______________  
**Severity:** CRITICAL / HIGH / MEDIUM / LOW  
**Description:** _______________________________________________  
**Steps to Reproduce:** _______________________________________________  
**Expected:** _______________________________________________  
**Actual:** _______________________________________________  
**Screenshots:** _______________________________________________

---

## ✅ Sign-Off

**Tests Completed:** _____ / 14  
**Tests Passed:** _____  
**Tests Failed:** _____  
**Critical Issues:** _____  

**Recommendation:**
- [ ] ✅ APPROVED - Ready for wider TestFlight distribution
- [ ] ⚠️ APPROVED WITH NOTES - Minor issues, can proceed
- [ ] ❌ REJECTED - Critical issues found, needs fixes

**Tester Signature:** _________________  
**Date:** _________________  
**Notes:** _______________________________________________

---

## 📝 Additional Notes

**Performance Observations:**
_______________________________________________

**UX Feedback:**
_______________________________________________

**Suggestions for Future Builds:**
_______________________________________________
