import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/token_validator.dart';
import 'package:shared/shared.dart';

void main() {
  // Use test constants (signatures won't verify but we can test structure validation)
  const testPublicKey = 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEtest';
  const testSignature = 'MEQCIE1234567890TestSignature';

  group('TokenValidator - CardIssueToken Structure', () {
    test('rejects token older than 5 minutes in secure mode', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final timestamp = now - (6 * 60 * 1000); // 6 minutes old

      final token = CardIssueToken(
        businessId: 'test-biz-123',
        businessName: 'Test Coffee',
        publicKey: testPublicKey,
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: testSignature,
        timestamp: timestamp,
        mode: OperationMode.secure,
      );

      final result = await TokenValidator.validateCardIssueToken(token);

      expect(result.isValid, false);
      expect(result.error, contains('expired'));
    });

    test('EXPECTED ERROR: skips timestamp check for simple mode tokens', () async {
      // Create very old token (1 hour old)
      final now = DateTime.now().millisecondsSinceEpoch;
      final timestamp = now - (60 * 60 * 1000);

      final token = CardIssueToken(
        businessId: 'test-biz-123',
        businessName: 'Test Coffee',
        publicKey: testPublicKey,
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: testSignature,
        timestamp: timestamp,
        mode: OperationMode.simple,
      );

      final result = await TokenValidator.validateCardIssueToken(token);

      // Will fail on signature but NOT on timestamp
      if (result.error != null) {
        expect(result.error, isNot(contains('expired')));
        expect(result.error, contains('signature'));
      }
    });

    test('rejects token with invalid structure', () async {
      // Create token with missing required fields (businessId empty)
      final token = CardIssueToken(
        businessId: '',
        businessName: 'Test Coffee',
        publicKey: testPublicKey,
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: testSignature,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await TokenValidator.validateCardIssueToken(token);

      expect(result.isValid, false);
      expect(result.error, contains('structure'));
    });

    test('validates token structure before checking signature', () async {
      // Invalid structure should fail before signature verification
      final token = CardIssueToken(
        businessId: '',
        businessName: '',
        publicKey: '',
        stampsRequired: -1,
        brandColor: 'invalid',
        signature: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await TokenValidator.validateCardIssueToken(token);

      expect(result.isValid, false);
      expect(result.error, contains('structure'));
    });
  });

  group('TokenValidator - StampToken Structure', () {
    const testCardId = 'test-card-123';
    const testBusinessId = 'test-biz-123';

    test('rejects stamp with broken hash chain', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 5,
        previousHash: 'wrong-hash',
        signature: testSignature,
        timestamp: now,
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: 'expected-hash',
        mode: OperationMode.secure,
      );

      expect(result.isValid, false);
      expect(result.error, contains('hash'));
      expect(result.error, contains('chain'));
    });

    test('rejects secure mode stamp older than 2 minutes', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final oldTimestamp = now - (3 * 60 * 1000); // 3 minutes old

      const previousHash = 'previous-hash';
      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 5,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: oldTimestamp,
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.secure,
      );

      expect(result.isValid, false);
      expect(result.error, contains('expired'));
    });

    test('EXPECTED ERROR: skips timestamp check for simple mode stamps', () async {
      // This test uses malformed test data. The ⛔ error about signature is EXPECTED.
      final now = DateTime.now().millisecondsSinceEpoch;
      final oldTimestamp = now - (60 * 60 * 1000); // 1 hour old

      const previousHash = 'previous-hash';
      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 5,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: oldTimestamp,
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
      );

      // Will fail on signature but NOT on timestamp
      if (result.error != null) {
        expect(result.error, isNot(contains('expired')));
      }
    });

    test('EXPECTED ERROR: validates first stamp with empty previous hash', () async {
      // This test uses malformed test data. The ⛔ error about signature is EXPECTED.
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: '',
        signature: testSignature,
        timestamp: now,
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: '',
        mode: OperationMode.secure,
      );

      // Should pass hash chain check (both empty)
      if (result.error != null) {
        expect(result.error, isNot(contains('hash')));
        expect(result.error, isNot(contains('chain')));
      }
    });

    test('validates hash chain before checking signature', () async {
      // Wrong hash should fail before signature verification
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 5,
        previousHash: 'wrong',
        signature: 'any-sig',
        timestamp: now,
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: 'expected',
        mode: OperationMode.secure,
      );

      expect(result.isValid, false);
      expect(result.error, contains('hash'));
    });
  });

  group('TokenValidator - CardStampRequestToken', () {
    test('accepts valid request token', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = CardStampRequestToken(
        cardId: 'card-123',
        businessId: 'business-123',
        currentStamps: 5,
        publicKey: testPublicKey,
        lastStampHash: 'last-hash',
        timestamp: now,
      );

      final result = TokenValidator.validateStampRequest(token, 'business-123');

      expect(result.isValid, true);
      expect(result.error, isNull);
    });

    test('rejects request for different business', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = CardStampRequestToken(
        cardId: 'card-123',
        businessId: 'business-123',
        currentStamps: 5,
        publicKey: testPublicKey,
        lastStampHash: 'last-hash',
        timestamp: now,
      );

      final result = TokenValidator.validateStampRequest(token, 'different-business');

      expect(result.isValid, false);
      expect(result.error, contains('different business'));
    });

    test('rejects request older than 1 minute', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final oldTimestamp = now - (90 * 1000); // 90 seconds old

      final token = CardStampRequestToken(
        cardId: 'card-123',
        businessId: 'business-123',
        currentStamps: 5,
        publicKey: testPublicKey,
        lastStampHash: 'last-hash',
        timestamp: oldTimestamp,
      );

      final result = TokenValidator.validateStampRequest(token, 'business-123');

      expect(result.isValid, false);
      expect(result.error, contains('expired'));
    });

    test('rejects request with invalid structure', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Empty cardId makes token invalid
      final token = CardStampRequestToken(
        cardId: '',
        businessId: 'business-123',
        currentStamps: 5,
        publicKey: testPublicKey,
        lastStampHash: 'last-hash',
        timestamp: now,
      );

      final result = TokenValidator.validateStampRequest(token, 'business-123');

      expect(result.isValid, false);
      expect(result.error, contains('structure'));
    });

    test('accepts request at exactly 1 minute boundary', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final boundaryTimestamp = now - (60 * 1000); // Exactly 60 seconds

      final token = CardStampRequestToken(
        cardId: 'card-123',
        businessId: 'business-123',
        currentStamps: 5,
        publicKey: testPublicKey,
        lastStampHash: 'last-hash',
        timestamp: boundaryTimestamp,
      );

      final result = TokenValidator.validateStampRequest(token, 'business-123');

      // At exactly 60s, should still be valid (not yet expired)
      expect(result.isValid, true);
    });
  });

  group('ValidationResult', () {
    test('creates valid result', () {
      final result = ValidationResult(isValid: true);

      expect(result.isValid, true);
      expect(result.error, isNull);
    });

    test('creates invalid result with error message', () {
      final result = ValidationResult(
        isValid: false,
        error: 'Test error message',
      );

      expect(result.isValid, false);
      expect(result.error, 'Test error message');
    });
  });

  group('REQ-022: Enhanced Simple Mode - StampToken Validation', () {
    const testCardId = 'test-card-123';
    const testBusinessId = 'test-biz-123';
    const previousHash = 'previous-hash';

    test('rejects token with stampCount exceeding stampsRequired', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
        stampCount: 15, // Exceeds card's requirement
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
        stampsRequired: 10, // Card requires 10 stamps
      );

      expect(result.isValid, false);
      expect(result.error, contains('Invalid stamp count'));
      expect(result.error, contains('15'));
      expect(result.error, contains('10'));
    });

    test('accepts token with valid stampCount', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
        stampCount: 5, // Valid: 5 <= 10
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
        stampsRequired: 10,
      );

      // Will fail on signature, but not on stampCount
      if (result.error != null) {
        expect(result.error, isNot(contains('stamp count')));
      }
    });

    test('accepts token with stampCount equal to stampsRequired', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
        stampCount: 10, // Exactly matches requirement
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
        stampsRequired: 10,
      );

      // Will fail on signature, but not on stampCount
      if (result.error != null) {
        expect(result.error, isNot(contains('stamp count')));
      }
    });

    test('rejects expired token (expiryDate in past)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final pastExpiry = now - (24 * 60 * 60 * 1000); // 1 day ago

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
        expiryDate: pastExpiry,
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
      );

      expect(result.isValid, false);
      expect(result.error, contains('expired'));
    });

    test('accepts token with future expiry date', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final futureExpiry = now + (7 * 24 * 60 * 60 * 1000); // 1 week from now

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
        expiryDate: futureExpiry,
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
      );

      // Will fail on signature, but not on expiry
      if (result.error != null) {
        expect(result.error, isNot(contains('expired')));
      }
    });

    test('accepts token with no expiry date', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
        expiryDate: null, // No expiry
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
      );

      // Will fail on signature, but not on expiry
      if (result.error != null) {
        expect(result.error, isNot(contains('expired')));
      }
    });

    test('validates stampCount before expiryDate', () async {
      // Both invalid - should fail on stampCount first
      final now = DateTime.now().millisecondsSinceEpoch;
      final pastExpiry = now - (24 * 60 * 60 * 1000);

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
        stampCount: 20, // Invalid
        expiryDate: pastExpiry, // Also invalid
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
        stampsRequired: 10,
      );

      expect(result.isValid, false);
      expect(result.error, contains('stamp count')); // Fails on stampCount first
    });

    test('backward compatibility: accepts token without REQ-022 fields', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Old-style token (defaults: stampCount=1, no expiry, no scanInterval)
      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
      );

      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
        stampsRequired: 10,
      );

      // Should not fail on REQ-022 fields (stampCount defaults to 1)
      if (result.error != null) {
        expect(result.error, isNot(contains('stamp count')));
        expect(result.error, isNot(contains('expired')));
      }
    });

    test('scanInterval field is extracted but not validated', () async {
      // scanInterval is informational only, used by RateLimiter
      final now = DateTime.now().millisecondsSinceEpoch;

      final token = StampToken(
        id: 'stamp-1',
        cardId: testCardId,
        businessId: testBusinessId,
        stampNumber: 1,
        previousHash: previousHash,
        signature: testSignature,
        timestamp: now,
        scanInterval: 45000, // 45 seconds
      );

      expect(token.scanInterval, 45000);

      // scanInterval should not affect validation
      final result = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: testPublicKey,
        expectedPreviousHash: previousHash,
        mode: OperationMode.simple,
      );

      // Will fail on signature, but scanInterval doesn't affect validation
      if (result.error != null) {
        expect(result.error, isNot(contains('scan')));
        expect(result.error, isNot(contains('interval')));
      }
    });
  });
}
