# TODO: Make Simple Mode scan cooldown editable after business creation

## Context
Currently `scanInterval` ("Customer Scan Cooldown") can only be set once, during
onboarding (`supplier_onboarding.dart`). There's no way to change it afterward.

**Good news confirmed by research:** this is safe and cheap to add. Unlike
`stampsRequired`, `scanInterval` is NOT baked into issued cards or the
`CardIssueToken`. It's read live off the `Business` record every time the
supplier generates a new stamp (`supplier_stamp_card.dart:395`,
`scanInterval: _business!.scanInterval`), and each `StampToken` signs its own
value at that moment (V-010 fix). So changing it:
- takes effect on the very next stamp generated, for every card (old or new)
- never invalidates past stamps (each one verifies against the value it was
  signed with, not the business's current value)
- needs no migration — the DB column (`scan_interval_seconds`) and
  `BusinessRepository.updateBusiness()` already exist and already work

## Plan
Mirror the existing pattern in `source/supplier_app/lib/widgets/stamps_required_fix.dart`
(which already lets suppliers fix an out-of-range `stampsRequired` post-creation
via `BusinessRepository().updateBusiness(business.copyWith(...))`).

1. **Add UI in `source/supplier_app/lib/screens/supplier/supplier_settings.dart`**
   - New editable row/control for the cooldown, same +/- stepper + slider UX
     as onboarding (`supplier_onboarding.dart:354-416`).
   - Bounds: `AppConstants.simpleModeMinScanIntervalMs` /
     `simpleModeMaxScanIntervalMs` (5-60s) — same constants onboarding uses,
     don't hardcode a second copy (that's exactly the kind of bound-drift bug
     TEST-016/017/019 hit for `stampsRequired`).
   - Only show it when `business.mode == OperationMode.simple` — Secure Mode
     never uses `scanInterval` at all (`crypto_utils.dart:163-166` — always
     signs `null` for genuine Secure Mode stamps), so the control would be
     meaningless there.
   - On save: `BusinessRepository().updateBusiness(business.copyWith(scanInterval: newValueMs))`.

2. **Copy update** — since this *is* immediately effective (unlike the
   stampsRequired fix's "only affects future cards" caveat), the dialog/label
   text should say something like "Applies to the next stamp scanned — no
   need to reissue existing cards."

3. **Tests to add/update**
   - `source/supplier_app/test/screens/supplier_onboarding_mode_selection_test.dart`
     has existing coverage for the onboarding slider — check for a sibling
     settings test file to extend, or add
     `supplier_settings_scan_interval_test.dart`.
   - Cover: bounds clamping, Simple-Mode-only visibility, persistence via
     `updateBusiness`, and that a newly generated `StampToken` after the
     change carries the new value.

## Files touched
- `source/supplier_app/lib/screens/supplier/supplier_settings.dart` (main change)
- possibly a small shared widget if the stepper/slider UI is worth factoring
  out of `supplier_onboarding.dart` to reuse rather than duplicate
- new/updated test file under `source/supplier_app/test/`

No changes needed to: `business.dart`, `business_repository.dart`,
`supplier_database_helper.dart`, `qr_token_generator.dart`, `rate_limiter.dart`,
`qr_tokens.dart` — all already support a changed value at runtime.
