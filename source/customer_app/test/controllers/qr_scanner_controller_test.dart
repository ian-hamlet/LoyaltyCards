import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:customer_app/controllers/controller_results.dart';
import 'package:customer_app/controllers/qr_scanner_controller.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:customer_app/services/stamp_repository.dart';
import 'package:customer_app/services/transaction_repository.dart';

/// Orchestration coverage for QrScannerController's dispatch, card-issue and
/// redemption paths.
///
/// The §4.1 stamp-crediting policy - the highest-value scenario and the one
/// that already had a safety net - stays in
/// `test/screens/qr_scanner_screen_stamp_snapshot_test.dart`, migrated from
/// the deleted `handleQRCodeForTesting` widget hook. What is added here are
/// the guard and dispatch branches that were previously unreachable from a
/// test at all, being buried behind a live camera: they need no crypto, only
/// the sequence of checks around it.
///
/// Signature-verification success paths are deliberately not covered here.
/// The customer app can only verify, never sign (KeyManager delegates to
/// CryptoUtils.verifySignature and there is no signing counterpart on this
/// side), so producing a genuinely valid supplier signature would mean
/// reaching into the supplier app. Verification itself has its own coverage
/// in test/services/token_validator_test.dart and key_manager_test.dart.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CardRepository cardRepo;
  late StampRepository stampRepo;
  late TransactionRepository transactionRepo;
  late QrScannerController controller;

  const businessId = 'business-scanner-test';

  Future<void> resetDb(String dbName) async {
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, dbName);
    if (await File(dbPath).exists()) {
      await File(dbPath).delete();
    }
    await DatabaseHelper.resetForTesting(testDatabaseName: dbName);

    final dbHelper = DatabaseHelper();
    cardRepo = CardRepository(dbHelper);
    stampRepo = StampRepository(dbHelper);
    transactionRepo = TransactionRepository(dbHelper);
    controller = QrScannerController(
      cardRepository: cardRepo,
      stampRepository: stampRepo,
      transactionRepository: transactionRepo,
      databaseHelper: dbHelper,
      deviceIdProvider: () async => 'test-device-id',
    );
  }

  CardIssueToken issueToken({
    String? cardId,
    OperationMode mode = OperationMode.simple,
    String businessName = 'Scanner Test Cafe',
    int stampsRequired = 6,
  }) {
    return CardIssueToken(
      businessId: businessId,
      businessName: businessName,
      publicKey: 'scanner-test-public-key',
      stampsRequired: stampsRequired,
      brandColor: '#AA33BB',
      logoIndex: 3,
      mode: mode,
      // Non-empty so it clears the structural check, but not a real
      // signature - card issuance verifies in both modes, so this token can
      // never get past TokenValidator. See the note on the validation group.
      signature: 'not-a-real-signature',
      cardId: cardId ?? 'issued-card-1',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<models.Card> insertCard({
    required String id,
    int stampsRequired = 4,
    int stampsCollected = 4,
    bool isRedeemed = false,
    String business = businessId,
  }) async {
    final now = DateTime.now();
    final card = models.Card(
      id: id,
      businessId: business,
      businessName: 'Scanner Test Cafe',
      businessPublicKey: 'scanner-test-public-key',
      stampsRequired: stampsRequired,
      stampsCollected: stampsCollected,
      brandColor: '#AA33BB',
      logoIndex: 3,
      mode: OperationMode.secure,
      createdAt: now,
      updatedAt: now,
      isRedeemed: isRedeemed,
      redeemedAt: isRedeemed ? now : null,
    );
    await cardRepo.insertCard(card);
    return card;
  }

  RedemptionToken redemptionToken({
    required String cardId,
    String business = businessId,
    int stampsRedeemed = 4,
  }) {
    return RedemptionToken(
      cardId: cardId,
      businessId: business,
      stampsRedeemed: stampsRedeemed,
      signature: 'not-a-real-signature',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  group('handleQrCode dispatch', () {
    test('unparseable data reports a stamp-specific message in receiveStamp mode', () async {
      await resetDb('scan_invalid_stamp_mode.db');

      final result = await controller.handleQrCode('this is not a token', QRScanMode.receiveStamp);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, ScanFailureReason.invalidQr);
      expect(result.message, contains('not a valid stamp QR code'));
    });

    test('unparseable data reports a card-specific message in addCard mode', () async {
      await resetDb('scan_invalid_card_mode.db');

      final result = await controller.handleQrCode('this is not a token', QRScanMode.addCard);

      expect(result.failureReason, ScanFailureReason.invalidQr);
      expect(result.message, contains('not a valid card QR code'));
    });

    test('onTokenRecognized fires for a parseable token and not for garbage', () async {
      await resetDb('scan_recognized_callback.db');

      var recognised = 0;
      await controller.handleQrCode('garbage', QRScanMode.addCard, onTokenRecognized: () => recognised++);
      expect(recognised, 0);

      await controller.handleQrCode(
        issueToken().toQRString(),
        QRScanMode.addCard,
        onTokenRecognized: () => recognised++,
      );
      expect(recognised, 1, reason: 'the haptic must fire once the code is readable, before the outcome is known');
    });

    test('a stamp token scanned in addCard mode is rejected as the wrong type', () async {
      await resetDb('scan_wrong_type_add.db');

      final token = StampToken(
        id: 's1',
        cardId: 'express-mode-stamp',
        businessId: businessId,
        stampNumber: 1,
        previousHash: '',
        signature: 'sig',
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      final result = await controller.handleQrCode(token.toQRString(), QRScanMode.addCard);

      expect(result.failureReason, ScanFailureReason.wrongTokenType);
      expect(result.message, 'Wrong QR type. Please scan a card issuance QR.');
    });

    test('a card-issue token scanned in receiveStamp mode gets the redirect-to-Add-Card message', () async {
      await resetDb('scan_wrong_type_stamp.db');

      final result = await controller.handleQrCode(issueToken().toQRString(), QRScanMode.receiveStamp);

      expect(result.failureReason, ScanFailureReason.wrongTokenType);
      expect(result.message, contains('Use Add Card to scan it'));
    });
  });

  group('handleCardIssue validation', () {
    // NOTE: card issuance verifies the supplier's signature in BOTH modes -
    // unlike a stamp token, where Express/Simple Mode skips crypto entirely
    // (see TokenValidator.validateCardIssueToken: the simple-mode branch
    // skips only the timestamp check, then still verifies). The customer app
    // has no signing counterpart, so the success path past that check is not
    // reachable from a customer_app test; what is covered here is that every
    // rejection reaching it is reported faithfully.

    test('an unverifiable signature is reported with the validator\'s own message', () async {
      await resetDb('scan_issue_bad_signature.db');

      final result = await controller.handleQrCode(issueToken().toQRString(), QRScanMode.addCard);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, ScanFailureReason.validationFailed);
      expect(result.message, contains('Invalid signature'));

      final all = await cardRepo.getCardsByBusiness(businessId);
      expect(all, isEmpty, reason: 'nothing may be written before the signature verifies');
    });

    test('a structural rejection passes the specific message straight through (TEST-019)', () async {
      // A business configured outside the supported stampsRequired range is a
      // permanent state the customer needs the real explanation for, not the
      // generic "invalid token" ErrorMessageMapper fallback.
      await resetDb('scan_issue_out_of_range.db');

      final result = await controller.handleQrCode(
        issueToken(stampsRequired: 99).toQRString(),
        QRScanMode.addCard,
      );

      expect(result.failureReason, ScanFailureReason.validationFailed);
      expect(result.message, contains('99 stamps'));
      expect(result.message, contains("doesn't support"));
    });
  });

  group('handleStampToken guards', () {
    test('a stamp for a business with no card reports card-not-found', () async {
      await resetDb('scan_stamp_no_card.db');

      final token = StampToken(
        id: 's1',
        cardId: 'express-mode-stamp',
        businessId: 'business-with-no-cards',
        stampNumber: 1,
        previousHash: '',
        signature: 'sig',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        scanInterval: 0,
      );

      final result = await controller.handleQrCode(token.toQRString(), QRScanMode.receiveStamp);

      expect(result.failureReason, ScanFailureReason.cardNotFound);
      expect(result.message, 'Card not found. Please add the card first.');
    });

    test('a scan inside the cooldown window is rate limited, distinctly from an error', () async {
      await resetDb('scan_stamp_rate_limited.db');
      final now = DateTime.now();
      await cardRepo.insertCard(models.Card(
        id: 'rate-limit-card',
        businessId: businessId,
        businessName: 'Scanner Test Cafe',
        businessPublicKey: 'scanner-test-public-key',
        stampsRequired: 8,
        stampsCollected: 1,
        brandColor: '#AA33BB',
        logoIndex: 3,
        mode: OperationMode.simple,
        createdAt: now,
        updatedAt: now,
      ));
      // A stamp collected just now, so any non-zero scan interval blocks.
      await stampRepo.insertStamp(Stamp(
        id: 'rate-limit-card_stamp_1',
        cardId: 'rate-limit-card',
        stampNumber: 1,
        timestamp: now,
        signature: 'seed-signature-1',
      ));

      final token = StampToken(
        id: 'rl-stamp',
        cardId: 'express-mode-stamp',
        businessId: businessId,
        stampNumber: 1,
        previousHash: '',
        signature: 'sig',
        timestamp: now.millisecondsSinceEpoch,
        scanInterval: 600, // ten minutes between scans
      );

      final result = await controller.handleQrCode(token.toQRString(), QRScanMode.receiveStamp);

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, ScanFailureReason.rateLimited);
      expect(result.message, isNotNull);

      final stamps = await stampRepo.getStampsByCard('rate-limit-card');
      expect(stamps.length, 1, reason: 'the blocked scan must not credit a stamp');
    });

    test('a scan with no cooldown configured is credited normally', () async {
      await resetDb('scan_stamp_credited.db');
      final now = DateTime.now();
      await cardRepo.insertCard(models.Card(
        id: 'credit-card',
        businessId: businessId,
        businessName: 'Scanner Test Cafe',
        businessPublicKey: 'scanner-test-public-key',
        stampsRequired: 8,
        stampsCollected: 0,
        brandColor: '#AA33BB',
        logoIndex: 3,
        mode: OperationMode.simple,
        createdAt: now,
        updatedAt: now,
      ));

      final token = StampToken(
        id: 'ok-stamp',
        cardId: 'express-mode-stamp',
        businessId: businessId,
        stampNumber: 1,
        previousHash: '',
        signature: 'sig',
        timestamp: now.millisecondsSinceEpoch,
        scanInterval: 0,
      );

      final result = await controller.handleQrCode(token.toQRString(), QRScanMode.receiveStamp);

      expect(result.isSuccess, isTrue);
      expect(result.message, 'Stamp added successfully!');
      expect((await cardRepo.getCardById('credit-card'))!.stampsCollected, 1);
    });
  });

  group('handleRedemptionToken guards', () {
    test('an unknown card reports card-not-found', () async {
      await resetDb('scan_redeem_no_card.db');

      final result = await controller.handleQrCode(
        redemptionToken(cardId: 'nope').toQRString(),
        QRScanMode.receiveStamp,
      );

      expect(result.failureReason, ScanFailureReason.cardNotFound);
    });

    test('a token from a different business is rejected before any signature work', () async {
      await resetDb('scan_redeem_mismatch.db');
      await insertCard(id: 'redeem-card');

      final result = await controller.handleQrCode(
        redemptionToken(cardId: 'redeem-card', business: 'some-other-business').toQRString(),
        QRScanMode.receiveStamp,
      );

      expect(result.failureReason, ScanFailureReason.businessMismatch);
      expect(result.message, 'Card business mismatch');
    });

    test('an incomplete card is rejected with the number of stamps still needed', () async {
      await resetDb('scan_redeem_incomplete.db');
      await insertCard(id: 'redeem-card', stampsRequired: 6, stampsCollected: 2);

      final result = await controller.handleQrCode(
        redemptionToken(cardId: 'redeem-card').toQRString(),
        QRScanMode.receiveStamp,
      );

      expect(result.failureReason, ScanFailureReason.cardNotComplete);
      expect(result.message, contains('4 more stamps'));
    });

    test('a single remaining stamp is described in the singular', () async {
      await resetDb('scan_redeem_incomplete_one.db');
      await insertCard(id: 'redeem-card', stampsRequired: 6, stampsCollected: 5);

      final result = await controller.handleQrCode(
        redemptionToken(cardId: 'redeem-card').toQRString(),
        QRScanMode.receiveStamp,
      );

      expect(result.message, contains('1 more stamp '));
      expect(result.message, isNot(contains('1 more stamps')));
    });

    test('an already-redeemed card is rejected', () async {
      await resetDb('scan_redeem_already.db');
      await insertCard(id: 'redeem-card', isRedeemed: true);

      final result = await controller.handleQrCode(
        redemptionToken(cardId: 'redeem-card').toQRString(),
        QRScanMode.receiveStamp,
      );

      expect(result.failureReason, ScanFailureReason.alreadyRedeemed);
      expect(result.message, 'This card has already been redeemed!');
    });

    test('a complete card with an invalid signature is rejected and stays unredeemed', () async {
      await resetDb('scan_redeem_bad_signature.db');
      await insertCard(id: 'redeem-card');

      final result = await controller.handleQrCode(
        redemptionToken(cardId: 'redeem-card').toQRString(),
        QRScanMode.receiveStamp,
      );

      expect(result.failureReason, ScanFailureReason.signatureInvalid);
      expect(result.message, contains('Invalid redemption signature'));

      final card = await cardRepo.getCardById('redeem-card');
      expect(card!.isRedeemed, isFalse, reason: 'nothing may be written before the signature verifies');
    });
  });
}
