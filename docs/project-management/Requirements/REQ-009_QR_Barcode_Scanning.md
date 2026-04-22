# Requirement: QR/Barcode Scanning

## ID
REQ-009

## Status
Draft

## Priority
Critical

## Category
Functional

## Description
The system shall generate unique QR codes and/or barcodes for each customer loyalty card. Supplier applications shall use device cameras to scan these codes for card identification during stamping and redemption. Cards shall also display a human-readable code identifier as a fallback.

## Rationale
Scanning provides fast, accurate card identification without manual data entry. Both QR codes and barcodes are widely supported by smartphone cameras. Human-readable fallback ensures system remains operational if scanning fails (poor lighting, damaged phone screen, camera issues).

## Acceptance Criteria
- [ ] Each customer card has unique QR code
- [ ] Each customer card has unique barcode (alternative representation)
- [ ] Each card displays human-readable code (8 characters as specified)
- [ ] Each card has unique GUID for backend identification
- [ ] Supplier app can scan QR codes using device camera
- [ ] Supplier app can scan barcodes using device camera
- [ ] Supplier app provides manual code entry fallback
- [ ] Scan process completes in under 2 seconds
- [ ] Scanning works in various lighting conditions
- [ ] Code formats are industry-standard (QR Code, Code 128 or EAN)

## Dependencies
- REQ-003 (Mobile Platform Support)
- REQ-004 (Zero Data Entry Card Issuance)
- REQ-006 (Fast Stamp Process)

## Constraints
- Must support cameras on devices 2-3 years old
- Must work with screen brightness variations
- QR/barcode must be large enough to scan reliably on mobile screens

## AI Prompt Reference
Generated from discovery document: 00-REQUIREMENTS_DISCOVERY.md - Sections 3, 5

## Related Documents
- [Technical Specification: Code Generation](../../01-Design/API/SPEC_Code_Generation.md) (To be created)
- [US-003](../UserStories/US-003_Stamp_Customer_Card.md) (To be created)

## Notes
- QR codes more robust for damaged/dirty screens
- Barcodes scan faster but require more screen space
- 8-character human-readable code should be alphanumeric, avoid ambiguous characters (0/O, 1/I)
- Consider code expiration/rotation for security

---
**Created**: 2026-03-30  
**Last Updated**: 2026-03-30  
**Owner**: Project Team
