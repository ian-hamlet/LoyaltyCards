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
- [x] Configuration can be changed after setup, not just during initial creation — see "Post-Setup Editability" below for the directional policy this actually follows
- [ ] New cards begin with zero stamps (all positions empty)
- [ ] Customer can see total stamps required on card

## Dependencies
- REQ-001 (Digital Stamp Card System)
- REQ-002 (Two-Actor System)
- REQ-007 (Visual Stamp Card Display)

## Post-Setup Editability

**Superseded 2026-08-22:** the original "affects new cards only, not existing customer cards" policy (below) was the *initial* behavior, investigated and confirmed safe in DECISION-017 (`DEFECT_TRACKER.md`). It has since been replaced by a customer-protective **directional** policy, implemented alongside Name/Icon/Brand Color becoming generally editable for the first time (previously locked at setup) — see `DECISION-021` and `docs/project-management/Requirements/DISCUSSION_Business_Field_Editing.md` for the full design record:

- A **decrease** applies to a customer's in-progress card on their *next scan* (reusing the existing overflow-relocation machinery from TEST-018 if that scan now completes or overflows the card).
- An **increase** never applies to a card already in progress — only to the *next* card, created once the current one completes and redeems.
- The old flat "new cards only" framing undersold this: a decrease is *not* new-cards-only, it reaches in-progress cards live. Only increases are truly new-cards-only.

## Constraints
- A stamp-requirement change never makes the deal worse for a customer already collecting on a card (see "Post-Setup Editability" above for the exact mechanics)
- Very high stamp counts (>20) may be difficult to display on mobile screens

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 3

## Related Documents
- [US-001](../UserStories/US-001_Supplier_Registration.md) (To be created)
- [Database Schema: Card Configuration](../../01-Design/Database/SCHEMA_Card_Config.md) (To be created)

## Notes
- Consider most common retail loyalty programs for defaults
- ~~Changing configuration mid-program could confuse customers - needs clear policy~~ Resolved: see "Post-Setup Editability" above — the directional policy (decrease live, increase deferred to next card) is that clear policy.
- Consider future enhancement: tiered rewards (different rewards at different stamp counts)
- Name, Icon, and Brand Color became editable post-setup in the same effort that revised this requirement's change policy — out of this requirement's scope (stamp count specifically), but see `DISCUSSION_Business_Field_Editing.md` for the combined record.

---
**Created**: 2026-03-30  
**Last Updated**: 2026-08-22  
**Owner**: Project Team
