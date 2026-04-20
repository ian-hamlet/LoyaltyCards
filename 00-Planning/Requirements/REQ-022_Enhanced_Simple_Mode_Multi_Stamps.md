# REQ-022: Enhanced Simple Mode - Multi-Denomination Stamps

**Status:** Draft  
**Priority:** High  
**Target Version:** v0.3.0  
**Created:** 2026-04-20  
**Related:** REQ-004, REQ-006

## Overview

Enhance Simple Mode to support multi-denomination stamps (1, 2, or 3 stamps per scan) with cashier-controlled QR codes. This addresses the abuse vector of counter-mounted QR codes while maintaining Simple Mode's ease of use and eliminating the need for customers to scan multiple times for multi-item purchases.

## Business Case

**Problem with Current Simple Mode:**
- Static QR codes on counters are easy to abuse (scan multiple times)
- 5-second rate limit feels restrictive for legitimate multi-item purchases
- Customers must scan once per stamp (tedious for "2 coffees" scenario)

**Solution - Cashier-Controlled Multi-Stamps:**
- Cashier presents appropriate denomination QR (1/2/3 stamps) based on purchase
- Single scan awards multiple stamps
- Limited exposure window (QR in till/drawer, not on counter)
- Can increase rate limit to 30 seconds (safe since cashier controls access)

## Requirements

### 1. Configurable Customer Scan Interval (Rate Limit)

**REQ-022.1:** Supplier-Defined Rate Limit
- Each supplier can configure customer scan interval for Simple Mode
- Default: 30 seconds (increased from current 5 seconds)
- Configurable range: 5-60 seconds
- Setting stored in supplier's business profile
- Encoded in supplier's QR code tokens
- Customer app reads and applies interval from scanned token

**Location:** Supplier Setup Screen
- Field: "Customer Scan Interval" (seconds)
- Help text: "Minimum time between stamp scans for this business"
- Applied to: Simple Mode only (Secure Mode has cryptographic protection)

### 2. Supplier Manual Stamp Screen - Denomination Support

**REQ-022.2:** Multi-Stamp Selection
- Extend Simple Mode "Add Stamp" screen with denomination selector
- UI similar to Secure Mode's multiple stamp interface
- Options: 1 stamp, 2 stamps, 3 stamps
- Default: 1 stamp
- Single button tap awards selected number of stamps
- Not expected to be frequently used (most usage via printable tokens)

**Purpose:** Allows supplier to manually award multiple stamps when printable tokens unavailable

### 3. Printable Token Generation

**REQ-022.3:** Generate Multi-Denomination QR Codes
- Located in Supplier Protected Area (biometric/passcode secured)
- Generate QR codes for offline customer scanning
- Configurable options:
  - Denomination: 1, 2, or 3 stamps (checkboxes or dropdown)
  - Expiry Date: Optional (None, Daily, Weekly, Custom date)
- Generate one or more QR codes per session
- Each QR code is uniquely generated (includes timestamp)

**REQ-022.4:** QR Code Output Options
- Save to device photos/gallery
- Email as PDF attachment
- Print (via system print dialog)
- Save as PDF to files
- Display on screen for immediate use

**REQ-022.5:** QR Code Visual Design
- QR code image includes text annotation
- Annotation shows: 
  - Business name
  - Stamp count: "**2 STAMPS**" (large, bold)
  - Expiry date if applicable: "Expires: 2026-04-25"
- Designed for printing and laminating
- Clear visual distinction between denominations
- Professional appearance suitable for customer-facing use

**REQ-022.6:** Token Data Structure
```json
{
  "businessId": "uuid",
  "businessName": "Coffee Shop",
  "mode": "simple",
  "timestamp": 1234567890,
  "stampCount": 2,           // NEW: 1-3 stamps
  "expiryDate": 1234567890,  // NEW: Optional (null if no expiry)
  "scanInterval": 30         // NEW: Supplier's configured rate limit
}
```

### 4. Customer App - Token Processing

**REQ-022.7:** Multi-Stamp Processing
- When scanning QR code with `stampCount > 1`:
  - Award all stamps in single transaction
  - Create individual stamp records for each
  - Apply overflow logic if stamps exceed card capacity
  - Single feedback message: "Added 2 stamps to Coffee Shop"

**REQ-022.8:** Expiry Validation
- Check `expiryDate` field when processing token
- If expired, reject with friendly message:
  - "This stamp code has expired. Please ask staff for a current code."
- Do not consume stamp or record transaction
- No rate limit penalty for expired scan

**REQ-022.9:** Dynamic Rate Limit
- Read `scanInterval` from scanned token
- Apply supplier-specific rate limit for that business
- Store in business profile for subsequent scans
- Override default 30-second interval with supplier's preference

### 5. Security Considerations

**REQ-022.10:** Abuse Mitigation
- Expiry dates limit lifetime of leaked/photographed QR codes
- 30-second rate limit prevents rapid re-scanning
- Cashier control limits exposure window (not permanently visible)
- Trust model: Employee presents correct denomination (employee fraud outside scope)

**REQ-022.11:** Token Uniqueness
- Each generated QR code includes unique timestamp
- Prevents simple QR duplication
- Enables future token usage tracking if needed

## Operational Flow

### Supplier Setup (One-Time)
1. Navigate to Protected Area → Token Management
2. Select denominations to generate (e.g., 1, 2, 3 stamps)
3. Set expiry policy (e.g., "Weekly" or "No expiry")
4. Generate QR codes
5. Save as PDF, print, laminate
6. Place laminated cards in till/cash drawer

### Transaction Flow
1. Customer: "2 lattes please"
2. Cashier: Rings up purchase, retrieves "2 STAMPS" card from till
3. Customer: Scans QR code once
4. App: Awards 2 stamps, shows confirmation
5. Cashier: Returns card to till
6. Total exposure: 5-10 seconds

### Regeneration Flow (Expired Tokens)
1. Customer scans expired token
2. App shows: "This stamp code has expired"
3. Customer asks staff
4. Supplier regenerates weekly tokens
5. Prints new set, discards old

## Technical Impact

### Files to Create/Modify
- `shared/lib/models/stamp_token.dart` - Add stampCount, expiryDate, scanInterval fields
- `shared/lib/constants/constants.dart` - Update default rate limits
- `supplier_app/lib/screens/supplier/business_setup_screen.dart` - Add scan interval config
- `supplier_app/lib/screens/supplier/simple_add_stamp_screen.dart` - Add denomination selector
- `supplier_app/lib/screens/supplier/token_generation_screen.dart` - NEW: Generate printable tokens
- `supplier_app/lib/widgets/token_qr_image.dart` - NEW: QR with annotations
- `customer_app/lib/services/token_validator.dart` - Add expiry validation
- `customer_app/lib/screens/customer/qr_scanner_screen.dart` - Process multi-stamps, dynamic rate limit

### Database Schema Changes
- Supplier DB: Add `scan_interval_seconds` to businesses table
- No customer DB changes needed (stamps stored individually as before)

### Testing Requirements
- Multi-stamp overflow edge cases (2 stamps when card needs 1 to complete)
- Expiry date validation (boundary conditions)
- Rate limit enforcement with supplier-specific intervals
- QR code generation and annotation rendering
- Print/email/save workflows

## Success Criteria

1. Supplier can configure customer scan interval (5-60s)
2. Supplier can generate multi-denomination QR codes with expiry dates
3. QR codes clearly show stamp count on printed output
4. Customer app awards correct number of stamps per scan
5. Expired tokens rejected with friendly error message
6. Rate limits apply per-supplier configuration
7. Existing Simple Mode cards continue to work (backward compatible)

## Future Enhancements (Out of Scope)

- Token usage analytics (which denominations used most)
- Seasonal stamp graphics (holiday-themed QR backgrounds)
- NFC-encoded tokens (when iOS supports P2P)
- Supplier dashboard showing token expiry warnings

## Dependencies

- Existing backup code generation infrastructure (reuse print/email/save)
- Existing overflow handling (TEST-008 fix from code review)
- Protected area biometric authentication (already implemented)

## Notes

- This enhancement maintains Simple Mode's core philosophy: ease of use
- Shifts trust boundary from customer to employee (better security model)
- 30-second rate limit feels generous because legitimate use requires cashier cooperation
- Printable tokens are primary use case; manual denomination screen is fallback
