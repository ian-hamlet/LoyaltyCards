# Development Machine Setup (macOS)

**Written:** 2026-08-28, to support moving from one Mac to another mid-project.
**Scope:** everything needed to get a new Mac productive on this repo, beyond what's already in
git. Companion to `docs/technical/ANDROID_DEV_ENVIRONMENT_SETUP.md`, which covers the Android
SDK/emulator toolchain specifically - this doc covers everything else (Flutter, Xcode, git access).

(`source/FLUTTER_SETUP_GUIDE.md` and `source/QUICK_START.md` used to exist here - deleted
2026-08-28. Both were dated 2026-03-30, Windows/PowerShell instructions for a
`loyalty_cards_prototype` project structure that no longer existed even then - the real project is
`source/{shared,customer_app,supplier_app}`. If either turns up again from an old branch/clone,
it's stale; use this doc instead.)

---

## 1. Clone the repo

```bash
git clone https://github.com/ian-hamlet/LoyaltyCards.git
cd LoyaltyCards
```

The remote is HTTPS, not SSH, using macOS Keychain (`git config credential.helper` ->
`osxkeychain`) to cache credentials after the first authenticated push/pull. The first `git push`
on a new machine will prompt for GitHub credentials (a Personal Access Token, not your account
password, if prompted at the terminal) - after that it's cached in Keychain and won't ask again.

## 2. Install Flutter

This project uses the **git-clone method** (not the zip/installer), on the `stable` channel:

```bash
mkdir -p ~/development/flutter-sdk
cd ~/development/flutter-sdk
git clone https://github.com/flutter/flutter.git
cd flutter
git checkout stable
```

Add to `~/.zshrc`:

```bash
export PATH="$PATH:$HOME/development/flutter-sdk/flutter/bin"
```

Then open a new terminal (or `source ~/.zshrc`) and verify:

```bash
flutter --version   # this Mac is on 3.44.8 stable as of 2026-08-28
flutter doctor -v
```

If you need to match this Mac's exact Flutter version rather than whatever's newest on `stable`,
`flutter --version` above shows it - `git checkout` that tag/commit instead of just `stable`.

## 3. Install Xcode (for iOS/macOS builds)

Install Xcode from the App Store (this Mac has 26.3), then:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
```

**Sign into Xcode with the Apple Developer account** (Xcode -> Settings -> Accounts) - needed for
code signing when building/running on a physical iOS device, and for Archive builds destined for
TestFlight/App Store Connect. This is a credential/account step only you can do - not something
scriptable or storable in this repo.

**CocoaPods is NOT needed.** Both apps were fully migrated off CocoaPods to Swift Package Manager
2026-08-27 (see `docs/technical/PACKAGE_UPDATE_MIGRATION_2026-08-26.md`) - there's no `Podfile` in
either app anymore. Skip installing `pod`/CocoaPods entirely; it would be dead weight.

One thing this migration *does* require - a machine-wide Flutter setting, not project config:

```bash
flutter config --enable-swift-package-manager
```

Without this, `flutter build ios`/`flutter build macos` will fail on plugins (like `app_settings`)
that dropped CocoaPods support and ship SPM-only.

## 4. Android toolchain

Separate, longer checklist - see **`docs/technical/ANDROID_DEV_ENVIRONMENT_SETUP.md`** in full.
Short version: Homebrew-installed JDK 17 (formula, not the `temurin` cask - that needs `sudo`),
Homebrew-installed Android SDK command-line tools (not the full Android Studio GUI), several SDK
components via `sdkmanager`, and an AVD created via `avdmanager`. Budget 20GB+ free disk space.
None of it is optional if you want to run the Android emulator - all machine-local, none of it
travels with `git pull`.

## 5. First build on the new machine

```bash
cd source/shared && flutter pub get && flutter test
cd ../customer_app && flutter pub get && flutter test
cd ../supplier_app && flutter pub get && flutter test
```

Expected as of 2026-08-28: shared 216/216, customer_app 186/186, supplier_app 141/141, all
passing, `flutter analyze` clean of errors (pre-existing lint-level info/warnings only).

For iOS: open `source/customer_app/ios/Runner.xcworkspace` (or `supplier_app`'s) in Xcode and Run,
or `flutter run -d <device>` from the CLI once a simulator/device is available.

For Android: once the Android toolchain above is done, `flutter run -d <emulator-id>` the same way.

---

## What travels automatically with `git pull` (for contrast - not action items)

- All application code, including the `compileSdk`/`applicationId` Android fixes and the
  `sharePdf` print fix
- `pubspec.yaml`/`pubspec.lock` dependency versions
- Gradle wrapper/AGP/Kotlin versions (`gradle-wrapper.properties`, `settings.gradle.kts`) -
  Gradle downloads the matching distribution itself on first build, no manual step
- `~/.zshrc`'s `ANDROID_HOME`/`JAVA_HOME` exports do NOT travel (see
  `ANDROID_DEV_ENVIRONMENT_SETUP.md`) - neither does `android/local.properties`, which is
  gitignored and regenerates itself via `flutter pub get` once the SDK is actually installed
