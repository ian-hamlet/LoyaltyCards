# Requirement: Zero Data Entry Card Issuance

## ID
REQ-004

## Status
Draft

## Priority
High

## Category
Functional

## Description
The system shall enable suppliers to issue new loyalty cards to customers with zero manual data entry. Card generation and transfer to customer device should be accomplished through a simple bump/tap or scan interaction.

## Rationale
Speed and simplicity are critical in checkout/till environments. Manual data entry (phone numbers, email addresses, names) creates friction, slows down the checkout process, and collects unnecessary personal data. The system should be as simple as handing a customer a physical card.

## Acceptance Criteria
- [ ] New card generation requires no manual text input from supplier
- [ ] New card generation requires no manual text input from customer
- [ ] Card transfer can be completed via device bump/tap (NFC) or scan (QR code)
- [ ] Card appears in customer application immediately after pickup
- [ ] System auto-generates unique card identifier
- [ ] Process completes in under 5 seconds
- [ ] No customer account creation required
- [ ] No customer personal data (name, email, phone) collected during issuance

## Dependencies
- REQ-002 (Two-Actor System)
- REQ-003 (Mobile Platform Support)
- REQ-005 (Minimal Personal Data Collection)
- REQ-009 (QR/Barcode Scanning)

## Constraints
- Must work reliably in busy retail environment
- Should handle intermittent network connectivity
- Must be intuitive for first-time users

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 3 (Prioritized List)

## Related Documents
- [US-002](../UserStories/US-002_Customer_Pickup_Card.md) (To be created)
- [UX Flow: Card Issuance](../../01-Design/UI-UX/FLOW_Card_Issuance.md) (To be created)

## Notes
- NFC/bump technology may not be available on all devices
- QR code fallback should be considered
- Consider deep linking or app-to-app communication

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
