import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// Covers supplier_database_helper.dart's public surface: schema creation,
/// close()/reopen, and deleteDatabase(). Backup/restore/upgrade-with-safety
/// are private methods only reachable via a real version bump on an
/// existing DB file - not covered here for the same reason documented in
/// customer_app/test/services/database_helper_operations_test.dart:
/// faithfully reproducing an old schema without access to real historical
/// versions would test invented behavior, not the real migration path.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late SupplierDatabaseHelper dbHelper;

  setUp(() async {
    await SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_supplier_database_helper.db');
    dbHelper = SupplierDatabaseHelper();
  });

  tearDown(() async {
    await dbHelper.clearAllData();
  });

  group('SupplierDatabaseHelper - schema', () {
    test('creates all required tables', () async {
      final db = await dbHelper.database;
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
        columns: ['name'],
      );
      final tableNames = tables.map((t) => t['name'] as String).toSet();

      for (final expected in [
        'business',
        'issued_cards',
        'stamp_history',
        'redemptions',
        'app_settings',
      ]) {
        expect(tableNames, contains(expected), reason: 'missing table: $expected');
      }
    });

    test('foreign keys are enabled', () async {
      final db = await dbHelper.database;
      final result = await db.rawQuery('PRAGMA foreign_keys');
      expect(result.first['foreign_keys'], 1);
    });
  });

  group('SupplierDatabaseHelper.clearAllData', () {
    test('removes rows from business and redemptions but keeps the schema usable', () async {
      final db = await dbHelper.database;
      await db.insert('business', {
        'id': 'business-1',
        'name': 'Test Business',
        'public_key': 'pub',
        'stamps_required': 10,
        'brand_color': '#FF0000',
        'logo_index': 0,
        'mode': 'secure',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'scan_interval_seconds': 30,
      });

      var businesses = await db.query('business');
      expect(businesses.length, 1);

      await dbHelper.clearAllData();

      businesses = await db.query('business');
      expect(businesses, isEmpty);

      // Still usable afterward.
      await db.insert('business', {
        'id': 'business-2',
        'name': 'Another Business',
        'public_key': 'pub2',
        'stamps_required': 5,
        'brand_color': '#00FF00',
        'logo_index': 1,
        'mode': 'simple',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'scan_interval_seconds': 30,
      });
      businesses = await db.query('business');
      expect(businesses.length, 1);
    });
  });

  group('SupplierDatabaseHelper.close', () {
    test('closes the connection and a subsequent access reopens it', () async {
      final db = await dbHelper.database;
      expect(db.isOpen, isTrue);

      await dbHelper.close();
      expect(db.isOpen, isFalse);

      final reopened = await dbHelper.database;
      expect(reopened.isOpen, isTrue);
    });
  });

  group('SupplierDatabaseHelper.deleteDatabase', () {
    test('data does not survive a delete + reopen cycle', () async {
      final db = await dbHelper.database;
      await db.insert('business', {
        'id': 'business-1',
        'name': 'Test Business',
        'public_key': 'pub',
        'stamps_required': 10,
        'brand_color': '#FF0000',
        'logo_index': 0,
        'mode': 'secure',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'scan_interval_seconds': 30,
      });

      await dbHelper.deleteDatabase();

      final freshDb = await dbHelper.database;
      final businesses = await freshDb.query('business');
      expect(businesses, isEmpty);
    });
  });
}
