# Review Coverage Matrix

Tracks every review pass run against the LoyaltyCards codebase — general-purpose
and role-based — so coverage gaps are visible at a glance. Update the matching
row each time a role from [REVIEW_ROLES.md](REVIEW_ROLES.md) is run.

| Role | Last Reviewed | Findings (Crit/High/Med/Low) | Status | Reference |
|---|---|---|---|---|
| Security (general) | 2026-07-25 | 3/4/–/– | Fixed | [VULNERABILITIES.md](VULNERABILITIES.md) V-010–V-016 |
| Functional/Correctness (general) | 2026-07-26 | –/–/10/– | Fixed (10 of 10, ex. Q-011 orientation) | [FUNCTIONAL_REVIEW_2026-07-26.md](FUNCTIONAL_REVIEW_2026-07-26.md) Q-001–Q-012 |
| Fraud / Abuse Red-Team | 2026-07-25 | 0/1/1/1 | Findings Open | [REVIEW_ROLES.md #1](REVIEW_ROLES.md#1-fraud--abuse-red-team) |
| Accessibility | 2026-07-25 | 1/2/2/1 | Findings Open | [REVIEW_ROLES.md #2](REVIEW_ROLES.md#2-accessibility) |
| App Store / Platform Compliance | 2026-07-25 | 1/0/2/1 | Findings Open | [REVIEW_ROLES.md #3](REVIEW_ROLES.md#3-app-store--platform-compliance) |
| Offline / Multi-Device Consistency | 2026-07-25 | 1/1/0/0 | Findings Open | [REVIEW_ROLES.md #4](REVIEW_ROLES.md#4-offline--multi-device-consistency) |
| Onboarding / First-Run UX | 2026-07-25 | 0/1/1/1 | Findings Open | [REVIEW_ROLES.md #5](REVIEW_ROLES.md#5-onboarding--first-run-ux) |
| Test Coverage / QA | 2026-07-25 | 2/3/2/1 | Findings Open | [REVIEW_ROLES.md #6](REVIEW_ROLES.md#6-test-coverage--qa) |
| Performance / Battery | 2026-07-25 | 0/0/0/1 | Findings Open (accept-as-risk) | [REVIEW_ROLES.md #7](REVIEW_ROLES.md#7-performance--battery) |
| Legal / Privacy | 2026-07-25 | 0/0/1/1 | Findings Open | [REVIEW_ROLES.md #8](REVIEW_ROLES.md#8-legal--privacy) |

**Cross-role convergences (see [REVIEW_ROLES.md](REVIEW_ROLES.md) top-of-doc
note for detail):**
- Recovery Backup / Clone Device restore defeats V-013 — flagged by both
  Fraud/Abuse (High) and Offline/Multi-Device Consistency (Critical). Highest
  priority fix from this round.
- Undisclosed hashed device identifier in redemption QR payloads — flagged by
  both App Store Compliance (Critical) and Legal/Privacy (Medium).

**Explicitly out of scope:** Localization — not a current product target.

## Legend
- **Status:** Pending / In Progress / Findings Open / Fixed / Accepted-as-risk
- **Findings:** counts at time of last review, by severity — update alongside
  `Status` each time a role is re-run, don't just overwrite silently if issues
  remain open from a prior pass.
