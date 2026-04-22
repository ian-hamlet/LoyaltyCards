# Requirement: Two-Actor System

## ID
REQ-002

## Status
Draft

## Priority
Critical

## Category
Functional

## Description
The system shall support two distinct user types (actors):
1. **Supplier** - Business owner/operator who registers their business, configures loyalty card offerings, and stamps customer cards
2. **Customer** - End user who picks up digital cards from suppliers and collects stamps

## Rationale
The loyalty card system requires different capabilities and workflows for business operators versus customers. Suppliers need administrative functions (setup, configuration, stamping), while customers need collection and tracking functions.

## Acceptance Criteria
- [ ] System distinguishes between Supplier and Customer user types
- [ ] Suppliers can register and configure their business
- [ ] Suppliers can issue new cards to customers
- [ ] Suppliers can stamp existing customer cards
- [ ] Suppliers can redeem and reset cards
- [ ] Customers can "pick up" digital cards from suppliers
- [ ] Customers can view their collected cards and stamp progress
- [ ] One supplier can serve multiple customers
- [ ] One customer can hold cards from multiple suppliers

## Dependencies
- REQ-001 (Digital Stamp Card System)
- REQ-003 (Mobile Platform Support)

## Constraints
- No requirement for customers to create account/login
- Supplier application requires mobile device security (PIN/biometric)

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 2

## Related Documents
- [US-001](../UserStories/US-001_Supplier_Registration.md) (To be created)
- [US-002](../UserStories/US-002_Customer_Pickup_Card.md) (To be created)

## Notes
- Supplier serves as trusted party in the relationship
- Customer interaction should require minimal setup
- Consider edge cases: lost phones, device transfer

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
