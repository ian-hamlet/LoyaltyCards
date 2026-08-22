import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/models/audit_entry.dart';
import 'package:supplier_app/screens/supplier/supplier_settings.dart';
import 'package:supplier_app/services/audit_trail_repository.dart';
import 'package:supplier_app/services/business_repository.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// Covers the Name/Icon/Brand Color editors added to Settings
/// (Requirements/DISCUSSION_Business_Field_Editing.md §1/§2), and that
/// Stamps Required is now generally editable (not just the DECISION-017
/// "Fix Now" out-of-range case). Each save is also expected to log an
/// audit trail entry (§7).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late BusinessRepository businessRepo;

  Future<Business> seedBusiness(WidgetTester tester, {required String dbName}) async {
    await tester.runAsync(() => SupplierDatabaseHelper.resetForTesting(testDatabaseName: dbName));
    businessRepo = BusinessRepository();

    final business = Business(
      id: 'business-settings-profile-editors-test',
      name: 'Original Name',
      publicKey: 'unused-plaintext-field',
      privateKey: 'unused-plaintext-field',
      stampsRequired: 6,
      brandColor: BrandColors.cardColorOptions.first,
      logoIndex: 0,
      mode: OperationMode.simple,
      createdAt: DateTime.now(),
    );
    await tester.runAsync(() => businessRepo.insertBusiness(business));
    return business;
  }

  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    SharedPreferences.setMockInitialValues({});
  });

  /// Save writes to the real sqflite FFI database - pumpAndSettle() alone
  /// doesn't let that real I/O complete under flutter_test (same pattern
  /// established in supplier_settings_scan_interval_test.dart).
  Future<void> pumpUntil(WidgetTester tester, bool Function() condition) async {
    await tester.pump();
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (condition()) break;
    }
    await tester.pumpAndSettle();
  }

  group('SupplierSettings - Business Name editor', () {
    testWidgets('editing and saving persists the new name and logs it to the audit trail', (tester) async {
      final business = await seedBusiness(tester, dbName: 'test_settings_name_save.db');

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      expect(find.text('Original Name'), findsOneWidget);

      await tester.tap(find.text('Original Name'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Renamed Coffee Shop');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await pumpUntil(tester, () => find.text('Renamed Coffee Shop').evaluate().isNotEmpty);

      expect(find.text('Renamed Coffee Shop'), findsOneWidget);

      final updated = await tester.runAsync(() => businessRepo.getBusiness());
      expect(updated!.name, 'Renamed Coffee Shop');

      final auditEntries = await tester.runAsync(() => AuditTrailRepository().getEntries(business.id));
      expect(
        auditEntries!.any((e) => e.propertyName == AuditProperty.businessName && e.newValue == 'Renamed Coffee Shop'),
        isTrue,
      );
    });

    testWidgets('empty name disables Save', (tester) async {
      final business = await seedBusiness(tester, dbName: 'test_settings_name_empty.db');

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Original Name'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      final saveButton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'));
      expect(saveButton.onPressed, isNull);
    });
  });

  group('SupplierSettings - Icon editor', () {
    testWidgets('shows an Icon row and opens a picker covering the full palette', (tester) async {
      final business = await seedBusiness(tester, dbName: 'test_settings_icon_open.db');

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      expect(find.text('Icon'), findsOneWidget);
      expect(find.text(BusinessIcons.getIconName(0)), findsOneWidget);

      await tester.tap(find.text('Icon'));
      await tester.pumpAndSettle();

      expect(find.text('Business Icon'), findsOneWidget);
      // The full palette is offered, not onboarding's curated subset - the
      // grid is lazily built (GridView.builder), so a late index may not
      // actually be on-screen without scrolling; check itemCount directly
      // instead of searching for a specific off-screen icon.
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect((grid.childrenDelegate as SliverChildBuilderDelegate).estimatedChildCount, BusinessIcons.icons.length);
    });

    testWidgets('selecting a new icon and saving persists it and logs it', (tester) async {
      final business = await seedBusiness(tester, dbName: 'test_settings_icon_save.db');

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Icon'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(BusinessIcons.getIcon(3)));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await pumpUntil(tester, () => find.text(BusinessIcons.getIconName(3)).evaluate().isNotEmpty);

      final updated = await tester.runAsync(() => businessRepo.getBusiness());
      expect(updated!.logoIndex, 3);

      final auditEntries = await tester.runAsync(() => AuditTrailRepository().getEntries(business.id));
      expect(
        auditEntries!.any((e) => e.propertyName == AuditProperty.icon && e.newValue == BusinessIcons.getIconName(3)),
        isTrue,
      );
    });
  });

  group('SupplierSettings - Brand Color editor', () {
    testWidgets('selecting a new color and saving persists it and logs it', (tester) async {
      final business = await seedBusiness(tester, dbName: 'test_settings_color_save.db');
      final newColor = BrandColors.cardColorOptions[1];

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Brand Color'));
      await tester.pumpAndSettle();

      final colorName = BrandColors.cardColorNames[newColor] ?? newColor;
      await tester.tap(find.bySemanticsLabel(colorName));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await pumpUntil(tester, () => find.text(newColor).evaluate().isNotEmpty);

      final updated = await tester.runAsync(() => businessRepo.getBusiness());
      expect(updated!.brandColor, newColor);

      final auditEntries = await tester.runAsync(() => AuditTrailRepository().getEntries(business.id));
      expect(
        auditEntries!.any((e) => e.propertyName == AuditProperty.brandColor && e.newValue == newColor),
        isTrue,
      );
    });
  });

  group('SupplierSettings - Stamps Required is now generally editable', () {
    testWidgets('an in-range business can still open the editor and change the value (not just when out of range)',
        (tester) async {
      final business = await seedBusiness(tester, dbName: 'test_settings_stamps_general_edit.db');
      expect(CardIssueToken.isStampsRequiredSupported(business.stampsRequired), isTrue);

      await tester.pumpWidget(MaterialApp(home: SupplierSettings(business: business)));
      await tester.pumpAndSettle();

      expect(find.text('6 stamps, tap to change'), findsOneWidget);

      await tester.tap(find.text('6 stamps, tap to change'));
      await tester.pumpAndSettle();

      expect(find.text('Fix Stamps Required'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add_circle));
      await tester.pump();

      await tester.tap(find.text('Save'));
      await pumpUntil(tester, () => find.text('7 stamps, tap to change').evaluate().isNotEmpty);

      final updated = await tester.runAsync(() => businessRepo.getBusiness());
      expect(updated!.stampsRequired, 7);

      final auditEntries = await tester.runAsync(() => AuditTrailRepository().getEntries(business.id));
      expect(
        auditEntries!.any((e) => e.propertyName == AuditProperty.stampsRequired && e.newValue == '7'),
        isTrue,
      );
    });
  });
}
