# Code Review: LoyaltyCards v0.2.0

**Review Date:** April 14, 2026  
**Version Reviewed:** v0.2.0 (Build 4) - Currently on TestFlight  
**Reviewer:** GitHub Copilot  
**Scope:** Full application suite (customer_app, supplier_app, shared)

---

## Executive Summary

The LoyaltyCards application suite demonstrates **good architectural design** with clear separation of concerns, thoughtful security considerations, and well-structured data models. The codebase is **suitable for pilot testing** in its current state.

However, **two critical issues** were identified that should be addressed before wider distribution:

1. **🔴 CRITICAL:** Broken public key encoding in card issuance
2. **🔴 CRITICAL:** Excessive debug logging exposing system internals

Additionally, opportunities exist to reduce code duplication, improve error handling, and enhance production readiness.

### Quality Metrics Summary

| Category | Rating | Status |
|----------|--------|--------|
| Architecture | ⭐⭐⭐⭐ | Excellent - Clean separation, well-organized |
| Security Implementation | ⭐⭐⭐ | Good - Some debug exposure issues |
| Error Handling | ⭐⭐ | Needs Work - Inconsistent patterns, silent failures |
| Code Duplication | ⭐⭐ | Needs Work - Cryptographic code duplicated |
| Testing | ⭐ | No unit tests found |
| Documentation | ⭐⭐⭐ | Adequate - Code readable, minimal inline docs |
| Performance | ⭐⭐⭐⭐ | Good - Efficient queries, no obvious bottlenecks |

---

## 🔴 Critical Issues (Fix Immediately)

### 1. Broken Public Key Encoding in Card Issuance

**Location:** [supplier_app/lib/services/stamp_signer.dart](supplier_app/lib/services/stamp_signer.dart#L113-L117)

**Issue:**
```dart
String _encodePublicKey(dynamic publicKey) {
  // This would use the KeyManager's encoding logic
  // For now, we'll use a placeholder
  return publicKey.toString();  // ❌ Returns "Instance of 'ECPublicKey'"
}
```

**Impact:** 
- Card issuance QR codes contain invalid public key data
- Customer app cannot verify supplier signatures
- **This breaks the entire cryptographic security model**
- Cards may appear to work in simple mode but fail in secure mode

**Verification Status:** 🚨 **UNVERIFIED** - This may not have been tested yet in TestFlight

**Fix Required:**
```dart
String _encodePublicKey(ECPublicKey publicKey) {
  // Use KeyManager's existing encoding logic
  final params = publicKey.parameters as ECCurve_secp256r1;
  final x = publicKey.Q!.x!.toBigInteger()!;
  final y = publicKey.Q!.y!.toBigInteger()!;
  
  final xBytes = _encodeBigInt(x);
  final yBytes = _encodeBigInt(y);
  
  final combined = <int>[];
  combined.addAll(_encodeLength(xBytes.length));
  combined.addAll(xBytes);
  combined.addAll(_encodeLength(yBytes.length));
  combined.addAll(yBytes);
  
  return base64Encode(combined);
}

List<int> _encodeBigInt(BigInt value) {
  final hex = value.toRadixString(16);
  final paddedHex = hex.length.isOdd ? '0$hex' : hex;
  return List<int>.generate(
    paddedHex.length ~/ 2,
    (i) => int.parse(paddedHex.substring(i * 2, i * 2 + 2), radix: 16),
  );
}

List<int> _encodeLength(int length) {
  return [
    (length >> 24) & 0xFF,
    (length >> 16) & 0xFF,
    (length >> 8) & 0xFF,
    length & 0xFF,
  ];
}
```

**Testing Required After Fix:**
1. Create a new business in supplier app
2. Issue a card (both simple and secure modes)
3. Scan card in customer app
4. Verify business details load correctly
5. Add stamps and verify signature validation works

---

### 2. Excessive Debug Logging in Production

**Locations:**
- [customer_app/lib/services/qr_token_generator.dart](customer_app/lib/services/qr_token_generator.dart#L14-L20)
- [supplier_app/lib/services/key_manager.dart](supplier_app/lib/services/key_manager.dart#L27-L189)
- [supplier_app/lib/services/supplier_database_helper.dart](supplier_app/lib/services/supplier_database_helper.dart#L115-L191)
- [supplier_app/lib/screens/supplier/supplier_onboarding.dart](supplier_app/lib/screens/supplier/supplier_onboarding.dart#L47-L96)

**Examples:**
```dart
print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
print('!!! GENERATING STAMP REQUEST QR - BUILD 4 !!!');
print('!!! This log MUST appear if new code is running !!!');
print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
print('Input card ID: ${card.id}');
print('Input card stamps collected: ${card.stampsCollected}');
```

**Impact:**
- Clutters console making real debugging difficult
- Exposes system internals (card IDs, database operations, key generation)
- Performance degradation on each operation
- Unprofessional appearance when debugging with client

**Fix Required:**

**Option 1 - Complete Removal (Recommended for v0.2.1):**
```dart
// Simply remove all print() statements used for debugging
```

**Option 2 - Conditional Debug Logging (Better long-term):**
```dart
// Add to shared/lib/utils/logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }
  
  static void info(String message) {
    print('[INFO] $message');
  }
  
  static void error(String message, [dynamic error, StackTrace? stack]) {
    print('[ERROR] $message');
    if (error != null) print('  Error: $error');
    if (stack != null && kDebugMode) print('  Stack: $stack');
  }
}

// Then replace all print() calls:
AppLogger.debug('Generating stamp request for card ${card.id}');
```

**Files Requiring Cleanup:** (Search for `print(` in these files)
- `customer_app/lib/services/qr_token_generator.dart` - 20+ statements
- `supplier_app/lib/services/key_manager.dart` - 8+ statements
- `supplier_app/lib/services/supplier_database_helper.dart` - 14+ statements
- `supplier_app/lib/screens/supplier/supplier_onboarding.dart` - 11+ statements
- Any other files with excessive logging

---

## 🟠 High Priority Issues (Fix for v0.2.1)

### 3. Duplicated Cryptographic Verification Code

**Affected Files:**
- [customer_app/lib/services/key_manager.dart](customer_app/lib/services/key_manager.dart#L37-L64)
- [supplier_app/lib/services/key_manager.dart](supplier_app/lib/services/key_manager.dart#L131-L158)

**Issue:**
Both apps contain identical 30-line signature verification methods. This violates DRY principle and creates maintenance risk.

**Impact:**
- Security bug fixes must be applied twice
- Risk of implementations diverging over time
- Code bloat and maintenance burden

**Fix:**
Create `shared/lib/utils/crypto_utils.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class CryptoUtils {
  /// Verify ECDSA signature using secp256r1 curve
  static bool verifySignature({
    required String publicKeyEncoded,
    required String data,
    required String signatureEncoded,
  }) {
    try {
      final publicKey = _decodePublicKey(publicKeyEncoded);
      if (publicKey == null) return false;

      final dataBytes = utf8.encode(data);
      final signatureBytes = base64Decode(signatureEncoded);
      
      if (signatureBytes.length != 64) return false;
      
      final rBytes = signatureBytes.sublist(0, 32);
      final sBytes = signatureBytes.sublist(32, 64);
      
      final r = BigInt.parse(rBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      final s = BigInt.parse(sBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      
      final signature = ECSignature(r, s);
      final signer = ECDSASigner(SHA256Digest());
      signer.init(false, PublicKeyParameter<ECPublicKey>(publicKey));
      
      return signer.verifySignature(Uint8List.fromList(dataBytes), signature);
    } catch (e) {
      return false;
    }
  }
  
  static ECPublicKey? _decodePublicKey(String encoded) {
    // ... existing decode logic
  }
  
  static int _decodeLength(List<int> bytes, int offset) {
    // ... existing decode logic
  }
}
```

Then replace both KeyManager implementations:
```dart
static Future<bool> verifySignature({
  required String publicKey,
  required String data,
  required String signature,
}) async {
  return CryptoUtils.verifySignature(
    publicKeyEncoded: publicKey,
    data: data,
    signatureEncoded: signature,
  );
}
```

---

### 4. Silent Failures in Security-Critical Operations

**Location:** [customer_app/lib/services/key_manager.dart](customer_app/lib/services/key_manager.dart#L59-L64)

**Issue:**
```dart
try {
  // ... verification logic
  return signer.verifySignature(...);
} catch (e) {
  return false;  // ❌ Silent failure - no indication WHY it failed
}
```

**Impact:**
- Impossible to debug signature verification failures
- Users see generic "Invalid signature" without root cause
- Security issues become invisible

**Fix:**
```dart
static Future<VerificationResult> verifySignature({
  required String publicKey,
  required String data,
  required String signature,
}) async {
  try {
    final pk = _decodePublicKey(publicKey);
    if (pk == null) {
      return VerificationResult.failure('Invalid public key format');
    }

    final signatureBytes = base64Decode(signature);
    if (signatureBytes.length != 64) {
      return VerificationResult.failure('Invalid signature length: ${signatureBytes.length}');
    }
    
    // ... verification logic
    
    final isValid = signer.verifySignature(Uint8List.fromList(dataBytes), sig);
    return isValid 
      ? VerificationResult.success()
      : VerificationResult.failure('Signature does not match');
      
  } catch (e, stack) {
    AppLogger.error('Signature verification failed', e, stack);
    return VerificationResult.failure('Verification error: ${e.toString()}');
  }
}

class VerificationResult {
  final bool isValid;
  final String? errorMessage;
  
  VerificationResult.success() : isValid = true, errorMessage = null;
  VerificationResult.failure(this.errorMessage) : isValid = false;
}
```

---

### 5. Incomplete TODO in Production Code

**Location:** [customer_app/lib/screens/customer/customer_add_card.dart](customer_app/lib/screens/customer/customer_add_card.dart#L238)

```dart
// TODO: Implement actual card creation from QR data
```

**Issue:**
- Unclear if feature is complete or placeholder
- TODO comments should not ship to production

**Fix:**
1. If implemented: Remove the TODO
2. If not implemented: Complete the feature or remove the code path

---

### 6. Missing Input Validation in Repository Layer

**Location:** [customer_app/lib/services/card_repository.dart](customer_app/lib/services/card_repository.dart#L48-L60)

**Issue:**
```dart
Future<void> insertCard(models.Card card) async {
  final db = await _dbHelper.database;
  await db.insert('cards', card.toJson());  // No validation
}
```

**Risk:**
- Invalid data could corrupt database
- No early detection of bad data
- Debugging becomes harder

**Fix:**
```dart
Future<void> insertCard(models.Card card) async {
  // Input validation
  if (card.id.isEmpty) {
    throw ArgumentError('Card ID cannot be empty');
  }
  if (card.businessName.isEmpty) {
    throw ArgumentError('Business name is required');
  }
  if (card.stampsRequired <= 0) {
    throw ArgumentError('stampsRequired must be positive');
  }
  if (card.stampsCollected < 0) {
    throw ArgumentError('stampsCollected cannot be negative');
  }
  if (card.stampsCollected > card.stampsRequired) {
    throw ArgumentError('stampsCollected exceeds stampsRequired');
  }
  
  final db = await _dbHelper.database;
  await db.insert('cards', card.toJson(), 
    conflictAlgorithm: ConflictAlgorithm.fail);
}
```

Apply similar validation to all repository methods (`insertStamp`, `updateCard`, etc.)

---

## 🟡 Medium Priority Issues

### 7. Race Condition in Card Issuance Logging

**Location:** [supplier_app/lib/screens/supplier/supplier_issue_card.dart](supplier_app/lib/screens/supplier/supplier_issue_card.dart#L42-L50)

**Issue:**
```dart
if (!_hasLoggedCardIssuance && token.cardId != null) {
  await _businessRepo.logIssuedCard(widget.business.id, token.cardId!);
  _hasLoggedCardIssuance = true;  // Only logs once per screen session
}
```

**Problem:**
- User changes initial stamp count from 0 to 1
- Regenerates QR code
- Second issuance not logged because flag is already set

**Fix:**
Track logged card IDs instead of boolean flag:
```dart
final Set<String> _loggedCardIds = {};

// In _generateQRCode:
if (token.cardId != null && !_loggedCardIds.contains(token.cardId!)) {
  await _businessRepo.logIssuedCard(widget.business.id, token.cardId!);
  _loggedCardIds.add(token.cardId!);
}
```

Or remove the flag entirely and use database-level deduplication.

---

### 8. Hard-coded Security Constants

**Locations:**
- [customer_app/lib/services/rate_limiter.dart](customer_app/lib/services/rate_limiter.dart#L44, #L86)
- [customer_app/lib/services/token_validator.dart](customer_app/lib/services/token_validator.dart#L54, #L103)

**Hard-coded Values:**
```dart
// rate_limiter.dart
const _stampCooldown = 1000;      // 1 second
const _issueCooldown = 30000;     // 30 seconds

// token_validator.dart
const _cardIssueTokenValidityMinutes = 5;
const _stampTokenValidityMinutes = 2;
```

**Issue:**
- Can't tune security parameters without code changes
- No single source of truth
- Difficult to find all security timeouts

**Fix:**
Add to `shared/lib/constants/constants.dart`:
```dart
// Security Settings
static const int stampRateLimitMs = 1000;
static const int cardIssueRateLimitMs = 30000;
static const int cardIssueTokenValidityMinutes = 5;
static const int stampTokenValidityMinutes = 2;
static const int cloneQRExpiryHours = 24;
```

Then reference:
```dart
if (timeSinceLastStamp < AppConstants.stampRateLimitMs) {
  return 'Please wait before requesting another stamp';
}
```

---

### 9. Potential Memory Leak in Camera Controller

**Location:** [customer_app/lib/screens/customer/qr_scanner_screen.dart](customer_app/lib/screens/customer/qr_scanner_screen.dart#L28-L35)

**Issue:**
```dart
@override
void dispose() {
  _controller.dispose();  // May have pending async operations
  super.dispose();
}
```

**Risk:**
- If barcode detection callback pending during dispose, could leak
- Camera not explicitly stopped before disposal

**Fix:**
```dart
@override
void dispose() {
  _controller.stop();      // Stop scanning first
  _controller.dispose();   // Then dispose controller
  super.dispose();
}
```

---

### 10. Database Version Management Inconsistency

**Issue:**
- **Customer App:** Uses `AppConstants.databaseVersion` (line 73)
- **Supplier App:** Hard-codes `version: 4` (line 49)

**Fix:**
Standardize both apps to use constants:
```dart
// shared/lib/constants/constants.dart
static const int customerDatabaseVersion = 5;
static const int supplierDatabaseVersion = 4;

// Then in database helpers:
version: AppConstants.customerDatabaseVersion,  // or supplierDatabaseVersion
```

---

## 🔵 Low Priority / Code Quality Improvements

### 11. No Structured Logging Framework

**Issue:**
All logging uses `print()` instead of proper logging framework

**Recommendation:**
Add `logger` package to dependencies:
```yaml
dependencies:
  logger: ^2.5.0
```

Create `shared/lib/utils/app_logger.dart`:
```dart
import 'package:logger/logger.dart';

final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
  ),
  level: kDebugMode ? Level.debug : Level.warning,
);

// Usage:
appLogger.d('Debug message');     // Only in debug mode
appLogger.i('Info message');      // Always logged
appLogger.w('Warning');           // Always logged
appLogger.e('Error', error: e);   // With error object
```

**Benefits:**
- Filterable log levels
- Automatic timestamps
- Better formatting
- Can disable debug logs in release builds

---

### 12. Test Data in Production Screens

**Location:** [customer_app/lib/screens/customer/customer_home.dart](customer_app/lib/screens/customer/customer_home.dart#L76-L91)

**Issue:**
```dart
Future<void> _addTestCard() async {
  // Creates "Awesome Coffee Shop" test card
}
```

**Recommendation:**
- Move to separate `test_utils.dart` file
- Guard with `kDebugMode` check:
```dart
if (kDebugMode) {
  // Show "Add Test Card" button
}
```

Or remove entirely for production builds.

---

### 13. QR Code Size Defined in Multiple Places

**Locations:**
- `shared/lib/utils/qr_code_size.dart` - `minSize: 200, maxSize: 300`
- `shared/lib/constants/constants.dart` - `qrCodeSize: 300`

**Fix:**
Consolidate in constants.dart:
```dart
static const double qrCodeMinSize = 200.0;
static const double qrCodeMaxSize = 300.0;
static const double qrCodeDefaultSize = 300.0;
```

Remove from `qr_code_size.dart` or make it reference constants.

---

### 14. Inconsistent Error Handling Patterns

**Issue:**
Mix of error handling approaches:
- Return `false` on error (KeyManager)
- Return strings as error messages (screens)
- Throw exceptions (repositories)
- Silent catch blocks

**Recommendation:**
Standardize with Result<T> pattern:
```dart
class Result<T> {
  final T? data;
  final String? error;
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
  
  Result.success(this.data) : error = null;
  Result.failure(this.error) : data = null;
}

// Usage:
Future<Result<Card>> getCardById(String id) async {
  try {
    final card = await db.query(...);
    if (card.isEmpty) {
      return Result.failure('Card not found');
    }
    return Result.success(Card.fromJson(card.first));
  } catch (e) {
    return Result.failure('Database error: $e');
  }
}

// Consumer:
final result = await repo.getCardById(cardId);
if (result.isSuccess) {
  setState(() => _card = result.data!);
} else {
  showError(result.error!);
}
```

---

### 15. Debug Information Exposed in Validation Errors

**Location:** [customer_app/lib/services/token_validator.dart](customer_app/lib/services/token_validator.dart#L121-L122)

**Issue:**
Prints hash mismatch details when validation fails:
```dart
print('Hash mismatch: expected $expectedHash, got $actualHash');
```

**Fix:**
Remove or route to debug-only logger:
```dart
if (kDebugMode) {
  print('Hash mismatch: expected $expectedHash, got $actualHash');
}
return 'Invalid stamp signature';  // User-facing message
```

---

## ✅ Positive Findings (Well Implemented)

The review identified many **strong architectural decisions**:

1. ✅ **Database Security:** Parameterized queries prevent SQL injection
2. ✅ **Schema Design:** Foreign keys and cascading deletes properly configured
3. ✅ **Database Migrations:** Well-structured version upgrades (v2→v3→v4→v5)
4. ✅ **Async Operations:** Correct use of async/await throughout
5. ✅ **Fraud Prevention:** Double redemption prevention via status flags
6. ✅ **Model Structure:** Clean separation of models, views, and services
7. ✅ **Operation Modes:** Simple/Secure mode properly separated
8. ✅ **Cryptography Choice:** ECDSA P-256 with SHA256 is industry standard
9. ✅ **Stamp Validation:** Hash chain verification prevents tampering
10. ✅ **Key Storage:** Private keys stored in secure device storage (not hardcoded)
11. ✅ **Material 3 UI:** Responsive design with proper loading states
12. ✅ **Camera Handling:** Thoughtful orientation management for QR scanning
13. ✅ **Token Expiry:** Time-based QR code expiration prevents replay attacks
14. ✅ **Code Organization:** Clear folder structure (models, services, screens, widgets)

---

## 📋 Recommended Action Plan

### Phase 1: Immediate Fixes (Before Wider TestFlight Distribution)

**Priority: CRITICAL**

- [ ] **Fix broken public key encoding** in `stamp_signer.dart`
  - Implement proper `_encodePublicKey()` method
  - Test card issuance in both simple and secure modes
  - Verify signature validation works end-to-end
  
- [ ] **Remove ALL debug print statements**
  - Search for `print(` in all files
  - Remove or replace with conditional logging
  - Test that apps still work without logs
  
- [ ] **Test secure mode thoroughly**
  - Issue cards in secure mode
  - Verify crypto signatures work
  - This may not have been fully tested yet!

**Estimated Effort:** 4-6 hours

---

### Phase 2: v0.2.1 Update (Next Week)

**Priority: HIGH**

- [ ] De-duplicate cryptographic verification code
  - Create `shared/lib/utils/crypto_utils.dart`
  - Refactor both KeyManager classes
  - Add unit tests for crypto operations
  
- [ ] Improve error handling in security operations
  - Return structured errors instead of `false`
  - Add logging for signature failures
  - Update UI to show meaningful error messages
  
- [ ] Consolidate all magic numbers to constants
  - Move rate limits to `constants.dart`
  - Move token expiry times to constants
  - Document security rationale for each value
  
- [ ] Add input validation to repositories
  - Validate card data before insertion
  - Validate stamp data before insertion
  - Validate business configuration
  
- [ ] Fix card issuance logging race condition
  - Track logged card IDs instead of boolean flag
  - OR implement database-level deduplication

**Estimated Effort:** 8-12 hours

---

### Phase 3: v0.3.0 Enhancements (Future)

**Priority: MEDIUM**

- [ ] Implement structured logging framework
  - Add `logger` package
  - Create `AppLogger` utility
  - Replace all remaining print() calls
  - Configure different log levels for debug/release
  
- [ ] Standardize error handling across app
  - Implement Result<T> pattern
  - Update all repositories to use Result
  - Update UI to handle Result responses
  
- [ ] Remove test data from production builds
  - Feature-flag test card creation
  - OR move to separate dev utilities
  
- [ ] Add unit tests
  - Test cryptographic operations
  - Test token generation/validation
  - Test database operations
  - Test business logic
  
- [ ] Performance profiling
  - Profile memory usage during camera scanning
  - Profile database query performance
  - Profile QR code generation/parsing

**Estimated Effort:** 20-30 hours

---

## 🧪 Testing Recommendations

### Critical Test Scenarios (Test NOW)

1. **Secure Mode Card Issuance:**
   - Create business in secure mode
   - Issue card to customer
   - Verify card appears correctly in customer app
   - **Check if business public key is readable**
   - Add stamp in secure mode
   - Verify signature validation succeeds
   
2. **Signature Verification:**
   - Issue card in secure mode
   - Try to manually modify stamp count (if possible)
   - Verify tampering is detected
   
3. **Multi-Device Clone:**
   - Export backup from supplier app
   - Import on second device
   - Verify business data and keys transferred correctly
   - Test stamp issuance from cloned device

### Future Test Coverage Needed

1. **Unit Tests:**
   - Cryptographic operations
   - Token generation/parsing
   - Signature verification
   - Database CRUD operations
   
2. **Integration Tests:**
   - Full stamp collection flow
   - Card redemption flow
   - Backup/restore flow
   - Multi-device synchronization
   
3. **Security Tests:**
   - Token expiry enforcement
   - Rate limiting effectiveness
   - QR code tampering detection
   - Private key protection

---

## 📊 Code Metrics

### Lines of Code
- **Total:** ~15,000 lines (estimated)
- **Customer App:** ~6,000 lines
- **Supplier App:** ~7,000 lines
- **Shared:** ~2,000 lines

### Code Duplication
- **High:** Cryptographic verification (~60 lines duplicated)
- **Medium:** Database helper patterns (similar structure, different schemas)
- **Low:** UI widgets (appropriately separated by app)

### Test Coverage
- **Current:** 0% (no unit tests found)
- **Target:** 60-70% for business logic
- **Priority:** Cryptographic operations should be 100% covered

---

## 📚 Technical Debt Summary

| Category | Debt Items | Estimated Effort |
|----------|-----------|------------------|
| Critical Bugs | 2 issues | 4-6 hours |
| Security Improvements | 4 issues | 6-8 hours |
| Code Quality | 6 issues | 10-15 hours |
| Testing Infrastructure | No tests | 40-60 hours |
| Documentation | Security docs missing | 8-12 hours |
| **TOTAL** | **18+ items** | **68-101 hours** |

---

## 🎯 Conclusion

The LoyaltyCards v0.2.0 codebase demonstrates **solid engineering fundamentals** with thoughtful security design and clean architecture. The apps are **suitable for pilot testing** after addressing the two critical issues.

### Immediate Action Required:

1. ✅ Fix public key encoding bug (CRITICAL)
2. ✅ Remove excessive debug logging (CRITICAL)
3. ✅ Test secure mode end-to-end (CRITICAL)

### Recommended Priority:

1. **Phase 1** (Critical fixes) - Complete before expanding TestFlight users
2. **Phase 2** (High-priority improvements) - Complete before production launch
3. **Phase 3** (Quality enhancements) - Ongoing improvement as app grows

The architectural foundation is strong. With these identified issues addressed, the application will be well-positioned for production deployment and future enhancements.

---

**Next Steps:**
1. Review this document with the development team
2. Create GitHub issues for each identified problem
3. Prioritize fixes based on TestFlight feedback
4. Implement Phase 1 fixes immediately
5. Plan Phase 2 for next release cycle

---

*Code review completed: April 14, 2026*  
*Reviewer: GitHub Copilot (Claude Sonnet 4.5)*  
*Review scope: Full application suite - customer_app, supplier_app, shared libraries*
