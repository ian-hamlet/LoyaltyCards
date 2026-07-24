# Package Update Plan

**Status:** In progress — Phases 0-3 complete (code-side); physical-device re-test of supplier backup/clone flow still outstanding
**Branch:** `feature/packageUpdate`
**Date:** 2026-07-24
**Version:** Not yet assigned. This work has not been bumped to a new version number — a version bump (4 files, per project convention) will be decided once we know whether this ships as its own release or folds into the next feature release (see Recommended plan / Verification checklist).
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

2. **`win32` resolves to two different versions across the apps' dependency graphs** (transitive, not a direct dep): `customer_app` resolves it to 6.0.1→6.3.0; `supplier_app` is stuck at 5.15.0. Root cause: `supplier_app`'s `flutter_secure_storage` (was 10.0.0) pulls in `flutter_secure_storage_windows` 4.1.0, which caps `win32` at 5.x.
   **Update after Phase 1:** bumping `flutter_secure_storage` to 10.3.1 did *not* resolve this as expected. `flutter pub outdated` still shows `flutter_secure_storage_windows`/`win32` as "Resolvable" to 4.2.2/6.3.0 but not "Upgradable" — something else in the graph (likely `share_plus` 12.x, still pinned pending Phase 2) is holding pub's solver back from taking it via a plain `flutter pub upgrade`. Would need `flutter pub upgrade --major-versions` or a `dependency_overrides` entry to force it. Only matters for a Windows desktop build target, irrelevant to the iOS App Store release — deferred rather than forced. See Phase 3 below.

No other cross-package conflicts — nothing failing to resolve, no two direct deps demanding incompatible transitive versions.

## Part 3: Packages declared but no longer needed

Checked every direct dependency in both apps' `pubspec.yaml` against actual `import 'package:...'` usage in `lib/`. Found genuinely dead direct dependencies — declared, but nothing in the app imports them:

### `customer_app` — 5 unused direct dependencies (removed in Phase 0)

| Package | Declared as | Evidence |
|---|---|---|
| `path_provider` | `^2.1.0` | No import anywhere. `database_helper.dart` gets its DB directory from `sqflite`'s own `getDatabasesPath()`, not `path_provider`. |
| `intl` | `^0.20.2` | No import anywhere. No `DateFormat` or other intl usage in the app. |
| `pointycastle` | `^4.0.0` | No import anywhere. All crypto goes through `shared`'s `crypto_utils.dart`, which already depends on `pointycastle` itself — this is a redundant direct declaration of a transitive dependency. |
| `google_fonts` | `^8.0.2` | No import anywhere, no `fontFamily`/`GoogleFonts.*` usage in `main.dart` or theme setup. App uses the default Material font. |
| `cupertino_icons` | `^1.0.6` | No `CupertinoIcons.*` usage anywhere — confirmed the app uses Material `Icons.*` exclusively (66 usages). Standard leftover from the Flutter project template. |

### `supplier_app` — 2 unused direct dependencies (removed in Phase 0)

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

## Part 5: Lint findings and test coverage (post-Phase 1 review)

After Phase 1, `flutter analyze` was run across all three packages and categorized (179 total issues: 35 shared, 44 customer_app, 100 supplier_app). Most were mechanical/cosmetic (unused imports, `withOpacity`→`withValues`, doc-comment formatting, `use_super_parameters`) and are **deferred** — see below. A few were real, and have been fixed:

### Fixed now

- **`stamp_signer_test.dart` had a broken `setUp()`.** Written as a bare `setUp() { ... }` function declaration instead of `setUp(() { ... });` — never actually registered with the `test` package, so `stampSigner`/`keyManager` were never reset between tests. One-line fix (`supplier_app/test/services/stamp_signer_test.dart`).
- **Two `dead_code`/`dead_null_aware_expression` findings in `shared/lib/models/supplier_config_backup.dart:52,90`** (`business.privateKey ?? ''`) — confirmed `Business.privateKey` is a non-nullable `String`, so the fallback was genuinely unreachable. Removed.
- **Two `unreachable_switch_default` findings** (`shared/lib/exceptions/backup_exception.dart`, `supplier_app/lib/models/backup_result.dart`) — both enum switches already had an explicit `case ... unknown:` covering every value; the trailing `default:` was dead. Removed.
- **New direct test for `shared/lib/utils/crypto_utils.dart`** (`shared/test/utils/crypto_utils_test.dart`, 9 tests) — this is the actual ECDSA P-256/SHA-256 signature verification declared to Apple in the export-compliance packet, and it previously had no dedicated coverage (only indirect, and buggy, coverage via the `stamp_signer_test.dart` issue above). New tests generate real key pairs and signatures via `pointycastle` (mirroring `KeyManager`'s exact wire encoding) and cover: valid signature accepted, tampered data rejected, wrong public key rejected, empty/truncated/corrupted signature rejected without throwing, malformed public key rejected without throwing, determinism.
- **12 genuinely unguarded `use_build_context_synchronously` sites in `supplier_app/lib/screens/supplier/recovery_backup_screen.dart`** (`_generateBackup`, `_printBackup`, `_shareViaEmail`, `_saveToFiles`) — unlike every other flagged site in the app (which already had a `mounted` check, just not in the exact idiom the linter fully trusts), these four methods called `setState`/`AppFeedback.error`/`AppFeedback.success` after an `await` with **no** `mounted` check at all. This is the backup/recovery QR screen — if the user navigated away mid-generation or mid-export, this could throw a "setState() called after dispose()" or use-after-unmount error. Added `if (!mounted) return;` guards after each await, in both the success and catch paths.
- **1 more genuine gap in `supplier_app/lib/screens/supplier/supplier_redeem_card.dart:735`** — used `context` after an awaited `showDialog` with no guard. Fixed the same way.

Verified after each fix: `flutter analyze` — no errors in any package (shared: 35→30 issues, supplier_app: 100→88 issues, customer_app unchanged at 44 — all remaining issues are the deferred cosmetic category below); `flutter test` — all green (shared 140 including the 9 new crypto tests, customer_app 87, supplier_app 46).

### Deferred — revisit after first pass at package updates (Phases 2-3)

- **Remaining `use_build_context_synchronously` info-level findings** (4 in supplier_app, 6 in customer_app) — every remaining site was checked individually and already has a `mounted`/`if (mounted)` guard; the linter's stricter idiom preference (wanting `context.mounted` or a specific guard-clause shape) isn't flagging a live risk. Low priority.
- **Bulk cosmetic lint cleanup** — unused imports/fields/variables, `deprecated_member_use` (`withOpacity`→`withValues()`, plus the `Share`/`shareXFiles`→`SharePlus` ones that overlap with Phase 2's share_plus migration), `use_super_parameters`, doc-comment formatting, unnecessary string-interpolation braces, `prefer_final_fields`, empty statements, non-null assertions, `asset_directory_does_not_exist`. Zero functional risk, good for a single batch pass later.
- **New test coverage for**: `shared` has no other gaps as critical as `crypto_utils.dart` was. `customer_app`: `database_helper.dart` (path/migration/backup/restore), `stamp_repository.dart`, `transaction_repository.dart`, `qr_token_generator.dart` (would be a good place to pin the 2-minute/5-minute expiry constants that have caused doc-drift all session). `supplier_app`: `supplier_database_helper.dart`, `business_repository.dart`, `qr_token_generator.dart`, and the brand-new `supplier_onboarding.dart` mode-selection UI (v1.0.3+11) which currently has zero coverage of any kind.

## Recommended plan

1. ✅ **Phase 0 — remove unused dependencies.** Deleted the 5 unused declarations from `customer_app/pubspec.yaml` and 2 from `supplier_app/pubspec.yaml` (Part 3). `flutter pub get` clean in both, `flutter analyze` produced no errors (pre-existing lint warnings only, unrelated to this change), `flutter test` passed in both (customer_app: 87 tests, supplier_app: 46 tests). Not yet committed.
2. ✅ **Phase 1 — low-risk patch/minor bumps.** Ran `flutter pub upgrade` in `shared` (1 dependency changed — most dev deps were already at their max resolvable version, matching the earlier audit), `customer_app` (35 dependencies changed, including `sqflite` 2.4.2→2.4.3 and `uuid` 4.5.3→4.6.0 as planned), and `supplier_app` (47 dependencies changed, including `flutter_secure_storage` 10.0.0→10.3.1, `pdf`, `printing`, `sqflite`, `uuid`; `share_plus` correctly stayed pinned at 12.0.2). `flutter analyze`: no errors in any of the three (pre-existing lint warnings only — 35/44/100 issues respectively, unchanged from baseline). `flutter test`: all green — `shared` 131, `customer_app` 87, `supplier_app` 46. Not yet committed. Surfaced one correction to Part 2's `win32` note — see above.
3. ✅ **Phase 2 — `share_plus` major bump (supplier_app only).** Fetched the actual pub.dev changelog for every version between 12.0.2 and 13.3.0: the only breaking change across all of them is raised minimum SDK/platform requirements (Flutter ≥3.41.6, Dart ≥3.11.0, iOS ≥13.0, macOS ≥10.15) introduced in 13.0.0 — no changes to the `Share`/`shareXFiles`/`SharePlus`/`sharePositionOrigin` API surface at all, and 13.3.0 specifically improves iPad `sharePositionOrigin` handling (exactly what `backup_storage_service.dart` uses). Confirmed the project already meets every minimum (Flutter 3.44.1, Dart 3.12.1, iOS deployment target already 13.0, macOS already 10.15) — so this was a pure version-constraint bump with zero required code changes. Bumped `share_plus: ^12.0.2` → `^13.3.0`, `flutter pub get` resolved cleanly (5 dependencies changed), `flutter analyze` no errors (same pre-existing `Share`/`shareXFiles`→`SharePlus` deprecation info-warnings as before the bump — those were already deprecated in 12.x and still function; migrating off them is optional cleanup, folded into the deferred bulk lint cleanup above, not required), `flutter test` all 46 green. Not yet committed. **Manual re-test of the backup/clone-device flow on a physical device is still needed from you** — I can't drive that interaction myself.
4. ✅ **Phase 3 — `win32` cleanup.** Confirmed: bumping `share_plus` past 12.x freed the solver, and `win32`/`flutter_secure_storage_windows` resolved themselves automatically during the Phase 2 `pub get` — no separate `--major-versions`/`dependency_overrides` action needed after all. Verified both apps' `pubspec.lock` now pin the identical `win32` version (matching sha256).

## Verification checklist

- [x] Unused dependencies removed from both `pubspec.yaml` files, `flutter analyze` clean immediately after (before any version bumps)
- [x] `flutter analyze` clean (no errors) in `shared`, `customer_app`, `supplier_app` — re-confirmed after Phase 1 and Phase 2
- [x] `flutter test` green in `shared` (140), `customer_app` (87), `supplier_app` (46) — re-confirmed after Phase 2
- [ ] Manual smoke test: customer scan/redeem flow, supplier issue/stamp flow (both Express and Secure mode)
- [ ] Supplier backup/clone-device flow re-tested on physical device after the `share_plus` bump specifically — **outstanding, needs you**
- [x] `flutter pub deps`/`pubspec.lock` confirms `win32` resolves consistently across both apps — resolved itself in Phase 2
- [ ] Version number decided and bumped (4 files, per project convention) once scope of this release is finalized — see Version note at top

## Out of scope for this pass

- Not evaluating Flutter SDK version itself (a separate "new version of Flutter is available" notice appeared during this audit but wasn't investigated).
