# Android Port Plan

**Status:** Track 1 Phases 1-5 complete as of 2026-08-31 - both apps build/run/test cleanly on a
native arm64 emulator, the core loyalty-card flows (issue/stamp/redeem, both Express and Secure
Mode, biometric-gated backup/clone) are confirmed working, real app icons and display names now
ship on Android (previously the literal Flutter placeholder and raw package names), and two real
bugs were found and fixed along the way (one of which also affects the currently-live iOS app -
see Phase 3 below and `2.2.2+37`'s changelog entry). Phase 5 (release build) is now done too: a
real signing keystore exists, both apps' Gradle configs use it, and a verified-signed release AAB
has been built for each. Track 2 (Play Console) is well underway as of 2026-09-04: the developer
account is registered, both Play Console listings exist, Internal testing is configured for both
apps, and v2.2.4+40 is installed on two real Android devices (Samsung Galaxy A14/A12) - the first
real-hardware testing this project has had on Android, surfacing and fixing one more real bug
along the way (a duplicate action button, unrelated to the port itself - see Track 2 below and
`version.dart` Builds 39/40). The functional Express/Secure Mode test pass on real hardware is
still in progress; the full store listing (content rating, data safety submission) is not yet
entered into Play Console.
**Branch:** `feature/android-port`
**Date:** 2026-08-29 (created); last updated 2026-09-04
**Context:** Porting to Android is low-risk, mostly testing and store-listing work rather than a
rewrite - both apps already ship `android/` scaffolding, `Platform.isAndroid` branches already
exist in `device_service.dart`/`backup_storage_service.dart`, and the ECDSA P-256/SHA-256 signing
(`pointycastle`, pure Dart) has zero OS dependency, so a signature produced on Android verifies
identically on iOS and vice versa. Originating requirement: `Requirements/REQ-003_Mobile_Platform_Support.md`
(its Android acceptance criteria are still unchecked there - this plan is where they actually get
executed; check them off in both places as items land). Android hardware (two Samsung Galaxy
devices) was sourced 2026-09-04 to satisfy Play's device-verification requirement and for
real-device testing - see "Open Decisions / Risks" below, updated accordingly.

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
- [x] Follow-up found during later emulator testing (2026-08-31): the "Tell a Friend"/"Tell a
      Business" `AppBar` itself (not the headline text fixed above) wasn't setting
      `foregroundColor`, so Material 3 defaulted the title to a dark `onSurface` color regardless
      of the custom navy `backgroundColor` - every other `AppBar` in both apps sets
      `foregroundColor: Colors.white` explicitly, this shared `AppReferralScreen` was the one
      exception. Fixed in `source/shared/lib/widgets/app_referral_screen.dart`.

### Phase 5: Release Build
- [x] Generate an Android signing keystore - 2026-08-31. One shared keystore
      (`~/.android-signing/loyaltycards-release.jks`, outside the repo, `chmod 600`) with two
      RSA 2048 key aliases, `loyaltycards-supplier`/`loyaltycards-customer`, 10,000-day validity
      (until 2054-01-16) - mirrors the iOS side, where one Apple Distribution certificate covers
      both apps. Uses PKCS12 (`keytool`'s modern default), which requires the store password and
      every key's password to match - both aliases share one password rather than having distinct
      per-alias passwords, which isn't a PKCS12 option. Password shared with the developer to store
      in his own secure vault; not retained in this repo or session.
- [x] Configure Gradle signing config for both apps; keep the keystore itself out of git -
      2026-08-31. Each app's `android/key.properties` (already gitignored by the Flutter-generated
      `.gitignore`, confirmed via `git check-ignore`) points at the shared keystore file and its
      app-specific alias. `android/app/build.gradle.kts` in both apps now loads `key.properties` at
      config time and defines a real `release` `signingConfig`, falling back to debug signing only
      when `key.properties` is absent (e.g. a fresh checkout without the keystore) so `flutter run`
      and CI keep working without it.
- [x] Build a release AAB (`flutter build appbundle`) for both apps and verify it - 2026-08-31.
      `supplier_app` 71.1MB, `customer_app` 63.1MB. Verified both are actually signed with the new
      keystore (not the debug fallback) via `jarsigner -verify -verbose -certs`: both report "jar
      verified" (exit 0) and show the expected certificate
      (`CN=Ian Hamlet, OU=LoyaltyCards, O=dotConnected`, correct per-app alias, expiring
      2054-01-16).

---

## Track 2: Google Play Developer Account & Store Listing

- [x] Register a Google Play Developer account ($25 one-time fee) - **the developer's own action**
      (Google login + payment). Completed 2026-09-04: the device-verification blocker (see below)
      is resolved - the developer sourced and reset two real Android devices (Samsung Galaxy
      A14/A12), and registration completed.
- [x] Create Play Console listings for both apps - both created 2026-09-04
      (`com.ianhamlet.loyaltycards.customer` / `com.ianhamlet.loyaltycards.supplier`, same
      pattern as the two App Store Connect listings under one Apple Developer account)
- [x] Store listing content (text) drafted - 2026-08-31, see
      `docs/deployment/PLAY_STORE_METADATA_PACKET_v2_2_2_37.md`: app names, short/full
      descriptions, category, and app-access/review notes for both apps, adapted from
      `APP_STORE_METADATA_PACKET_v2_2_1_36.md` to Play's field set and refreshed to the current
      build (2.2.2+37).
- [x] Phone screenshots captured 2026-09-02 - 26 total (13 per app), real live captures covering
      both Express and Secure Mode end-to-end against the developer's iPhone, committed to the
      repo (`screenshots/customer_app/android/`, `screenshots/supplier_app/android/`) so they're
      available for tomorrow's registration. Feature graphic (1024x500) and the 512x512 app icon
      export drafted 2026-09-02 and approved by the developer the same day, in
      `store_graphics/customer_app/` and `store_graphics/supplier_app/` - see the metadata
      packet's "Graphic Assets" section. Ready to upload once the Play Console listings exist.
- [ ] Content rating questionnaire - expected answers drafted in the packet above (all "None" /
      Everyone-3+, mirroring the App Store's Age Rating), but it's a self-service in-console
      questionnaire, not something submittable in advance
- [ ] Data safety form (Play's equivalent of the App Store's privacy nutrition label) - drafted in
      the packet above, but flagged with one open judgment call (whether/how to disclose the
      Secure Mode anti-fraud device signal) that needs a deliberate decision before submitting,
      not just carrying the Privacy Policy's existing framing forward automatically
      - [x] Real bug found and fixed while digging into this, 2026-09-02: the Android anti-fraud
            device signal was a hash of `Build.ID` (an OS-build tag shared by every device on
            identical firmware, not per-device), silently breaking the V-005 mismatch check for
            Android devices sharing an OS image. Fixed with an app-generated random UUID
            persisted locally instead. Version bumped 2.2.2+37 → 2.2.3+38 - see `version.dart`
            Build 38.
      - [x] Data Safety disclosure decided 2026-09-02 against the fixed behavior above - see
            `PLAY_STORE_METADATA_PACKET_v2_2_2_37.md`. Not yet entered into Play Console (that
            happens once the store listing itself is filled in, not required for Internal
            testing).
- [x] Privacy Policy / Support / Terms URLs - already hosted on Cloudflare Pages from the iOS
      work, directly reusable (same URLs carried into the Play packet)
- [x] Configure an Internal testing track (Play's TestFlight equivalent) - done for both apps,
      2026-09-04
- [x] Upload a first internal test build for both apps - done 2026-09-04: v2.2.4+40 (customer_app's
      first successful Android release; supplier_app's first Android release of any kind).
      v2.2.4+39 was built and uploaded first but its version code got consumed by an abandoned
      draft release (Play permanently reserves a version code once uploaded to any track, even
      for a deleted draft) - +40 is a build-only bump carrying no code changes beyond +39, purely
      to get a fresh, usable version code. Both AABs confirmed release-signed via `jarsigner
      -verify` before upload. Installed and updating correctly on two real Android devices
      (Samsung Galaxy A14/A12) via the Play Store's tester opt-in flow - first real-hardware
      confirmation of the build/signing/upload pipeline end-to-end.
- [ ] Confirm the first internal test build - functional Express/Secure Mode test pass across the
      two real devices, in progress. Found and fixed one real bug already during this pass (see
      below), unrelated to the Android port itself.
- [x] Real bug found and fixed during this real-device pass, 2026-09-04: a Secure Mode card that's
      complete but not yet redeemed showed two buttons doing the exact same thing ("Scan
      Redemption" inline, "Scan Confirmation" floating) - not an Android-specific bug, just never
      visible on iOS/TestFlight screens captured previously. Removed the redundant floating button,
      keeping the inline one, which also matches the primary-action pattern used everywhere else in
      both apps. Version bumped 2.2.3+38 → 2.2.4+39 (then +40, see above) - see `version.dart`
      Builds 39/40.

---

## Open Decisions / Risks

- **No Android hardware owned.** Fully resolved 2026-09-04 - the developer sourced and reset two
  real Android devices (Samsung Galaxy A14/A12), both satisfying Play's device-verification
  requirement and now running v2.2.4+40 via Internal testing. Before this, functional testing
  relied on emulator webcam passthrough (Mac's built-in camera, configured 2026-08-30), which
  worked but was always going to need a real-device pass before submission given OEM variance -
  that pass is now underway on real hardware rather than rented (Firebase Test Lab/BrowserStack
  is no longer needed).
- **Keystore backup.** Generated 2026-08-31 (Phase 5) at `~/.android-signing/loyaltycards-release.jks`,
  machine-local only. As sensitive and as easy to lose as the iOS Distribution certificate - the
  keystore file itself still needs a real backup (Time Machine/iCloud Drive/etc. - not yet
  confirmed done), and the password was handed to the developer to store in his own secure vault
  rather than kept in this repo or session. Play App Signing (the modern default for new apps)
  softens the worst case - this local key becomes an "upload key," and Google can help recover a
  lost one with proof of ownership - but that's still a real hassle, not instant, so losing it
  isn't a non-event.

---

## Related docs
- `docs/technical/ANDROID_DEV_ENVIRONMENT_SETUP.md` - machine-local toolchain setup steps and
  known issues, needed again on any new machine
- `docs/project-management/Requirements/REQ-003_Mobile_Platform_Support.md` - originating
  requirement and acceptance criteria
- `docs/deployment/ANDROID_APP_SUBMISSION_CHECKLIST.md` - the copy-paste/tick-through Play
  Console checklist for Track 2, mirroring `APP_STORE_SUBMISSION_CHECKLIST.md` on the iOS side
