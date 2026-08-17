# Magic Numbers / Hardcoded Constants Review — 2026-08-17

**LoyaltyCards (branch `develop`)**
**Assessment Date:** August 17, 2026
**Assessor:** AI-assisted review (Claude) — repo-wide search across `source/supplier_app`, `source/customer_app`, and `source/shared` for numeric literals used directly in business/security-rule logic instead of a named constant.
**Scope:** Time windows, thresholds, counts, rate limits, and crypto parameters that encode a rule. Purely cosmetic UI sizing (padding, font size, icon size) was intentionally skipped except where it duplicates a security-relevant value.
**Status:** Investigation only — no code was changed as part of this review.

---

## How to resume this review

Nothing below has been fixed yet. When picking this back up, the natural next step is to:
1. Add the missing constants (5-minute issuance expiry, 60-second stamp-request freshness, `stampsRequired` ceiling of `100`) to `source/shared/lib/constants/constants.dart` alongside the existing `AppConstants`.
2. Replace each duplicated raw literal below with a reference to the (new or existing) constant.
3. Resolve the clone-QR expiry discrepancy (N-005) with whoever owns that feature before changing code — it's not clear yet whether the code or the docs are wrong.
4. Decide whether the duplicated crypto decode routine (N-007) is worth consolidating into one shared implementation, or just documenting as intentional duplication.

`AppConstants.issueIntervalMs` (30s) is defined but currently unused anywhere in the codebase — worth checking whether it was meant to gate something before assuming it's dead code.

---

## Existing constants infrastructure

`source/shared/lib/constants/constants.dart` (`AppConstants`) already centralizes some of the values below, and is the natural home for the rest:

| Constant | Value | Correctly referenced everywhere? |
|---|---|---|
| `stampRateLimitMs` | 5000 (5s between stamps) | Yes — see `rate_limiter.dart:61` |
| `issueIntervalMs` | 30000 (30s) | Unreferenced anywhere — possibly dead |
| `stampExpiryMs` | 120000 (2-min stamp-token expiry) | Enforced correctly (`token_validator.dart:147`), but redisplayed as a raw literal in UI (see N-003) |
| `simpleModeDefaultScanIntervalMs` | 30000 | Redefined as raw literal elsewhere (see N-006) |
| `simpleModeMinScanIntervalMs` | 5000 | Redefined as raw literal elsewhere (see N-006) |
| `simpleModeMaxScanIntervalMs` | 60000 | Redefined as raw literal elsewhere (see N-006) |
| `databaseVersion` / `supplierDatabaseVersion` | — | Yes, both DB helpers reference these correctly |

`CardIssueToken.minStampsRequired` / `maxStampsRequired` (`source/shared/lib/models/qr_tokens.dart:107-108`) is the pattern done right elsewhere in the codebase — a single source of truth referenced consistently from `supplier_onboarding.dart` and `stamps_required_fix.dart`. Worth using as the template for the fixes below.

---

## Findings

### N-001: 5-minute card-issuance QR expiry has no named constant, and is re-typed three times
**Priority:** High (security-relevant, duplicated)

- `source/customer_app/lib/services/token_validator.dart:59` — `if (age > 5 * 60 * 1000)` (Secure Mode card-issue token expiry check — the actual enforcement).
- `source/supplier_app/lib/screens/supplier/supplier_issue_card.dart:696` and `:721` — `.add(const Duration(minutes: 5))`, independently re-typed for the countdown/expiry-time display shown to the supplier.

No constant exists anywhere for this value. The enforcement side and the two display sites can drift independently since nothing ties them together.

### N-002: 60-second stamp-request freshness window duplicated identically in two files
**Priority:** High (security-relevant, duplicated)

- `source/customer_app/lib/services/token_validator.dart:223` — `if (age > 60 * 1000)` inside `validateStampRequest`.
- `source/supplier_app/lib/screens/supplier/supplier_stamp_card.dart:169` — `if (age > 60 * 1000)`, the exact same check, independently re-typed on the supplier side rather than sharing a constant.

Same risk shape as N-001: customer and supplier each enforce their own copy of a value that's supposed to represent one shared rule.

### N-003: 2-minute stamp-token expiry correctly centralized for enforcement, but re-typed for display
**Priority:** Medium

- Enforcement is correct: `token_validator.dart:147` uses `AppConstants.stampExpiryMs`.
- Display is not: `source/supplier_app/lib/screens/supplier/supplier_stamp_card.dart:340` and `:1214` independently hardcode `.add(const Duration(minutes: 2))` for the countdown UI, instead of deriving from `AppConstants.stampExpiryMs`.
- Related: `source/customer_app/lib/screens/customer/qr_display_screen.dart:268-269, 344-352` hardcodes both the 1-minute (stamp-request) and 2-minute (stamp-token) windows as raw `int` arguments to `_getExpiryTime()` and in UI copy (`'Valid 1 min ...'` / `'Valid 2 min ...'`), duplicating both N-002's and N-003's values without referencing either constant.

### N-004: Database open timeout hardcoded identically in both apps
**Priority:** Low-Medium (not security-relevant, but a real duplication)

- `source/customer_app/lib/services/database_helper.dart:49` and `source/supplier_app/lib/services/supplier_database_helper.dart:38` both independently declare `const Duration(seconds: 10)` for the DB-open timeout that triggers recovery/deletion logic. Same value, no shared constant.

### N-005: Clone-QR expiry — code says 5 minutes, documentation says 24 hours
**Priority:** High (looks like a genuine bug, not just a style issue — confirm with the team before touching)

- `source/shared/lib/models/supplier_config_backup.dart:41-45` — `createCloneQR` doc comment says *"expires in 5 minutes"* and the code uses `Duration(minutes: 5)`.
- The same file's class-level doc comment (line 10) and `source/supplier_app/lib/screens/supplier/clone_device_screen.dart:13` both describe this as a **"24-hour expiring QR."**

This needs a decision (which is correct?) before it's treated as a simple magic-number cleanup — it may be an actual functional bug where the QR expires 288x faster than documented/expected.

### N-006: Scan-interval bounds (5–60s) re-typed instead of referencing `AppConstants`
**Priority:** Low-Medium

- `source/supplier_app/lib/screens/supplier/supplier_onboarding.dart:378, 398, 411-412` — slider bounds (`Slider(min: 5, max: 60, ...)`) and +/- button bounds re-type `5`/`60` in seconds; the tooltip text at lines ~204/364 also hardcodes the string `"Range: 5-60 seconds"`. All of these duplicate `AppConstants.simpleModeMinScanIntervalMs` / `simpleModeMaxScanIntervalMs` (in ms) without referencing them.
- `source/shared/lib/models/business.dart:14, 26, 52-53` — `scanInterval` constructor default and JSON round-trip (`json['scan_interval_seconds'] as int? ?? 30`) both independently re-derive `30`/`30000` instead of using `AppConstants.simpleModeDefaultScanIntervalMs`.

### N-007: `stampsRequired > 100` sanity ceiling duplicated identically 3x, no named constant
**Priority:** Medium

- `source/supplier_app/lib/services/business_repository.dart:34` and `:69`
- `source/customer_app/lib/services/card_repository.dart:276`

All three throw on the same `100` ceiling. This is a separate, larger bound than `CardIssueToken.maxStampsRequired = 12` (`qr_tokens.dart:108`) — it reads as an independent "hard ceiling" invariant, not derived from the existing 12-stamp business rule, and isn't named anywhere.

### N-008: Public-key/signature decode routine duplicated wholesale between `crypto_utils.dart` and `key_manager.dart`, with magic numbers repeated in each copy
**Priority:** Medium (duplication of logic, not just numbers)

- `source/shared/lib/utils/crypto_utils.dart:54, 72, 90, 236, 243, 256` and `source/supplier_app/lib/services/key_manager.dart:224, 229-256` both independently hardcode `8` (minimum byte-buffer length for two 4-byte length headers) and `4` (length-prefix field size) multiple times.
- This isn't just repeated literals — the entire `_decodePublicKey` / `_decodeLength` implementation exists twice. If the encoding format ever changes, both copies have to be updated in lockstep, and the magic numbers `8`/`4` would need to change consistently in both.

### N-009 (minor, informational): `_errorCooldownDuration` — same value, defined twice, but already named
**Priority:** Low

- `source/customer_app/lib/screens/customer/qr_scanner_screen.dart:58` and `source/supplier_app/lib/screens/supplier/supplier_redeem_card.dart:37` both declare `static const Duration _errorCooldownDuration = Duration(seconds: 2);`. Each is already a named constant locally, so this is lower severity than the others, but it's still one shared value defined independently in two places.

---

## Summary table

| ID | Value(s) | Files affected | Priority |
|---|---|---|---|
| N-001 | 5-min card-issue expiry | `token_validator.dart`, `supplier_issue_card.dart` (x2) | High |
| N-002 | 60s stamp-request freshness | `token_validator.dart`, `supplier_stamp_card.dart` | High |
| N-003 | 2-min stamp-token expiry (display) | `supplier_stamp_card.dart` (x2), `qr_display_screen.dart` | Medium |
| N-004 | 10s DB open timeout | `database_helper.dart`, `supplier_database_helper.dart` | Low-Medium |
| N-005 | Clone-QR expiry: 5 min (code) vs 24 hr (docs) | `supplier_config_backup.dart`, `clone_device_screen.dart` | High (possible bug) |
| N-006 | 5–60s scan-interval bounds | `supplier_onboarding.dart`, `business.dart` | Low-Medium |
| N-007 | `stampsRequired > 100` ceiling | `business_repository.dart` (x2), `card_repository.dart` | Medium |
| N-008 | `8` / `4` byte-header sizes + duplicated decode logic | `crypto_utils.dart`, `key_manager.dart` | Medium |
| N-009 | 2s error cooldown (already named, defined twice) | `qr_scanner_screen.dart`, `supplier_redeem_card.dart` | Low |

No changes were made to any source file as part of this review.
