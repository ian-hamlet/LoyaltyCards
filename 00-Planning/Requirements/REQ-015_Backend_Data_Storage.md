# Requirement: Peer-to-Peer Data Architecture

## ID
REQ-015

## Status
Draft

## Priority
Critical

## Category
Technical

## Description
The system shall implement a peer-to-peer (P2P) data architecture where loyalty card data is stored locally on customer devices and stamp transactions occur through direct device-to-device communication (NFC, Bluetooth, or QR code exchange). An optional minimal cloud backup service may be provided for data recovery only, but shall not be required for core stamping operations.

## Rationale
P2P architecture eliminates backend infrastructure costs, maximizes privacy, enables offline operation, and provides the fastest possible stamping experience. By storing data on customer devices and using cryptographic signatures to prevent fraud, the system can operate without complex backend databases while maintaining security and data integrity. This aligns with the stated preference for device-to-device interaction and cost minimization goals.

## Acceptance Criteria
- [ ] Customer loyalty card data stored in local device database (SQLite or equivalent)
- [ ] Supplier business configuration stored locally on supplier device
- [ ] Stamp transactions occur via direct P2P communication (no backend required)
- [ ] P2P communication supports: QR code exchange (MVP), NFC tap, or Bluetooth Low Energy
- [ ] Cryptographic signatures used to authenticate stamp transactions and prevent fraud
- [ ] Each stamp includes: digital signature, timestamp, supplier ID, previous stamp hash (chain)
- [ ] Customer device validates all stamp signatures before accepting
- [ ] Local transaction history maintained on both customer and supplier devices
- [ ] Optional encrypted cloud backup for customer data recovery (iCloud, Google Drive, or minimal backend)
- [ ] System operates fully offline (stamping, viewing, redemption)
- [ ] Conflict resolution strategy defined for edge cases
- [ ] Solution scales without backend infrastructure costs

## Dependencies
- REQ-010 (Data Synchronization)
- REQ-013 (GDPR Compliance)
- REQ-017 (Cost Minimization)

## Constraints
- Must minimize or eliminate cost for suppliers and customers
- Must comply with data privacy regulations
- Must be maintainable by small development team

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Sections 4, Notes

## Related Documents
- [Architecture Decision: Data Storage](../../01-Design/Architecture/DECISION_Data_Storage.md) (To be created)
- [Database Schema](../../01-Design/Database/SCHEMA.md) (To be created if backend chosen)
- [API Specification](../../01-Design/API/API_SPEC.md) (To be created if backend chosen)

## Notes
Discovery mentions:
- "Ideally if the applications can interact directly without backend storage that would be better"
- "Almost stored on the customer's device"
- "If one could use the customer device for secure storage, the supplier device simply bumps/scans and securely increments the stamp counter"

**P2P Architecture Decision:**
After evaluation, P2P is viable and preferred for this use case:

**Phase 1 (MVP):** QR Code Exchange
- Customer shows QR code with card ID + public key
- Supplier scans, generates signed stamp token
- Supplier shows QR code with stamp token
- Customer scans and validates signature
- Advantage: Universal compatibility, no specialized hardware

**Phase 2:** NFC Enhancement (where supported)
- Tap-to-stamp for devices with NFC
- Faster UX, same cryptographic security
- Fallback to QR for unsupported devices

**Phase 3:** Optional Cloud Backup
- Customer can enable encrypted backup to personal cloud storage
- For device loss/replacement recovery only
- No impact on day-to-day stamping operations

**Security Model:**
- Supplier has cryptographic key pair (private key secure on device)
- Each stamp signed with supplier private key
- Customer verifies with supplier public key (obtained at card issuance)
- Hash chain prevents tampering with stamp history
- Rate limiting on customer device prevents abuse

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
