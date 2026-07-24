import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:pointycastle/export.dart';
import 'package:shared/shared.dart';
import 'package:supplier_app/services/key_manager.dart';
import 'package:supplier_app/services/qr_token_generator.dart';

/// Exercises the real signing path end-to-end: generate a key pair, store it
/// via KeyManager (backed by flutter_secure_storage's official in-memory
/// test fake - no real Keychain/Keystore access needed), generate a real
/// token, and verify the signature actually validates via CryptoUtils. This
/// is the mechanism V-010/V-011 fixed the signed-data format for.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyManager keyManager;
  late QRTokenGenerator generator;
  const businessId = 'business-1';

  setUp(() async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    keyManager = KeyManager();
    generator = QRTokenGenerator(keyManager);

    final keyPair = await keyManager.generateKeyPair();
    await keyManager.storePrivateKey(businessId, keyPair.privateKey as ECPrivateKey);
    await keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);
  });

  group('QRTokenGenerator.generateStampToken', () {
    test('produces a token whose signature genuinely verifies', () async {
      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final token = await generator.generateStampToken(
        businessId: businessId,
        cardId: 'card-1',
        stampNumber: 1,
        previousHash: '',
      );

      final result = CryptoUtils.verifySignature(
        data: token.getSignatureData(),
        signatureBase64: token.signature,
        publicKeyEncoded: publicKeyEncoded!,
      );

      expect(result.isValid, isTrue);
    });

    test('defaults stampCount=1, expiryDate=null, scanInterval=null for a plain Secure Mode stamp', () async {
      final token = await generator.generateStampToken(
        businessId: businessId,
        cardId: 'card-1',
        stampNumber: 1,
        previousHash: '',
      );

      expect(token.stampCount, 1);
      expect(token.expiryDate, isNull);
      expect(token.scanInterval, isNull);
    });

    test('a tampered stampCount invalidates the signature (V-010 regression)', () async {
      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final token = await generator.generateStampToken(
        businessId: businessId,
        cardId: 'card-1',
        stampNumber: 1,
        previousHash: '',
      );

      // Simulate an attacker editing stampCount after the token was signed.
      final tamperedSignatureData = StampToken(
        id: token.id,
        cardId: token.cardId,
        businessId: token.businessId,
        stampNumber: token.stampNumber,
        previousHash: token.previousHash,
        signature: token.signature,
        timestamp: token.timestamp,
        stampCount: 10, // attacker inflates a single-stamp token
      ).getSignatureData();

      final result = CryptoUtils.verifySignature(
        data: tamperedSignatureData,
        signatureBase64: token.signature,
        publicKeyEncoded: publicKeyEncoded!,
      );

      expect(result.isValid, isFalse);
    });

    test('Simple Mode multi-denomination fields (REQ-022) round-trip and sign correctly', () async {
      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final expiry = DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;

      final token = await generator.generateStampToken(
        businessId: businessId,
        cardId: 'express-mode-stamp',
        stampNumber: 1,
        previousHash: '',
        stampCount: 5,
        expiryDate: expiry,
        scanInterval: 45,
      );

      expect(token.stampCount, 5);
      expect(token.expiryDate, expiry);
      expect(token.scanInterval, 45);

      final result = CryptoUtils.verifySignature(
        data: token.getSignatureData(),
        signatureBase64: token.signature,
        publicKeyEncoded: publicKeyEncoded!,
      );
      expect(result.isValid, isTrue);
    });

    test('additionalStamps are each independently, validly signed and chained', () async {
      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final token = await generator.generateStampToken(
        businessId: businessId,
        cardId: 'card-1',
        stampNumber: 1,
        previousHash: '',
        additionalStampCount: 2,
      );

      expect(token.additionalStamps.length, 2);
      expect(token.additionalStamps[0].stampNumber, 2);
      expect(token.additionalStamps[1].stampNumber, 3);

      // Each additional stamp's signature must independently verify against
      // its own chain data - main stamp signature is stamp 1's previousHash.
      String previousHash = token.signature;
      for (final additional in token.additionalStamps) {
        final data = '${token.cardId}:${additional.stampNumber}:${additional.timestamp}:$previousHash';
        final result = CryptoUtils.verifySignature(
          data: data,
          signatureBase64: additional.signature,
          publicKeyEncoded: publicKeyEncoded!,
        );
        expect(result.isValid, isTrue, reason: 'additional stamp ${additional.stampNumber} signature invalid');
        previousHash = additional.signature;
      }
    });

    test('throws when no private key is stored for the business', () async {
      expect(
        () => generator.generateStampToken(
          businessId: 'unknown-business',
          cardId: 'card-1',
          stampNumber: 1,
          previousHash: '',
        ),
        throwsException,
      );
    });
  });

  group('QRTokenGenerator.generateCardIssueToken', () {
    test('produces a token whose signature genuinely verifies', () async {
      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final business = Business(
        id: businessId,
        name: 'Test Coffee',
        publicKey: publicKeyEncoded!,
        privateKey: '',
        stampsRequired: 10,
        brandColor: '#FF5733',
        mode: OperationMode.secure,
        createdAt: DateTime.now(),
      );

      final token = await generator.generateCardIssueToken(business: business);

      final result = CryptoUtils.verifySignature(
        data: token.getSignatureData(),
        signatureBase64: token.signature,
        publicKeyEncoded: publicKeyEncoded,
      );
      expect(result.isValid, isTrue);
    });

    test('a tampered mode invalidates the signature (V-011 regression)', () async {
      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final business = Business(
        id: businessId,
        name: 'Test Coffee',
        publicKey: publicKeyEncoded!,
        privateKey: '',
        stampsRequired: 10,
        brandColor: '#FF5733',
        mode: OperationMode.secure,
        createdAt: DateTime.now(),
      );

      final token = await generator.generateCardIssueToken(business: business);

      // Simulate an attacker editing mode after the token was signed.
      final downgraded = CardIssueToken(
        businessId: token.businessId,
        businessName: token.businessName,
        publicKey: token.publicKey,
        stampsRequired: token.stampsRequired,
        brandColor: token.brandColor,
        mode: OperationMode.simple,
        signature: token.signature,
        cardId: token.cardId,
        timestamp: token.timestamp,
      );

      final result = CryptoUtils.verifySignature(
        data: downgraded.getSignatureData(),
        signatureBase64: token.signature,
        publicKeyEncoded: publicKeyEncoded,
      );
      expect(result.isValid, isFalse);
    });

    test('includes correctly chained, independently-signed initial stamps', () async {
      final publicKeyEncoded = await keyManager.getPublicKeyString(businessId);
      final business = Business(
        id: businessId,
        name: 'Test Coffee',
        publicKey: publicKeyEncoded!,
        privateKey: '',
        stampsRequired: 10,
        brandColor: '#FF5733',
        mode: OperationMode.secure,
        createdAt: DateTime.now(),
      );

      final token = await generator.generateCardIssueToken(
        business: business,
        initialStampCount: 3,
      );

      expect(token.initialStamps.length, 3);

      String previousHash = '';
      for (final stamp in token.initialStamps) {
        final data = '${token.cardId}:${stamp.stampNumber}:${stamp.timestamp}:$previousHash';
        final result = CryptoUtils.verifySignature(
          data: data,
          signatureBase64: stamp.signature,
          publicKeyEncoded: publicKeyEncoded,
        );
        expect(result.isValid, isTrue, reason: 'initial stamp ${stamp.stampNumber} signature invalid');
        previousHash = stamp.signature;
      }
    });

    test('throws when no private key is stored for the business', () async {
      final business = Business(
        id: 'unknown-business',
        name: 'Test Coffee',
        publicKey: 'irrelevant',
        privateKey: '',
        stampsRequired: 10,
        brandColor: '#FF5733',
        createdAt: DateTime.now(),
      );

      expect(
        () => generator.generateCardIssueToken(business: business),
        throwsException,
      );
    });
  });
}
