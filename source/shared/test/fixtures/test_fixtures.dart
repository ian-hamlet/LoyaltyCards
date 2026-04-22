/// Test fixtures and helpers for shared package tests
/// 
/// Provides deterministic test data for reproducible testing
library;

import 'package:shared/shared.dart';

/// Test data fixtures
class TestFixtures {
  // Prevent instantiation
  TestFixtures._();

  // Test timestamps (fixed for deterministic tests)
  static final testTimestamp1 = DateTime(2026, 4, 1, 10, 0, 0);
  static final testTimestamp2 = DateTime(2026, 4, 2, 15, 30, 0);
  static final testTimestamp3 = DateTime(2026, 4, 18, 9, 15, 0);

  // Test Business
  static final testBusiness = Business(
    id: 'test-biz-123',
    name: 'Test Coffee Shop',
    publicKey: 'test-public-key-base64',
    privateKey: 'test-private-key-base64',
    stampsRequired: 10,
    brandColor: '#FF5733',
    logoIndex: 0,
    createdAt: testTimestamp1,
  );

  static final testBusiness2 = Business(
    id: 'test-biz-456',
    name: 'Test Pizza Place',
    publicKey: 'test-public-key-2-base64',
    privateKey: 'test-private-key-2-base64',
    stampsRequired: 8,
    brandColor: '#3366FF',
    logoIndex: 1,
    createdAt: testTimestamp2,
  );

  // Test Card
  static final testCard = Card(
    id: 'test-card-001',
    businessId: testBusiness.id,
    businessName: testBusiness.name,
    businessPublicKey: 'test-public-key-base64',
    stampsRequired: testBusiness.stampsRequired,
    stampsCollected: 5,
    brandColor: testBusiness.brandColor,
    logoIndex: testBusiness.logoIndex,
    mode: OperationMode.secure,
    createdAt: testTimestamp1,
    updatedAt: testTimestamp3,
    isRedeemed: false,
  );

  static final testCardSimpleMode = Card(
    id: 'test-card-002',
    businessId: testBusiness2.id,
    businessName: testBusiness2.name,
    businessPublicKey: '',
    stampsRequired: testBusiness2.stampsRequired,
    stampsCollected: 2,
    brandColor: testBusiness2.brandColor,
    logoIndex: testBusiness2.logoIndex,
    mode: OperationMode.simple,
    createdAt: testTimestamp2,
    updatedAt: testTimestamp3,
    isRedeemed: false,
  );

  static final testCardRedeemed = Card(
    id: 'test-card-003',
    businessId: testBusiness.id,
    businessName: testBusiness.name,
    businessPublicKey: 'test-public-key-base64',
    stampsRequired: 10,
    stampsCollected: 10,
    brandColor: testBusiness.brandColor,
    logoIndex: testBusiness.logoIndex,
    mode: OperationMode.secure,
    createdAt: testTimestamp1,
    updatedAt: testTimestamp3,
    isRedeemed: true,
    redeemedAt: testTimestamp3,
  );

  // Test Stamps
  static final testStamp1 = Stamp(
    id: 'test-stamp-001',
    cardId: testCard.id,
    stampNumber: 1,
    timestamp: testTimestamp1,
    signature: 'test-signature-1',
    previousHash: null,
  );

  static final testStamp2 = Stamp(
    id: 'test-stamp-002',
    cardId: testCard.id,
    stampNumber: 2,
    timestamp: testTimestamp2,
    signature: 'test-signature-2',
    previousHash: 'hash-of-stamp-1',
  );

  static final testStamp3 = Stamp(
    id: 'test-stamp-003',
    cardId: testCard.id,
    stampNumber: 3,
    timestamp: testTimestamp3,
    signature: 'test-signature-3',
    previousHash: 'hash-of-stamp-2',
  );

  static List<Stamp> get testStampChain => [testStamp1, testStamp2, testStamp3];

  // Test Transactions
  static final testTransactionCardIssued = Transaction(
    id: 'test-txn-001',
    cardId: testCard.id,
    type: TransactionType.pickup,
    timestamp: testTimestamp1,
    businessName: testBusiness.name,
    details: 'Card issued for ${testBusiness.name}',
  );

  static final testTransactionStampAdded = Transaction(
    id: 'test-txn-002',
    cardId: testCard.id,
    type: TransactionType.stamp,
    timestamp: testTimestamp2,
    businessName: testBusiness.name,
    details: 'Stamp #1 added',
  );

  static final testTransactionCardRedeemed = Transaction(
    id: 'test-txn-003',
    cardId: testCard.id,
    type: TransactionType.redemption,
    timestamp: testTimestamp3,
    businessName: testBusiness.name,
    details: 'Card redeemed with 10 stamps',
  );

  // Test QR Tokens
  static final testCardIssueToken = CardIssueToken(
    businessId: testBusiness.id,
    businessName: testBusiness.name,
    publicKey: 'test-public-key-base64',
    stampsRequired: testBusiness.stampsRequired,
    brandColor: testBusiness.brandColor,
    logoIndex: testBusiness.logoIndex,
    signature: 'test-signature',
    timestamp: testTimestamp1.millisecondsSinceEpoch,
  );

  static final testCardStampRequestToken = CardStampRequestToken(
    cardId: testCard.id,
    businessId: testCard.businessId,
    currentStamps: testCard.stampsCollected,
    publicKey: testCard.businessPublicKey,
    lastStampHash: 'hash-of-stamp-5',
    timestamp: testTimestamp2.millisecondsSinceEpoch,
  );

  static final testStampToken = StampToken(
    id: 'test-stamp-token-1',
    cardId: testCard.id,
    businessId: testCard.businessId,
    stampNumber: 6,
    previousHash: 'hash-of-stamp-5',
    signature: 'test-signature-stamp-6',
    timestamp: testTimestamp3.millisecondsSinceEpoch,
  );

  // Test Supplier Config Backup
  static final testSupplierConfigBackup = SupplierConfigBackup(
    type: 'recovery',
    version: 1,
    businessId: testBusiness.id,
    businessName: testBusiness.name,
    privateKey: 'test-private-key-base64',
    publicKey: 'test-public-key-base64',
    stampsRequired: testBusiness.stampsRequired,
    brandColor: testBusiness.brandColor,
    operationMode: OperationMode.secure,
    timestamp: testTimestamp3,
    signature: 'test-signature',
  );
}

/// Test crypto keys (for deterministic testing)
/// 
/// These are NOT secure keys - only for testing purposes
class TestCryptoKeys {
  TestCryptoKeys._();

  // Test public key (base64 encoded)
  // In real tests, this would be generated from a known private key
  static const String publicKeyBase64 = '''
MEkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDMgAEJvPZ0VPvOh7wLaVDZYvKe9eMgJGD
0uKhpU5FgkQHt2cE1NVcXjqO2vSHpMxWXEVJ
''';

  // Test private key (base64 encoded)
  // WARNING: Never use this pattern in production!
  static const String privateKeyBase64 = '''
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgTest1234567890Test
1234567890Test1234567890hkjOPQQDAgNIADBFAiEA1234567890Test
''';

  // Test signature (base64 encoded)
  static const String signatureBase64 = '''
MEUCIE1234567890TestSignature1234567890AiEA1234567890TestSignature1234567890
''';

  // Test data to sign
  static const String testData = 'test-card-001:1:1711968000000:';
}

/// Helper class for creating test variations
class TestDataBuilder {
  TestDataBuilder._();

  /// Create a card with custom fields
  static Card createCard({
    String? id,
    String? businessId,
    String? businessName,
    String? businessPublicKey,
    int? stampsRequired,
    int? stampsCollected,
    String? brandColor,
    int? logoIndex,
    OperationMode? mode,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRedeemed,
    DateTime? redeemedAt,
    String? deviceId,
  }) {
    return Card(
      id: id ?? 'test-card-${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId ?? TestFixtures.testBusiness.id,
      businessName: businessName ?? TestFixtures.testBusiness.name,
      businessPublicKey: businessPublicKey ?? 'test-public-key',
      stampsRequired: stampsRequired ?? 10,
      stampsCollected: stampsCollected ?? 0,
      brandColor: brandColor ?? '#FF5733',
      logoIndex: logoIndex ?? 0,
      mode: mode ?? OperationMode.secure,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      isRedeemed: isRedeemed ?? false,
      redeemedAt: redeemedAt,
      deviceId: deviceId,
    );
  }

  /// Create a business with custom fields
  static Business createBusiness({
    String? id,
    String? name,
    String? publicKey,
    String? privateKey,
    int? stampsRequired,
    String? brandColor,
    int? logoIndex,
    OperationMode? mode,
    DateTime? createdAt,
  }) {
    return Business(
      id: id ?? 'test-biz-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Business',
      publicKey: publicKey ?? 'test-public-key',
      privateKey: privateKey ?? 'test-private-key',
      stampsRequired: stampsRequired ?? 10,
      brandColor: brandColor ?? '#FF5733',
      logoIndex: logoIndex ?? 0,
      mode: mode ?? OperationMode.secure,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create a stamp with custom fields
  static Stamp createStamp({
    String? id,
    String? cardId,
    int? stampNumber,
    DateTime? timestamp,
    String? signature,
    String? previousHash,
    String? deviceId,
  }) {
    return Stamp(
      id: id ?? 'test-stamp-${DateTime.now().millisecondsSinceEpoch}',
      cardId: cardId ?? TestFixtures.testCard.id,
      stampNumber: stampNumber ?? 1,
      timestamp: timestamp ?? DateTime.now(),
      signature: signature ?? 'test-signature',
      previousHash: previousHash,
      deviceId: deviceId,
    );
  }

  /// Create a transaction with custom fields
  static Transaction createTransaction({
    String? id,
    String? cardId,
    TransactionType? type,
    DateTime? timestamp,
    String? businessName,
    String? details,
  }) {
    return Transaction(
      id: id ?? 'test-txn-${DateTime.now().millisecondsSinceEpoch}',
      cardId: cardId ?? TestFixtures.testCard.id,
      type: type ?? TransactionType.stamp,
      timestamp: timestamp ?? DateTime.now(),
      businessName: businessName ?? TestFixtures.testBusiness.name,
      details: details,
    );
  }
}
