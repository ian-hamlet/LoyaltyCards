# Testing Strategy - Retrospective Test Implementation

**Status:** Production Testing for v0.3.0+1  
**Created:** April 18, 2026  
**Updated:** April 22, 2026  
**Purpose:** Comprehensive testing strategy for two dependent P2P applications  
**Context:** 264 automated tests (100% passing), deployed to TestFlight

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State](#current-state)
3. [Testing Architecture](#testing-architecture)
4. [Unit Testing Strategy](#unit-testing-strategy)
5. [Integration Testing Strategy](#integration-testing-strategy)
6. [Test Coverage Goals](#test-coverage-goals)
7. [Testing Infrastructure](#testing-infrastructure)
8. [Test Execution Plan](#test-execution-plan)
9. [Maintenance Strategy](#maintenance-strategy)

---

## Executive Summary

### Purpose

Implement retrospective unit and integration tests for LoyaltyCards v0.2.0, which consists of two P2P Flutter applications (Customer and Supplier) with a shared package. The apps are already deployed with comprehensive physical device testing; this strategy adds automated test coverage to prevent regression and enable confident refactoring.

### Key Constraints

1. **Two Dependent Applications:**
   - Customer app depends on Supplier app for QR token generation
   - Supplier app depends on Customer app for card validation
   - Shared package used by both apps
   - P2P architecture (no backend to test)

2. **QR Scanning Limitation:**
   - Physical QR scanning already comprehensively tested on devices
   - Unit tests will mock QR data input/output
   - Integration tests will simulate QR token exchange programmatically

3. **Cryptographic Operations:**
   - ECDSA signature generation/verification critical to security
   - Requires deterministic test keys and test vectors
   - Must test both success and failure paths

4. **Database Operations:**
   - SQLite databases in both apps
   - Tests require in-memory databases or mocking
   - Migration testing needed

### Coverage Goals

| Component | Target Coverage | Priority |
|-----------|----------------|----------|
| Shared Package | 80%+ | CRITICAL |
| Crypto Operations | 95%+ | CRITICAL |
| Database Repositories | 70%+ | HIGH |
| Business Logic Services | 70%+ | HIGH |
| QR Token Parsing | 90%+ | HIGH |
| UI Layer | 30%+ | MEDIUM |
| Integration Tests | Key flows | HIGH |

### Success Criteria

- ✅ All tests pass in CI/CD
- ✅ No test interferes with production code
- ✅ Tests catch known regression scenarios
- ✅ P2P integration flows validated
- ✅ Crypto operations validated with test vectors
- ✅ Database migrations tested

---

## Current State

### Existing Tests

**Shared Package:**
- ✅ `test/qr_tokens_test.dart` - QR token serialization/deserialization

**Customer App:**
- ❌ No tests (empty `test/` directory)

**Supplier App:**
- ❌ No tests (empty `test/` directory)

### Code Coverage

**Current:** ~1% (only QR token models)

**Issue:** Code was developed iteratively without TDD, retrospective testing required.

### Physical Device Testing Status

**Comprehensive manual testing completed:**
- ✅ Card issuance flow (Supplier → Customer)
- ✅ Stamp addition flow (Customer → Supplier → Customer)
- ✅ Stamp chain validation
- ✅ Card redemption
- ✅ Backup/restore operations
- ✅ Multi-device scenarios
- ✅ QR code scanning (camera-based)
- ✅ Biometric authentication
- ✅ Error handling and edge cases

**These physical tests remain valid and should continue.** Unit/integration tests complement (not replace) device testing.

---

## Testing Architecture

### Three-Tier Testing Approach

```
┌─────────────────────────────────────────────────────┐
│         Integration Tests                           │
│  (Cross-app P2P flows using programmatic QR tokens) │
└─────────────────────────────────────────────────────┘
                        ▲
                        │
         ┌──────────────┴──────────────┐
         │                              │
┌────────┴────────┐            ┌───────┴────────┐
│  Customer App   │            │  Supplier App  │
│   Unit Tests    │            │   Unit Tests   │
│  - Repositories │            │  - Repositories│
│  - Services     │            │  - Signing     │
│  - Validators   │            │  - Key Manager │
└────────┬────────┘            └───────┬────────┘
         │                              │
         └──────────────┬───────────────┘
                        ▼
         ┌──────────────────────────────┐
         │    Shared Package Tests      │
         │  - Models                    │
         │  - CryptoUtils               │
         │  - QR Tokens                 │
         │  - Constants                 │
         └──────────────────────────────┘
```

### Test Isolation Strategy

1. **Shared Package Tests:**
   - Pure Dart tests (no Flutter dependencies where possible)
   - Deterministic test data (fixed keys, timestamps, UUIDs)
   - No side effects (no file I/O, no network)

2. **App Unit Tests:**
   - Mock database operations
   - Mock secure storage (for key retrieval)
   - Mock file system (for backups)
   - Test business logic in isolation

3. **Integration Tests:**
   - Simulate P2P flows programmatically
   - Use test databases (in-memory SQLite)
   - Verify end-to-end token exchange
   - No physical QR scanning (use programmatic token passing)

---

## Unit Testing Strategy

### Shared Package Tests

**Priority: CRITICAL** (used by both apps)

#### 1. Models (`shared/lib/models/`)

**Files to Test:**
- `card.dart` - Card model and JSON serialization
- `business.dart` - Business model
- `stamp.dart` - Stamp model
- `transaction.dart` - Transaction model
- `qr_tokens.dart` - ✅ Partially covered (expand coverage)
- `supplier_config_backup.dart` - Backup model

**Test Requirements:**
```dart
// For each model:
- toJson() / fromJson() roundtrip
- copyWith() creates proper copy
- Equality and hashCode
- Edge cases (null fields, empty strings, boundary values)
- Invalid data handling
```

**Example Test Pattern:**
```dart
group('Card Model', () {
  test('toJson and fromJson roundtrip', () {
    final card = Card(
      id: 'test-id',
      businessId: 'biz-123',
      businessName: 'Test Coffee',
      // ... all fields
    );
    
    final json = card.toJson();
    final decoded = Card.fromJson(json);
    
    expect(decoded.id, card.id);
    expect(decoded.businessName, card.businessName);
    // ... all fields
  });
  
  test('copyWith creates new instance', () {
    final card = Card(/* ... */);
    final updated = card.copyWith(businessName: 'New Name');
    
    expect(updated.id, card.id); // Unchanged
    expect(updated.businessName, 'New Name'); // Changed
  });
});
```

#### 2. CryptoUtils (`shared/lib/utils/crypto_utils.dart`)

**Priority: CRITICAL** (security-critical)

**Test Requirements:**
```dart
group('CryptoUtils', () {
  // Setup: Generate test key pair with known values
  late ECPublicKey testPublicKey;
  late ECPrivateKey testPrivateKey;
  late String testPublicKeyEncoded;
  
  setUp(() {
    // Generate deterministic test keys
  });
  
  test('verifySignature - valid signature returns true', () {
    // Test with known good signature
  });
  
  test('verifySignature - invalid signature returns false', () {
    // Test with tampered data
  });
  
  test('verifySignature - wrong public key returns false', () {
    // Sign with key A, verify with key B
  });
  
  test('verifySignature - malformed signature returns false', () {
    // Test with invalid base64, wrong format, etc.
  });
  
  test('public key encoding/decoding roundtrip', () {
    // Encode then decode, should match original
  });
  
  test('signature format validation', () {
    // Test signature byte format
  });
});
```

**Test Vectors:**
Use predefined test vectors with known inputs/outputs:
```dart
// Known test data
const testData = "Hello, World!";
const testSignature = "base64signature...";
const testPublicKey = "base64publickey...";

// Should verify correctly
expect(CryptoUtils.verifySignature(...), true);
```

#### 3. QR Tokens (`shared/lib/models/qr_tokens.dart`)

**Status:** ✅ Partially covered, expand tests

**Additional Tests Needed:**
```dart
group('QR Token Edge Cases', () {
  test('CardIssueToken - handles long business names', () {
    // Test 100+ character business name
  });
  
  test('CardIssueToken - handles special characters', () {
    // Test Unicode, emoji, etc.
  });
  
  test('StampToken - handles maximum stamp number', () {
    // Test with stamp number 100, 1000, etc.
  });
  
  test('QRToken.fromQRString - handles malformed JSON', () {
    expect(() => QRToken.fromQRString('invalid'), throwsException);
  });
  
  test('QRToken.fromQRString - handles unknown token type', () {
    final json = jsonEncode({'type': 'unknown'});
    expect(() => QRToken.fromQRString(json), throwsException);
  });
});
```

#### 4. AppLogger (`shared/lib/utils/app_logger.dart`)

**Test Requirements:**
```dart
group('AppLogger', () {
  test('logs do not throw exceptions', () {
    expect(() => AppLogger.debug('test', 'Test'), returnsNormally);
    expect(() => AppLogger.error('test'), returnsNormally);
    expect(() => AppLogger.crypto('test'), returnsNormally);
  });
  
  // Note: Don't test actual output (platform-dependent)
  // Just ensure methods are callable
});
```

### Customer App Tests

**Priority: HIGH**

#### 1. Database Helper (`lib/services/database_helper.dart`)

**Test Strategy:** Use in-memory SQLite database

```dart
group('DatabaseHelper', () {
  late Database testDb;
  
  setUp() async {
    // Create in-memory database
    testDb = await openDatabase(
      inMemoryDatabasePath,
      version: AppConstants.databaseVersion,
      onCreate: (db, version) async {
        // Copy onCreate logic from DatabaseHelper
      },
    );
  });
  
  tearDown() async {
    await testDb.close();
  });
  
  test('database schema created correctly', () async {
    // Verify tables exist
    final tables = await testDb.query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
    expect(tables.map((t) => t['name']), containsAll(['cards', 'stamps', 'transactions']));
  });
  
  test('foreign key constraints enforced', () async {
    // Try to insert stamp without card, should fail
  });
  
  test('database migration from v5 to v6', () async {
    // Create v5 schema, run migration, verify v6
  });
});
```

#### 2. Card Repository (`lib/services/card_repository.dart`)

**Test Strategy:** Mock database

```dart
group('CardRepository', () {
  late MockDatabase mockDb;
  late CardRepository repository;
  
  setUp() {
    mockDb = MockDatabase();
    repository = CardRepository(mockDb);
  });
  
  test('getAllCards returns list of cards', () async {
    // Mock database query result
    when(mockDb.query('cards')).thenAnswer((_) async => [
      {'id': '1', 'business_name': 'Test', /* ... */},
    ]);
    
    final cards = await repository.getAllCards();
    expect(cards.length, 1);
    expect(cards[0].businessName, 'Test');
  });
  
  test('getCard returns null for non-existent ID', () async {
    when(mockDb.query('cards', where: anyNamed('where'))).thenAnswer((_) async => []);
    
    final card = await repository.getCard('nonexistent');
    expect(card, isNull);
  });
  
  test('saveCard inserts into database', () async {
    final card = Card(/* ... */);
    
    when(mockDb.insert('cards', any)).thenAnswer((_) async => 1);
    
    await repository.saveCard(card);
    
    verify(mockDb.insert('cards', argThat(contains('id')))).called(1);
  });
  
  test('deleteCard removes from database', () async {
    when(mockDb.delete('cards', where: anyNamed('where'))).thenAnswer((_) async => 1);
    
    await repository.deleteCard('test-id');
    
    verify(mockDb.delete('cards', where: 'id = ?', whereArgs: ['test-id'])).called(1);
  });
});
```

#### 3. Token Validator (`lib/services/token_validator.dart`)

**Test Strategy:** Pure unit tests with test data

```dart
group('TokenValidator', () {
  test('validate CardIssueToken - valid token passes', () {
    final token = CardIssueToken(/* valid data */);
    final result = TokenValidator.validateCardIssueToken(token);
    expect(result.isValid, true);
  });
  
  test('validate CardIssueToken - expired token fails', () {
    final token = CardIssueToken(
      timestamp: DateTime.now().subtract(Duration(hours: 2)).millisecondsSinceEpoch,
      /* ... */
    );
    final result = TokenValidator.validateCardIssueToken(token);
    expect(result.isValid, false);
    expect(result.reason, contains('expired'));
  });
  
  test('validate StampToken - signature verification', () async {
    // Use test keys
    final token = StampToken(/* with signature */);
    final isValid = await TokenValidator.validateStampSignature(token, testPublicKey);
    expect(isValid, true);
  });
});
```

#### 4. Stamp Repository (`lib/services/stamp_repository.dart`)

Similar pattern to CardRepository (mock database).

#### 5. Rate Limiter (`lib/services/rate_limiter.dart`)

```dart
group('RateLimiter', () {
  test('allows action within rate limit', () {
    final limiter = RateLimiter(maxActions: 3, period: Duration(seconds: 10));
    
    expect(limiter.canPerformAction('test-key'), true);
    expect(limiter.canPerformAction('test-key'), true);
    expect(limiter.canPerformAction('test-key'), true);
  });
  
  test('blocks action exceeding rate limit', () {
    final limiter = RateLimiter(maxActions: 2, period: Duration(seconds: 10));
    
    limiter.canPerformAction('test-key');
    limiter.canPerformAction('test-key');
    
    expect(limiter.canPerformAction('test-key'), false);
  });
  
  test('resets after time period', () async {
    final limiter = RateLimiter(maxActions: 1, period: Duration(milliseconds: 100));
    
    limiter.canPerformAction('test-key');
    expect(limiter.canPerformAction('test-key'), false);
    
    await Future.delayed(Duration(milliseconds: 150));
    expect(limiter.canPerformAction('test-key'), true);
  });
});
```

### Supplier App Tests

**Priority: HIGH**

#### 1. Key Manager (`lib/services/key_manager.dart`)

**Test Strategy:** Mock FlutterSecureStorage

```dart
group('KeyManager', () {
  late MockFlutterSecureStorage mockStorage;
  late KeyManager keyManager;
  
  setUp() {
    mockStorage = MockFlutterSecureStorage();
    keyManager = KeyManager(storage: mockStorage); // Inject mock
  });
  
  test('generateKeyPair creates valid ECDSA key pair', () async {
    final keyPair = await keyManager.generateKeyPair();
    
    expect(keyPair.privateKey, isA<ECPrivateKey>());
    expect(keyPair.publicKey, isA<ECPublicKey>());
    expect(keyPair.publicKey.parameters?.curve, ECCurve_secp256r1().curve);
  });
  
  test('storePrivateKey saves to secure storage', () async {
    final keyPair = await keyManager.generateKeyPair();
    
    when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
      .thenAnswer((_) async => null);
    
    await keyManager.storePrivateKey('biz-123', keyPair.privateKey as ECPrivateKey);
    
    verify(mockStorage.write(
      key: 'business_private_key_biz-123',
      value: anyNamed('value'),
    )).called(1);
  });
  
  test('getPrivateKey retrieves from storage', () async {
    // Store a key
    final testKeyBase64 = 'base64encodedkey...';
    when(mockStorage.read(key: 'business_private_key_biz-123'))
      .thenAnswer((_) async => testKeyBase64);
    
    final privateKey = await keyManager.getPrivateKey('biz-123');
    expect(privateKey, isNotNull);
  });
  
  test('signData creates valid signature', () async {
    final keyPair = await keyManager.generateKeyPair();
    final signature = await keyManager.signData('test data', keyPair.privateKey as ECPrivateKey);
    
    expect(signature, isNotNull);
    expect(signature, isA<String>()); // Base64 encoded
    
    // Verify signature with public key
    final publicKeyEncoded = keyManager.encodePublicKey(keyPair.publicKey as ECPublicKey);
    final isValid = KeyManager.verifySignature('test data', signature!, publicKeyEncoded);
    expect(isValid, true);
  });
});
```

#### 2. Stamp Signer (`lib/services/stamp_signer.dart`)

```dart
group('StampSigner', () {
  late StampSigner signer;
  late MockKeyManager mockKeyManager;
  
  setUp() {
    mockKeyManager = MockKeyManager();
    signer = StampSigner(keyManager: mockKeyManager);
  });
  
  test('createStamp generates valid stamp', () async {
    final testPrivateKey = /* test key */;
    when(mockKeyManager.getPrivateKey('biz-123')).thenAnswer((_) async => testPrivateKey);
    when(mockKeyManager.signData(any, any)).thenAnswer((_) async => 'signature');
    
    final stamp = await signer.createStamp(
      businessId: 'biz-123',
      cardId: 'card-1',
      stampNumber: 1,
    );
    
    expect(stamp.id, isNotEmpty);
    expect(stamp.stampNumber, 1);
    expect(stamp.signature, 'signature');
  });
  
  test('createStamp throws when private key not found', () async {
    when(mockKeyManager.getPrivateKey('biz-123')).thenAnswer((_) async => null);
    
    expect(
      () => signer.createStamp(businessId: 'biz-123', cardId: 'card-1', stampNumber: 1),
      throwsException,
    );
  });
  
  test('verifyStampChain validates correct chain', () async {
    final stamps = [
      Stamp(id: '1', stampNumber: 1, previousHash: null, /* ... */),
      Stamp(id: '2', stampNumber: 2, previousHash: 'hash1', /* ... */),
      Stamp(id: '3', stampNumber: 3, previousHash: 'hash2', /* ... */),
    ];
    
    final isValid = await signer.verifyStampChain(stamps, testPublicKey);
    expect(isValid, true);
  });
  
  test('verifyStampChain fails on broken chain', () async {
    final stamps = [
      Stamp(id: '1', stampNumber: 1, previousHash: null, /* ... */),
      Stamp(id: '2', stampNumber: 2, previousHash: 'wrong-hash', /* ... */),
    ];
    
    final isValid = await signer.verifyStampChain(stamps, testPublicKey);
    expect(isValid, false);
  });
});
```

#### 3. Business Repository (`lib/services/business_repository.dart`)

Similar pattern to Customer app repositories (mock database).

#### 4. Backup Storage Service (`lib/services/backup_storage_service.dart`)

```dart
group('BackupStorageService', () {
  test('createBackup serializes config correctly', () async {
    final config = SupplierConfigBackup(/* ... */);
    final json = BackupStorageService.serializeBackup(config);
    
    expect(json, contains('businessId'));
    expect(json, contains('privateKey'));
  });
  
  test('restoreBackup deserializes config', () {
    final json = '{"businessId":"123", /* ... */}';
    final config = BackupStorageService.deserializeBackup(json);
    
    expect(config.businessId, '123');
  });
  
  test('restoreBackup throws on invalid JSON', () {
    expect(() => BackupStorageService.deserializeBackup('invalid'), throwsException);
  });
});
```

---

## Integration Testing Strategy

### P2P Flow Integration Tests

**Purpose:** Validate end-to-end flows between Customer and Supplier apps without physical QR scanning.

**Location:** `03-Source/integration_tests/`

**Approach:** Programmatically pass QR token data between app components.

### Key Integration Test Scenarios

#### Integration Test 1: Full Card Issuance Flow

```dart
testWidgets('Full card issuance flow - Supplier to Customer', (tester) async {
  // SETUP: Initialize both apps
  final supplierKeyManager = KeyManager();
  final supplierBusinessRepo = BusinessRepository(testSupplierDb);
  final customerCardRepo = CardRepository(testCustomerDb);
  
  // STEP 1: Supplier creates business
  final business = Business(
    id: 'biz-123',
    name: 'Test Coffee',
    stampsRequired: 10,
    brandColor: '#FF5733',
  );
  await supplierBusinessRepo.saveBusiness(business);
  
  // STEP 2: Supplier generates key pair
  final keyPair = await supplierKeyManager.generateKeyPair();
  await supplierKeyManager.storePrivateKey(business.id, keyPair.privateKey);
  await supplierKeyManager.storePublicKey(business.id, keyPair.publicKey);
  
  // STEP 3: Supplier creates card issue token
  final publicKeyEncoded = supplierKeyManager.encodePublicKey(keyPair.publicKey);
  final token = CardIssueToken(
    businessId: business.id,
    businessName: business.name,
    publicKey: publicKeyEncoded,
    stampsRequired: business.stampsRequired,
    brandColor: business.brandColor,
    signature: 'signature', // Signed by supplier
    timestamp: DateTime.now().millisecondsSinceEpoch,
  );
  
  // STEP 4: Customer receives token (simulating QR scan)
  final qrString = token.toQRString();
  final receivedToken = QRToken.fromQRString(qrString) as CardIssueToken;
  
  // STEP 5: Customer validates and creates card
  final card = Card(
    id: uuid.v4(),
    businessId: receivedToken.businessId,
    businessName: receivedToken.businessName,
    businessPublicKey: receivedToken.publicKey,
    stampsRequired: receivedToken.stampsRequired,
    stampsCollected: 0,
    brandColor: receivedToken.brandColor,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  await customerCardRepo.saveCard(card);
  
  // VERIFY: Card stored correctly in customer app
  final savedCard = await customerCardRepo.getCard(card.id);
  expect(savedCard, isNotNull);
  expect(savedCard!.businessName, 'Test Coffee');
  expect(savedCard.stampsCollected, 0);
});
```

#### Integration Test 2: Stamp Addition Flow

```dart
testWidgets('Full stamp addition flow - Customer to Supplier to Customer', (tester) async {
  // SETUP: Card already issued (from Integration Test 1)
  final card = /* existing card */;
  final business = /* existing business */;
  
  // STEP 1: Customer creates stamp request token
  final stampRequestToken = CardStampRequestToken(
    cardId: card.id,
    businessId: card.businessId,
    currentStampCount: card.stampsCollected,
    publicKey: card.businessPublicKey,
    timestamp: DateTime.now().millisecondsSinceEpoch,
  );
  
  // STEP 2: Supplier scans request (simulated)
  final requestQRString = stampRequestToken.toQRString();
  final receivedRequest = QRToken.fromQRString(requestQRString) as CardStampRequestToken;
  
  // STEP 3: Supplier validates and creates stamp
  final stampSigner = StampSigner(keyManager: supplierKeyManager);
  final stamp = await stampSigner.createStamp(
    businessId: business.id,
    cardId: receivedRequest.cardId,
    stampNumber: receivedRequest.currentStampCount + 1,
  );
  
  // STEP 4: Supplier creates stamp token
  final stampToken = StampToken(
    cardId: stamp.cardId,
    stampNumber: stamp.stampNumber,
    timestamp: stamp.timestamp.millisecondsSinceEpoch,
    signature: stamp.signature,
    previousHash: stamp.previousHash,
  );
  
  // STEP 5: Customer receives stamp (simulated)
  final stampQRString = stampToken.toQRString();
  final receivedStamp = QRToken.fromQRString(stampQRString) as StampToken;
  
  // STEP 6: Customer validates signature
  final isValid = KeyManager.verifySignature(
    '${receivedStamp.cardId}:${receivedStamp.stampNumber}:${receivedStamp.timestamp}:${receivedStamp.previousHash ?? ""}',
    receivedStamp.signature,
    card.businessPublicKey,
  );
  expect(isValid, true);
  
  // STEP 7: Customer saves stamp
  final stampRepository = StampRepository(testCustomerDb);
  await stampRepository.addStamp(card.id, receivedStamp);
  
  // VERIFY: Stamp saved and card updated
  final stamps = await stampRepository.getStampsForCard(card.id);
  expect(stamps.length, 1);
  expect(stamps[0].stampNumber, 1);
  
  final updatedCard = await customerCardRepo.getCard(card.id);
  expect(updatedCard!.stampsCollected, 1);
});
```

#### Integration Test 3: Complete Card Lifecycle

```dart
testWidgets('Complete card lifecycle - Issue, Stamp, Redeem', (tester) async {
  // Full lifecycle test combining:
  // 1. Card issuance
  // 2. Multiple stamp additions (up to stampsRequired)
  // 3. Card redemption
  // 4. Card reset/re-issue
  
  // ... (combines Tests 1 & 2, adds redemption)
});
```

#### Integration Test 4: Stamp Chain Validation

```dart
testWidgets('Stamp chain validation - detects tampering', (tester) async {
  // Create card with multiple stamps
  // Verify stamp chain is valid
  // Tamper with one stamp
  // Verify stamp chain now invalid
});
```

#### Integration Test 5: Backup and Restore

```dart
testWidgets('Supplier config backup and restore', (tester) async {
  // Create business with key pair
  // Generate backup JSON
  // Restore from backup to new instance
  // Verify keys match and can sign/verify
});
```

---

## Test Coverage Goals

### Coverage Targets

| Component | Lines | Branches | Priority |
|-----------|-------|----------|----------|
| **Shared Package** |
| Models | 85% | 80% | CRITICAL |
| CryptoUtils | 95% | 95% | CRITICAL |
| QR Tokens | 90% | 85% | HIGH |
| Utils | 70% | 70% | MEDIUM |
| **Customer App** |
| Database Helper | 75% | 70% | HIGH |
| Repositories | 80% | 75% | HIGH |
| Key Manager | 90% | 85% | HIGH |
| Token Validator | 85% | 80% | HIGH |
| Services | 70% | 65% | MEDIUM |
| UI Screens | 30% | 25% | LOW |
| **Supplier App** |
| Database Helper | 75% | 70% | HIGH |
| Repositories | 80% | 75% | HIGH |
| Key Manager | 95% | 90% | CRITICAL |
| Stamp Signer | 90% | 85% | CRITICAL |
| Services | 70% | 65% | MEDIUM |
| UI Screens | 30% | 25% | LOW |
| **Integration** |
| P2P Flows | 100% | 100% | HIGH |

### Coverage Measurement

```bash
# Run tests with coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

### Acceptance Criteria

**Minimum for merge to develop:**
- [ ] Shared package: 80%+ coverage
- [ ] Crypto operations: 95%+ coverage
- [ ] Customer app repositories: 70%+ coverage
- [ ] Supplier app key operations: 90%+ coverage
- [ ] All integration tests pass

---

## Testing Infrastructure

### Dependencies

**Add to each `pubspec.yaml`:**

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  test: ^1.24.0
  integration_test:
    sdk: flutter
```

**For shared package (no Flutter deps if possible):**
```yaml
dev_dependencies:
  test: ^1.24.0
  mockito: ^5.4.0
```

### Mock Generation

Create mock classes for dependencies:

**File:** `test/mocks.dart`
```dart
import 'package:mockito/annotations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lib/services/key_manager.dart';

@GenerateMocks([
  Database,
  FlutterSecureStorage,
  KeyManager,
])
void main() {}
```

**Generate mocks:**
```bash
flutter pub run build_runner build
```

### Test Fixtures

**Create test data fixtures:**

**File:** `test/fixtures/test_data.dart`
```dart
import 'package:shared/shared.dart';

class TestData {
  // Test keys (deterministic for reproducible tests)
  static const testPrivateKeyBase64 = 'base64key...';
  static const testPublicKeyBase64 = 'base64key...';
  
  // Test business
  static final testBusiness = Business(
    id: 'test-biz-123',
    name: 'Test Coffee Shop',
    stampsRequired: 10,
    brandColor: '#FF5733',
  );
  
  // Test card
  static final testCard = Card(
    id: 'test-card-456',
    businessId: testBusiness.id,
    businessName: testBusiness.name,
    businessPublicKey: testPublicKeyBase64,
    stampsRequired: 10,
    stampsCollected: 5,
    brandColor: testBusiness.brandColor,
    createdAt: DateTime(2026, 4, 1),
    updatedAt: DateTime(2026, 4, 18),
  );
  
  // Test stamps
  static final testStamps = [
    Stamp(
      id: 'stamp-1',
      cardId: testCard.id,
      stampNumber: 1,
      timestamp: DateTime(2026, 4, 1),
      signature: 'sig1',
    ),
    Stamp(
      id: 'stamp-2',
      cardId: testCard.id,
      stampNumber: 2,
      timestamp: DateTime(2026, 4, 2),
      signature: 'sig2',
      previousHash: 'hash1',
    ),
  ];
}
```

### Test Database Helper

**File:** `test/helpers/test_database.dart`
```dart
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TestDatabase {
  static Future<Database> createCustomerTestDb() async {
    // Initialize FFI for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    return await openDatabase(
      inMemoryDatabasePath,
      version: 6,
      onCreate: (db, version) async {
        // Copy schema from DatabaseHelper._onCreate
        await db.execute('''CREATE TABLE cards (...)''');
        await db.execute('''CREATE TABLE stamps (...)''');
        // ... etc
      },
    );
  }
  
  static Future<Database> createSupplierTestDb() async {
    // Similar for supplier app
  }
  
  static Future<void> populateWithTestData(Database db) async {
    // Insert test data
  }
}
```

### CI/CD Integration

**File:** `.github/workflows/test.yml` (update existing or create)
```yaml
name: Tests

on:
  push:
    branches: [develop, main, 'feature/**']
  pull_request:
    branches: [develop, main]

jobs:
  test:
    runs-on: macos-latest # Need macOS for iOS builds
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.3.0'
          channel: 'stable'
      
      - name: Install dependencies - Shared
        run: cd 03-Source/shared && flutter pub get
      
      - name: Install dependencies - Customer App
        run: cd 03-Source/customer_app && flutter pub get
      
      - name: Install dependencies - Supplier App
        run: cd 03-Source/supplier_app && flutter pub get
      
      - name: Run tests - Shared Package
        run: cd 03-Source/shared && flutter test --coverage
      
      - name: Run tests - Customer App
        run: cd 03-Source/customer_app && flutter test --coverage
      
      - name: Run tests - Supplier App
        run: cd 03-Source/supplier_app && flutter test --coverage
      
      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: |
            03-Source/shared/coverage/lcov.info,
            03-Source/customer_app/coverage/lcov.info,
            03-Source/supplier_app/coverage/lcov.info
      
      - name: Check coverage thresholds
        run: |
          # Fail if coverage below thresholds
          # (Add script to parse lcov.info)
```

---

## Test Execution Plan

### Phase 1: Foundation (Days 1-2)

**Goals:**
- [ ] Set up testing infrastructure
- [ ] Create test fixtures and helpers
- [ ] Generate mocks
- [ ] Validate CI/CD pipeline

**Deliverables:**
- Mock generation working
- Test fixtures created
- CI/CD running tests

### Phase 2: Shared Package (Days 3-4)

**Priority: CRITICAL** (both apps depend on this)

**Tests to Implement:**
1. [ ] Model tests (Card, Business, Stamp, Transaction, QR Tokens)
2. [ ] CryptoUtils comprehensive tests
3. [ ] AppLogger tests
4. [ ] Utility function tests

**Target:** 80%+ coverage

### Phase 3: Customer App (Days 5-7)

**Tests to Implement:**
1. [ ] DatabaseHelper tests
2. [ ] CardRepository tests
3. [ ] StampRepository tests
4. [ ] TransactionRepository tests
5. [ ] TokenValidator tests
6. [ ] KeyManager (verification) tests
7. [ ] RateLimiter tests

**Target:** 70%+ coverage on business logic

### Phase 4: Supplier App (Days 8-10)

**Tests to Implement:**
1. [ ] DatabaseHelper tests
2. [ ] BusinessRepository tests
3. [ ] KeyManager (signing + verification) tests
4. [ ] StampSigner tests
5. [ ] BackupStorageService tests
6. [ ] QR Token Generator tests

**Target:** 70%+ coverage on business logic, 95%+ on crypto

### Phase 5: Integration Tests (Days 11-12)

**Tests to Implement:**
1. [ ] Full card issuance flow
2. [ ] Stamp addition flow
3. [ ] Complete lifecycle test
4. [ ] Stamp chain validation
5. [ ] Backup/restore flow
6. [ ] Multi-device scenarios

**Target:** All critical P2P flows covered

### Phase 6: Refinement (Days 13-14)

**Activities:**
- [ ] Address coverage gaps
- [ ] Fix flaky tests
- [ ] Optimize slow tests
- [ ] Document testing patterns
- [ ] Update this strategy document

---

## Maintenance Strategy

### Ongoing Test Requirements

**For every new feature:**
1. Write unit tests BEFORE implementation (TDD)
2. Achieve 70%+ coverage minimum
3. Add integration test if multi-component
4. Update test fixtures if needed

**For every bug fix:**
1. Write failing test that reproduces bug
2. Fix the bug
3. Verify test now passes
4. Add to regression test suite

**For every refactor:**
1. Run full test suite BEFORE refactoring
2. Ensure all tests still pass AFTER refactoring
3. Update tests if API changed
4. Improve test coverage if opportunity arises

### Test Health Monitoring

**Weekly:**
- [ ] Review test execution time (target: <5 minutes total)
- [ ] Check for flaky tests
- [ ] Review code coverage trends

**Monthly:**
- [ ] Audit test quality (are tests testing the right things?)
- [ ] Remove obsolete tests
- [ ] Update test fixtures with realistic data

**Quarterly:**
- [ ] Review testing strategy
- [ ] Update coverage targets
- [ ] Evaluate new testing tools/practices

### Test Quality Guidelines

**Good Tests Are:**
- ✅ **Fast:** Run in milliseconds, not seconds
- ✅ **Isolated:** No dependencies on other tests
- ✅ **Repeatable:** Same result every time
- ✅ **Self-validating:** Pass/fail, no manual inspection
- ✅ **Timely:** Written with/before code, not months later

**Avoid:**
- ❌ Tests that test Flutter framework (trust Flutter)
- ❌ Tests that test third-party libraries (trust dependencies)
- ❌ Tests that require manual setup/cleanup
- ❌ Tests with hard-coded sleep/delays
- ❌ Tests that test implementation details (test behavior, not internals)

### Common Pitfalls to Avoid

1. **Over-mocking:**
   - Don't mock everything
   - Use real objects when simple (e.g., models)
   - Mock only external dependencies (database, storage, network)

2. **Brittle Tests:**
   - Don't test private methods
   - Don't rely on exact string matches (use `contains`)
   - Don't hard-code timestamps (use relative times)

3. **Slow Tests:**
   - Use in-memory databases, not file-based
   - Don't use real async delays (mock time)
   - Parallelize independent tests

4. **Flaky Tests:**
   - Don't depend on execution order
   - Clean up after each test (tearDown)
   - Don't share mutable state between tests

---

## Success Metrics

### Quantitative Metrics

| Metric | Current | Target | Deadline |
|--------|---------|--------|----------|
| Overall Coverage | ~1% | 70%+ | Phase 6 |
| Shared Package Coverage | 10% | 80%+ | Phase 2 |
| Crypto Coverage | 0% | 95%+ | Phase 2 |
| Customer App Coverage | 0% | 70%+ | Phase 3 |
| Supplier App Coverage | 0% | 70%+ | Phase 4 |
| Integration Tests | 0 | 6+ | Phase 5 |
| Test Execution Time | N/A | <5 min | Phase 6 |
| CI/CD Pass Rate | N/A | 95%+ | Phase 6 |

### Qualitative Success Criteria

- [ ] Team confidence in making changes (no fear of breaking things)
- [ ] Caught at least one regression that would have escaped
- [ ] Tests aid debugging (failures point to exact issue)
- [ ] New developers can understand codebase via tests
- [ ] Refactoring is safe and straightforward

---

## Related Documents

- [Process Improvements](PROCESS_IMPROVEMENTS.md) - Why testing matters
- [Lessons Learned](LESSONS_LEARNED.md) - What happens without tests
- [Code Review v0.2.0](CODE_REVIEW_v0.2.0.md) - Issues tests would catch
- [Database Schema](DATABASE_SCHEMA.md) - Schema for test databases

**Maintained by:** Development Team  
**Last Updated:** April 18, 2026  
**Status:** In Progress (feature/retrospective-testing branch)
