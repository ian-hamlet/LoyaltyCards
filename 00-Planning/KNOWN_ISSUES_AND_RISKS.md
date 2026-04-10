# Known Issues and Risks

**Document Version:** 1.1  
**Created:** 2026-04-08  
**Last Updated:** 2026-04-09

**CRITICAL ISSUES FOUND IN TESTING (2026-04-09):**

## ✅ Issue #5: Stamp Chain Validation Failing (FIXED)

**Identified:** 2026-04-09 (Physical Device Testing Session 2)  
**Status:** ✅ FIXED  
**Priority:** WAS CRITICAL - NOW RESOLVED

**Problem:**
When adding a second stamp, customer app showed **"Previous hash mismatch - stamp chain broken"** error.

**Root Cause:**
- Supplier was generating stamp token with `previousHash: 'prev_hash_placeholder'`
- Customer expected `previousHash` to match the previous stamp's signature
- Hash chain validation failed on second and subsequent stamps

**Fix Applied (2026-04-09):**

1. **Updated `CardStampRequestToken`** model to include `lastStampHash` field
2. **Customer app** now retrieves last stamp's signature and includes it in QR token
3. **Supplier app** uses customer's provided hash instead of placeholder
4. **Proper cryptographic chain** now maintained
5. **Added QR refresh** - Customer must regenerate QR after each stamp (important!)

**Code Changes:**
- `shared/lib/models/qr_tokens.dart`: Added `lastStampHash` field
- `customer_app/lib/services/qr_token_generator.dart`: Changed to async, fetches last stamp
- `customer_app/lib/screens/customer/qr_display_screen.dart`: Made stateful, added refresh button
- `supplier_app/lib/screens/supplier/supplier_stamp_card.dart`: Use `token.lastStampHash`
- Added debug logging to track hash mismatches

**Important Workflow:**
1. Customer shows stamp request QR to supplier
2. Supplier scans and generates stamp token
3. Customer scans stamp token → stamp added ✓
4. **Customer MUST tap refresh (⟳) before requesting next stamp**
5. Customer shows fresh QR for next stamp

**Why Refresh is Needed:**
The stamp request QR contains the customer's current state (last stamp hash). After adding stamp #1, the QR still has stamp #0's hash. Customer must regenerate the QR so it contains stamp #1's hash for the next request.

**Added UI Hints:**
- Orange info box reminds customer to refresh QR
- Refresh icon in AppBar (top right)
- Debug logging shows hash values for troubleshooting

**Testing:**
- ✅ First stamp works (empty hash)
- ✅ Second stamp works after QR refresh
- ✅ Third+ stamps work with proper workflow
- ⚠️ Fails if customer forgets to refresh QR (by design - shows old state)

**Rebuild Required:** Both customer and supplier apps

---

## ✅ Issue #6: Supplier Statistics Improved

**Identified:** 2026-04-09 (Physical Device Testing Session 2)  
**Status:** ✅ IMPROVED WITH PRACTICAL METRICS  
**Priority:** RESOLVED

**Original Problem:**
Supplier app couldn't track if customers successfully received stamps due to P2P architecture.

**Solution Implemented (2026-04-09):**

Instead of trying to track what we can't know, we track actionable metrics:

1. **"QRs Generated"** (formerly "Cards Issued")
   - Increments each time supplier generates a card issuance QR
   - Represents times supplier offered a card to customers
   - Tracked in `issued_cards` table

2. **"Active Cards"** (NEW METRIC)
   - Counts unique card IDs that have requested stamps
   - Logged when supplier scans a stamp request (even if token fails later)
   - Represents number of unique customers using the loyalty program
   - Uses `COUNT(DISTINCT card_id)` from `stamp_history`

**What We Track:**
- ✅ Supplier actions (QR generations, stamp requests scanned)
- ✅ Unique active customers (distinct cards seen)
- ✅ Honest labels that match what's actually measured

**What We DON'T Track:**
- ❌ If customer actually scanned the issuance QR
- ❌ If customer successfully validated stamp token
- ❌ If stamp was added to customer's wallet

**Why This Works:**
These metrics answer business questions:
- "How many times did I offer cards?" → QRs Generated
- "How many unique customers am I serving?" → Active Cards
- "Am I growing my customer base?" → Active Cards trend

**Code Changes:**
- Added `getActiveCardCount()` method to `BusinessRepository`
- Added `logCardActivity()` to track when cards request stamps
- Updated home screen to show both metrics with explanatory text

**P2P Limitation Acknowledged:**
Perfect tracking requires server architecture. These metrics are "proxy indicators" that are useful and honest about what they measure.

---

# Original Issues

**Document Version:** 1.0  
**Created:** 2026-04-08  
**Last Updated:** 2026-04-08

This document tracks known issues, technical debt, and risks identified during development and testing.

---

## 🔴 Critical UX Issues

### Issue #1: Multiple Stamps UX Problem

**Identified:** 2026-04-08 (Physical Device Testing)  
**Status:** NEEDS DESIGN REVIEW  
**Priority:** HIGH

**Problem:**
The current digital stamping process is **slower and more cumbersome** than the physical card model it's replacing:

- **Physical Card:** Supplier can stamp 4 times instantly for 4 coffees (2 seconds total)
- **Digital Card:** Requires 4 separate scan cycles:
  1. Customer shows card QR
  2. Supplier scans
  3. Supplier shows stamp token QR
  4. Customer scans
  5. Repeat 4 times = ~40-60 seconds total (with 1-second rate limit between each)

**Impact:**
- Poor user experience for bulk purchases
- Slower than physical cards defeats the purpose
- May discourage adoption by businesses

**Current Workaround:**
- Rate limit reduced to 1 second (minimal protection against accidental duplicates)
- Allows rapid sequential stamping but still requires 4 full scan cycles

**Proposed Solutions for Future:**

1. **Option A: "Add Multiple Stamps" Feature**
   - Supplier can specify quantity (e.g., "Add 4 stamps")
   - Single QR token contains multiple stamps
   - Requires crypto chain validation for batch stamps
   - **Complexity:** Medium
   - **Benefit:** Matches physical card UX

2. **Option B: Bulk Stamp Mode**
   - Supplier enters "bulk mode" 
   - Can scan card multiple times rapidly
   - Generates single compound token at the end
   - **Complexity:** Medium-High
   - **Benefit:** Most flexible

3. **Option C: Quick Add Button**
   - After first stamp, show "Add Another?" button
   - No QR scanning required for subsequent stamps
   - Timestamp-based session (e.g., 30 seconds to add more)
   - **Complexity:** Low
   - **Benefit:** Simple, quick to implement

4. **Option D: Supplier-Side Counter**
   - Supplier app has "+1" button instead of scanning each time
   - Customer scans once at start, again at end
   - Supplier generates batch token
   - **Complexity:** Medium
   - **Benefit:** Minimal customer interaction

**Recommended Approach:**
- **Short-term:** Keep 1-second rate limit, document limitation
- **Phase 5:** Implement Option C (Quick Add Button) - easiest path
- **Phase 6:** Consider Option A if needed for production

**Related Requirements:**
- REQ-006: Fast Stamp Process (currently not meeting requirement for bulk purchases)

---

## ⚠️ Technical Debt

### Issue #2: Card Issuance Statistics Not Tracked

**Identified:** 2026-04-08  
**Status:** DOCUMENTED  
**Priority:** LOW

**Problem:**
In the P2P (Peer-to-Peer) model, the supplier app generates a card issuance QR code but has no way to know if/when the customer actually scans and picks up the card.

**Impact:**
- "Cards Issued" statistic on supplier home screen always shows 0
- No way to track card pickup rate
- Can't measure conversion (QR generated → card added)

**Solution Options:**
1. Accept limitation (P2P model trade-off)
2. Add optional callback mechanism (customer app pings supplier)
3. Change label to "Cards (P2P - not tracked)"

**Current:** Using label "Cards (P2P)" to indicate tracking limitation

---

## 🔍 Items for Future Risk Assessment

### Rate Limiting Strategy

**Current Implementation:**
- 1 second between stamps (prevents accidental duplicates only)
- No business-level rate limits
- No daily/weekly caps

**Potential Risks:**
1. **Abuse:** Customer could rapidly collect stamps if they hack the timing
2. **Business Fraud:** Collusion between customer and rogue employee
3. **Gaming:** Single customer getting unlimited stamps

**Mitigation Considerations:**
- Add business-configurable daily stamp limits
- Implement anomaly detection (e.g., 20 stamps in 5 minutes)
- Add audit trail with timestamp clustering detection
- Consider requiring supplier authentication for high-frequency stamping

**Timeline:** Review in Phase 5 (Security & Optimization)

---

### Cryptographic Chain Validation

**Current Implementation:**
- Basic signature verification working
- Previous hash chain concept implemented but using placeholder
- No verification of stamp sequence integrity beyond signature

**Known Gaps:**
1. Previous hash is placeholder ('prev_hash_placeholder')
2. No detection of missing stamps in chain
3. No prevention of stamp reordering

**Risk Level:** Medium-Low (signatures prevent forgery, but chain integrity not enforced)

**Timeline:** Address in Phase 4 (Supplier Operations completion)

---

## 📝 Testing Session Findings

### Session 1: Initial P2P Testing (2026-04-08)

**Issues Found and Fixed:**
- ✅ Brand color bug (`##` → `#`)
- ✅ Public key placeholder instead of actual key
- ✅ Missing settings/reset functionality
- ✅ Statistics not updating after stamp issuance
- ✅ Rate limit too restrictive (1 hour → 1 second)

**Outstanding:**
- 🔴 Multiple stamps UX problem (see Issue #1 above)

---

## 🎯 Action Items

**Immediate (Phase 3 completion):**
- [x] Fix rate limit to 1 second
- [x] Document multiple stamps UX issue
- [ ] Complete Phase 3 testing with new rate limit

**Phase 4:**
- [ ] Implement proper previous hash chain (remove placeholder)
- [ ] Add stamp sequence validation

**Phase 5:**
- [ ] Design and implement "Quick Add" stamping feature (Option C)
- [ ] Add rate limiting analytics/monitoring
- [ ] Review security implications of 1-second rate limit

**Phase 6:**
- [ ] Consider bulk stamping features if UX testing shows need
- [ ] Implement business-level stamping policies (if needed)

---

## 📊 Risk Register

| Risk ID | Description | Likelihood | Impact | Mitigation | Owner |
|---------|-------------|------------|--------|------------|-------|
| RISK-001 | Multiple stamps UX slower than physical cards | HIGH | HIGH | Implement Quick Add feature (Phase 5) | Product |
| RISK-002 | 1-second rate limit insufficient for abuse prevention | MEDIUM | MEDIUM | Monitor in beta, add analytics | Security |
| RISK-003 | Stamp chain integrity not fully validated | MEDIUM | LOW | Implement proper hash chain (Phase 4) | Engineering |
| RISK-004 | Card pickup rate unknown (P2P limitation) | LOW | LOW | Accept or add optional tracking | Product |

---

## 🔄 Review Schedule

- **Weekly:** Review new issues from testing
- **Phase Completion:** Risk assessment before moving to next phase
- **Pre-Production:** Full security audit and UX testing with real users

---

**Next Review:** End of Phase 3 (Physical Device Testing completion)
