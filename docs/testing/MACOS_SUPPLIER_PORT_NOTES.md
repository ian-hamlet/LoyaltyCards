# macOS Native Build - Testing Notes

**Status: development/testing tool only.** Neither app is signed for distribution, and there's no decision yet on a Mac App Store listing. This exists so the supplier app can be tested on a shop's till-style Mac, and so both apps can be run side-by-side on one machine to exercise the full P2P flow without needing two physical devices. See `docs/project-management/DEFECT_TRACKER.md` DECISION-022 for the full defect/fix history behind this.

## Running the apps

From the repo root:

```bash
./source/run_supplier_app_macos.sh
./source/run_customer_app_macos.sh
```

Each just wraps `flutter run -d macos` in the relevant app directory. Run both at once to test the full flow on one machine - each app uses its own local SQLite database, so there's no conflict running side-by-side.

**Testing a QR scan between two windows on one Mac:** a Mac only has one camera, so you can't literally point one app's camera at the other app's QR code the way you would with two phones. Options that work:
- Screenshot the QR code from one app's window, then use the other app's "scan from Photos"/gallery option if it has one.
- Print or AirDrop the QR to a second device and scan from there.
- Use a second Mac or an iPhone/iPad as the second device.

## Known caveats (not blockers, but expect these)

- **The camera preview may appear sideways or upside-down the first time you run on a new Mac.** The manual rotation offset defaults to a value calibrated for iPhone/iPad. Use the existing on-screen rotation buttons (90°/180°) to correct it once - the app remembers your choice per-device after that.
- **QR scan reliability for larger payloads (e.g. a redemption QR bundling several stamp signatures) was inconsistent on one specific low-resolution (720p) test webcam.** Single-stamp scans were reliable on that same hardware. If you hit scan failures specifically on redemption/large QR codes, try a Mac with a higher-resolution camera (or an iPhone as a Continuity Camera) before assuming it's a code bug.
- **Camera facing is requested as "back" (`CameraFacing.back`)** in the two supplier-app camera screens, since that's correct for iPhone/iPad. A Mac's built-in camera is front-only. This hasn't caused a failure in testing so far - the camera plugin appears to fall back gracefully - but it also hasn't been formally verified against the plugin's documented macOS behavior. If a future mobile_scanner update changes this, camera-dependent screens on macOS specifically would be the place to check first.

## What's already fixed

- `flutter_secure_storage`'s default macOS keychain API needs an entitlement unavailable without a real Developer Team - worked around via `MacOsOptions(usesDataProtectionKeychain: false)` in `key_manager.dart` (macOS-only; doesn't touch iOS/Android behavior).
- Camera access requires `com.apple.security.device.camera` in both entitlements files plus `NSCameraUsageDescription` in `Info.plist` - both apps have this now.
- A CocoaPods build warning about the `app_settings` pod's deployment target is silenced via a `post_install` hook in both apps' `macos/Podfile`.
- **The repeated Mac password prompt when Secure Mode signs something is fixed.** Both apps' macOS `Runner` targets now carry the same `DEVELOPMENT_TEAM` (and an explicit `CODE_SIGN_IDENTITY = "Apple Development"`) already used for the iOS builds, so `flutter build`/`flutter run -d macos` sign with a real, stable identity instead of falling back to ad-hoc "Sign to Run Locally." Verified with `codesign -dvv` on a clean build of both apps. You'll still see the password prompt (and an "Always Allow" choice) the *first* time after this change, or after a "Delete All Data" that recreates the keys - that's normal Keychain behavior, not a regression. If it starts happening on every run again, check `codesign -dvv path/to/the.app` for `flags=0x2(adhoc)` - that means the signing identity fell back to ad-hoc again (e.g. if the certificate expires or is removed from the keychain).
