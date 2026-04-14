# Tomorrow's Checkpoint - TestFlight Upload

**Date:** April 14, 2026  
**Status:** Ready to upload via Transporter

---

## ✅ What's Complete

- [x] GitHub Pages enabled with privacy policy
- [x] Support email added: ian.hamlet@dotConnected.com
- [x] Custom app icons installed (both apps)
- [x] Version bumped to v0.2.0 (Build 0)
- [x] Bundle IDs registered in Apple Developer portal
- [x] App Store Connect listings created:
  - Customer: "LoyaltyCards - Digital Stamps"
  - Supplier: "LoyaltyCards Business"
- [x] Apps archived in Xcode (v0.2.0)
- [x] Customer app rebuilt to fix dSYM issue

---

## ⏳ What's Next: Upload via Transporter

### Issue We Hit
Xcode upload fails with dSYM error for `objective_c.framework`

### Solution: Use Transporter App

#### Step 1: Export IPA from Xcode

**In Xcode Archives window:**
1. Select **customer app** archive (v0.2.0)
2. Click **Distribute App**
3. Select **App Store Connect** → **Next**
4. **IMPORTANT:** Select **Export** (NOT Upload)
5. Click through signing screens
6. Choose export location (Desktop or Downloads)
7. Click **Export**
8. Note where the `.ipa` file is saved

Repeat for **supplier app** archive.

---

#### Step 2: Install Transporter (if needed)

1. Open **App Store** app on Mac
2. Search for **Transporter** (by Apple)
3. Install (free)

---

#### Step 3: Upload Both IPAs

**For Customer App:**
1. Open Transporter app
2. Sign in with Apple Developer account
3. Drag customer `.ipa` file into window (or click +)
4. Click **Deliver**
5. Wait for upload (2-5 minutes)
6. Should complete successfully!

**Repeat for Supplier App**

---

#### Step 4: Wait for Processing

- Apps process in App Store Connect (10-20 minutes)
- You'll get email confirmations
- Check App Store Connect → Apps → Your App → TestFlight tab

---

#### Step 5: Configure TestFlight

**In App Store Connect (after builds appear):**

1. Go to each app → **TestFlight** tab
2. Fill in **Test Information:**
   - What to Test: "Initial pilot testing of v0.2.0"
   - Beta App Description: (copy from app description)
   - Feedback Email: ian.hamlet@dotConnected.com
   - Privacy Policy URL: https://ian-hamlet.github.io/LoyaltyCards/PRIVACY_POLICY

3. **Export Compliance:**
   - "Does your app use encryption?" → **NO**
   - (Or select appropriate option)

4. Create **Internal Testing** group:
   - Click + under Internal Testing
   - Name: "Internal Testers"
   - Add yourself (your Apple ID email)
   - Select build (0.2.0)

5. **Save**

---

#### Step 6: Install on Device

**Internal testers get instant access (no review needed):**

1. Install TestFlight app from App Store (on iPhone/iPad)
2. Sign in with same Apple ID
3. Apps appear automatically
4. Click **Install** for each app
5. Start testing!

---

## Quick Reference

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

**App Names in App Store Connect:**
- Customer: "LoyaltyCards - Digital Stamps"
- Supplier: "LoyaltyCards Business"

**Version:** v0.2.0 (Build 0)

---

## Files Ready

**Archives Ready in Xcode:**
- ✅ Customer app v0.2.0 (rebuilt, fresh)
- ✅ Supplier app v0.2.0 (may need rebuild like customer)

**If Supplier App Needs Rebuild:**
```bash
cd /Users/ianhamlet/development/LoyaltyCards/03-Source/supplier_app
flutter clean
flutter build ios --release --no-codesign --no-tree-shake-icons
open ios/Runner.xcworkspace
```
Then archive in Xcode again.

---

## Estimated Time Tomorrow

- Export IPAs: 5 minutes
- Install Transporter: 2 minutes (if needed)
- Upload both apps: 10 minutes
- Wait for processing: 20 minutes
- Configure TestFlight: 10 minutes
- Install on device: 5 minutes

**Total: ~1 hour to have apps installed and testing!**

---

**Current Branch:** develop (7082bf5)  
**Status:** Ready for upload via Transporter tomorrow morning!
