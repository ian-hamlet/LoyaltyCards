# Requirement: Security Requirements

## ID
REQ-020

## Status
Draft

## Priority
Critical

## Category
Non-Functional (Security)

## Description
The system shall implement security measures to protect user data, prevent fraud, and secure peer-to-peer communications between supplier and customer mobile devices. Security shall leverage cryptographic signatures, mobile device built-in security features, and tamper-proof hash chains to prevent unauthorized stamp additions without requiring backend validation.

## Rationale
Although minimal personal data is collected, the system handles transactional data representing real value (free products/services). In a P2P architecture without backend validation, cryptographic security is critical to prevent: unauthorized stamp additions, card duplication, redemption fraud, stamp tampering, and supplier impersonation. Trust is essential for adoption, and the security model must be robust despite operating offline.

## Acceptance Criteria

**P2P Cryptographic Security:**
- [ ] Each supplier has unique cryptographic key pair (ECDSA P-256 or RSA-2048)
- [ ] Supplier private key stored securely in device keychain/keystore (never transmitted)
- [ ] Supplier public key embedded in customer card at issuance
- [ ] Each stamp transaction digitally signed by supplier private key
- [ ] Customer device validates stamp signature before accepting (using supplier public key)
- [ ] Invalid signatures rejected immediately with error message
- [ ] Stamp data includes: cardID, supplierID, timestamp, stampNumber, previousStampHash, signature
- [ ] Hash chain links all stamps (each stamp references hash of previous stamp)
- [ ] Tampering with any stamp breaks the hash chain and is detectable

**Device-Level Security:**
- [ ] Supplier app requires device authentication (PIN, biometric, or pattern lock)
- [ ] Supplier private key only accessible after device authentication
- [ ] Customer card data encrypted at rest in local SQLite database
- [ ] Supplier business data encrypted at rest on supplier device
- [ ] Data isolated per-app using OS-level sandboxing

**Fraud Prevention:**
- [ ] Rate limiting on customer device: max 1 stamp per supplier per hour
- [ ] Timestamp validation: stamps must be within ±24 hours of current time
- [ ] Duplicate stamp detection: reject stamps with identical cardID + stampNumber
- [ ] Nonce/unique ID in each stamp to prevent replay attacks
- [ ] QR codes expire after 60 seconds (timestamp-based)
- [ ] Card GUID cryptographically random (UUID v4) to prevent guessing

**Security Testing:**
- [ ] Penetration testing of P2P communication
- [ ] Cryptographic implementation reviewed (no custom crypto)
- [ ] Security vulnerabilities regularly assessed (automated scanning)
- [ ] Third-party dependencies kept updated with security patches

## Dependencies
- REQ-003 (Mobile Platform Support)
- REQ-006 (Fast Stamp Process)
- REQ-009 (QR/Barcode Scanning)
- REQ-013 (GDPR Compliance)
- REQ-015 (Backend Data Storage)

## Constraints
- Security measures must not significantly impact performance (< 100ms overhead for signature verification)
- Cryptographic operations must work on older mobile devices (2-3 years old)
- Must balance security with user experience simplicity
- Must work within mobile platform security sandboxes
- Cannot rely on backend validation (all security must work offline)

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 5

## Related Documents
- [Security Architecture](../../01-Design/Architecture/SECURITY_ARCHITECTURE.md) (To be created)
- [Threat Model](../../07-Documentation/Technical/THREAT_MODEL.md) (To be created)
- [Security Testing Plan](../../04-Tests/Integration/PLAN_Security_Testing.md) (To be created)

## Notes
Discovery states: "Use existing mobile security model to secure the supplier application"

**P2P Security Model:**

1. **Threat: Unauthorized Stamping**
   - Mitigation: Only supplier with private key can create valid stamps
   - Customer device validates signature cryptographically

2. **Threat: Card Duplication**
   - Mitigation: Each card has unique GUID; supplier tracks recently stamped cards
   - Rate limiting prevents rapid stamping of duplicated cards

3. **Threat: Stamp Tampering**
   - Mitigation: Hash chain links stamps; modifying any stamp breaks chain
   - Signature verification ensures stamp hasn't been altered

4. **Threat: Replay Attacks**
   - Mitigation: Timestamps prevent old stamps from being reused
   - Nonce/unique stamp ID prevents duplicate submission

5. **Threat: Supplier Impersonation**
   - Mitigation: Supplier public key embedded in card at issuance
   - Only that specific supplier can create valid stamps for that card

6. **Threat: Lost/Stolen Supplier Device**
   - Mitigation: Private key requires device authentication (PIN/biometric)
   - Key rotation capability if device compromised

**Cryptographic Libraries:**
- iOS: CryptoKit (native Apple framework)
- Android: Jetpack Security / Android Keystore
- Cross-platform: SubtleCrypto (Web Crypto API), libsodium

**Example Stamp Structure:**
```json
{
  "cardId": "550e8400-e29b-41d4-a716-446655440000",
  "supplierId": "CAFE-4567",
  "stampNumber": 5,
  "timestamp": 1743350400000,
  "nonce": "a8f5b3c9",
  "previousHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "signature": "MEUCIQDxTz... (base64 encoded ECDSA signature)"
}
```

**OWASP Mobile Top 10 Compliance:**
- M1: Improper Platform Usage - Use platform keychains/keystores ✓
- M2: Insecure Data Storage - Encrypt local databases ✓
- M3: Insecure Communication - P2P with signature validation ✓
- M4: Insecure Authentication - Device-level auth required ✓
- M5: Insufficient Cryptography - Use proven libraries, strong algorithms ✓
- M9: Reverse Engineering - Code obfuscation for production builds

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
