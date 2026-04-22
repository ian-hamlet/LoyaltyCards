# Requirement: Stamp Expiration

## ID
REQ-019

## Status
Draft

## Priority
Low

## Category
Functional

## Description
The system shall optionally support stamp expiration policies where stamps expire after a defined period (e.g., 90 days) from the date of issuance or last stamp. Suppliers can configure expiration rules during setup. Customers receive warnings before stamps expire.

## Rationale
Many loyalty programs include expiration policies to encourage regular visits and prevent abuse. However, this adds complexity and may frustrate customers. Expiration should be optional and clearly communicated.

## Acceptance Criteria
- [ ] Supplier can enable/disable stamp expiration during setup
- [ ] If enabled, supplier can configure expiration period (days)
- [ ] Expiration policy is clearly displayed on customer card
- [ ] Customer receives notification 7 days before expiration
- [ ] Customer receives notification 1 day before expiration
- [ ] Expired cards are marked clearly in customer app
- [ ] Expired stamps are removed or card is reset based on supplier policy
- [ ] Supplier can configure: expire individual stamps vs. expire entire card

## Dependencies
- REQ-007 (Visual Stamp Card Display)
- REQ-008 (Configurable Stamp Requirements)
- REQ-016 (Push Notifications)

## Constraints
- Expiration adds complexity to customer experience
- Requires clear communication to avoid customer frustration
- Must track individual stamp timestamps if individual expiration is supported

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 5 (mentions expiration dates)

## Related Documents
- [US-001](../UserStories/US-001_Supplier_Registration.md) (To be created)
- [UX Guidelines: Communicating Expiration](../../01-Design/UI-UX/GUIDELINES_Expiration.md) (To be created)

## Notes
- Discovery mentions "Expiration dates for purchases" in data capture section
- Expiration is common in loyalty programs but can be customer-unfriendly
- Recommend: make optional, default to no expiration
- Consider grace period: stamps expire but can be restored by supplier
- Consider tiered expiration: first few stamps don't expire, later ones do

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
