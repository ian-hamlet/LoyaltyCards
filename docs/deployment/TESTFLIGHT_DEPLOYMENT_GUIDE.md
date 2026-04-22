# TestFlight Deployment Guide - LoyaltyCards v0.3.0+1

**Date:** April 22, 2026  
**Current Version:** v0.3.0+1 (Build 23)  
**Apps:** LoyaltyCards (Customer) + LoyaltyCards Business (Supplier)  
**Method:** Automatic signing via Xcode

---

## Prerequisites ✅

- [x] Xcode 26.3 installed
- [x] Apple Developer account active ($99/year)
- [x] Privacy Policy live at: https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY
- [x] Version: v0.3.0+1 (Build 23)
- [x] Custom app icons installed
- [x] Bundle IDs ready:
  - Customer: `com.ianhamlet.loyaltycards.customerApp`
  - Supplier: `com.ianhamlet.loyaltycards.supplierApp`

---

## Step 1: Configure Signing for CUSTOMER APP (15 minutes)

### 1.1 Open Customer App in Xcode

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app/ios
open Runner.xcworkspace
```

**Wait for Xcode to fully load before proceeding.**

---

### 1.2 Sign In to Apple Developer Account

1. In Xcode menu → **Xcode** → **Settings** (or Preferences)
2. Click **Accounts** tab
3. Click **+** button (bottom left)
4. Select **Apple ID**
5. Sign in with your Apple Developer account
6. Close Settings window

---

### 1.3 Configure Automatic Signing

1. In Xcode's left sidebar, click **Runner** (top blue icon)
2. In main panel, select **Runner** target (with app icon)
3. Click **Signing & Capabilities** tab
4. Under **Signing**, check these settings:

   **✅ Automatically manage signing** (MUST be checked)
   
   **Team:** Select your team from dropdown (your Apple Developer account)
   
   **Bundle Identifier:** Should show `com.ianhamlet.loyaltycards.customerApp`

5. Xcode will now:
   - Create distribution certificate automatically
   - Create provisioning profile automatically
   - You'll see "Runner.app" with green checkmark when ready

**Expected Result:**
- No red errors in Signing section
- Team dropdown shows your Apple Developer account name
- Status shows "Signing for 'Runner' requires a development team..."

---

### 1.4 Build Customer App IPA (Using Flutter)

**⚠️ IMPORTANT: Use Flutter CLI, NOT Xcode Archive**

Flutter apps must be built using `flutter build ipa` command. Xcode's Product → Archive doesn't properly handle Flutter's build system.

**In Terminal:**

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app

# Clean previous builds
flutter clean
flutter pub get

# Build iOS release IPA (3-5 minutes)
flutter build ipa --release
```

**Build Process:**
- `flutter clean` removes old build artifacts (~5 seconds)
- `flutter pub get` downloads dependencies (~30 seconds)
- `flutter build ipa --release` creates IPA (~3-5 minutes)
- Progress shown in terminal

**Expected Result:**
- Build completes successfully
- IPA created at: `build/ios/ipa/customer_app.ipa`
- File size: ~19-20 MB
- Terminal shows: "✓ Built build/ios/ipa/customer_app.ipa"

**⚠️ If Build Fails:**
- Check Xcode signing is configured (Step 1.3)
- Run `pod install` in `ios/` directory
- Check for Flutter/Xcode version compatibility
- Review error messages carefully

**Verify Build:**
```bash
# Check IPA exists
ls -lh build/ios/ipa/customer_app.ipa

# Verify version (should show 0.2.0 and build 21)
unzip -p build/ios/ipa/customer_app.ipa \
  Payload/Runner.app/Info.plist | \
  grep -A1 CFBundleShortVersionString
```

---

### 1.5 Upload Customer App to App Store Connect

**Option A: Transporter App (Recommended - Easiest)**

1. Download **Transporter** from Mac App Store (if not installed)
2. Open Transporter app
3. Sign in with your Apple ID (same as Xcode)
4. Drag and drop `customer_app.ipa` into Transporter window
   - Location: `03-Source/customer_app/build/ios/ipa/customer_app.ipa`
5. Click **Deliver** button
6. Wait for upload to complete (2-5 minutes)
7. Check for success message

**Option B: Xcode Organizer**

1. Open Xcode
2. Menu: **Window** → **Organizer**
3. Click **Archives** tab (top)
4. Drag `customer_app.ipa` file into Archives window
5. Select the archive
6. Click **Distribute App**
7. Select **App Store Connect** → **Next**
8. Select **Upload** → **Next**
9. **Automatically manage signing** → **Next**
10. Review and click **Upload**

**Option C: Command Line (Advanced)**

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/customer_app.ipa \
  --username YOUR_APPLE_ID@EMAIL.COM \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

**Expected Result:**
- Upload completes successfully
- App appears in App Store Connect within 10-15 minutes
- You'll receive email confirmation

---

## Step 2: Configure Signing for SUPPLIER APP (15 minutes)

### 2.1 Open Supplier App in Xcode

**Close current Xcode window first, then:**

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/supplier_app/ios
open Runner.xcworkspace
```

**Wait for Xcode to fully load before proceeding.**

---

### 2.2 Configure Automatic Signing (Supplier)

**SAME AS CUSTOMER APP:**

1. In Xcode's left sidebar, click **Runner** (top blue icon)
2. Select **Runner** target
3. Click **Signing & Capabilities** tab
4. Settings:

   **✅ Automatically manage signing** (MUST be checked)
   
   **Team:** Select your team (same as customer app)
   
   **Bundle Identifier:** Should show `com.ianhamlet.loyaltycards.supplierApp`

5. Wait for green checkmark

---

### 2.3 Build Supplier App IPA (Using Flutter)

**SAME FLUTTER BUILD PROCESS AS CUSTOMER APP:**

**In Terminal:**

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/supplier_app

# Clean previous builds
flutter clean
flutter pub get

# Build iOS release IPA (3-5 minutes)
flutter build ipa --release
```

**Expected Result:**
- IPA created at: `build/ios/ipa/supplier_app.ipa`
- File size: ~22-23 MB
- Terminal shows: "✓ Built build/ios/ipa/supplier_app.ipa"

**Verify Build:**
```bash
ls -lh build/ios/ipa/supplier_app.ipa
```

---

### 2.4 Upload Supplier App to App Store Connect

**REPEAT SAME UPLOAD PROCESS AS CUSTOMER APP:**

**Using Transporter (Recommended):**
1. Open Transporter app
2. Drag `supplier_app.ipa` into window
   - Location: `03-Source/supplier_app/build/ios/ipa/supplier_app.ipa`
3. Click **Deliver**
4. Wait for success

**Using Xcode Organizer:**
1. Window → Organizer → Archives
2. Drag `supplier_app.ipa` into Archives
3. Distribute App → App Store Connect → Upload

**Expected Result:**
- Upload completes successfully
- Both apps now appear in App Store Connect

---

## Step 3: Create App Store Connect Listings (30 minutes)

### 3.1 Access App Store Connect

1. Go to: https://appstoreconnect.apple.com
2. Sign in with Apple Developer account
3. Click **My Apps**

---

### 3.2 Create Customer App Listing

**Click + button → New App**

1. **Platforms:** iOS
2. **Name:** LoyaltyCards
3. **Primary Language:** English (U.S.)
4. **Bundle ID:** Select `com.ianhamlet.loyaltycards.customerApp`
5. **SKU:** `loyaltycards-customer` (unique identifier for your records)
6. **User Access:** Full Access
7. Click **Create**

**Fill in App Information:**

1. **Privacy Policy URL:** `https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY`
2. **Category:**
   - Primary: Lifestyle
   - Secondary: Business (optional)
3. **Content Rights:** Check "I have the rights to share this content"

**Version Information (1.0):**

1. **Description:**
```
Digital loyalty stamp cards for your favorite local businesses.

Zero signup. Zero personal data collection. Just scan QR codes to collect stamps and redeem rewards.

FEATURES:
• Scan QR codes to add loyalty cards instantly
• Track stamps and rewards for multiple businesses
• Completely offline - no internet required
• No accounts, no personal data, no tracking
• Privacy-first architecture - everything local

Perfect for coffee shops, restaurants, retail stores, and any business offering stamp-based rewards.

PRIVACY GUARANTEE:
We collect ZERO personal data. All cards and stamps are stored locally on your device. No servers, no cloud storage, no tracking. Your privacy is guaranteed by our architecture, not just our promise.
```

2. **Keywords:** `loyalty,stamp,card,rewards,local,business,privacy,offline,qr,scan`

3. **Support URL:** Your website or GitHub: `https://github.com/ian-hamlet/LoyaltyCards`

4. **Marketing URL:** (optional, leave blank)

**Screenshots:** (You'll need to provide these)
- Take screenshots on iPhone and iPad
- Required sizes: 6.7", 6.5", 5.5" iPhone
- Can use Xcode Simulator to capture

**Build:**
- Wait 10-15 minutes after upload
- Build will appear in "Build" section
- Select the build (0.2.0)

**Age Rating:**
- Click "Edit" next to Age Rating
- Answer questionnaire (likely 4+)

**Copyright:** `2026 Ian Hamlet`

**Click Save** (top right)

---

### 3.3 Create Supplier App Listing

**Repeat same process:**

1. Click **+ button** → **New App**
2. **Name:** LoyaltyCards Business
3. **Bundle ID:** `com.ianhamlet.loyaltycards.supplierApp`
4. **SKU:** `loyaltycards-supplier`
5. **Create**

**Description:**
```
Business management app for LoyaltyCards stamp card system.

Create and manage digital loyalty programs for your business. Issue stamps, track redemptions, and reward loyal customers - all without collecting personal data.

FEATURES:
• Two operation modes: Simple (trust-based) or Secure (cryptographic)
• Issue QR-based loyalty cards instantly
• Add stamps via QR scanning or static codes
• Process reward redemptions
• Multi-device support with backup and clone features
• Completely offline - no internet required
• Zero customer data collection

PRIVACY-FIRST ARCHITECTURE:
No customer data is collected or stored centrally. All transactions happen peer-to-peer between devices. Perfect for privacy-conscious businesses.

BACKUP & RECOVERY:
• Create backup QR codes of your business configuration
• Clone to multiple devices for multi-register setups
• Restore from backup if you lose your device

Requires customers to have LoyaltyCards app installed.
```

**Keywords:** `business,loyalty,stamp,pos,rewards,privacy,qr,merchant,retail`

**Same settings as customer app (privacy URL, support URL, etc.)**

---

## Step 4: Submit for TestFlight Beta Review (5 minutes)

### For EACH app:

1. In App Store Connect → Your app
2. Click **TestFlight** tab (top)
3. Under "Internal Testing" section:
   - Click **+** to create test group
   - Name: "Internal Testers"
   - Add yourself (your Apple ID email)
   
4. Select build (0.2.0)
5. Fill in **Test Information:**
   - **What to Test:** "Initial pilot testing of loyalty card functionality"
   - **Beta App Description:** (copy from App Information description)
   - **Feedback Email:** ian.hamlet@dotConnected.com
   - **Privacy Policy URL:** https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY

6. **Export Compliance:**
   - Does your app use encryption? **NO** (unless using HTTPS for network calls)
   - Or select "No, my app does not use encryption"

7. Click **Submit for Review**

**Timeline:**
- Internal testing: Available immediately (no review needed)
- External testing: 1-2 business days for Beta App Review

---

## Step 5: Install on Physical Device (Immediate)

### Internal TestFlight Testing:

1. On your iPhone/iPad:
   - Install TestFlight app from App Store
   - Open TestFlight
   - Sign in with same Apple ID
   
2. Apps appear automatically (you're internal tester)
   - Click "Install" for each app
   - Start testing immediately!

**Internal testing = No review needed = Instant access**

---

## Troubleshooting

### "No accounts with App Store Connect access"
- Go to Xcode → Settings → Accounts
- Remove and re-add your Apple ID
- Make sure account shows "Agent" or "Admin" role

### "Provisioning profile doesn't include signing certificate"
- Uncheck "Automatically manage signing"
- Wait 5 seconds
- Re-check "Automatically manage signing"
- Xcode will refresh

### Archive grayed out
- Select "Any iOS Device (arm64)" as destination
- Make sure you're not on a simulator

### Build doesn't appear in App Store Connect
- Wait 15-20 minutes
- Check email for processing errors
- Verify bundle ID matches exactly

### Upload fails with certificate error
- Revoke existing certificates in Apple Developer portal
- Let Xcode create fresh ones automatically

---

## Quick Reference

**Flutter Build Commands:**
```bash
# Customer App
cd 03-Source/customer_app
flutter clean && flutter pub get
flutter build ipa --release
# Output: build/ios/ipa/customer_app.ipa (~19-20 MB)

# Supplier App
cd 03-Source/supplier_app
flutter clean && flutter pub get
flutter build ipa --release
# Output: build/ios/ipa/supplier_app.ipa (~22-23 MB)
```

**Upload with Transporter:**
1. Open Transporter app from Mac App Store
2. Drag IPAs into window
3. Click Deliver
4. Wait 10-15 minutes for processing

**Privacy Policy URL:**
```
https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY
```

**Support Email:**
```
ian.hamlet@dotConnected.com
```

**Bundle IDs:**
- Customer: `com.ianhamlet.loyaltycards.customerApp`
- Supplier: `com.ianhamlet.loyaltycards.supplierApp`

**Version:** v0.2.1 (Current: Build 23)

**GitHub:** https://github.com/ian-hamlet/LoyaltyCards

---

## Next Steps After Upload

1. ✅ Archives created successfully
2. ✅ Apps uploaded to App Store Connect
3. ✅ App listings created
4. ✅ Submitted for Beta Review
5. ⏳ Wait for Beta App Review (1-2 days)
6. ✅ Install via TestFlight (internal testing = immediate)
7. 📧 Invite external beta testers (after approval)
8. 🧪 Collect feedback and iterate

---

**Status:** Ready to begin! Start with Step 1.1 above.
