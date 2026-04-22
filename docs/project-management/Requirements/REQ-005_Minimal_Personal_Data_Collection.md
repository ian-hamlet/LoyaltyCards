# Requirement: Minimal Personal Data Collection

## ID
REQ-005

## Status
Draft

## Priority
Critical

## Category
Non-Functional (Privacy/Security)

## Description
The system shall collect and store only the minimum personal data necessary to operate the loyalty card functionality. Customer names, email addresses, and phone numbers shall NOT be required or collected unless absolutely necessary for system operation (e.g., mobile wallet integration).

## Rationale
Privacy-first design reduces regulatory compliance burden (GDPR, CCPA), builds customer trust, and aligns with the principle of data minimization. Small businesses should not become custodians of sensitive customer data. The simpler the data model, the lower the security and privacy risks.

## Acceptance Criteria
- [ ] Customer name is NOT required for card issuance or use
- [ ] Customer email is NOT required for card issuance or use
- [ ] Customer phone number is NOT required for card issuance or use
- [ ] System operates with anonymous customer cards
- [ ] Only essential data is collected: supplier branding, card ID, stamp count, transaction timestamps
- [ ] Data collection complies with GDPR data minimization principle
- [ ] System provides data export function if personal data is collected
- [ ] System provides data deletion function (right to be forgotten)

## Dependencies
- REQ-004 (Zero Data Entry Card Issuance)
- REQ-013 (GDPR Compliance)

## Constraints
- May limit future analytics capabilities
- May complicate customer recovery scenarios (lost device)

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Sections 3, 5

## Related Documents
- [Privacy Policy](../../07-Documentation/User/PRIVACY_POLICY.md) (To be created)
- [Data Model](../../01-Design/Database/DATA_MODEL.md) (To be created)

## Notes
- Consider optional customer registration for enhanced features in future
- Anonymous cards should still have unique identifiers
- Transaction history can be maintained without personal identifiers

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
