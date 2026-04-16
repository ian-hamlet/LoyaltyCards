# Test Plan: Business Import Navigation Fix (TEST-014 & TEST-015)
**Build:** 16  
**Date:** April 16, 2026  
**Device:** iPad/iPhone  
**Tester:** Ian

---

## 🎯 Objective

Verify that after importing or creating a business, the user **cannot** navigate back to the onboarding screen to create duplicate businesses, and that camera errors don't cause infinite loops.

---

## 🐛 Original Bug (What You Discovered)

**Your Reproduction Steps:**
1. Had supplier app running with business configured
2. Went to Settings → Delete All Data (debug mode)
3. App navigated to SupplierOnboarding screen
4. Selected "Recover from Backup"
5. Rotated camera 90° (twice in logs)
6. Scanned recovery QR for "Secure Paws"
7. **Import succeeded** ✅
8. App navigated to SupplierHome
9. **Tapped back button** ← BUG!
10. **Returned to SupplierOnboarding** ← BUG!
11. **Could create new business** ← BUG!

**Root Cause:** Navigation used `pushReplacement` which only replaced ImportBusinessScreen but left SupplierOnboarding in the stack.

---

## ✅ Expected Behavior After Fix

After importing or creating a business:
- **Navigation stack is completely cleared**
- **Back button either:**
  - Not visible/disabled, OR
  - Exits the app (closes supplier app)
- **Cannot return to SupplierOnboarding**
- **Cannot create duplicate business**

---

## 📋 Test Case 1: Import Business - No Back Navigation

### Setup
- iPad/iPhone with Supplier app installed
- Have a recovery QR code ready (printed or on another device)
- Optional: Have existing business to delete first

### Steps

**Step 1: Get to Clean State**
1. Open Supplier app
2. If business exists: Settings → Dangerous Operations → Delete All Data
3. Confirm deletion
4. **VERIFY:** App shows SupplierOnboarding screen

**Step 2: Import Business**
5. Tap **"Recover from Backup"** button
6. **VERIFY:** Camera opens with ImportBusinessScreen
7. Rotate camera if needed (90°, 180° buttons)
8. Scan recovery QR code
9. **VERIFY:** Progress indicator shows: "Restoring business..."
10. **VERIFY:** Success message appears: "Business restored: [Name]"
11. **VERIFY:** App navigates to SupplierHome

**Step 3: Attempt Back Navigation (THE BUG TEST)**
12. Look for back button in top-left of screen
13. **CRITICAL TEST:** Tap back button OR swipe from left edge
14. **EXPECTED RESULT:** 
    - Back button does nothing, OR
    - App minimizes/exits to home screen
    - **MUST NOT** return to SupplierOnboarding
15. **VERIFY:** Still on SupplierHome with imported business visible

**Step 4: Verify No Duplicate Business Creation**
16. Try to navigate to business creation
    - Check menu/navigation for "Create Business"
    - Try any navigation paths you can find
17. **EXPECTED:** No way to create second business without deleting first

### ✅ Pass Criteria
- [ ] Import succeeds and navigates to SupplierHome
- [ ] Back button does NOT return to SupplierOnboarding
- [ ] Cannot create duplicate business after import
- [ ] Business data is intact and usable

### ❌ Fail Criteria
- [ ] Can navigate back to SupplierOnboarding after import
- [ ] Can create second business without deleting first
- [ ] Business data lost or corrupted

---

## 📋 Test Case 2: Create New Business - No Back Navigation

### Setup
- Fresh app install OR reset via Settings → Delete All Data

### Steps

**Step 1: Get to Clean State**
1. Open Supplier app
2. If needed: Delete existing business
3. **VERIFY:** SupplierOnboarding screen appears

**Step 2: Create New Business**
4. Enter business name: "Test Business"
5. Set stamps required: 10
6. Choose brand color
7. Choose logo
8. Select operation mode: Secure
9. Tap **"Create Business"** button
10. **VERIFY:** Progress indicator shows
11. **VERIFY:** Success feedback (haptic + visual)
12. **VERIFY:** App navigates to SupplierHome

**Step 3: Attempt Back Navigation**
13. Look for back button in top-left
14. Tap back button OR swipe from left edge
15. **EXPECTED:** 
    - Back button does nothing, OR
    - App exits to home screen
    - **MUST NOT** return to SupplierOnboarding

**Step 4: Verify Business Setup Complete**
16. **VERIFY:** SupplierHome shows created business
17. **VERIFY:** Can issue cards, see statistics, etc.
18. Try to access business creation again
19. **VERIFY:** No way to create second business

### ✅ Pass Criteria
- [ ] Business creation succeeds
- [ ] No back navigation to SupplierOnboarding
- [ ] Business fully functional
- [ ] Cannot create duplicate business

---

## 📋 Test Case 3: Import When Business Already Exists (TEST-015)

### Setup
- Supplier app with business already configured
- Recovery QR code ready

### Steps

**Step 1: Start with Existing Business**
1. Open Supplier app
2. **VERIFY:** Business already configured (see SupplierHome)
3. Note business name for verification

**Step 2: Attempt Import (Should Be Blocked)**
4. Navigate: Settings → ? (try to find import option)
   - **NOTE:** May need to navigate via deep link or direct screen launch
   - Alternative: This test may not be accessible in normal flow
5. If ImportBusinessScreen somehow opens:
   - **VERIFY:** Error message appears IMMEDIATELY
   - **VERIFY:** Message: "Business already configured: [Name]"
   - **VERIFY:** Camera does NOT open
   - **VERIFY:** Shows "Go Back" button
6. Tap "Go Back"
7. **VERIFY:** Returns to previous screen cleanly

### ✅ Pass Criteria
- [ ] Cannot access import when business exists
- [ ] Clear error message if import screen accessed
- [ ] Camera never activates
- [ ] Can navigate back cleanly

---

## 📋 Test Case 4: Failed Import - Camera Loop Prevention (TEST-015)

### Setup
- Fresh app OR deleted business state
- Invalid QR code OR expired clone QR code ready

### Steps

**Step 1: Attempt Import with Invalid QR**
1. SupplierOnboarding → "Recover from Backup"
2. **VERIFY:** Camera opens
3. Scan **invalid** QR code (not a recovery/clone QR)
4. **VERIFY:** Error message appears
5. **CRITICAL:** Watch camera behavior after error
6. **EXPECTED:** Camera stops, no continuous scanning
7. **MUST NOT:** See infinite scan/reject loop

**Step 2: Attempt Second Scan After Error**
8. Dismiss error message if shown as dialog
9. **VERIFY:** Camera is stopped (not active)
10. **VERIFY:** Error banner visible
11. Try scanning another QR code
12. **EXPECTED:** Scanner does not respond (camera stopped)

**Step 3: Clean Exit After Error**
13. Tap "Cancel" button
14. **VERIFY:** Returns to SupplierOnboarding cleanly
15. **VERIFY:** No app freeze or crash
16. **VERIFY:** Can start import process again if desired

### ✅ Pass Criteria
- [ ] Camera stops after error
- [ ] No infinite scan loop
- [ ] Error message is clear
- [ ] Can exit cleanly with Cancel button
- [ ] No app freeze or crash

### ❌ Fail Criteria
- [ ] Camera enters infinite loop (continuous capture/reject)
- [ ] Cannot exit import screen after error
- [ ] App freezes or crashes

---

## 📋 Test Case 5: Your Exact Reproduction Scenario

**This replicates your exact steps from the logs**

### Steps

1. ✅ Start with business configured: "simple pizza"
2. ✅ Settings → Delete All Data (debug mode kDebugMode)
3. ✅ Confirm deletion
4. ✅ **Log Check:** See "BUSINESS RESET COMPLETE"
5. ✅ Navigate to "Recover from Backup"
6. ✅ Rotate camera 90° (tap button)
7. ✅ Rotate camera 90° again (tap button again)
8. ✅ **Log Check:** See rotation offset changes to 1 (90°)
9. ✅ Scan recovery QR for "Secure Paws"
10. ✅ **Log Check:** See all import steps succeed:
    - Step 1: Parsing QR data
    - Step 2: Verifying signature ✅
    - Step 3: Recovery backup (no expiry)
    - Step 4: No existing business found
    - Step 5: Converting backup to Business model
    - Step 6-7: Keys stored
    - Step 8: Business saved to database
    - "Business import complete: Secure Paws"
    - **"Camera stopped successfully"** ← NEW (fix)
11. ✅ **VERIFY:** Navigates to SupplierHome
12. ⚠️ **CRITICAL TEST:** Try to go back
13. ❌ **EXPECTED (BEFORE FIX):** Could return to SupplierOnboarding
14. ✅ **EXPECTED (AFTER FIX):** CANNOT return to SupplierOnboarding
15. ✅ **EXPECTED (AFTER FIX):** CANNOT create "simple pizza" again

### What Changed in Logs (After Fix)

**Before Fix:**
```
Navigator.pushReplacement() → SupplierHome
Back button → SupplierOnboarding still in stack → Can create business again
```

**After Fix:**
```
Navigator.pushAndRemoveUntil() → SupplierHome
(route) => false  ← Clears ALL previous routes
Back button → Nothing (or exits app)
```

### ✅ Pass Criteria
- [ ] Logs show "Camera stopped successfully" after import
- [ ] Back button does NOT return to SupplierOnboarding
- [ ] Cannot create duplicate business
- [ ] Navigation stack is clean

---

## 🔍 Debugging Tips

### Check Logs for Success

**Look for this sequence:**
```
[BUSINESS] Business import complete: [Name]
[Import] Camera stopped successfully  ← NEW
[Backup] Generating recovery backup...  ← Means navigated to home successfully
```

**Red Flags (Should NOT see):**
```
[Import] Error stopping camera: [error]  ← Camera stop failed
Multiple scan attempts after first success  ← Loop bug
Business inserted twice  ← Duplicate creation
```

### iOS Xcode Console Checks

**Good signs:**
- No navigation warnings
- No "popped view controller not in stack" errors
- Clean navigation transitions

**Bad signs:**
- "Unbalanced calls to begin/end appearance transitions"
- Navigation stack corruption warnings

---

## 📝 Test Results Template

### Test Execution: [Date/Time]
**Device:** [iPad/iPhone model]  
**iOS Version:** [version]  
**Build:** 16

| Test Case | Result | Notes |
|-----------|--------|-------|
| TC1: Import No Back Navigation | ⬜ Pass / ⬜ Fail | |
| TC2: Create No Back Navigation | ⬜ Pass / ⬜ Fail | |
| TC3: Import When Exists | ⬜ Pass / ⬜ Fail | |
| TC4: Failed Import Loop | ⬜ Pass / ⬜ Fail | |
| TC5: Your Exact Scenario | ⬜ Pass / ⬜ Fail | |

### Issues Found
1. 
2. 
3. 

### Logs Attached
- [ ] Full Xcode console log
- [ ] Screenshots of failure states
- [ ] Video recording if needed

---

## 🎯 Summary

**Primary Test:** Test Case 5 (Your exact scenario)  
**Critical Verification:** After import, back button must NOT return to SupplierOnboarding  
**Secondary Tests:** TC1-4 cover edge cases and error handling

**If TC5 passes → Fix is verified! ✅**  
**If TC5 fails → More investigation needed ❌**
