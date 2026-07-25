# Security Vulnerability Assessment

**LoyaltyCards v0.3.0+1 Build 23**  
**Assessment Date:** April 17, 2026  
**Updated:** April 22, 2026 (v0.3.0+1 deployment)  
**Assessor:** Development Team  
**Scope:** iOS application security audit

**⚠️ See also:** [2026-07-25 Security Review](#2026-07-25-security-review--signature-coverage--redemption-verification) at the bottom of this document, performed after v1.0.3+11 was submitted for App Store review. It found that Secure Mode's core cryptographic guarantee has gaps this original assessment did not test for — specifically, several fields critical to fraud prevention (`stampCount`, card `mode`) are not covered by the ECDSA signature, and the redemption flow's signature-verification code path is dead/unreferenced. This materially qualifies the "VERIFIED OK" conclusions on V-003 and V-004, and the "crypto protection" framing in V-005, below. Read the new section for current status before relying on this document's original April 2026 sign-off.

---

## Executive Summary

This document captures the security vulnerability assessment performed on LoyaltyCards v0.2.0 prior to TestFlight deployment. All critical vulnerabilities have been addressed in v0.3.0+1.

**Status Overview (v0.3.0+1):**
- ✅ **FIXED & DEPLOYED:** 2 vulnerabilities (V-002, V-005) - Deployed in v0.3.0+1
- 📋 **BY DESIGN:** 2 vulnerabilities (V-001, V-009)
- ✅ **VERIFIED OK:** 2 vulnerabilities (V-003, V-004)
- ⚠️ **DOCUMENTED:** 1 vulnerability (V-006)
- 📝 **DEFERRED:** 2 vulnerabilities (V-007, V-008)

---

## Vulnerability Details

### V-001: Simple Mode Self-Redemption

**Severity:** LOW  
**Status:** 📋 BY DESIGN  
**Affected Component:** Customer App - Simple Mode redemption flow

**Description:**  
In Simple Mode, customers can mark their own cards as "redeemed" without supplier confirmation. This could allow a customer to show a "redeemed" card repeatedly to claim rewards multiple times.

**Why This Is By Design:**  
Simple Mode is intentionally trust-based, designed to mirror physical stamp cards where customers hold the card and the supplier must verify it visually. This is an **accepted trade-off** for speed and ease of use.

**Mitigations:**
1. **Redemption timestamp visible**: Card shows exact date/time of redemption
2. **Supplier visual verification**: Supplier checks redemption date matches today
3. **Stamp history with timestamps**: Suspicious patterns (10 stamps in one day) are visible
4. **Face-to-face accountability**: Supplier sees customer, recognizes fraud patterns
5. **Rate limiting**: 5-second cooldown prevents rapid duplicate stamps

**Documentation:**
- See [SECURITY_MODEL.md](SECURITY_MODEL.md) for full explanation
- Simple Mode suitable only for low-value rewards (<$10)
- Businesses with high-value rewards must use Secure Mode

**Resolution:** ACCEPTED - Working as designed for Simple Mode use cases

---

### V-002: Private Key Extraction

**Severity:** CRITICAL  
**Status:** ✅ FIXED & DEPLOYED (Build 20/21, v0.3.0+1)  
**Affected Component:** Supplier App - Recovery Backup & Clone features

**Description:**  
Prior to Build 20, the Supplier App's recovery backup and device clone features would display QR codes containing private cryptographic keys without requiring authentication. An attacker with access to an unlocked device could view these QR codes and compromise the business's security.

**Impact:**  
- Attacker could issue valid stamps for the business
- Attacker could impersonate the business
- Complete compromise of Secure Mode security

**Fix Implemented (Build 20, deployed v0.3.0+1):**
- Added `local_auth` package for biometric authentication
- Created `BiometricAuthService` for unified authentication
- Recovery backup QR now requires Face ID/Touch ID/Passcode
- Clone device QR now requires Face ID/Touch ID/Passcode
- Authentication prompt explains: "Authenticate to view recovery backup QR code containing your private key"

**Files Modified:**
- `supplier_app/pubspec.yaml` - Added local_auth dependency
- `supplier_app/lib/services/biometric_auth_service.dart` - New service
- `supplier_app/lib/screens/supplier/recovery_backup_screen.dart` - Added auth requirement
- `supplier_app/lib/screens/supplier/clone_device_screen.dart` - Added auth requirement

**Testing:**
- ✅ Compile-tested (builds successfully)
- ✅ Physical device testing completed
- ✅ Deployed to TestFlight Build 23 (v0.3.0+1)

**Resolution:** ✅ FIXED & DEPLOYED

---

### V-003: QR Screenshot Reuse

**Severity:** HIGH  
**Status:** ✅ VERIFIED OK  
**Affected Component:** Customer App - Secure Mode stamp validation

**Description:**  
Concern that a customer could screenshot a supplier's stamp QR code and scan it multiple times to collect duplicate stamps fraudulently.

**Analysis:**  
**Secure Mode Protection:**
1. **Primary Key Constraint**: Each stamp has a unique `id` (from QR token)
2. **Database Schema**: `stamps` table has `id TEXT PRIMARY KEY`
3. **Duplicate Prevention**: Attempting to insert duplicate `stampId` fails
4. **Current Behavior**: Uses `ConflictAlgorithm.replace` which replaces existing stamp
5. **Result**: Stamp count stays the same (1 stamp replaced with 1 stamp = no gain)

**Code Reference:**
```dart
// customer_app/lib/services/stamp_repository.dart:67
await db.insert(
  'stamps',
  stamp.toJson(),
  conflictAlgorithm: ConflictAlgorithm.replace,  // Prevents count increase
);
```

**Simple Mode Protection:**
1. **Rate Limiting**: 5-second cooldown between stamps
2. **Unique Stamp IDs**: Generated as `${cardId}_stamp_${nextStampNumber}`
3. **Sequential numbering**: Prevents gaps in stamp sequence

**Potential Improvement (Future):**
- Change `ConflictAlgorithm.replace` to `ConflictAlgorithm.abort`
- Catch database exception and show user-friendly error: "This stamp has already been applied"
- Better UX feedback for duplicate scan attempts

**Resolution:** ✅ VERIFIED OK - Fraud prevented, UX could be improved

---

### V-004: Time Manipulation

**Severity:** HIGH  
**Status:** ✅ VERIFIED OK  
**Affected Component:** Customer App - Rate limiting and timestamp validation

**Description:**  
Concern that a customer could change their device clock to bypass rate limits or manipulate stamp timestamps.

**Analysis:**  
**Rate Limiting Protection:**
```dart
// customer_app/lib/services/rate_limiter.dart
const stampRateLimitMs = 5000; // 5 seconds
final lastStampTime = results.first['timestamp'] as int;
final now = DateTime.now().millisecondsSinceEpoch;
final timeSinceLastStamp = now - lastStampTime;

if (timeSinceLastStamp < rateLimitMs) {
  return RateLimitResult(canProceed: false, ...);
}
```

**Timestamp Validation:**
- All stamps include timestamp from `DateTime.now()`
- Timestamps are **visible to supplier** when reviewing stamp history
- Obvious manipulation is detectable:
  - Stamps from "future" dates
  - Multiple stamps with same timestamp
  - Stamps from dates business was closed
  
**Mitigation Strategy:**
1. **Supplier Visual Verification**: Check stamp timestamps match expected dates
2. **Timestamp Anomaly Detection**: Supplier sees all timestamps, can spot patterns
3. **Secure Mode**: Cryptographic signatures include timestamps, manipulation breaks signatures

**Scenarios:**
- Customer sets clock forward: Can bypass rate limit, but stamps show future dates (obvious)
- Customer sets clock backward: Stamps show old dates (obvious)
- Customer resets clock between stamps: Inconsistent timeline visible to supplier

**Resolution:** ✅ VERIFIED OK - Supplier visual verification sufficient, Secure Mode adds crypto protection

---

### V-005: Multi-Device Card Duplication

**Severity:** HIGH  
**Status:** ✅ FIXED (Build 21)  
**Affected Component:** Customer App - Card management, Supplier App - Redemption validation

**Description:**  
A customer could back up their device, restore to a second device, and have the same loyalty card on two devices. They could collect stamps on one device and redeem on the other, or redeem the same card multiple times.

**Impact:**
- Customer gets double rewards for single purchase behavior
- Difficult to detect without centralized tracking
- Legitimate use (device upgrade) vs. fraud (intentional duplication)

**Fix Implemented (v0.2.0+21):****

**1. Device Tracking:**
- Added `device_info_plus` package to get unique device identifiers
- Created `DeviceService` to manage device IDs
- Database migration v5→v6 adds `device_id` columns to `cards` and `stamps` tables
- All cards and stamps now tagged with device where created/collected

**2. Device Mismatch Detection:**
- Redemption QR codes now include:
  - `cardDeviceId`: Device where card was originally created
  - `currentDeviceId`: Device showing redemption QR
- Supplier app checks for mismatch
- Warning dialog shown to supplier if devices differ

**3. Supplier Warning UI:**
```dart
// supplier_app/lib/screens/supplier/supplier_redeem_card.dart
if (token.hasDeviceMismatch()) {
  _showDeviceMismatchWarning(context, token);
  // Shows dialog explaining possible scenarios:
  // - Legitimate: New phone, backup restore
  // - Fraudulent: Card cloning
  // Supplier can choose to proceed or cancel
}
```

**Files Modified:**
- `customer_app/pubspec.yaml` - Added device_info_plus dependency
- `customer_app/lib/services/device_service.dart` - New service
- `customer_app/lib/services/database_helper.dart` - Added v6 migration
- `shared/lib/constants/constants.dart` - Bumped database version to 6
- `shared/lib/models/card.dart` - Added deviceId field
- `shared/lib/models/stamp.dart` - Added deviceId field
- `shared/lib/models/qr_tokens.dart` - Added device fields to RedemptionRequestToken
- `customer_app/lib/screens/customer/qr_scanner_screen.dart` - Track device on card/stamp creation
- `customer_app/lib/screens/customer/customer_card_detail.dart` - Include device IDs in redemption QR
- `supplier_app/lib/screens/supplier/supplier_redeem_card.dart` - Check and warn on device mismatch

**Legitimate Use Cases:**
- Customer upgrades to new phone
- Customer restores from backup
- Family shares devices (less common)

**Fraudulent Use Cases:**
- Customer intentionally duplicates card to multiple devices
- Customer collects stamps on device A, redeems on device B repeatedly
- Customer sells/shares cards with others

**Supplier Guidance:**
- Device mismatch triggers warning (not automatic rejection)
- Supplier verifies customer identity and purchase history
- Supplier uses professional judgment to accept or deny
- Warning text suggests checking stamp history for suspicious patterns

**Resolution:** ✅ FIXED - Detection implemented, supplier discretion enabled

---

#### V-005 Technical Implementation Details

**How Device Tracking Works:**

**1. Device Identification Service**

File: `customer_app/lib/services/device_service.dart`

```dart
class DeviceService {
  static Future<String> getDeviceId() async {
    // iOS: Uses identifierForVendor (unique per vendor)
    // - Persists across app reinstalls
    // - Changes if all vendor apps deleted, then reinstalled
    // - Same across iCloud restore to new device
    
    // Android: Uses androidId (unique per device + app)
    
    String identifier;
    if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      identifier = iosInfo.identifierForVendor ?? 'unknown-ios-...';
    } else if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      identifier = androidInfo.id;
    }
    
    // Hash and truncate for privacy (12 chars is enough)
    final bytes = utf8.encode(identifier);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 12);
    // Example result: "a3b5c7d9e1f2"
  }
}
```

**Key Properties:**
- ✅ Stable: Persists across app reinstalls
- ⚠️ Changes on: Complete app deletion → reinstall → first launch
- ✅ Survives: iCloud backup → restore to new device (iOS gets new ID on new hardware)
- 🔒 Privacy: Hashed to 12 chars (collision-resistant, not reversible)
- ⚡ Cached: Only calculated once per app session

**2. Device ID Capture - Card Creation**

File: `customer_app/lib/screens/customer/qr_scanner_screen.dart`

When customer scans "Issue Card" QR from supplier:

```dart
// Get device ID for multi-device tracking (V-005)
final deviceId = await DeviceService.getDeviceId();

final card = models.Card(
  id: cardId,
  businessId: token.businessId,
  businessName: token.businessName,
  // ... other fields ...
  deviceId: deviceId, // V-005: Track device where card created
);

await cardRepository.insertCard(card);
```

Database schema:
```sql
CREATE TABLE cards (
  id TEXT PRIMARY KEY,
  business_id TEXT NOT NULL,
  -- ... other columns ...
  device_id TEXT,  -- Added in v6 migration (Build 21)
  -- ...
);
```

**3. Device ID Capture - Stamp Collection**

File: `customer_app/lib/screens/customer/qr_scanner_screen.dart`

When customer scans "Add Stamp" QR from supplier:

```dart
// Get device ID for multi-device tracking (V-005)
final deviceId = await DeviceService.getDeviceId();

final stamp = Stamp(
  id: stampId,
  cardId: card.id,
  stampNumber: stampNumber,
  timestamp: stampTimestamp,
  signature: token.signature,
  previousHash: stampPreviousHash,
  deviceId: deviceId, // V-005: Track device where stamp collected
);

await stampRepo.insertStamp(stamp);
```

Database schema:
```sql
CREATE TABLE stamps (
  id TEXT PRIMARY KEY,
  card_id TEXT NOT NULL,
  stamp_number INTEGER NOT NULL,
  -- ... other columns ...
  device_id TEXT,  -- Added in v6 migration (Build 21)
  FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
);
```

**4. Device ID Transmission - Redemption QR**

File: `customer_app/lib/screens/customer/customer_card_detail.dart`

When customer shows completed card to supplier for redemption:

```dart
String _generateCardQR() {
  if (_card!.isComplete) {
    final qrData = {
      'type': 'redemption_request',
      'cardId': _card!.id,
      'businessId': _card!.businessId,
      'stampsCollected': _card!.stampsCollected,
      'stampSignatures': signatures,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      
      // V-005: Device mismatch detection
      'cardDeviceId': _card!.deviceId,      // Where card created
      'currentDeviceId': _currentDeviceId,  // Where QR shown now
    };
    return jsonEncode(qrData);
  }
}
```

QR Code JSON example:
```json
{
  "type": "redemption_request",
  "cardId": "abc-123-def",
  "businessId": "xyz-789",
  "stampsCollected": 10,
  "stampSignatures": ["sig1", "sig2", ...],
  "timestamp": 1713369600000,
  "cardDeviceId": "a3b5c7d9e1f2",   // Original device
  "currentDeviceId": "x9y8z7w6v5u4"  // Current device (different!)
}
```

**5. Device Mismatch Detection - Supplier Side**

File: `supplier_app/lib/screens/supplier/supplier_redeem_card.dart`

When supplier scans customer's redemption QR:

```dart
// Parse redemption token from QR
final token = RedemptionRequestToken.fromJson(json);

// V-005: Check for device mismatch
if (token.hasDeviceMismatch()) {
  AppLogger.warning('Device mismatch detected!', 'Security');
  AppLogger.warning('Card device: ${token.cardDeviceId}', 'Security');
  AppLogger.warning('Current device: ${token.currentDeviceId}', 'Security');
  
  _showDeviceMismatchWarning(context, token);
  return; // Pause redemption for supplier review
}

// No mismatch, proceed normally
_showSecureModeRedemptionConfirmation(context, token.cardId, ...);
```

File: `shared/lib/models/qr_tokens.dart`

```dart
class RedemptionRequestToken extends QRToken {
  final String? cardDeviceId;    // Where card was created
  final String? currentDeviceId;  // Where QR shown now
  
  /// Check if there's a device mismatch (V-005)
  bool hasDeviceMismatch() {
    // If either ID is null, can't determine mismatch (old cards)
    if (cardDeviceId == null || currentDeviceId == null) {
      return false; // Backward compatible with pre-Build 21 cards
    }
    
    // If both present, check if they differ
    return cardDeviceId != currentDeviceId;
  }
}
```

**6. Warning Dialog - Supplier Decision**

File: `supplier_app/lib/screens/supplier/supplier_redeem_card.dart`

```dart
void _showDeviceMismatchWarning(BuildContext context, 
                                 RedemptionRequestToken token) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Device Mismatch'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This card is being redeemed on a different device '
              'than where it was created.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Possible reasons:'),
            const Text('• Customer got a new phone'),
            const Text('• Customer restored from backup'),
            const Text('• Card was cloned/duplicated (fraud)'),
            const SizedBox(height: 16),
            const Text(
              'Verify the customer\'s identity and check stamp '
              'history before proceeding.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Proceed Anyway'),
          ),
        ],
      );
    },
  );
  
  if (result == true) {
    // Supplier chose to proceed despite mismatch
    AppLogger.warning('Supplier chose to proceed with mismatch', 'Security');
    _showSecureModeRedemptionConfirmation(context, token.cardId, ...);
  } else {
    // Supplier cancelled
    AppLogger.warning('Supplier cancelled due to mismatch', 'Security');
  }
}
```

**7. Database Migration (Build 20 → Build 21)**

File: `customer_app/lib/services/database_helper.dart`

```dart
static const int _databaseVersion = 6; // Bumped from 5

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 6) {
    // V-005: Add device tracking columns
    await db.execute('ALTER TABLE cards ADD COLUMN device_id TEXT');
    await db.execute('ALTER TABLE stamps ADD COLUMN device_id TEXT');
    
    AppLogger.database('Database upgraded to v6 - Added device_id columns');
  }
}
```

**Impact:**
- Existing cards (pre-Build 21): `device_id = NULL` (no mismatch detection)
- New cards (Build 21+): `device_id` populated automatically
- Graceful degradation: Old cards work normally, new cards have protection

**8. Scenario Analysis**

| Scenario | cardDeviceId | currentDeviceId | Mismatch? | Supplier Sees |
|----------|--------------|-----------------|-----------|---------------|
| **Normal usage** | `a3b5c7` | `a3b5c7` | ❌ No | Redeems normally |
| **New iPhone** | `a3b5c7` | `x9y8z7` | ✅ Yes | ⚠️ Warning dialog |
| **iCloud restore** | `a3b5c7` | `x9y8z7` | ✅ Yes | ⚠️ Warning dialog |
| **Card cloning (fraud)** | `a3b5c7` | `x9y8z7` | ✅ Yes | ⚠️ Warning dialog |
| **Old card (pre-v21)** | `null` | `null` | ❌ No | Redeems normally |
| **Old → new device** | `null` | `x9y8z7` | ❌ No | Redeems normally |

**9. Why Stamping Is Not Blocked**

Device mismatch is NOT checked during stamp collection because:

1. **Legitimate use:** Customer might use multiple devices (iPhone + iPad)
2. **iCloud restore:** Card syncs to new phone, should still collect stamps
3. **Low fraud impact:** Collecting stamps has lower fraud risk than redemption
4. **User experience:** Blocking stamps would frustrate legitimate users
5. **Detection focus:** High-value event (redemption) is where detection matters

**Stamps still track device IDs for forensics:**
- Every stamp records which device collected it
- Supplier can review stamp history if suspicious
- Pattern analysis possible (e.g., 10 stamps from Device A, redemption from Device B)
- Device ID data available for investigation

**10. Security Trade-offs**

**✅ Detects:**
- Device cloning/duplication (fraud)
- iCloud restore to different device (legitimate)
- New phone upgrades (legitimate)
- Multiple device usage (legitimate)

**⚠️ Legitimate False Positives:**
- Customer upgrades phone → Warning shown (supplier verifies and proceeds)
- Customer restores backup → Warning shown (supplier accepts)
- Family shares devices → Warning shown (rare scenario)

**Design Decision:**
- **Inform, don't block** - Supplier makes final judgment call
- **Orange warning** (not red error) - Indicates caution, not prevention
- **Business discretion** - Supplier knows their regular customers
- **Transparency** - Customer can explain "I got a new phone"

**11. Testing Requirements**

**Single Device Testing (Partial):**
- ✅ Card creation captures device ID
- ✅ Stamps capture device IDs
- ✅ No mismatch warning on same device redemption
- ✅ Database migration works

**Multi-Device Testing (Requires 2 devices):**
- ⏳ Create card on Device A (iPhone)
- ⏳ Restore to Device B (iPad) or use second device
- ⏳ Redeem on Device B
- ⏳ Verify mismatch warning appears
- ⏳ Test "Proceed Anyway" flow
- ⏳ Test "Cancel" flow

**12. Implementation Summary**

**V-005 Device Mismatch Detection:**
1. ✅ Device IDs captured at card creation
2. ✅ Device IDs captured with every stamp  
3. ✅ Both IDs transmitted in redemption QR
4. ✅ Mismatch detected on supplier scan
5. ✅ Supplier warned with clear dialog
6. ✅ Supplier chooses to proceed or cancel
7. ✅ Stamping NOT blocked (usability)
8. ✅ Backward compatible (old cards work)
9. ✅ Database migration (v5→v6) successful
10. ✅ Graceful degradation (null = no check)

**Goal:** Detect potential fraud without disrupting legitimate users who upgrade phones or restore from backup. The system provides visibility to suppliers while preserving user experience.

---

### V-006: Device Storage Limits

**Severity:** LOW  
**Status:** ⚠️ DOCUMENTED  
**Affected Component:** Both apps - Local database storage

**Description:**  
Without server-side storage, all data accumulates locally on user devices. Over time, excessive accumulation of cards, stamps, and transaction logs could impact device storage and app performance.

**Affected Users:**
**Customer App:**
- Heavy users with many businesses
- Users who never delete redeemed cards
- Accumulation of transaction history

**Supplier App:**
- High-volume businesses (coffee shops, etc.)
- Businesses that never archive old data
- Accumulation of issued card records and transaction logs

**Impact:**
- Device storage consumption
- App slowdown (large database queries)
- User experience degradation

**Mitigation:**
1. **Documented in Terms of Service** (Section 6.1)
   - Users informed of storage responsibility
   - Recommendation to delete old cards periodically

2. **User Responsibility:**
   - Customer App: Delete redeemed cards older than 30-60 days
   - Supplier App: Export and archive old transaction data
   - Both: Manage own device storage

3. **Future Enhancements (Deferred):**
   - Auto-archive feature for redeemed cards >90 days
   - Database size monitoring with warnings
   - Built-in data export tools

**Design Rationale:**
This is an inherent limitation of the local-only, privacy-first architecture. The trade-off for no cloud storage is user responsibility for data management.

**Documentation:**
- TERMS_OF_SERVICE.md Section 6.1
- USER_GUIDE.md (should add storage management section)

**Resolution:** ⚠️ ACCEPTED & DOCUMENTED - User responsibility, future enhancements possible

---

### V-007: Recovery Backup Expiration

**Severity:** LOW  
**Status:** 📝 DEFERRED (Future Enhancement)  
**Affected Component:** Supplier App - Recovery backup feature

**Description:**  
Recovery backup QR codes never expire, creating a permanent security risk if the QR code is leaked or stored insecurely.

**Current Behavior:**
```dart
// supplier_app/lib/models/supplier_config_backup.dart
static Future<SupplierConfigBackup> createRecoveryBackup(...) {
  final backup = SupplierConfigBackup(
    type: 'recovery',
    expiresAt: null,  // Never expires
    // ... contains private key
  );
}
```

**Risk Scenarios:**
- Supplier prints backup, later discards improperly
- Backup stored in email/cloud, account compromised
- Backup photo taken, phone stolen months later
- Ex-employee has access to old backup

**Current Mitigations:**
- **V-002 Fix**: Biometric auth required to generate backup (Build 20)
- **User Warnings**: App displays "Store securely" warnings
- **User Documentation**: Recovery backup security guidance in USER_GUIDE.md

**Potential Enhancements (Deferred):**
1. **Optional Expiration**:
   - Allow supplier to set expiration (1 month, 6 months, 1 year, never)
   - Balance between security and disaster recovery
   
2. **Password Protection**:
   - Encrypt backup QR with user-chosen password
   - Requires password on import
   - Better than expiration for long-term storage

3. **Backup Rotation**:
   - Invalidate old backups when new one created
   - Requires storing backup IDs in app
   - Tracks "latest valid backup"

4. **Multi-Part Backup**:
   - Split backup into multiple QR codes
   - Requires all parts to restore
   - Reduces risk of single QR compromise

**Decision:**
Feature is deferred pending user feedback and pilot testing. Current mitigation (biometric auth + warnings) deemed sufficient for v0.2.0 release.

**Tracking:**
- Added to DEFECT_TRACKER.md as future enhancement
- Marked BACKLOG for post-v1.0 consideration

**Resolution:** 📝 DEFERRED - Adequate mitigations in place, enhancement tracked for future

---

### V-008: QR Code Entropy / Guessing Attacks

**Severity:** MEDIUM  
**Status:** 📝 DEFERRED (Future Analysis)  
**Affected Component:** Shared - QR token generation

**Description:**  
Analysis needed to determine if QR token IDs have sufficient entropy to prevent guessing attacks. If token IDs are predictable, an attacker might generate valid-looking tokens without supplier authorization.

**Tokens Affected:**
- Card Issuance Tokens (cardId)
- Stamp Tokens (stampId)
- Redemption Tokens (cardId)
- Clone QR (backup IDs)

**Current Implementation:**
```dart
// Typical ID generation
final cardId = const Uuid().v4();  // UUID v4 = 122 bits entropy
```

**Questions to Answer:**
1. Are all token IDs using cryptographically secure random generation?
2. Is UUID v4 sufficient entropy for this use case?
3. Are there any sequential or predictable components?
4. What's the attack surface for ID guessing?

**Preliminary Assessment:**
- UUID v4 provides 2^122 possible values (~5.3×10^36)
- Probability of guessing a valid ID is astronomically low
- Secure Mode adds cryptographic signatures (prevents token forgery even if ID guessed)
- Simple Mode relies on ID uniqueness only

**Required Analysis:**
- Code audit of all UUID/ID generation points
- Entropy calculation for each token type
- Threat modeling for ID-based attacks
- Comparison against OWASP/NIST randomness guidelines

**Mitigation (If Needed):**
- Increase entropy (use SHA256 of UUID + timestamp)
- Add rate limiting on token validation
- Implement token blacklisting on supplier side

**Decision:**
Deferred for post-v1.0 security audit. Current UUID v4 implementation appears sufficient, but formal analysis needed.

**Tracking:**
- Added to future security audit checklist
- Not blocking for initial TestFlight release

**Resolution:** 📝 DEFERRED - Requires dedicated security analysis

---

### V-009: Card Revocation Limitations

**Severity:** LOW  
**Status:** 📋 BY DESIGN  
**Affected Component:** Architecture - P2P, local-only design

**Description:**  
Due to the P2P architecture with no central server, there is **no way to revoke individual loyalty cards** once issued. If a supplier needs to invalidate a card (fraud, customer dispute, etc.), the only option is to reset the entire business configuration, invalidating ALL customer cards.

**Scenarios:**
1. **Individual Fraud**: One customer duplicates/abuses their card
2. **Dispute Resolution**: Customer demands card cancellation
3. **System Compromise**: Supplier's key leaked, need to invalidate all cards
4. **Policy Change**: Supplier wants to sunset old card format

**Current Solutions:**
**For Individual Issues:**
- Supplier simply refuses redemption at redemption time
- No technical solution needed; handle ad-hoc
- Use device mismatch warnings (V-005) to identify suspicious cards
- Maintain manual "do not honor" list if needed

**For Mass Revocation:**
- Supplier: Settings → Reset Business Configuration
- **Result**: All customer cards become invalid (business ID changes)
- Supplier re-issues cards to legitimate customers as they visit
- Communicate change to customers (signage, social media, etc.)

**Why This Is By Design:**
P2P architecture means:
- No central authority to push revocation notices
- Customer cards are independent of supplier state
- Cards validated by cryptographic signatures, not server lookups
- Trade-off: Privacy & offline-first vs. centralized control

**Comparison to Alternatives:**
| Architecture | Revocation | Privacy | Offline | Complexity |
|--------------|-----------|---------|---------|------------|
| **P2P (LoyaltyCards)** | ❌ No individual | ✅ Full | ✅ Yes | ⭐ Low |
| Server-Based | ✅ Yes | ❌ Limited | ❌ No | ⭐⭐⭐ High |
| Blockchain | ⚠️ Complex | ✅ Partial | ❌ No | ⭐⭐⭐⭐ Very High |

**Mitigations:**
1. **Documented Limitation**: TERMS_OF_SERVICE.md Section 6.2
2. **Supplier Training**: USER_GUIDE.md explains revocation limitations
3. **Fraud Prevention**: V-005 device mismatch detection identifies duplicates
4. **Manual Process**: Suppliers maintain discretion at redemption time

**User Guidance (From TOS):**
> "If you need to revoke cards, you must reset your entire business configuration. All existing customer cards will become invalid. You will need to re-issue cards to legitimate customers. Use Case: Business was compromised, mass fraud detected, security breach."

**Resolution:** 📋 BY DESIGN & DOCUMENTED - Inherent architectural limitation, alternatives provided

---

## Summary Table

| ID | Vulnerability | Severity | Status | Build | Notes |
|----|--------------|----------|--------|-------|-------|
| V-001 | Simple Mode Self-Redemption | LOW | BY DESIGN | - | Trust-based by design |
| V-002 | Private Key Extraction | CRITICAL | ✅ FIXED | 20 | Biometric auth added |
| V-003 | QR Screenshot Reuse | HIGH | ✅ VERIFIED | - | Database PK prevents duplication |
| V-004 | Time Manipulation | HIGH | ✅ VERIFIED | - | Supplier visual verification |
| V-005 | Multi-Device Duplication | HIGH | ✅ FIXED | 21 | Device tracking + warnings |
| V-006 | Device Storage Limits | LOW | DOCUMENTED | - | User responsibility in TOS |
| V-007 | Recovery Backup Expiration | LOW | DEFERRED | - | Future enhancement |
| V-008 | QR Entropy / Guessing | MEDIUM | DEFERRED | - | Needs formal analysis |
| V-009 | Card Revocation | LOW | BY DESIGN | - | Architectural limitation |

---

## Recommendations

### For v0.2.0 Release (TestFlight)

**Ready for Release:**
- ✅ All CRITICAL and HIGH severity issues resolved or verified
- ✅ Security model documented and explained
- ✅ Terms of Service covers limitations and responsibilities
- ✅ V-002 and V-005 fixes need physical device testing

**Testing Priorities:**
1. V-002: Verify biometric auth on physical iOS devices
2. V-005: Test device mismatch warning flow
3. Security: Attempt known attack scenarios (QR reuse, time manipulation)

### For Future Releases

**Short-Term (v0.3.0):**
- V-003 UX: Better error message for duplicate stamp scans
- V-006: Add storage usage monitoring and warnings
- Documentation: Add storage management to USER_GUIDE.md

**Medium-Term (v0.4.0):**
- V-007: Implement optional backup expiration or password protection
- V-008: Conduct formal entropy analysis and security audit

**Long-Term (v1.0+):**
- Consider blockchain-based revocation tracking (if privacy trade-off acceptable)
- Implement advanced fraud detection (ML-based pattern analysis)
- Add optional server-side verification mode (hybrid architecture)

---

## Security Audit Sign-Off

**Assessment Completed:** April 17, 2026  
**Build Assessed:** v0.2.0 Build 21  
**Critical Issues:** 0 remaining  
**High Issues:** 0 remaining (2 verified, 1 fixed)  

**Recommendation:** ✅ **APPROVED FOR TESTFLIGHT** with physical device testing of V-002 and V-005

---

**Document Version:** 1.0  
**Next Review:** After TestFlight pilot testing or before App Store submission

---

## 2026-07-25 Security Review — Signature Coverage & Redemption Verification

**LoyaltyCards v1.1.0+12 (branch `feature/SecurityReview`, forked from `feature/packageUpdate`)**
**Assessment Date:** July 25, 2026
**Assessor:** AI-assisted review (4 parallel focused analyses — cryptography/key management, data storage/SQL, business logic/authentication, platform config/input validation), each finding independently verified by direct code reading before being recorded here.
**Trigger:** Requested after v1.0.3+11 was submitted for App Store review, as a general robustness/vulnerability pass separate from the dependency-update work on `feature/packageUpdate`.
**Scope:** Full-app review, not limited to a specific feature — this is the first review of this depth since the April 2026 assessment above, and the first to specifically trace what data each ECDSA signature actually covers versus what's checked at each verification point.

### Status Overview

- ✅ **CRITICAL — FIXED (2026-07-25, `feature/SecurityReview`):** 3 (V-010, V-011, V-012)
- ✅ **HIGH — FIXED:** 3 (V-013, V-014, V-016)
- 📋 **HIGH — BY DESIGN:** 1 (V-015)
- ✅ **MEDIUM/LOW/INFORMATIONAL — FIXED:** 4 of 6 (see "Additional Observations" below)
- 📋 **MEDIUM/LOW/INFORMATIONAL — left as-is by deliberate decision:** 2 of 6

**Update 2026-07-25/26:** All seven main findings from this review are resolved - V-010 through V-014 and V-016 fixed in code, V-015 resolved as an accepted by-design trade-off (consistent with V-001's precedent). 4 of 6 lower-priority observations are fixed; the remaining 2 (expiry-via-local-clock, device-mismatch advisory-only) were reviewed and deliberately left as-is with documented rationale, not overlooked. Plus a full missing-test-coverage pass across both apps (329 tests total, up from 179 at the start of this review). `flutter analyze` clean (no errors) and `flutter test` green across all three packages after every change - see each entry below for exactly what changed, and the "Test Coverage Added" section for the full list of new test files.

---

### V-010: Unsigned `stampCount` Enables Single-Scan Full-Card Completion in Secure Mode

**Severity:** CRITICAL
**Status:** ✅ FIXED (2026-07-25)
**Affected Component:** Customer App - Secure Mode stamp crediting
**Relationship to prior findings:** Distinct mechanism from **V-003** (QR Screenshot Reuse). V-003 verified that replaying the *same* `stampId` is safely absorbed by the database's primary-key `ConflictAlgorithm.replace`. This finding is not about replaying a stamp ID — it's about tampering a field on a single, otherwise-genuine, never-before-seen stamp token so that ONE legitimate scan mints many new, uniquely-IDed stamp rows. V-003's mitigation does not apply here.

**Description:**
`StampToken.getSignatureData()` (`shared/lib/models/qr_tokens.dart:354-356`) signs only `'$cardId:$stampNumber:$timestamp:$previousHash'`. The `stampCount` field (how many stamps this single token should grant — a REQ-022 "multi-denomination" feature) is **not part of the signed data**. `TokenValidator.validateStampToken` does check `stampCount <= stampsRequired` (`token_validator.dart:113`), but only as an upper bound — it does not, and cannot, detect that `stampCount` was changed after signing, because the signature itself never covered it.

`qr_scanner_screen.dart:475-512` then runs unconditionally (regardless of `card.mode`): if `token.stampCount > 1`, it inserts `stampCount - 1` additional `Stamp` rows, each reusing `token.signature` verbatim with **no further per-stamp verification**.

**Concrete exploit:**
1. A customer receives one genuine, correctly-signed Secure Mode `StampToken` from a supplier (`stampCount` defaults to 1 for normal single-stamp issuance).
2. The customer extracts the QR's raw JSON (any QR decoder, or by decoding a screenshot), changes `"stampCount": 1` to `"stampCount": <stampsRequired>`, and re-encodes it as a QR.
3. Scans it with their own device. `TokenValidator` verifies the ECDSA signature — which still checks out, since `stampCount` was never signed — and passes the `stampCount <= stampsRequired` bound.
4. The app inserts `stampsRequired` stamp rows, all citing the one genuine signature, completing the card from a single real interaction.

**Impact:** Full defeat of Secure Mode's core anti-fraud claim ("each stamp is cryptographically signed... can't be reused or forged," per the in-app onboarding copy) for any card, using only a QR decoder/encoder — no cryptography, key material, or supplier-device access required.

**Fix Implemented (2026-07-25):**
- `StampToken.getSignatureData()` now signs `cardId:stampNumber:timestamp:previousHash:stampCount:expiryDate:scanInterval` instead of stopping at `previousHash`. Matching change on the signing side in `qr_token_generator.dart` (`generateStampToken`), so tampering `stampCount` post-signing now invalidates the ECDSA signature.
- Confirmed via direct code inspection (`supplier_stamp_card.dart`) that Secure Mode issuance (`_generateAndShowStamp`) never sets `stampCount`/`expiryDate`/`scanInterval` — those are exclusively a Simple/Express Mode (REQ-022) feature. Added a second, independent layer of defense: `qr_scanner_screen.dart` now explicitly rejects any Secure Mode token with `stampCount != 1` outright, rather than relying solely on the signature catching it.
- Both defenses verified with new tests in `shared/test/qr_tokens_test.dart` (exact-string assertion + a test proving tampering `stampCount` changes the signed data) proving the fix actually closes the gap, not just that the code compiles.

**Files Modified:**
- `shared/lib/models/qr_tokens.dart` (`StampToken.getSignatureData()`)
- `supplier_app/lib/services/qr_token_generator.dart` (`generateStampToken`)
- `customer_app/lib/screens/customer/qr_scanner_screen.dart` (reject `stampCount != 1` in the Secure Mode branch)
- `shared/test/qr_tokens_test.dart` (new regression tests)

**Resolution:** ✅ FIXED - Signature now covers `stampCount`; Secure Mode additionally hard-rejects any token where it isn't exactly 1.

---

### V-011: Unsigned Card `mode` Field Enables Secure→Simple Downgrade at Issuance

**Severity:** CRITICAL
**Status:** ✅ FIXED (2026-07-25)
**Affected Component:** Customer App - Card issuance and mode-gated validation

**Description:**
`CardIssueToken.getSignatureData()` (`shared/lib/models/qr_tokens.dart:167-170`) signs `'$businessId:$businessName:$publicKey:$stampsRequired:$brandColor:$cardIdValue:$timestamp'` — `mode` is absent. `card.mode` is read from this token once at issuance and persisted to the local DB; every later stamp/redemption decision correctly trusts that *stored* value rather than re-reading mode from each new scan (`qr_scanner_screen.dart:390`) — which is the right architectural pattern in general, but it means the one moment `mode` is trusted from an external, attacker-reachable source (the issuance token) is also unprotected by the signature.

**Concrete exploit:**
1. Attacker obtains any validly-signed `CardIssueToken` for a Secure Mode business (their own scan, a shared screenshot, a photographed display QR).
2. Edits `"mode":"secure"` → `"mode":"simple"` in the JSON. The signature still verifies — `mode` was never part of what it covers.
3. Scans the edited token. The resulting card is permanently created in Simple/Express mode on that device.
4. Every future stamp for that card now takes the `else` branch at `qr_scanner_screen.dart:403` ("skip crypto"), which only checks `stampCount <= stampsRequired` and (if present) an unsigned `expiryDate` — it will accept fully self-fabricated stamp tokens with garbage `signature`/`previousHash` values.

**Impact:** A one-time, offline edit permanently strips all cryptographic protection from a card, with no further interaction with a real supplier device needed after the initial (possibly legitimately obtained) issuance token.

**Fix Implemented (2026-07-25):**
- `CardIssueToken.getSignatureData()` now signs `...timestamp:mode` (using `mode.toStorageString()`) instead of stopping at `timestamp`. The signing side (`qr_token_generator.dart`'s `generateCardIssueToken`) already called `token.getSignatureData()` directly rather than duplicating the string, so it picked up the fix automatically with no separate change needed there.
- Verified with new tests in `shared/test/qr_tokens_test.dart` (exact-string assertion + a test proving changing `mode` after construction changes the signed data).

**Files Modified:**
- `shared/lib/models/qr_tokens.dart` (`CardIssueToken.getSignatureData()`)
- `shared/test/qr_tokens_test.dart` (new regression tests)

**Resolution:** ✅ FIXED - Signature now covers `mode`; a post-signing edit from `secure` to `simple` invalidates the signature and is rejected at verification.

---

### V-012: Redemption Never Verifies Stamp Signatures — Verification Code Exists But Is Dead

**Severity:** CRITICAL
**Status:** ✅ FIXED (2026-07-25)
**Affected Component:** Supplier App - Redemption flow
**Relationship to prior findings:** This directly undermines the "Secure Mode adds crypto protection" framing used in the analysis for **V-004** and **V-005** above — that framing assumed the redemption step itself checks stamp signatures. It doesn't.

**Description:**
`TokenValidator.validateRedemptionRequest()` (`customer_app/lib/services/token_validator.dart:229`) exists, is correctly implemented, and would re-derive each stamp's signing data and verify it against the business's public key — but it is **never called anywhere in the codebase** (confirmed via `grep -rn "validateRedemptionRequest("` across both app trees — the only hit is the function's own definition).

The actual redemption path, `supplier_redeem_card.dart:536-669` (`_processCardQR` → `_showSecureModeRedemptionConfirmation`), parses the customer-supplied `RedemptionRequestToken`, logs `"Signatures to verify: ${token.stampSignatures.length}"` (line 553, suggesting verification was intended), checks only `hasDeviceMismatch()`, and immediately signs a new `RedemptionToken` for `token.stampsCollected` — the customer's self-reported count. Confirmed via direct grep of the file: zero calls to `verifySignature`, `CryptoUtils`, or any `KeyManager.verify*` method anywhere in `supplier_redeem_card.dart`.

**Concrete exploit:** Combined with V-010/V-011, a customer can fabricate a "complete" card entirely offline (no real stamps ever collected) and present it for redemption. The supplier's device has no independent cryptographic check to catch this — it trusts the customer's claimed `stampsCollected` count outright. Even without V-010/V-011, a customer could set `stampSignatures` to an arbitrary list of junk strings satisfying only `RedemptionRequestToken.isValid()`'s length/non-empty checks (`qr_tokens.dart:417-429`) and redeem successfully.

**Impact:** The redemption step — the one that actually costs the business a reward — currently performs no cryptographic verification at all, regardless of Secure Mode's other protections working correctly or not.

**Fix Implemented (2026-07-25):**

The originally-recommended fix (wire up the existing `validateRedemptionRequest`) turned out not to be viable as-is: that function lives in `customer_app`, which `supplier_app` cannot import (separate Flutter packages, only `shared` is common to both), and it expects full `List<Stamp>` objects with timestamps that the supplier never actually receives — `RedemptionRequestToken` only ever transmitted bare signature strings (`stampSignatures: List<String>`), not enough data to reconstruct what was signed. A real fix required a small protocol change:

1. Added `RedemptionStampProof { signature, timestamp }` to `shared/lib/models/qr_tokens.dart` and changed `RedemptionRequestToken.stampSignatures: List<String>` → `stampProofs: List<RedemptionStampProof>`, so the supplier receives enough data (signature + timestamp per stamp) to reconstruct each stamp's original signed string. `fromJson` still accepts the old `stampSignatures` key as a fallback (timestamp defaults to 0), but such tokens will always fail verification, not silently succeed - there are no production tokens of the old shape to migrate, this is just defensive parsing.
2. Added `CryptoUtils.verifyRedemptionStampChain()` to `shared/lib/utils/crypto_utils.dart` - a new shared function (callable from both apps) that walks the stamp chain, reconstructing `cardId:stampNumber:timestamp:previousHash:1::` for each stamp (the constant `1::` suffix reflects that genuine Secure Mode stamps always have `stampCount=1, expiryDate=null, scanInterval=null` baked in per the V-010 fix - confirmed by inspecting `supplier_stamp_card.dart`, which never sets those fields for Secure Mode issuance) and verifying against the business's public key.
3. Wired this into `supplier_redeem_card.dart`'s `_showSecureModeRedemptionConfirmation`: for Secure Mode businesses, redemption now requires a `RedemptionRequestToken` with a fully-verifying stamp chain, or it's rejected outright. The legacy `LOYALTYCARD:REDEEM:` string format (which carries no signatures at all) is now rejected for Secure Mode businesses specifically, since it can't be verified - it remains accepted only where `business.mode != secure` (Express/Simple Mode's honor-based system, per V-001, is unaffected).
4. Updated both places that build a `RedemptionRequestToken` on the customer side (`customer_app/lib/services/qr_token_generator.dart` and a second, independent inline JSON builder in `customer_app/lib/screens/customer/customer_card_detail.dart`) to include each stamp's timestamp.
5. Removed the old, dead, subtly-inconsistent `TokenValidator.validateRedemptionRequest()` from `customer_app` (it used `stamp.timestamp` directly in a string interpolation rather than `.millisecondsSinceEpoch` - another latent bug that never surfaced only because the function was never called).
6. Added 6 new direct tests for `verifyRedemptionStampChain` in `shared/test/utils/crypto_utils_test.dart`: genuine chain accepted, fabricated chain rejected, genuine-stamps-plus-one-fabricated-stamp rejected, wrong `cardId` rejected, wrong business public key rejected, reordered stamps rejected, empty list rejected outright rather than vacuously passing.

**Files Modified:**
- `shared/lib/models/qr_tokens.dart` (`RedemptionStampProof` new class, `RedemptionRequestToken.stampProofs`)
- `shared/lib/utils/crypto_utils.dart` (`verifyRedemptionStampChain`)
- `supplier_app/lib/screens/supplier/supplier_redeem_card.dart` (verification wired into the real redemption flow, both direct and device-mismatch "proceed anyway" call sites; also added a `mounted` guard on the same async gap while touching this method)
- `customer_app/lib/services/qr_token_generator.dart` (`generateRedemptionRequest` builds `stampProofs`)
- `customer_app/lib/screens/customer/customer_card_detail.dart` (`_generateCardQR`'s inline duplicate updated to match)
- `customer_app/lib/services/token_validator.dart` (dead `validateRedemptionRequest` removed)
- `shared/test/qr_tokens_test.dart`, `shared/test/utils/crypto_utils_test.dart` (updated/new tests)

**Resolution:** ✅ FIXED - Secure Mode redemption now cryptographically verifies every claimed stamp before the supplier signs off on a reward; a fabricated or replayed redemption request is rejected rather than trusted.

---

### V-013: No Duplicate-Redemption Protection

**Severity:** HIGH
**Status:** ✅ FIXED (2026-07-25)
**Affected Component:** Supplier App - Redemption flow, Business Repository
**Relationship to prior findings:** Extends **V-005** (Multi-Device Card Duplication). V-005 added *detection/warning* for device mismatches at redemption time, with supplier discretion to proceed. This finding is different: there is no check at all — on any device, matching or not — for whether a given card's stamps have already been redeemed before.

**Description:**
`BusinessRepository.logRedemption()` (`business_repository.dart:190`) only *writes* a redemption record; nothing queries prior redemptions for a `cardId` before a new `RedemptionToken` is signed. The only "already redeemed" state that exists is the `isRedeemed` flag on the *customer's own* local `Card` record — which the customer fully controls (e.g., a restored pre-redemption local DB backup resets it to `false`).

**Concrete exploit:** A customer redeems a card normally, then restores an earlier local backup (or otherwise resets `isRedeemed` on their device) and re-presents the same, genuinely-signed stamp data for a second redemption. Nothing on the supplier side has a record to check it against.

**Fix Implemented (2026-07-25):**
- Added `BusinessRepository.hasBeenRedeemed(cardId)`, querying the existing `redemptions` table (`SELECT COUNT(*) ... WHERE card_id = ?` — no schema migration needed, the table already existed with a `card_id` column).
- Confirmed this check is safe and won't block legitimate repeat business: each stamp-collection cycle gets a brand-new `cardId` (`'${businessId}_${timestamp}'`, see `qr_scanner_screen.dart`'s post-redemption new-card creation) - a `cardId` is never reused for a customer's next card.
- Wired into `_showSecureModeRedemptionConfirmation` in `supplier_redeem_card.dart`, before both the V-012 verification and the signing step - applies to both modes, since duplicate-redemption is a general concern, not crypto-specific.
- New test file `supplier_app/test/services/business_repository_test.dart` (4 tests): no history returns false, logging a redemption returns true for that card, unrelated cards aren't flagged, and a direct replay-of-the-same-card scenario is rejected.

**Files Modified:**
- `supplier_app/lib/services/business_repository.dart` (`hasBeenRedeemed`)
- `supplier_app/lib/screens/supplier/supplier_redeem_card.dart` (check wired into the confirmation flow)
- `supplier_app/test/services/business_repository_test.dart` (new)

**Resolution:** ✅ FIXED - A card that's already been redeemed on this device is now rejected outright, independent of device-mismatch detection.

---

### V-014: Biometric App-Lock Fails Open on Any Exception

**Severity:** HIGH
**Status:** ✅ FIXED (2026-07-25)
**Affected Component:** Customer App - App-lock authentication gate
**Relationship to prior findings:** Different from **V-002** (which added biometric gating to the Supplier App's backup/clone screens, and remains correctly fail-closed there). This is the separate, customer-facing app-lock toggle in `main.dart`.

**Description:**
`_checkAuthRequirement()` (`customer_app/lib/main.dart:65-99`) wraps both the `SharedPreferences` read (`require_app_lock`) and the `_biometricAuth.authenticate()` call in a single `try`. The `catch` block explicitly does:
```dart
} catch (e) {
  AppLogger.error('Error checking auth requirement: $e', tag: 'Security');
  setState(() {
    _isAuthenticated = true; // Fail open for better UX
    _isAuthenticating = false;
  });
```
Any exception — a `SharedPreferences` plugin error, a `local_auth` platform-channel failure, or `authenticate()` throwing instead of returning `false` — unlocks the app with **no successful authentication**. `BiometricAuthService.authenticate()` itself is correctly fail-closed on every internal path; this bug is isolated to this one caller.

**Fix Implemented (2026-07-25):**
- The `catch` block now sets `_isAuthenticated = false` instead of `true`. A `SharedPreferences` failure or an `authenticate()` exception now lands the user on the existing "App Locked" screen (which already has a retry button calling `_checkAuthRequirement` again), rather than silently unlocking. No new UI needed - the fail-closed path was already built, just never reached.

**Files Modified:**
- `customer_app/lib/main.dart` (`_checkAuthRequirement`)

**Resolution:** ✅ FIXED - Any exception during the auth check now fails closed, not open.

---

### V-015: Scan-Cooldown Rate Limiting Is Fully Client-Side, Per-Device, and Keyed to Untrusted Data

**Severity:** HIGH
**Status:** 📋 BY DESIGN (2026-07-25) - documented, not a code change
**Affected Component:** Customer App - Rate limiting
**Relationship to prior findings:** Adjacent to **V-001** (Simple Mode Self-Redemption, accepted by-design trust model) but distinct — V-001 is about the redemption honor system; this is specifically about the supplier-configured scan cooldown (5-60s, REQ-022) being technically bypassable, which the in-app copy presents as a real fraud "protection" rather than an honor-system convenience.

**Description:**
`canReceiveStamp` (`customer_app/lib/services/rate_limiter.dart:32-79`) checks only the *local* `stamps` table for that `cardId` on that device, and uses `scanInterval` from the token itself as the effective cooldown — a field that, like `stampCount` (V-010), is not part of any signed payload.

**Concrete exploits:**
- **Two-device bypass:** A static, reusable Express Mode stamp QR scanned from two separate app installs each sees an empty local history — the configured cooldown never engages across devices for the same physical visit.
- **Forged interval:** An attacker-crafted token can set `"scanInterval": 0`, removing the cooldown entirely on their own device.

**Decision (2026-07-25):** Resolved as **by design**, the same way as V-001. `scanInterval` is never cryptographically enforced in *any* mode - it's a client-side friction/UX signal, not a security boundary, even in Secure Mode. Signing it (as V-010 now does defensively for the fields that matter) wouldn't close the two-device bypass anyway, since Express Mode performs no signature verification of any kind - that's the whole point of Express Mode's honor-based design. The two-device bypass specifically is an inherent limitation of a P2P architecture with no server to check across devices, not a bug to fix - same category as V-009's card-revocation limitation. A real fix would mean adding server-side or cross-device state to Express Mode, contradicting its purpose (fast, no-equipment, trust-based checkout).

No code changes made. If the in-app/marketing copy anywhere frames the scan cooldown as fraud-proof "protection" rather than accepted friction, it should be reviewed for accuracy (mirrors V-001's existing guidance that Simple/Express Mode is suitable only for low-value rewards).

**Resolution:** 📋 BY DESIGN - Consistent with V-001's Express Mode trust model; not a fixable gap without contradicting the mode's purpose.

---

### V-016: Recovery Backup Signature Is Self-Certifying, Not Authenticating

**Severity:** HIGH
**Status:** ✅ FIXED (2026-07-25)
**Affected Component:** Supplier App - Backup/restore (`SupplierConfigBackup`)
**Relationship to prior findings:** Different angle from **V-002** (Private Key Extraction, fixed via biometric gating on the *legitimate owner's* device). This finding is about the backup format itself being importable by anyone, from anywhere, regardless of biometric gating on the originating device.

**Description:**
`SupplierConfigBackup`'s integrity signature (`shared/lib/models/supplier_config_backup.dart:124-141`) is an HMAC whose key is derived (HKDF) from the `privateKey` field — which is itself part of the same signed payload. Since the algorithm is public, anyone can generate a fresh key pair, embed arbitrary `businessName`/`stampsRequired`/`operationMode` values, compute a signature that validates, and produce a backup QR that `import_business_screen.dart` will accept — it only checks "no existing business already configured on this device," not that the imported identity matches anything previously trusted.

**Impact:** Lower severity than V-010/V-011/V-012 in isolation (it lets someone impersonate a *fictitious* business, not steal a real one's key), but worth fixing since it means the backup format provides no actual authentication guarantee — only structural integrity (the fields weren't corrupted in transit).

**Fix Implemented (2026-07-25):**
- Full structural fix (independently authenticating backups without a server) deferred as a harder architectural problem - implemented the recommended lowest-effort mitigation instead: `import_business_screen.dart` now shows an explicit confirmation dialog after signature verification but before anything is stored, displaying the business name and a short SHA-256 fingerprint of the public key (grouped hex, not the raw base64 blob), with copy explaining that anyone can create a backup claiming any business name. Import only proceeds if the user taps "Restore This Business"; cancelling resets state and restarts the camera for another scan attempt.

**Files Modified:**
- `supplier_app/lib/screens/supplier/import_business_screen.dart` (`_confirmImport`, `_publicKeyFingerprint`)

**Resolution:** ✅ FIXED (partial/mitigated - full authentication isn't achievable without a server) - a scanned backup is no longer silently trusted; the user must explicitly confirm what they're restoring.

---

### Additional Observations (Medium/Low/Informational)

Found during the same review, lower priority than V-010–V-016. Three of the six were fixed on 2026-07-25 alongside the missing-test-coverage pass below (items 3, 4, 6 per the numbering used when this list was reviewed with the user); the remaining three are documented only, tracked for a later pass.

**Fixed (2026-07-25):**

- ✅ **`SupplierConfigBackup.fromQRString` now wraps parsing in try/catch**, rethrowing as a well-typed `FormatException` with context instead of letting a raw JSON/cast error propagate. Kept the throwing contract (its one caller already handles it) rather than switching to a nullable return, to avoid an unnecessary caller-side restructure. *(shared/lib/models/supplier_config_backup.dart)*
- ✅ **`flutter_secure_storage`'s iOS Keychain accessibility tightened** from `first_unlock` to `first_unlock_this_device` — this Keychain item no longer migrates via an encrypted iTunes/iCloud device backup/restore, closing a side-channel around the app's own explicit, biometric-gated Recovery Backup / Clone Device QR flow (those flows are unaffected - they re-derive and re-store keys via a scanned QR, independent of this setting). Also verified the "backup save location defaults to public storage" half of this observation: on iOS (this app's actual shipping platform), `saveToFiles` already writes to the app's private sandboxed Documents directory and immediately opens the system share sheet for the user to pick the real destination - the public-directory default is Android-specific code (`/storage/emulated/0/Download`), and this app doesn't currently build/ship for Android. *(supplier_app/lib/services/key_manager.dart)*
- ✅ **`SignatureFormat` rebuilt from scratch and actually wired in.** Investigation found it was worse than "mostly unused" - every method in it was 100% dead in production, and its only caller (`StampSigner`, a complete alternate stamp-signing implementation) was *also* dead code, never instantiated outside its own test. Worse, `StampSigner.calculateStampHash` used a different hash-chain algorithm than what production actually uses (`previousHash` = the raw prior signature, not a SHA-256 digest of stamp fields) - a real risk if anyone had wired it in later, since it would have silently failed to verify genuine production stamps. Removed `StampSigner` and its test (`stamp_signer_test.dart`, 13 tests - all exercising the abandoned algorithm, not real coverage). Replaced `SignatureFormat` with two accurate methods (`stampChainData`, `redemptionTokenData`) and routed the actual live duplicated string-literals through them: `StampToken`/`RedemptionToken.getSignatureData()` and the corresponding signing code in `qr_token_generator.dart`/`supplier_redeem_card.dart` now share one source of truth instead of hand-duplicated strings that could drift. *(shared/lib/utils/signature_format.dart, shared/lib/models/qr_tokens.dart, supplier_app/lib/services/qr_token_generator.dart, supplier_app/lib/screens/supplier/supplier_redeem_card.dart)*

**Bonus fix found while adding test coverage:** `SupplierDatabaseHelper` had no `resetForTesting`-style test-database-name support (unlike `customer_app`'s `DatabaseHelper`, which already had one). Every supplier_app test touching the database shared the same on-disk singleton file, and Dart's test runner executing files concurrently caused real cross-file interference - confirmed via a reproducible failure (`business_repository_test.dart`'s replay-redemption test failing only when the full suite ran together, never in isolation). Added the same `resetForTesting(testDatabaseName:)` mechanism `DatabaseHelper` already had. *(supplier_app/lib/services/supplier_database_helper.dart)*

**Fixed (2026-07-26, second pass):**

- ✅ **Release-build logs no longer include stack traces.** Weighed the actual tradeoff first rather than reflexively dropping them: `AppLogger.error()` unconditionally passed `stackTrace` through regardless of build mode (`kDebugMode` only gates the *minimum* logged severity, not what an error-level call includes), and this app has no remote crash-reporting pipeline (no Crashlytics/Sentry) - these logs only ever reach the local OS unified log, with no established support workflow that collects them from real users. So the debugging value was mostly theoretical, while a stack trace is real (if modest) internal-structure exposure to anyone with brief physical access to an unlocked device. One central fix: `AppLogger.error()` now only includes `stackTrace` when `kDebugMode` is true; the error *message* (often a caught exception's `toString()`, genuinely useful support context and far less revealing) still logs in both modes. *(shared/lib/utils/app_logger.dart)*

**Still documented only, not fixed (deliberately, low value relative to effort):**

- **Expiry checked against local device clock, not a trusted source.** The 2-minute stamp / 5-minute issuance expiry windows (`token_validator.dart:52-59, 139-147`) compare `DateTime.now()` (unattested) against the *signed* `token.timestamp` — the timestamp itself can't be forged, but rolling the verifying device's own clock backward shrinks the computed `age` and can make an otherwise-stale token appear fresh. Narrower than V-004's original scope (which addressed forward-clock rate-limit bypass and signature-protected stamp timestamps, both still valid conclusions). **Decision (2026-07-26):** left as-is. iOS exposes no trusted/tamper-resistant wall clock to third-party apps without network access; the one real offline mitigation (cross-checking wall-clock delta against a monotonic elapsed-time reference, which can't be user-set) only narrows the window rather than closing it, and doesn't survive a reboot. Not worth the complexity at this app's stakes (a loyalty stamp, not currency).
- **Device-mismatch "Proceed Anyway" applies no *additional* restriction beyond the supplier's own judgment** (`supplier_redeem_card.dart:679-745`) — still advisory/discretionary per V-005's original design. Not a compounding gap - since V-012/V-013 fixed, the stamp-chain verification and duplicate-redemption check still run on the "proceed anyway" path (the `token` is passed through), so a supplier choosing to proceed despite a device mismatch still can't push through fabricated or already-redeemed stamps. **Decision (2026-07-26):** left as advisory-only, deliberately. This signal is predominantly a *legitimate-use* detector, not a fraud detector - `identifierForVendor` (what the device ID is derived from) genuinely changes across an iCloud/iTunes restore to new hardware, so the single most common trigger is a customer upgrading phones, not sharing. Deliberate cloning is a narrower case, and V-012/V-013 already cap the damage regardless (a card can only be redeemed once, on any device - sharing a backup across two phones nets the same single reward a normal customer gets, not a repeatable exploit). Making this a hard block instead of a warning would trade real friction for legitimate phone upgrades against negligible additional fraud-prevention value.

No SQL injection anywhere (parameterized queries throughout), no plaintext secrets in `shared_preferences`, path-traversal properly sanitized in file saves, no ATS weakening, no deep-link attack surface, and QR/JSON parsing is empirically resistant to size/depth DoS well beyond real QR code capacity — all confirmed clean.

---

### Test Coverage Added (2026-07-25)

Closed the missing-coverage backlog noted in `docs/project-management/PACKAGE_UPDATE_PLAN.md`'s "Deferred" section:

| Area | New test file | Tests |
|---|---|---|
| `customer_app/lib/services/database_helper.dart` | `test/services/database_helper_operations_test.dart` | 4 |
| `customer_app/lib/services/stamp_repository.dart` | `test/services/stamp_repository_test.dart` | 14 |
| `customer_app/lib/services/transaction_repository.dart` | `test/services/transaction_repository_test.dart` | 8 |
| `customer_app/lib/services/qr_token_generator.dart` | `test/services/qr_token_generator_test.dart` | 7 |
| `supplier_app/lib/services/supplier_database_helper.dart` | `test/services/supplier_database_helper_test.dart` | 5 |
| `supplier_app/lib/services/qr_token_generator.dart` | `test/services/qr_token_generator_test.dart` | 10 (real end-to-end signing via `flutter_secure_storage`'s official in-memory test fake, not just the model layer) |
| `supplier_app/lib/screens/supplier/supplier_onboarding.dart` (mode selection UI) | `test/screens/supplier_onboarding_mode_selection_test.dart` | 6 (widget tests) |
| `supplier_app/lib/services/business_repository.dart` (V-013, added earlier) | `test/services/business_repository_test.dart` | 4 |

Database migration/backup/restore (`_onUpgradeWithSafety`, `_createDatabaseBackup`, etc. in both apps) remains untested - these are private methods only reachable via a real version bump on an existing DB file, and fabricating a fake "old schema" without access to real historical versions would test invented behavior rather than the real migration path. Noted as a known gap, not attempted.

Final count after this pass: `shared` 151 tests, `customer_app` 120 tests, `supplier_app` 58 tests (329 total) — all passing, `flutter analyze` clean across all three packages.

---

### Fix Plan

**Phase 1 (complete, 2026-07-25):** V-010, V-011, V-012 — the three that combined into a complete offline bypass of Secure Mode. Committed on `feature/SecurityReview` (`07690eb`).
**Phase 2 (complete, 2026-07-25):** V-013, V-014, V-016 fixed in code; V-015 resolved by-design (documented, no code change - see its entry above for rationale).

All seven findings closed. Final verification: `flutter analyze` clean (no errors) and `flutter test` green across all three packages - shared 151, customer_app 87, supplier_app 50 (46 + 4 new `business_repository_test.dart` tests for V-013).

**Remaining (not part of this review's scope, tracked separately):** the "Additional Observations" list above (Medium/Low/Informational, not blocking) and the pre-existing `SignatureFormat` drift-risk cleanup noted there.

**Document Version:** 4.0 (2026-07-25, all V-010–V-016 fixes + 3 of 6 lower-priority observations + full test coverage pass recorded)
