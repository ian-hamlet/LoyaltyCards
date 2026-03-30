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
If backend storage is implemented, the system shall record transaction history for stamp additions, card redemptions, and card issuances. Customers should be able to view their transaction history for a given card. Suppliers should be able to view aggregate transaction data for audit and basic analytics purposes.

## Rationale
Transaction history provides transparency and accountability. Customers can verify stamps and redemptions. Suppliers can audit activity, detect fraud, and gain basic insights into customer behavior without complex analytics systems.

## Acceptance Criteria
- [ ] System records all stamp transactions (date, time, card ID, supplier ID)
- [ ] System records all redemption transactions
- [ ] System records all card issuance transactions
- [ ] Customer can view transaction history for each card
- [ ] Supplier can view transactions for their business
- [ ] Transaction data includes: timestamp, transaction type (stamp/redemption/issuance), card ID
- [ ] Transaction history retained for minimum 1 year
- [ ] Transaction data can be exported (CSV or JSON)
- [ ] Transaction history complies with data privacy requirements

## Dependencies
- REQ-005 (Minimal Personal Data Collection)
- REQ-013 (GDPR Compliance)
- REQ-015 (Backend Data Storage)

## Constraints
- Transaction history increases storage requirements
- Must anonymize/aggregate data to protect customer privacy
- Must define data retention policy

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 5

## Related Documents
- [Database Schema: Transactions](../../01-Design/Database/SCHEMA_Transactions.md) (To be created)
- [US-007](../UserStories/US-007_View_Transaction_History.md) (To be created)

## Notes
- Transaction history enables basic analytics without complex tools
- Suppliers can answer: "How many stamps issued this week?" "How many redemptions this month?"
- Consider privacy: customer transaction history should not expose personal info
- Consider retention policy: indefinite storage vs. rolling deletion (e.g., delete after 2 years)

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
