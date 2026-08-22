import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path/path.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:customer_app/screens/customer/qr_scanner_screen.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:customer_app/services/stamp_repository.dart';

/// Fake MobileScannerPlatform so QRScannerScreen can mount under
/// `flutter_test` without a real platform channel - the genuine channel's
/// `start()` call never resolves (and never throws) in this environment,
/// which otherwise hangs pumpAndSettle() forever. Mirrors the identical
/// fixture in supplier_app's supplier_redeem_card_test.dart, which itself
/// mirrors mobile_scanner's own widget test fixture
/// (mobile_scanner-*/test/mobile_scanner_widget/detect_barcode_test.dart).
class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    return Future.value(const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(200, 200),
      numberOfCameras: 1,
    ));
  }

  @override
  Widget buildCameraView() => const SizedBox.square(dimension: 100);

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

/// Covers the directional business-profile-snapshot policy applied on an
/// ordinary stamp scan (Requirements/DISCUSSION_Business_Field_Editing.md
/// §4.1): a stampsRequired decrease applies immediately to the in-progress
/// card; an increase never does (only recorded for the next card, at
/// redemption); name/icon/color always take the freshest value. Uses
/// Express Mode throughout - no crypto signature verification needed for
/// this logic, which runs identically before the mode-specific validation
/// branch.
///
/// Drives the real _handleStampToken code path via
/// QRScannerScreen.handleQRCodeForTesting (mirrors
/// SupplierRedeemCard.processCardQRForTesting), since there's no camera
/// hardware under flutter_test to feed it a scanned QR string.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  MobileScannerPlatform.instance = _FakeMobileScannerPlatform();

  late CardRepository cardRepo;
  late StampRepository stampRepo;
  const businessId = 'business-snapshot-test';

  Future<models.Card> seedCard(
    WidgetTester tester, {
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
    await tester.runAsync(() async {
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, dbName);
      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }
    });
    await tester.runAsync(() => DatabaseHelper.resetForTesting(testDatabaseName: dbName));
    final dbHelper = DatabaseHelper();
    cardRepo = CardRepository(dbHelper);
    stampRepo = StampRepository(dbHelper);

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
    await tester.runAsync(() => cardRepo.insertCard(card));

    // Pre-existing stamps, timestamped well outside any cooldown window, so
    // the test's one real scan below never gets rate-limited.
    for (var i = 1; i <= stampsCollected; i++) {
      await tester.runAsync(() => stampRepo.insertStamp(Stamp(
            id: 'card-snapshot-test_stamp_$i',
            cardId: card.id,
            stampNumber: i,
            timestamp: now.subtract(const Duration(hours: 1)),
            signature: 'seed-signature-$i',
          )));
    }

    return card;
  }

  /// Drives one scan through the real _handleStampToken path.
  Future<void> scan(WidgetTester tester, StampToken token) async {
    await tester.pumpWidget(const MaterialApp(home: QRScannerScreen(mode: QRScanMode.receiveStamp)));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(QRScannerScreen));
    // ignore: avoid_dynamic_calls
    await tester.runAsync(() => (state as dynamic).handleQRCodeForTesting(token.toQRString()) as Future<void>);
    await tester.pumpAndSettle();
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
    testWidgets('a lower snapshot value updates the card immediately, no overflow', (tester) async {
      await seedCard(tester, dbName: 'test_snapshot_decrease_no_overflow.db', stampsRequired: 10, stampsCollected: 4);

      await scan(tester, stampToken(snapshotStampsRequired: 6));

      final updated = await tester.runAsync(() => cardRepo.getCardById('card-snapshot-test'));
      expect(updated!.stampsRequired, 6);
      expect(updated.stampsCollected, 5); // the one stamp this scan credited
      expect(updated.latestStampsRequiredSnapshot, 6);
      expect(updated.isRedeemed, isFalse);
    });

    testWidgets('a decrease that reaches the new target completes the card via the existing overflow machinery',
        (tester) async {
      // 7/10, decrease to 5 - the scan's own +1 stamp makes it 8, past the
      // new target of 5 - should complete at exactly 5 and roll 3 stamps
      // onto a new card, the same as any ordinary over-collection.
      await seedCard(tester, dbName: 'test_snapshot_decrease_overflow.db', stampsRequired: 10, stampsCollected: 7);

      await scan(tester, stampToken(snapshotStampsRequired: 5));

      final oldCard = await tester.runAsync(() => cardRepo.getCardById('card-snapshot-test'));
      expect(oldCard!.stampsRequired, 5);
      expect(oldCard.stampsCollected, 5);
      expect(oldCard.isComplete, isTrue);

      final allCards = await tester.runAsync(() => cardRepo.getCardsByBusiness(businessId));
      expect(allCards!.length, 2);
      final newCard = allCards.firstWhere((c) => c.id != oldCard.id);
      expect(newCard.stampsCollected, 3); // 8 - 5 overflow
    });
  });

  group('§4.1 - stampsRequired increase never applies to the in-progress card', () {
    testWidgets('a higher snapshot value does NOT change the card, but is recorded for redemption', (tester) async {
      await seedCard(tester, dbName: 'test_snapshot_increase_withheld.db', stampsRequired: 6, stampsCollected: 3);

      await scan(tester, stampToken(snapshotStampsRequired: 10));

      final updated = await tester.runAsync(() => cardRepo.getCardById('card-snapshot-test'));
      // Never worsen the deal for a customer already collecting under it.
      expect(updated!.stampsRequired, 6);
      expect(updated.stampsCollected, 4);
      // But the higher value is known, for the *next* card at redemption.
      expect(updated.latestStampsRequiredSnapshot, 10);
    });

    testWidgets('an increase that completes the card via a stamp scan (not redemption) still applies to the next card',
        (tester) async {
      // Real-world defect report: business at 3, card at 2/3. Business
      // raised to 5. Next scan (+1 = 3/3) correctly leaves the completing
      // card at its original 3 (never worsen an in-progress card), but the
      // auto-created next card was found to still require 3, not 5 - the
      // increase never took effect at all. Root cause: unlike
      // _handleRedemptionToken (already fixed to read
      // latestStampsRequiredSnapshot), the ordinary "CARD COMPLETE -
      // AUTO-CREATING NEW CARD" continuation reached when a stamp SCAN
      // itself completes a card - not a separate redemption action -
      // still built the new card from card.stampsRequired directly. This
      // is actually the more common way a card completes in Express Mode,
      // since redemption is a distinct, later action.
      await seedCard(tester, dbName: 'test_snapshot_increase_completes_card.db', stampsRequired: 3, stampsCollected: 2);

      await scan(tester, stampToken(snapshotStampsRequired: 5));

      final oldCard = await tester.runAsync(() => cardRepo.getCardById('card-snapshot-test'));
      expect(oldCard!.stampsRequired, 3, reason: 'the completing card itself must never be worsened');
      expect(oldCard.stampsCollected, 3);
      expect(oldCard.isComplete, isTrue);

      final allCards = await tester.runAsync(() => cardRepo.getCardsByBusiness(businessId));
      expect(allCards!.length, 2, reason: 'completing the card at exact target must auto-create a fresh next card');
      final newCard = allCards.firstWhere((c) => c.id != oldCard.id);
      expect(newCard.stampsRequired, 5, reason: 'the next card is exactly where a pending increase should take effect');
      expect(newCard.stampsCollected, 0);
    });
  });

  group('§4.1 - name/icon/color are purely cosmetic, always take the freshest value', () {
    testWidgets('a scan with a fresh name/color/icon updates the card immediately regardless of direction',
        (tester) async {
      await seedCard(
        tester,
        dbName: 'test_snapshot_cosmetic_fields.db',
        stampsRequired: 6,
        stampsCollected: 1,
        businessName: 'Old Name',
        brandColor: '#111111',
        logoIndex: 1,
      );

      await scan(
        tester,
        stampToken(
          businessName: 'New Name',
          brandColor: '#EEEEEE',
          logoIndex: 9,
        ),
      );

      final updated = await tester.runAsync(() => cardRepo.getCardById('card-snapshot-test'));
      expect(updated!.businessName, 'New Name');
      expect(updated.brandColor, '#EEEEEE');
      expect(updated.logoIndex, 9);
    });
  });

  group('§4.1 - backward compatibility: no snapshot fields changes nothing', () {
    testWidgets('a token with all snapshot fields null leaves the card exactly as it was', (tester) async {
      await seedCard(
        tester,
        dbName: 'test_snapshot_backward_compat.db',
        stampsRequired: 6,
        stampsCollected: 1,
        businessName: 'Unchanged Name',
        brandColor: '#ABCDEF',
        logoIndex: 4,
      );

      await scan(tester, stampToken()); // no snapshot fields set at all

      final updated = await tester.runAsync(() => cardRepo.getCardById('card-snapshot-test'));
      expect(updated!.stampsRequired, 6);
      expect(updated.businessName, 'Unchanged Name');
      expect(updated.brandColor, '#ABCDEF');
      expect(updated.logoIndex, 4);
      expect(updated.latestStampsRequiredSnapshot, isNull);
      expect(updated.stampsCollected, 2);
    });
  });
}
