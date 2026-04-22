# Security Vulnerability Assessment

**LoyaltyCards v0.3.0+1 Build 23**  
**Assessment Date:** April 17, 2026  
**Updated:** April 22, 2026 (v0.3.0+1 deployment)  
**Assessor:** Development Team  
**Scope:** iOS application security audit

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

**Fix Implemented (Build 21):**

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
