import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:pointycastle/export.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/controllers/controller_results.dart';
import 'package:supplier_app/controllers/supplier_redeem_card_controller.dart';
import 'package:supplier_app/services/business_repository.dart';
import 'package:supplier_app/services/key_manager.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// Orchestration coverage for SupplierRedeemCardController, testable
/// without pumping a widget tree.
///
/// This complements rather than replaces
/// test/screens/supplier_redeem_card_test.dart, which still exercises the
/// same crypto/verification logic end-to-end through the screen's
/// ForTesting hooks - deliberately kept in place (unlike qr_scanner_screen's
/// migrated hook) because this screen's State class still does real
/// dialog/navigation orchestration (device-mismatch confirmation, the
/// manual-redemption success dialog, the redemption-QR Navigator.push) that
/// only a widget-level test can verify. What's added here is fast,
/// no-camera-no-dialog coverage of the controller's own logic in isolation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late KeyManager keyManager;
  late BusinessRepository businessRepo;
  late SupplierRedeemCardController controller;
  late ECPrivateKey privateKey;

  const businessId = 'business-redeem-controller-test';

  Future<void> seedBusiness({required OperationMode mode, int stampsRequired = 8}) async {
    final keyPair = await keyManager.generateKeyPair();
    privateKey = keyPair.privateKey as ECPrivateKey;
    await keyManager.storePrivateKey(businessId, privateKey);
    await keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);
    final publicKeyEncoded = (await keyManager.getPublicKeyString(businessId))!;

    await businessRepo.insertBusiness(Business(
      id: businessId,
      name: 'Test Spa',
      publicKey: publicKeyEncoded,
      privateKey: 'unused-plaintext-field',
      stampsRequired: stampsRequired,
      brandColor: '#6A1B9A',
      mode: mode,
      createdAt: DateTime.now(),
    ));
  }

  Future<List<RedemptionStampProof>> buildValidStampProofs({
    required String cardId,
    required int count,
  }) async {
    final proofs = <RedemptionStampProof>[];
    String previousHash = '';
    for (var i = 1; i <= count; i++) {
      final timestamp = 1700000000000 + i;
      final data = '$cardId:$i:$timestamp:$previousHash:1::';
      final signature = await keyManager.signData(data, privateKey);
      proofs.add(RedemptionStampProof(signature: signature!, timestamp: timestamp));
      previousHash = signature;
    }
    return proofs;
  }

  late SupplierDatabaseHelper dbHelper;

  setUp(() async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    await SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_redeem_card_controller.db');
    dbHelper = SupplierDatabaseHelper();

    keyManager = KeyManager();
    businessRepo = BusinessRepository();
    controller = SupplierRedeemCardController(
      businessRepository: businessRepo,
      keyManager: keyManager,
    );
  });

  // resetForTesting() doesn't delete the underlying db file, so data from an
  // earlier test in this file can otherwise leak into a later one (matches
  // the same pattern test/screens/supplier_redeem_card_test.dart guards
  // against) - explicitly wipe between tests instead.
  tearDown(() async {
    await dbHelper.clearAllData();
  });

  group('loadBusiness', () {
    test('loads the seeded business', () async {
      await seedBusiness(mode: OperationMode.secure);

      final result = await controller.loadBusiness();

      expect(result.isSuccess, isTrue);
      expect(controller.business?.id, businessId);
    });
  });

  group('recordManualRedemption', () {
    test('fails gracefully (not a thrown exception) if called before loadBusiness()', () async {
      // Reachable via the screen's processManualRedemptionForTesting() hook
      // without going through the UI's own _business == null guard first -
      // must degrade gracefully, not throw, matching the pre-extraction
      // code's own try/catch-everything behavior here.
      final result = await controller.recordManualRedemption();

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.loadFailed);
      expect(result.errorMessage, isNotNull);
    });

    test('logs the redemption using the business\'s stampsRequired', () async {
      await seedBusiness(mode: OperationMode.simple, stampsRequired: 10);
      await controller.loadBusiness();

      final result = await controller.recordManualRedemption();

      expect(result.isSuccess, isTrue);
      expect(result.stampsRedeemed, 10);
      expect(result.redeemedAt, isNotNull);
    });
  });

  group('parseRedemptionQr', () {
    test('recognizes a plain-JSON redemption_request token', () async {
      await seedBusiness(mode: OperationMode.secure);
      final proofs = await buildValidStampProofs(cardId: 'card-parse-json', count: 8);
      final token = RedemptionRequestToken(
        cardId: 'card-parse-json',
        businessId: businessId,
        stampsCollected: 8,
        stampProofs: proofs,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      var recognized = false;

      final result = await controller.parseRedemptionQr(
        token.toQRString(),
        onTokenRecognized: () => recognized = true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.cardId, 'card-parse-json');
      expect(result.stampsCollected, 8);
      expect(result.token, isNotNull);
      expect(recognized, isTrue);
    });

    test('recognizes the TEST-020 compact-encoded token', () async {
      await seedBusiness(mode: OperationMode.secure);
      final proofs = await buildValidStampProofs(cardId: 'card-parse-compact', count: 8);
      final token = RedemptionRequestToken(
        cardId: 'card-parse-compact',
        businessId: businessId,
        stampsCollected: 8,
        stampProofs: proofs,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.parseRedemptionQr(RedemptionQrCodec.encode(token));

      expect(result.isSuccess, isTrue);
      expect(result.cardId, 'card-parse-compact');
      expect(result.token, isNotNull);
    });

    test('recognizes the legacy LOYALTYCARD:REDEEM: format with no token payload', () async {
      final result = await controller.parseRedemptionQr('LOYALTYCARD:REDEEM:card-legacy:8');

      expect(result.isSuccess, isTrue);
      expect(result.cardId, 'card-legacy');
      expect(result.stampsCollected, 8);
      expect(result.token, isNull);
    });

    test('reports a not-ready-yet card_stamp_request as a distinct, non-error outcome', () async {
      final stampToken = CardStampRequestToken(
        cardId: 'card-incomplete',
        businessId: businessId,
        currentStamps: 3,
        publicKey: 'some-public-key',
        lastStampHash: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.parseRedemptionQr(stampToken.toQRString());

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.notReadyYet);
      expect(result.errorMessage, contains('3 stamps'));
    });

    test('rejects unparseable data with a generic message', () async {
      final result = await controller.parseRedemptionQr('not a valid qr payload at all');

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.invalidQr);
    });
  });

  group('validateRedemptionToken', () {
    test('flags device mismatch as its own failure reason, not a generic error', () async {
      final proofs = await (() async {
        await seedBusiness(mode: OperationMode.secure);
        return buildValidStampProofs(cardId: 'card-mismatch', count: 8);
      })();
      final token = RedemptionRequestToken(
        cardId: 'card-mismatch',
        businessId: businessId,
        stampsCollected: 8,
        stampProofs: proofs,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        cardDeviceId: 'device-A',
        currentDeviceId: 'device-B',
      );

      final result = controller.validateRedemptionToken(token);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.deviceMismatch);
    });

    test('a token with no device recorded (legacy) is not a mismatch', () async {
      await seedBusiness(mode: OperationMode.secure);
      final proofs = await buildValidStampProofs(cardId: 'card-legacy-device', count: 8);
      final token = RedemptionRequestToken(
        cardId: 'card-legacy-device',
        businessId: businessId,
        stampsCollected: 8,
        stampProofs: proofs,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = controller.validateRedemptionToken(token);

      expect(result.isSuccess, isTrue);
    });
  });

  group('confirmRedemption', () {
    test('a genuinely signed redemption verifies, signs, and logs', () async {
      await seedBusiness(mode: OperationMode.secure, stampsRequired: 8);
      const cardId = 'card-confirm-valid';
      final proofs = await buildValidStampProofs(cardId: cardId, count: 8);
      final token = RedemptionRequestToken(
        cardId: cardId,
        businessId: businessId,
        stampsCollected: 8,
        stampProofs: proofs,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.confirmRedemption(cardId, 8, token: token);

      expect(result.isSuccess, isTrue);
      expect(result.redemptionToken, isNotNull);
      expect(result.redemptionToken!.cardId, cardId);
      expect(result.redemptionToken!.stampsRedeemed, 8);
      expect(await businessRepo.hasBeenRedeemed(cardId), isTrue);

      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final verification = CryptoUtils.verifySignature(
        data: result.redemptionToken!.getSignatureData(),
        signatureBase64: result.redemptionToken!.signature,
        publicKeyEncoded: publicKeyEncoded!,
      );
      expect(verification.isValid, isTrue);
    });

    test('V-012: tampered/replayed signatures from a different card are rejected', () async {
      await seedBusiness(mode: OperationMode.secure, stampsRequired: 8);
      // Genuinely signed stamps for a DIFFERENT card, attached to this one -
      // verifyRedemptionStampChain reconstructs each stamp's signed data
      // using the token's own cardId, so this must fail even though every
      // signature is individually real.
      final proofs = await buildValidStampProofs(cardId: 'card-original', count: 8);
      final token = RedemptionRequestToken(
        cardId: 'card-tampered',
        businessId: businessId,
        stampsCollected: 8,
        stampProofs: proofs,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.confirmRedemption('card-tampered', 8, token: token);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.verificationFailed);
      expect(await businessRepo.hasBeenRedeemed('card-tampered'), isFalse);
    });

    test('V-013: an already-redeemed card is rejected', () async {
      await seedBusiness(mode: OperationMode.secure, stampsRequired: 8);
      const cardId = 'card-already-redeemed';
      await businessRepo.logRedemption(cardId: cardId, stampsRedeemed: 8, businessId: businessId);
      final proofs = await buildValidStampProofs(cardId: cardId, count: 8);
      final token = RedemptionRequestToken(
        cardId: cardId,
        businessId: businessId,
        stampsCollected: 8,
        stampProofs: proofs,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.confirmRedemption(cardId, 8, token: token);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.alreadyRedeemed);
    });

    test('an incomplete card (fewer stamps than required) is rejected even with valid signatures', () async {
      await seedBusiness(mode: OperationMode.secure, stampsRequired: 8);
      const cardId = 'card-incomplete-confirm';
      final proofs = await buildValidStampProofs(cardId: cardId, count: 5);
      final token = RedemptionRequestToken(
        cardId: cardId,
        businessId: businessId,
        stampsCollected: 5,
        stampProofs: proofs,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.confirmRedemption(cardId, 5, token: token);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.verificationFailed);
    });

    test('Secure Mode rejects the legacy/unsigned format outright (no token)', () async {
      await seedBusiness(mode: OperationMode.secure, stampsRequired: 8);

      final result = await controller.confirmRedemption('card-legacy-secure', 8, token: null);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.verificationFailed);
    });

    test('Express Mode redeems the legacy/unsigned format without any signature check (V-001)', () async {
      await seedBusiness(mode: OperationMode.simple, stampsRequired: 8);

      final result = await controller.confirmRedemption('card-legacy-express', 8, token: null);

      expect(result.isSuccess, isTrue);
      expect(result.redemptionToken!.stampsRedeemed, 8);
    });

    test('fails clearly if no business is configured', () async {
      // No seedBusiness() call - nothing in the database.
      final result = await controller.confirmRedemption('card-no-business', 1);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, SupplierScanFailureReason.loadFailed);
    });
  });
}
