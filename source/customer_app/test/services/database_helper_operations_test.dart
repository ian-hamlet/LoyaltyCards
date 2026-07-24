import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Covers database_helper.dart operations not already exercised by
/// database_migration_test.dart: close()/reopen and deleteDatabase().
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;

  setUp(() async {
    await DatabaseHelper.resetForTesting(testDatabaseName: 'test_database_helper_operations.db');
    dbHelper = DatabaseHelper();
  });

  tearDown(() async {
    try {
      await dbHelper.deleteDatabase();
    } catch (e) {
      // Ignore if already deleted
    }
  });

  group('DatabaseHelper.close', () {
    test('closes the database connection', () async {
      final db = await dbHelper.database;
      expect(db.isOpen, isTrue);

      await dbHelper.close();
      expect(db.isOpen, isFalse);
    });

    test('re-opening after close returns a fresh, usable connection', () async {
      await dbHelper.database;
      await dbHelper.close();

      final reopened = await dbHelper.database;
      expect(reopened.isOpen, isTrue);

      // Sanity check the reopened connection is actually functional.
      final tables = await reopened.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', 'cards'],
      );
      expect(tables, isNotEmpty);
    });
  });

  group('DatabaseHelper.deleteDatabase', () {
    test('data does not survive a delete + reopen cycle', () async {
      final db = await dbHelper.database;
      await db.insert('cards', {
        'id': 'test-card-1',
        'business_id': 'business-1',
        'business_name': 'Test Business',
        'business_public_key': 'test-key',
        'stamps_required': 10,
        'stamps_collected': 0,
        'brand_color': '#FF0000',
        'logo_index': 0,
        'mode': 'secure',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_redeemed': 0,
      });

      await dbHelper.deleteDatabase();

      final freshDb = await dbHelper.database;
      final cards = await freshDb.query('cards');
      expect(cards, isEmpty);
    });

    test('deleteDatabase does not throw when called on a fresh (never-opened) database', () async {
      // resetForTesting in setUp doesn't open a connection by itself -
      // deleting before ever touching `database` should be a safe no-op.
      await expectLater(dbHelper.deleteDatabase(), completes);
    });
  });
}
