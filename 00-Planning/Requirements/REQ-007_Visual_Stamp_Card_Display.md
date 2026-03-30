# Requirement: Visual Stamp Card Display

## ID
REQ-007

## Status
Draft

## Priority
High

## Category
Functional

## Description
The customer application shall display loyalty cards using a visual stamp/punch card metaphor. Cards shall show total stamps required, stamps collected so far, and stamps remaining. The display shall use simple branding from the supplier and clearly communicate progress toward reward.

## Rationale
Physical stamp cards provide immediate visual feedback on progress ("3 more coffees until free one"). The digital version must preserve this intuitive visualization to maintain user engagement and clarity. Customers should instantly see their progress without counting or calculating.

## Acceptance Criteria
- [ ] Card displays supplier name and branding
- [ ] Card shows visual representation of stamp positions (e.g., 8 boxes for "buy 7 get 8th free")
- [ ] Filled/collected stamps are visually distinct from empty stamps
- [ ] Customer can see at a glance: stamps collected and stamps remaining
- [ ] Card displays expiration date if applicable
- [ ] Tapping card shows QR/barcode for supplier scanning
- [ ] Card design is configurable by supplier (colors, logo)
- [ ] Multiple cards can be browsed/scrolled in customer app
- [ ] Cards are easily distinguishable by brand/logo

## Dependencies
- REQ-002 (Two-Actor System)
- REQ-003 (Mobile Platform Support)
- REQ-008 (Configurable Stamp Requirements)

## Constraints
- Design must work on various screen sizes (small phones to tablets)
- Must be accessible (consider color blindness, screen readers)
- Simple branding limits to avoid complexity (logo, colors, name)

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Section 3

## Related Documents
- [UI Mockups: Card Display](../../01-Design/UI-UX/MOCKUP_Card_Display.md) (To be created)
- [US-005](../UserStories/US-005_View_Card_Progress.md) (To be created)

## Notes
- Consider card animations when stamp is added
- Consider push notification with visual update
- May need default branding for quick supplier setup
- Accessibility considerations for visual design

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
