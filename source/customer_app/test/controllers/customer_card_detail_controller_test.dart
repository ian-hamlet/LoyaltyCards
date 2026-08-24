import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:qr_flutter/qr_flutter.dart' show QrCode, QrErrorCorrectLevel;
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:customer_app/controllers/controller_results.dart';
import 'package:customer_app/controllers/customer_card_detail_controller.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:customer_app/services/qr_token_generator.dart';
import 'package:customer_app/services/stamp_repository.dart';
import 'package:customer_app/services/transaction_repository.dart';

/// Controller-level tests for CustomerCardDetailController.
///
/// These are plain `test()` cases, not `testWidgets()` - no widget tree, no
/// fake-async clock, no runAsync dance. That is the whole point of the
/// extraction, and the reason this file can pin things
/// customer_card_detail_test.dart structurally cannot:
///
///   qr_flutter's `QrImageView` keeps its payload in private fields
///   (`_data`, `_qrCode`), so the stamp-request JSON and the
///   plain-vs-compact redemption encoding were simply not observable from
///   outside the widget. The screen-level characterization tests pin every
///   branch that *is* observable; the QR payload contracts are pinned here.
///
/// The stamp-request shape below is a CROSS-APP contract: the supplier app
/// parses it via `CardStampRequestToken.fromJson`. It is asserted against
/// that model directly, so a drift on either side fails here.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CardRepository cardRepo;
  late StampRepository stampRepo;
  late TransactionRepository transactionRepo;

  const businessId = 'business-controller-test';
  const cardId = 'card-controller-test';
  const publicKey = 'test-public-key-abcdef';

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
  }

  CustomerCardDetailController buildController({String id = cardId}) {
    return CustomerCardDetailController(
      cardId: id,
      cardRepository: cardRepo,
      stampRepository: stampRepo,
      transactionRepository: transactionRepo,
      deviceIdProvider: () async => 'test-device-id',
    );
  }

  Future<models.Card> seed({
    required String dbName,
    int stampsRequired = 6,
    int stampsCollected = 2,
    int? stampRowCount,
    bool isRedeemed = false,
    OperationMode mode = OperationMode.secure,
    int? latestStampsRequiredSnapshot,
    String signatureFiller = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
  }) async {
    await resetDb(dbName);
    final now = DateTime.now();
    final card = models.Card(
      id: cardId,
      businessId: businessId,
      businessName: 'Controller Test Cafe',
      businessPublicKey: publicKey,
      stampsRequired: stampsRequired,
      stampsCollected: stampsCollected,
      brandColor: '#3366CC',
      logoIndex: 2,
      mode: mode,
      createdAt: now,
      updatedAt: now,
      isRedeemed: isRedeemed,
      redeemedAt: isRedeemed ? now : null,
      latestStampsRequiredSnapshot: latestStampsRequiredSnapshot,
      deviceId: 'origin-device',
    );
    await cardRepo.insertCard(card);

    for (var i = 1; i <= (stampRowCount ?? stampsCollected); i++) {
      await stampRepo.insertStamp(Stamp(
        id: '${cardId}_stamp_$i',
        cardId: cardId,
        stampNumber: i,
        timestamp: now.subtract(Duration(hours: 10 - (i % 9))),
        signature: 'sig-$i-$signatureFiller',
        previousHash: i == 1 ? null : 'sig-${i - 1}-$signatureFiller',
        deviceId: 'origin-device',
      ));
    }
    return card;
  }

  group('load() terminal states', () {
    test('an in-progress card caches the stamp-request QR and no redemption QR', () async {
      await seed(dbName: 'ctl_load_in_progress.db', stampsRequired: 6, stampsCollected: 2);
      final controller = buildController();

      final result = await controller.load();

      expect(result.isSuccess, isTrue);
      expect(controller.card, isNotNull);
      expect(controller.stamps.length, 2);
      expect(controller.currentDeviceId, 'test-device-id');
      expect(controller.cachedQrData, isNotNull);
      expect(controller.redemptionQrCode, isNull);
      expect(controller.qrTooLargeToRender, isFalse);
    });

    test('a complete-but-unredeemed card caches the redemption QR and clears the stamp-request one', () async {
      await seed(dbName: 'ctl_load_complete.db', stampsRequired: 4, stampsCollected: 4);
      final controller = buildController();

      final result = await controller.load();

      expect(result.isSuccess, isTrue);
      expect(controller.cachedQrData, isNull);
      expect(controller.redemptionQrCode, isNotNull);
      expect(controller.qrTooLargeToRender, isFalse);
    });

    test('an already-redeemed card caches the REDEEMED marker and no redemption QR', () async {
      await seed(dbName: 'ctl_load_redeemed.db', stampsRequired: 4, stampsCollected: 4, isRedeemed: true);
      final controller = buildController();

      await controller.load();

      expect(controller.cachedQrData, 'REDEEMED');
      expect(controller.redemptionQrCode, isNull);
      expect(controller.qrTooLargeToRender, isFalse);
    });

    test('a missing card leaves a null card and an empty stamp-request payload', () async {
      await resetDb('ctl_load_missing.db');
      final controller = buildController(id: 'no-such-card');

      final result = await controller.load();

      expect(result.isSuccess, isTrue, reason: 'a missing card is not a load failure');
      expect(controller.card, isNull);
      expect(controller.cachedQrData, '');
    });

    test('a repository failure returns a failure result and leaves prior data untouched', () async {
      await seed(dbName: 'ctl_load_failure.db');
      final controller = CustomerCardDetailController(
        cardId: cardId,
        cardRepository: _ThrowingCardRepository(),
        stampRepository: stampRepo,
        transactionRepository: transactionRepo,
        deviceIdProvider: () async => 'test-device-id',
      );

      final result = await controller.load();

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, CardDetailFailureReason.loadFailed);
      expect(result.errorMessage, isNotNull);
      expect(result.errorMessage, isNotEmpty);
      expect(controller.card, isNull);
    });
  });

  group('generateCardQr() - cross-app payload contract', () {
    test('emits exactly the field set CardStampRequestToken parses', () async {
      await seed(dbName: 'ctl_qr_shape.db', stampsRequired: 6, stampsCollected: 3);
      final controller = buildController();
      await controller.load();

      final raw = controller.cachedQrData!;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;

      // Exact key set - an added or renamed field is a breaking change for
      // every supplier app already in the field.
      expect(
        decoded.keys.toSet(),
        {'type', 'cardId', 'businessId', 'currentStamps', 'publicKey', 'lastStampHash', 'timestamp'},
      );

      expect(decoded['type'], 'card_stamp_request');
      expect(decoded['cardId'], cardId);
      expect(decoded['businessId'], businessId);
      expect(decoded['currentStamps'], 3);
      expect(decoded['publicKey'], publicKey);
      expect(decoded['lastStampHash'], controller.stamps.last.signature);
      expect(decoded['timestamp'], isA<int>());

      // And it must actually round-trip through the shared model the
      // supplier app uses (supplier_stamp_card.dart's _handleQRCode).
      final token = CardStampRequestToken.fromJson(decoded);
      expect(token.cardId, cardId);
      expect(token.businessId, businessId);
      expect(token.currentStamps, 3);
      expect(token.publicKey, publicKey);
      expect(token.lastStampHash, controller.stamps.last.signature);
      expect(token.isValid(), isTrue);
      expect(token.toJson().keys.toSet(), decoded.keys.toSet());
    });

    test('lastStampHash is the LAST stamp signature, and empty when there are no stamps', () async {
      await seed(dbName: 'ctl_qr_no_stamps.db', stampsRequired: 6, stampsCollected: 0);
      final controller = buildController();
      await controller.load();

      final decoded = jsonDecode(controller.cachedQrData!) as Map<String, dynamic>;
      expect(decoded['lastStampHash'], '');
      expect(decoded['currentStamps'], 0);
    });

    test('a redeemed card returns the REDEEMED marker rather than a payload', () async {
      await seed(dbName: 'ctl_qr_redeemed.db', stampsRequired: 4, stampsCollected: 4, isRedeemed: true);
      final controller = buildController();
      await controller.load();

      expect(controller.generateCardQr(), 'REDEEMED');
    });

    test('with no card loaded it returns an empty string, never null or a throw', () {
      final controller = buildController();
      expect(controller.generateCardQr(), '');
    });
  });

  group('buildRedemptionQrCode() - size fallback ladder', () {
    test('a small card takes the plain-JSON path (same QR geometry as encoding the JSON directly)', () async {
      await seed(dbName: 'ctl_ladder_plain.db', stampsRequired: 3, stampsCollected: 3);
      final controller = buildController();
      await controller.load();

      final built = controller.redemptionQrCode;
      expect(built, isNotNull);

      // Rebuild the same token independently and confirm the plain JSON does
      // fit - if it does, TEST-022 requires the plain path to have been taken.
      final token = QRTokenGenerator().generateRedemptionRequest(
        card: controller.card!,
        stamps: controller.stamps,
        cardDeviceId: controller.card!.deviceId,
        currentDeviceId: controller.currentDeviceId,
      );
      final plainJson = token.toQRString();
      expect(QrCapacity.fits(plainJson), isTrue);

      final expected = QrCode.fromData(data: plainJson, errorCorrectLevel: QrErrorCorrectLevel.L);
      expect(built!.typeNumber, expected.typeNumber);
      expect(built.moduleCount, expected.moduleCount);
    });

    test('an oversized card falls back to the compact alphanumeric encoding', () async {
      // 30 stamps of realistic signature length overflows byte-mode QR
      // capacity as plain JSON, so a non-null result can only have come from
      // the RedemptionQrCodec (gzip + Base45) branch - TEST-020.
      await seed(dbName: 'ctl_ladder_compact.db', stampsRequired: 30, stampsCollected: 30);
      final controller = buildController();
      await controller.load();

      final token = QRTokenGenerator().generateRedemptionRequest(
        card: controller.card!,
        stamps: controller.stamps,
        cardDeviceId: controller.card!.deviceId,
        currentDeviceId: controller.currentDeviceId,
      );
      expect(
        QrCapacity.fits(token.toQRString()),
        isFalse,
        reason: 'the premise of this test is that the plain path is unavailable',
      );

      expect(controller.redemptionQrCode, isNotNull, reason: 'the compact encoding must still fit');
      expect(controller.qrTooLargeToRender, isFalse);

      // And the compact payload really does decode back to the same token.
      final roundTripped = RedemptionQrCodec.decode(RedemptionQrCodec.encode(token));
      expect(roundTripped.cardId, cardId);
      expect(roundTripped.stampProofs.length, 30);
    });

    test('inconsistent card/stamp data returns null and flags too-large-to-render', () async {
      // QRTokenGenerator rejects stampsCollected != stamps.length; the catch
      // in buildRedemptionQrCode turns that into the same null result as a
      // payload that genuinely exceeds capacity.
      await seed(dbName: 'ctl_ladder_null.db', stampsRequired: 5, stampsCollected: 5, stampRowCount: 3);
      final controller = buildController();
      await controller.load();

      expect(controller.redemptionQrCode, isNull);
      expect(controller.qrTooLargeToRender, isTrue);
      expect(controller.buildRedemptionQrCode(), isNull);
    });

    test('with no card loaded it returns null rather than throwing', () {
      final controller = buildController();
      expect(controller.buildRedemptionQrCode(), isNull);
    });
  });

  group('processRedemption()', () {
    test('marks redeemed, logs the transaction, and reports a genuinely new card', () async {
      await seed(dbName: 'ctl_redeem_new.db', stampsRequired: 4, stampsCollected: 4, mode: OperationMode.simple);
      final controller = buildController();
      await controller.load();

      final result = await controller.processRedemption();

      expect(result.isSuccess, isTrue);
      expect(result.newCardCreated, isTrue);
      expect(result.redeemedAt, isNotNull);

      final redeemed = await cardRepo.getCardById(cardId);
      expect(redeemed!.isRedeemed, isTrue);

      final transactions = await transactionRepo.getTransactionsByCard(cardId);
      expect(transactions.where((t) => t.type == TransactionType.redemption).length, 1);

      final all = await cardRepo.getCardsByBusiness(businessId);
      expect(all.length, 2);
      expect(all.firstWhere((c) => c.id != cardId).stampsCollected, 0);
    });

    test('reports newCardCreated=false when an existing under-filled card is reused (Q-004)', () async {
      await seed(dbName: 'ctl_redeem_reuse.db', stampsRequired: 4, stampsCollected: 4, mode: OperationMode.simple);
      final now = DateTime.now();
      await cardRepo.insertCard(models.Card(
        id: 'spare-card',
        businessId: businessId,
        businessName: 'Controller Test Cafe',
        businessPublicKey: publicKey,
        stampsRequired: 4,
        stampsCollected: 1,
        brandColor: '#3366CC',
        logoIndex: 2,
        mode: OperationMode.simple,
        createdAt: now,
        updatedAt: now,
      ));

      final controller = buildController();
      await controller.load();

      final result = await controller.processRedemption();

      expect(result.isSuccess, isTrue);
      expect(result.newCardCreated, isFalse);

      final all = await cardRepo.getCardsByBusiness(businessId);
      expect(all.length, 2, reason: 'no third card should have appeared');
    });

    test('a new card takes stampsRequired from latestStampsRequiredSnapshot (§4.1)', () async {
      await seed(
        dbName: 'ctl_redeem_snapshot.db',
        stampsRequired: 4,
        stampsCollected: 4,
        mode: OperationMode.simple,
        latestStampsRequiredSnapshot: 9,
      );
      final controller = buildController();
      await controller.load();

      await controller.processRedemption();

      final all = await cardRepo.getCardsByBusiness(businessId);
      final fresh = all.firstWhere((c) => c.id != cardId);
      expect(fresh.stampsRequired, 9);
      expect((await cardRepo.getCardById(cardId))!.stampsRequired, 4);
    });

    test('a write failure returns a failure result rather than throwing', () async {
      await seed(dbName: 'ctl_redeem_failure.db', stampsRequired: 4, stampsCollected: 4);
      final controller = CustomerCardDetailController(
        cardId: cardId,
        cardRepository: _ThrowingOnRedeemCardRepository(),
        stampRepository: stampRepo,
        transactionRepository: transactionRepo,
        deviceIdProvider: () async => 'test-device-id',
      );
      // Load through a healthy repo first so a card is present.
      final healthy = buildController();
      await healthy.load();
      await controller.load();

      final result = await controller.processRedemption();

      expect(result.isSuccess, isFalse);
      expect(result.failureReason, CardDetailFailureReason.redeemFailed);
      expect(result.errorMessage, isNotNull);
      expect(result.newCardCreated, isFalse);
    });

    test('throws for the unreachable no-card-loaded case (programmer error, not a result)', () async {
      await resetDb('ctl_redeem_no_card.db');
      final controller = buildController();
      expect(() => controller.processRedemption(), throwsStateError);
    });
  });
}

/// Injected fake proving the constructor seam works: production code keeps
/// its real defaults, tests substitute behaviour.
class _ThrowingCardRepository extends CardRepository {
  _ThrowingCardRepository() : super(DatabaseHelper());

  @override
  Future<models.Card?> getCardById(String id) async {
    throw StateError('simulated database failure');
  }
}

class _ThrowingOnRedeemCardRepository extends CardRepository {
  _ThrowingOnRedeemCardRepository() : super(DatabaseHelper());

  @override
  Future<void> markCardAsRedeemed(String cardId) async {
    throw StateError('simulated redemption write failure');
  }
}
