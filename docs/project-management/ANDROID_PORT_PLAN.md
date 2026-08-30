# Android Port Plan

**Status:** Track 1 Phases 1-4 (toolchain, build config, functional verification, platform
polish) complete as of 2026-08-30 - both apps build/run/test cleanly on a native arm64 emulator,
the core loyalty-card flows (issue/stamp/redeem, both Express and Secure Mode, biometric-gated
backup/clone) are confirmed working, real app icons and display names now ship on Android
(previously the literal Flutter placeholder and raw package names), and two real bugs were found
and fixed along the way (one of which also affects the currently-live iOS app - see Phase 3 below
and `2.2.2+37`'s changelog entry). Phase 5 (release build) is next. Track 2 (Play Console) not
started at all.
**Branch:** `feature/android-port`
**Date:** 2026-08-29 (created); last updated 2026-08-30
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
      end-to-end. `biometric_auth_service.dart` had zero test coverage before this - added
      `test/services/biometric_auth_service_test.dart` (14 tests) covering the full
      `LocalAuthExceptionCode` mapping, substituting `LocalAuthPlatform.instance` directly rather
      than mocking the MethodChannel (confirmed the channel-mock approach used elsewhere in this
      suite can't reach `LocalAuthException` at all under `flutter test` - it only ever throws
      `PlatformException` via the unregistered-platform fallback).
- [x] Recovery Backup file-output paths - share and print both bring up the correct native
      dialogs on the emulator - 2026-08-30. Low risk of surprising further on real hardware:
      unlike the biometric/enrollment issues found above, share/print dialogs are standard OS
      chrome (`share_plus`/`printing`), not something the app or emulator meaningfully diverges
      on. Full save-to-file/actual-print-output round trip still untested, but not considered a
      priority follow-up given this.
- [x] Secure storage round-trip (`flutter_secure_storage` → Android Keystore) - implicitly
      confirmed by the Secure Mode testing above: `key_manager.dart` writes/reads the ECDSA
      private key via `FlutterSecureStorage` for every signing operation, so issue/stamp/redeem
      all working in Secure Mode already proves the round-trip works. Not a separate untested
      item.
- [x] QR camera scan via the emulator's own camera (webcam passthrough) - 2026-08-30, confirmed:
      the Secure Mode issue/stamp/redemption testing required the supplier app to actually scan
      codes on the emulator (not just generate them), using the Mac's built-in camera passthrough
      configured earlier.
- [x] Full automated suite still green in this context (`shared` 216, `customer_app` 186,
      `supplier_app` 141) - reconfirmed repeatedly today, including after the toolchain rebuild
      and after both biometric-auth fixes - 2026-08-30

### Phase 4: Platform Polish
- [x] "Tell a Friend"/"Tell a Business" screen headline color - fixed 2026-08-30
      (`app_referral_screen.dart:93`). Ruled out the dark/light-mode theory first: checked the
      emulator's actual system setting (`adb shell cmd uimode night` → "no", i.e. light mode,
      same as the test iPhone), so it wasn't a theme mismatch. Root cause not fully pinned down,
      but the code smell was real regardless - every other `Text` in this file sets an explicit
      color, this headline was the one outlier left to inherit an ambient default. Gave it an
      explicit `Colors.black87` to match its siblings, removing the platform-dependent ambiguity
      either way.
- [x] Adaptive app icon for both apps - fixed 2026-08-30. Both apps' Android `mipmap-*/ic_launcher.png`
      were still Flutter's literal default placeholder logo (never generated for Android at all,
      not just missing the adaptive variant - confirmed by viewing the actual PNG). Added
      `flutter_launcher_icons` (dev dependency + config in each `pubspec.yaml`), generating both
      the legacy icon set and a proper Android 8+ adaptive icon (`mipmap-anydpi-v26`, 16% inset
      auto-applied for the safe zone) from the same branded 1024px source already used for
      iOS/macOS. Rebuilt both APKs and confirmed visually in the emulator's actual app drawer -
      both icons render correctly, cleanly circle-masked, no clipping.
- [x] `AndroidManifest.xml` permissions review (camera, biometric, storage) for both apps -
      2026-08-30, confirmed correct with no changes needed: checked the actual final *merged*
      manifest from a release build output (not just the source manifest, since Flutter plugins
      inject their own permissions via manifest merging) - `local_auth` and `mobile_scanner`
      already correctly contribute `USE_BIOMETRIC`/`USE_FINGERPRINT`/`CAMERA` automatically. No
      storage permission present or needed (scoped, app-private storage only). Found and fixed a
      related real gap along the way: both apps' `android:label` were still the raw `flutter
      create` defaults (`supplier_app`/`customer_app`) instead of proper display names - now
      `LoyaltyCards Business`/`LoyaltyCards`, matching each app's iOS `CFBundleDisplayName`
      exactly. Confirmed via the emulator's app drawer that these were showing as truncated raw
      package names before the fix.
- [x] Material Design pass - confirmed 2026-08-30: zero Cupertino widget usage anywhere in
      `lib/` across all three packages (grepped for it), and both apps' theming is pure Material
      3 (`ColorScheme.fromSeed`, light + dark). Matches everything observed live on the emulator
      throughout today's testing - nothing read as iOS-styled.
- [x] Decide and set minimum supported Android OS version (`minSdk`) - 2026-08-30, confirmed
      already correct with no change needed: both apps use Flutter's own default
      (`flutter.minSdkVersion`, not a custom override), which resolves to API 24 (Android 7.0,
      released 2016 - confirmed via `aapt2 dump badging` on the actual built APK). Appropriately
      conservative for 2026; raising it would only exclude users for no benefit, and lowering it
      isn't possible below Flutter's own engine floor.

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

- **No Android hardware owned.** Resolved for functional testing purposes: emulator webcam
  passthrough (Mac's built-in camera, configured 2026-08-30) let the emulator genuinely scan real
  codes, confirmed via full Secure Mode issue/stamp/redeem testing. Still worth a final real-device
  pass (rented via Firebase Test Lab / BrowserStack) before Play Store submission, since an
  emulator - even with a working camera - isn't a full substitute for real hardware/OEM variance,
  but this is no longer a functional blocker for continued development.
- **Keystore backup.** Once generated (Phase 5), the Android signing keystore is as sensitive and
  as easy to lose as the iOS Distribution certificate - worth a deliberate decision on where it's
  backed up before it's needed for a real release, not after.

---

## Related docs
- `docs/technical/ANDROID_DEV_ENVIRONMENT_SETUP.md` - machine-local toolchain setup steps and
  known issues, needed again on any new machine
- `docs/project-management/Requirements/REQ-003_Mobile_Platform_Support.md` - originating
  requirement and acceptance criteria
