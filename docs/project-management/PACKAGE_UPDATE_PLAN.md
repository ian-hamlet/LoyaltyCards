# Package Update Plan

**Status:** Planning
**Branch:** `feature/packageUpdate`
**Date:** 2026-07-24
**Context:** v1.0.3+11 has been submitted for App Store review. This plan captures a dependency audit of `shared`, `customer_app`, and `supplier_app` done afterward, to evaluate package updates before the next release cycle.

## Scope

Audited via `flutter pub outdated` in each of the three packages (`source/shared`, `source/customer_app`, `source/supplier_app`), then cross-checked direct dependency version constraints between the two apps and their transitive resolution to find incompatibilities.

## Part 1: Packages with updates available

### `shared` (dev-only; all runtime deps current)

| Package | Current | Latest |
|---|---|---|
| build_runner | 2.15.1 | 2.15.2 |
| mockito | 5.6.4 | 5.7.0 |
| test | 1.31.0 | 1.31.2 |

### `customer_app`

| Package | Current | Latest | Type |
|---|---|---|---|
| device_info_plus | 13.1.0 | 13.2.0 | minor |
| google_fonts | 8.0.2 | 8.2.0 | minor |
| intl | 0.20.2 | 0.20.3 | patch |
| local_auth | 3.0.1 | 3.0.2 | patch |
| mobile_scanner | 7.2.0 | 7.4.0 | minor |
| path_provider | 2.1.5 | 2.1.6 | patch |
| sqflite | 2.4.2 | 2.4.3 | patch |
| uuid | 4.5.3 | 4.6.0 | minor |

### `supplier_app`

| Package | Current | Latest | Type |
|---|---|---|---|
| flutter_secure_storage | 10.0.0 | 10.3.1 | minor |
| google_fonts | 8.0.2 | 8.2.0 | minor |
| intl | 0.20.2 | 0.20.3 | patch |
| local_auth | 3.0.1 | 3.0.2 | patch |
| mobile_scanner | 7.2.0 | 7.4.0 | minor |
| path_provider | 2.1.5 | 2.1.6 | patch |
| pdf | 3.12.0 | 3.13.0 | minor |
| printing | 5.14.3 | 5.15.0 | minor |
| **share_plus** | **12.0.2** | **13.3.0** | **major** ⚠️ |
| sqflite | 2.4.2 | 2.4.3 | patch |
| uuid | 4.5.3 | 4.6.0 | minor |

All other entries in the raw `flutter pub outdated` output are transitive (pulled in automatically by the packages above) and aren't hand-edited directly.

## Part 2: Version incompatibilities

**No divergence between the two apps' own direct dependency constraints.** Every package both apps depend on directly (`mobile_scanner`, `sqflite`, `path_provider`, `uuid`, `intl`, `local_auth`, `google_fonts`, `shared_preferences`, `path`, `pointycastle`, `crypto`, `cupertino_icons`) is pinned to the same version range in both `pubspec.yaml` files, and both consume the same `shared` package via path dependency. The two apps are not drifting apart from each other.

Two real issues found:

1. **`share_plus` is major-version-capped in `supplier_app`.** Current constraint `^12.0.2` cannot reach 13.3.0 without editing `pubspec.yaml`. This is the one direct dependency with real breaking-change risk — share_plus has changed its `Share.share()` API surface across majors before. Needs its own focused review, not a blanket `flutter pub upgrade --major-versions`. share_plus is used in the supplier app's backup/clone-device flow.

2. **`win32` resolves to two different versions across the apps' dependency graphs** (transitive, not a direct dep): `customer_app` resolves it to 6.0.1→6.3.0; `supplier_app` is stuck at 5.15.0. Root cause: `supplier_app`'s `flutter_secure_storage` (10.0.0) pulls in `flutter_secure_storage_windows` 4.1.0, which caps `win32` at 5.x. Bumping `flutter_secure_storage` to 10.3.1 should pull `flutter_secure_storage_windows` 4.2.2, resolving `win32` up to 6.3.0. Only matters for a Windows build target; irrelevant to the iOS App Store release, but worth closing so the two apps' lockfiles don't silently diverge on a shared plugin family.

No other cross-package conflicts — nothing failing to resolve, no two direct deps demanding incompatible transitive versions.

## Part 3: Packages declared but no longer needed

Checked every direct dependency in both apps' `pubspec.yaml` against actual `import 'package:...'` usage in `lib/`. Found genuinely dead direct dependencies — declared, but nothing in the app imports them:

### `customer_app` — 5 unused direct dependencies

| Package | Declared as | Evidence |
|---|---|---|
| `path_provider` | `^2.1.0` | No import anywhere. `database_helper.dart` gets its DB directory from `sqflite`'s own `getDatabasesPath()`, not `path_provider`. |
| `intl` | `^0.20.2` | No import anywhere. No `DateFormat` or other intl usage in the app. |
| `pointycastle` | `^4.0.0` | No import anywhere. All crypto goes through `shared`'s `crypto_utils.dart`, which already depends on `pointycastle` itself — this is a redundant direct declaration of a transitive dependency. |
| `google_fonts` | `^8.0.2` | No import anywhere, no `fontFamily`/`GoogleFonts.*` usage in `main.dart` or theme setup. App uses the default Material font. |
| `cupertino_icons` | `^1.0.6` | No `CupertinoIcons.*` usage anywhere — confirmed the app uses Material `Icons.*` exclusively (66 usages). Standard leftover from the Flutter project template. |

### `supplier_app` — 2 unused direct dependencies

| Package | Declared as | Evidence |
|---|---|---|
| `google_fonts` | `^8.0.2` | No import anywhere, no `fontFamily`/`GoogleFonts.*` usage. |
| `cupertino_icons` | `^1.0.6` | No `CupertinoIcons.*` usage — app uses Material `Icons.*` exclusively (131 usages). |

(`path_provider`, `intl`, and `pointycastle` **are** genuinely used in `supplier_app` — confirmed real imports in `backup_storage_service.dart`, `recovery_backup_screen.dart`, `key_manager.dart`, `import_business_screen.dart`, `supplier_onboarding.dart` — so nothing to remove there beyond the two above.)

Removing these 7 declarations (5 + 2, `google_fonts`/`cupertino_icons` overlap both apps) is pure cleanup: smaller dependency tree, fewer transitive packages to track for updates/CVEs, faster `pub get`/build times. Zero functional risk since nothing references them.

## Part 4: Candidates for replacement with more standard packages

Reviewed each direct dependency against what's currently the de facto standard choice in the Flutter ecosystem for that job:

- `mobile_scanner`, `qr_flutter`, `local_auth`, `device_info_plus`, `flutter_secure_storage`, `share_plus`, `path_provider`, `shared_preferences`, `sqflite`, `crypto`, `uuid`, `intl`, `printing`/`pdf` — **all already are** the standard, actively-maintained choice for their purpose (several, like `mobile_scanner`, are themselves the modern replacement for now-unmaintained older packages like `qr_code_scanner`). No swap recommended for any of these.

- `pointycastle` (used for ECDSA P-256 signing in `shared/lib/utils/crypto_utils.dart`) is the one package worth flagging as a **longer-term watch item, not an action for this pass**. It's a solid, widely-used pure-Dart crypto library and is the correct choice for ECDSA P-256 specifically (Dart's newer `cryptography` package is more actively developed and offers platform-native backends for better performance, but its algorithm support leans toward Ed25519/X25519/AES rather than P-256 ECDSA — it may not be a drop-in replacement here). Given this is the app's actual security-critical signing path, already declared to Apple in the export-compliance rationale (ECDSA P-256 / SHA-256), and the app is mid-App-Store-review, this should stay untouched for now. Worth a dedicated, separately-tested spike in a future cycle if `pointycastle`'s maintenance activity ever drops off — not bundled into this update pass.

No other replacement candidates identified — the existing package choices are already aligned with ecosystem standards.

## Recommended plan

1. **Phase 0 — remove unused dependencies.** Delete the 5 unused declarations from `customer_app/pubspec.yaml` and 2 from `supplier_app/pubspec.yaml` (Part 3). Run `flutter pub get` in each, then `flutter analyze` to confirm nothing was silently relying on a transitive re-export. Zero functional risk; do this first since it shrinks what Phase 1 needs to touch.
2. **Phase 1 — low-risk patch/minor bumps.** Everything in the Part 1 tables above except `share_plus`. Run `flutter pub upgrade` in each of the three packages, then `flutter analyze` and `flutter test` in each. Low regression risk; safe to batch together.
3. **Phase 2 — `share_plus` major bump (supplier_app only).** Review the v12→v13 changelog/breaking changes first, update the call site(s) in the backup/clone-device flow if the API changed, bump the pubspec constraint, then manually re-test that flow on a physical device (matches the pattern already used for other supplier_app screenshots/testing this cycle).
4. **Phase 3 — `win32` cleanup.** Falls out automatically once `flutter_secure_storage` is bumped in Phase 1; no separate action expected, just confirm via `flutter pub deps` after Phase 1 that `win32` now resolves to 6.3.0 in `supplier_app` too.

## Verification checklist

- [ ] Unused dependencies removed from both `pubspec.yaml` files, `flutter analyze` clean immediately after (before any version bumps)
- [ ] `flutter analyze` clean in `shared`, `customer_app`, `supplier_app`
- [ ] `flutter test` green in all three
- [ ] Manual smoke test: customer scan/redeem flow, supplier issue/stamp flow (both Express and Secure mode)
- [ ] Supplier backup/clone-device flow re-tested on physical device after the `share_plus` bump specifically
- [ ] `flutter pub deps` confirms `win32` resolves consistently across both apps
- [ ] Version bump (4 files, per project convention) if this work ships as its own release rather than folding into the next feature release

## Out of scope for this pass

- No code changes have been made yet — this document is planning only.
- Not evaluating Flutter SDK version itself (a separate "new version of Flutter is available" notice appeared during this audit but wasn't investigated).
