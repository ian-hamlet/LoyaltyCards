# TestFlight Deployment Guide - Build 15

**Date:** April 16, 2026  
**Version:** v0.2.0+15 (Build 15)  
**Previous Build:** v0.2.0+9 (Build 9 - deployed April 13, 2026)  
**Apps:** LoyaltyCards Customer + LoyaltyCards Business (Supplier)

---

## 📋 What's New in Build 15

### Fixed Issues
- ✅ **TEST-008:** Recursive overflow stamp handling prevents duplicate cards
- ✅ **CR-014:** Error handling standardization with comprehensive documentation
- ✅ **Code Review Fixes:** String safety + dead code cleanup
- ✅ **UX Improvement:** Conditional redemption messages (only shows "new card" when actually created)

### Defect Resolution
- **26/27 defects fixed (96%)**
- All HIGH priority defects resolved
- Only 1 LOW priority defect remaining (CR-015 - camera orientation)

---

## ⚠️ Important Notes

- **Signing Already Configured:** This is the second deployment, so Xcode signing, certificates, and provisioning profiles are already set up
- **Last Deployment Issue:** Xcode Archive GUI had problems - we used command-line tools successfully
- **Recommended Approach:** Use `xcodebuild` command-line tools for archiving and uploading

---

## 🔨 Phase 1: Build Apps (10 minutes)

### 1.1 Verify Version Numbers

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source

# Check all versions are 0.2.0+15
grep "appVersion" shared/lib/version.dart
grep "version:" customer_app/pubspec.yaml
grep "version:" supplier_app/pubspec.yaml
```

**Expected output:**
```
const String appVersion = '0.2.0+15';
version: 0.2.0+15
version: 0.2.0+15
```

---

### 1.2 Build Customer App

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for iOS release
flutter build ios --release
```

**Expected output:**
- ✓ Built build/ios/iphoneos/Runner.app
- Size: ~19-20MB
- No errors

---

### 1.3 Build Supplier App

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/supplier_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for iOS release
flutter build ios --release
```

**Expected output:**
- ✓ Built build/ios/iphoneos/Runner.app
- Size: ~21-22MB
- No errors

---

## 📦 Phase 2: Archive Apps Using Command Line (20 minutes)

Since Xcode GUI archiving had issues during the first deployment, we'll use `xcodebuild` command-line tools.

### 2.1 Archive Customer App

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app/ios

# Archive the app
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath ~/Desktop/CustomerApp-Build15.xcarchive \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID
```

**Replace `YOUR_TEAM_ID`** with your Apple Developer Team ID (found in Apple Developer account settings)

**Expected output:**
- `** ARCHIVE SUCCEEDED **`
- Archive created at: `~/Desktop/CustomerApp-Build15.xcarchive`

**If this fails:**
- Check that automatic signing worked during Build 9 deployment
- Verify Team ID is correct
- Ensure certificates haven't expired

---

### 2.2 Archive Supplier App

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/supplier_app/ios

# Archive the app
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath ~/Desktop/SupplierApp-Build15.xcarchive \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID
```

**Expected output:**
- `** ARCHIVE SUCCEEDED **`
- Archive created at: `~/Desktop/SupplierApp-Build15.xcarchive`

---

## 📤 Phase 3: Export and Upload to App Store Connect (30 minutes)

### 3.1 Export Customer App for App Store

```bash
# Create export options plist
cat > ~/Desktop/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

# Replace YOUR_TEAM_ID in the file
# Then export the archive
xcodebuild -exportArchive \
  -archivePath ~/Desktop/CustomerApp-Build15.xcarchive \
  -exportPath ~/Desktop/CustomerApp-Build15-IPA \
  -exportOptionsPlist ~/Desktop/ExportOptions.plist
```

**Expected output:**
- `** EXPORT SUCCEEDED **`
- IPA file created at: `~/Desktop/CustomerApp-Build15-IPA/Runner.ipa`

---

### 3.2 Export Supplier App for App Store

```bash
xcodebuild -exportArchive \
  -archivePath ~/Desktop/SupplierApp-Build15.xcarchive \
  -exportPath ~/Desktop/SupplierApp-Build15-IPA \
  -exportOptionsPlist ~/Desktop/ExportOptions.plist
```

**Expected output:**
- `** EXPORT SUCCEEDED **`
- IPA file created at: `~/Desktop/SupplierApp-Build15-IPA/Runner.ipa`

---

### 3.3 Upload Customer App to App Store Connect

**Option A: Using xcrun altool (Recommended for command line)**

```bash
xcrun altool --upload-app \
  --type ios \
  --file ~/Desktop/CustomerApp-Build15-IPA/Runner.ipa \
  --username "YOUR_APPLE_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

**Option B: Using Transporter CLI**

```bash
xcrun iTMSTransporter -m upload \
  -f ~/Desktop/CustomerApp-Build15-IPA/Runner.ipa \
  -u "YOUR_APPLE_ID" \
  -p "APP_SPECIFIC_PASSWORD"
```

**Option C: Using Transporter GUI App (Easiest)**

1. Open Transporter app (pre-installed on macOS with Xcode)
2. Sign in with Apple ID
3. Drag and drop `~/Desktop/CustomerApp-Build15-IPA/Runner.ipa`
4. Click **Deliver**

**Expected output:**
- "Package uploaded successfully"
- Processing time: 5-15 minutes on Apple's servers

---

### 3.4 Upload Supplier App to App Store Connect

Repeat the same upload process for Supplier app:

```bash
# Option A: altool
xcrun altool --upload-app \
  --type ios \
  --file ~/Desktop/SupplierApp-Build15-IPA/Runner.ipa \
  --username "YOUR_APPLE_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

Or use Transporter GUI for easier upload.

---

### 📝 App-Specific Password Setup (If Needed)

If you don't have an app-specific password:

1. Go to https://appleid.apple.com
2. Sign in with your Apple ID
3. Navigate to "Security" section
4. Click "Generate Password" under "App-Specific Passwords"
5. Label it "TestFlight Upload"
6. Copy the generated password (format: xxxx-xxxx-xxxx-xxxx)
7. Use this password in the upload commands above

---

## ✅ Phase 4: Configure TestFlight (30 minutes)

### 4.1 Wait for Processing

After upload, apps must complete processing on Apple's servers:

1. Go to https://appstoreconnect.apple.com
2. Navigate to **My Apps**
3. Select **LoyaltyCards** (Customer App)
4. Click **TestFlight** tab
5. Check "iOS Builds" section

**Processing Status:**
- ⏳ **Processing:** Yellow indicator, "Processing" status (5-15 minutes)
- ✅ **Ready to Test:** Green indicator, build appears with version number
- ❌ **Invalid Binary:** Red indicator - see error details

**Repeat for LoyaltyCards Business (Supplier App)**

---

### 4.2 Add Build to Test Group - Customer App

Once processing completes:

1. In **TestFlight** tab for Customer App
2. Scroll to **iOS Builds** section
3. Find **Build 15 (0.2.0+15)**
4. Click the **+** icon or **Provide Export Compliance Info**

**Export Compliance Questions:**
- "Does your app use encryption?" → **NO** (we use standard iOS libraries)
- "Does your app qualify for any of the exemptions?" → **YES** (standard encryption)

5. After completing compliance:
   - Build status changes from "Missing Compliance" to "Ready to Submit"
   - Click **Submit for Review** (internal testing doesn't require review)

6. Navigate to **Internal Testing** section (left sidebar)
7. Click your test group (or create new group: **"Build 15 Testers"**)
8. Click **Builds** header
9. Click **+ (Add Build)**
10. Select **Build 15 (0.2.0+15)**
11. Click **Add Build**

---

### 4.3 Add Build to Test Group - Supplier App

Repeat the same steps for Supplier App:

1. Navigate to **LoyaltyCards Business** in App Store Connect
2. Click **TestFlight** tab
3. Complete Export Compliance for Build 15
4. Add Build 15 to Internal Testing group

---

### 4.4 Remove Old Builds from Testing (Recommended)

To avoid confusion and ensure testers get the latest version:

**For Customer App:**

1. In **TestFlight** → **Internal Testing** → Your test group
2. Click **Builds** header
3. Find **Build 9 (0.2.0+9)** in the list
4. Click the **minus (-)** icon next to Build 9
5. Confirm removal
6. Build 9 will no longer be available to testers (but remains in archive)

**For Supplier App:**

1. Repeat same steps for Supplier App
2. Remove Build 9 from Internal Testing group

**Note:** This doesn't delete the old build, just removes it from the test group. Testers with Build 9 installed will see an update available to Build 15.

---

### 4.5 Verify Tester Configuration

Ensure your internal testers are properly configured:

1. In **TestFlight** tab
2. Click **Internal Testing** (left sidebar)
3. Click your test group name
4. Click **Testers** tab
5. Verify testers are listed and have **Accepted** status
6. If testers need to be added:
   - Click **+ (Add Testers)**
   - Enter Apple IDs (must be in your App Store Connect team)
   - Check apps they should test (Customer, Supplier, or both)
   - Click **Add**

---

## 🔔 Phase 5: Notify Testers and Test (15 minutes)

### 5.1 Automatic Notifications

If "Automatic Distribution" is enabled (default):
- Testers receive push notification on device
- Email notification sent to registered email
- TestFlight app badge shows update available

---

### 5.2 Manual Distribution (If Needed)

If automatic distribution is disabled:

1. In **TestFlight** → **Internal Testing** → Your test group
2. Click **Build 15** 
3. Toggle **"Automatically distribute to testers"** to **ON**

Or send manual notification:
1. Click **Notify Testers** button
2. Add release notes (What to Test section below)
3. Click **Send**

---

### 5.3 What to Test - Release Notes

**Suggested Release Notes for Build 15:**

```
🎉 Build 15 Release - April 16, 2026

NEW FIXES:
✅ Fixed duplicate card creation when overflow stamps exceed capacity
✅ Improved redemption messages (only shows "new card" when actually created)
✅ Enhanced error handling and code stability
✅ String safety improvements

TESTING FOCUS:
1. PRIORITY: Test multi-stamp QR codes that cause overflow
   - Create Card A with 8/10 stamps
   - Create Card B with 2/10 stamps (delete stamps to test)
   - Scan 5-stamp QR code
   - Expected: Card A completes, Card B gets 3 more stamps (5/10 total)
   - Bug if: New Card C is created instead of filling Card B

2. Test redemption flow:
   - Complete a card (10/10 stamps)
   - Redeem the card
   - Check message: should NOT say "new card added" if existing card has space

3. General testing:
   - Create new cards
   - Add stamps (single and multi-stamp QR)
   - Redeem completed cards
   - Use redeemed card filter (hide/show toggle)

KNOWN ISSUES:
- Camera default orientation may require manual rotation (LOW priority - deferred to v0.3.0)

Please report any issues via TestFlight feedback or directly to development team.
```

---

### 5.4 Install and Test on Devices

**On Tester's iOS Device:**

1. Open **TestFlight** app
2. Find **LoyaltyCards** (Customer) or **LoyaltyCards Business** (Supplier)
3. If Build 9 is installed:
   - "Update" button appears → Tap to update to Build 15
4. If not installed:
   - "Install" button appears → Tap to install Build 15
5. Launch app
6. Check version on home screen: Should show **v0.2.0 (Build 15)**
7. Perform testing per release notes above

---

## ⚠️ Troubleshooting

### "No such module" Error During Archive

**Symptom:** `xcodebuild archive` fails with "No such module 'shared'"

**Solution:**
```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app
flutter clean
flutter pub get
flutter build ios --release
# Then retry archive command
```

---

### "Code Signing Error" During Archive

**Symptom:** Archive fails with signing errors

**Solution:**
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select Runner target → Signing & Capabilities
3. Verify "Automatically manage signing" is checked
4. Verify correct Team is selected
5. Clean build folder: Xcode menu → Product → Clean Build Folder
6. Close Xcode and retry command-line archive

---

### "Export Failed" with Provisioning Profile Error

**Symptom:** Export succeeds archive but fails to export IPA

**Solution:**
1. Check export options plist has correct Team ID
2. Verify provisioning profile exists in Xcode
3. Try exporting through Xcode GUI:
   - Open Xcode
   - Window → Organizer
   - Select Archive
   - Click "Distribute App" → App Store Connect
   - Follow wizard

---

### Upload Fails with Authentication Error

**Symptom:** `altool` upload fails with "authentication failed"

**Solution:**
1. Verify app-specific password is correct (not regular Apple ID password)
2. Try using Transporter GUI app instead (more reliable)
3. Check Apple ID has App Store Connect access:
   - Go to https://appstoreconnect.apple.com
   - Try logging in with same credentials

---

### Build Stuck "Processing" for Over 30 Minutes

**Symptom:** Build status remains "Processing" in App Store Connect

**Solution:**
1. Wait up to 1 hour (sometimes Apple's servers are slow)
2. Check for email from Apple (may indicate issues)
3. Try uploading again (won't create duplicate if first succeeded)
4. Check App Store Connect status: https://developer.apple.com/system-status/

---

### Testers Don't Receive Notification

**Symptom:** Build 15 added to test group but testers see no notification

**Solution:**
1. Verify "Automatically distribute" is enabled
2. Check tester's email is correct in App Store Connect
3. Ask tester to manually open TestFlight app (update shows there)
4. Send manual notification via App Store Connect

---

## 📊 Deployment Checklist

Use this checklist to track deployment progress:

### Pre-Deployment
- [ ] All version numbers verified at 0.2.0+15
- [ ] Git branch is `develop` with latest commit
- [ ] Both apps build successfully (flutter build ios)
- [ ] No compilation errors or warnings
- [ ] DEFECT_TRACKER shows TEST-008 as FIXED

### Archive Phase
- [ ] Customer app archived successfully
- [ ] Supplier app archived successfully
- [ ] Archive files exist on Desktop (.xcarchive)

### Export Phase
- [ ] ExportOptions.plist created with correct Team ID
- [ ] Customer app exported to IPA
- [ ] Supplier app exported to IPA
- [ ] IPA files exist on Desktop

### Upload Phase
- [ ] Customer app uploaded to App Store Connect
- [ ] Supplier app uploaded to App Store Connect
- [ ] Upload success message received
- [ ] Apps show "Processing" status in App Store Connect

### TestFlight Configuration
- [ ] Customer app processing completed
- [ ] Supplier app processing completed
- [ ] Export compliance completed for both apps
- [ ] Build 15 added to Internal Testing group (Customer)
- [ ] Build 15 added to Internal Testing group (Supplier)
- [ ] Build 9 removed from testing (Customer)
- [ ] Build 9 removed from testing (Supplier)
- [ ] Testers configured and accepted invitations
- [ ] Automatic distribution enabled or manual notification sent

### Testing
- [ ] Testers received TestFlight notification
- [ ] Testers successfully updated/installed Build 15
- [ ] Version shows "v0.2.0 (Build 15)" in app
- [ ] TEST-008 overflow stamp scenario tested
- [ ] Redemption message improvement verified
- [ ] No critical bugs reported in first 24 hours

### Post-Deployment
- [ ] Update deployment notes with any issues encountered
- [ ] Archive IPA files for records
- [ ] Clean up Desktop (move archives to organized folder)
- [ ] Document any TestFlight feedback received

---

## 📝 Deployment Log Template

Document your deployment for future reference:

```
# Build 15 TestFlight Deployment Log

Date: 2026-04-16
Deployed By: [Your Name]
Duration: [Total time from start to testers installing]

## Build Phase
- Customer app build: ✅ Success / ❌ Failed
  - Time: ___ minutes
  - Issues: None / [describe issues]
  
- Supplier app build: ✅ Success / ❌ Failed
  - Time: ___ minutes
  - Issues: None / [describe issues]

## Archive Phase
- Customer archiving method: xcodebuild CLI / Xcode GUI
  - Result: ✅ Success / ❌ Failed
  - Issues: None / [describe issues]
  
- Supplier archiving method: xcodebuild CLI / Xcode GUI
  - Result: ✅ Success / ❌ Failed
  - Issues: None / [describe issues]

## Upload Phase
- Upload tool used: altool / Transporter CLI / Transporter GUI
- Customer upload: ✅ Success / ❌ Failed
  - Processing time: ___ minutes
  
- Supplier upload: ✅ Success / ❌ Failed
  - Processing time: ___ minutes

## TestFlight Configuration
- Export compliance: ✅ Completed
- Builds added to test groups: ✅ Yes
- Old builds removed: ✅ Yes / ⏳ Pending / ❌ No
- Testers notified: ✅ Automatic / ✅ Manual / ⏳ Pending

## Testing Results (First 24 Hours)
- Testers installed: ___ / ___ invited
- Critical bugs: None / [list bugs]
- TEST-008 verification: ✅ Fixed / ❌ Still occurring / ⏳ Not yet tested
- Overall feedback: [summary]

## Issues Encountered
[Document any problems and solutions for future deployments]

## Next Steps
- [ ] Monitor feedback for 48 hours
- [ ] Address any critical bugs
- [ ] Plan next build if needed
```

---

## 🎯 Success Criteria

Build 15 deployment is successful when:

1. ✅ Both apps uploaded to App Store Connect without errors
2. ✅ Both apps completed processing (no "Invalid Binary" status)
3. ✅ Both apps added to Internal Testing with Build 15
4. ✅ Old Build 9 removed from testing (testers see only Build 15)
5. ✅ At least one tester successfully installs Build 15 on physical device
6. ✅ Version displays as "v0.2.0 (Build 15)" in app
7. ✅ TEST-008 fix verified: overflow stamps fill existing cards instead of creating duplicates
8. ✅ No critical bugs reported in first test session

---

## 📚 Additional Resources

- **App Store Connect:** https://appstoreconnect.apple.com
- **TestFlight Documentation:** https://developer.apple.com/testflight/
- **xcodebuild Man Page:** `man xcodebuild` in Terminal
- **Transporter App:** Pre-installed with Xcode (Applications folder)
- **Privacy Policy:** https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY
- **Project Defect Tracker:** `/DEFECT_TRACKER.md`
- **Version File:** `/03-Source/shared/lib/version.dart`

---

## 🏁 Quick Reference Commands

```bash
# Verify versions
cd /Users/ianhamlet/development/LoyaltyCards/03-Source
grep "appVersion" shared/lib/version.dart

# Build Customer App
cd customer_app && flutter clean && flutter pub get && flutter build ios --release

# Build Supplier App  
cd ../supplier_app && flutter clean && flutter pub get && flutter build ios --release

# Archive Customer App
cd customer_app/ios && xcodebuild archive \
  -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath ~/Desktop/CustomerApp-Build15.xcarchive \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=YOUR_TEAM_ID

# Archive Supplier App
cd ../../supplier_app/ios && xcodebuild archive \
  -workspace Runner.xcworkspace -scheme Runner -configuration Release \
  -archivePath ~/Desktop/SupplierApp-Build15.xcarchive \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=YOUR_TEAM_ID

# Upload with Transporter (easiest)
open -a Transporter
# Then drag-drop IPA files
```

---

**End of Build 15 Deployment Guide**

Good luck with the deployment! 🚀
