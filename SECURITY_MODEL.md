# Security Model & Risk Documentation

**LoyaltyCards v0.2.0**  
**Last Updated:** April 17, 2026

---

## Overview

LoyaltyCards uses a **dual-mode architecture** designed to balance security, privacy, and ease-of-use for different business needs. This document explains the security model and intentional design decisions.

---

## 🔐 Security Architecture

### Dual Operation Modes

The application offers two distinct operation modes, each with different security profiles:

1. **Simple Mode** - Trust-based, minimal friction
2. **Secure Mode** - Cryptographically verified, maximum security

Businesses choose their mode during initial setup based on their risk tolerance and reward value.

---

## 🟦 Simple Mode Security Model

### Design Philosophy

**Simple Mode is INTENTIONALLY trust-based** - it prioritizes ease-of-use and speed over cryptographic verification. This is **not a vulnerability** - it's a **conscious design decision** for specific use cases.

### Intended Use Cases

✅ **Suitable for:**
- Low-value rewards (free coffee, 10% discount)
- Established customer relationships (regular customers)
- Face-to-face transactions (supplier verifies customer identity)
- Small businesses where trust is expected
- Situations where speed is critical (busy coffee shop rush)

❌ **NOT suitable for:**
- High-value rewards ($50+ gift cards, expensive items)
- Anonymous customers
- Remote/online redemptions
- Situations requiring audit trails for accounting

### Trust Model

Simple Mode operates on a **social trust model** similar to physical stamp cards:

```
┌─────────────────────────────────────────────────────────┐
│  PHYSICAL STAMP CARD                                    │
│  ✓ Customer can self-stamp if they have the stamp      │
│  ✓ Customer can forge stamps with similar stamp        │
│  ✓ Supplier verifies by visual inspection              │
│  ✓ Face-to-face interaction provides accountability    │
└─────────────────────────────────────────────────────────┘
                          ↓ Digital Equivalent
┌─────────────────────────────────────────────────────────┐
│  SIMPLE MODE - LOYALTYCARDS                             │
│  ✓ Customer can self-redeem completed cards            │
│  ✓ Customer marks card as "redeemed" locally           │
│  ✓ Supplier verifies by checking stamp history         │
│  ✓ Face-to-face redemption provides accountability     │
└─────────────────────────────────────────────────────────┘
```

**Key Insight:** Physical stamp cards have the same "vulnerabilities" - they rely on trust, visual verification, and social accountability. Simple Mode digitizes this existing trust model.

---

## 🛡️ Simple Mode Security Mitigations

While Simple Mode is trust-based, it includes **several built-in mitigations** to detect and prevent abuse:

### 1. **Visible Stamp History with Timestamps**

Every stamp includes a **date and time** when it was collected:

```
Stamp History:
✓ Stamp 1 - Apr 15, 2026 9:23 AM
✓ Stamp 2 - Apr 15, 2026 9:24 AM  ⚠️ SUSPICIOUS (1 minute apart)
✓ Stamp 3 - Apr 16, 2026 2:15 PM
✓ Stamp 4 - Apr 17, 2026 10:05 AM
```

**Supplier Visual Verification:**
- Supplier can **quickly scan** the stamp history
- **Abnormal patterns** are immediately visible:
  - Multiple stamps within seconds/minutes (fraud)
  - Stamps on closed days (e.g., Sunday for business closed Sunday)
  - Unrealistic number of stamps per day (10 stamps in one day for a weekly customer)

**Real-World Analogy:** Like a cashier glancing at a physical stamp card and noticing "this looks very fresh for supposedly 6 months old"

### 2. **Redemption Date Verification**

When a customer redeems a card, the **exact date and time** are permanently recorded:

```
Card Redeemed!
🕐 10:45 AM
📅 17/4/2026
```

**Supplier Workflow:**
1. Customer shows "Card Redeemed" screen
2. Supplier checks **redemption date matches today**
3. Supplier verifies against their records (recent purchase)
4. Supplier provides reward

**Prevents:**
- Customer showing old redemption from weeks ago
- Customer redeeming same card multiple times (date won't change)
- Customer pre-redeeming cards for future visits

### 3. **Rate Limiting (5-Second Cooldown)**

Simple Mode enforces a **5-second cooldown** between stamps:

```dart
// Rate limit prevents rapid duplicate stamps
const stampRateLimitMs = 5000; // 5 seconds
```

**Prevents:**
- Accidental double-scans (supplier scans QR twice by mistake)
- Rapid abuse (customer can't scan 10 times in a row)

**Note:** This is a **speed bump**, not a security wall. A determined attacker could wait 5 seconds between scans, but:
- It slows down abuse significantly
- Most fraud is opportunistic, not planned
- It prevents honest mistakes

### 4. **Face-to-Face Accountability**

Simple Mode assumes **physical presence** during stamping:

- Customer must be **physically present** to receive stamp
- Supplier sees customer's face (social accountability)
- Most customers are **repeat customers** (reputation matters)
- Fraudulent behavior risks being **banned from business**

**Risk Mitigation:**
- Unlikely for a regular customer to risk relationship over a free coffee
- Business can recognize suspicious behavior patterns
- Social dynamics discourage fraud

### 5. **Automatic New Card Creation**

After redemption, a **new empty card** is auto-created:

```
Old Card: REDEEMED (10/10 stamps)
New Card: 0/10 stamps (ready for next loyalty cycle)
```

**Prevents:**
- Customer "un-redeeming" old cards
- Customer modifying redemption history
- Data integrity maintained (old card immutable)

---

## ⚠️ Simple Mode Known Limitations

These are **accepted risks** for businesses choosing Simple Mode:

### L-001: Self-Redemption (By Design)

**Limitation:** Customer can mark their own card as "redeemed" without supplier confirmation.

**Why Accepted:**
- Supplier **must still physically verify** redemption date before giving reward
- Same trust model as physical punch cards
- Speed and simplicity outweigh risk for low-value rewards

**Mitigation:**
- Supplier checks redemption timestamp (must be today)
- Supplier verifies stamp history looks legitimate
- Face-to-face interaction provides accountability

**Business Decision:** If this risk is unacceptable, **use Secure Mode instead**.

### L-002: No Cryptographic Verification

**Limitation:** Stamps are not cryptographically signed - customer could theoretically forge stamps.

**Why Accepted:**
- Speed: No signature verification (instant stamping)
- Simplicity: No key management required
- Trust model: Similar to physical cards (can be forged too)

**Mitigation:**
- Timestamp verification reveals suspicious patterns
- Reputation/relationship with regular customers
- Low reward value makes fraud not worthwhile

**Business Decision:** For high-value rewards, **Secure Mode is mandatory**.

### L-003: Device Time Manipulation

**Limitation:** Customer could change device clock to bypass rate limits or manipulate timestamps.

**Why Accepted:**
- Requires technical knowledge (most customers won't attempt)
- Timestamps are **visible to supplier** (obviously wrong dates are flagged)
- Supplier can reject cards with suspicious timestamps

**Mitigation:**
- Supplier visual verification of dates
- Obvious clock manipulation is detectable (stamps from "future")
- For businesses concerned about this, **use Secure Mode**

---

## 🔒 Secure Mode Security Model

### Design Philosophy

**Secure Mode uses cryptographic verification** to ensure every stamp is legitimate and issued by the authorized supplier.

### Security Features

✅ **Cryptographic Signatures**
- Each stamp signed with supplier's private key (ECDSA secp256r1)
- Customer app verifies signature with supplier's public key
- Impossible to forge stamps without private key

✅ **Hash Chain Integrity**
- Stamps linked in blockchain-like chain
- Each stamp includes hash of previous stamp
- Tampering with any stamp breaks entire chain

✅ **Timestamp Validation**
- QR codes expire (2-5 minutes)
- Prevents screenshot/replay attacks within window

✅ **Two-Step Redemption**
- Customer shows redemption QR to supplier
- Supplier issues redemption confirmation token
- Customer scans confirmation to complete redemption
- Supplier maintains full control over reward distribution

### Suitable For

- High-value rewards ($20+)
- Businesses requiring audit trails
- Compliance/regulatory requirements
- Situations where fraud risk is high

---

## 🎯 Mode Selection Guidance

| Factor | Simple Mode | Secure Mode |
|--------|-------------|-------------|
| **Reward Value** | < $10 | > $10 |
| **Customer Type** | Regulars | Anyone |
| **Speed Priority** | Critical | Moderate |
| **Fraud Risk** | Low | High |
| **Setup Complexity** | Minimal | Moderate |
| **Key Management** | None | Required |

### Decision Framework

**Choose Simple Mode if:**
- ✅ Rewards are low-value (coffee, small discounts)
- ✅ You trust your customers (regular clientele)
- ✅ Speed is critical (busy environment)
- ✅ Visual verification is acceptable

**Choose Secure Mode if:**
- ✅ Rewards are high-value ($20+)
- ✅ You need cryptographic proof of stamps
- ✅ Audit trails are required
- ✅ You want maximum fraud prevention

**Can't Decide?**
- Start with Simple Mode for initial pilot
- Monitor for abuse patterns
- Switch to Secure Mode if needed (keys generated on demand)

---

## 📊 Security Comparison

| Security Feature | Simple Mode | Secure Mode |
|------------------|-------------|-------------|
| Cryptographic Signatures | ❌ No | ✅ Yes (ECDSA) |
| Stamp Forgery Prevention | ⚠️ Social | ✅ Cryptographic |
| Redemption Control | ⚠️ Customer | ✅ Supplier |
| Hash Chain Integrity | ❌ No | ✅ Yes |
| QR Expiration | ❌ No | ✅ 2-5 min |
| Rate Limiting | ✅ 5 sec | ✅ 5 sec |
| Timestamp Tracking | ✅ Yes | ✅ Yes |
| Supplier Verification Required | ✅ Visual | ✅ Cryptographic |
| Setup Complexity | ⭐ Low | ⭐⭐⭐ Moderate |
| Stamping Speed | ⚡⚡⚡ Instant | ⚡⚡ Fast |

---

## 🔐 Additional Security Measures (Both Modes)

### V-002 Mitigation: Private Key Protection

**Implementation (Build 20):**
- **Face ID / Touch ID / Passcode** required before:
  - Viewing recovery backup QR code
  - Generating device clone QR code
- Prevents unauthorized access to private keys if device left unlocked

**Rationale:**
- Recovery/clone QR codes contain **private keys** (Secure Mode)
- Unauthorized export could enable stamp forgery
- Biometric auth adds critical protection layer

**User Experience:**
```
User taps "Recovery Backup"
  ↓
System prompts: "Authenticate with Face ID to view recovery backup"
  ↓
User authenticates
  ↓
QR code displayed
```

### Device Security Assumptions

**Required:**
- ✅ Device passcode/biometric lock enabled
- ✅ Device not jailbroken (iOS security model intact)
- ✅ Supplier protects physical device access

**Not Required:**
- ❌ Network connectivity (works offline)
- ❌ Cloud backups (local storage only)
- ❌ App Store updates (independent operation)

---

## 📋 Security Audit Log

| Issue | Severity | Status | Resolution |
|-------|----------|--------|------------|
| V-001: Simple Mode Self-Redemption | LOW* | BY DESIGN | Documented + mitigations explained |
| V-002: Private Key Extraction | CRITICAL | ✅ FIXED | Biometric auth required (Build 20/21) |
| V-003: QR Screenshot Reuse | HIGH | ✅ VERIFIED | Database PK prevents duplication |
| V-004: Time Manipulation | HIGH | ✅ VERIFIED | Supplier visual verification |
| V-005: Multi-Device Duplication | HIGH | ✅ FIXED | Device tracking + warnings (Build 21) |
| V-006: Device Storage Limits | LOW | DOCUMENTED | User responsibility in TOS |
| V-007: Recovery Backup Expiration | LOW | DEFERRED | Future enhancement (backlog) |
| V-008: QR Entropy / Guessing | MEDIUM | DEFERRED | Requires formal analysis |
| V-009: Card Revocation Limitations | LOW | BY DESIGN | Documented architectural limitation |

**Note:** Items marked "BY DESIGN" are intentional architectural decisions, not security bugs.

**Full Assessment:** See [VULNERABILITIES.md](VULNERABILITIES.md) for comprehensive security vulnerability assessment.

---

## 🎓 Summary

**Simple Mode:**
- Trust-based by design (like physical stamp cards)
- Multiple mitigations prevent common abuse
- Suitable for low-value rewards and trusted customers
- Visual verification by supplier is expected

**Secure Mode:**
- Cryptographically verified
- Maximum fraud prevention
- Suitable for high-value rewards
- Additional complexity justified by security needs

**Both modes are production-ready** - the choice depends on business requirements and risk tolerance.

---

**Questions?** See [USER_GUIDE.md](../07-Documentation/USER_GUIDE.md) for operational guidance.
