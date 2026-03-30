# Requirement: Configurable Stamp Requirements

## ID
REQ-008

## Status
Draft

## Priority
High

## Category
Functional

## Description
The system shall allow suppliers to configure the number of stamps required to earn a reward when setting up their loyalty card. Common configurations (5, 7, 10 stamps) should be pre-set options for ease of setup. Each card starts with all stamp positions empty, allowing customers to see total progress.

## Rationale
Different businesses have different loyalty models. A coffee shop might use "buy 7 get 8th free" while a sandwich shop might use "buy 5 get 6th free". The system must be flexible to accommodate various business models while remaining simple to configure.

## Acceptance Criteria
- [ ] Supplier can configure number of stamps required during business setup
- [ ] Pre-set options available: 5, 7, 10 stamps (most common)
- [ ] Custom stamp count can be specified (e.g., 12, 15)
- [ ] Minimum stamp count: 3
- [ ] Maximum stamp count: 20
- [ ] Configuration can be changed (affects new cards only, not existing customer cards)
- [ ] New cards begin with zero stamps (all positions empty)
- [ ] Customer can see total stamps required on card

## Dependencies
- REQ-001 (Digital Stamp Card System)
- REQ-002 (Two-Actor System)
- REQ-007 (Visual Stamp Card Display)

## Constraints
- Changing stamp requirement does not affect cards already issued to customers
- Very high stamp counts (>20) may be difficult to display on mobile screens

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 3

## Related Documents
- [US-001](../UserStories/US-001_Supplier_Registration.md) (To be created)
- [Database Schema: Card Configuration](../../01-Design/Database/SCHEMA_Card_Config.md) (To be created)

## Notes
- Consider most common retail loyalty programs for defaults
- Changing configuration mid-program could confuse customers - needs clear policy
- Consider future enhancement: tiered rewards (different rewards at different stamp counts)

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
