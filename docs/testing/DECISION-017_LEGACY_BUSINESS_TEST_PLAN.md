# 20-Stamp Legacy Business Test Plan (DECISION-017 / TEST-021 / TEST-022)

**Purpose:** Manual device-testing reference for validating DECISION-017 (self-service `stampsRequired` fix) and the cross-version compatibility issues it surfaced (TEST-021, TEST-022), using the recurring 20-stamp Secure Mode legacy business scenario. Living document - update the Progress Log as testing continues instead of re-deriving state from chat history.

**Devices:** Supplier app on iPad, Customer app on iPhone.

**Available TestFlight builds (both apps):**
- **2.0.3 (23)** - live on the App Store. Predates TEST-016 through DECISION-017 entirely.
- **2.1.0 (27)** - has TEST-016 through TEST-021. No DECISION-017 (no "Fix Now").
- **2.1.1 (28)** - has everything, including DECISION-017.

---

## Known constraints (read before testing - avoids re-discovering these)

1. **TEST-022 (open defect):** a supplier on build 27+ generates a compact-encoded Issue Card QR *unconditionally* (every issuance, not just large ones). A customer app older than build 27 can't parse it at all - "This is not a valid QR Code" for every issuance, regardless of stamp count. **To issue a NEW card to an OLD customer app, both apps must be on a matched old version (v23) for that specific step.**
2. **Stamping an EXISTING card is NOT affected by this.** Stamp tokens have never been compact-encoded, on any build in this chain - confirmed via code trace, a real signed round-trip test, and a live device test (see Progress Log). Version mismatches between supplier and customer are safe for stamping specifically.
3. **New-card issuance already enforces the 3-12 `stampsRequired` range** as of TEST-020/build 26 - this predates DECISION-017. A business outside that range (e.g. 20 stamps) cannot issue *new* cards on any build 26+, until DECISION-017's "Fix Now" is used (build 28+).
4. **Token expiry windows** - worth ruling out before assuming a rejection is a real bug: stamp tokens expire after 2 minutes (exact text: *"Stamp expired (older than 2 minutes)"*), card-issue tokens after 5 minutes, stamp-request tokens after 1 minute.
5. **Recovery Backup / Clone restore only carries the business's own config** (keys, `stampsRequired`, mode, stats) - it never includes customer card data, since cards live entirely in the customer app's own local database.

---

## Progress Log

### Setup — ✅ COMPLETE
- [x] Supplier iPad: v2.0.3(23), Secure Mode business restored from backup, `stampsRequired = 20`
- [x] Customer iPhone: v2.0.3(23) (matched version - required per constraint #1 above; a 27-supplier/23-customer pairing was tried first and failed exactly as constraint #1 describes, which is how TEST-022 was found)
- [x] Issued a new card with 5 initial stamps → card at 5/20
- [x] Added 2 more stamps via the normal Add Stamp flow → card at **7/20**

### Phase 2 — Baseline stamping control — ✅ COMPLETE, PASSED
- [x] Confirmed ordinary stamping works on a matched v23/v23 pair, before any Fix Now involvement (this is what produced the 7/20 card above)

### Phase 3–4 — Fix Now + old-card stamping — ✅ COMPLETE, PASSED
- [x] Supplier iPad upgraded to v2.1.1(28)
- [x] DECISION-017's "New cards can't be issued" banner appeared correctly for the 20-stamp business
- [x] Used Fix Now to reconfigure `stampsRequired` to a supported value (**12** selected)
- [x] Generated a fresh Add Stamp QR immediately afterward
- [x] Customer scanned it successfully - stamp was added to the old card
- [x] Repeated: supplier scanned the customer's stamp-request code and added 2 more stamps in a single transaction - card went from 7/20 to **9/20** on the customer app, confirmed (customer still on v23 - mismatched)
- **Result: stamping an old out-of-range card is unaffected by Fix Now, confirmed across two separate attempts (single stamp, then a 2-stamp transaction) with a mismatched customer version. Matches the code-level prediction exactly.**

### Phase 6a — Matched-version re-confirmation (28/28) — ✅ COMPLETE, PASSED
- [x] Customer iPhone upgraded to v2.1.1(28) - now fully matched with the supplier
- [x] Added 1 more stamp to the existing card - card went from 9/20 to **10/20**, confirmed
- **Result: stamping continues to work identically with both apps matched on 28. No new issues from removing the version mismatch.**

### Phase 6b — Positive path: new card issuance from the fixed business — ✅ COMPLETE, PASSED
- [x] Issued a brand-new card from the business (now `stampsRequired = 12`) with 2 initial stamps pre-applied, on the matched 28/28 pair - customer received a second card, **2/12**, no errors
- [x] Added a further stamp to the *old* 20-stamp card - went from 10/20 to **11/20** - old card keeps working normally alongside the new one
- [x] Added a further stamp to the *new* 12-stamp card - went from 2/12 to **3/12** - new card also stamps normally
- **Result: the actual purpose of DECISION-017 is confirmed working end-to-end. The business now has two live cards for the same customer - an old 20-stamp card (11/20) and a new 12-stamp card (3/12) - both stamping correctly and independently, exactly as the architecture predicted (each card frozen at its own issuance-time stampsRequired, unaffected by the business's current live config).**

### Phase 7 — Extended confirmation: 20-stamp card completed via overflow onto the 12-stamp card, then redeemed — ✅ COMPLETE, PASSED
- [x] Continued adding stamps to the old 20-stamp card on the matched 28/28 pair until it completed
- [x] Overflow (leftover stamps beyond the 20-stamp card's own target) correctly rolled onto the *existing* 12-stamp card rather than creating a third card - matches `CardRepository.findCardWithSpace()`'s "most stamps with space" priority (confirmed by code read earlier this session)
- [x] The completed 20-stamp card was redeemable and was successfully redeemed
- **Result: the overflow-relocation mechanics (TEST-018) and the redemption QR compact encoding (TEST-020) both work correctly end-to-end for a real, live legacy card, including routing overflow onto a pre-existing card rather than blindly creating a new one. This is the most complete real-world exercise of the whole TEST-017 through DECISION-017 defect chain in a single scenario.**

### Discovered along the way
- **TEST-022** (see `docs/project-management/DEFECT_TRACKER.md`): supplier v27 + customer v23 could not issue a *new* card - blocked by constraint #1 above. Root-caused to TEST-021's unconditional compact QR encoding. **Fixed 2026-08-17** (v2.1.1+29, built and delivered to TestFlight 2026-08-18) - now prefers plain JSON whenever it fits, falling back to compact encoding only for the genuine oversized case.

---

## Status: this test plan is complete

Every phase passed, including the extended Phase 7 exercise (full completion + overflow relocation + redemption of the legacy 20-stamp card). DECISION-017 works exactly as designed - self-service reconfiguration, no impact on existing cards, new issuance unblocked, and existing cards continue to interoperate correctly with overflow/redemption even after the business's live config changes. TEST-022 (found along the way) is fixed and tracked separately in `DEFECT_TRACKER.md`; final on-device confirmation on v2.1.1+29 passed 2026-08-18, see below.

## Remaining steps

- [x] Build and upload v2.1.1+29 to TestFlight - done 2026-08-18.
- [x] Confirm TEST-022's fix (ordinary card issuance from a matched-or-mismatched supplier/customer pair) on an actual device - done 2026-08-18, both scenarios passed. Full log: `docs/testing/TEST-022_VALIDATION_TEST_PLAN.md`.

**This test plan and its TEST-022 follow-up are both now complete.**

---

## Notes / corrections

*(Add anything here that turns out to be wrong or needs updating as testing continues, rather than editing the Progress Log entries above out of existence - keeps a trail of what was actually learned when.)*
