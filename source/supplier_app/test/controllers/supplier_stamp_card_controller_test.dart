import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:pointycastle/export.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/controllers/controller_results.dart';
import 'package:supplier_app/controllers/supplier_stamp_card_controller.dart';
import 'package:supplier_app/services/business_repository.dart';
import 'package:supplier_app/services/key_manager.dart';
import 'package:supplier_app/services/qr_token_generator.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// Orchestration coverage for SupplierStampCardController - parsing a
/// scanned stamp-request token, validating it against the loaded business,
/// and generating both Secure Mode and Express Mode stamp tokens.
///
/// Follows the same pattern as
/// customer_app/test/controllers/qr_scanner_controller_test.dart: real
/// crypto (via KeyManager's real key pair, backed by flutter_secure_storage's
/// official in-memory test fake), no widget tree.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late KeyManager keyManager;
  late BusinessRepository businessRepo;
  late SupplierStampCardController controller;

  const businessId = 'business-stamp-controller-test';

  setUp(() async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    await SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_stamp_card_controller.db');

    keyManager = KeyManager();
    businessRepo = BusinessRepository();
    controller = SupplierStampCardController(
      businessRepository: businessRepo,
      tokenGenerator: QRTokenGenerator(keyManager),
    );

    final keyPair = await keyManager.generateKeyPair();
    await keyManager.storePrivateKey(businessId, keyPair.privateKey as ECPrivateKey);
    await keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);
    final publicKeyEncoded = (await keyManager.getPublicKeyString(businessId))!;

    await businessRepo.insertBusiness(Business(
      id: businessId,
      name: 'Test Coffee Shop',
      publicKey: publicKeyEncoded,
      privateKey: 'unused-plaintext-field',
      stampsRequired: 10,
      brandColor: '#FF5733',
      mode: OperationMode.secure,
      createdAt: DateTime.now(),
    ));
  });

  group('loadBusiness', () {
    test('loads the seeded business', () async {
      final result = await controller.loadBusiness();

      expect(result.isSuccess, isTrue);
      expect(controller.business?.id, businessId);
      expect(controller.business?.name, 'Test Coffee Shop');
    });
  });

  group('parseStampRequest', () {
    CardStampRequestToken buildToken({
      String? cardId,
      String? tokenBusinessId,
      int currentStamps = 3,
      String publicKey = 'some-public-key',
      String lastStampHash = '',
      int? timestamp,
    }) {
      return CardStampRequestToken(
        cardId: cardId ?? 'card-test-0001',
        businessId: tokenBusinessId ?? businessId,
        currentStamps: currentStamps,
        publicKey: publicKey,
        lastStampHash: lastStampHash,
        timestamp: timestamp ?? DateTime.now().millisecondsSinceEpoch,
      );
    }

    test('throws if called before loadBusiness()', () async {
      expect(
        () => controller.parseStampRequest('not-json'),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects data that is not a valid QR token at all', () async {
      await controller.loadBusiness();

      final result = await controller.parseStampRequest('not valid json at all');

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.invalidQr);
    });

    test('rejects a well-formed token of the wrong type', () async {
      await controller.loadBusiness();

      // A CardIssueToken is a real, readable QRToken - just the wrong kind
      // for this scan mode.
      final wrongTypeToken = CardIssueToken(
        businessId: businessId,
        businessName: 'Test Coffee Shop',
        publicKey: 'x',
        stampsRequired: 10,
        brandColor: '#FF5733',
        signature: 'unused-in-this-test',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.parseStampRequest(wrongTypeToken.toQRString());

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.invalidQr);
    });

    test('rejects a structurally invalid token and still fires onTokenRecognized', () async {
      await controller.loadBusiness();
      var recognized = false;

      final token = buildToken(cardId: ''); // isValid() requires non-empty cardId
      final result = await controller.parseStampRequest(
        token.toQRString(),
        onTokenRecognized: () => recognized = true,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.invalidToken);
      expect(recognized, isTrue,
          reason: 'the type check passed before structural validation failed, '
              'so the recognized callback should still fire');
    });

    test('rejects a token for a different business', () async {
      await controller.loadBusiness();

      final token = buildToken(tokenBusinessId: 'some-other-business');
      final result = await controller.parseStampRequest(token.toQRString());

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.businessMismatch);
    });

    test('rejects an expired token', () async {
      await controller.loadBusiness();

      final expiredTimestamp = DateTime.now()
          .subtract(Duration(milliseconds: AppConstants.stampRequestExpiryMs + 5000))
          .millisecondsSinceEpoch;
      final token = buildToken(timestamp: expiredTimestamp);
      final result = await controller.parseStampRequest(token.toQRString());

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.qrExpired);
    });

    test('succeeds for a fresh, valid, matching token and fires onTokenRecognized once', () async {
      await controller.loadBusiness();
      var recognizedCount = 0;

      // Realistic-length hash and cardId: real values here are always long
      // (a base64 signature; a UUID/businessId_timestamp-style card id), and
      // the pre-extraction debug-logging calls two unconditional
      // .substring(0, N) calls on them (lastStampHash.substring(0, 20) and
      // cardId.substring(0, 8)) with no length guard - a short dummy value
      // in either one throws RangeError instead of exercising the success
      // path. Both are pre-existing landmines in the original code
      // (confirmed present before this extraction, unrelated to it) that
      // never fire in production because real values are always long
      // enough - flagged for a follow-up defect entry, not fixed here since
      // this extraction preserves behavior exactly. buildToken()'s default
      // cardId ('card-test-0001') is already long enough to avoid the
      // second one.
      const realisticHash = 'MEUCIQDx7z8bK3nVqR9pW2xY4zA6cB1dE3fG5hJ7kL9mN0oP2qStestSignature==';
      final token = buildToken(currentStamps: 5, lastStampHash: realisticHash);
      final result = await controller.parseStampRequest(
        token.toQRString(),
        onTokenRecognized: () => recognizedCount++,
      );

      expect(result.isSuccess, isTrue);
      expect(result.token?.cardId, 'card-test-0001');
      expect(result.token?.currentStamps, 5);
      expect(result.previousHash, realisticHash);
      expect(recognizedCount, 1);
    });
  });

  group('generateStampToken', () {
    test('throws if called before loadBusiness()', () async {
      final token = CardStampRequestToken(
        cardId: 'card-test-0001',
        businessId: businessId,
        currentStamps: 0,
        publicKey: 'x',
        lastStampHash: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      expect(
        () => controller.generateStampToken(token, '', 1),
        throwsA(isA<StateError>()),
      );
    });

    test('produces a real, verifiable stamp token for a single stamp', () async {
      await controller.loadBusiness();
      final token = CardStampRequestToken(
        cardId: 'card-test-0001',
        businessId: businessId,
        currentStamps: 2,
        publicKey: 'customer-public-key',
        lastStampHash: 'prev-hash',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.generateStampToken(token, 'prev-hash', 1);

      expect(result.isSuccess, isTrue);
      expect(result.stampToken, isNotNull);
      expect(result.stampToken!.stampNumber, 3); // currentStamps + 1
      expect(result.stampToken!.additionalStamps, isEmpty); // stampCount 1 -> 0 additional

      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final verification = CryptoUtils.verifySignature(
        data: result.stampToken!.getSignatureData(),
        signatureBase64: result.stampToken!.signature,
        publicKeyEncoded: publicKeyEncoded!,
      );
      expect(verification.isValid, isTrue);
    });

    test('a multi-stamp request produces the right number of additional stamps', () async {
      await controller.loadBusiness();
      final token = CardStampRequestToken(
        cardId: 'card-test-0001',
        businessId: businessId,
        currentStamps: 0,
        publicKey: 'customer-public-key',
        lastStampHash: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.generateStampToken(token, '', 3);

      expect(result.isSuccess, isTrue);
      expect(result.stampToken!.additionalStamps.length, 2); // 3 stamps - 1 main = 2 additional
    });
  });

  group('generateExpressModeToken', () {
    test('throws if called before loadBusiness()', () async {
      expect(
        () => controller.generateExpressModeToken(stampCount: 1),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a stamp count below 1', () async {
      await controller.loadBusiness();

      final result = await controller.generateExpressModeToken(stampCount: 0);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.generationFailed);
    });

    test('rejects a stamp count above the business\'s stampsRequired', () async {
      await controller.loadBusiness(); // seeded business has stampsRequired: 10

      final result = await controller.generateExpressModeToken(stampCount: 11);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.generationFailed);
    });

    test('produces a real, verifiable, reusable Express Mode token', () async {
      await controller.loadBusiness();

      final result = await controller.generateExpressModeToken(stampCount: 4);

      expect(result.isSuccess, isTrue);
      expect(result.stampToken!.cardId, 'express-mode-stamp');
      expect(result.stampToken!.stampNumber, 1);

      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final verification = CryptoUtils.verifySignature(
        data: result.stampToken!.getSignatureData(),
        signatureBase64: result.stampToken!.signature,
        publicKeyEncoded: publicKeyEncoded!,
      );
      expect(verification.isValid, isTrue);
    });

    test('respects an explicit expiry date', () async {
      await controller.loadBusiness();
      final expiry = DateTime.now().add(const Duration(days: 7));

      final result = await controller.generateExpressModeToken(stampCount: 1, expiryDate: expiry);

      expect(result.isSuccess, isTrue);
      expect(result.stampToken!.expiryDate, expiry.millisecondsSinceEpoch);
    });
  });
}
