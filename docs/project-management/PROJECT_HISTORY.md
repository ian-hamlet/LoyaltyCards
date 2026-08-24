# Project History — Decisions & Requirements, Condensed

**Purpose:** a fast, single-document read on how LoyaltyCards got to its current shape and why, replacing the need to read through months of individual planning snapshots and one-time review reports to answer "what did we decide and when." Full defect-by-defect and decision-by-decision detail still lives in `DEFECT_TRACKER.md` and `VULNERABILITIES.md` - this document links into specific IDs there rather than duplicating them.

**Last updated:** 2026-08-24, as part of the documentation consolidation described below.

---

## What this supersedes

The documents below were superseded planning snapshots, one-time review reports, or resolved point-fix plans - moved to `docs/archive/` (mirroring their original subfolder) rather than deleted, so nothing is lost and every link/grep still works. See "Superseded-document index" at the bottom for the full old-path → new-path list.

---

## Chronological milestone timeline

**v0.2.0 (April 2026) — baseline.** First coherent build: dual-mode operation (originally "Simple" and "Secure" Mode), P2P QR-based card issuance/stamping/redemption, ECDSA P-256 signatures, biometric key protection, encrypted backup/restore, zero personal data collection. An initial security assessment (`VULNERABILITIES.md` V-001 through V-009) and a paired architectural/production-readiness review (now archived) both date from this era.

**April–June 2026 — hardening toward v1.0.** TestFlight feedback cycle, dark mode, package updates, App Store materials preparation.

**July 2026 — the V-010 through V-016 security review.** A second, deeper pass on signature coverage and redemption verification found real gaps missed by the original assessment - unsigned `stampCount`/`mode` fields, dead verification code, no duplicate-redemption protection, client-side-only rate limiting. All fixed. A same-week functional/correctness review (four parallel focused passes) found and fixed ten more issues (Q-001–Q-010: biometric re-lock, DB-timeout data loss, non-atomic stamp crediting, and others) independently of the security pass - recorded as a reminder that one review lens doesn't substitute for another. Its one still-open low-severity item is now tracked as `DEFECT_TRACKER.md` Q-012.

**July 28 2026 — "Simple Mode" renamed to "Express Mode"** across all user-facing copy, alongside closing a critical redemption-inflation gap and an Express Mode repeat-customer lockout bug (v2.0.0+19). Rejected by App Review for CRASH-001 (a native crash tapping Print, supplier app); fixed and live as v2.0.2+21 (Aug 10) - **the project's first public App Store release**.

**August 15–19 2026 — the `stampsRequired`/QR-capacity saga.** TEST-016 (3-4 stamp businesses couldn't issue cards) led to TEST-017 through TEST-022, tracing a QR-capacity ceiling problem through both the redemption and issuance sides, plus a cross-version compatibility regression (TEST-022) found via real-device testing. Resolved by DECISION-017 (self-service "Fix Now" reconfiguration for an out-of-range business) and TEST-020's compact QR encoding, raising the safe stamps-required ceiling to 12. Shipped as v2.1.1+29, approved and live Aug 19.

**August 21–24 2026 — v2.2.0 line.** Editable Express Mode scan cooldown, then supplier-editable business profile fields (Name, Icon, Brand Color) with a directional `stampsRequired` policy protecting customers already collecting (DECISION-021), a local audit trail, and a macOS desktop build for the Supplier app (dev/testing convenience, not a distribution target - DECISION-022). Consolidated into v2.2.0+32, approved and released to the App Store 2026-08-24. The Cloudflare Pages migration (public site moved off GitHub Pages) completed the same day, and this documentation consolidation plus a code-quality refactor pass followed immediately after.

---

## Key architectural decisions, stated once

**P2P, no server, ever.** No backend, no account system, no central database. Every device holds its own data; cards move between devices only via QR codes the two apps exchange directly. This is a permanent constraint, not a current limitation - features that would require a server (push notifications, cross-device sync, aggregate analytics) are explicitly out of scope, not deferred.

**Dual-mode: Express and Secure.** Express Mode is trust-based (reusable QR, no per-stamp signature) - suited to low-value rewards where the cost of occasional abuse is lower than the friction of cryptographic verification. Secure Mode signs every stamp with a time-limited, device-bound token. Businesses choose once at setup; the choice is permanently locked (only `stampsRequired`, Name, Icon, Brand Color, and Express Mode's scan cooldown are editable afterward).

**Directional `stampsRequired` policy (DECISION-021, `Requirements/DISCUSSION_Business_Field_Editing.md` §4.1).** A customer already collecting is never made worse off retroactively, but freely gets any improvement: a decrease applies to an in-progress card on the customer's next scan; an increase only ever applies to the *next* card, never retroactively. Carried via unsigned `StampToken` snapshot fields, decoded as nullable for backward compatibility with pre-feature tokens.

**Signed-data format is invariant.** `getSignatureData()` (`shared/lib/models/qr_tokens.dart`) and its documented byte format (`shared/lib/utils/signature_format.dart`) must never change shape - every card already issued or in circulation verifies against the format it was signed with. Any refactor calls into these unchanged; nothing in this codebase should ever reimplement signing/verification inline.

**No CI gate — deferred, not declined** (`docs/quality/CODE_QUALITY_REVIEW_2026-08-21.md`, step 1). `flutter analyze`/`flutter test` run manually rather than automatically on push. Revisit once manual-run discipline stops being manageable for a single-developer workflow.

---

## Superseded-document index

| Original path | New path | Why archived |
|---|---|---|
| `docs/project-management/NEXT_ACTIONS.md` | `docs/archive/project-management/NEXT_ACTIONS.md` | Stale "current plan" snapshot (last updated 2026-06-11, describes a since-shipped v1.0.1 release candidate) |
| `docs/project-management/PROJECT_DEVELOPMENT_PLAN.md` | `docs/archive/project-management/PROJECT_DEVELOPMENT_PLAN.md` | Original April 2026 roadmap, long superseded by shipped releases |
| `docs/project-management/BRANCH_STATUS_2026-07-26.md` | `docs/archive/project-management/BRANCH_STATUS_2026-07-26.md` | Point-in-time snapshot of two now-merged feature branches |
| `docs/project-management/KNOWN_ISSUES_AND_RISKS.md` | `docs/archive/project-management/KNOWN_ISSUES_AND_RISKS.md` | Superseded by `DEFECT_TRACKER.md`/`VULNERABILITIES.md`, both actively maintained |
| `docs/project-management/VERSION_INCONSISTENCY_REPORT.md` | `docs/archive/project-management/VERSION_INCONSISTENCY_REPORT.md` | One-time v0.3.0-era version-string audit |
| `docs/project-management/VERSION_MANAGEMENT_ANALYSIS.md` | `docs/archive/project-management/VERSION_MANAGEMENT_ANALYSIS.md` | One-time v0.2.0-era version-drift analysis |
| `docs/project-management/CLOUDFLARE_MIGRATION_COMPLETION_PLAN.md` | `docs/archive/project-management/CLOUDFLARE_MIGRATION_COMPLETION_PLAN.md` | Task complete as of 2026-08-24 |
| `docs/project-management/FEATURE_PLAN_SCAN_INTERVAL_EDITABLE.md` | `docs/archive/project-management/FEATURE_PLAN_SCAN_INTERVAL_EDITABLE.md` | Task complete as of 2026-08-21 (shipped in v2.2.0+30, folded into v2.2.0+32) |
| `docs/project-management/NEXT_ITERATION_PLANNING_2026-08-21.md` | `docs/archive/project-management/NEXT_ITERATION_PLANNING_2026-08-21.md` | Its own contents (Cloudflare migration, scan-cooldown feature) are now all actioned |
| `docs/project-management/CRASH-001-stamp-print-race-condition.md` | `docs/archive/project-management/CRASH-001-stamp-print-race-condition.md` | Resolved and live since v2.0.2+21; `CRASH-001` remains a valid ID reference in code comments and `DEFECT_TRACKER.md` |
| `docs/project-management/UI-001-how-it-works-dark-mode-contrast.md` | `docs/archive/project-management/UI-001-how-it-works-dark-mode-contrast.md` | Resolved; `UI-001` remains a valid ID reference |
| `docs/quality/EXPERT_ARCHITECTURAL_REVIEW.md` | `docs/archive/quality/EXPERT_ARCHITECTURAL_REVIEW.md` | Frozen point-in-time review, v0.2.0 era (April 2026) |
| `docs/quality/EXPERT_CODE_REVIEW_PRODUCTION_READINESS.md` | `docs/archive/quality/EXPERT_CODE_REVIEW_PRODUCTION_READINESS.md` | Frozen point-in-time review, v0.2.0 era (April 2026) |
| `docs/quality/LESSONS_LEARNED.md` | `docs/archive/quality/LESSONS_LEARNED.md` | Explicitly scoped to v0.2.0 |
| `docs/quality/PROCESS_IMPROVEMENTS.md` | `docs/archive/quality/PROCESS_IMPROVEMENTS.md` | Retrospective companion to the above |
| `docs/quality/REVIEW_PROCESS_EXPLANATION.md` | `docs/archive/quality/REVIEW_PROCESS_EXPLANATION.md` | One-time explainer, April 2026 |
| `docs/quality/TEST_COMPLETION_REPORT.md` | `docs/archive/quality/TEST_COMPLETION_REPORT.md` | April 2026 completion snapshot, mislabeled "Active" |
| `docs/quality/MAGIC_NUMBERS_REVIEW_2026-08-17.md` | `docs/archive/quality/MAGIC_NUMBERS_REVIEW_2026-08-17.md` | All findings (N-001–N-009) resolved and marked complete |
| `docs/quality/FUNCTIONAL_REVIEW_2026-07-26.md` | `docs/archive/quality/FUNCTIONAL_REVIEW_2026-07-26.md` | All findings resolved or closed; the one genuinely open item (Q-012) ported to `DEFECT_TRACKER.md` first |

**Not archived, deliberately:** `DEFECT_TRACKER.md`, `VULNERABILITIES.md` (both living logs, still being appended to), `TESTING_STRATEGY.md`, `REVIEW_ROLES.md`, `REVIEW_MATRIX.md`, `VERSION_NUMBERING_STANDARD.md` (still-current policy), the whole `Requirements/` subfolder (canonical requirements set, cited across 17 dart files), and `GENERALIZATION_AND_OPEN_PROTOCOL_PLAN.md` (forward-looking backlog, not history).
