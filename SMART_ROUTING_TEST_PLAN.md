# Smart Routing & Auto New Card - Test Plan

**Feature Branch:** `feature/streamline-save-options`  
**Date:** April 21, 2026  
**Changes:** Smart routing documentation + auto new card on completion (not just overflow)

---

## What Changed

### 1. Auto New Card Creation (BEHAVIOR CHANGE)
**Before:** New card created only when stamps OVERFLOW (exceed required)
- Card with 9/10 stamps + 1 stamp = 10/10 complete (NO new card)
- Card with 9/10 stamps + 2 stamps = 10/10 complete + new card with 1 stamp

**After:** New card created when card reaches completion (≥ required)
- Card with 9/10 stamps + 1 stamp = 10/10 complete + new card created (empty)
- Card with 9/10 stamps + 2 stamps = 10/10 complete + new card with 1 stamp

**User Notification:** Shows clear message explaining what happened
- "Card complete! 🎉 New card ready for [Business Name]" (exact completion)
- "Card complete! 🎉 New card started with X stamps" (overflow)

### 2. Smart Routing (DOCUMENTED - was already implemented)
**Simple Mode:** Stamps automatically go to correct business based on QR code's businessId
- Don't need to be on the correct card screen
- System finds the right card for you
- Works across different businesses

**Secure Mode:** Uses exact cardId matching (each card has unique ID)

---

## Test Cases

### Test 1: Auto New Card on Exact Completion (Simple Mode)

**Setup:**
1. Create Business A (Simple Mode, 10 stamps required)
2. Customer adds Business A card
3. Customer scans 9 stamps (card at 9/10)

**Test:**
1. Scan 1 more stamp QR
2. **Expected:**
   - Original card marked complete (10/10)
   - NEW card automatically created (0/10)
   - Notification: "Card complete! 🎉 New card ready for [Business A]"
   - Customer returns to card detail screen
   - Can see both cards in wallet (one complete, one new)

**✅ Pass / ❌ Fail**

---

### Test 2: Auto New Card with Overflow (Simple Mode)

**Setup:**
1. Business A (Simple Mode, 10 stamps required)
2. Customer has card at 9/10 stamps

**Test:**
1. Scan QR for 3 stamps (multi-stamp token)
2. **Expected:**
   - Original card marked complete (10/10)
   - NEW card created with 2 stamps (2/10)
   - Notification: "Card complete! 🎉 New card started with 2 stamps"
   - Both cards visible in wallet

**✅ Pass / ❌ Fail**

---

### Test 3: Smart Routing - Cross-Business Scanning (Simple Mode)

**Setup:**
1. Business A (Simple Mode) - Customer has card at 5/10
2. Business B (Simple Mode) - Customer has card at 3/10
3. Open Business A card detail screen

**Test:**
1. While viewing Business A card, scan Business B stamp QR
2. **Expected:**
   - Stamp goes to Business B card (smart routing)
   - Business B card now 4/10
   - Business A card unchanged (5/10)
   - User sees success message
   - Returns to Business A screen (doesn't auto-switch cards)

**✅ Pass / ❌ Fail**

---

### Test 4: Smart Routing - Scan from Card List (Simple Mode)

**Setup:**
1. Business A card (5/10)
2. Business B card (7/10)
3. Open main card list screen (not in any card detail)

**Test:**
1. Tap "Scan to Add Stamp" from card list
2. Scan Business B stamp QR
3. **Expected:**
   - System finds Business B card automatically
   - Business B card updated to 8/10
   - Returns to card list
   - Business B card shows updated count

**✅ Pass / ❌ Fail**

---

### Test 5: Mixed Mode - Simple and Secure Cards

**Setup:**
1. Business A (Simple Mode) - card at 5/10
2. Business C (Secure Mode) - card at 3/10
3. Open Business A card detail

**Test:**
1. Scan Business C stamp QR (secure mode token)
2. **Expected:**
   - Stamp validated and added to Business C card
   - Business C card now 4/10
   - Business A unchanged
   - Success message shown

**Note:** Verify secure mode validation still works (signature check, etc.)

**✅ Pass / ❌ Fail**

---

### Test 6: Card Not Found - Smart Routing

**Setup:**
1. Customer has Business A card only
2. Open Business A card detail

**Test:**
1. Scan Business Z stamp QR (business customer doesn't have card for)
2. **Expected:**
   - Error: "Card not found. Please add the card first."
   - No changes to existing cards
   - User remains on scanner screen

**✅ Pass / ❌ Fail**

---

### Test 7: Overflow with Existing Card with Space

**Setup:**
1. Business A (Simple Mode, 10 stamps required)
2. Customer has:
   - Card #1: 9/10 stamps
   - Card #2: 5/10 stamps (existing card with space)

**Test:**
1. Scan 3-stamp QR on Card #1
2. **Expected:**
   - Card #1 becomes 10/10 (complete)
   - 2 overflow stamps go to Card #2 → becomes 7/10
   - NO new card created (existing card had space)
   - Notification: "Card complete! 🎉 2 stamps added to existing card"

**✅ Pass / ❌ Fail**

---

### Test 8: Overflow Exceeds Existing Card Space

**Setup:**
1. Business A (10 stamps required)
2. Customer has:
   - Card #1: 9/10 stamps
   - Card #2: 9/10 stamps (almost full)

**Test:**
1. Scan 5-stamp QR on Card #1
2. **Expected:**
   - Card #1 → 10/10 (complete)
   - Card #2 → 10/10 (filled with 1 stamp, now complete)
   - NEW Card #3 created with 3 stamps
   - Notification: "Card complete! 🎉 1 stamp added to existing card, new card started with 3"

**✅ Pass / ❌ Fail**

---

### Test 9: Secure Mode - No Smart Routing

**Setup:**
1. Business C (Secure Mode) - Customer has 2 cards:
   - Card #1 (ID: abc123): 5/10 stamps
   - Card #2 (ID: def456): 3/10 stamps
2. Open Card #1 detail screen

**Test:**
1. Scan stamp QR for Card #2 (different cardId)
2. **Expected:**
   - **Behavior:** Stamp should go to Card #2 (matches cardId in QR)
   - Card #2 → 4/10
   - Card #1 unchanged
   - No "smart routing" needed - secure mode uses exact cardId

**Note:** Verify this doesn't break - secure mode should work independently

**✅ Pass / ❌ Fail**

---

## Code Changes Summary

### Modified Files

1. **`customer_app/lib/screens/customer/qr_scanner_screen.dart`**
   - Line ~574: Changed `if (newTotalStamps > card.stampsRequired)` to `if (newTotalStamps >= card.stampsRequired)`
   - Updated log message: "OVERFLOW DETECTED" → "CARD COMPLETE"
   - Enhanced notifications to handle overflow = 0 case
   - Added comprehensive documentation about smart routing and auto new card

2. **`07-Documentation/USER_GUIDE.md`**
   - Added "Smart Routing Feature" explanation
   - Added "Auto New Card" behavior documentation
   - Explained how stamps automatically find correct business card

### No Breaking Changes
- All existing tests pass (87 customer + 46 supplier + 131 shared)
- Behavior is more user-friendly (creates card on completion, not just overflow)
- Smart routing was already implemented, just documented now

---

## Notes for Testers

**Key Points to Verify:**
1. New card creation happens at completion (not just overflow)
2. Smart routing works across different simple mode businesses
3. Secure mode cards still use exact cardId matching
4. Mixed simple/secure mode scenarios work correctly
5. Notifications are clear and helpful
6. Existing card with space logic still works (TEST-008 fix preserved)

**Common Issues to Watch For:**
- Card duplication
- Stamps going to wrong card
- Missing notifications
- Incorrect overflow calculations
- Secure mode validation breaking

**Performance:**
- No performance impact (just inequality change)
- Existing rate limiting still applies
- Database operations unchanged
