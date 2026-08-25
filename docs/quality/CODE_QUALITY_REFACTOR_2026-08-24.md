# Code Quality Refactor — Execution & Follow-Up Review

**Branch:** `feature/code-quality-refactor`
**Executes:** [CODE_QUALITY_REVIEW_2026-08-21.md](CODE_QUALITY_REVIEW_2026-08-21.md) (steps 2–4; step 1, a CI gate, deliberately deferred per user instruction — see that review and `docs/project-management/PROJECT_HISTORY.md`)
**Date:** 2026-08-24
**Scope:** read/write — real code changes, not a read-only assessment like the review it executes

---

## Part 1 — The extraction (Track A)

Extracted business/crypto logic out of the five oversized files the original review flagged, into a new `lib/controllers/` convention (plain Dart classes, no UI imports, Result objects instead of thrown exceptions, testable without a widget tree). Full design rationale lives in the controller files' own header comments (see `customer_card_detail_controller.dart`, the template the rest follow).

| File | Before | After | Notes |
|---|---|---|---|
| `customer_app/.../customer_card_detail.dart` | 1,178 ln, 0 tests | 999 ln + `CustomerCardDetailController` | 14 characterization tests written and verified green against the *unmodified* file before extracting (zero prior coverage) |
| `customer_app/.../qr_scanner_screen.dart` | 1,347 ln, 6 tests | 365 ln + `QrScannerController` | Existing 6 tests migrated off the `handleQRCodeForTesting` widget hook to call the controller directly; hook deleted |
| `supplier_app/.../supplier_stamp_card.dart` | 1,408 ln | + `SupplierStampCardController` | Mirrors the generation-side shape of `QrScannerController` |
| `supplier_app/.../supplier_redeem_card.dart` | 1,013 ln | + `SupplierRedeemCardController` | Mirrors the verification-side shape of `QrScannerController.handleRedemptionToken` |
| `supplier_app/.../backup_storage_service.dart` | 1,205 ln, not UI-fused | ~20-line facade + `services/backup/{config,simple_token,issue_card}_backup_service.dart`, `pdf_validation.dart` | Pure service split; existing 20-test suite needed zero edits |

**Signed-data safety:** `getSignatureData()` (3 implementations in `shared/lib/models/qr_tokens.dart`) and `shared/lib/utils/signature_format.dart` verified byte-identical (zero diff) at the end of the extraction — every controller calls into these unchanged rather than reimplementing signing/verification.

**Test delta:** customer_app 138→186 (+48), supplier_app 104→137 (+33, before the follow-up pass below added 4 more). shared unchanged, 216/216.

**Step 4 of the original review (bound-check consolidation) — investigated, no action taken.** The review suspected `stampsRequired`-bound-check drift similar to the pre-DECISION-017 TEST-016/017/019/020 saga. On inspection, `BusinessRepository`/`CardRepository`'s sanity checks (`AppConstants.stampsRequiredHardCeiling`, 100) and `CardIssueToken.isStampsRequiredSupported()` (3–12) are two deliberately different, already-correctly-separated bounds — a loose storage-layer sanity ceiling vs. the narrow issuance-gating range, both already routed through shared constants at every call site. Nothing to consolidate; "fixing" this would have broken legacy-business support (DECISION-017's out-of-range recovery scenario).

---

## Part 2 — Follow-up code-quality review & fix pass

Two `code-review --high` passes were run against the resulting diff (the second, empty-fix-loop pattern the user asked for: fix → test → re-review → repeat until clean).

### Pass 1 — findings and fixes

| # | Finding | File(s) | Fix |
|---|---|---|---|
| 1 | `recordManualRedemption()` threw an unhandled `StateError` if called before `loadBusiness()` — reachable via the `processManualRedemptionForTesting()` test hook, bypassing the UI's normal guard. The pre-extraction code degraded gracefully here (try/catch wrapped the equivalent null-dereference). | `supplier_redeem_card_controller.dart` | Returns `ManualRedemptionResult.failure(...)` instead of throwing. Test updated to assert graceful failure, not a thrown exception. |
| 2 | Disk-space error detection existed on `saveToFiles`/`saveSimpleTokenToFiles` (partially) but not on any of the three backup services' print paths. | `config_backup_service.dart`, `simple_token_backup_service.dart`, `issue_card_backup_service.dart` | Added to all print paths and to `saveSimpleTokenToFiles` (the one save path missing it). |
| 3 | Filename-generation logic (date formatting + business-name sanitization) duplicated near-verbatim across the three new backup services. | Same three files | Extracted to new `services/backup/backup_filename.dart` (`BackupFilename.dateStamp`/`sanitizeBusinessName`). |
| 4 | `SupplierRedeemCardController.loadBusiness()`'s failure returned a `null` error message; `SupplierStampCardController`'s equivalent returned a descriptive string. | `supplier_redeem_card_controller.dart` | Now returns `'Error loading business: $e'`, matching the sibling controller. |
| 5 | 10 near-identical Result-wrapper classes across both apps' `controller_results.dart`, hand-copying the same `isSuccess`/`failureReason`/`message` shape. | Both apps' `controller_results.dart` | Consolidated 9 of 10 behind shared base classes: `SupplierResult` (supplier_app, all 7 classes) and `ControllerResult` (customer_app, 2 of 3 — `CardDetailLoadResult`, `RedemptionResult`). `ScanResult` deliberately left standalone (see below). |
| 6 | `SupplierScanFailureReason.cardNotFound` declared but never constructed anywhere. | `controller_results.dart` (supplier_app) | Removed. |

### Pass 2 — findings and fixes (5-angle review of Pass 1's diff)

| # | Finding | Fix |
|---|---|---|
| 7 | `audit_trail_pdf_service.dart` had its own inline copies of the PDF-validation and filename-sanitization logic just extracted in finding 3/backup split — a fourth near-duplicate the original split missed. | Now uses `PdfValidation`/`BackupFilename` directly; its own `_isValidPdfBytes`/`_generateValidatedPdfBytes` deleted. |
| 8 | The new disk-space check (finding 2) used a bare `errorString.contains('space')`, which would misclassify any error mentioning "namespace"/"workspace"/"whitespace" as disk-full. | Extracted `BackupErrorClassification.isDiskFullError()` with specific phrases (`'disk full'`, `'no space left'`, `'not enough space'`, `'insufficient space'`, `'insufficient storage'`). New test file `test/services/backup/backup_error_classification_test.dart` (4 tests) pins both the true-positive phrases and the false-positive cases the old check would have hit. |
| 9 | The `'cancel'` check ran before the disk-full check in all three print paths — a hypothetical message containing both words would be misclassified as a cancellation. | Reordered: disk-full check now runs first everywhere. |

**Pass 3** (re-review after fixes 7–9): zero findings. Clean.

---

## Deliberately not fixed — scope decisions, not oversights

- **`BackupResult`** (`supplier_app/lib/models/backup_result.dart`) and **`VerificationResult`** (`shared/lib/models/verification_result.dart`) are structurally near-identical to the new `SupplierResult`/`ControllerResult` bases but were **not** migrated. Both predate this refactor; `BackupResult` alone has a large existing call surface (every backup/audit-trail method). Folding them in is a legitimate future cleanup, not part of this pass's actual mandate.
- **`ScanResult`** (customer_app) stayed standalone rather than joining `ControllerResult` — it names its message field `message` (set on success too) rather than `errorMessage`, and unifying that naming would mean touching ~24 call sites across `qr_scanner_controller.dart`/`qr_scanner_screen.dart`/their tests for no behavioral benefit.
- **No `source/shared/` base** unifying `ControllerResult` (customer_app) and `SupplierResult` (supplier_app) — the two classes are structurally identical but each app package got its own copy. Real but modest duplication (~10 lines); judged not worth the cross-package churn tonight.
- **Pre-existing deprecated API usage**, untouched: `Share`/`Share.shareXFiles` (→ `SharePlus.instance.share()`), `QrPainter`'s `color` param (→ `eyeStyle`/`dataModuleStyle`), `pw.Table.fromTextArray` (→ `TableHelper.fromTextArray`). Outside this refactor's footprint; see "Open items" below.
- **CI gate** (original review's step 1) and **broader lint adoption** (step 5, beyond the one rule — `prefer_const_constructors` — added here) — both explicitly deferred per user instruction at the start of this work, not part of this pass.

---

## Final verification

- `flutter analyze`: 0 errors, all three packages.
- `flutter test` (via `source/test_all_packages.sh`): shared 216/216, customer_app 186/186, supplier_app 141/141 (543 total, up from 458 before this branch).
- Signed-data files (`qr_tokens.dart`, `signature_format.dart`, `crypto_utils.dart`, and the QR codec utils) verified byte-identical to `develop` throughout.

## Open items for a future pass

1. Migrate `Share`/`Share.shareXFiles` → `SharePlus.instance.share()` across both apps (real behavioral risk if rushed — see the risk discussion this doc's commit message/PR description should link back to).
2. Migrate `QrPainter`'s deprecated `color` param.
3. Migrate `pw.Table.fromTextArray` → `TableHelper.fromTextArray` (single call site, `audit_trail_pdf_service.dart`).
4. Consider folding `BackupResult`/`VerificationResult` into the `SupplierResult`/`ControllerResult` pattern, and/or a `source/shared/` base, if the duplication becomes a real maintenance cost.
5. The CI gate and broader lint adoption from the original review, whenever that's revisited.
