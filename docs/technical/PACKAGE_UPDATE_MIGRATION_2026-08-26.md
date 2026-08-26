# Package Update Migration — Pre-Android-Port

**Branch:** `feature/android-port`
**Date:** 2026-08-26
**Status:** Complete — verified, not yet committed

---

## Purpose

Before Android bring-up begins on this branch, this migration updates the direct
dependencies identified during a package appraisal as having significant available
updates. The goal is to land on current package baselines first, so Android bring-up
isn't also debugging deprecated APIs at the same time.

---

## Targeted Packages

### 1. `flutter_secure_storage` — 10.3.1 → 11.0.0 (supplier_app)

**Why update now:** This app has never actually run on Android yet. The current code
in [key_manager.dart](../../source/supplier_app/lib/services/key_manager.dart) pins
`AndroidOptions(encryptedSharedPreferences: true)` — an Android-specific option that
**11.0.0 removes entirely** ("Jetpack Security / EncryptedSharedPreferences backend is
no longer supported"). Staying on 10.x means building Android support on a backend that
is already obsolete upstream. Updating now, before Android code is written, means the
key-storage code is verified once against the current API rather than migrated later
after Android-specific code has been built around the old option.

**Breaking changes in 11.0.0 (Android):**
- Removed `KeyCipherAlgorithm.RSA_ECB_PKCS1Padding` / `StorageCipherAlgorithm.AES_CBC_PKCS7Padding`
- Removed `encryptedSharedPreferences` parameter (Jetpack Security backend dropped)
- Removed `sharedPreferencesName` in favor of `storageNamespace`
- Raised minimum SDK to API 24, compile target to 37
- Added `requireBiometricConfirmation` option to `AndroidOptions`

**Code change required:** Remove `encryptedSharedPreferences: true` from the
`AndroidOptions` constructor in `KeyManager`. The `read`/`write`/`delete` API surface
used elsewhere in the file is unchanged.

**Risk:** Medium — this is the private-key storage path (ECDSA P-256 keys). Verified by
running the full supplier_app test suite after the change, including
`test/services/key_manager_test.dart` if present.

### 2. `app_settings` — 6.1.1 → 9.0.0 (shared, used by customer_app & supplier_app)

**Why update now:** Only call site is `AppSettings.openAppSettings()` in
[scanner_permission_error_view.dart](../../source/shared/lib/widgets/scanner_permission_error_view.dart),
an API unchanged across this range. The Android-relevant changes between 6.x and 9.0.0
are all *compatibility fixes* (AGP 9 property-assignment syntax, Kotlin plugin
application fixes, Gradle/Kotlin upgrades) — i.e. things that will only help a fresh
Android Gradle build, not hurt it. The only breaking change (9.0.0) is iOS-only
(SwiftPM minimum raised to iOS 13.0).

**Risk:** Low — single call site, stable API. However, a deeper platform-tooling
change *was* missed in the initial appraisal — see [Post-Update Finding: Swift Package
Manager Required](#post-update-finding-swift-package-manager-required) below.

---

## Out of Scope

Transitive/dev-tooling packages with available updates (analyzer, build_runner,
sqlite3, vm_service, mockito, etc.) were reviewed but excluded from this migration —
no Android relevance and low value relative to risk of unrelated churn on this branch.
`mobile_scanner` and `qr_flutter` (the other Android-camera-sensitive plugins) were
already at their latest resolvable versions and required no change.

---

## Verification Plan

1. Update `pubspec.yaml` constraints for the two targeted packages.
2. Update `KeyManager` for the `flutter_secure_storage` 11.0.0 API.
3. `flutter pub get` in `shared`, `customer_app`, `supplier_app`.
4. `flutter analyze` in each package.
5. `flutter test` in each package.
6. Record results and final resolved versions below.

---

## Results

All three packages resolved and verified cleanly.

| Step | shared | customer_app | supplier_app |
|---|---|---|---|
| `flutter pub get` | ✅ resolved | ✅ resolved | ✅ resolved |
| `flutter analyze` | ✅ 0 errors (35 pre-existing infos, unrelated) | ✅ 0 errors (48 pre-existing infos/warnings, unrelated) | ✅ 0 errors (pre-existing infos/warnings, unrelated) |
| `flutter test` | ✅ 216/216 passed | ✅ 186/186 passed | ✅ 141/141 passed |

No new analyzer errors or warnings were introduced by either package bump. The one
analyzer note that *did* change is the `encryptedSharedPreferences` deprecation notice
on `key_manager.dart:25`, which existed before this migration (flutter_secure_storage
had already deprecated the parameter ahead of removing it in 11.0.0) and is now
resolved by removing the parameter.

`KeyManager`'s crypto flow (key retrieval, signing) was exercised directly by
`supplier_app`'s existing test suite (e.g. `supplier_stamp_card_test.dart`), which
passed against the new `flutter_secure_storage` 11.0.0 default `AndroidOptions()`
(RSA-OAEP key wrapping + AES-GCM storage — the new baseline security posture, replacing
the removed `encryptedSharedPreferences` flag).

### Code changes

- [source/shared/pubspec.yaml](../../source/shared/pubspec.yaml): `app_settings: ^6.1.1` → `^9.0.0`
- [source/supplier_app/pubspec.yaml](../../source/supplier_app/pubspec.yaml): `flutter_secure_storage: ^10.0.0` → `^11.0.0`
- [source/supplier_app/lib/services/key_manager.dart](../../source/supplier_app/lib/services/key_manager.dart): removed `AndroidOptions(encryptedSharedPreferences: true)` in favor of default `AndroidOptions()` (parameter no longer exists in 11.0.0)

Not committed — pending explicit instruction.

---

## Current Package Versions (post-migration)

Resolved versions per `pubspec.lock`, 2026-08-26:

| Package | shared | customer_app | supplier_app | Was (pre-migration) |
|---|---|---|---|---|
| `app_settings` | 9.0.0 (direct) | 9.0.0 (transitive, via `shared`) | 9.0.0 (transitive, via `shared`) | 6.1.1 |
| `flutter_secure_storage` | — | — | 11.0.0 (direct) | 10.3.1 |
| `flutter_secure_storage_darwin` | — | — | 0.4.0 | 0.3.2 |
| `flutter_secure_storage_linux` | — | — | 3.0.1 | 3.0.1 (unchanged in lock; 3.0.2 available) |
| `flutter_secure_storage_platform_interface` | — | — | 2.0.2 | 2.0.2 (unchanged in lock; 2.0.3 available) |

Everything else in each `pubspec.lock` is unchanged from before this migration — see
[docs/technical/DEPENDENCIES.md](DEPENDENCIES.md) for the full dependency inventory
(that document still reflects pre-migration versions for `flutter_secure_storage` and
`app_settings` and should be refreshed alongside/after the Android port work).

---

## Post-Update Finding: Swift Package Manager Required

**Discovered:** iOS build of `customer_app` failed after the `app_settings` bump with:

```
The following plugin(s) are only compatible with Swift Package Manager:
  - app_settings
Try enabling Swift Package Manager by running "flutter config --enable-swift-package-manager"
or remove the plugin as a dependency.
```

**Root cause:** `app_settings` dropped CocoaPods support at **8.0.0**, not 9.0.0 — the
original appraisal only checked the 9.0.0 breaking-change note (SwiftPM iOS minimum)
and missed that CocoaPods support was already gone by the time this update landed.
Swift Package Manager support was disabled machine-wide in this environment's Flutter
config (`enable-swift-package-manager: false` in `~/.flutter`), so the build failed
outright rather than silently falling back.

**Fix applied:**
1. `flutter config --enable-swift-package-manager` — a machine-wide Flutter CLI
   setting (not project-local), now `true`.
2. `flutter build ios --no-codesign --simulator` in both `customer_app` and
   `supplier_app`. Flutter detected that *every* iOS plugin in both projects already
   supports SPM and auto-migrated each project's CocoaPods integration accordingly.
   Both builds completed successfully:
   - `✓ Built build/ios/iphonesimulator/Runner.app` (customer_app)
   - `✓ Built build/ios/iphonesimulator/Runner.app` (supplier_app)

**Files changed by the auto-migration (per app):**
- `ios/Podfile.lock` — third-party pods removed (all now resolved via SPM instead); only the `Flutter` pod remains
- `ios/Runner.xcodeproj/project.pbxproj` — Swift Package references added
- `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` — updated for the package graph

**Scope note:** this is a machine-level Flutter config change, not a repo setting —
anyone else building this branch (or the Android-port session, if on a different
machine) will hit the same `app_settings`-requires-SPM error until they run
`flutter config --enable-swift-package-manager` locally too. Worth calling out during
handoff.

### Follow-up: full CocoaPods deintegration (iOS)

The hybrid CocoaPods+SPM state above left one piece of noise: Flutter reprinted the
"non-standard Podfile" advisory on every subsequent iOS build (`pod install` still ran
each time, even though it had nothing left to install), and recommended running
`pod deintegrate` for a faster build. This was completed for both apps:

1. `pod deintegrate` in each app's `ios/` directory — strips CocoaPods build phases
   and file references from `Runner.xcodeproj` directly (`Check Pods Manifest.lock`
   phases, `Pods_Runner.framework`/`Pods_RunnerTests.framework` references, the
   `Pods-*.xcconfig` references, and the now-empty `Frameworks` group).
2. Deleted `ios/Podfile` and `ios/Podfile.lock` in both apps — no longer needed since
   every plugin resolves via SPM.
3. Removed the now-dangling `#include? ".../Pods-Runner.debug/release.xcconfig"` line
   from each app's `ios/Flutter/Debug.xcconfig` and `Release.xcconfig` (these used the
   optional-include `?` form, so they weren't the cause of a build failure — just dead
   references worth cleaning up alongside the rest).
4. Rebuilt both apps (`flutter build ios --no-codesign --simulator`) to confirm: no
   CocoaPods advisory, no warnings, and both build noticeably faster than the hybrid
   state — customer_app 108.6s → 53.7s, supplier_app (comparable improvement, 58.0s).
5. Re-ran the full Dart test suites for both apps post-deintegration — still
   186/186 (customer_app) and 141/141 (supplier_app) passing.

The custom `post_install` block in each app's (now-deleted) `Podfile` — which
suppressed a `device_info_plus` compiler warning and forced a consistent
`IPHONEOS_DEPLOYMENT_TARGET` across pod targets — no longer applies to anything,
since there are no more CocoaPods pod targets in the project. If either issue
resurfaces under pure SPM (unlikely, since SPM packages carry their own deployment
target metadata), it would need a different fix — e.g. an Xcode build setting on the
`Runner` target directly, rather than a `post_install` hook.

Both apps' iOS projects are now on pure Swift Package Manager, no CocoaPods
remnants.

### Follow-up: full CocoaPods deintegration (macOS)

Both apps also have a `macos/` platform target with its own Podfile (the crypto
`key_manager.dart` MacOsOptions config confirms macOS is an actively built target, not
a scaffold-only folder). Since `app_settings` dropped CocoaPods for iOS *and* macOS at
the same version, `flutter build macos` hit the identical hybrid state iOS did:

1. `flutter build macos` for each app first (baseline) — Flutter added SPM integration
   automatically and printed the same "non-standard Podfile... run pod deintegrate"
   advisory seen on iOS. Both builds still succeeded.
2. `pod deintegrate` in each app's `macos/` directory — same cleanup as iOS (stripped
   CocoaPods build phases/references from `Runner.xcodeproj`, including an extra
   now-empty `Pods` group that iOS didn't have).
3. Deleted `macos/Podfile` and `macos/Podfile.lock` in both apps.
4. Removed the dangling `#include? ".../Pods-Runner.debug/release.xcconfig"` line from
   each app's `macos/Flutter/Flutter-Debug.xcconfig` and `Flutter-Release.xcconfig`.
5. Rebuilt both (`flutter build macos`) to confirm: no CocoaPods advisory, clean
   builds — `customer_app.app` (47.5MB) and `supplier_app.app` (53.4MB).

Both apps' macOS projects are now pure SPM as well, matching iOS. No CocoaPods
remnants anywhere in either app.

Two pre-existing, unrelated warnings appeared in the macOS build output on every run
(before and after the deintegration above, so not introduced by it). Both have now
been addressed:

- **`Error: unable to find directory entry in pubspec.yaml: .../assets/images/`** —
  both apps declared an `assets/images/` directory in `pubspec.yaml` that doesn't
  exist (neither app has an `assets/` folder at all), and no code references
  `assets/images` anywhere. Removed the dead `assets:` block from
  [customer_app/pubspec.yaml](../../source/customer_app/pubspec.yaml) and
  [supplier_app/pubspec.yaml](../../source/supplier_app/pubspec.yaml).

- **`Run script build phase 'Run Script' will be run during every build because it
  does not specify any outputs`** — this is Flutter's own generated `Flutter Assemble`
  build phase; a byte-for-byte diff against the Flutter SDK's own macOS project
  template confirmed it wasn't a project misconfiguration. Apple's own recommended fix
  for this warning is to mark the phase as always running rather than relying on
  (currently unreliable) dependency analysis. Added `alwaysOutOfDate = 1;` to the
  `ShellScript` phase in both apps' `macos/Runner.xcodeproj/project.pbxproj` — the
  same flag the *other* shell-script phase in the same project already uses for
  exactly this reason.

Rebuilt both apps after both fixes: clean output, only the `objective_c` warning below
remains.

**Not fixable here:** `warning: Code asset "package:objective_c/objective_c.dylib" has
different framework names for different architectures...` — `objective_c` isn't a
direct dependency of any of the three packages; it's pulled in transitively by
Flutter/Dart's own native-assets tooling (it shows up in all three `pubspec.lock`
files, including `shared`, which has no macOS-specific plugin). The warning text
itself says to report it to the package maintainers — there's no pubspec constraint in
this repo that controls it.
