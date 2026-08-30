# Android Port Plan

**Status:** Track 1 (technical setup) underway - toolchain installed and confirmed working on this
Mac, one successful `flutter run` on an emulator already done (2026-08-27, pre-Apple-Silicon-fix).
Functional verification, platform polish, and release-build steps below are not yet started.
Track 2 (Play Console) not started at all.
**Branch:** `feature/android-port`
**Date:** 2026-08-29
**Context:** Porting to Android is low-risk, mostly testing and store-listing work rather than a
rewrite - both apps already ship `android/` scaffolding, `Platform.isAndroid` branches already
exist in `device_service.dart`/`backup_storage_service.dart`, and the ECDSA P-256/SHA-256 signing
(`pointycastle`, pure Dart) has zero OS dependency, so a signature produced on Android verifies
identically on iOS and vice versa. Originating requirement: `Requirements/REQ-003_Mobile_Platform_Support.md`
(its Android acceptance criteria are still unchecked there - this plan is where they actually get
executed; check them off in both places as items land). No Android hardware is owned - see "Open
Decisions / Risks" below for how that's handled.

---

## Track 1: Technical Setup & App-Level Port

### Phase 1: Toolchain (machine-local - see `docs/technical/ANDROID_DEV_ENVIRONMENT_SETUP.md`)
- [x] Android SDK/emulator installed and `flutter doctor` Android toolchain green - 2026-08-27
- [x] Fixed for Apple Silicon after the machine migration: Java, the emulator engine, and the
      system image were all silently Intel-only (masked by Rosetta being present during the
      original setup) - reinstalled all three as native arm64 and confirmed with a cold boot
      completing in 10 seconds - 2026-08-29

### Phase 2: Build Configuration
- [x] `supplier_app` `compileSdk` bumped 36 → 37 (`flutter_secure_storage` 11.0.0 requires it)
- [x] `applicationId` set for both apps (`com.ianhamlet.loyaltycards.supplier`/`customer`)
- [x] First `flutter run` confirmed working on an emulator via device logs - 2026-08-27 (on the
      since-replaced Intel emulator/image)
- [x] Re-confirm `flutter run` works end-to-end on the rebuilt native arm64 emulator - 2026-08-30,
      both apps: release APK built via Gradle, installed, and launched, confirmed via each app's
      own `I/flutter` log line on the device (not just a clean build). customer_app 65s cold
      build, supplier_app 35s (Gradle daemon warm). One benign warning both times ("SDK XML
      versions up to 3 but... version 4 was encountered") - a known cmdline-tools/build-tools
      version-skew cosmetic warning, not a blocker.

### Phase 3: Functional Verification (both apps, on the emulator)
- [x] Manual smoke test: issue card, issue stamps - Express Mode - 2026-08-30, supplier app on the
      Android emulator paired with the customer app on a physical iPhone (no camera needed on the
      Android side for this direction - the iPhone did the scanning). Confirms Android↔iOS QR
      interop, not just Android-side rendering. Redeem not yet tested.
- [x] Business profile editing (name, stamp count) confirmed working on the emulator - 2026-08-30
- [x] Redeem flow, Secure Mode issue/stamp/redeem cycle - 2026-08-30, confirmed working on the
      emulator (signed, time-limited QR)
- [x] Biometric-gated flows (Create Recovery Backup, Clone to Another Device) - 2026-08-30,
      confirmed working after two real bugs were found and fixed (full detail in
      `source/shared/lib/version.dart` Build 37):
      1. `MainActivity` extended plain `FlutterActivity`, but `local_auth`'s `BiometricPrompt`
         requires a `FragmentActivity` host - threw "The current activity must be a
         FragmentActivity" on every `authenticate()` call. This was the actual root blocker.
         Fixed in both apps' `MainActivity.kt` (→ `FlutterFragmentActivity`).
      2. `supplier_app`'s `biometric_auth_service.dart` caught `PlatformException`, but the
         pinned `local_auth_android` 2.0.9 throws `LocalAuthException` instead, so all specific
         error-code handling was dead code (generic "Unexpected error" for every failure,
         platform-independent - not emulator-specific). Fixed with a `LocalAuthException`
         handler; `PlatformException` kept as a defensive fallback.
      With both fixed: no-credential-enrolled state shows the correct friendly message, and with
      a PIN actually set, both Create Recovery Backup and Clone to Another Device work
      end-to-end.
- [x] Recovery Backup file-output paths - share and print both bring up the correct native
      dialogs on the emulator - 2026-08-30. Low risk of surprising further on real hardware:
      unlike the biometric/enrollment issues found above, share/print dialogs are standard OS
      chrome (`share_plus`/`printing`), not something the app or emulator meaningfully diverges
      on. Full save-to-file/actual-print-output round trip still untested, but not considered a
      priority follow-up given this.
- [ ] Secure storage round-trip (`flutter_secure_storage` → Android Keystore, vs. iOS Keychain)
- [ ] QR camera scan - emulators have no real camera by default, see "Open Decisions" below
- [ ] Full automated suite still green in this context (`shared` 216, `customer_app` 186,
      `supplier_app` 141) - these are Dart-only and arch-independent, but worth reconfirming after
      the toolchain rebuild

### Phase 4: Platform Polish
- [ ] "Tell a Friend"/"Tell a Business" screen headline color differs from other screens on
      Android (not an issue on iOS) - found 2026-08-30. Root cause candidate:
      `source/shared/lib/widgets/app_referral_screen.dart:93`, the headline `Text`'s `TextStyle`
      has no explicit `color`, so it inherits the ambient theme's default text color - plausibly
      a light/dark mode difference between the Android emulator's and the test iPhone's system
      theme setting, not yet confirmed. Needs a proper look, not guessed at further here.
- [ ] Adaptive app icon for both apps (Play Store requirement - the iOS icon asset doesn't carry
      over as-is)
- [ ] `AndroidManifest.xml` permissions review (camera, biometric, storage) for both apps
- [ ] Material Design pass - confirm the existing UI doesn't read as obviously iOS-styled (REQ-003's
      acceptance criterion); likely low-effort since Flutter's Material widgets are already the
      default look on Android
- [ ] Decide and set minimum supported Android OS version (`minSdk`)

### Phase 5: Release Build
- [ ] Generate an Android signing keystore (the Play Store equivalent of the Apple Distribution
      certificate step just done for iOS)
- [ ] Configure Gradle signing config for both apps; keep the keystore itself out of git
- [ ] Build a release AAB (`flutter build appbundle`) for both apps and verify it

---

## Track 2: Google Play Developer Account & Store Listing

- [ ] Register a Google Play Developer account ($25 one-time fee)
- [ ] Create Play Console listings for both apps (one developer account, two listings - same
      pattern as the two App Store Connect listings under one Apple Developer account)
- [ ] Store listing content - can start from the existing App Store metadata packets
      (`docs/deployment/APP_STORE_METADATA_PACKET_v2_2_1_36.md`) as a draft, adapted to Play's
      field set and character limits rather than written from scratch
- [ ] Content rating questionnaire
- [ ] Data safety form (Play's equivalent of the App Store's privacy nutrition label)
- [ ] Privacy Policy / Support / Terms URLs - already hosted on Cloudflare Pages from the iOS
      work, should be directly reusable
- [ ] Configure an Internal testing track (Play's TestFlight equivalent)
- [ ] Upload and confirm a first internal test build for both apps

---

## Open Decisions / Risks

- **No Android hardware owned.** The QR camera-scan flow needs a real camera, which the emulator
  doesn't have by default. Two options, neither started: (a) emulator webcam passthrough - point
  the Mac's camera at a physical iPhone showing the QR code to scan it into the emulator, or (b)
  rent a real device for an hour via Firebase Test Lab / BrowserStack for a final pre-Play-Store
  check rather than buying hardware. Decide when Phase 3 gets there.
- **Keystore backup.** Once generated (Phase 5), the Android signing keystore is as sensitive and
  as easy to lose as the iOS Distribution certificate - worth a deliberate decision on where it's
  backed up before it's needed for a real release, not after.

---

## Related docs
- `docs/technical/ANDROID_DEV_ENVIRONMENT_SETUP.md` - machine-local toolchain setup steps and
  known issues, needed again on any new machine
- `docs/project-management/Requirements/REQ-003_Mobile_Platform_Support.md` - originating
  requirement and acceptance criteria
