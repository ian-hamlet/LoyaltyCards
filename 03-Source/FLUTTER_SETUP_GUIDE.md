# Flutter Development Setup & Testing Guide

## Quick Start

This guide will help you install Flutter, set up the development environment, and deploy the LoyaltyCards prototype to test devices.

---

## Part 1: Install Flutter

### Windows Setup (Your Platform)

#### 1. Download Flutter SDK

```powershell
# Create development directory
New-Item -ItemType Directory -Path C:\dev\flutter -Force
cd C:\dev\flutter

# Download Flutter (latest stable)
# Visit: https://docs.flutter.dev/get-started/install/windows
# Or use direct download:
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip" -OutFile "flutter.zip"

# Extract
Expand-Archive -Path flutter.zip -DestinationPath C:\dev\
```

#### 2. Add to PATH

```powershell
# Add Flutter to system PATH
[System.Environment]::SetEnvironmentVariable(
    "Path",
    [System.Environment]::GetEnvironmentVariable("Path", "User") + ";C:\dev\flutter\bin",
    "User"
)

# Restart PowerShell, then verify
flutter --version
```

#### 3. Run Flutter Doctor

```powershell
# Check what's missing
flutter doctor

# Expected output will show:
# [✓] Flutter
# [✗] Android toolchain - Need to install
# [✗] Visual Studio - Need to install
# [!] Android Studio - Need to install
```

---

## Part 2: Install Android Development Tools

### Android Studio Setup

#### 1. Download & Install Android Studio

```powershell
# Download from: https://developer.android.com/studio
# Or use winget (Windows Package Manager)
winget install Google.AndroidStudio
```

#### 2. Install Android SDK

1. Open Android Studio
2. Go to **Tools** → **SDK Manager**
3. Install:
   - Android SDK Platform 34 (latest)
   - Android SDK Platform-Tools
   - Android SDK Build-Tools
   - Android SDK Command-line Tools

#### 3. Accept Android Licenses

```powershell
flutter doctor --android-licenses
# Type 'y' to accept all licenses
```

#### 4. Install Flutter & Dart Plugins

1. In Android Studio: **File** → **Settings** → **Plugins**
2. Search for "Flutter" and install
3. Install "Dart" plugin (dependency)
4. Restart Android Studio

---

## Part 3: Set Up VS Code (Recommended for Flutter)

### VS Code Setup

#### 1. Install VS Code

```powershell
winget install Microsoft.VisualStudioCode
```

#### 2. Install Flutter Extension

1. Open VS Code
2. Go to Extensions (`Ctrl+Shift+X`)
3. Search "Flutter" and install
4. Install "Dart" extension (auto-suggested)

#### 3. Verify Setup

```powershell
# Run doctor again
flutter doctor

# Should now show:
# [✓] Flutter
# [✓] Android toolchain
# [✓] VS Code
# [✓] Connected device (if emulator running)
```

---

## Part 4: Set Up Android Emulator

### Create Virtual Device

#### Option A: Using Android Studio

1. Open Android Studio
2. **Tools** → **Device Manager**
3. Click **Create Device**
4. Select device: **Pixel 7** (recommended)
5. Select system image: **API 34 (Android 14)**
6. Download if necessary
7. Finish and start emulator

#### Option B: Using Command Line

```powershell
# List available devices
flutter emulators

# Create emulator
flutter emulators --create --name loyalty_test

# Launch emulator
flutter emulators --launch loyalty_test
```

---

## Part 5: Set Up Physical Android Device

### Enable Developer Mode

1. **On your Android phone**:
   - Go to **Settings** → **About Phone**
   - Tap **Build Number** 7 times
   - Developer options enabled!

2. **Enable USB Debugging**:
   - Go to **Settings** → **Developer Options**
   - Enable **USB Debugging**
   - Enable **Install via USB** (if available)

3. **Connect to Computer**:
   - Connect phone via USB cable
   - Accept "Allow USB Debugging" prompt on phone
   - Verify connection:

```powershell
flutter devices

# Should show:
# Android SDK built for x86 (emulator)
# YOUR_PHONE_MODEL • xxxxx • android-arm64 • Android 14 (API 34)
```

---

## Part 6: Create Flutter Prototype Project

### Initialize Project

```powershell
# Navigate to source directory
cd E:\dev\personal\LoyaltyCards\03-Source

# Create new Flutter project
flutter create loyalty_cards_prototype

# Navigate into project
cd loyalty_cards_prototype

# Open in VS Code
code .
```

### Install Dependencies

Edit `pubspec.yaml`:

```yaml
name: loyalty_cards_prototype
description: LoyaltyCards P2P mobile prototype
publish_to: 'none'
version: 0.1.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # QR Code
  qr_flutter: ^4.1.0
  mobile_scanner: ^5.0.0
  
  # Crypto (for future)
  crypto: ^3.0.3
  uuid: ^4.3.0
  
  # UI
  cupertino_icons: ^1.0.6
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

Install packages:

```powershell
flutter pub get
```

---

## Part 7: Run the Prototype

### Test on Emulator

```powershell
# Make sure emulator is running
flutter emulators --launch loyalty_test

# Run the app
flutter run
```

### Test on Physical Device

```powershell
# Make sure device is connected
flutter devices

# Run on device
flutter run -d <device-id>

# Or if only one device:
flutter run
```

### Hot Reload (During Development)

While app is running:
- Press `r` to hot reload (instant UI updates)
- Press `R` to hot restart (full app restart)
- Press `q` to quit

---

## Part 8: Testing the P2P Interactions

### What You'll Need

To fully test supplier ↔ customer interactions:

**Option 1: Two Physical Devices** (Recommended)
- One device as "Supplier App"
- One device as "Customer App"
- QR codes can be scanned between devices

**Option 2: One Device + Computer Screen**
- Phone as one actor
- Display QR code on computer screen
- Phone scans computer screen

**Option 3: Two Emulators** (Limited - can't scan QR codes)
- Good for UI testing
- Cannot test QR scanning (no camera)
- Use mock QR data

### Testing Workflow

#### Test 1: Supplier Onboarding
```powershell
# Run supplier app on device 1
flutter run --flavor supplier
```

**Actions**:
1. Launch app
2. Create business profile (name, branding)
3. Configure stamp card (e.g., 7 stamps)
4. Generate issuer QR code

**Expected**: Supplier setup complete, QR code displayed

#### Test 2: Customer Card Pickup
```powershell
# Run customer app on device 2
flutter run --flavor customer
```

**Actions**:
1. Launch app
2. Tap "Add Card"
3. Scan supplier QR code (from device 1 screen)
4. Card appears in customer wallet

**Expected**: Card added with 0 stamps, shows supplier branding

#### Test 3: Apply Stamp
**Device 1 (Supplier)**:
1. Tap "Stamp Card"
2. Show stamp request screen (wait for customer)

**Device 2 (Customer)**:
1. Open card
2. Tap "Get Stamp"
3. Display card QR code

**Device 1 (Supplier)**:
1. Scan customer QR code
2. Confirm stamp addition
3. Display stamp token QR code

**Device 2 (Customer)**:
1. Scan supplier stamp token QR code
2. Card updates with new stamp

**Expected**: Customer card shows 1/7 stamps

#### Test 4: Redemption
**Device 2 (Customer)**: Shows completed card (7/7 stamps)

**Device 1 (Supplier)**:
1. Tap "Redeem Card"
2. Scan customer card QR code
3. Verify all stamps valid
4. Generate redemption token QR

**Device 2 (Customer)**:
1. Scan redemption QR code
2. Card resets to 0/7 stamps

**Expected**: Card reset, redemption recorded

---

## Part 9: Debugging & Development Tools

### Flutter DevTools

```powershell
# Launch DevTools
flutter pub global activate devtools
flutter pub global run devtools

# Then run your app with:
flutter run --observatory-port=9200
```

**Features**:
- Inspector (widget tree)
- Performance profiling
- Network monitoring
- Logging console

### VS Code Debugging

1. Set breakpoints in code (click left margin)
2. Press `F5` to debug
3. Use debug console to inspect variables

### Useful Commands

```powershell
# Clean build cache
flutter clean

# Rebuild app
flutter run

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Format code
flutter format lib/

# Build APK for testing
flutter build apk --debug

# Install APK on device
flutter install
```

---

## Part 10: Testing Checklist

### Pre-Flight Checks

- [ ] Flutter doctor shows all green checkmarks
- [ ] At least one device connected (emulator or physical)
- [ ] VS Code Flutter extension installed
- [ ] Project dependencies installed (`flutter pub get`)
- [ ] App launches successfully (`flutter run`)

### Interaction Testing

- [ ] Supplier can complete onboarding flow
- [ ] Supplier can display issuer QR code
- [ ] Customer can scan supplier QR code (or use mock data)
- [ ] Customer card appears in wallet with correct branding
- [ ] Stamp flow works (customer shows QR, supplier scans, stamp applied)
- [ ] Customer can see updated stamp count
- [ ] Redemption flow works (full card → redeem → reset)
- [ ] UI is clear and intuitive
- [ ] Visual feedback is immediate
- [ ] No crashes or errors

### Performance Testing

- [ ] QR code generation < 1 second
- [ ] QR code scanning < 2 seconds
- [ ] Screen transitions smooth (60 FPS)
- [ ] App startup < 3 seconds
- [ ] No memory leaks (check DevTools)

---

## Troubleshooting

### Common Issues

**"No devices found"**
```powershell
# Restart adb
adb kill-server
adb start-server
flutter devices
```

**"Gradle build failed"**
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**"Camera permission denied"**
- Check `AndroidManifest.xml` has camera permission
- Grant permission manually in phone settings

**"QR codes won't scan"**
- Ensure good lighting
- Hold camera steady
- Increase QR code size on screen
- Use high contrast (black/white)

**"App crashes on signature verification"**
- Check crypto library imported
- Verify test data is valid
- Check error logs: `flutter logs`

---

## Next Steps

Once prototype is testing successfully:

1. **Gather UX Feedback**: Test with real users
2. **Iterate on Design**: Refine based on testing
3. **Implement Crypto**: Add signature verification
4. **Add Database**: Implement SQLite storage
5. **Production Build**: Build release APK/IPA

---

## Resources

- **Flutter Docs**: https://docs.flutter.dev
- **Flutter Cookbook**: https://docs.flutter.dev/cookbook
- **QR Code Package**: https://pub.dev/packages/qr_flutter
- **Mobile Scanner**: https://pub.dev/packages/mobile_scanner
- **Flutter Community**: https://flutter.dev/community

---

**Document Owner**: Development Team  
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30
