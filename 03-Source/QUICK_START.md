# Flutter Prototype - Quick Reference

## 🎯 What You Have Now

A complete **Flutter prototype** ready for testing the P2P loyalty card interactions!

### 📱 Screens Created

#### Supplier App (6 screens)
1. **Supplier Onboarding** - Set up business name and stamp requirements
2. **Supplier Home** - Dashboard with action buttons
3. **Issue Card** - Generate QR for customer pickup
4. **Stamp Card** - Scan customer QR and add stamp
5. **Redeem Card** - Scan completed card and reset
6. **Statistics** - View activity metrics

#### Customer App (3 screens)
1. **Customer Home** - Wallet view with all cards
2. **Add Card** - Scan supplier QR to pick up card
3. **Card Detail** - View stamps, show QR for stamping/redemption

### 📄 Documentation Created

| Document | Location | Purpose |
|----------|----------|---------|
| **Flutter Setup Guide** | `03-Source/FLUTTER_SETUP_GUIDE.md` | Complete installation instructions |
| **Prototype README** | `03-Source/loyalty_cards_prototype/README.md` | How to run and test |
| **Flutter Decision** | `01-Design/Architecture/DECISION_Flutter_Framework.md` | Why Flutter? |
| **P2P Architecture** | `01-Design/Architecture/DECISION_P2P_Architecture.md` | How P2P works |

---

## 🚀 Getting Started (Installation)

### Step 1: Install Flutter

**Windows (PowerShell)**:
```powershell
# Download Flutter
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip" -OutFile "C:\dev\flutter.zip"

# Extract
Expand-Archive -Path C:\dev\flutter.zip -DestinationPath C:\dev\

# Add to PATH
[System.Environment]::SetEnvironmentVariable(
    "Path",
    [System.Environment]::GetEnvironmentVariable("Path", "User") + ";C:\dev\flutter\bin",
    "User"
)

# Restart PowerShell, then verify
flutter --version
```

Or download manually: https://docs.flutter.dev/get-started/install/windows

### Step 2: Install Android Studio

```powershell
winget install Google.AndroidStudio
```

Or download: https://developer.android.com/studio

### Step 3: Configure Android SDK

1. Open Android Studio
2. **Tools** → **SDK Manager**
3. Install:
   - Android SDK Platform 34
   - Android SDK Build-Tools
   - Android SDK Command-line Tools

```powershell
# Accept licenses
flutter doctor --android-licenses
```

### Step 4: Install VS Code + Flutter Extension

```powershell
winget install Microsoft.VisualStudioCode
```

Then in VS Code:
- Install "Flutter" extension
- Install "Dart" extension

### Step 5: Set Up Test Device

**Option A: Physical Android Phone**
1. Enable Developer Options (tap Build Number 7 times)
2. Enable USB Debugging
3. Connect via USB
4. Accept debugging prompt on phone

**Option B: Android Emulator**
1. Android Studio → **Tools** → **Device Manager**
2. Create Device → Pixel 7 → API 34
3. Launch emulator

Verify: `flutter devices`

---

## 📱 Running the Prototype

### Initialize Project

```bash
cd E:\dev\personal\LoyaltyCards\03-Source\loyalty_cards_prototype

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Test User Flows

#### Test 1: Customer Picks Up Card

**Device 1 (Supplier Mode)**:
1. Launch app → Choose "Supplier"
2. Set up business: "Joe's Coffee Shop", 7 stamps
3. Tap "Issue Card"
4. QR code displays

**Device 2 (Customer Mode)**:
1. Launch app → Choose "Customer"
2. Tap "+ Add Card"
3. Scan Device 1 QR code (or tap "Use Mock Data" for testing)
4. ✅ Card appears in wallet!

#### Test 2: Get a Stamp

**Device 2 (Customer)**:
1. Open card → Tap "Show QR to Get Stamp"
2. Display customer QR code

**Device 1 (Supplier)**:
1. Tap "Stamp Card"
2. Scan Device 2 customer QR
3. Confirm → Display stamp token QR

**Device 2 (Customer)**:
1. Scan supplier stamp token QR
2. ✅ Card updates (1/7 stamps)

#### Test 3: Redeem Reward

Repeat stamping until 7/7 stamps.

**Device 2 (Customer)**:
1. Open completed card
2. Tap "Show QR to Redeem"

**Device 1 (Supplier)**:
1. Tap "Redeem Card"
2. Scan customer redemption QR
3. ✅ Redemption complete, card resets to 0/7

---

## 🧪 Evaluation Checklist

Use this to evaluate the design:

### User Experience
- [ ] Is onboarding clear and simple?
- [ ] Can a customer pick up a card in under 30 seconds?
- [ ] Is stamping fast (< 10 seconds total)?
- [ ] Are visual indicators (stamps) intuitive?
- [ ] Is redemption flow obvious?

### Performance
- [ ] QR code generation instant?
- [ ] QR code scanning < 3 seconds?
- [ ] Screen transitions smooth?
- [ ] No lag or stuttering?

### Visual Design
- [ ] Are cards visually appealing?
- [ ] Is stamp progress clear at a glance?
- [ ] Do colors/branding work well?
- [ ] Is text readable?
- [ ] Are buttons appropriately sized?

### Usability
- [ ] Can a non-technical user navigate?
- [ ] Are errors handled gracefully?
- [ ] Is feedback immediate (haptic/visual)?
- [ ] Are instructions helpful?

### Real-World Testing
- [ ] Works in coffee shop lighting?
- [ ] Screen brightness adequate for scanning?
- [ ] Can scan from another phone screen?
- [ ] Works when customer is in a hurry?

---

## 🛠️ Customizing the Prototype

### Change Stamp Requirements

Edit `lib/screens/supplier/supplier_onboarding.dart`:
```dart
final List<int> _stampOptions = [3, 5, 7, 10, 12, 15, 20];
```

### Modify Card Colors

Edit `lib/screens/customer/customer_home.dart`:
```dart
final colors = [
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
  // Add more colors
];
```

### Adjust QR Code Size

Edit any QR display screen:
```dart
QrImageView(
  size: 300.0, // Change size here
)
```

### Add Custom Branding

Edit card display to include logos:
```dart
// Add to CardWidget
Image.asset('assets/images/logo.png')
```

---

## 🐛 Common Issues

### "flutter: command not found"
- Restart PowerShell after adding to PATH
- Or use full path: `C:\dev\flutter\bin\flutter`

### "No devices found"
```powershell
adb kill-server
adb start-server
flutter devices
```

### QR codes display as blank
- Ensure `qr_flutter` package installed: `flutter pub get`
- Check import: `import 'package:qr_flutter/qr_flutter.dart';`

### Camera permission errors
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA"/>
```

### Build fails on first run
```powershell
flutter clean
flutter pub get
flutter run
```

---

## 📊 What to Measure

### Timing Metrics
- **Onboarding time** (supplier setup): Target < 2 minutes
- **Card pickup time** (customer): Target < 30 seconds
- **Stamp time** (scan to confirmation): Target < 10 seconds
- **Redemption time**: Target < 15 seconds

### User Feedback
- "Was anything confusing?"
- "What would you change?"
- "Would you use this over physical cards?"
- "Any missing features?"

### Technical Metrics
- App size: Check `flutter build apk --analyze-size`
- Performance: Use Flutter DevTools
- Memory: Monitor with Android Studio Profiler

---

## 🔄 Iteration Process

1. **Test** with real users (coffee shop owner + customers)
2. **Gather feedback** (what worked, what didn't)
3. **Identify pain points** (confusing flows, slow interactions)
4. **Modify** Flutter code (screens in `lib/screens/`)
5. **Hot reload** (press `r`) and test again
6. **Repeat** until flows feel natural

---

## ✅ Next Phase (After Testing)

Once prototype testing is complete:

### Phase 2: Core Implementation
1. **Cryptography** - Implement real ECDSA signatures
2. **Database** - Add SQLite for persistent storage
3. **Security** - Hash chains and rate limiting
4. **Validation** - Proper QR data validation
5. **Error Handling** - Robust offline scenarios

### Phase 3: Production Ready
1. **Testing** - Unit tests, integration tests
2. **Performance** - Optimize QR scanning
3. **Accessibility** - Screen readers, color contrast
4. **Localization** - Multiple languages
5. **Distribution** - Publish to App Store/Play Store

---

## 📚 Resources

- **Flutter Docs**: https://docs.flutter.dev
- **QR Flutter**: https://pub.dev/packages/qr_flutter
- **Mobile Scanner**: https://pub.dev/packages/mobile_scanner
- **Our Setup Guide**: [03-Source/FLUTTER_SETUP_GUIDE.md](FLUTTER_SETUP_GUIDE.md)
- **Prototype README**: [03-Source/loyalty_cards_prototype/README.md](loyalty_cards_prototype/README.md)

---

**Last Updated**: 2026-03-30  
**Version**: Prototype 0.1.0  
**Status**: Ready for UX Testing 🚀
