# Requirement: Multi-Device Supplier Support

## ID
REQ-021

## Status
Defined - Ready for Implementation

## Priority
Critical

## Category
Technical

## Description
The system shall support multiple devices operating as the same supplier business through configuration cloning and backup/recovery mechanisms. A single business (e.g., "Joe's Coffee Shop") must be able to clone their supplier configuration (business identity and cryptographic keys) to additional devices, with each device capable of independently issuing cards, adding stamps, and redeeming rewards. All devices with the same cloned configuration shall share the same business identity and cryptographic keys, ensuring that loyalty cards issued or stamped by any device are recognized as coming from the same business.

Additionally, the system shall provide comprehensive backup and recovery capabilities to protect against device loss, theft, or failure. Suppliers can generate a non-expiring recovery backup QR code that preserves their complete business identity (including cryptographic keys), enabling them to restore their supplier configuration to a replacement device with the exact same Business ID and keys. This ensures that all previously-issued customer loyalty cards remain valid after device recovery, preventing significant customer impact from device loss scenarios.

The supplier app shall have security measures to prevent customer app users from accessing supplier functionality.

## Rationale
Real-world retail environments often have multiple points of sale and multiple staff members serving customers simultaneously. A coffee shop may have 2-5 devices at checkout counters, a restaurant may have tablets at each table, or a retail store may have roaming staff with mobile devices. Rather than implementing complex real-time device pairing or shared database storage, a simple configuration cloning approach allows businesses to duplicate their setup to multiple devices. Each device operates completely independently with no inter-device communication required, maintaining the P2P architecture's simplicity while enabling multi-device scenarios.

**Disaster Recovery Need:**
In the P2P architecture, a supplier's cryptographic private key is the singular source of business identity. If a device is lost, stolen, or broken without a backup, generating a new key pair would invalidate all existing customer loyalty cards (cards signed with the old public key would fail validation). This creates significant business disruption as all customers with active cards would need to be re-issued new cards. A comprehensive backup and recovery system is therefore critical to business continuity - it allows a supplier to restore their exact business identity (including the same cryptographic keys) to a replacement device, ensuring all existing customer cards remain valid. This transforms device loss from a catastrophic business event into a minor inconvenience.

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
- [ ] Supplier can reset/delete business configuration (with confirmation)
- [ ] Warning displayed when exporting configuration about security risks

**Key Backup & Recovery (Disaster Recovery):**
- [ ] Supplier can export backup QR code containing complete configuration
- [ ] Backup QR code does NOT expire (unlike cloning QR which expires in 24h)
- [ ] Backup QR clearly labeled as "RECOVERY BACKUP - Store Securely"
- [ ] Supplier prompted to save backup during initial setup
- [ ] Backup can be saved as: QR code image, PDF, or encrypted file
- [ ] Recommended storage: Print physical copy, secure cloud storage, password manager
- [ ] Recovery QR can restore exact same Business ID and cryptographic key
- [ ] Recovering from backup restores full supplier functionality with original identity
- [ ] Warning displayed about backup security: "Anyone with this QR can impersonate your business"
- [ ] Optional: Backup protected with additional password/PIN (user-chosen)
- [ ] App provides "Test Recovery" feature to verify backup works without wiping current config
- [ ] Backup includes version number for future format compatibility

## Dependencies
- REQ-020 (Security Requirements) - Key management and cryptographic signatures
- REQ-010 (Data Synchronization) - P2P communication for device pairing
- REQ-009 (QR/Barcode Scanning) - Pairing QR code exchange
- REQ-002 (Two-Actor System) - Supplier role definition

## Constraints
- Configuration cloning is manual process (user exports from Device A, imports to Device B)
- No automatic sync of configuration changes between cloned devices
- If business name/branding changes, all devices must re-import configuration
- Lost backup QR is security risk (anyone can impersonate business - same as lost physical keys)
- No centralized device revocation (each device operates independently)
- User responsible for secure backup storage and access control
- Recommended maximum 10 devices (not enforced, but best practice)
- Cannot prevent configuration from being cloned to unauthorized devices (trust-based)
- iOS/Android keychain limitations may affect key storage capacity
- Recovery backup QR is not password-protected by default (optional feature)

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

3. **Lost Device Scenario (WITH Backup):**
   - **Problem:** Supplier loses device with business configuration
   - **Solution with Backup:**
     - Supplier retrieves saved backup QR code (from printed copy, password manager, etc.)
     - New device: Import backup QR during supplier setup
     - System restores exact same Business ID and cryptographic private key
     - All existing customer cards remain valid (same public key for validation)
     - No customer impact - seamless recovery
   - **Solution without Backup:**
     - Generate new key pair on new device
     - All old customer cards become invalid (different public key)
     - Customer impact: Must re-issue all active cards to customers
     - Acceptable for P2P architecture but significant business disruption
   - **Best Practice:** Always save backup during initial setup
   - **User Education:** "Treat backup like your business's master key"

4. **Backup vs Cloning QR Codes:**
   - **Cloning QR (24h expiry):** For adding new devices while original still works
     - Use case: Adding iPad #2 when you have iPad #1
     - Short-lived for security (reduces window for QR theft)
   - **Recovery Backup QR (no expiry):** For disaster recovery
     - Use case: Lost/stolen/broken device, need to restore to new device
     - Long-lived because needs to be stored securely for months/years
     - Protected by physical security (locked drawer, password manager, etc.)

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

**Backup & Recovery Format:**

**Recovery Backup QR Code Structure:**
```json
{
  "type": "supplier_recovery_backup",
  "version": "1.0",
  "businessId": "uuid-v4",
  "businessName": "Joe's Coffee",
  "privateKey": "base64-encoded-key",
  "publicKey": "base64-encoded-key",
  "stampsRequired": 7,
  "brandColor": "#8B4513",
  "operationMode": "simple|secure",
  "backupTimestamp": "2026-04-13T12:00:00Z",
  "noExpiry": true,
  "signature": "backup-signature"
}
```

**Backup Storage Options:**
1. **Physical Print (Recommended for small businesses):**
   - Generate PDF with QR code + business details
   - Print and store in safe, locked drawer, or safety deposit box
   - Label: "BUSINESS RECOVERY KEY - KEEP SECURE"

2. **Digital Secure Storage:**
   - Save QR image to password manager (1Password, LastPass, etc.)
   - Encrypted cloud storage (iCloud Keychain, Google Drive with encryption)
   - Offline USB drive in secure location

3. **Optional Password Protection:**
   - User can add additional password to backup QR
   - Recovery requires both QR code AND password
   - Increases security if QR is accidentally exposed
   - Password stored separately (not in QR)

**Security Considerations for Backups:**
- ⚠️ **Backup = Complete Business Control:** Anyone with backup can impersonate business
- ✅ **Physical Security:** Printed backups protected by physical locks
- ✅ **Password Protection:** Optional password layer for digital backups
- ✅ **User Education:** Warning dialogs during backup creation
- ❌ **No Revocation:** Lost backup cannot be remotely invalidated (P2P limitation)
- ✅ **Mitigation:** If backup compromised, generate new key and re-issue cards to customers

**Backup User Flow:**
```
Initial Supplier Setup                 Device Lost/Broken
---------------------                  ------------------
1. Complete onboarding                 1. Get replacement device
   Business name, stamps, etc.         
                                       2. Install supplier app
2. System: "Save Recovery Backup"      
   "If you lose this device, you'll    3. Tap "Recover Existing Business"
    need this QR to restore"           
                                       4. Scan saved backup QR
3. User chooses backup method:            (from print, password manager, etc.)
   [ ] Print PDF                       
   [ ] Save to Photos                  5. System validates backup
   [ ] Save to Files                   
   [ ] Email to myself                 6. Restores exact configuration:
                                          - Same Business ID
4. User confirms backup saved             - Same crypto keys
                                          - Same business name/settings
5. Proceed to use supplier app         
                                       7. All customer cards still valid!
                                       
                                       8. Continue operations
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
- Optional: Password-protected backups (user sets password during backup creation)
- Optional: Encrypted cloud backup sync (automatic backup to iCloud/Google Drive)
- Optional: Multi-part backup (split key across multiple QR codes for higher security)
- Optional: Device usage analytics (local only)
- Optional: Device nickname displayed on receipts/confirmations
- Optional: Remote revocation via optional supplier backend (paid tier)
- Optional: Time-limited recovery codes (generate temporary recovery code for support scenarios)
- Optional: Backup health check (periodic reminder to verify backup is still accessible)

---
**Created**: 2026-04-03  
**Last Updated**: 2026-04-13  
**Owner**: Project Team
