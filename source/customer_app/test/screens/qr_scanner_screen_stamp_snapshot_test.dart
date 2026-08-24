import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:customer_app/controllers/qr_scanner_controller.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:customer_app/services/stamp_repository.dart';
import 'package:customer_app/services/transaction_repository.dart';

/// Covers the directional business-profile-snapshot policy applied on an
/// ordinary stamp scan (Requirements/DISCUSSION_Business_Field_Editing.md
/// §4.1): a stampsRequired decrease applies immediately to the in-progress
/// card; an increase never does (only recorded for the next card, at
/// redemption); name/icon/color always take the freshest value. Uses
/// Express Mode throughout - no crypto signature verification needed for
/// this logic, which runs identically before the mode-specific validation
/// branch.
///
/// These are the same six scenarios that previously drove the real
/// _handleStampToken path through QRScannerScreen.handleQRCodeForTesting -
/// a @visibleForTesting hook on the widget that existed only because the
/// logic was trapped inside a State class with no camera to feed it. That
/// logic now lives in QrScannerController, so they call it directly and the
/// hook has been deleted: no widget tree, no fake MobileScannerPlatform, no
/// runAsync/pumpAndSettle, and plain `test()` instead of `testWidgets()`.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CardRepository cardRepo;
  late StampRepository stampRepo;
  late QrScannerController controller;
  const businessId = 'business-snapshot-test';

  Future<models.Card> seedCard({
    required String dbName,
    required int stampsRequired,
    int stampsCollected = 0,
    String businessName = 'Original Name',
    String brandColor = '#111111',
    int logoIndex = 1,
  }) async {
    // resetForTesting() swaps in a fresh DatabaseHelper singleton but does
    // not delete the underlying sqflite file - a db file left over from a
    // prior run (e.g. one this suite's own overflow-completion test writes
    // a real new-card row to) would otherwise leak stale rows into this
    // run. Delete it first for true per-test isolation, mirroring
    // database_migration_test.dart's setUp.
    final databasesPath = await getDatabasesPath();
    final dbPath = join(databasesPath, dbName);
    if (await File(dbPath).exists()) {
      await File(dbPath).delete();
    }
    await DatabaseHelper.resetForTesting(testDatabaseName: dbName);

    final dbHelper = DatabaseHelper();
    cardRepo = CardRepository(dbHelper);
    stampRepo = StampRepository(dbHelper);
    controller = QrScannerController(
      cardRepository: cardRepo,
      stampRepository: stampRepo,
      transactionRepository: TransactionRepository(dbHelper),
      databaseHelper: dbHelper,
      deviceIdProvider: () async => 'test-device-id',
    );

    final now = DateTime.now();
    final card = models.Card(
      id: 'card-snapshot-test',
      businessId: businessId,
      businessName: businessName,
      businessPublicKey: 'unused-public-key',
      stampsRequired: stampsRequired,
      stampsCollected: stampsCollected,
      brandColor: brandColor,
      logoIndex: logoIndex,
      mode: OperationMode.simple,
      createdAt: now,
      updatedAt: now,
    );
    await cardRepo.insertCard(card);

    // Pre-existing stamps, timestamped well outside any cooldown window, so
    // the test's one real scan below never gets rate-limited.
    for (var i = 1; i <= stampsCollected; i++) {
      await stampRepo.insertStamp(Stamp(
        id: 'card-snapshot-test_stamp_$i',
        cardId: card.id,
        stampNumber: i,
        timestamp: now.subtract(const Duration(hours: 1)),
        signature: 'seed-signature-$i',
      ));
    }

    return card;
  }

  /// Drives one scan through the real stamp-handling path.
  Future<void> scan(StampToken token) async {
    final result = await controller.handleQrCode(token.toQRString(), QRScanMode.receiveStamp);
    expect(result.isSuccess, isTrue, reason: 'scan rejected: ${result.message}');
  }

  StampToken stampToken({
    String? businessName,
    String? brandColor,
    int? logoIndex,
    int? snapshotStampsRequired,
  }) {
    return StampToken(
      id: 'stamp-snapshot-test',
      cardId: 'express-mode-stamp',
      businessId: businessId,
      stampNumber: 1,
      previousHash: '',
      signature: 'unused-in-express-mode',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      scanInterval: 0, // avoid any rate-limit flakiness
      businessName: businessName,
      brandColor: brandColor,
      logoIndex: logoIndex,
      stampsRequired: snapshotStampsRequired,
    );
  }

  group('§4.1 - stampsRequired decrease applies to the in-progress card', () {
    test('a lower snapshot value updates the card immediately, no overflow', () async {
      await seedCard(dbName: 'test_snapshot_decrease_no_overflow.db', stampsRequired: 10, stampsCollected: 4);

      await scan(stampToken(snapshotStampsRequired: 6));

      final updated = await cardRepo.getCardById('card-snapshot-test');
      expect(updated!.stampsRequired, 6);
      expect(updated.stampsCollected, 5); // the one stamp this scan credited
      expect(updated.latestStampsRequiredSnapshot, 6);
      expect(updated.isRedeemed, isFalse);
    });

    test('a decrease that reaches the new target completes the card via the existing overflow machinery',
        () async {
      // 7/10, decrease to 5 - the scan's own +1 stamp makes it 8, past the
      // new target of 5 - should complete at exactly 5 and roll 3 stamps
      // onto a new card, the same as any ordinary over-collection.
      await seedCard(dbName: 'test_snapshot_decrease_overflow.db', stampsRequired: 10, stampsCollected: 7);

      await scan(stampToken(snapshotStampsRequired: 5));

      final oldCard = await cardRepo.getCardById('card-snapshot-test');
      expect(oldCard!.stampsRequired, 5);
      expect(oldCard.stampsCollected, 5);
      expect(oldCard.isComplete, isTrue);

      final allCards = await cardRepo.getCardsByBusiness(businessId);
      expect(allCards.length, 2);
      final newCard = allCards.firstWhere((c) => c.id != oldCard.id);
      expect(newCard.stampsCollected, 3); // 8 - 5 overflow
    });
  });

  group('§4.1 - stampsRequired increase never applies to the in-progress card', () {
    test('a higher snapshot value does NOT change the card, but is recorded for redemption', () async {
      await seedCard(dbName: 'test_snapshot_increase_withheld.db', stampsRequired: 6, stampsCollected: 3);

      await scan(stampToken(snapshotStampsRequired: 10));

      final updated = await cardRepo.getCardById('card-snapshot-test');
      // Never worsen the deal for a customer already collecting under it.
      expect(updated!.stampsRequired, 6);
      expect(updated.stampsCollected, 4);
      // But the higher value is known, for the *next* card at redemption.
      expect(updated.latestStampsRequiredSnapshot, 10);
    });

    test('an increase that completes the card via a stamp scan (not redemption) still applies to the next card',
        () async {
      // Real-world defect report: business at 3, card at 2/3. Business
      // raised to 5. Next scan (+1 = 3/3) correctly leaves the completing
      // card at its original 3 (never worsen an in-progress card), but the
      // auto-created next card was found to still require 3, not 5 - the
      // increase never took effect at all. Root cause: unlike
      // handleRedemptionToken (already fixed to read
      // latestStampsRequiredSnapshot), the ordinary "CARD COMPLETE -
      // AUTO-CREATING NEW CARD" continuation reached when a stamp SCAN
      // itself completes a card - not a separate redemption action -
      // still built the new card from card.stampsRequired directly. This
      // is actually the more common way a card completes in Express Mode,
      // since redemption is a distinct, later action.
      await seedCard(dbName: 'test_snapshot_increase_completes_card.db', stampsRequired: 3, stampsCollected: 2);

      await scan(stampToken(snapshotStampsRequired: 5));

      final oldCard = await cardRepo.getCardById('card-snapshot-test');
      expect(oldCard!.stampsRequired, 3, reason: 'the completing card itself must never be worsened');
      expect(oldCard.stampsCollected, 3);
      expect(oldCard.isComplete, isTrue);

      final allCards = await cardRepo.getCardsByBusiness(businessId);
      expect(allCards.length, 2, reason: 'completing the card at exact target must auto-create a fresh next card');
      final newCard = allCards.firstWhere((c) => c.id != oldCard.id);
      expect(newCard.stampsRequired, 5, reason: 'the next card is exactly where a pending increase should take effect');
      expect(newCard.stampsCollected, 0);
    });
  });

  group('§4.1 - name/icon/color are purely cosmetic, always take the freshest value', () {
    test('a scan with a fresh name/color/icon updates the card immediately regardless of direction',
        () async {
      await seedCard(
        dbName: 'test_snapshot_cosmetic_fields.db',
        stampsRequired: 6,
        stampsCollected: 1,
        businessName: 'Old Name',
        brandColor: '#111111',
        logoIndex: 1,
      );

      await scan(
        stampToken(
          businessName: 'New Name',
          brandColor: '#EEEEEE',
          logoIndex: 9,
        ),
      );

      final updated = await cardRepo.getCardById('card-snapshot-test');
      expect(updated!.businessName, 'New Name');
      expect(updated.brandColor, '#EEEEEE');
      expect(updated.logoIndex, 9);
    });
  });

  group('§4.1 - backward compatibility: no snapshot fields changes nothing', () {
    test('a token with all snapshot fields null leaves the card exactly as it was', () async {
      await seedCard(
        dbName: 'test_snapshot_backward_compat.db',
        stampsRequired: 6,
        stampsCollected: 1,
        businessName: 'Unchanged Name',
        brandColor: '#ABCDEF',
        logoIndex: 4,
      );

      await scan(stampToken()); // no snapshot fields set at all

      final updated = await cardRepo.getCardById('card-snapshot-test');
      expect(updated!.stampsRequired, 6);
      expect(updated.businessName, 'Unchanged Name');
      expect(updated.brandColor, '#ABCDEF');
      expect(updated.logoIndex, 4);
      expect(updated.latestStampsRequiredSnapshot, isNull);
      expect(updated.stampsCollected, 2);
    });
  });
}
