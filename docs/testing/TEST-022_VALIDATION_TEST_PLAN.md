# TEST-022 Real-Device Test Case (v2.1.1+29)

**Purpose:** Manual device-testing reference for confirming TEST-022's fix - the automated tests already prove the encoding logic is correct (see `docs/project-management/DEFECT_TRACKER.md`), but this is the one item in the current batch of work that specifically needs a real device, since it's a cross-version QR-format bug that only shows up in the interaction between two actual app builds.

**Devices:** Supplier app on iPad, Customer app on iPhone (same pairing as the DECISION-017 test plan).

**What TEST-022 was:** `supplier_issue_card.dart`'s Issue Card QR started unconditionally compact-encoding every card issuance in v2.1.0+27 (TEST-021's fix), instead of only the rare oversized case it was meant for. A customer app older than v27 only knows how to parse plain JSON, so it rejected *every* new-card QR from an updated supplier - "This is not a valid QR Code" regardless of stamp count, not just the original large-payload edge case. **Fix:** both the Issue Card QR and the Redemption QR now check `QrCapacity.fits()` on plain JSON first, and only fall back to compact encoding when the payload genuinely doesn't fit (verified: covers every stamp count up to 16, only the true worst case at 20 still needs compact encoding).

---

## Pre-requisites

- Supplier iPad and Customer iPhone both updated to **v2.1.1+29** (the build this fix ships in - v27/28 still have the bug).
- Any business, Secure or Express mode, `stampsRequired` in the normal 3-12 range is enough to exercise the common path; no need to reuse the legacy 20-stamp business for this specific test.

---

## Test 1 - Matched-version issuance uses plain JSON (regression guard)

1. On the matched 29/29 pair, issue a brand-new card with 0 initial stamps.
2. Customer scans it - **expected:** card is added normally, no error.
3. Repeat issuing a card with a few initial stamps (e.g. 5).
4. **Expected:** works identically - this confirms the ordinary path (which was never actually broken) still works after the fix.

## Test 2 - The actual regression: mismatched supplier/customer versions

This is the scenario that was broken in v27/v28 and is the real point of this test.

1. Leave the **supplier** on v2.1.1+29.
2. If possible, put the **customer** app on an older build (v2.1.0+27 or v2.0.3+23) - reproduces the exact mismatch that originally surfaced TEST-022. If a second customer device/build isn't available, this step can be skipped in favor of Test 1 plus the automated coverage, but it's the most direct confirmation of the fix.
3. Supplier issues a new card (any stamp count in the normal range).
4. Customer scans it.
5. **Expected (fixed):** card is added successfully - plain JSON parses fine on the older customer app, since the supplier now only falls back to compact encoding when actually necessary.
6. **What it would have looked like broken (for reference, don't expect this):** "This is not a valid QR Code. Please scan a card issuance QR."

## Test 3 - Worst-case fallback still works (optional, lower priority)

Only worth doing if a legacy business with `stampsRequired` far outside the normal range is available (e.g. the existing 20-stamp test business used in the DECISION-017 plan), since this is what still exercises the compact-encoding fallback path:

1. Issue a new card with a high initial stamp count (approaching 20) from that business.
2. Customer scans it, on a **matched, current** (29/29) pair - compact-encoding round-trips correctly on any build that already understands it, so this isn't a version-mismatch test, just confirming the fallback path itself still works end-to-end on a real device.
3. **Expected:** card is added successfully, same as before this fix - this path already worked, the fix just narrowed when it's used.

---

## Result reference

Record results directly in this file's Progress Log (add one below, following the pattern in `DECISION-017_LEGACY_BUSINESS_TEST_PLAN.md`) once run - keeps a trail of what was actually confirmed on-device rather than only automated-test coverage.

## Progress Log

**v2.1.1+29 built and delivered to TestFlight 2026-08-18 - ready to test.** Not yet run.
