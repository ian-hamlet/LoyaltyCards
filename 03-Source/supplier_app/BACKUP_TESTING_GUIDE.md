# Supplier Backup & Recovery Testing Guide

**Build:** 76  
**Feature:** REQ-021 Supplier Configuration Backup/Recovery  
**Date:** April 13, 2026

---

## 🎯 How to Access the Backup Feature

### Method 1: Via Settings (Main Entry Point)

1. **Open Supplier App** on your device
2. **Complete supplier onboarding** if not already done:
   - Set business name (e.g., "Test Coffee Shop")
   - Choose stamps required (e.g., 10)
   - Select brand color
   - Choose operation mode (Simple or Secure)
3. **Tap Settings icon** (gear icon in top-right of Home screen)
4. **Scroll to "Backup & Recovery" section**
5. **Tap "Create Recovery Backup"**

### Method 2: During First-Time Setup (Not yet implemented)

_Note: Integration with onboarding flow is planned but not yet implemented._

---

## 📋 Testing Checklist

### Test 1: Create Recovery Backup

**Steps:**
1. Go to Settings → Create Recovery Backup
2. Verify the screen shows:
   - ✅ Red warning banner about security
   - ✅ QR code with business name
   - ✅ "Recovery Backup - No Expiry" label
   - ✅ Created date
   - ✅ Four storage option buttons
   - ✅ Completion tracker (0/4)

**Expected Result:** Screen displays correctly with QR code

---

### Test 2: Save to Photos

**Steps:**
1. On backup screen, tap **"Save to Photos"**
2. Grant photo access if prompted
3. Check Photos app

**Expected Results:**
- ✅ Success message appears
- ✅ Button shows green checkmark
- ✅ Completion tracker updates (1/4)
- ✅ Image saved to Photos with name: `LoyaltyCards-Recovery-[BusinessName]-2026-04-13.png`
- ✅ QR code visible in saved image

**To Verify:**
```bash
Open Photos app → Search "LoyaltyCards"
```

---

### Test 3: Print Backup (PDF)

**Steps:**
1. On backup screen, tap **"Print Backup"**
2. System print dialog appears
3. Select printer OR "Save as PDF"

**Expected Results:**
- ✅ Print dialog opens
- ✅ PDF preview shows:
  - Business name
  - Large QR code
  - Red security warning
  - Storage recommendations
  - Recovery instructions
- ✅ Can print or save as PDF

**iOS Simulator Note:** Printing may not work in simulator. Test on physical device.

---

### Test 4: Email to Self

**Steps:**
1. On backup screen, tap **"Email to Myself"**
2. System share sheet appears
3. Select Mail app
4. Email should be pre-filled:
   - **Subject:** "LoyaltyCards Backup - [Business Name]"
   - **Body:** Warning text + recovery instructions
   - **Attachment:** QR code PNG image

**Expected Results:**
- ✅ Share sheet opens
- ✅ Can select Mail or other apps
- ✅ Email has correct subject
- ✅ Body text includes warnings
- ✅ QR image attached

**To Verify:**
- Send email to yourself
- Check inbox on any device
- Verify QR code is readable

---

### Test 5: Save to Files

**Steps:**
1. On backup screen, tap **"Save to Files"**
2. iOS: Share sheet opens, can save to iCloud Drive
3. Android: File saved to Downloads folder

**Expected Results:**
- ✅ iOS: Share sheet allows saving to Files app
- ✅ File name: `LoyaltyCards-Recovery-[BusinessName]-2026-04-13.png`
- ✅ Can browse to file in Files/Downloads

**To Verify (iOS):**
```
Files app → On My iPhone or iCloud Drive → Find file
```

**To Verify (Android):**
```
Files app → Downloads → Find file
```

---

### Test 6: Multiple Backup Methods

**Steps:**
1. Use all four storage methods in sequence
2. Watch completion tracker

**Expected Results:**
- ✅ Each method shows green checkmark after success
- ✅ Completion tracker updates: 1/4 → 2/4 → 3/4 → 4/4
- ✅ Container turns green when 2+ methods completed
- ✅ Text shows "We recommend at least 2 methods"

---

### Test 7: Skip Warning

**Steps:**
1. Create new business (or reset existing)
2. Go to backup screen
3. Tap **"Done"** without using any backup method
4. Dialog should appear

**Expected Results:**
- ✅ Warning dialog appears
- ✅ Title: "No Backup Created"
- ✅ Explains consequences of device loss
- ✅ Two options: "Go Back" or "Skip Anyway"
- ✅ "Skip Anyway" is styled in red

---

### Test 8: QR Code Size and Readability

**Steps:**
1. Create backup
2. Save QR to Photos
3. Open Photos and zoom into QR code
4. Try scanning with another device's camera

**Expected Results:**
- ✅ QR code is sharp and clear (800x800px)
- ✅ Can be scanned by standard QR scanner
- ✅ Contains JSON data (not encrypted in current version)

**To Verify QR Contents:**
```bash
# Scan QR with camera app or QR scanner
# Should show JSON starting with:
{"type":"recovery","version":1,"businessId":"..."}
```

---

### Test 9: Cross-Device Compatibility

**Steps:**
1. Create backup on iOS device
2. Email QR to self
3. Open email on Android device
4. Verify QR is readable

**Expected Results:**
- ✅ QR code displays correctly on both platforms
- ✅ Can scan on either platform
- ✅ Image quality is maintained

---

## 🔍 Technical Verification

### Check Backup Data Structure

```dart
// Expected JSON structure in QR code:
{
  "type": "recovery",           // or "clone"
  "version": 1,
  "businessId": "uuid-v4",
  "businessName": "Test Coffee Shop",
  "privateKey": "base64-string",
  "publicKey": "base64-string",
  "stampsRequired": 10,
  "brandColor": "#8B4513",
  "operationMode": "simple",   // or "secure"
  "timestamp": "2026-04-13T...",
  "expiresAt": null,           // null for recovery
  "signature": "hmac-sha256"
}
```

### Verify Signature

The `signature` field should be a base64-encoded HMAC-SHA256 hash of all other fields. This prevents tampering.

### Check File Names

All exported files should follow this pattern:
```
LoyaltyCards-Recovery-BusinessName-2026-04-13.png
LoyaltyCards-Recovery-BusinessName-2026-04-13.pdf
```

---

## ⚠️ Known Limitations (Current Build)

1. **No Import/Recovery Yet**
   - Can create backups
   - Cannot restore from backup yet
   - Import screen not implemented

2. **No Clone QR**
   - 24-hour expiring clone QR not implemented
   - Only recovery (non-expiring) works

3. **No Encryption**
   - QR data is signed but not encrypted
   - Future: Add optional password protection

4. **No First-Time Backup Prompt**
   - Must manually go to Settings
   - Future: Auto-prompt after onboarding

5. **Simulator Limitations**
   - Print function may not work in iOS Simulator
   - Test printing on physical device

---

## 🐛 What to Look For (Potential Issues)

### Visual Issues:
- [ ] QR code too small or pixelated
- [ ] Warning banner not visible
- [ ] Buttons not responding
- [ ] Completion tracker not updating

### Functional Issues:
- [ ] Photos permission denied - no error message
- [ ] Print dialog crashes
- [ ] Email doesn't attach QR image
- [ ] File save fails silently

### Data Issues:
- [ ] QR code won't scan
- [ ] JSON structure incorrect
- [ ] Business name with special characters breaks filename
- [ ] Signature verification fails

---

## 📱 Device Testing Matrix

| Feature | iOS Physical | iOS Simulator | Android Physical | Android Simulator |
|---------|-------------|---------------|------------------|-------------------|
| Save to Photos | ✅ Test | ⚠️ May fail | ✅ Test | ⚠️ May fail |
| Print PDF | ✅ Test | ❌ Won't work | ✅ Test | ❌ Won't work |
| Email Share | ✅ Test | ✅ Test | ✅ Test | ✅ Test |
| Save to Files | ✅ Test | ✅ Test | ✅ Test | ✅ Test |

---

## 🔄 Next Testing Phase (After Import Implementation)

Once import/recovery is implemented, test:

1. **Full Recovery Flow**
   - Create backup on Device A
   - Scan backup on Device B
   - Verify same Business ID restored
   - Verify same crypto keys
   - Verify existing customer cards still validate

2. **Clone Flow**
   - Generate 24h clone QR
   - Scan on second device
   - Verify both devices work independently
   - Verify expiry after 24 hours

---

## 📊 Success Criteria

✅ **Backup Creation:**
- All 4 storage methods work on physical device
- QR codes are readable and contain correct data
- Files have consistent naming

✅ **User Experience:**
- Clear warnings about security
- Intuitive button states (checkmarks)
- Helpful guidance about backup methods
- No silent failures

✅ **Cross-Platform:**
- Works on both iOS and Android
- QR codes readable across platforms
- File formats compatible

---

## 🚀 Testing Quick Start

**Fastest way to test:**

```bash
# 1. Deploy to device
cd 03-Source/supplier_app
flutter run --release

# 2. In app:
Settings → Create Recovery Backup → Try all 4 methods

# 3. Verify:
Photos app → Search "LoyaltyCards"
Mail app → Check sent/drafts
Files app → Check downloads
```

---

## 📝 Report Issues

When reporting issues, include:
- Device type (iPhone 12, Pixel 5, etc.)
- iOS/Android version
- Which storage method failed
- Error message (if any)
- Screenshots

---

**Status:** Ready for comprehensive device testing  
**Build:** 76 (19.1MB supplier app)  
**Last Updated:** April 13, 2026
