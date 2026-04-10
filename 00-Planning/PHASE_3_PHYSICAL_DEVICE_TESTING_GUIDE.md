# Phase 3 Physical Device Testing Guide

**Document Version:** 1.1  
**Created:** 2026-04-08  
**Last Updated:** 2026-04-08  
**Target:** First-time iOS app testing on physical devices

**Latest Updates (v1.1):**
- ✅ Added Settings & Reset test scenario (Test 1B)
- ✅ Updated QR refresh button instructions (Test 2)
- ✅ Fixed brand color validation bug (`##` → `#`)
- ✅ Fixed `deleteKey` → `deleteKeys` method name
- ✅ Added troubleshooting for "Invalid token structure" error
- ✅ Updated test results checklist
- ⚠️ Rate limit reduced to 1 second (see Known UX Issue below)

---

## ⚠️ Known UX Issue: Multiple Stamps

**IMPORTANT:** During testing, you'll notice that adding multiple stamps (e.g., customer buys 4 coffees) requires **4 complete scan cycles** (customer shows card → supplier scans → supplier shows stamp → customer scans → repeat).

This is **slower than physical cards** where a supplier can stamp 4 times instantly.

**Current State:**
- Rate limit: 1 second between stamps (minimal duplicate protection)
- Allows rapid sequential stamping but still requires full scan cycle each time
- 4 stamps ≈ 40-60 seconds vs. physical card ≈ 2 seconds

**Future Solution:**
- A "Quick Add" or "Multiple Stamps" feature is planned for Phase 5
- See `KNOWN_ISSUES_AND_RISKS.md` for full analysis and proposed solutions

**For Testing:**
This is a **known limitation**, not a bug. Document your experience with multiple stamps in the test results.

---

## 🎯 Testing Overview

**What We're Testing:**
- Phase 3: Customer P2P & QR Scanning
- QR code generation and scanning between devices
- Card pickup flow (Supplier → Customer)
- Stamp issuance flow (Customer → Supplier → Customer)

**Device Setup:**
- 💻 **MacBook:** Development machine
- 📱 **iPhone:** Customer app testing
- 📱 **iPad:** Supplier app testing (optional but recommended)

**Estimated Setup Time:** 30-60 minutes (first time)  
**Estimated Testing Time:** 1-2 hours

---

## ⚠️ Important Notes About Free Apple Developer Account

**Your Free Account Limitations:**
- ✅ Can install apps on your own devices
- ✅ Can test all features (camera, location, etc.)
- ⚠️ Apps expire after **7 days** and need re-installing
- ⚠️ Cannot distribute to other devices/testers
- ⚠️ Limited to 3 apps per device at a time
- ⚠️ No TestFlight distribution

**Upgrading to Paid ($99/year):**
- Apps valid for 1 year
- Can distribute to 100 testers via TestFlight
- Can publish to App Store
- **Recommended before Phase 6** (production deployment)

---

## 📋 Pre-Flight Checklist

Before starting, ensure you have:

- [ ] MacBook with Xcode installed (verify: `xcode-select --print-path`)
- [ ] Flutter SDK installed and working
- [ ] iPhone with **iOS 12.0+** (preferably iOS 16+)
- [ ] iPad with **iPadOS 12.0+** (optional but helpful)
- [ ] **Lightning/USB-C cable** for each device
- [ ] Apple ID signed into Xcode
- [ ] Both devices have **passcode/biometric enabled** (required for secure storage)
- [ ] Both devices **trusted** with this Mac
- [ ] Both devices on **same Wi-Fi** as Mac (for debugging, optional)

---

## 🔧 Part 1: First-Time Device Setup (30 minutes)

### Step 1.1: Connect and Trust Your iPhone

1. **Connect iPhone to Mac** using USB cable
2. **Unlock your iPhone**
3. **Trust prompt will appear on iPhone:**
   - Tap **"Trust"**
   - Enter your iPhone passcode
4. **Trust prompt may appear on Mac:**
   - Click **"Trust"** in dialog

**Verify Connection:**
```bash
# Open Terminal on Mac
flutter devices
```

**Expected Output:**
```
iPhone 15 Pro (mobile) • 00008110-001234567890ABCD • ios • iOS 17.4.1
```

✅ If your iPhone appears, proceed to Step 1.2  
❌ If not, see [Troubleshooting Section](#troubleshooting)

---

### Step 1.2: Enable Developer Mode on iPhone

**iOS 16+ requires Developer Mode to be enabled:**

1. On iPhone, go to **Settings** → **Privacy & Security**
2. Scroll down to **Developer Mode**
3. Toggle **Developer Mode ON**
4. Tap **Restart** (iPhone will reboot)
5. After restart, confirm activation

**iOS 15 or earlier:** Skip this step (not required)

---

### Step 1.3: Configure Xcode Signing (Customer App)

This is the most important step for first-time deployment.

1. **Open Customer App in Xcode:**
   ```bash
   cd ~/development/LoyaltyCards/03-Source/customer_app
   open ios/Runner.xcworkspace
   ```

2. **Wait for Xcode to open** (may take 30-60 seconds)

3. **Select Runner in the left sidebar** (blue icon at top)

4. **Go to "Signing & Capabilities" tab**

5. **Configure Team:**
   - Check **"Automatically manage signing"**
   - Under **Team**, select your Apple ID (e.g., "Your Name (Personal Team)")
   
   **If you don't see your Apple ID:**
   - Click **"Add an Account..."**
   - Sign in with your Apple ID
   - Go back to Team dropdown

6. **Change Bundle Identifier:**
   - Current: `com.example.customerApp`
   - Change to: `com.YOURNAME.loyaltycards.customer` (replace YOURNAME)
   - Example: `com.janesmith.loyaltycards.customer`
   
   **Why?** Bundle IDs must be globally unique. Using `com.example.*` will fail.

7. **Verify Signing:**
   - Under **Debug** section, you should see:
     - ✅ Provisioning Profile: "iOS Team Provisioning Profile"
     - ✅ Signing Certificate: "Apple Development: your-email@example.com"
   
   - Under **Release** section (optional for now):
     - ✅ Same as Debug

**Common Errors at This Stage:**
- ❌ "Failed to create provisioning profile" → Bundle ID already taken, try a different one
- ❌ "No signing certificate" → Add your Apple ID account in Xcode preferences
- ❌ "This device is not registered" → Wait 1-2 minutes, Xcode registers it automatically

---

### Step 1.4: Add Required Capabilities (Customer App)

Still in Xcode's "Signing & Capabilities" tab:

1. **Click the "+ Capability" button** (top left)

2. **Add "Keychain Sharing":**
   - Type "keychain" in search
   - Double-click "Keychain Sharing"
   - A Keychain Groups section appears
   - Default value is fine: `$(AppIdentifierPrefix)com.YOURNAME.loyaltycards.customer`

3. **Verify Info.plist has Camera Permission:**
   ```bash
   # In Terminal
   cd ~/development/LoyaltyCards/03-Source/customer_app/ios/Runner
   cat Info.plist | grep -A 1 "NSCameraUsageDescription"
   ```
   
   **Expected:** Should see a camera usage description
   
   **If missing, add it:**
   ```bash
   # Open Info.plist in Xcode or editor
   open Info.plist
   ```
   
   Add these lines before the final `</dict>`:
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>We need camera access to scan QR codes for loyalty cards</string>
   ```

4. **Save** (Cmd+S)

---

### Step 1.5: Build and Deploy Customer App to iPhone

1. **In Xcode, select your iPhone as the target:**
   - Top toolbar, next to "Runner" dropdown
   - Click the device dropdown
   - Select your iPhone (e.g., "Jane's iPhone")

2. **Click the Play button (▶)** or press **Cmd+R**

3. **Wait for build** (first time: 2-5 minutes)

4. **Watch for errors:**
   - ✅ "Build Succeeded" → Proceed to Step 1.6
   - ❌ Build fails → Check error messages, see [Troubleshooting](#troubleshooting)

5. **App installs on iPhone**

6. **iPhone shows error: "Untrusted Developer"**
   - This is NORMAL for free accounts
   - Don't panic! Go to Step 1.6

---

### Step 1.6: Trust the App on iPhone

**First time only, you must manually trust the developer certificate:**

1. On **iPhone**, go to **Settings** → **General** → **VPN & Device Management**

2. Under **"Developer App"**, tap on your Apple ID (e.g., "your-email@example.com")

3. Tap **"Trust 'your-email@example.com'"**

4. Tap **"Trust"** in confirmation dialog

5. **Return to Home Screen**

6. **Tap the LoyaltyCards customer app icon**

7. **App should launch!** 🎉

**What you should see:**
- Customer home screen
- "No loyalty cards yet" message (empty state)
- Bottom navigation

✅ **Success!** Customer app is running on iPhone.

---

### Step 1.7: Repeat for Supplier App on iPad (or iPhone)

**If you have an iPad, use it for supplier app (better for testing).**  
**If not, you can install both apps on the same iPhone for testing.**

1. **Connect iPad to Mac** (if using iPad)
   - Repeat Steps 1.1-1.2 for iPad

2. **Open Supplier App in Xcode:**
   ```bash
   cd ~/development/LoyaltyCards/03-Source/supplier_app
   open ios/Runner.xcworkspace
   ```

3. **Configure Signing (same as Step 1.3):**
   - Select Runner → Signing & Capabilities
   - Check "Automatically manage signing"
   - Select your Team (Personal Team)
   - Change Bundle ID to: `com.YOURNAME.loyaltycards.supplier`

4. **Add Capabilities (same as Step 1.4):**
   - Add Keychain Sharing
   - Verify camera permission in Info.plist

5. **Select target device:**
   - Choose iPad (or iPhone if testing both on one device)

6. **Build and Run** (Cmd+R)

7. **Trust the app** (same as Step 1.6)

8. **Launch Supplier App**

**What you should see:**
- Supplier onboarding screen
- "Welcome" message
- Business setup form

✅ **Success!** Both apps running on physical devices.

---

## 🧪 Part 2: Phase 3 Testing Scenarios (1-2 hours)

Now the fun part! Testing P2P interactions.

### Test Scenario 1: Supplier Onboarding

**Goal:** Set up a test business on supplier app  
**Device:** iPad (or iPhone with supplier app)  
**Time:** 5 minutes

**Steps:**

1. **Open Supplier App on iPad**

2. **Complete Onboarding:**
   - **Step 1:** Business Name
     - Enter: **"Test Coffee Shop"**
     - Tap **Next**
   
   - **Step 2:** Stamps Required
     - Use slider, select: **7 stamps**
     - Tap **Next**
   
   - **Step 3:** Brand Color
     - Choose any color (e.g., brown for coffee)
     - Tap **Complete**

3. **Wait for key generation** (~1 second)

4. **Home screen appears**

**Verification:**
- ✅ Business name shows: "Test Coffee Shop"
- ✅ "7 stamps required" displayed
- ✅ Brand color visible
- ✅ Settings icon visible in AppBar (top right)

**Troubleshooting:**
- ❌ App crashes during onboarding → Check logs, may be secure storage issue
- ❌ Stuck on "Generating keys" → Force quit and restart

**Result:** ✅ PASS / ❌ FAIL  
**Notes:**

---

### Test Scenario 1B: Settings and Business Reset

**Goal:** Verify settings screen and reset functionality  
**Device:** iPad (supplier app)  
**Time:** 3 minutes

**Steps:**

1. **From Supplier Home screen, tap ⚙️ Settings** icon (top right)

2. **Settings screen displays**

3. **Verify Business Information section shows:**
   - Business Name: "Test Coffee Shop"
   - Brand Color: (with colored circle indicator)
   - Stamps Required: 7 stamps
   - Business ID: (long UUID string)

4. **Scroll to "Danger Zone" section** (red heading)

5. **Tap "Reset Business Configuration"**

6. **Confirmation dialog appears:**
   - Warning about data loss
   - Lists what will be deleted (name, keys, history)
   - "Cancel" and "Reset" buttons

7. **Tap "Cancel"** (don't reset yet)
   - Dialog closes
   - Still on settings screen

8. **Optional: Test actual reset:**
   - Tap "Reset Business Configuration" again
   - Tap "Reset" button in confirmation
   - Loading indicator appears
   - Returns to onboarding screen
   - Enter new business name to test re-setup

**Note:** If testing reset, you'll need to re-onboard before continuing other tests.

**Verification:**
- ✅ Settings screen accessible
- ✅ All business info displayed correctly
- ✅ Brand color hex format correct (#RRGGBB)
- ✅ Reset confirmation warning appears
- ✅ Can cancel reset
- ✅ Reset works (if tested)
- ✅ Re-onboarding works after reset (if tested)

**Use Cases:**
- Fixing typo in business name (as encountered in testing)
- Starting over with fresh configuration
- Testing multiple business setups

**Result:** ✅ PASS / ❌ FAIL  
**Notes:**

---

### Test Scenario 2: Card Issuance QR Generation

**Goal:** Generate QR code for customer to scan  
**Device:** iPad (supplier app)  
**Time:** 2 minutes

**Steps:**

1. **On iPad Supplier App, tap "Issue Card"** button

2. **QR code generates and displays**

3. **Verify QR code is visible:**
   - Should be large (at least 50% of screen)
   - Should have border/padding
   - Should not be blurry
   - Should show "Cryptographically Signed" badge

4. **Note the information displayed:**
   - Business name: "Test Coffee Shop"
   - Stamps required: 7
   - "Show this QR to customer" instruction
   - "QR code valid for 5 minutes" warning
   - Blue **"Generate New QR Code"** button visible

5. **Test QR Refresh:**
   - Tap the blue **"Generate New QR Code"** button
   - QR code should regenerate (will look different)
   - Alt: Use refresh icon in top-right AppBar
   - Useful when QR expires or for testing

**DO NOT SCAN YET** - This is just visual verification

**Verification:**
- ✅ QR code displays
- ✅ QR code is clear and scannable size
- ✅ Business info correct
- ✅ QR expiry notice visible (5 minutes)
- ✅ Refresh button present and working
- ✅ Brand color format correct (#RRGGBB, 7 characters)

**Known Fixed Issues:**
- ✅ Brand color bug fixed (was `##673AB7`, now `#673AB7`)
- ✅ Refresh button added (previously mentioned but not visible)

**Result:** ✅ PASS / ⚠️ NOT IMPLEMENTED / ❌ FAIL  
**Notes:**

---

### Test Scenario 3: QR Scanning Permissions (Customer App)

**Goal:** Verify camera permissions work  
**Device:** iPhone (customer app)  
**Time:** 2 minutes

**Steps:**

1. **Open Customer App on iPhone**

2. **Tap "Add Card"** (+ button or similar)

3. **Camera permission dialog appears:**
   - "LoyaltyCards would like to access the camera"
   - Tap **"Allow"**

4. **Camera preview appears**

5. **Point camera at any QR code** (can test with any QR code initially)

6. **Verify camera is working:**
   - Live preview visible
   - Focus working
   - Can move phone and preview updates

7. **Tap "Cancel" or back button** to exit

**Verification:**
- ✅ Camera permission requested
- ✅ Camera preview works
- ✅ Can exit without crash

**Troubleshooting:**
- ❌ "Camera permission denied" → Go to iPhone Settings → Privacy → Camera → Enable for LoyaltyCards
- ❌ Black screen → NSCameraUsageDescription may be missing from Info.plist
- ❌ App crashes → Check console logs

**Current Status (as of Phase 2 completion):**
- ⚠️ This scanning screen may not be fully implemented yet
- If "Add Card" doesn't exist → Phase 3 needs QR scanner implementation

**Result:** ✅ PASS / ⚠️ NOT IMPLEMENTED / ❌ FAIL  
**Notes:**

---

### Test Scenario 4: Card Pickup Flow (P2P Test)

**Goal:** Customer scans supplier QR to add card  
**Devices:** iPad (supplier) + iPhone (customer)  
**Time:** 5 minutes

**THIS IS THE KEY P2P TEST!**

**Prerequisites:**
- ✅ Supplier app onboarded (Test Scenario 1)
- ✅ Supplier QR generated (Test Scenario 2)
- ✅ Customer camera working (Test Scenario 3)

**Steps:**

1. **iPad: Display Card Issuance QR**
   - Open Supplier App
   - Tap "Issue Card"
   - Hold iPad steady

2. **iPhone: Scan the QR**
   - Open Customer App
   - Tap "Add Card"
   - Point iPhone camera at iPad screen
   - Hold steady for 1-2 seconds

3. **Expected: QR Scanned Successfully**
   - iPhone shows success message
   - Card added to wallet animation
   - Returns to home screen

4. **Verify Card Added:**
   - Customer home shows "Test Coffee Shop" card
   - Shows 0/7 stamps
   - Brand color matches supplier's choice

5. **Tap Card:**
   - Opens detail view
   - Shows empty stamp grid
   - Shows progress: 0 of 7 stamps

**Verification:**
- ✅ QR scan successful
- ✅ Card appears in customer wallet
- ✅ Business name correct
- ✅ Stamp count shows 0/7
- ✅ Card detail opens correctly
- ✅ Brand color matches supplier's choice

**Troubleshooting:**
- ❌ "Can't scan QR" → Make sure QR is clear, well-lit, fills 30-50% of camera view
- ❌ "Invalid token structure" → **FIXED:** Was caused by brand color format bug (double `#`). Ensure supplier app has latest code with fix.
- ❌ "Invalid QR code" → Token parsing may have issues, check logs
- ❌ "Failed to add card" → Database error, check customer app logs
- ❌ Nothing happens → QR parsing may not be implemented yet

**Known Fixed Issues:**
- ✅ **Brand color bug:** QR token was generating `##673AB7` instead of `#673AB7`, causing validation to fail with "Invalid token structure". Fixed in `qr_token_generator.dart`.
- ✅ Token validation now checks for exactly 7 characters (`#RRGGBB` format)

**Expected Implementation Status:**
- Phase 3 should include QR token generation and parsing
- Token validation with signature verification
- If not working, check that all recent fixes are applied

**Result:** ✅ PASS / ⚠️ NOT IMPLEMENTED / ❌ FAIL  
**Notes:**

---

### Test Scenario 5: Display Customer Card QR

**Goal:** Customer shows card for stamping  
**Device:** iPhone (customer app)  
**Time:** 2 minutes

**Steps:**

1. **Open Customer App**

2. **Tap on "Test Coffee Shop" card**

3. **Card detail screen opens**

4. **Look for "Get Stamp" or "Show QR" button**

5. **Tap button**

6. **QR code displays** (card stamp request token)

7. **Verify QR contains:**
   - Card ID
   - Business ID
   - Current stamp count (0)

**Verification:**
- ✅ Can navigate to QR display
- ✅ QR code generates
- ✅ QR is clear and large
- ✅ Can return to card detail

**Current Status:**
- May be implemented in Phase 2/3
- If not, this is Phase 3 task

**Result:** ✅ PASS / ⚠️ NOT IMPLEMENTED / ❌ FAIL  
**Notes:**

---

### Test Scenario 6: Stamp Card Flow (P2P Test)

**Goal:** Supplier scans customer card and issues stamp  
**Devices:** iPhone (customer) + iPad (supplier)  
**Time:** 10 minutes

**THIS IS THE COMPLETE P2P CYCLE!**

**Prerequisites:**
- ✅ Customer has card (Test Scenario 4)
- ✅ Customer can display QR (Test Scenario 5)

**Steps:**

**Part A: Customer Shows Card**
1. iPhone: Open customer app
2. Tap "Test Coffee Shop" card
3. Tap "Get Stamp" button
4. Hold iPhone steady showing QR

**Part B: Supplier Scans Card**
5. iPad: Open supplier app
6. Tap "Stamp Card" button
7. Point camera at iPhone QR
8. Wait for scan (1-2 seconds)

**Part C: Supplier Generates Stamp Token**
9. iPad: Scan successful
10. Verify card info displayed:
    - Business: Test Coffee Shop
    - Current stamps: 0
    - Next stamp: 1
11. Tap "Issue Stamp" button
12. Stamp token QR displays on iPad

**Part D: Customer Receives Stamp**
13. iPhone: Tap "Scan Stamp Token" or similar
14. Point camera at iPad QR
15. Wait for scan
16. Success message displays
17. Card updates: 1/7 stamps

**Part E: Verify**
18. iPhone: Card detail shows 1 collected stamp
19. Stamp grid shows filled stamp at position 1
20. Transaction logged (if history exists)

**Verification:**
- ✅ Supplier can scan customer card
- ✅ Stamp token generates with valid signature
- ✅ Customer can scan stamp token
- ✅ Card updates correctly (0→1 stamps)
- ✅ Signature verified
- ✅ Visual feedback correct

**Troubleshooting:**
- ❌ "Invalid card QR" → Token parsing issue
- ❌ "Signature verification failed" → Crypto bug, needs fixing
- ❌ "Card not updated" → Database/repository issue
- ❌ Can't scan stamp token → QR size or format issue

**Expected Implementation:**
- Core of Phase 3 & 4
- If not working, this is primary development task

**Result:** ✅ PASS / ⚠️ NOT IMPLEMENTED / ❌ FAIL  
**Notes:**

---

### Test Scenario 7: Multiple Stamps

**Goal:** Add multiple stamps, verify rate limiting  
**Devices:** iPhone + iPad  
**Time:** 15 minutes

**Steps:**

1. **Complete Test Scenario 6** to get first stamp (1/7)

2. **Immediately try to add another stamp:**
   - Repeat Scenario 6 steps
   - Expected: "Rate limit exceeded" error
   - Reason: 1 stamp per hour per business (configurable)

3. **Wait or override rate limit:**
   - For testing, you can modify rate limit in code
   - Or use debug button to bypass
   - Or change device time (not recommended)

4. **Add second stamp** (1/7 → 2/7)
   - Repeat full stamp flow
   - Verify: Card shows 2 stamps

5. **Add third stamp** (2/7 → 3/7)

6. **Continue until 7/7** (card complete)

7. **Verify card completion:**
   - Card shows "Complete" status
   - All 7 stamps visible
   - UI indicates ready for redemption

**Verification:**
- ✅ Rate limiting works
- ✅ Each stamp increments correctly
- ✅ Stamp chain maintains integrity
- ✅ Card completion detected
- ✅ UI reflects each state change

**Result:** ✅ PASS / ⚠️ NOT IMPLEMENTED / ❌ FAIL  
**Notes:**

---

### Test Scenario 8: Data Persistence

**Goal:** Verify cards/stamps survive app restart  
**Devices:** iPhone (customer)  
**Time:** 5 minutes

**Steps:**

1. **With card at 3/7 stamps** (from previous test)

2. **Force quit customer app:**
   - Double-tap home button (or swipe up)
   - Swipe app away

3. **Reopen customer app**

4. **Verify:**
   - Card still present
   - Shows 3/7 stamps
   - Stamp grid correct
   - All data intact

5. **Repeat with supplier app:**
   - Force quit
   - Reopen
   - Business config still present
   - Keys still accessible

**Verification:**
- ✅ Customer cards persist
- ✅ Stamps persist
- ✅ Supplier business config persists
- ✅ Private keys still accessible

**Result:** ✅ PASS / ⚠️ NOT IMPLEMENTED / ❌ FAIL  
**Notes:**

---

## 📊 Part 3: Test Results Summary

After completing all scenarios, fill out this summary:

### Test Results Overview

| Test # | Scenario | Status | Time | Notes |
|--------|----------|--------|------|-------|
| 1 | Supplier Onboarding | ⬜ | ___ min | |
| 1B | Settings & Reset | ⬜ | ___ min | |
| 2 | Card Issuance QR | ⬜ | ___ min | |
| 3 | Camera Permissions | ⬜ | ___ min | |
| 4 | Card Pickup (P2P) | ⬜ | ___ min | |
| 5 | Display Customer QR | ⬜ | ___ min | |
| 6 | Stamp Card (P2P) | ⬜ | ___ min | |
| 7 | Multiple Stamps | ⬜ | ___ min | |
| 8 | Data Persistence | ⬜ | ___ min | |

**Legend:** ✅ Pass | ⚠️ Not Implemented | ❌ Fail

### Overall Assessment

**Phase 3 Readiness:**
- [ ] All P2P flows functional
- [ ] QR scanning working on both apps
- [ ] Signature verification working
- [ ] Settings and reset functionality working
- [ ] QR refresh working correctly
- [ ] Ready for Phase 4 implementation

**Recent Fixes Applied:**
- ✅ Brand color bug fix (token validation)
- ✅ Settings screen implementation
- ✅ QR refresh button added
- ✅ `deleteKeys()` method name corrected

**Blockers Found:**
1. _________________________________
2. _________________________________
3. _________________________________

**Next Steps:**
- _________________________________
- _________________________________

---

## 🐛 Part 4: Troubleshooting

### Common Issues & Solutions

#### Issue: "Failed to verify code signature"

**Cause:** Free account limitation or expired certificate

**Solution:**
```bash
# Clean build folder
cd customer_app
flutter clean
flutter pub get

# Rebuild
open ios/Runner.xcworkspace
# In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
# Then rebuild (Cmd+B)
```

---

#### Issue: "App keeps crashing on launch"

**Solution:**
1. **Check device logs:**
   - Connect device
   - Open Xcode → Window → Devices and Simulators
   - Select device → View Device Logs
   - Look for crash reports

2. **Check console output:**
   ```bash
   flutter logs
   # or
   flutter run --verbose
   ```

3. **Common causes:**
   - Missing keychain entitlement
   - Secure storage not accessible (device needs passcode)
   - Database migration error

---

#### Issue: "Camera not working / black screen"

**Solution:**
1. **Verify Info.plist:**
   ```bash
   cat ios/Runner/Info.plist | grep Camera
   ```
   Should show `NSCameraUsageDescription`

2. **Check permissions:**
   - Settings → Privacy & Security → Camera
   - Enable for LoyaltyCards

3. **Restart app after granting permission**

---

#### Issue: "QR code not scanning"

**Solutions:**
1. **Lighting:** Ensure bright, even lighting
2. **Distance:** QR should fill 30-50% of camera view
3. **Steady:** Hold both devices very steady (2 seconds)
4. **Clean screen:** Wipe both screens clean
5. **Size:** QR may be too small, check QR generation code
6. **Debug:** Add logging to QR scanner callback

---

#### Issue: "Invalid token structure" when scanning supplier QR

**Cause:** Brand color format bug (fixed as of 2026-04-08)

**Symptoms:**
- Customer app shows "Invalid token structure" error
- Happens immediately when scanning card issuance QR
- QR code appears valid visually

**Root Cause:**
The QR token generator was adding an extra `#` prefix to the brand color:
- **Stored in DB:** `#673AB7` (7 characters)
- **In QR token:** `##673AB7` (8 characters) ❌
- **Validation expects:** `#RRGGBB` (exactly 7 characters)

**Solution:**
1. **Verify fix is applied:**
   ```bash
   cd ~/development/LoyaltyCards/03-Source/supplier_app/lib/services
   grep "brandColor: business.brandColor" qr_token_generator.dart
   ```
   Should show: `brandColor: business.brandColor,` (without extra `#`)

2. **If fix not applied, update:**
   - In `qr_token_generator.dart`, lines ~22 and ~44
   - Change: `brandColor: '#${business.brandColor}',`
   - To: `brandColor: business.brandColor,`

3. **Rebuild supplier app:**
   ```bash
   flutter clean && flutter build ios
   ```

4. **Reset and re-test:**
   - Use Settings → Reset Business Configuration
   - Re-onboard with correct setup
   - Generate new QR code
   - Should now scan successfully

**Status:** ✅ Fixed in latest code

---

#### Issue: Build fails with "deleteKey method not found"

**Cause:** Method name typo in settings screen (fixed as of 2026-04-08)

**Error Message:**
```
lib/screens/supplier/supplier_settings.dart:62:27: Error: The method 'deleteKey' 
isn't defined for the type 'KeyManager'.
```

**Solution:**
1. **Verify fix in settings file:**
   ```bash
   grep "deleteKeys" supplier_app/lib/screens/supplier/supplier_settings.dart
   ```
   Should show: `await _keyManager.deleteKeys(widget.business.id);`

2. **If not fixed, update line ~62:**
   - Change: `await _keyManager.deleteKey(widget.business.id);`
   - To: `await _keyManager.deleteKeys(widget.business.id);` (plural)

3. **Rebuild:**
   ```bash
   flutter clean && flutter build ios
   ```

**Status:** ✅ Fixed in latest code

---

#### Issue: "Signature verification failed"

**Cause:** Crypto implementation bug or key mismatch

**Debug:**
1. **Check key consistency:**
   ```dart
   print('Public key stored: ${business.publicKey}');
   print('Signature: ${stamp.signature}');
   ```

2. **Verify data format:**
   - Make sure data being signed matches data being verified
   - Check Base64 encoding/decoding
   - Verify ECDSA parameters match (P-256)

3. **Test signature separately:**
   - Create unit test with known good signature
   - Test with test vectors

---

#### Issue: "App expired after 7 days"

**Cause:** Free developer account limitation

**Solution:**
1. **Re-install app:**
   ```bash
   flutter run --release
   ```

2. **Or upgrade to paid account** ($99/year):
   - Apps valid for 1 year
   - Access to TestFlight
   - App Store publication

---

#### Issue: "Device not trusted"

**Solution:**
1. **Reconnect device**
2. **Unlock device**
3. **Tap "Trust" on device**
4. **Tap "Trust" on Mac**
5. **Restart Xcode if needed**

---

#### Issue: "Build takes forever"

**First build is slow (2-5 minutes). Subsequent builds should be faster.**

**If consistently slow:**
```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean Flutter
flutter clean
flutter pub get

# Rebuild
flutter build ios
```

---

## 📸 Part 5: Capturing Test Evidence

For documentation and debugging:

### Screenshots to Capture

1. **Supplier Onboarding:** Business setup complete
2. **Supplier Home:** Showing business info
3. **Card Issuance QR:** Full screen QR code
4. **Customer Home:** Empty state and with cards
5. **Card Detail:** Showing stamps
6. **Stamp Process:** Each stage of stamping
7. **Completed Card:** 7/7 stamps

### Screen Recording (Optional)

**On iPhone/iPad:**
1. Settings → Control Center
2. Add "Screen Recording"
3. Swipe down from top-right
4. Tap record button
5. Record test scenario
6. Video saves to Photos

**Useful for:**
- Demonstrating bugs
- Showing complete flow
- Documentation

---

## 🔄 Part 6: Iterative Development Loop

After initial testing, you'll likely need to make changes:

### Quick Update Cycle

**When you change code:**

1. **Make changes in VS Code** (or editor)

2. **Hot reload (if app running):**
   ```bash
   # In terminal where flutter run is active
   Press 'r' for hot reload
   Press 'R' for hot restart
   ```

3. **Full rebuild (if needed):**
   ```bash
   # Stop app (Ctrl+C)
   flutter run
   ```

4. **From Xcode:**
   - Press Cmd+R to rebuild and run
   - Changes deploy automatically

**Hot reload limitations:**
- Doesn't work for native changes (iOS)
- Doesn't work for dependency changes
- Use hot restart (R) or full rebuild if issues

---

## ✅ Part 7: Completion Checklist

Mark when complete:

### Setup Phase
- [ ] iPhone connected and trusted
- [ ] iPad connected and trusted (if using)
- [ ] Developer mode enabled
- [ ] Customer app signed and installed
- [ ] Supplier app signed and installed
- [ ] Both apps trusted on devices

### Testing Phase
- [ ] Supplier onboarding complete
- [ ] Card issuance QR working
- [ ] Customer can scan QR
- [ ] Card added to customer wallet
- [ ] Customer can display card QR
- [ ] Supplier can scan customer card
- [ ] Stamp token generated
- [ ] Customer receives stamp
- [ ] Multiple stamps working
- [ ] Rate limiting functional
- [ ] Data persistence verified

### Documentation
- [ ] Test results recorded
- [ ] Screenshots captured
- [ ] Issues documented
- [ ] Next steps identified

---

## 📞 Next Steps After Testing

### If Everything Works ✅

**Congratulations!** Phase 3 is complete. Update:
- `PHASE_3_COMPLETION.md` (create new document)
- `DAILY_PROGRESS_LOG.md` (add testing session)
- `TEST_COMPLETION_REPORT.md` (add P2P test results)

**Then proceed to:**
- Phase 4: Supplier Operations (redemption flow)
- Phase 5: Multi-device configuration

### If Implementation Needed ⚠️

**Likely scenario:** Some features not yet implemented.

**Create a task list:**
1. QR token generation for card issuance
2. QR scanner integration (mobile_scanner)
3. Token parsing and validation
4. Stamp signing and verification
5. UI for QR display screens

**Estimate:** 2-3 days development

### If Issues Found ❌

**Document bugs in:**
- GitHub Issues (if using)
- `KNOWN_ISSUES.md` document
- This testing guide (notes section)

**Prioritize:**
1. Critical: App crashes, signature failures
2. High: QR scanning not working, data loss
3. Medium: UI glitches, error messages
4. Low: Cosmetic issues, minor UX

---

## 📚 Additional Resources

### Flutter iOS Debugging
- [Flutter Debugging Docs](https://docs.flutter.dev/testing/debugging)
- [iOS Device Logs](https://developer.apple.com/documentation/xcode/diagnosing-issues-using-crash-reports-and-device-logs)

### Xcode Resources
- [Xcode Help](https://help.apple.com/xcode/)
- [App Distribution Guide](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices)

### QR Code Best Practices
- Size: 200x200 minimum, 300x300 recommended for scanning
- Error correction: Medium or High (30-40% recovery)
- Contrast: High contrast, light background

---

## 📝 Test Session Log Template

**Date:** _______________  
**Tester:** _______________  
**Duration:** _______________  
**Devices Used:**
- iPhone: _______________ (iOS ___)
- iPad: _______________ (iPadOS ___)

**Test Results:**
- Passing: ___/8
- Not Implemented: ___/8
- Failing: ___/8

**Key Findings:**
- ___________________________________
- ___________________________________
- ___________________________________

**Next Actions:**
1. ___________________________________
2. ___________________________________
3. ___________________________________

**Notes:**
___________________________________
___________________________________
___________________________________

---

**Good luck with your first iOS device testing! 🚀**

**Remember:** First time is always the longest. Once set up, testing becomes quick and easy!

---

## 📊 Appendix: Testing Session History

### Session 1: Initial P2P Testing (2026-04-08)

**Tester:** Ian Hamlet  
**Duration:** ~2 hours  
**Devices:**
- iPhone: Customer App
- iPad Pro: Supplier App

**Tests Completed:**
- ✅ Xcode signing configuration (both apps)
- ✅ Device pairing and developer mode setup
- ✅ Supplier onboarding (Test 1)
- ⚠️ Card issuance QR generation (Test 2) - Issues found
- ⚠️ Card pickup flow (Test 4) - Blocked by QR validation bug

**Issues Found & Fixed:**

1. **"Invalid token structure" Error (Critical)**
   - **Symptom:** Customer app rejected supplier QR code immediately
   - **Root Cause:** Brand color format bug - extra `#` prefix (`##673AB7`)
   - **Fix:** Removed duplicate prefix in `qr_token_generator.dart`
   - **Status:** ✅ Fixed and verified

2. **Missing Refresh Button**
   - **Symptom:** QR expiry message mentioned refresh button, but not visible
   - **Root Cause:** Button existed in AppBar but wasn't prominent
   - **Fix:** Added large blue button below QR code
   - **Status:** ✅ Fixed

3. **No Settings/Reset Functionality**
   - **Symptom:** Typo in business name, no way to change it
   - **Root Cause:** Settings screen not implemented
   - **Fix:** Created `supplier_settings.dart` with reset feature
   - **Status:** ✅ Fixed

4. **Build Failure: "deleteKey not found"**
   - **Symptom:** Xcode build failed after adding settings screen
   - **Root Cause:** Called `deleteKey()` instead of `deleteKeys()` (plural)
   - **Fix:** Corrected method name
   - **Status:** ✅ Fixed

**Outcomes:**
- All critical bugs fixed in same session
- Test guide updated with new scenarios and troubleshooting
- Ready for next testing session with full P2P flow

**Next Testing:**
- Complete Test 4 (Card Pickup) with fixes applied
- Continue to Test 5-8 (Stamp flow and persistence)

---
