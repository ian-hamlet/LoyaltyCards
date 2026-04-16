# LoyaltyCards v0.2.0 - TestFlight Testing Guide

**Version:** 0.2.0 (Build 4)  
**Date:** April 14, 2026  
**Platform:** iOS (TestFlight Internal Testing)  
**Tester:** Internal Pilot

---

## Apps Under Test

**Customer App:** LoyaltyCards - Digital Stamps  
**Supplier App:** LoyaltyCards Business

**Devices Required:**
- Minimum: 1 iPhone or iPad (can test with one device)
- Recommended: 2 devices (e.g., iPhone + iPad for full multi-device testing)

---

## Installation (Already Complete)

✅ TestFlight app installed  
✅ Both apps downloaded from TestFlight  
✅ Ready to test

---

## Testing Checklist Overview

- [ ] **Test 1:** Create Business (Supplier)
- [ ] **Test 2:** Issue Loyalty Card (Supplier → Customer)
- [ ] **Test 3:** Collect Stamps (Customer)
- [ ] **Test 4:** Redeem Reward (Customer)
- [ ] **Test 5:** Search & Organization (Customer)
- [ ] **Test 6:** Backup to Photos (Supplier)
- [ ] **Test 7:** Restore from Backup (Supplier)
- [ ] **Test 8:** Clone to Second Device (Supplier)
- [ ] **Test 9:** Secure Mode Comparison (Both)
- [ ] **Test 10:** Edge Cases & Stress Testing

---

## Priority 1: Critical Path Tests (Day 1)

### Test 1: Create Business Profile

**App:** LoyaltyCards Business (Supplier)  
**Device:** iPad or iPhone

**Steps:**
1. Open LoyaltyCards Business app
2. Tap **"Create Business Profile"**
3. Enter business details:
   - **Business Name:** "Test Coffee Shop"
   - **Color:** Any
   - **Logo:** Skip or upload test image
4. Choose **Operation Mode:**
   - Select **"Simple Mode"** (recommended for first test)
5. Configure stamps:
   - **Stamps Required:** 5
   - **Reward Description:** "Free Coffee"
6. Tap **"Create"**

**Expected Result:**
- Business created successfully
- Home screen shows business name and stats
- "Issue New Card" button visible

**✅ Pass / ❌ Fail**  
**Notes:**

---

### Test 2: Issue Loyalty Card

**Apps:** Supplier (iPad) → Customer (iPhone)  
**Prerequisites:** Test 1 complete

**Steps:**

**On Supplier Device (iPad):**
1. From home screen, tap **"Issue New Card"**
2. QR code appears on screen
3. Keep device steady for customer to scan

**On Customer Device (iPhone):**
1. Open **LoyaltyCards** app (customer)
2. Tap camera/scan button (usually center or top right)
3. Point camera at supplier's QR code
4. Wait for scan to register

**Expected Result:**
- Card appears in customer's wallet
- Shows 0/5 stamps (or 0 of your configured requirement)
- Business name and color displayed correctly

**✅ Pass / ❌ Fail**  
**Notes:**

---

### Test 3: Collect Stamps

**Apps:** Supplier (iPad) + Customer (iPhone)  
**Prerequisites:** Test 2 complete (card issued)

**Steps:**

**On Supplier Device (iPad):**
1. From home screen, view customer card list
2. Select the customer's card
3. Tap **"Add Stamps"** or similar button
4. QR code for stamp appears

**On Customer Device (iPhone):**
1. Open **LoyaltyCards** app
2. Open your loyalty card
3. Tap scan button
4. Scan the stamp QR from supplier device
5. Stamp should add (1/5)

**Repeat 4 more times** until card shows 5/5 stamps filled

**Expected Results:**
- Each stamp adds immediately
- Progress bar/counter updates (e.g., 1/5, 2/5, 3/5...)
- Card shows "full" when complete (5/5)
- Stamp history visible with timestamps
- Simple mode: 1-second cooldown between stamps (normal behavior)

**✅ Pass / ❌ Fail**  
**Notes:**

---

### Test 4: Redeem Reward (Simple Mode)

**App:** LoyaltyCards (Customer)  
**Device:** iPhone  
**Prerequisites:** Test 3 complete (card full - 5/5 stamps)

**Steps:**

**On Customer Device:**
1. Open **LoyaltyCards** app
2. Open completed card (5/5 stamps)
3. Show to supplier (in real scenario)
4. Tap **"Redeem Reward"** button
5. Confirm redemption in dialog

**Expected Results:**
- Card marked as "Redeemed" with timestamp
- Card moves to redeemed section or changes appearance
- **New empty card created automatically** (0/5 stamps)
- Ready to start collecting again

**✅ Pass / ❌ Fail**  
**Notes:**

---

## Priority 2: Backup & Recovery Tests (Day 2)

### Test 5: Search & Organization

**App:** LoyaltyCards (Customer)  
**Device:** iPhone

**Steps:**
1. Have at least 2-3 cards from different businesses (create more test businesses if needed)
2. Test search bar at top of card list
3. Search by business name
4. Verify filtering works
5. Check card sorting (active vs redeemed)

**Expected Results:**
- Search finds cards by business name
- Cards organized clearly (active, redeemed)
- Easy to find specific card

**✅ Pass / ❌ Fail**  
**Notes:**

---

### Test 6: Backup Business to Photos

**App:** LoyaltyCards Business (Supplier)  
**Device:** iPad

**Steps:**
1. Open **LoyaltyCards Business** app
2. Go to **Settings** (gear icon)
3. Find **"Backup & Recovery"** section
4. Tap **"Create Recovery Backup"**
5. Choose **"Save to Photos"**
6. Grant photo library permission if prompted
7. Wait for confirmation

**Verify:**
1. Open **Photos** app
2. Check recent photos
3. QR code image should be saved

**Expected Results:**
- QR code successfully saved to Photos
- Image is clear and scannable
- Contains business configuration data

**✅ Pass / ❌ Fail**  
**Notes:**

---

### Test 7: Restore from Backup

**App:** LoyaltyCards Business (Supplier)  
**Device:** iPad  
**Prerequisites:** Test 6 complete (backup QR saved)

**⚠️ WARNING:** This will delete current business. Only proceed if comfortable.

**Steps:**
1. In LoyaltyCards Business app
2. Go to **Settings**
3. Scroll to **"Reset Business Configuration"**
4. Confirm deletion (business and all data erased)
5. App returns to onboarding screen
6. Tap **"Recover Existing Business"**
7. Grant camera permission
8. Open **Photos** app in split screen or on second device
9. Display backup QR code from Photos
10. Scan QR code with supplier app camera
11. Wait for restoration

**Expected Results:**
- Business restored with **same name, settings, and ID**
- All customer cards from before still work (same business ID)
- No data loss

**✅ Pass / ❌ Fail**  
**Notes:**

---

## Priority 3: Advanced Tests (Day 3)

### Test 8: Clone to Second Device

**App:** LoyaltyCards Business (Supplier)  
**Devices:** 2 devices with supplier app installed  
**Prerequisites:** Business created on Device 1

**Steps:**

**On Device 1 (Original - iPad):**
1. Open LoyaltyCards Business
2. Go to **Settings**
3. Tap **"Clone to Another Device"**
4. QR code appears with **5-minute countdown timer**
5. Keep this QR visible

**On Device 2 (New - iPhone):**
1. Open LoyaltyCards Business app
2. On onboarding screen, tap **"Clone from Another Device"**
3. Scan clone QR from Device 1
4. Wait for cloning to complete

**Verify Multi-Device Operation:**
1. Both devices show same business
2. Issue stamp from Device 2 (iPhone)
3. Customer scans with their app
4. Issue stamp from Device 1 (iPad)
5. Customer scans again
6. Both stamps appear correctly

**Expected Results:**
- Clone completes within 5 minutes
- Both devices have identical business
- Stamps work from either device
- Customer cards stay synchronized (P2P model)

**⚠️ Expiry Test:**
- Wait 6+ minutes
- Clone QR should expire
- Attempting to scan shows error message

**✅ Pass / ❌ Fail**  
**Notes:**

---

### Test 9: Secure Mode Comparison

**App:** LoyaltyCards Business (Supplier)  
**Device:** Any

**Steps:**
1. Create a **new business** (not same as Test 1)
2. Name it differently (e.g., "Secure Café")
3. Choose **"Secure Mode"** this time
4. Configure stamps (e.g., 5 required)
5. Issue card to customer
6. Test stamp flow

**Secure Mode Workflow:**
1. Customer opens their card
2. Customer shows QR to supplier
3. Supplier scans customer's QR with camera
4. Supplier confirms stamp count
5. Stamp QR generated (cryptographically signed)
6. Customer scans supplier's stamp QR
7. Stamp added

**Compare with Simple Mode:**

| Feature | Simple Mode | Secure Mode |
|---------|-------------|-------------|
| **Customer Action** | Scans supplier QR | Shows QR, then scans |
| **Supplier Action** | Shows static QR | Scans customer QR first |
| **QR Reusability** | Same QR reused | New QR each time |
| **Security** | Trust-based | Cryptographic validation |
| **Speed** | Faster (1 scan) | Slower (2 scans) |

**Expected Results:**
- Secure mode requires 2 scans per stamp
- Each stamp QR is unique
- More secure but slightly slower
- Good for high-value rewards

**✅ Pass / ❌ Fail**  
**Preference:** Simple / Secure  
**Notes:**

---

### Test 10: Edge Cases & Stress Testing

**Various scenarios to test:**

#### A. Wrong QR Code
1. Try scanning a QR from Business A with a card from Business B
2. **Expected:** Error message "Card not found" or similar

**✅ Pass / ❌ Fail**

---

#### B. Incomplete Card Redemption
1. Try to redeem card with only 3/5 stamps
2. **Expected:** Button disabled or error message

**✅ Pass / ❌ Fail**

---

#### C. Rapid Stamp Collection
1. Try scanning multiple stamps very quickly (1-2 seconds apart)
2. **Expected:** 
   - Simple mode: 1-second cooldown prevents duplicates
   - Secure mode: Each scan requires new QR

**✅ Pass / ❌ Fail**

---

#### D. Card Deletion
1. Delete a card from customer wallet
2. Try to scan stamp QR for that deleted card
3. **Expected:** Card re-created with new ID or error (depends on mode)

**✅ Pass / ❌ Fail**

---

#### E. Expired Clone QR
1. Generate clone QR
2. Wait 6+ minutes
3. Try to scan expired QR
4. **Expected:** Error message about expiration

**✅ Pass / ❌ Fail**

---

#### F. Network Independence (Offline Test)
1. Enable **Airplane Mode** on both devices
2. Try to issue card, add stamps, redeem
3. **Expected:** Everything works (P2P, no internet needed)
4. Turn off Airplane Mode
5. No sync needed - everything already local

**✅ Pass / ❌ Fail**

---

#### G. Camera Rotation Persistence
1. Open any QR scanner screen (customer or supplier)
2. If camera view is sideways/upside down, tap rotation button (90° or 180°)
3. Scan a QR code successfully
4. Close the camera screen
5. Open the SAME camera screen again
6. **Expected:** Camera opens with your preferred rotation already applied
7. Now open a DIFFERENT camera screen (e.g., stamp issuance if you just tested card issuance)
8. **Expected:** Your rotation preference applies to ALL cameras
9. Close and reopen the app completely
10. Open any camera screen
11. **Expected:** Rotation preference persists across app restarts

**Testing Notes:**
- Camera rotation preference is shared across ALL QR scanners in both apps
- Setting applies to: Customer scanner, Supplier import, Supplier stamp, Supplier redeem
- Preference saved automatically when rotation button tapped
- Default rotation: 90° (may vary by screen)
- Test on both iPhone (portrait) and iPad (landscape) if available

**✅ Pass / ❌ Fail**  
**Notes:**

---

## UI/UX Observations

### Visual & Layout Issues

**iPhone:**
- [ ] App icons clear and recognizable
- [ ] Text readable at all sizes
- [ ] Colors appropriate
- [ ] Buttons easy to tap
- [ ] QR codes scan well
- [ ] Animations smooth

**iPad:**
- [ ] Layout uses screen space well
- [ ] Text not too small
- [ ] Share sheet works (for backup)
- [ ] QR codes display large enough

**Issues Found:**

---

### Performance

- [ ] App launches quickly
- [ ] QR scanning responsive
- [ ] No crashes
- [ ] No freezing
- [ ] Camera permissions work
- [ ] Photo library access works

**Issues Found:**

---

## Known Behaviors (Not Bugs)

✅ **Expected behaviors:**

1. **Simple mode 1-second cooldown:**  
   Prevents accidental duplicate scans. This is intentional.

2. **Clone QR expires after 5 minutes:**  
   Security feature. Generate new QR if expired.

3. **No undo for redemption:**  
   Once redeemed, card moves to history. This is by design.

4. **No cloud sync:**  
   Data stays local on device. Privacy-first architecture.

5. **Statistics in simple mode:**  
   May not be accurate (no server-side tracking).

---

## Bug Report Template

**If you find an issue, note:**

1. **What were you trying to do?**  


2. **What actually happened?**  


3. **Steps to reproduce:**  
   1.  
   2.  
   3.  

4. **Device:** iPhone / iPad  
   **iOS Version:**  
   **App:** Customer / Supplier  

5. **Screenshots:** (if applicable)

6. **How often does it happen?** Always / Sometimes / Once

---

## Feedback & Next Steps

### What Worked Well


### What Needs Improvement


### Feature Requests


### Overall Impression

**Would you use this app?** Yes / No / Maybe

**Would you recommend to businesses?** Yes / No / Maybe

**Readiness for pilot with real businesses:**
- [ ] Ready now
- [ ] Needs minor fixes first
- [ ] Needs major changes

---

## Summary

**Total Tests:** 10 core tests + edge cases  
**Tests Passed:** ___ / ___  
**Critical Bugs Found:** ___  
**Minor Issues Found:** ___

**Overall Status:** ✅ Ready for Pilot / ⚠️ Needs Fixes / ❌ Major Issues

---

## Contact

**Feedback Email:** ian.hamlet@dotConnected.com  
**GitHub:** https://github.com/ian-hamlet/LoyaltyCards  
**Privacy Policy:** https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY

---

**Thank you for testing! Your feedback helps make LoyaltyCards better.** 🎉
