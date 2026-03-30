# LoyaltyCards Testing Guide - Your First Flutter Project

**Welcome!** This guide will walk you through setting up Flutter and testing the LoyaltyCards prototype for the first time.

---

## 📋 Prerequisites Checklist

Before you start, you'll need:
- [ ] Windows computer with PowerShell
- [ ] Internet connection (for downloads)
- [ ] ~5GB free disk space
- [ ] 1-2 hours for initial setup
- [ ] Android phone OR willingness to use emulator

---

## Part 1: Install Flutter (One-Time Setup)

### Step 1: Download and Install Flutter SDK

Open **PowerShell** and run:

```powershell
# Create a directory for Flutter
New-Item -ItemType Directory -Path C:\dev -Force

# Download Flutter (this may take several minutes)
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip" -OutFile "C:\dev\flutter.zip"

# Extract Flutter
Expand-Archive -Path C:\dev\flutter.zip -DestinationPath C:\dev\
```

### Step 2: Add Flutter to Your PATH

```powershell
# Add Flutter to PATH so you can run 'flutter' command anywhere
[System.Environment]::SetEnvironmentVariable(
    "Path",
    [System.Environment]::GetEnvironmentVariable("Path", "User") + ";C:\dev\flutter\bin",
    "User"
)
```

**IMPORTANT**: Close PowerShell and open a NEW PowerShell window for PATH changes to take effect.

### Step 3: Verify Flutter Installation

In your NEW PowerShell window:

```powershell
flutter --version
```

You should see something like:
```
Flutter 3.19.0 • channel stable
```

### Step 4: Run Flutter Doctor

```powershell
flutter doctor
```

This will show what's installed and what's missing. Don't worry if you see ❌ marks - we'll fix them next!

---

## Part 2: Install Android Development Tools

### Step 5: Install Android Studio

**Option A: Using winget (easiest)**
```powershell
winget install Google.AndroidStudio
```

**Option B: Manual Download**
1. Go to https://developer.android.com/studio
2. Download Android Studio
3. Run installer and accept all defaults

### Step 6: Configure Android Studio

1. **Open Android Studio** (it will take a few minutes first time)
2. Complete the setup wizard (accept all defaults)
3. Click **More Actions** → **SDK Manager**
4. In the **SDK Platforms** tab, ensure these are checked:
   - ✅ Android 14.0 ("UpsideDownCake") - API Level 34
5. In the **SDK Tools** tab, ensure these are checked:
   - ✅ Android SDK Build-Tools
   - ✅ Android SDK Command-line Tools
   - ✅ Android Emulator
   - ✅ Android SDK Platform-Tools
6. Click **Apply** and wait for downloads to complete

### Step 7: Accept Android Licenses

Back in PowerShell:

```powershell
flutter doctor --android-licenses
```

Type `y` and press Enter for each license agreement (there will be several).

### Step 8: Install Flutter Plugin in Android Studio

1. In Android Studio, go to **File** → **Settings** (or **Preferences** on Mac)
2. Click **Plugins**
3. Search for "**Flutter**"
4. Click **Install**
5. Also install "**Dart**" plugin (should be suggested automatically)
6. Click **OK** and **Restart** Android Studio

---

## Part 3: Set Up VS Code (Recommended)

### Step 9: Install VS Code

```powershell
winget install Microsoft.VisualStudioCode
```

Or download from: https://code.visualstudio.com

### Step 10: Install Flutter Extension in VS Code

1. Open VS Code
2. Click Extensions icon (or press `Ctrl+Shift+X`)
3. Search for "**Flutter**"
4. Click **Install** on the official Flutter extension
5. The Dart extension will install automatically

---

## Part 4: Set Up a Test Device

You need ONE of these options to run the app:

### Option A: Use Your Android Phone (Recommended)

1. **On your phone:**
   - Go to **Settings** → **About Phone**
   - Find **Build Number** and tap it **7 times**
   - You'll see "You are now a developer!"
   
2. **Enable USB Debugging:**
   - Go to **Settings** → **System** → **Developer Options**
   - Toggle on **USB Debugging**
   - Toggle on **Install via USB** (if available)

3. **Connect to Computer:**
   - Connect phone to computer with USB cable
   - On phone, tap **Allow** when prompted "Allow USB debugging?"
   - Select **Always allow from this computer**

4. **Verify Connection:**
   ```powershell
   flutter devices
   ```
   
   You should see your phone listed!

### Option B: Use an Android Emulator

1. **In Android Studio:**
   - Click **More Actions** → **Virtual Device Manager**
   - Click **Create Device**
   - Select **Pixel 7** (recommended)
   - Click **Next**
   - Select **UpsideDownCake** (API 34) system image
   - Click **Download** if needed, then **Next**
   - Click **Finish**

2. **Start Emulator:**
   - Click the ▶️ Play button next to your device
   - Wait for emulator to boot (takes 1-2 minutes first time)

3. **Verify:**
   ```powershell
   flutter devices
   ```
   
   You should see the emulator listed!

---

## Part 5: Run the LoyaltyCards Prototype

### Step 11: Navigate to Project

```powershell
cd E:\dev\personal\LoyaltyCards\03-Source\loyalty_cards_prototype
```

### Step 12: Install Project Dependencies

```powershell
flutter pub get
```

You'll see packages being downloaded. This is normal and happens once.

### Step 13: Run the App! 🚀

```powershell
flutter run
```

The first build takes **5-10 minutes**. You'll see lots of output - this is normal!

When you see:
```
✓ Built build\app\outputs\flutter-apk\app-debug.apk
```

The app will automatically launch on your device/emulator!

---

## Part 6: Test the Prototype

### What You'll See

The app will show two options:
- **Customer** - For people collecting loyalty cards
- **Supplier** - For businesses issuing cards

### Test Scenario 1: Supplier Issues a Card

**Goal**: Set up a coffee shop and create a loyalty card

1. Tap **Supplier**
2. Enter Business Name: **Joe's Coffee Shop**
3. Select **7 stamps** (most common)
4. Tap **Complete Setup**
5. Tap **Issue Card**
6. You'll see a QR code on screen

**✅ Success**: QR code displayed with business name

**📸 Take a screenshot** - you'll need this for customer testing!

### Test Scenario 2: Customer Picks Up Card

**If you have TWO devices:**
- Device 1: Keep showing supplier QR code
- Device 2: Launch app → Tap **Customer**

**If you have ONE device:**
- Take screenshot of supplier QR code
- Back out to home screen
- Tap **Customer**

**Now:**
1. Tap **Customer** (if not already there)
2. Tap the **+ Add Card** button (bottom right)
3. Tap **Use Mock Data (Testing)** button at bottom

OR if you want to test scanning:
3. Point camera at the QR code (screenshot on computer monitor works!)

**✅ Success**: Card appears in wallet showing "Joe's Coffee Shop" with 0/7 stamps!

### Test Scenario 3: Add a Stamp

**This demonstrates the core interaction**

**Customer (showing card):**
1. Tap on the card to open details
2. Tap **Show QR to Get Stamp**
3. QR code displays

**Supplier (stamping):**
1. Back to home → **Supplier** mode
2. Tap **Stamp Card**
3. *In a real scenario, scan customer QR*
   *For testing: Press Back and use mock flow*
4. Confirm stamp addition
5. Stamp token QR displays

**Customer (receiving stamp):**
1. *In a real scenario, scan supplier stamp token*
2. Card updates to show **1/7 stamps**

**✅ Success**: Customer card now shows 1 filled circle out of 7!

### Test Scenario 4: Visual Card Progress

**Repeat stamping** (you can use mock data) until you have several stamps.

**Observe:**
- Circles fill in as stamps are added
- Counter updates (3/7, 4/7, etc.)
- When complete (7/7), card shows "COMPLETE" badge

**✅ Success**: Visual progress is clear and intuitive!

### Test Scenario 5: Redeem Card

**Once card is complete (7/7):**

**Customer:**
1. Open completed card
2. Tap **Show QR to Redeem**
3. QR code displays with celebration icon 🎉

**Supplier:**
1. Tap **Redeem Card**
2. *In real scenario, scan customer QR*
3. Confirm redemption
4. Success message shows

**✅ Success**: Card resets to 0/7 stamps, ready for reuse!

---

## Part 7: What to Evaluate

As you test, consider these questions:

### Ease of Use
- [ ] Could a coffee shop owner set this up without help?
- [ ] Could a customer figure out how to add a card?
- [ ] Is the stamping process faster than a physical card?
- [ ] Is it obvious when a reward is ready?

### Visual Design
- [ ] Are the stamp circles clear and intuitive?
- [ ] Do the colors and branding look professional?
- [ ] Is text large enough to read easily?
- [ ] Are buttons easy to tap?

### Real-World Concerns
- [ ] Would this work during a busy morning rush?
- [ ] Is the screen bright enough to scan in sunlight?
- [ ] Would older customers understand this?
- [ ] Any confusing steps?

### Write Down:
- Things that worked well
- Things that were confusing
- Features you wish existed
- Any bugs or crashes

---

## Part 8: Troubleshooting

### "flutter: The term 'flutter' is not recognized"

**Fix**: You need to restart PowerShell after adding Flutter to PATH.
1. Close PowerShell
2. Open NEW PowerShell window
3. Try again

### "No devices found"

**Fix**: Restart adb (Android Debug Bridge)
```powershell
cd C:\dev\flutter\bin\cache\dart-sdk\bin
adb kill-server
adb start-server
flutter devices
```

### App won't build / "Gradle error"

**Fix**: Clean and rebuild
```powershell
flutter clean
flutter pub get
flutter run
```

### Camera won't scan QR codes

**Options**:
1. Use **"Use Mock Data"** button for testing
2. Display QR code on computer screen and scan with phone
3. Take screenshot and scan from another device
4. Increase screen brightness to maximum

### App is slow in emulator

**This is normal!** Emulators are slower than real devices. For best testing experience, use a physical Android phone.

---

## Part 9: Making Changes (Once You're Comfortable)

### Hot Reload (Instant Updates!)

While app is running:
1. Edit any Dart file in VS Code
2. Save the file (`Ctrl+S`)
3. App updates INSTANTLY on your device!

**Try it:**
1. Open `lib/screens/home_screen.dart`
2. Change line 18: `'LoyaltyCards'` to `'My Loyalty App'`
3. Save file
4. Watch app update immediately!

Press `r` in PowerShell to hot reload manually.

### Useful Commands

```powershell
# Run app
flutter run

# Hot reload (while running)
# Press 'r' in terminal

# Hot restart (full restart)
# Press 'R' in terminal

# Stop app
# Press 'q' in terminal

# Clean build
flutter clean

# Analyze code for issues
flutter analyze

# Run tests (when we add them)
flutter test
```

---

## Part 10: Next Steps (After Testing)

### Tomorrow's Session

1. **Review your notes** from testing
2. **Identify improvements** needed
3. **Prioritize changes** (critical vs nice-to-have)
4. **Make small tweaks** using hot reload
5. **Test again** with real users (coffee shop owner?)

### Phase 2: Real Implementation

Once UX is validated:
- [ ] Add cryptographic signatures for security
- [ ] Implement SQLite database for persistence
- [ ] Build proper QR validation
- [ ] Add offline sync handling
- [ ] Implement transaction history
- [ ] Add error handling and edge cases

---

## 📚 Additional Resources

### Flutter Documentation
- **Official Docs**: https://docs.flutter.dev
- **Flutter Codelabs**: https://docs.flutter.dev/codelabs
- **Widget Catalog**: https://docs.flutter.dev/ui/widgets

### Your Project Documentation
- **Setup Guide**: `E:\dev\personal\LoyaltyCards\03-Source\FLUTTER_SETUP_GUIDE.md`
- **Quick Start**: `E:\dev\personal\LoyaltyCards\03-Source\QUICK_START.md`
- **Requirements**: `E:\dev\personal\LoyaltyCards\00-Planning\Requirements\README.md`

### Getting Help
- **Flutter Community**: https://flutter.dev/community
- **Stack Overflow**: https://stackoverflow.com/questions/tagged/flutter
- **Flutter Discord**: https://discord.gg/flutter

---

## ✅ Daily Checklist (For Tomorrow)

When you come back to work on this:

```
[ ] Open PowerShell
[ ] cd E:\dev\personal\LoyaltyCards\03-Source\loyalty_cards_prototype
[ ] Ensure device/emulator is connected: flutter devices
[ ] Run the app: flutter run
[ ] Open VS Code: code .
[ ] Start testing/making changes
```

---

## 🎉 Congratulations!

You've set up Flutter and tested your first mobile app prototype!

**What you've accomplished:**
✅ Installed Flutter development environment  
✅ Configured Android tools  
✅ Run your first Flutter app  
✅ Tested P2P loyalty card interactions  
✅ Evaluated UX and design decisions  

**Remember:**
- First build: ~10 minutes (normal!)
- Subsequent runs: 30-60 seconds
- Hot reload: INSTANT changes!
- When stuck: Check this guide, run `flutter doctor`, search error messages

---

**Last Updated**: 2026-03-30  
**Your Project**: E:\dev\personal\LoyaltyCards  
**Your Contact**: [Add your details if sharing with others]

**Happy Flutter coding! 🚀**
