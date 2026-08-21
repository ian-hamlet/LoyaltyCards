# Engineering Assessment — For Planning

**LoyaltyCards: develop-branch code quality assessment**

A maintainability review of the Flutter monorepo (customer_app / supplier_app / shared), commissioned ahead of the next refactor planning session.

- **Branch:** develop
- **Commit:** `b0f6476`
- **Reviewed:** 2026-08-21
- **Scope:** read-only, no changes made

**Source:** consolidated from `docs/review/code-quality-review.txt`, 2026-08-21.

## At a glance

| Metric | Value |
|---|---|
| Non-test Dart files | 76 |
| Lines of app code | 21.4K |
| Lines of tests (~47%) | 10.1K |
| Lines of markdown docs | 37K |
| Unique defect/decision IDs cited in code | 142 |
| Largest screen file (lines) | 1,400 |

## Bottom line

**Verdict — moderate, targeted refactor.**

This is not a codebase in crisis. Package boundaries are sound and test discipline is genuinely above average for a project this size. The problem is accreted complexity: a handful of oversized screens fusing UI with business and crypto logic, and a correctness model that leans on scattered patch comments rather than centralized invariants. Recommend a scoped extraction effort on the five largest screens plus a CI safety net — not a rewrite.

## 01 — What's already working

Reasons this isn't starting from zero:

- **Clean package split.** `models` / `services` / `screens` separation is consistent across all three packages, with genuinely shared crypto and model code factored into `shared/`.
- **Real test coverage.** ~47% test-to-code ratio by line count, and the tests read as deliberate rather than an afterthought.
- **Institutional memory is preserved.** Every non-trivial bug fix is tagged (`TEST-016`, `V-011`, `N-006`, `DECISION-017`...) and traceable back to `DEFECT_TRACKER.md`, so history isn't lost even where it isn't yet centralized in code.

## 02 — What's driving the refactor need

Six findings, ranked by leverage:

1. **Oversized, logic-fused screen widgets.** `supplier_stamp_card.dart` (1,400 ln), `qr_scanner_screen.dart` (1,272), `backup_storage_service.dart` (1,205), `customer_card_detail.dart` (1,169), `supplier_redeem_card.dart` (1,013). These `StatefulWidget`s mix UI, navigation, crypto token generation, and error handling directly in `State` methods — confirmed by reading `_generateAndShowStamp` / `_showStampTokenQR` in the first file. None of that logic can be unit-tested without pumping the full widget tree.
2. **No state-management seam.** Zero provider / riverpod / bloc / get_it in any `pubspec.yaml` — raw `setState()` throughout (18 `StatefulWidget`s vs. 11 `StatelessWidget`s). Workable at this size, but it's precisely why finding 1 exists: there's no architectural seam to pull logic out to.
3. **Correctness lives in patch comments, not the design.** 206 defect-ID references (142 unique IDs) embedded directly in business logic outside test files. Valuable history, but a real comprehension tax — the `stampsRequired` bound literally drifted across three separate check-sites over TEST-016 / 017 / 019 / 020 before DECISION-017 centralized it. That pattern likely repeats elsewhere uncaught.
4. **Force-unwrap culture.** 24 `!.` null-assertions in `supplier_stamp_card.dart` alone. A crash risk, and it flattens control flow that should be visible in the types.
5. **No CI gate.** The only GitHub Actions workflow deploys the marketing site to Cloudflare Pages. Neither `flutter analyze` nor `flutter test` runs automatically anywhere — the 10K lines of tests only protect you when someone remembers to run them locally. This raises the risk tier of any refactor until it's fixed.
6. **Default lints only.** `flutter_lints` with no project-specific rules added, despite a bug history that stricter analyzer rules could plausibly have caught earlier.

## 03 — Recommended sequence

| Step | Action | Why this order |
|---|---|---|
| 1 | Add a CI workflow running `flutter analyze` + `flutter test` on every push/PR. | Establishes a safety net before any refactor touches signed-data code paths. |
| 2 | Extract business/crypto/state orchestration out of the top 2 largest screens into testable controllers. | Highest leverage; sets the pattern the remaining screens can follow mechanically. |
| 3 | Apply the same extraction to the remaining 3 oversized screens. | Repetitive once the pattern from step 2 exists — lower risk, lower judgment required. |
| 4 | Consolidate scattered bound/constant checks (the `stampsRequired`-style drift) into single-source validators. | Directly addresses finding 3; some precedent already exists in `CardIssueToken`. |
| 5 | Tighten lints; reduce `!.` force-unwraps in favor of proper null-handling. | Lower urgency clean-up, best done once the structural extraction has settled. |

## 04 — Model recommendation

**Opus 5 to lead, Sonnet 5 to scale.**

The bulk of this work isn't mechanical rename-and-move — it's judgment-heavy. Extracting logic from a 1,400-line widget means preserving signed-data contracts byte-for-byte (`getSignatureData()` formats must stay identical or every existing card fails verification), reconciling scattered bound-checks without missing a call site, and not silently dropping one of the 142 defect-fix behaviors encoded in comments.

- **Opus 5 — lead the extraction.** Use for step 1 planning and step 2 (the first two screen extractions). Wide-context, high-stakes-correctness work where most of this codebase's real behavior is invisible in the code itself — it's encoded in signed-data formats and defect history that has to be cross-referenced, not guessed at.
- **Sonnet 5 — scale the pattern.** Once Opus has established the controller/service pattern on the first screens, hand the remaining oversized screens (step 3) to Sonnet — applying an already-proven pattern is a good place to control cost without raising risk.

---

*Prepared by Claude Code. Branch: develop @ `b0f6476`. Method: static review only, no code changes.*
