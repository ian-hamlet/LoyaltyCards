import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/models/audit_entry.dart';
import 'package:supplier_app/services/audit_trail_repository.dart';
import 'package:supplier_app/services/business_repository.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// Covers the local audit trail's data layer
/// (Requirements/DISCUSSION_Business_Field_Editing.md §7) - the migration
/// itself, and AuditTrailRepository's insert/query behavior.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const businessId = 'business-audit-trail-test';
  late AuditTrailRepository auditRepo;
  late BusinessRepository businessRepo;

  Future<void> seedBusiness() async {
    await businessRepo.insertBusiness(Business(
      id: businessId,
      name: 'Test Coffee Shop',
      publicKey: 'unused-plaintext-field',
      privateKey: 'unused-plaintext-field',
      stampsRequired: 6,
      brandColor: '#673AB7',
      mode: OperationMode.simple,
      createdAt: DateTime.now(),
    ));
  }

  setUp(() async {
    await SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_audit_trail_repository.db');
    auditRepo = AuditTrailRepository();
    businessRepo = BusinessRepository();
    await seedBusiness();
  });

  group('AuditTrailRepository', () {
    test('logEntry persists a single row with the given fields', () async {
      await auditRepo.logEntry(
        businessId: businessId,
        propertyName: AuditProperty.businessName,
        newValue: 'New Name',
      );

      final entries = await auditRepo.getEntries(businessId);
      expect(entries.length, 1);
      expect(entries.first.propertyName, AuditProperty.businessName);
      expect(entries.first.newValue, 'New Name');
      expect(entries.first.businessId, businessId);
      expect(entries.first.appVersion, appVersion);
    });

    test('logEntry accepts a null newValue (event markers)', () async {
      await auditRepo.logEntry(businessId: businessId, propertyName: AuditProperty.recoveryBackupCreated);

      final entries = await auditRepo.getEntries(businessId);
      expect(entries.length, 1);
      expect(entries.first.propertyName, AuditProperty.recoveryBackupCreated);
      expect(entries.first.newValue, isNull);
    });

    test('getEntries returns entries oldest-first', () async {
      await auditRepo.logEntry(businessId: businessId, propertyName: AuditProperty.businessName, newValue: 'First');
      await auditRepo.logEntry(businessId: businessId, propertyName: AuditProperty.businessName, newValue: 'Second');
      await auditRepo.logEntry(businessId: businessId, propertyName: AuditProperty.businessName, newValue: 'Third');

      final entries = await auditRepo.getEntries(businessId);
      expect(entries.length, 3);
      expect(entries.map((e) => e.newValue).toList(), ['First', 'Second', 'Third']);
    });

    test('getEntries is scoped to businessId - another business\'s entries never appear', () async {
      const otherBusinessId = 'business-audit-trail-other';
      await businessRepo.insertBusiness(Business(
        id: otherBusinessId,
        name: 'Other Shop',
        publicKey: 'unused-plaintext-field',
        privateKey: 'unused-plaintext-field',
        stampsRequired: 6,
        brandColor: '#673AB7',
        mode: OperationMode.simple,
        createdAt: DateTime.now(),
      ));

      await auditRepo.logEntry(businessId: businessId, propertyName: AuditProperty.businessName, newValue: 'Mine');
      await auditRepo.logEntry(businessId: otherBusinessId, propertyName: AuditProperty.businessName, newValue: 'Theirs');

      final entries = await auditRepo.getEntries(businessId);
      expect(entries.length, 1);
      expect(entries.first.newValue, 'Mine');
    });

    test('logProfileSnapshot logs one row per tracked field, Simple Mode includes Scan Cooldown', () async {
      await auditRepo.logProfileSnapshot(
        businessId: businessId,
        name: 'Test Coffee Shop',
        logoIndex: 1,
        brandColor: '#673AB7',
        stampsRequired: 6,
        mode: OperationMode.simple,
        scanIntervalMs: 30000,
      );

      final entries = await auditRepo.getEntries(businessId);
      final propertyNames = entries.map((e) => e.propertyName).toSet();
      expect(propertyNames, {
        AuditProperty.businessName,
        AuditProperty.icon,
        AuditProperty.brandColor,
        AuditProperty.stampsRequired,
        AuditProperty.operationMode,
        AuditProperty.scanCooldown,
      });

      final iconEntry = entries.firstWhere((e) => e.propertyName == AuditProperty.icon);
      expect(iconEntry.newValue, BusinessIcons.getIconName(1));

      final cooldownEntry = entries.firstWhere((e) => e.propertyName == AuditProperty.scanCooldown);
      expect(cooldownEntry.newValue, '30s');
    });

    test('logProfileSnapshot omits Scan Cooldown for Secure Mode (never uses scanInterval)', () async {
      await auditRepo.logProfileSnapshot(
        businessId: businessId,
        name: 'Test Coffee Shop',
        logoIndex: 1,
        brandColor: '#673AB7',
        stampsRequired: 6,
        mode: OperationMode.secure,
        scanIntervalMs: 30000,
      );

      final entries = await auditRepo.getEntries(businessId);
      final propertyNames = entries.map((e) => e.propertyName).toSet();
      expect(propertyNames.contains(AuditProperty.scanCooldown), isFalse);
    });

    test('deleting the business cascades to its audit_trail rows (matches every other child table)', () async {
      await auditRepo.logEntry(businessId: businessId, propertyName: AuditProperty.businessName, newValue: 'Cascaded Away');
      expect((await auditRepo.getEntries(businessId)).length, 1);

      await businessRepo.deleteBusiness(businessId);

      expect((await auditRepo.getEntries(businessId)).length, 0);
    });
  });
}
