# Architecture Decision: Peer-to-Peer Data Exchange

## Decision ID
ARCH-001

## Date
2026-03-30

## Status
✅ **ACCEPTED**

## Context

The LoyaltyCards application requires a method to exchange stamp transaction data between supplier devices (issuing stamps) and customer devices (collecting stamps). The key question was whether to use:

1. **Traditional backend architecture** - Central server coordinates all transactions
2. **Peer-to-peer (P2P) architecture** - Direct device-to-device communication
3. **Hybrid approach** - P2P with minimal backend for backup/sync

## Decision

**We will implement a peer-to-peer (P2P) architecture** where stamp transactions occur through direct device-to-device communication with **no backend server required** for core stamping operations.

### Primary Implementation: QR Code Exchange

**The MVP will use QR code exchange as the P2P communication method** because:
- Universal compatibility (100% of smartphones have cameras)
- Simple user experience (scan and done)
- No special hardware requirements
- Works on all iOS and Android versions
- Reliable in various lighting conditions

### Enhanced Implementation: NFC (Future Phase)

NFC tap-to-stamp will be added in a future phase for devices that support it, providing faster "bump" interaction.

### Optional Backup: Encrypted Cloud Storage

Users may optionally enable encrypted backup to their personal cloud storage (iCloud, Google Drive) for data recovery only.

## Rationale

### Why P2P Wins for This Use Case

#### ✅ **Alignment with Requirements**

| Requirement | How P2P Satisfies |
|------------|-------------------|
| **REQ-017**: Cost Minimization | Zero backend infrastructure costs |
| **REQ-005**: Minimal Personal Data | Data stays on device, never transmitted to servers |
| **REQ-006**: Fast Stamp Process | No network latency, instant device-to-device |
| **REQ-011**: Offline Capability | Fully offline operation, no internet required |
| **REQ-013**: GDPR Compliance | Privacy-first, no central data storage |

#### 💰 **Cost Analysis**

| Architecture | Setup Cost | Monthly Cost (1000 users) | Scalability Cost |
|-------------|-----------|--------------------------|-----------------|
| **Backend (Serverful)** | $500-2000 (dev) | $50-200 | Increases with users |
| **Backend (Serverless)** | $0 (free tier) | $10-50 | Increases with transactions |
| **P2P (Local-First)** | $0 | $0 | $0 (no change) |

#### ⚡ **Performance Comparison**

| Architecture | Stamp Time | Network Dependency | Offline Support |
|-------------|-----------|-------------------|-----------------|
| **Backend** | 1-3 sec (network latency) | Required | Limited |
| **P2P** | <1 sec (instant) | None | Full |

#### 🔒 **Security Model**

Instead of relying on backend validation, P2P uses **cryptographic signatures**:

```
Customer Device                    Supplier Device
┌──────────────────┐              ┌──────────────────┐
│ Card Data        │              │ Private Key      │
│ - Card GUID      │◄─────QR──────│ (Creates stamps) │
│ - Public Key     │              │                  │
│ - Stamp Chain    │──────QR─────►│ Validates        │
│                  │              │ Redemptions      │
│ Validates        │              └──────────────────┘
│ Signatures       │
└──────────────────┘

Security: ECDSA P-256 signatures
          Hash chain prevents tampering
          Rate limiting on device
```

## Consequences

### Positive ✅

1. **Zero Infrastructure Costs** - No servers to maintain or pay for
2. **Maximum Privacy** - Data never leaves user devices
3. **Fastest Performance** - No network latency
4. **100% Offline** - Works without internet connection
5. **Infinite Scalability** - Adding users costs nothing
6. **GDPR Simplified** - No central data controller
7. **Simple Deployment** - Just mobile apps, no backend ops

### Negative ❌

1. **No Cross-Device Sync** - Lost phone = lost customer data (mitigated by optional cloud backup)
2. **Limited Analytics** - Supplier insights limited to their device data
3. **Fraud Detection Harder** - No centralized monitoring (mitigated by cryptography)
4. **Device Compatibility** - Must ensure crypto works on older devices
5. **No Customer Recovery** - If customer loses device and has no backup, data is lost

### Mitigations

| Risk | Mitigation |
|------|-----------|
| Lost phone data | Optional encrypted cloud backup to user's personal storage |
| Fraud without backend | Cryptographic signatures, hash chains, rate limiting |
| Limited supplier analytics | Local transaction history with export capability |
| Customer recovery | Education about enabling cloud backup during onboarding |
| Compatibility issues | Use well-tested platform crypto libraries (CryptoKit, Android Keystore) |

## Technical Implementation

### P2P Transaction Flow (QR Code Method)

#### **1. Card Issuance**

```
Supplier App                          Customer App
    │                                      │
    ├──Generate supplier key pair          │
    │  (if first launch)                   │
    │                                      │
    ├──Generate card data:                 │
    │  - GUID (UUID v4)                    │
    │  - Supplier public key               │
    │  - Stamp configuration               │
    │                                      │
    ├──Create QR code                      │
    │                                      │
    │         Show QR Code                 │
    ├─────────────────────────────────────►│
    │                                      │
    │                                      ├──Customer scans
    │                                      ├──Store card locally
    │                                      │  (SQLite)
    │                                      │
    │        Confirmation QR               │
    │◄─────────────────────────────────────┤
    │                                      │
    ├──Log transaction                     │
```

#### **2. Stamping Transaction**

```
Customer App                          Supplier App
    │                                      │
    ├──Customer opens card                 │
    │                                      │
    ├──Generate request QR:                │
    │  - Card GUID                         │
    │  - Current stamp count               │
    │  - Timestamp                         │
    │                                      │
    │         Show QR Code                 │
    ├─────────────────────────────────────►│
    │                                      │
    │                                      ├──Scan & validate
    │                                      ├──Create stamp token:
    │                                      │  {
    │                                      │    cardId,
    │                                      │    stampNumber,
    │                                      │    timestamp,
    │                                      │    previousHash,
    │                                      │    signature
    │                                      │  }
    │                                      │
    │                                      ├──Sign with private key
    │                                      │
    │         Stamp Token QR               │
    │◄─────────────────────────────────────┤
    │                                      │
    ├──Scan stamp QR                       │
    ├──Validate signature                  │
    ├──Check hash chain                    │
    ├──Apply rate limiting                 │
    ├──Update local database               │
    ├──Display confirmation                │
```

### Data Structures

#### **Card Data (Stored on Customer Device)**

```json
{
  "cardId": "550e8400-e29b-41d4-a716-446655440000",
  "supplierId": "CAFE-4567",
  "supplierName": "Joe's Coffee Shop",
  "supplierLogo": "base64_encoded_image",
  "supplierPublicKey": "-----BEGIN PUBLIC KEY-----\nMFkw...",
  "stampsRequired": 7,
  "createdAt": 1743350400000,
  "stamps": [
    {
      "stampNumber": 1,
      "timestamp": 1743350400000,
      "nonce": "a8f5b3c9",
      "previousHash": "0000000000000000...",
      "signature": "MEUCIQDxTz..."
    },
    {
      "stampNumber": 2,
      "timestamp": 1743436800000,
      "nonce": "b9g6c4d0",
      "previousHash": "e3b0c44298fc1c14...",
      "signature": "MEQCIDgPz..."
    }
  ]
}
```

#### **Stamp Token (Exchanged via QR)**

```json
{
  "cardId": "550e8400-e29b-41d4-a716-446655440000",
  "stampNumber": 3,
  "timestamp": 1743523200000,
  "nonce": "c1h7d5e1",
  "previousHash": "f4c2a55398ab7d45...",
  "signature": "MEYCIQC8u..."
}
```

### Cryptographic Security

**Algorithm**: ECDSA with P-256 curve (recommended) or RSA-2048 (alternative)

**Key Generation** (Supplier first launch):
```javascript
// iOS: CryptoKit
let privateKey = P256.Signing.PrivateKey()
let publicKey = privateKey.publicKey

// Android: Android Keystore
KeyPairGenerator keyGen = KeyPairGenerator.getInstance("EC");
KeyPair keyPair = keyGen.generateKeyPair();
```

**Signing** (Supplier creates stamp):
```javascript
const dataToSign = JSON.stringify({
  cardId, stampNumber, timestamp, nonce, previousHash
});
const signature = await supplierPrivateKey.sign(dataToSign);
```

**Verification** (Customer validates stamp):
```javascript
const isValid = await supplierPublicKey.verify(
  signature,
  dataToSign
);
if (!isValid) throw new Error("Invalid stamp signature");
```

**Hash Chain**:
```javascript
const previousHash = stamps.length > 0 
  ? sha256(JSON.stringify(stamps[stamps.length - 1]))
  : "0000000000000000000000000000000000000000000000000000000000000000";
```

## Alternatives Considered

### Alternative 1: Traditional Backend Architecture

**Pros:**
- Centralized data recovery
- Cross-device sync
- Comprehensive analytics
- Fraud detection via pattern analysis
- Customer account management

**Cons:**
- $50-200/month operational costs
- Development complexity (API, database, hosting)
- Network dependency (slower, requires internet)
- Privacy concerns (central data storage)
- GDPR compliance complexity
- Scalability costs increase with users

**Why Rejected:** Conflicts with REQ-017 (cost minimization) and REQ-005 (minimal data collection). Higher complexity for a simple stamping use case.

### Alternative 2: Hybrid (Minimal Backend)

**Pros:**
- Best of both worlds (P2P + backup)
- Optional cloud sync for recovery
- Can add analytics later

**Cons:**
- Still requires backend maintenance
- Network dependency for sync
- Adds complexity for marginal benefit
- Contradicts "free for supplier" goal if backend costs scale

**Why Rejected:** The "optional encrypted backup to personal cloud" approach provides the same recovery benefit without requiring us to operate backend infrastructure.

### Alternative 3: Blockchain/Distributed Ledger

**Pros:**
- Tamper-proof transaction history
- Decentralized trust model
- No central authority

**Cons:**
- Massive complexity overkill
- Poor mobile performance
- High battery/network usage
- Requires cryptocurrency or consensus mechanism
- User experience nightmare

**Why Rejected:** Cryptographic signatures provide the same tamper-proof guarantee without blockchain complexity.

## Implementation Phases

### Phase 1: MVP (QR Code P2P) 🎯
- QR code-based card issuance
- QR code-based stamping
- QR code-based redemption
- Local SQLite storage
- Cryptographic signatures
- Hash chain validation
- Basic transaction history

**Timeline**: 2-3 months development
**Cost**: $0 infrastructure

### Phase 2: Enhanced UX
- NFC tap-to-stamp (where supported)
- Improved QR scanning (continuous scan mode)
- Enhanced visual feedback
- Push notifications (local only, no backend)
- Transaction export (CSV/JSON)

**Timeline**: 1-2 months
**Cost**: $0 infrastructure

### Phase 3: Optional Backup
- Encrypted backup to iCloud/Google Drive
- Restore from backup on new device
- User education on backup importance

**Timeline**: 1 month
**Cost**: $0 (uses user's personal storage)

## Success Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| **Stamp Time** | <3 seconds | QR scan to confirmation |
| **Transaction Success Rate** | >99% | Successful stamp validations |
| **Offline Operation** | 100% | No network required |
| **Storage per Customer** | <5MB | For 50 cards with history |
| **Battery Impact** | <1% per hour | Background crypto operations |
| **Infrastructure Cost** | $0/month | No backend services |

## Related Documents

- [REQ-015: Peer-to-Peer Data Architecture](../../project-management/Requirements/REQ-015_Backend_Data_Storage.md)
- [REQ-010: P2P Data Synchronization](../../project-management/Requirements/REQ-010_Data_Synchronization.md)
- [REQ-020: Security Requirements](../../project-management/Requirements/REQ-020_Security_Requirements.md)
- [REQ-017: Cost Minimization](../../project-management/Requirements/REQ-017_Cost_Minimization.md)

## Approval

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Architecture Owner | [TBD] | 2026-03-30 | APPROVED |
| Security Reviewer | [TBD] | [Pending] | |
| Project Stakeholder | [TBD] | [Pending] | |

---

**Document Owner**: Architecture Team  
**Last Updated**: 2026-03-30  
**Next Review**: After Phase 1 MVP completion
