# Requirement: Data Synchronization

## ID
REQ-010

## Status
Draft

## Priority
Critical

## Category
Technical

## Description
The system shall synchronize loyalty card data between supplier and customer devices using peer-to-peer (P2P) communication. When a supplier stamps or redeems a card, the data transfer occurs directly between devices via QR code exchange, NFC, or Bluetooth. The synchronization shall be immediate during the transaction (device-to-device), with no backend server required.

## Rationale
P2P synchronization provides the fastest, most cost-effective, and most private method of data exchange. By transferring signed stamp tokens directly from supplier to customer device during the transaction, both parties have immediate confirmation without network latency or backend dependencies. This eliminates infrastructure costs and enables fully offline operation.

## Acceptance Criteria
- [ ] Stamp additions transfer directly from supplier device to customer device
- [ ] Card redemptions transfer directly from supplier device to customer device
- [ ] P2P sync completes in under 3 seconds (scan-to-confirmation)
- [ ] Customer sees updated stamp count immediately after transaction
- [ ] Stamp data includes cryptographic signature for verification
- [ ] Customer device validates stamp signature before accepting
- [ ] Failed P2P transfers provide clear error message and retry option
- [ ] Customer can view pending/unconfirmed stamps if transfer incomplete
- [ ] No internet connection required for stamping operation
- [ ] System supports multiple P2P methods: QR code exchange (primary), NFC (enhanced), BLE (future)
- [ ] Duplicate stamp detection prevents double-stamping same transaction
- [ ] Transaction timestamp validated (must be within reasonable time window)

## Dependencies
- REQ-003 (Mobile Platform Support)
- REQ-006 (Fast Stamp Process)
- REQ-011 (Offline Capability)
- REQ-015 (Backend Data Storage) (if backend architecture chosen)

## Constraints
- Must work with zero network connectivity (fully offline P2P)
- Must minimize battery drain from scanning operations
- P2P methods must be widely supported across iOS and Android devices
- NFC availability varies by device (iOS 13+, most Android)
- QR code method must work on all devices as universal fallback

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 4

## Related Documents
- [Architecture Decision: Sync Strategy](../../01-Design/Architecture/DECISION_Sync_Strategy.md) (To be created)
- [Technical Specification: Data Sync](../../01-Design/API/SPEC_Data_Sync.md) (To be created)

## Notes
**P2P Synchronization Flow (QR Code Method):**

1. **Stamping:**
   - Customer opens their card in app
   - Customer shows QR code (contains: cardID, currentStampCount, publicKey)
   - Supplier scans customer QR code
   - Supplier app generates stamp token (cardID, newStampCount, timestamp, signature)
   - Supplier shows QR code with stamp token
   - Customer scans supplier QR code
   - Customer app validates signature and updates local database
   - Both devices confirm transaction with visual/haptic feedback

2. **Redemption:**
   - Customer shows completed card QR code
   - Supplier scans and validates all stamp signatures
   - Supplier generates redemption token (signed)
   - Supplier shows redemption QR code
   - Customer scans and resets card locally

**Security:** Cryptographic signatures prevent fraud without backend validation
**Conflict Resolution:** Supplier device is authoritative source; customer validates but cannot self-stamp

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
