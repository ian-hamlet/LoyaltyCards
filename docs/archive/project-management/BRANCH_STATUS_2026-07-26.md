# Branch Status — 2026-07-26

**Context:** v1.0.3+11 was submitted for App Store review. Since then, two branches of follow-up work have accumulated: a dependency/package-update pass (`feature/packageUpdate`) and a security review + fix pass (`feature/SecurityReview`, branched from `feature/packageUpdate`). This document is a snapshot of what's done and what's still open across both, so nothing gets lost between sessions.

**Update 2026-07-26:** A second, separate critical-appraisal pass was done on `feature/SecurityReview` — functional correctness / Flutter engineering quality / iOS platform integration, distinct from the security-focused 2026-07-25 review. 12 findings recorded in [`docs/quality/FUNCTIONAL_REVIEW_2026-07-26.md`](../quality/FUNCTIONAL_REVIEW_2026-07-26.md) (4 High severity, independently verified), **none fixed yet** — see that document's own "Recommended triage order." None of these were caught by the prior security review, since it was scoped differently (exploits, not general correctness) — noted there explicitly so future reviews account for both angles.

---

## `feature/SecurityReview` (current branch, HEAD `4c713c8`)

### Done
- All 7 main findings from the 2026-07-25 security review (V-010–V-016) resolved — see `docs/quality/VULNERABILITIES.md` for full detail. 6 fixed in code, 1 (V-015) resolved as an accepted by-design trade-off.
- 3 of 6 lower-priority "Additional Observations" fixed: `SupplierConfigBackup.fromQRString` try/catch, Keychain accessibility tightened, `SignatureFormat`/`StampSigner` dead-code cleanup (which turned out to be a bigger, more important cleanup than originally scoped — see VULNERABILITIES.md).
- Missing test coverage backlog fully closed: 58 new tests across `database_helper`, `stamp_repository`, `transaction_repository`, `qr_token_generator` (both apps), `supplier_database_helper`, `business_repository`, and `supplier_onboarding.dart` mode-selection widget tests.
- Bonus fix found along the way: `SupplierDatabaseHelper` had no test-isolation support, causing real cross-file test interference — fixed with the same `resetForTesting` mechanism `customer_app`'s `DatabaseHelper` already had.
- Final verification: `flutter analyze` clean, `flutter test` green across all three packages — shared 151, customer_app 120, supplier_app 58 (329 tests total, up from 179 at the start of the security review).

### Still open
- **3 lower-priority observations remain documented only, not fixed** (deliberately deferred, not overlooked):
  - Expiry windows checked against local device clock, not a trusted source (narrower residual gap after V-010/V-011 fixed the signed-timestamp side of this)
  - Device-mismatch "Proceed Anyway" still advisory-only (by design per V-005, now backstopped by V-012/V-013 so it's lower-consequence than before)
  - Release-build logs include stack traces in several `backup_storage_service.dart` paths (internal detail exposure, not a confirmed secret leak)
- **No physical-device regression pass yet.** This branch changed the actual signed-data format (V-010/V-011) and the redemption verification flow (V-012/V-013) — real behavioral change, not just refactoring. Should be tested (issue/stamp/redeem, both modes) on a physical device before merging, matching the pattern already used for `feature/packageUpdate`.
- **No version bump for this branch's changes.** Still sitting at 1.1.0+12 (the version `feature/packageUpdate`'s work landed on). The V-010–V-016 fixes are real behavior changes and likely warrant their own version bump before release.

## `feature/packageUpdate` (parent branch)

### Done
Dependency audit and update, fully executed and physical-device verified — see `docs/project-management/PACKAGE_UPDATE_PLAN.md`. Version 1.1.0+12.

### Still open
- **~180 mechanical lint issues** (unused imports, deprecated `withOpacity`, doc-comment formatting) — deferred, zero functional risk, batch cleanup whenever convenient.

## Structural / cross-cutting

- **Two feature branches not yet merged anywhere.** `main`/`develop` are still at the last equalized commit from the App Store submission work — unaware of either branch's changes.
- **App Store review status is independent of all of this.** v1.0.3+11 should still be under Apple's review; nothing in either branch touches that submission.
- **Merge strategy not yet decided.** Since `feature/SecurityReview` is branched from `feature/packageUpdate`, the natural path is one combined release (physical-device test → version bump → merge `feature/SecurityReview` → `develop`/`main` in one go), but this hasn't been confirmed.

---

**Next decision point:** physical-device regression test of `feature/SecurityReview`, then decide merge strategy and version number for the combined release.
