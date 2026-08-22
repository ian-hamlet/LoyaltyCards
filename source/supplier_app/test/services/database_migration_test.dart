import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// Covers the v5 -> v6 migration (audit_trail table), added for
/// Requirements/DISCUSSION_Business_Field_Editing.md §7. Mirrors
/// customer_app/test/services/database_migration_test.dart's
/// hand-crafted-old-schema-then-real-upgrade pattern.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('v5 -> v6 Migration (audit_trail table)', () {
    const testDbName = 'test_supplier_database_migration_v5_v6.db';
    late String testDbPath;

    setUp(() async {
      await SupplierDatabaseHelper.resetForTesting(testDatabaseName: testDbName);
      final databasesPath = await getDatabasesPath();
      testDbPath = join(databasesPath, testDbName);
      if (await File(testDbPath).exists()) {
        await File(testDbPath).delete();
      }
    });

    tearDown(() async {
      await SupplierDatabaseHelper().close();
      if (await File(testDbPath).exists()) {
        await File(testDbPath).delete();
      }
      final databasesPath = await getDatabasesPath();
      final directory = Directory(databasesPath);
      final backupFiles = directory
          .listSync()
          .whereType<File>()
          .where((file) => basename(file.path).startsWith('backup_'))
          .toList();
      for (final backup in backupFiles) {
        await backup.delete();
      }
    });

    test('existing v5 business rows survive the upgrade and the audit_trail table is created empty', () async {
      // Build a real v5 database by hand - the shape
      // SupplierDatabaseHelper._onCreate produced before the v6 migration
      // added the audit_trail table.
      final v5Db = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 5,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE business (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                public_key TEXT NOT NULL,
                stamps_required INTEGER NOT NULL,
                brand_color TEXT NOT NULL,
                logo_index INTEGER NOT NULL DEFAULT 0,
                mode TEXT NOT NULL DEFAULT 'secure',
                created_at INTEGER NOT NULL,
                scan_interval_seconds INTEGER NOT NULL DEFAULT 30
              )
            ''');
            await db.execute('''
              CREATE TABLE issued_cards (
                id TEXT PRIMARY KEY,
                business_id TEXT NOT NULL,
                issued_at INTEGER NOT NULL,
                FOREIGN KEY (business_id) REFERENCES business (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE stamp_history (
                id TEXT PRIMARY KEY,
                card_id TEXT NOT NULL,
                stamp_number INTEGER NOT NULL,
                issued_at INTEGER NOT NULL,
                business_id TEXT NOT NULL,
                FOREIGN KEY (business_id) REFERENCES business (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE redemptions (
                id TEXT PRIMARY KEY,
                card_id TEXT NOT NULL,
                stamps_redeemed INTEGER NOT NULL,
                redeemed_at INTEGER NOT NULL,
                business_id TEXT NOT NULL,
                FOREIGN KEY (business_id) REFERENCES business (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE app_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
              )
            ''');
          },
        ),
      );

      await v5Db.insert('business', {
        'id': 'business-v5-1',
        'name': 'Pre-Migration Business',
        'public_key': 'test-key',
        'stamps_required': 8,
        'brand_color': '#123456',
        'logo_index': 0,
        'mode': 'secure',
        'created_at': 1749600000000,
        'scan_interval_seconds': 30,
      });
      await v5Db.close();

      // Open through the real SupplierDatabaseHelper - sqflite sees an
      // on-disk user_version=5 vs the app's current target and runs the
      // real onUpgrade path.
      final dbHelper = SupplierDatabaseHelper();
      final upgradedDb = await dbHelper.database;

      expect(upgradedDb.isOpen, isTrue);
      expect(await upgradedDb.getVersion(), AppConstants.supplierDatabaseVersion);

      final businesses = await upgradedDb.query('business', where: 'id = ?', whereArgs: ['business-v5-1']);
      expect(businesses.length, 1);
      expect(businesses.first['name'], 'Pre-Migration Business');
      expect(businesses.first['stamps_required'], 8);

      // The audit_trail table must now exist, and be empty for a
      // pre-migration install - it never retroactively fabricates history
      // for edits that predate the feature.
      final auditRows = await upgradedDb.query('audit_trail');
      expect(auditRows, isEmpty);

      // It must be usable exactly as the fresh-install schema is.
      await upgradedDb.insert('audit_trail', {
        'business_id': 'business-v5-1',
        'timestamp': 1749600000000,
        'property_name': 'businessName',
        'new_value': 'Renamed After Migration',
        'app_version': '2.2.0+31',
      });
      final insertedRows = await upgradedDb.query('audit_trail', where: 'business_id = ?', whereArgs: ['business-v5-1']);
      expect(insertedRows.length, 1);
      expect(insertedRows.first['new_value'], 'Renamed After Migration');
    });
  });
}
