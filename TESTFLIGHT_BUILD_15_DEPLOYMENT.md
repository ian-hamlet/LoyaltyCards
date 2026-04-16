# TestFlight Deployment Guide - Build 15

**Date:** April 16, 2026  
**Version:** v0.2.0+15 (Build 15)  
**Previous Build:** v0.2.0+9 (Build 9 - deployed April 13, 2026)  
**Apps:** LoyaltyCards Customer + LoyaltyCards Business (Supplier)

## ✅ DEPLOYMENT STATUS: SUCCESSFUL

**Deployed:** April 16, 2026  
**Method:** flutter build ipa + Transporter GUI  
**Result:** ✅ Both apps successfully uploaded and processed  
**Testing:** ✅ Confirmed working on iPhone and iPad  
**Testers:** Received Build 15 via TestFlight  

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

## 🔨 Phase 1: Verify Version Numbers (5 minutes)

### 1.1 Check Version Consistency

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

✅ If all three match: Continue to Phase 2  
❌ If any don't match: Update and commit before proceeding

---

## 📦 Phase 2: Build IPA Files (15 minutes)

**✨ This is the method that worked successfully for Build 9 deployment!**

Flutter's `build ipa` command handles archiving, code signing, and IPA creation automatically.

### 2.1 Build Customer App IPA

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build IPA for App Store distribution
flutter build ipa --release
```

**Expected output:**
```
Building App Store IPA...
✓ Built Runner.app
✓ Built IPA
Built: build/ios/ipa/customer_app.ipa
```

**IPA Location:** `03-Source/customer_app/build/ios/ipa/customer_app.ipa`  
**Size:** ~19-20MB

**What this does:**
1. Compiles Flutter app in release mode
2. Runs Xcode archiving with automatic signing
3. Exports archive to IPA format
4. Ready for upload to App Store Connect

---

### 2.2 Build Supplier App IPA

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/supplier_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build IPA for App Store distribution
flutter build ipa --release
```

**Expected output:**
```
Building App Store IPA...
✓ Built Runner.app
✓ Built IPA
Built: build/ios/ipa/supplier_app.ipa
```

**IPA Location:** `03-Source/supplier_app/build/ios/ipa/supplier_app.ipa`  
**Size:** ~21-22MB

---

### 2.3 Verify IPA Files Exist

```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source

# Check both IPAs were created
ls -lh customer_app/build/ios/ipa/*.ipa
ls -lh supplier_app/build/ios/ipa/*.ipa
```

**Expected output:**
```
-rw-r--r--  1 user  staff    19M Apr 16 10:30 customer_app/build/ios/ipa/customer_app.ipa
-rw-r--r--  1 user  staff    22M Apr 16 10:35 supplier_app/build/ios/ipa/supplier_app.ipa
```

---

## 📤 Phase 3: Upload to App Store Connect (15 minutes)

**✨ Use Transporter GUI - This worked perfectly for Build 9!**

### 3.1 Open Transporter App

Transporter is Apple's official IPA upload tool (pre-installed with Xcode).

```bash
# Open Transporter
open -a Transporter
```

Or find it in Applications folder: **Applications > Transporter.app**

---

### 3.2 Sign In to Transporter

1. Transporter opens
2. Click **Sign In** in top-right
3. Enter your **Apple ID** (Apple Developer account)
4. Enter your **password**
5. If prompted for 2FA, complete verification

**Expected result:**
- Signed in successfully
- Your name appears in top-right corner

---

### 3.3 Upload Customer App IPA

**Drag-and-Drop Upload:**

1. In Finder, navigate to:
   ```
   /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app/build/ios/ipa/
   ```

2. Find `customer_app.ipa`

3. **Drag the IPA file** into Transporter window

4. Transporter shows upload details:
   - App Name: **LoyaltyCards**
   - Bundle ID: `com.ianhamlet.loyaltycards.customerApp`
   - Version: **0.2.0**
   - Build: **15**

5. Click **Deliver** button

6. Wait for upload (2-5 minutes):
   - Progress bar shows upload status
   - "Delivered" status appears when complete

**Expected result:**
- ✅ **Delivered** status with green checkmark
- Timestamp shows delivery time

---

### 3.4 Upload Supplier App IPA

**Repeat same process:**

1. In Finder, navigate to:
   ```
   /Users/ianhamlet/development/LoyaltyCards/03-Source/supplier_app/build/ios/ipa/
   ```

2. Find `supplier_app.ipa`

3. **Drag the IPA file** into Transporter window

4. Transporter shows upload details:
   - App Name: **LoyaltyCards Business**
   - Bundle ID: `com.ianhamlet.loyaltycards.supplierApp`
   - Version: **0.2.0**
   - Build: **15**

5. Click **Deliver** button

6. Wait for upload (2-5 minutes)

**Expected result:**
- ✅ **Delivered** status with green checkmark
- Both apps show "Delivered" in Transporter history

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

### "flutter build ipa" Fails with Code Signing Error

**Symptom:** `flutter build ipa` fails with signing/provisioning errors

**Solution:**
```bash
# 1. Verify signing is configured in Xcode
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app
open ios/Runner.xcworkspace

# In Xcode:
# - Select Runner target → Signing & Capabilities
# - Verify "Automatically manage signing" is checked
# - Verify correct Team is selected
# - Close Xcode

# 2. Clean and retry
flutter clean
flutter pub get
flutter build ipa --release
```

---

### "No such module 'shared'" Error During Build

**Symptom:** Build fails with "No such module 'shared'" error

**Solution:**
```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app

# Clean Flutter cache
flutter clean

# Get dependencies (this rebuilds Flutter modules)
flutter pub get

# Try build again
flutter build ipa --release
```

---

### IPA File Not Created (Build Succeeds But No IPA)

**Symptom:** `flutter build ipa` completes successfully but IPA file doesn't exist

**Solution:**
```bash
# Check if IPA was created in different location
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app
find . -name "*.ipa" -type f

# Expected location:
# build/ios/ipa/customer_app.ipa

# If not found, try building again with verbose output
flutter build ipa --release --verbose
```

---

### Transporter Won't Sign In

**Symptom:** Transporter app fails to sign in with Apple ID

**Solution:**
1. Verify Apple ID credentials are correct
2. Check if 2FA is required - complete verification
3. Try signing out and back in to Transporter
4. Verify Apple Developer account is active (not expired)
5. Check at https://developer.apple.com

---

### Transporter Upload Fails or Gets Stuck

**Symptom:** IPA upload fails or progress bar hangs in Transporter

**Solution:**
1. **Cancel upload** if stuck for >10 minutes
2. Check internet connection
3. Try uploading again (Transporter resumes uploads)
4. Check IPA file size is reasonable (~20MB for Customer, ~22MB for Supplier)
5. Verify IPA isn't corrupted:
   ```bash
   # Check file size
   ls -lh build/ios/ipa/*.ipa
   # Should be 15-25MB
   ```

---

### Build Shows "Invalid Binary" in App Store Connect

**Symptom:** Upload succeeds but build shows "Invalid Binary" after processing

**Solution:**
1. Check email from Apple for specific error details
2. Common issues:
   - Missing or invalid capabilities in app config
   - Info.plist errors (permissions, etc.)
   - Code signing certificate expired
3. Fix the issue and rebuild:
   ```bash
   flutter clean
   flutter build ipa --release
   ```
4. Upload again via Transporter

---

### Build Stuck "Processing" for Over 30 Minutes

**Symptom:** Build status remains "Processing" in App Store Connect

**Solution:**
1. Wait up to 1 hour (sometimes Apple's servers are slow)
2. Check for email from Apple (may indicate issues)
3. Check App Store Connect status: https://developer.apple.com/system-status/
4. If stuck for >2 hours, contact Apple Developer Support

---

### Testers Don't Receive Notification

**Symptom:** Build 15 added to test group but testers see no notification

**Solution:**
1. Verify "Automatically distribute" is enabled
2. Check tester's email is correct in App Store Connect
3. Ask tester to manually open TestFlight app (update shows there)
4. Send manual notification via App Store Connect
5. Verify tester has "Accepted" status (not "Invited")

---

### Version Number Mismatch After Upload

**Symptom:** App Store Connect shows wrong build number

**Solution:**
This means pubspec.yaml version didn't match. You must:
1. Update the version in pubspec.yaml
2. Rebuild the IPA:
   ```bash
   flutter clean
   flutter build ipa --release
   ```
3. Upload again via Transporter
4. Old upload will be replaced automatically

---

## 📊 Deployment Checklist

Use this checklist to track deployment progress:

### Pre-Deployment
- [ ] All version numbers verified at 0.2.0+15
- [ ] Git branch is `develop` with latest commit
- [ ] DEFECT_TRACKER shows TEST-008 as FIXED
- [ ] No uncommitted changes in git

### Build IPA Phase
- [ ] Customer app: `flutter build ipa --release` successful
- [ ] Supplier app: `flutter build ipa --release` successful
- [ ] Customer IPA exists: `customer_app/build/ios/ipa/customer_app.ipa`
- [ ] Supplier IPA exists: `supplier_app/build/ios/ipa/supplier_app.ipa`
- [ ] IPA sizes are reasonable (~19MB customer, ~22MB supplier)

### Upload Phase
- [ ] Transporter app opened and signed in
- [ ] Customer app uploaded via Transporter
- [ ] Supplier app uploaded via Transporter
- [ ] Both apps show "Delivered" status in Transporter
- [ ] Apps show "Processing" status in App Store Connect

### TestFlight Configuration
- [ ] Customer app processing completed (Ready to Test)
- [ ] Supplier app processing completed (Ready to Test)
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
- [ ] Archive IPA files for records (optional)
- [ ] Document any TestFlight feedback received
- [ ] Update deployment log below

---

## 📝 Deployment Log Template

Document your deployment for future reference:

```
# Build 15 TestFlight Deployment Log

Date: 2026-04-16
Deployed By: [Your Name]
Duration: [Total time from start to testers installing]

## Build IPA Phase
- Customer app build: ✅ Success / ❌ Failed
  - Time: ___ minutes
  - IPA size: ___ MB
  - Issues: None / [describe issues]
  
- Supplier app build: ✅ Success / ❌ Failed
  - Time: ___ minutes
  - IPA size: ___ MB
  - Issues: None / [describe issues]

## Upload Phase
- Upload method: Transporter GUI / Transporter CLI
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
- **Flutter Build IPA Docs:** https://docs.flutter.dev/deployment/ios
- **Transporter App:** Pre-installed with Xcode (Applications folder)
- **Privacy Policy:** https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY
- **Project Defect Tracker:** `/DEFECT_TRACKER.md`
- **Version File:** `/03-Source/shared/lib/version.dart`
- **Build 9 Deployment Guide:** `/TESTFLIGHT_DEPLOYMENT_GUIDE.md` (first deployment reference)

---

## 🏁 Quick Reference Commands

```bash
# Verify versions
## 🏁 Quick Reference Commands

**Complete deployment in 4 commands:**

```bash
# 1. Verify versions are all 0.2.0+15
cd /Users/ianhamlet/development/LoyaltyCards/03-Source
grep "appVersion" shared/lib/version.dart
grep "version:" customer_app/pubspec.yaml
grep "version:" supplier_app/pubspec.yaml

# 2. Build Customer App IPA
cd customer_app
flutter clean && flutter pub get && flutter build ipa --release
# IPA created at: build/ios/ipa/customer_app.ipa

# 3. Build Supplier App IPA
cd ../supplier_app
flutter clean && flutter pub get && flutter build ipa --release
# IPA created at: build/ios/ipa/supplier_app.ipa

# 4. Upload both IPAs via Transporter
open -a Transporter
# Then drag-drop both IPA files and click Deliver
```

**IPA Locations:**
- Customer: `/Users/ianhamlet/development/LoyaltyCards/03-Source/customer_app/build/ios/ipa/customer_app.ipa`
- Supplier: `/Users/ianhamlet/development/LoyaltyCards/03-Source/supplier_app/build/ios/ipa/supplier_app.ipa`

---

**End of Build 15 Deployment Guide**

Good luck with the deployment! 🚀
