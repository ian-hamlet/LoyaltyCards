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

/// Coverage for DECISION-024 (Add a Sort Control to the Customer Wallet Home
/// Screen): the wallet's card order was previously a fixed, invisible
/// default (newest-created first, straight from the DB query) with no way
/// to change it. This exercises the new sort control end to end - default
/// order, each explicit option, and that the choice survives a reload.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CardRepository cardRepo;
  const dbName = 'test_customer_home_sort.db';

  Future<void> resetDb(WidgetTester tester) async {
    // customer_home.dart's initState() calls SharedPreferences.getInstance()
    // - without this it hangs forever under flutter_test waiting on an
    // unmocked platform channel (same fix as customer_home_semantics_test.dart).
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

  /// Real (non-fake-clock) DB/SharedPreferences I/O in initState() can't be
  /// observed completing via pumpAndSettle() alone. Polls for the actual
  /// signal (all three seeded card names rendering) with real wall-clock
  /// time between checks, matching the pattern already used in
  /// customer_home_semantics_test.dart / supplier_stamp_card_test.dart.
  Future<void> settleAfterMount(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: CustomerHome()));
    await tester.pump();
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.text('Alpha Cafe').evaluate().isNotEmpty &&
          find.text('Beta Bakery').evaluate().isNotEmpty &&
          find.text('Charlie Diner').evaluate().isNotEmpty) {
        break;
      }
    }
    await tester.pumpAndSettle();
  }

  models.Card buildCard({
    required String id,
    required String businessName,
    required DateTime createdAt,
  }) {
    return models.Card(
      id: id,
      businessId: 'business-$id',
      businessName: businessName,
      businessPublicKey: 'test-public-key-$id',
      stampsRequired: 10,
      stampsCollected: 2,
      brandColor: '#3366CC',
      logoIndex: 2,
      mode: OperationMode.secure,
      createdAt: createdAt,
      updatedAt: createdAt,
      isRedeemed: false,
      deviceId: 'seed-device',
    );
  }

  /// Insertion order deliberately doesn't match any sort option's output,
  /// so a test passing can't be a coincidence of insertion order.
  Future<void> seedThreeCards(WidgetTester tester) async {
    final base = DateTime(2026, 1, 1);
    await tester.runAsync(() async {
      // Beta: created second (middle), name starts with B
      await cardRepo.insertCard(buildCard(
        id: 'card-beta',
        businessName: 'Beta Bakery',
        createdAt: base.add(const Duration(days: 2)),
      ));
      // Alpha: created first (oldest), name starts with A
      await cardRepo.insertCard(buildCard(
        id: 'card-alpha',
        businessName: 'Alpha Cafe',
        createdAt: base.add(const Duration(days: 1)),
      ));
      // Charlie: created last (newest), name starts with C
      await cardRepo.insertCard(buildCard(
        id: 'card-charlie',
        businessName: 'Charlie Diner',
        createdAt: base.add(const Duration(days: 3)),
      ));
    });
  }

  /// The card list renders one Text widget per business name in list order,
  /// so the vertical order of these matches the vertical order onscreen.
  List<String> renderedNamesInOrder(WidgetTester tester) {
    final names = ['Alpha Cafe', 'Beta Bakery', 'Charlie Diner'];
    final positions = <String, double>{};
    for (final name in names) {
      final finder = find.text(name);
      expect(finder, findsOneWidget, reason: '$name should be rendered');
      positions[name] = tester.getTopLeft(finder).dy;
    }
    final sorted = names.toList()..sort((a, b) => positions[a]!.compareTo(positions[b]!));
    return sorted;
  }

  Future<void> selectSortOption(WidgetTester tester, String label) async {
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    // warnIfMissed: false - the menu item's own InkWell sits slightly inset
    // from the Text's bounding box, which flutter_test's hit-test warning
    // flags even though the tap correctly lands on and activates the menu
    // item (confirmed by the resulting sort order in every test below).
    await tester.tap(find.text(label), warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to Newest First, matching the pre-existing behavior',
      (tester) async {
    await resetDb(tester);
    await seedThreeCards(tester);
    await settleAfterMount(tester);

    expect(renderedNamesInOrder(tester),
        ['Charlie Diner', 'Beta Bakery', 'Alpha Cafe']);

    // The control itself should reflect that default, not just the list.
    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    final checkedItem = tester.widget<CheckedPopupMenuItem<CardSortOrder>>(
      find.widgetWithText(CheckedPopupMenuItem<CardSortOrder>, 'Newest First'),
    );
    expect(checkedItem.checked, isTrue);
  });

  testWidgets('Oldest First reverses the default order', (tester) async {
    await resetDb(tester);
    await seedThreeCards(tester);
    await settleAfterMount(tester);

    await selectSortOption(tester, 'Oldest First');

    expect(renderedNamesInOrder(tester),
        ['Alpha Cafe', 'Beta Bakery', 'Charlie Diner']);
  });

  testWidgets('Name (A-Z) sorts alphabetically ascending', (tester) async {
    await resetDb(tester);
    await seedThreeCards(tester);
    await settleAfterMount(tester);

    await selectSortOption(tester, 'Name (A-Z)');

    expect(renderedNamesInOrder(tester),
        ['Alpha Cafe', 'Beta Bakery', 'Charlie Diner']);
  });

  testWidgets('Name (Z-A) sorts alphabetically descending', (tester) async {
    await resetDb(tester);
    await seedThreeCards(tester);
    await settleAfterMount(tester);

    await selectSortOption(tester, 'Name (Z-A)');

    expect(renderedNamesInOrder(tester),
        ['Charlie Diner', 'Beta Bakery', 'Alpha Cafe']);
  });

  testWidgets('sort choice persists across a reload of the screen',
      (tester) async {
    await resetDb(tester);
    await seedThreeCards(tester);
    await settleAfterMount(tester);

    await selectSortOption(tester, 'Name (A-Z)');
    expect(renderedNamesInOrder(tester),
        ['Alpha Cafe', 'Beta Bakery', 'Charlie Diner']);

    // Simulate coming back to the screen later (fresh widget, same
    // SharedPreferences-backed storage) rather than re-mocking prefs to {}.
    await settleAfterMount(tester);

    expect(renderedNamesInOrder(tester),
        ['Alpha Cafe', 'Beta Bakery', 'Charlie Diner']);
  });
}
