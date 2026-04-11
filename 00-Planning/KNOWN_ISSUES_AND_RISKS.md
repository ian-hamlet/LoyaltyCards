# Known Issues and Risks

# Known Issues and Risks

**Document Version:** 2.0  
**Created:** 2026-04-08  
**Last Updated:** 2026-04-11  
**Current Build:** v0.1.0 (Build 11)

---

## 🎉 Issues Resolved (Build 1-11)

### ✅ Issue #5: Stamp Chain Validation Failing (FIXED in Build 5)

**Status:** ✅ FULLY RESOLVED  
**Fix Date:** 2026-04-09

**Problem:** Hash chain validation failing due to cardId mismatch between supplier and customer.

**Solution:** 
- Added `cardId` field to `CardIssueToken`
- Supplier generates cardId once, customer uses from token
- Made cardId nullable for backward compatibility
- Card detail QR now includes `lastStampHash` field

**Verified:** ✅ Multi-stamp operations working correctly through Build 11

---

### ✅ Issue #6: Multi-Stamp UX Problem (SOLVED in Builds 1-4)

**Status:** ✅ FULLY IMPLEMENTED  
**Completion Date:** 2026-04-10

**Original Problem:** Required 4 separate scan cycles for 4 stamps (40-60 seconds).

**Solution Implemented:**
- **Multi-stamp card issuance:** 0-7 initial stamps on new card
- **Multi-stamp operations:** 1-7 stamps per scan cycle
- **Hash chain validation:** All stamps cryptographically linked
- **Single scan cycle now handles:** Customer shows QR → Supplier scans → Supplier issues 1-7 stamps → Customer scans → Done

**UX Improvement:**
- Before: 4 coffees = 4 scan cycles = ~60 seconds
- After: 4 coffees = 1 scan cycle with 4 stamps = ~10 seconds
- **6x faster** than original implementation

**Verified:** ✅ Tested with 3+3+3+3 stamps in Build 11

---

### ✅ Issue #7: Overflow Handling (ENHANCED in Build 8)

**Status:** ✅ IMPLEMENTED AS BONUS FEATURE  
**Completion Date:** 2026-04-10

**Scenario:** Customer has 9 stamps on 10-stamp card, supplier adds 3 stamps (total would be 12).

**Solution:**
- Auto-detect overflow when `stampsCollected + newStamps > stampsRequired`
- Mark original card as complete (exactly 10 stamps)
- Create new card automatically with overflow stamps (2 stamps)
- Renumber overflow stamps (start from #1 on new card)
- Maintain hash chain integrity in both cards

**Verified:** ✅ Tested and confirmed in Build 8-11

---

### ✅ Issue #8: Supplier Statistics Clarity (FIXED in Build 10)

**Status:** ✅ LABELS CLARIFIED  
**Completion Date:** 2026-04-11

**Problem:** "QRs Generated" and "Active Cards" labels unclear about P2P limitations.

**Solution:**
- Renamed "QRs Generated" → **"Cards Issued"** (count of card issuances)
- Renamed "Active Cards" → **"Cards Stamped"** (count of unique cards stamped)
- Added clear descriptions of what each metric means
- Acknowledged P2P limitations in documentation

**Verified:** ✅ Build 10-11 has clear labels

---

### ✅ Issue #9: Deployment Verification (SOLVED in Builds 3-7)

**Status:** ✅ VERSION TRACKING IMPLEMENTED  
**Completion Date:** 2026-04-10

**Problem:** Xcode aggressive caching prevented code deployment verification.

**Solution:**
- Created `shared/lib/version.dart` single source of truth
- Added version to startup logs
- Added version to AppBar titles
- Added version to Settings screens
- Build number incremented with each deployment

**Workflow:** `flutter clean + pod install + Xcode Clean Build Folder` for deployments

**Verified:** ✅ Build 11 visible in logs and UI

---

## 🔴 Known Current Limitations (P2P Architecture)

### Limitation #1: Supplier Unaware of Customer-Created Cards

**Status:** ACCEPTED AS P2P TRADE-OFF  
**Priority:** LOW (documented)

**Issue:**
When overflow creates a new card on customer device, supplier app doesn't know the card exists until customer brings it for stamping.

**Impact:**
- "Cards Issued" counter only reflects supplier-initiated card issuances
- "Cards Stamped" counter is only accurate for cards with at least one stamp
- Overflow cards invisible to supplier until first stamp request

**Mitigation:**
- Labels clearly state what they count
- Documentation explains P2P limitations
- Metrics are "proxy indicators" not absolute counts

**Alternative:** Would require centralized server (out of scope for P2P model)

---

### Limitation #2: No Redemption Confirmation

**Status:** ACCEPTED AS SIMPLIFIED FLOW  
**Priority:** LOW (by design)

**Issue:**
Simplified redemption flow: supplier verifies complete card, customer deletes card. No token exchange to prove redemption occurred.

**Impact:**
- Supplier has no record that customer redeemed reward
- Customer could screenshot QR and redeem multiple times (if they don't delete)
- No cryptographic proof of redemption

**Mitigation:**
- Trust-based model (like physical punch cards)
- Supplier visually confirms card before giving reward
- Customer expected to delete card after redemption
- If abuse detected, supplier can refuse service

**Alternative:** Token-based redemption with reset (complexity not justified for MVP)

---

### Limitation #3: Clock Drift Handling

**Status:** NOT IMPLEMENTED (deferred)  
**Priority:** LOW

**Issue:**
Timestamp validation relies on device clocks being reasonably accurate. No protection against:
- Device clock set far in future/past
- Timestamp replay attacks (old stamp tokens re-presented)

**Current State:**
- Rate limiting uses only elapsed time between operations
- No timestamp range validation
- No detection of chronologically impossible stamps

**Risk Level:** LOW (signatures prevent forgery, timing abuse requires device manipulation)

**Future Enhancement:** Add timestamp sanity checks (e.g., stamps no more than 1 hour in future)

---

## ⚠️ Technical Debt

### Debt #1: Debug Logging in Production Code

**Status:** ACTIVE (intentional for MVP)  
**Priority:** MEDIUM

**Issue:**
Extensive `print()` statements throughout code for debugging. Should be removed or gated behind `kDebugMode` flag for production.

**Files Affected:**
- `customer_app/lib/screens/customer/qr_scanner_screen.dart` (overflow logging)
- `customer_app/lib/main.dart` (startup logging)
- `customer_app/lib/screens/customer/customer_home.dart` (data deletion logging)
- `supplier_app/lib/main.dart` (startup logging)
- `supplier_app/lib/screens/supplier/supplier_home.dart` (business reset logging)

**Remediation Plan:**
- Phase 6: Wrap all debug prints in `if (kDebugMode)` checks
- Or: Create logging service with configurable levels
- Keep startup version logging (useful for support)

---

### Debt #2: No Automated Integration Tests

**Status:** DEFERRED TO PHASE 6  
**Priority:** MEDIUM

**Issue:**
All P2P testing is manual (physical devices). No automated tests for:
- QR generation/scanning flows
- Multi-stamp operations
- Overflow handling
- Hash chain validation

**Current State:**
- Shared package: 17/17 unit tests passing
- Manual testing: Comprehensive but time-consuming
- No regression test suite

**Remediation Plan:**
- Phase 6: Create integration test suite
- Mock QR scanning for automated tests
- Golden tests for QR code generation

---

### Debt #3: Rate Limiting Only on Customer Side

**Status:** ACCEPTED FOR MVP  
**Priority:** LOW

**Issue:**
Rate limiting (1 second between stamps) only enforced on customer app. Supplier app has no rate limit logic.

**Risk:**
- Modified customer app could bypass rate limit
- No server-side enforcement (P2P architecture)

**Mitigation:**
- Low risk for honest mistakes
- Would require intent to modify app
- Physical interaction required (face-to-face stamping)

**Future:** Add business-configurable stamping policies if abuse detected

---

## 🎯 Action Items

### Immediate (Phase 5)

- [ ] Export/import business configuration for multi-device suppliers
- [ ] Test configuration cloning on iPad + iPhone
- [ ] Verify both devices can issue/stamp with same business ID

### Phase 6 (Polish)

- [ ] Wrap debug prints in `kDebugMode` checks
- [ ] Create integration test suite
- [ ] Add timestamp sanity checks
- [ ] Performance profiling and optimization
- [ ] Accessibility audit
- [ ] App store preparation

### Future Enhancements (Post-MVP)

- [ ] Duplicate stamp detection (prevent replay attacks)
- [ ] Business analytics dashboard (trends over time)
- [ ] Transaction history screen (customer app)
- [ ] Stamp expiration feature (REQ-019)
- [ ] Push notifications (REQ-016) - requires server architecture

---

## 📊 Updated Risk Register

| Risk ID | Description | Likelihood | Impact | Mitigation | Status |
|---------|-------------|------------|--------|------------|--------|
| RISK-001 | Multiple stamps UX too slow | HIGH | HIGH | Multi-stamp feature | ✅ RESOLVED |
| RISK-002 | Hash chain validation failures | MEDIUM | HIGH | cardId in token | ✅ RESOLVED |
| RISK-003 | Overflow handling missing | LOW | MEDIUM | Auto-split cards | ✅ RESOLVED |
| RISK-004 | P2P statistics inaccurate | MEDIUM | LOW | Clear labels | ✅ MITIGATED |
| RISK-005 | Clock drift abuse | LOW | MEDIUM | Document limitation | ⏭️ DEFERRED |
| RISK-006 | Redemption replay attack | LOW | MEDIUM | Trust-based model | ⏭️ ACCEPTED |
| RISK-007 | Debug logging in production | HIGH | LOW | Phase 6 cleanup | ⬜ PENDING |

---

## 📝 Testing Session Summary

### Session 1: Initial P2P Testing (2026-04-08)
- Identified brand color bug, public key issues
- Found rate limit too restrictive
- Multi-stamp UX problem identified

### Session 2-3: Multi-Stamp Implementation (2026-04-09)
- Hash chain validation failures discovered and fixed
- Multi-stamp architecture implemented (Builds 1-4)
- cardId mismatch resolved (Build 5)

### Session 4-5: Deployment & Overflow (2026-04-10)
- Xcode caching issues resolved
- Version tracking system implemented
- Auto-switching QR modes implemented
- Overflow-to-new-card logic added (Build 8)

### Session 6: Final Polish (2026-04-11)
- Dashboard counter labels clarified (Builds 9-10)
- Redemption scanner QR frame added (Build 11)
- All acceptance criteria validated
- **RESULT:** Phases 3 & 4 COMPLETE

---

## ✅ Current Status

**Build Version:** v0.1.0 (Build 11)  
**Phases Complete:** 0, 1, 2, 3, 4 (67% of project)  
**Core P2P Functionality:** ✅ Working on physical devices  
**Next Phase:** Phase 5 (Multi-Device Configuration)  

**Production Readiness:** Ready for single-device supplier testing and feedback

