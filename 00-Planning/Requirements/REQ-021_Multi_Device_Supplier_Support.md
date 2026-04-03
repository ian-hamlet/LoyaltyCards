# Requirement: Multi-Device Supplier Support

## ID
REQ-021

## Status
Draft

## Priority
Critical

## Category
Technical

## Description
The system shall support multiple devices operating as the same supplier business through configuration cloning. A single business (e.g., "Joe's Coffee Shop") must be able to clone their supplier configuration (business identity and cryptographic keys) to additional devices, with each device capable of independently issuing cards, adding stamps, and redeeming rewards. All devices with the same cloned configuration shall share the same business identity and cryptographic keys, ensuring that loyalty cards issued or stamped by any device are recognized as coming from the same business. The supplier app shall have security measures to prevent customer app users from accessing supplier functionality.

## Rationale
Real-world retail environments often have multiple points of sale and multiple staff members serving customers simultaneously. A coffee shop may have 2-5 devices at checkout counters, a restaurant may have tablets at each table, or a retail store may have roaming staff with mobile devices. Rather than implementing complex real-time device pairing or shared database storage, a simple configuration cloning approach allows businesses to duplicate their setup to multiple devices. Each device operates completely independently with no inter-device communication required, maintaining the P2P architecture's simplicity while enabling multi-device scenarios.

## Acceptance Criteria

**Configuration Cloning & Setup:**
- [ ] Primary device can export supplier configuration as encrypted QR code or file
- [ ] Export includes: Business ID, business name, private key, stamp requirements, branding
- [ ] Secondary devices can import configuration by scanning QR or importing file
- [ ] Imported configuration is validated before storage (signature check, schema validation)
- [ ] Configuration export requires supplier device authentication (PIN/biometric)
- [ ] Exported configuration contains timestamp and expires after 24 hours
- [ ] Configuration can be re-exported any time from any cloned device
- [ ] Maximum recommended 10 devices per business (user warning, not enforced)

**Supplier App Security:**
- [ ] Supplier app requires device passcode/biometric to be enabled
- [ ] Initial supplier setup requires device authentication
- [ ] Supplier private key only accessible after device unlock
- [ ] App detects if user tries to import supplier config into customer app (reject with error)
- [ ] Supplier functionality hidden/disabled if business not configured
- [ ] Optional: Supplier can set additional PIN for high-value operations (redemptions)

**Shared Business Identity:**
- [ ] All cloned devices share the same Business ID (UUID)
- [ ] All cloned devices share the same business name and branding
- [ ] All cloned devices use the same cryptographic private key for signing stamps
- [ ] Cards issued from any cloned device show the same business name to customers
- [ ] Stamps from any cloned device validate using the same public key
- [ ] Customer cannot distinguish which specific device issued a card or stamp

**Independent Operation:**
- [ ] Each device operates completely independently (no inter-device sync)
- [ ] Each device maintains its own local SQLite database
- [ ] No real-time communication between cloned devices
- [ ] No shared database or cloud storage required
- [ ] Device A can stamp while Device B is offline
- [ ] Rate limiting enforced by customer device (1 stamp/hour regardless of supplier device)

**Configuration Management:**
- [ ] Supplier can view current business configuration details
- [ ] Supplier can edit business name/branding (requires re-cloning to other devices)
- [ ] Optional: Display device nickname (user sets locally, not shared)
- [ ] Optional: Configuration backup to device or cloud (encrypted)
- [ ] Supplier can reset/delete business configuration (with confirmation)
- [ ] Warning displayed when exporting configuration about security risks

## Dependencies
- REQ-020 (Security Requirements) - Key management and cryptographic signatures
- REQ-010 (Data Synchronization) - P2P communication for device pairing
- REQ-009 (QR/Barcode Scanning) - Pairing QR code exchange
- REQ-002 (Two-Actor System) - Supplier role definition

## Constraints
- Configuration cloning is manual process (user exports from Device A, imports to Device B)
- No automatic sync of configuration changes between cloned devices
- If business name/branding changes, all devices must re-import configuration
- Lost device with supplier config is security risk (private key compromised)
- No centralized device revocation (each device operates independently)
- User responsible for secure configuration storage and transfer
- Recommended maximum 10 devices (not enforced, but best practice)
- Cannot prevent configuration from being cloned to unauthorized devices (trust-based)
- iOS/Android keychain limitations may affect key storage capacity

## AI Prompt Reference
User request: "add in an additional requirement where a supplier can have multiple devices in a store and we need to set up multiple instances of a supplier capability so that a customer can pick up stamps from any device in that shop"

## Related Documents
- [REQ-020: Security Requirements](REQ-020_Security_Requirements.md)
- [REQ-010: Data Synchronization](REQ-010_Data_Synchronization.md)
- [Architecture Decision: Configuration Cloning Strategy](../../01-Design/Architecture/DECISION_Configuration_Cloning.md) (To be created)
- [Technical Specification: Configuration Export Format](../../01-Design/API/SPEC_Configuration_Export.md) (To be created)

## Notes

**Implementation Strategy: Configuration Cloning**

The approach uses **simple configuration export/import** rather than complex device pairing:

1. **Initial Setup (Device A):**
   - Supplier completes onboarding on Device A
   - System generates Business ID + ECDSA key pair
   - Configuration stored in local keychain

2. **Clone to Device B:**
   - Device A: Export configuration → QR code or encrypted file
   - Device B: Import configuration → validates and stores
   - Both devices now operate independently with same credentials

3. **Independent Operation:**
   - No communication between devices
   - No shared database
   - Each device maintains its own transaction history
   - Customer device enforces duplicate detection

**Why This Approach:**
- ✅ **Simple**: No complex pairing protocol
- ✅ **P2P-aligned**: No backend/sync infrastructure
- ✅ **Offline**: Works completely offline
- ✅ **Scalable**: Easy to add more devices
- ⚠️ **Trade-off**: No centralized device management or revocation

**Security Model:**

1. **Configuration Export:**
```json
{
  "businessId": "uuid-v4",
  "businessName": "Joe's Coffee",
  "privateKey": "base64-encoded-key",
  "publicKey": "base64-encoded-key",
  "stampsRequired": 7,
  "brandColor": "#8B4513",
  "exportTimestamp": "2026-04-03T12:00:00Z",
  "signature": "export-signature"
}
```
   - Encrypted with temporary key
   - QR code or file format
   - Expires after 24 hours

2. **Supplier App Security:**
   - Device passcode/biometric required
   - Customer app cannot import supplier config (validation check)
   - Warning to users about secure storage

3. **Lost Device Scenario:**
   - No automatic revocation (limitation of P2P model)
   - Mitigation: Generate new key pair, clone to new devices
   - Old cards become invalid (acceptable for P2P architecture)
   - User education: Treat supplier device like physical key

**Configuration Cloning Flow:**
```
Device A (Supplier)                Device B (New Supplier Device)
------------------                 ---------------------------
1. Tap "Clone Configuration"
   - Authenticate with biometric
   
2. Generate export QR code
   - Encrypt configuration
   - Add timestamp/signature
   
3. Display QR code ------------> 4. Tap "Import Configuration"
                                     (from supplier app setup)
                                     
                                  5. Scan QR code
                                  
                                  6. Validate:
                                     - Not expired
                                     - Correct format
                                     - Not customer app
                                     
                                  7. Store in keychain
                                  
                                  8. Supplier app ready
                                  
Both devices now operational with same business identity
```

**Preventing Customer Access to Supplier Features:**

1. **App-Level Separation:**
   - Supplier features require business configuration
   - Customer app cannot import supplier config (schema/type validation)
   - Different app flows: Customer = no business setup, Supplier = requires setup

2. **Database Flag:**
   - Store `app_mode` in local database: "customer" or "supplier"
   - Supplier features check: `if app_mode != "supplier" then hide/disable`

3. **UI/UX:**
   - Initial launch: "Are you a business or customer?"
   - Once set, requires app reset to change
   - Prevent accidental mode switching

**Alternative Considered: Separate Apps**
- Option: Two separate apps (Customer app vs. Supplier app)
- **Not chosen:** Adds development/maintenance overhead
- Current approach: Single app, mode determined by configuration

**Future Enhancements (Post-Launch):**
- Optional: Cloud backup of configuration (encrypted)
- Optional: Device usage analytics (local only)
- Optional: Device nickname displayed on receipts/confirmations
- Optional: Remote revocation via optional supplier backend (paid tier)

---
**Created**: 2026-04-03  
**Last Updated**: 2026-04-03  
**Owner**: Project Team
