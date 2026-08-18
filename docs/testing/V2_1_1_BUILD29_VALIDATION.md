# v2.1.1+29 Short Device Validation Plan

**Status: v2.1.1+29 built and delivered to TestFlight 2026-08-18.** Section 1 (TEST-022) run and passed 2026-08-18 - sections 2 and 3 not yet run.

**Purpose:** Quick real-device sanity pass now that v2.1.1+29 is on TestFlight, covering everything fixed in this batch of work. Not a full regression pass - the automated suite (shared 211, customer_app 131, supplier_app 83, all green) already covers correctness; this is specifically for the one item that's inherently cross-version/device-dependent (TEST-022), plus quick confirmation nothing else regressed.

**Devices:** Supplier iPad + Customer iPhone, both updated to v2.1.1+29.

---

## 1. TEST-022 - the one item that actually needs a device

Full procedure in `docs/testing/TEST-022_VALIDATION_TEST_PLAN.md`. Minimum version of it:
- [x] Matched 29/29 pair: issue a new card (any normal stamp count) - adds successfully, no error. ✅ PASSED 2026-08-18.
- [x] If an older customer build is available: supplier on 29, customer on an older build, issue a new card - should now succeed (this was the actual regression; confirms the plain-JSON-first fix). ✅ PASSED 2026-08-18.

(Test 3 from the full procedure - the worst-case legacy fallback - was deliberately skipped: current install base is too small to justify chasing that edge case, and the fallback path stays covered by TEST-020's own automated/real-device verification.)

## 2. Quick smoke pass on N-008/N-009/item-4 (low risk, but worth eyeballing)

These were internal refactors with no intended behavior change - the automated suite already exercises the code paths they touch, so this is just a "does it still look and feel normal" check, not a deep test:

- [ ] **N-008** (crypto decode consolidation): any signature verification still works normally - e.g. redeem a completed Secure Mode card and confirm it succeeds. If this were broken, redemption would fail outright, not subtly.
- [ ] **N-009** (shared error-cooldown constant): scan an invalid/garbage QR on both apps - error message should appear once, then a ~2 second cooldown before it can retrigger, same as before (behavior is unchanged, just de-duplicated).
- [ ] **Item 4** (`issueIntervalMs` removed): nothing to check on-device - confirmed unreferenced anywhere in the codebase before removal, so there's no behavior to regress. The actual cooldown feature (Express Mode's scan-interval slider) is untouched by this change.

## 3. General regression guard

- [ ] Normal card issuance (Secure and Express mode) works.
- [ ] Normal stamping works.
- [ ] Normal redemption works.

If all of these pass, this batch of work is done and TEST-022's `docs/testing/TEST-022_VALIDATION_TEST_PLAN.md` can be marked complete in `DEFECT_TRACKER.md`.
