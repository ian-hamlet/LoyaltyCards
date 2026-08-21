import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/screens/supplier/supplier_settings.dart';
import 'package:supplier_app/services/business_repository.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// Covers making the Express Mode scan cooldown editable from Settings
/// (source/supplier_app/lib/widgets/scan_interval_editor.dart), following
/// the same self-service pattern already tested for stampsRequired
/// (DECISION-017, see supplier_issue_card_test.dart). Unlike stampsRequired,
/// scanInterval is never baked into an issued card - it's read live off the
/// Business record at generation time - so this test just needs to confirm
/// the value persists and the tile reflects it immediately, not anything
/// about existing cards.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late BusinessRepository businessRepo;

  // resetForTesting only closes the connection - it doesn't delete the
  // on-disk file (see supplier_database_helper.dart) - and getBusiness()
  // has no ID filter (single-business model), so every test needs its own
  // database name to get a genuinely empty database. Same pattern as
  // supplier_issue_card_test.dart.
  Future<Business> seedBusiness(
    WidgetTester tester, {
    required String dbName,
    required OperationMode mode,
    int scanInterval = 30000,
  }) async {
    await tester.runAsync(() => SupplierDatabaseHelper.resetForTesting(testDatabaseName: dbName));
    businessRepo = BusinessRepository();

    final business = Business(
      id: 'business-settings-scan-interval-test',
      name: 'Test Coffee Shop',
      publicKey: 'unused-plaintext-field',
      privateKey: 'unused-plaintext-field',
      stampsRequired: 6,
      brandColor: '#673AB7',
      mode: mode,
      createdAt: DateTime.now(),
      scanInterval: scanInterval,
    );
    await tester.runAsync(() => businessRepo.insertBusiness(business));
    return business;
  }

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    SharedPreferences.setMockInitialValues({});
  });

  group('SupplierSettings - editable scan cooldown', () {
    testWidgets('Express Mode business shows the cooldown row, tappable, with the current value', (tester) async {
      final business = await seedBusiness(
        tester,
        dbName: 'test_scan_interval_display.db',
        mode: OperationMode.simple,
        scanInterval: 30000,
      );

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      expect(find.text('Scan Cooldown'), findsOneWidget);
      expect(find.text('30 seconds between accepted scans, tap to change'), findsOneWidget);
    });

    testWidgets('Secure Mode business shows no cooldown row at all', (tester) async {
      final business = await seedBusiness(
        tester,
        dbName: 'test_scan_interval_secure_hidden.db',
        mode: OperationMode.secure,
      );

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      expect(find.text('Scan Cooldown'), findsNothing);
    });

    testWidgets('tapping the cooldown row opens an editor defaulting to the current value', (tester) async {
      final business = await seedBusiness(
        tester,
        dbName: 'test_scan_interval_open_dialog.db',
        mode: OperationMode.simple,
        scanInterval: 45000,
      );

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan Cooldown'));
      await tester.pumpAndSettle();

      expect(find.text('45 seconds'), findsOneWidget);
    });

    testWidgets('increasing and saving persists the new value and updates the tile immediately', (tester) async {
      final business = await seedBusiness(
        tester,
        dbName: 'test_scan_interval_save.db',
        mode: OperationMode.simple,
        scanInterval: 30000,
      );

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan Cooldown'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_circle));
      await tester.pumpAndSettle();
      expect(find.text('35 seconds'), findsOneWidget);

      // Save writes to the real sqflite FFI database - pumpAndSettle()
      // alone doesn't let that real I/O complete under flutter_test, same
      // as the DECISION-017 Save flow in supplier_issue_card_test.dart.
      await tester.tap(find.text('Save'));
      await tester.pump();
      for (var attempt = 0; attempt < 50; attempt++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        if (find.text('35 seconds between accepted scans, tap to change').evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();

      // Tile reflects the change without needing the screen reloaded.
      expect(find.text('35 seconds between accepted scans, tap to change'), findsOneWidget);

      // And it actually persisted to the database, not just local state.
      final updated = await tester.runAsync(() => businessRepo.getBusiness());
      expect(updated!.scanInterval, 35000);
    });

    testWidgets('Cancel leaves the stored value unchanged', (tester) async {
      final business = await seedBusiness(
        tester,
        dbName: 'test_scan_interval_cancel.db',
        mode: OperationMode.simple,
        scanInterval: 30000,
      );

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan Cooldown'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add_circle));
      await tester.pumpAndSettle();
      expect(find.text('35 seconds'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('30 seconds between accepted scans, tap to change'), findsOneWidget);
      final unchanged = await tester.runAsync(() => businessRepo.getBusiness());
      expect(unchanged!.scanInterval, 30000);
    });

    testWidgets('stepper disables at the configured bounds', (tester) async {
      final business = await seedBusiness(
        tester,
        dbName: 'test_scan_interval_bounds.db',
        mode: OperationMode.simple,
        scanInterval: AppConstants.simpleModeMaxScanIntervalMs,
      );

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Scan Cooldown'));
      await tester.pumpAndSettle();

      final incrementButton = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add_circle));
      expect(incrementButton.onPressed, isNull, reason: 'already at the max, increment should be disabled');
    });
  });
}
