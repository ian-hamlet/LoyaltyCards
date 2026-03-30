# Requirement: Transaction History

## ID
REQ-018

## Status
Draft

## Priority
Medium

## Category
Functional

## Description
The system shall record transaction history locally on both customer and supplier devices for stamp additions, card redemptions, and card issuances. Customers can view their transaction history for each card stored on their device. Suppliers can view aggregate transaction data on their device for audit and basic analytics purposes. All transaction data is stored locally with optional encrypted cloud backup.

## Rationale
Transaction history provides transparency and accountability. Local storage of transaction history enables customers to verify stamps and redemptions, and allows suppliers to audit activity and gain basic insights without requiring backend infrastructure. Each transaction record includes cryptographic proof (signature), creating an immutable audit trail.

## Acceptance Criteria
- [ ] Customer device records all stamp transactions in local database (SQLite)
- [ ] Customer device records all redemption transactions locally
- [ ] Customer device records card issuances (pickup history)
- [ ] Supplier device records all stamps issued, redemptions processed
- [ ] Customer can view transaction history for each card in app
- [ ] Supplier can view transaction statistics: stamps issued today/week/month, redemptions processed
- [ ] Transaction data includes: timestamp, transaction type, card ID, supplier ID, cryptographic signature
- [ ] Transaction history retained locally for minimum 1 year (configurable)
- [ ] Transaction data can be exported from device (CSV or JSON)
- [ ] Transaction signatures can be verified offline for audit purposes
- [ ] Transaction history complies with data privacy requirements (no personal data)
- [ ] Optional: Transaction history backed up to user's personal cloud (encrypted)

## Dependencies
- REQ-005 (Minimal Personal Data Collection)
- REQ-013 (GDPR Compliance)
- REQ-015 (Backend Data Storage)

## Constraints
- Transaction history increases local device storage requirements (minimal: ~1KB per transaction)
- Must anonymize/aggregate data to protect customer privacy (no personal identifiers)
- Must define data retention policy for local storage
- Device storage limits may require pruning old transactions (keep most recent year)
- Supplier analytics limited to data visible on their device (no cross-supplier insights)

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 5

## Related Documents
- [Database Schema: Transactions](../../01-Design/Database/SCHEMA_Transactions.md) (To be created)
- [US-007](../UserStories/US-007_View_Transaction_History.md) (To be created)

## Notes
**Local Transaction History Benefits:**
- No backend infrastructure or costs required
- Complete privacy - data never leaves device unless user explicitly exports/backs up
- Offline access to full transaction history
- Cryptographic signatures provide tamper-proof audit trail
- Supplier analytics available immediately without waiting for backend sync

**Storage Estimates:**
- Average transaction record: ~500 bytes (including signature)
- 1000 transactions ≈ 500KB storage
- 1 year for active customer ≈ 100-200 transactions ≈ 100KB
- Minimal impact on device storage

**Supplier Insights (Device-Level):**
- Stamps issued: today, this week, this month, all time
- Redemptions processed: same time breakdowns
- Average stamps-to-redemption time
- Busiest transaction times/days
- All computed locally from device database

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
