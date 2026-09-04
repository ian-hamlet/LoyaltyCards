import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:customer_app/screens/customer/customer_home.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';

/// Regression coverage for the accessibility fix to _LoyaltyCardWidget
/// (private, in customer_home.dart - not directly importable, so this drives
/// the real CustomerHome screen instead): the card's visual body (business
/// name, mode icon, status text, and one unlabeled _StampCircle per stamp)
/// is wrapped in ExcludeSemantics and replaced with a single combined
/// Semantics label, so VoiceOver/TalkBack reads one useful sentence per card
/// instead of stopping on stampsRequired individual unlabeled circles.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CardRepository cardRepo;
  const dbName = 'test_customer_home_semantics.db';

  Future<void> resetDb(WidgetTester tester) async {
    // customer_home.dart's _loadFilterPreference() calls
    // SharedPreferences.getInstance() in initState() - without this it
    // hangs forever under flutter_test waiting on an unmocked platform
    // channel (same fix as supplier_stamp_card_test.dart).
    SharedPreferences.setMockInitialValues({});
    await tester.runAsync(() async {
      final databasesPath = await getDatabasesPath();
      final dbPath = join(databasesPath, dbName);
      if (await File(dbPath).exists()) {
        await File(dbPath).delete();
      }
      await DatabaseHelper.resetForTesting(testDatabaseName: dbName);
    });
    cardRepo = CardRepository(DatabaseHelper());
  }

  /// initState() -> _loadCards()/_loadFilterPreference() do real
  /// (non-fake-clock) DB/SharedPreferences I/O that pumpAndSettle() alone
  /// can't observe completing. Polls for the actual signal (the seeded
  /// card's name rendering) with real wall-clock time between checks,
  /// rather than one fixed delay - a fixed delay is exactly the kind of
  /// flakiness this codebase has hit before under full-suite concurrent
  /// I/O load (see settleAfterMount in supplier_stamp_card_test.dart /
  /// supplier_issue_card_test.dart, same pattern).
  Future<void> settleAfterMount(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CustomerHome()));
    await tester.pump();
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.text('Test Cafe').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  models.Card buildCard({
    OperationMode mode = OperationMode.secure,
    int stampsRequired = 10,
    int stampsCollected = 4,
  }) {
    final now = DateTime.now();
    return models.Card(
      id: 'card-semantics-test',
      businessId: 'business-semantics-test',
      businessName: 'Test Cafe',
      businessPublicKey: 'test-public-key',
      stampsRequired: stampsRequired,
      stampsCollected: stampsCollected,
      brandColor: '#3366CC',
      logoIndex: 2,
      mode: mode,
      createdAt: now,
      updatedAt: now,
      isRedeemed: false,
      deviceId: 'seed-device',
    );
  }

  testWidgets('card exposes one combined semantic label instead of separate stamp circles',
      (tester) async {
    final handle = tester.ensureSemantics();
    await resetDb(tester);
    await tester.runAsync(
      () => cardRepo.insertCard(buildCard(mode: OperationMode.secure, stampsRequired: 10, stampsCollected: 4)),
    );

    await settleAfterMount(tester);

    // The combined label says everything a sighted user sees in one place.
    expect(
      find.bySemanticsLabel('Test Cafe, Secure Mode, 6 more to go, 4 of 10 stamps collected'),
      findsOneWidget,
    );

    // The bare business name is no longer its own standalone semantics
    // node - it's folded into the combined label above via ExcludeSemantics,
    // not merely duplicated alongside it. If this starts failing because the
    // name legitimately needs its own node again, that's fine - just make
    // sure the combined label above still exists too.
    expect(find.bySemanticsLabel('Test Cafe'), findsNothing);

    handle.dispose();
  });

  testWidgets('combined label reflects Express Mode and a complete card', (tester) async {
    final handle = tester.ensureSemantics();
    await resetDb(tester);
    await tester.runAsync(
      () => cardRepo.insertCard(buildCard(mode: OperationMode.simple, stampsRequired: 5, stampsCollected: 5)),
    );

    await settleAfterMount(tester);

    expect(
      find.bySemanticsLabel('Test Cafe, Express Mode, Ready to redeem your reward, 5 of 5 stamps collected'),
      findsOneWidget,
    );

    handle.dispose();
  });
}
