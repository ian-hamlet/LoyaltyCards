# Build 46 - Testing Checklist

**Version:** v0.1.0 (Build 46)  
**Date:** April 12, 2026  
**Purpose:** Systematic device testing before TestFlight deployment

---

## 📱 Pre-Test Setup

### iPhone (Customer App)
- [ ] Device: iPhone _____________ (model)
- [ ] iOS Version: _____________
- [ ] Build deployed successfully
- [ ] App launches without errors
- [ ] Database initializes correctly

### iPad (Supplier App)
- [ ] Device: iPad _____________ (model)
- [ ] iOS Version: _____________
- [ ] Build deployed successfully
- [ ] App launches without errors
- [ ] Database initializes correctly

### Create Test Business
- [ ] Business Name: "Test Coffee Shop"
- [ ] Stamps Required: 10
- [ ] Brand Color: (any)
- [ ] Logo Icon: Coffee cup
- [ ] Keys generated successfully
- [ ] Dashboard displays correctly

---

## ✅ Core Functionality Tests

### Test 1: Basic Card Issuance
**Expected Time:** 5 minutes

- [ ] iPad: Navigate to "Issue New Card"
- [ ] iPad: Set initial stamps to 0
- [ ] iPad: QR code displays
- [ ] iPhone: Scan QR code
- [ ] iPhone: Card appears in wallet
- [ ] iPhone: Card shows 0/10 stamps
- [ ] iPhone: Business name correct
- [ ] iPhone: Brand color matches

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 2: Single Stamp Addition
**Expected Time:** 5 minutes

- [ ] iPhone: Open card from Test 1
- [ ] iPhone: Tap "Show QR for Stamp"
- [ ] iPhone: Customer QR displays
- [ ] iPad: Navigate to "Add Stamp"
- [ ] iPad: Scan customer QR
- [ ] iPad: "How many stamps?" dialog appears
- [ ] iPad: Select "1"
- [ ] iPad: Stamp token QR displays
- [ ] iPhone: Scan stamp QR
- [ ] iPhone: Haptic feedback received
- [ ] iPhone: Success message shows
- [ ] iPhone: Card now shows 1/10 stamps

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 3: Multi-Stamp Addition
**Expected Time:** 5 minutes

- [ ] Using same card (now at 1/10)
- [ ] iPhone: Show QR for Stamp
- [ ] iPad: Scan customer QR
- [ ] iPad: Select "3" stamps
- [ ] iPhone: Scan stamp token
- [ ] iPhone: Card now shows 4/10 stamps
- [ ] Verify: Math is correct (1 + 3 = 4)

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 4: Card Completion & Redemption
**Expected Time:** 10 minutes

- [ ] Using same card (now at 4/10)
- [ ] Add 6 more stamps to reach 10/10
- [ ] iPhone: Card shows "Complete!" badge
- [ ] iPhone: Card color changes (if implemented)
- [ ] iPhone: Tap "Show QR for Redemption"
- [ ] iPhone: Redemption QR displays
- [ ] iPad: Navigate to "Redeem Card"
- [ ] iPad: Scan redemption QR
- [ ] iPad: Confirmation dialog appears
- [ ] iPad: Confirm redemption
- [ ] iPad: Success message
- [ ] iPhone: Scan redemption token
- [ ] iPhone: Card marked as redeemed
- [ ] iPhone: New card auto-created (0/10)

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 5: Pre-Loaded Card Issuance
**Expected Time:** 5 minutes

- [ ] iPad: Issue New Card
- [ ] iPad: Set initial stamps to 5
- [ ] iPhone: Scan card issuance QR
- [ ] iPhone: Card appears with 5/10 stamps
- [ ] Verify: Correct initial stamp count

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 6: Overflow Mechanics
**Expected Time:** 10 minutes

- [ ] Create card with 8/10 stamps
- [ ] iPad: Add 5 stamps
- [ ] iPhone: Scan stamp token
- [ ] iPhone: Original card shows 10/10
- [ ] iPhone: New card created with 3/10
- [ ] Verify: 8 + 5 = 10 (original) + 3 (new)
- [ ] Redeem original card
- [ ] Verify: New card still has 3 stamps

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 7: Exact Completion (No Overflow)
**Expected Time:** 5 minutes

- [ ] Create card with 8/10 stamps
- [ ] iPad: Add exactly 2 stamps
- [ ] iPhone: Card shows 10/10, complete
- [ ] Verify: No new card created
- [ ] Redeem card
- [ ] Verify: Only one new blank card created

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

## 🎯 UX & Polish Tests

### Test 8: Search Functionality
**Expected Time:** 5 minutes

- [ ] iPhone: Have 3+ different business cards
- [ ] iPhone: Tap search bar
- [ ] iPhone: Type partial business name
- [ ] Verify: Filtered results correct
- [ ] Verify: Clear button works
- [ ] Verify: Empty state shows "No matches"

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 9: Haptic Feedback
**Expected Time:** 5 minutes

Test haptics on:
- [ ] iPhone: Search typing (selection clicks)
- [ ] iPhone: Pull to refresh (medium)
- [ ] iPhone: Card tap (light)
- [ ] iPad: Color selection (selection)
- [ ] iPad: Logo selection (selection)
- [ ] iPad: Stamp count selection (selection)
- [ ] iPad: Create business (medium)
- [ ] iPad: Delete business confirmation (error)

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 10: "How It Works" Screens
**Expected Time:** 5 minutes

**Supplier App:**
- [ ] iPad: Tap help icon (?)
- [ ] Verify: 4 steps display correctly
- [ ] Verify: Security section visible
- [ ] Verify: QR code timing section visible
- [ ] Verify: Offline section visible

**Customer App:**
- [ ] iPhone: Tap help icon (?)
- [ ] Verify: 4 steps display correctly
- [ ] Verify: Privacy section visible
- [ ] Verify: Security section visible
- [ ] Verify: QR timing section visible
- [ ] Verify: Offline section visible

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 11: Loading States
**Expected Time:** 3 minutes

- [ ] iPhone: Kill and restart app
- [ ] Verify: Skeleton loaders show during card load
- [ ] Verify: Skeleton loaders disappear when data loads
- [ ] iPad: Navigate between screens
- [ ] Verify: Loading indicators show appropriately

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 12: AppFeedback Messages
**Expected Time:** 5 minutes

Test that all messages use AppFeedback (not SnackBar):
- [ ] Success message (green, checkmark icon)
- [ ] Error message (red, X icon, dismissible)
- [ ] Info message (blue, info icon)
- [ ] Warning message (orange, warning icon)

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

## 🔧 Edge Cases & Error Scenarios

### Test 13: QR Code Expiration
**Expected Time:** 5 minutes

- [ ] iPad: Generate card issuance QR
- [ ] Wait 2+ minutes (past expiration)
- [ ] iPhone: Attempt to scan expired QR
- [ ] Verify: Error message or refresh prompt
- [ ] iPad: Tap refresh button
- [ ] Verify: New QR generates
- [ ] iPhone: Scan new QR successfully

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 14: Invalid QR Codes
**Expected Time:** 5 minutes

- [ ] iPhone: Scan random QR code (not loyalty card)
- [ ] Verify: Error message displays
- [ ] Verify: App doesn't crash
- [ ] iPad: Scan random QR code
- [ ] Verify: Error message displays
- [ ] Verify: App doesn't crash

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 15: Camera Orientations
**Expected Time:** 10 minutes

Test scanning in different device orientations:
- [ ] Portrait (normal)
- [ ] Landscape left
- [ ] Landscape right
- [ ] Portrait upside down
- [ ] Verify: Manual rotation buttons work
- [ ] Verify: QR codes scan in all orientations

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 16: Low Light Conditions
**Expected Time:** 5 minutes

- [ ] Test scanning in dimly lit room
- [ ] Test scanning with screen brightness low
- [ ] Verify: Camera performs acceptably
- [ ] Note: Any difficulty scanning?

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 17: App Backgrounding
**Expected Time:** 5 minutes

- [ ] Start a scan operation
- [ ] Background the app (home button/gesture)
- [ ] Wait 10 seconds
- [ ] Return to app
- [ ] Verify: App resumes correctly
- [ ] Verify: Camera still works

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 18: Multiple Cards from Same Business
**Expected Time:** 5 minutes

- [ ] Have 1 card from "Test Coffee Shop" (completed)
- [ ] Issue another card from same business
- [ ] iPhone: Verify both cards show in wallet
- [ ] Verify: Cards distinguished properly
- [ ] Verify: Can operate on each independently

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 19: Many Different Businesses
**Expected Time:** 15 minutes

- [ ] Create 5 different test businesses on iPad
- [ ] Issue card from each
- [ ] iPhone: Verify all 5 cards in wallet
- [ ] Test search with 5 cards
- [ ] Test scrolling performance with 5 cards

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

## ⚡ Performance Tests

### Test 20: Extended Use Session
**Expected Time:** 60 minutes

- [ ] Perform 20+ card operations continuously
- [ ] Mix of: issue cards, add stamps, redeem
- [ ] Monitor for:
  - [ ] Memory leaks (app slowing down)
  - [ ] UI lag or stuttering
  - [ ] Camera degradation
  - [ ] App crashes
- [ ] Note battery drain percentage: _____%

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 21: App Launch Time
**Expected Time:** 5 minutes

- [ ] Force quit both apps
- [ ] iPhone: Launch customer app
- [ ] Record time to interactive: _____ seconds
- [ ] iPad: Launch supplier app
- [ ] Record time to interactive: _____ seconds
- [ ] Verify: < 3 seconds is acceptable

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

## 🎨 Visual & UX Review

### Test 22: Typography Consistency
**Expected Time:** 10 minutes

Review both apps for consistent font sizes:
- [ ] All titles use AppTypography.titleLarge/Medium
- [ ] All body text uses AppTypography.bodyLarge/Medium
- [ ] All labels use AppTypography.labelSmall/Medium
- [ ] No hardcoded font sizes (except exceptions)

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 23: Spacing Consistency
**Expected Time:** 10 minutes

Review both apps for consistent spacing:
- [ ] All padding uses AppSpacing constants
- [ ] No hardcoded padding values
- [ ] Spacing feels consistent between screens

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

### Test 24: Dialog UX
**Expected Time:** 5 minutes

- [ ] All dialog buttons visible without scrolling
- [ ] Cancel buttons on left
- [ ] Confirm buttons on right
- [ ] Destructive actions use red color
- [ ] All dialogs have haptics

**Result:** ✅ PASS / ❌ FAIL  
**Notes:** _________________________________

---

## 📊 Final Assessment

### Summary

| Category | Pass | Fail | Notes |
|----------|------|------|-------|
| Core Functionality (Tests 1-7) | ___ | ___ | _____________ |
| UX & Polish (Tests 8-12) | ___ | ___ | _____________ |
| Edge Cases (Tests 13-19) | ___ | ___ | _____________ |
| Performance (Tests 20-21) | ___ | ___ | _____________ |
| Visual Review (Tests 22-24) | ___ | ___ | _____________ |

### Critical Issues Found
1. _________________________________________
2. _________________________________________
3. _________________________________________

### Minor Issues Found
1. _________________________________________
2. _________________________________________
3. _________________________________________

### Overall Assessment
- [ ] ✅ **READY FOR TESTFLIGHT** - No critical issues, minor issues acceptable
- [ ] ⚠️ **NEEDS FIXES** - Critical issues must be resolved first
- [ ] ❌ **NOT READY** - Major rework required

### Next Steps
_____________________________________________
_____________________________________________
_____________________________________________

---

**Tester Name:** _____________________  
**Date Tested:** _____________________  
**Duration:** _____ hours  
**Signature:** _____________________

---

Last Updated: April 12, 2026
