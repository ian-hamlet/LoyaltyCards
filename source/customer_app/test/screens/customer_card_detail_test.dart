import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:customer_app/screens/customer/customer_card_detail.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:customer_app/services/stamp_repository.dart';
import 'package:customer_app/services/transaction_repository.dart';

/// Characterization tests for CustomerCardDetail.
///
/// Written BEFORE the CustomerCardDetailController extraction, against the
/// then-unmodified screen, as the safety net that extraction had to keep
/// green - this screen had no test coverage of any kind, and the logic
/// being moved (redemption side effects, the redemption-QR size-fallback
/// ladder, the stamp-request QR payload) is exactly the kind that fails
/// silently. Mirrors the test-first discipline DEFECT_TRACKER.md records
/// for defect fixes, applied proactively to a refactor instead.
///
/// These drive the real screen through the widget tree deliberately: they
/// assert observable outcomes (which UI branch renders, what actually
/// landed in the database), never internal fields, so the same assertions
/// hold before and after the logic moved into the controller. The
/// controller-level tests that pin the QR payload shapes - which are not
/// observable through the widget, see the note in
/// customer_card_detail_controller_test.dart - live alongside them.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CardRepository cardRepo;
  late StampRepository stampRepo;
  late TransactionRepository transactionRepo;

  const businessId = 'business-card-detail-test';
  const cardId = 'card-detail-test';

  /// Fresh, isolated database per test. resetForTesting() swaps the
  /// DatabaseHelper singleton but leaves the sqflite file on disk, so a
  /// prior run's rows would otherwise leak in - delete it first, mirroring
  /// qr_scanner_screen_stamp_snapshot_test.dart / database_migration_test.dart.
  Future<void> resetDb(WidgetTester tester, String dbName) async {
    await tester.runAsync(() async {
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, dbName);
      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await DatabaseHelper.resetForTesting(testDatabaseName: dbName);
    });
    final dbHelper = DatabaseHelper();
    cardRepo = CardRepository(dbHelper);
    stampRepo = StampRepository(dbHelper);
    transactionRepo = TransactionRepository(dbHelper);
  }

  models.Card buildCard({
    String id = cardId,
    int stampsRequired = 6,
    int stampsCollected = 2,
    OperationMode mode = OperationMode.secure,
    bool isRedeemed = false,
    DateTime? redeemedAt,
    int? latestStampsRequiredSnapshot,
    String businessName = 'Test Cafe',
  }) {
    final now = DateTime.now();
    return models.Card(
      id: id,
      businessId: businessId,
      businessName: businessName,
      businessPublicKey: 'test-public-key',
      stampsRequired: stampsRequired,
      stampsCollected: stampsCollected,
      brandColor: '#3366CC',
      logoIndex: 2,
      mode: mode,
      createdAt: now,
      updatedAt: now,
      isRedeemed: isRedeemed,
      redeemedAt: redeemedAt,
      latestStampsRequiredSnapshot: latestStampsRequiredSnapshot,
      deviceId: 'seed-device',
    );
  }

  /// Insert [count] stamps for [card], timestamped an hour ago so they are
  /// never mistaken for card-creation stamps by the history section.
  Future<void> seedStamps(WidgetTester tester, models.Card card, int count) async {
    for (var i = 1; i <= count; i++) {
      await tester.runAsync(() => stampRepo.insertStamp(Stamp(
            id: '${card.id}_stamp_$i',
            cardId: card.id,
            stampNumber: i,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            // A realistic-length signature: payload size is what drives the
            // redemption-QR fallback ladder, so a short placeholder would
            // make the "fits as plain JSON" tests meaningless.
            signature: 'c2lnbmF0dXJlLWJ5dGVzLWZvci1zdGFtcC0kaS0${'A' * 60}$i',
            previousHash: i == 1 ? null : 'prev-hash-${i - 1}',
            deviceId: 'seed-device',
          )));
    }
  }

  Future<models.Card> seedCard(
    WidgetTester tester, {
    required String dbName,
    int stampsRequired = 6,
    int stampsCollected = 2,
    int? stampRowCount,
    OperationMode mode = OperationMode.secure,
    bool isRedeemed = false,
    DateTime? redeemedAt,
    int? latestStampsRequiredSnapshot,
  }) async {
    await resetDb(tester, dbName);
    final card = buildCard(
      stampsRequired: stampsRequired,
      stampsCollected: stampsCollected,
      mode: mode,
      isRedeemed: isRedeemed,
      redeemedAt: redeemedAt,
      latestStampsRequiredSnapshot: latestStampsRequiredSnapshot,
    );
    await tester.runAsync(() => cardRepo.insertCard(card));
    await seedStamps(tester, card, stampRowCount ?? stampsCollected);
    return card;
  }

  /// Mounts the screen and lets its real (non-fake-async) database I/O
  /// complete. initState -> _loadCardData does genuine sqflite work, which
  /// never resolves under flutter_test's fake async clock, so the mount has
  /// to happen inside runAsync before frames are pumped normally.
  Future<void> pumpDetail(WidgetTester tester, {String id = cardId}) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: CustomerCardDetail(cardId: id)));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  /// Taps a button and lets any database work it kicks off actually run.
  Future<void> tapAndRun(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  group('_loadCardData terminal states (via the branch each one renders)', () {
    testWidgets('an in-progress secure card renders the stamp-request QR and progress text', (tester) async {
      await seedCard(tester, dbName: 'test_detail_in_progress.db', stampsRequired: 6, stampsCollected: 2);

      await pumpDetail(tester);

      expect(find.text('Show this QR code to collect stamps'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('2 of 6 stamps'), findsOneWidget);
      expect(find.text('Card Redeemed!'), findsNothing);
      expect(find.text("This card's code is too large to display"), findsNothing);
    });

    testWidgets('a complete-but-unredeemed secure card renders the redemption QR', (tester) async {
      await seedCard(tester, dbName: 'test_detail_complete.db', stampsRequired: 4, stampsCollected: 4);

      await pumpDetail(tester);

      expect(find.text('Show this QR code to redeem your reward'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('COMPLETE'), findsOneWidget);
      expect(find.text("This card's code is too large to display"), findsNothing);
      // Complete cards collapse the stamp grid into the compact display.
      expect(find.text('4 of 4 stamps'), findsOneWidget);
    });

    testWidgets('an already-redeemed card renders the redeemed panel and no QR at all', (tester) async {
      final redeemedAt = DateTime(2026, 3, 4, 15, 7);
      await seedCard(
        tester,
        dbName: 'test_detail_redeemed.db',
        stampsRequired: 4,
        stampsCollected: 4,
        isRedeemed: true,
        redeemedAt: redeemedAt,
      );

      await pumpDetail(tester);

      expect(find.text('Card Redeemed!'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      expect(find.text('REDEEMED'), findsOneWidget);
      expect(find.text('15:07'), findsOneWidget);
      expect(find.text('4/3/2026'), findsOneWidget);
    });

    testWidgets('a missing card renders the not-found branch', (tester) async {
      await resetDb(tester, 'test_detail_missing.db');

      await pumpDetail(tester, id: 'no-such-card');

      expect(find.text('Card not found'), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('the loading branch renders before card data resolves', (tester) async {
      await seedCard(tester, dbName: 'test_detail_loading.db');

      // The first frame has to be sampled from inside runAsync: the screen's
      // load is genuine (non-fake-async) I/O, so futures started by a
      // pumpWidget outside runAsync would never advance at all and the screen
      // would sit on the loading branch forever.
      late final bool loadingBranchRendered;
      late final bool spinnerRendered;
      await tester.runAsync(() async {
        await tester.pumpWidget(const MaterialApp(home: CustomerCardDetail(cardId: cardId)));
        await tester.pump();
        loadingBranchRendered = find.text('Loading...').evaluate().isNotEmpty;
        spinnerRendered = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
        await Future<void>.delayed(const Duration(milliseconds: 400));
        await tester.pump();
      });
      await tester.pumpAndSettle();

      expect(loadingBranchRendered, isTrue);
      expect(spinnerRendered, isTrue);
      expect(find.text('Loading...'), findsNothing, reason: 'the load must actually terminate');
    });
  });

  group('redemption-QR fallback ladder', () {
    testWidgets('a modest complete card renders a QR (payload fits)', (tester) async {
      await seedCard(tester, dbName: 'test_detail_qr_fits.db', stampsRequired: 4, stampsCollected: 4);

      await pumpDetail(tester);

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text("This card's code is too large to display"), findsNothing);
    });

    testWidgets('a card whose stamp rows disagree with its count falls back to the too-large panel',
        (tester) async {
      // QRTokenGenerator.generateRedemptionRequest rejects inconsistent
      // card/stamp data (stampsCollected != stamps.length) by throwing, and
      // _buildRedemptionQrCode's catch turns any such failure into a null
      // QrCode - the same terminal state as a payload that genuinely
      // exceeds QR capacity, and far more constructible than the latter.
      await seedCard(
        tester,
        dbName: 'test_detail_qr_inconsistent.db',
        stampsRequired: 5,
        stampsCollected: 5,
        stampRowCount: 3,
      );

      await pumpDetail(tester);

      expect(find.text("This card's code is too large to display"), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
      // The stamp history below still proves what was earned (TEST-017).
      expect(find.text('Stamp History'), findsOneWidget);
    });
  });

  group('UI-branch smoke coverage for Express (simple) mode', () {
    testWidgets('an in-progress express card shows the scan button and never a QR', (tester) async {
      await seedCard(
        tester,
        dbName: 'test_detail_simple_in_progress.db',
        stampsRequired: 6,
        stampsCollected: 2,
        mode: OperationMode.simple,
      );

      await pumpDetail(tester);

      expect(find.text('Express Mode'), findsOneWidget);
      expect(find.text('Scan to Add Stamp'), findsOneWidget);
      expect(find.text('Redeem Reward'), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('a complete express card shows the Redeem Reward button', (tester) async {
      await seedCard(
        tester,
        dbName: 'test_detail_simple_complete.db',
        stampsRequired: 4,
        stampsCollected: 4,
        mode: OperationMode.simple,
      );

      await pumpDetail(tester);

      expect(find.text('Redeem Reward'), findsOneWidget);
      expect(find.text('Scan to Add Stamp'), findsNothing);
      expect(find.byType(QrImageView), findsNothing);
    });
  });

  group('_processRedemption side effects', () {
    /// Drives the real Redeem Reward -> confirm dialog -> _processRedemption
    /// path end to end.
    Future<void> redeem(WidgetTester tester) async {
      await tapAndRun(tester, find.text('Redeem Reward'));
      expect(find.text('Redeem Reward?'), findsOneWidget);
      await tapAndRun(tester, find.text('Yes, Redeem'));
    }

    testWidgets('marks the card redeemed and logs a redemption transaction', (tester) async {
      await seedCard(
        tester,
        dbName: 'test_detail_redeem_marks.db',
        stampsRequired: 4,
        stampsCollected: 4,
        mode: OperationMode.simple,
      );

      await pumpDetail(tester);
      await redeem(tester);

      final updated = await tester.runAsync(() => cardRepo.getCardById(cardId));
      expect(updated!.isRedeemed, isTrue);
      expect(updated.redeemedAt, isNotNull);
      // The stamp count is untouched by redemption.
      expect(updated.stampsCollected, 4);

      final transactions = await tester.runAsync(() => transactionRepo.getTransactionsByCard(cardId));
      final redemptions =
          transactions!.where((t) => t.type == TransactionType.redemption).toList();
      expect(redemptions.length, 1);
      expect(redemptions.first.businessName, 'Test Cafe');
      expect(redemptions.first.details, 'Reward redeemed: 4 stamps');
    });

    testWidgets('creates a new card when no existing card has space, and says so in the dialog',
        (tester) async {
      await seedCard(
        tester,
        dbName: 'test_detail_redeem_new_card.db',
        stampsRequired: 4,
        stampsCollected: 4,
        mode: OperationMode.simple,
      );

      await pumpDetail(tester);
      await redeem(tester);

      final allCards = await tester.runAsync(() => cardRepo.getCardsByBusiness(businessId));
      expect(allCards!.length, 2, reason: 'a genuinely new card should have been inserted');
      final newCard = allCards.firstWhere((c) => c.id != cardId);
      expect(newCard.stampsCollected, 0);
      expect(newCard.stampsRequired, 4);
      expect(newCard.isRedeemed, isFalse);
      expect(newCard.mode, OperationMode.simple);

      // Q-004: the dialog may only claim a new card when one was made.
      expect(find.text('Reward Redeemed!'), findsOneWidget);
      expect(find.text('A new card has been added to your wallet automatically'), findsOneWidget);
    });

    testWidgets('reuses an existing under-filled card instead of creating one, and does NOT claim otherwise',
        (tester) async {
      // Q-004 regression guard: the success dialog used to claim "a new card
      // has been added" unconditionally, including on this exact path where
      // an existing under-filled card was silently reused instead.
      await seedCard(
        tester,
        dbName: 'test_detail_redeem_reuses.db',
        stampsRequired: 4,
        stampsCollected: 4,
        mode: OperationMode.simple,
      );
      final spare = buildCard(
        id: 'card-detail-test-spare',
        stampsRequired: 4,
        stampsCollected: 1,
        mode: OperationMode.simple,
      );
      await tester.runAsync(() => cardRepo.insertCard(spare));

      await pumpDetail(tester);
      await redeem(tester);

      final allCards = await tester.runAsync(() => cardRepo.getCardsByBusiness(businessId));
      expect(allCards!.length, 2, reason: 'the existing spare card should have been reused, not added to');
      expect(
        allCards.map((c) => c.id).toSet(),
        {cardId, 'card-detail-test-spare'},
      );

      expect(find.text('Reward Redeemed!'), findsOneWidget);
      expect(find.text('A new card has been added to your wallet automatically'), findsNothing);
    });

    testWidgets('the new card takes stampsRequired from latestStampsRequiredSnapshot when one exists',
        (tester) async {
      // §4.1: a stampsRequired increase never applies retroactively to the
      // card being redeemed, but the next card is exactly where it lands.
      await seedCard(
        tester,
        dbName: 'test_detail_redeem_snapshot.db',
        stampsRequired: 4,
        stampsCollected: 4,
        mode: OperationMode.simple,
        latestStampsRequiredSnapshot: 9,
      );

      await pumpDetail(tester);
      await redeem(tester);

      final allCards = await tester.runAsync(() => cardRepo.getCardsByBusiness(businessId));
      final newCard = allCards!.firstWhere((c) => c.id != cardId);
      expect(newCard.stampsRequired, 9, reason: 'the snapshot, not the redeemed card\'s own value');

      final redeemed = await tester.runAsync(() => cardRepo.getCardById(cardId));
      expect(redeemed!.stampsRequired, 4, reason: 'the redeemed card itself is never rewritten');
    });

    testWidgets('the screen reloads into the redeemed branch after redemption', (tester) async {
      await seedCard(
        tester,
        dbName: 'test_detail_redeem_reloads.db',
        stampsRequired: 4,
        stampsCollected: 4,
        mode: OperationMode.simple,
      );

      await pumpDetail(tester);
      await redeem(tester);

      // Dismiss the success dialog and confirm the screen behind it moved to
      // the redeemed branch (i.e. _loadCardData really re-ran).
      await tapAndRun(tester, find.text('Done'));
      expect(find.text('Card Redeemed!'), findsOneWidget);
      expect(find.text('Redeem Reward'), findsNothing);
    });
  });
}
