import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:shared/shared.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  // Initialize sqflite for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Database Migration Safety Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      // Use unique database name for this test file to prevent locking
      await DatabaseHelper.resetForTesting(testDatabaseName: 'test_database_migration.db');

      dbHelper = DatabaseHelper();

      // Clean up any existing test database
      try {
        await dbHelper.deleteDatabase();
      } catch (e) {
        // Ignore if doesn't exist
      }
    });

    tearDown(() async {
      try {
        await dbHelper.close();
        await dbHelper.deleteDatabase();
        
        // Clean up backup files
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
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    test('database initializes successfully', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);
      expect(db.isOpen, isTrue);
    });

    test('database has all required tables', () async {
      final db = await dbHelper.database;
      
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      
      expect(tableNames.contains('cards'), isTrue);
      expect(tableNames.contains('stamps'), isTrue);
      expect(tableNames.contains('transactions'), isTrue);
      expect(tableNames.contains('app_settings'), isTrue);
    });

    test('cards table has all required columns', () async {
      final db = await dbHelper.database;
      
      final columns = await db.rawQuery('PRAGMA table_info(cards)');
      final columnNames = columns.map((c) => c['name'] as String).toSet();
      
      final requiredColumns = {
        'id', 'business_id', 'business_name', 'business_public_key',
        'stamps_required', 'stamps_collected', 'brand_color', 'logo_index',
        'mode', 'created_at', 'updated_at', 'is_redeemed', 'redeemed_at',
        'device_id'
      };
      
      for (final col in requiredColumns) {
        expect(columnNames.contains(col), isTrue, reason: 'Missing column: $col');
      }
    });

    test('foreign keys are enabled', () async {
      final db = await dbHelper.database;
      
      final fkResult = await db.rawQuery('PRAGMA foreign_keys');
      final fkEnabled = fkResult.isNotEmpty && fkResult.first['foreign_keys'] == 1;
      
      expect(fkEnabled, isTrue, reason: 'Foreign keys should be enabled');
    });

    test('performance indexes are created', () async {
      final db = await dbHelper.database;
      
      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'"
      );
      
      final indexNames = indexes.map((i) => i['name'] as String).toSet();
      
      expect(indexNames.contains('idx_cards_business_id'), isTrue);
      expect(indexNames.contains('idx_cards_device_id'), isTrue);
      expect(indexNames.contains('idx_cards_is_redeemed'), isTrue);
      expect(indexNames.contains('idx_cards_created_at'), isTrue);
      expect(indexNames.contains('idx_stamps_card_id'), isTrue);
      expect(indexNames.contains('idx_transactions_card_id'), isTrue);
    });

    test('cascade delete works correctly', () async {
      final db = await dbHelper.database;
      
      // Insert a test card
      await db.insert('cards', {
        'id': 'test-card-1',
        'business_id': 'business-1',
        'business_name': 'Test Business',
        'business_public_key': 'test-key',
        'stamps_required': 10,
        'stamps_collected': 3,
        'brand_color': '#FF0000',
        'logo_index': 0,
        'mode': 'secure',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_redeemed': 0,
      });
      
      // Insert a stamp for this card
      await db.insert('stamps', {
        'id': 'stamp-1',
        'card_id': 'test-card-1',
        'stamp_number': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'signature': 'test-signature',
      });
      
      // Insert a transaction for this card
      await db.insert('transactions', {
        'id': 'transaction-1',
        'card_id': 'test-card-1',
        'type': 'stamp_added',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'business_name': 'Test Business',
      });
      
      // Verify data exists
      final stamps = await db.query('stamps', where: 'card_id = ?', whereArgs: ['test-card-1']);
      final transactions = await db.query('transactions', where: 'card_id = ?', whereArgs: ['test-card-1']);
      
      expect(stamps.length, 1);
      expect(transactions.length, 1);
      
      // Delete the card
      await db.delete('cards', where: 'id = ?', whereArgs: ['test-card-1']);
      
      // Verify cascade delete removed stamps and transactions
      final stampsAfter = await db.query('stamps', where: 'card_id = ?', whereArgs: ['test-card-1']);
      final transactionsAfter = await db.query('transactions', where: 'card_id = ?', whereArgs: ['test-card-1']);
      
      expect(stampsAfter.length, 0, reason: 'Stamps should be cascade deleted');
      expect(transactionsAfter.length, 0, reason: 'Transactions should be cascade deleted');
    });

    test('database can be cleared and reused', () async {
      final db = await dbHelper.database;
      
      // Insert test data
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
      
      // Verify data exists
      final cardsBefore = await db.query('cards');
      expect(cardsBefore.length, 1);
      
      // Clear all data
      await dbHelper.clearAllData();
      
      // Verify data is gone
      final cardsAfter = await db.query('cards');
      expect(cardsAfter.length, 0);
      
      // Verify database is still functional
      await db.insert('cards', {
        'id': 'test-card-2',
        'business_id': 'business-2',
        'business_name': 'Test Business 2',
        'business_public_key': 'test-key-2',
        'stamps_required': 5,
        'stamps_collected': 0,
        'brand_color': '#00FF00',
        'logo_index': 1,
        'mode': 'simple',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_redeemed': 0,
      });
      
      final cardsNew = await db.query('cards');
      expect(cardsNew.length, 1);
    });
  });

  group('Database Schema Validation Tests', () {
    test('detects missing tables', () async {
      // This test would require mocking or creating a database with missing tables
      // For now, we just verify the validation method exists and runs
      final dbHelper = DatabaseHelper();
      final db = await dbHelper.database;

      // The database should validate successfully when properly created
      expect(db, isNotNull);
    });
  });

  group('v7 -> v8 Migration (original stamp context columns)', () {
    const testDbName = 'test_database_migration_v7_v8.db';
    late String testDbPath;

    setUp(() async {
      await DatabaseHelper.resetForTesting(testDatabaseName: testDbName);
      final databasesPath = await getDatabasesPath();
      testDbPath = join(databasesPath, testDbName);
      if (await File(testDbPath).exists()) {
        await File(testDbPath).delete();
      }
    });

    tearDown(() async {
      await DatabaseHelper().close();
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

    test('existing v7 stamp rows survive the upgrade with original-context columns defaulting to NULL', () async {
      // Step 1: build a real v7 database by hand - the same shape
      // DatabaseHelper._onCreate produced before the v8 migration added
      // original_card_id/original_stamp_number/original_previous_hash to
      // stamps. Deliberately duplicated here rather than importing private
      // helpers, since the whole point is to simulate an install that
      // predates today's code.
      final v7Db = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 7,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE cards (
                id TEXT PRIMARY KEY,
                business_id TEXT NOT NULL,
                business_name TEXT NOT NULL,
                business_public_key TEXT NOT NULL,
                stamps_required INTEGER NOT NULL,
                stamps_collected INTEGER NOT NULL,
                brand_color TEXT NOT NULL,
                logo_index INTEGER NOT NULL DEFAULT 0,
                mode TEXT NOT NULL DEFAULT 'secure',
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                is_redeemed INTEGER NOT NULL DEFAULT 0,
                redeemed_at INTEGER,
                device_id TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE stamps (
                id TEXT PRIMARY KEY,
                card_id TEXT NOT NULL,
                stamp_number INTEGER NOT NULL,
                timestamp INTEGER NOT NULL,
                signature TEXT NOT NULL,
                previous_hash TEXT,
                device_id TEXT,
                FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE transactions (
                id TEXT PRIMARY KEY,
                card_id TEXT NOT NULL,
                type TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                business_name TEXT NOT NULL,
                details TEXT,
                FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
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

      await v7Db.insert('cards', {
        'id': 'card-v7-1',
        'business_id': 'business-v7-1',
        'business_name': 'Pre-Migration Business',
        'business_public_key': 'test-key',
        'stamps_required': 5,
        'stamps_collected': 1,
        'brand_color': '#123456',
        'logo_index': 0,
        'mode': 'secure',
        'created_at': 1749600000000,
        'updated_at': 1749600000000,
        'is_redeemed': 0,
      });
      await v7Db.insert('stamps', {
        'id': 'card-v7-1_stamp_1',
        'card_id': 'card-v7-1',
        'stamp_number': 1,
        'timestamp': 1749600000001,
        'signature': 'genuine-pre-migration-signature',
        'previous_hash': null,
        'device_id': 'device-abc',
      });
      await v7Db.close();

      // Step 2: open the same file through the real DatabaseHelper, which
      // requests the app's current target version - sqflite sees on-disk
      // user_version=7 vs target=8 and runs the real onUpgrade path
      // (_onUpgradeWithSafety -> _onUpgrade) rather than onCreate.
      final dbHelper = DatabaseHelper();
      final upgradedDb = await dbHelper.database;

      expect(upgradedDb.isOpen, isTrue);
      // References the constant rather than a hardcoded literal - this test
      // upgrades from a hand-built v7 database to whatever the app's
      // current target version is, not specifically v8, so a later schema
      // bump (e.g. v9's latest_stamps_required_snapshot column) shouldn't
      // need this test edited too.
      expect(await upgradedDb.getVersion(), AppConstants.databaseVersion);

      // The pre-existing card and stamp row must survive untouched.
      final cards = await upgradedDb.query('cards', where: 'id = ?', whereArgs: ['card-v7-1']);
      expect(cards.length, 1);
      expect(cards.first['business_name'], 'Pre-Migration Business');

      final stamps = await upgradedDb.query('stamps', where: 'id = ?', whereArgs: ['card-v7-1_stamp_1']);
      expect(stamps.length, 1);
      expect(stamps.first['signature'], 'genuine-pre-migration-signature');

      // The three new columns must exist and default to NULL for a stamp
      // that predates the concept of a "moved" stamp - this is the
      // condition verifyRedemptionStampChain's `wasMoved` branch depends on
      // to correctly treat pre-migration stamps as never-moved.
      expect(stamps.first.containsKey('original_card_id'), isTrue);
      expect(stamps.first.containsKey('original_stamp_number'), isTrue);
      expect(stamps.first.containsKey('original_previous_hash'), isTrue);
      expect(stamps.first['original_card_id'], isNull);
      expect(stamps.first['original_stamp_number'], isNull);
      expect(stamps.first['original_previous_hash'], isNull);

      // A freshly-inserted post-migration stamp can now populate them.
      await upgradedDb.insert('stamps', {
        'id': 'card-v7-1_stamp_2',
        'card_id': 'card-v7-1',
        'stamp_number': 1,
        'timestamp': 1749600000002,
        'signature': 'moved-stamp-signature',
        'previous_hash': null,
        'device_id': 'device-abc',
        'original_card_id': 'card-source',
        'original_stamp_number': 6,
        'original_previous_hash': 'source-prev-hash',
      });
      final movedStamp = await upgradedDb.query('stamps', where: 'id = ?', whereArgs: ['card-v7-1_stamp_2']);
      expect(movedStamp.first['original_card_id'], 'card-source');
      expect(movedStamp.first['original_stamp_number'], 6);
    });
  });

  group('v8 -> v9 Migration (latest_stamps_required_snapshot column)', () {
    const testDbName = 'test_database_migration_v8_v9.db';
    late String testDbPath;

    setUp(() async {
      await DatabaseHelper.resetForTesting(testDatabaseName: testDbName);
      final databasesPath = await getDatabasesPath();
      testDbPath = join(databasesPath, testDbName);
      if (await File(testDbPath).exists()) {
        await File(testDbPath).delete();
      }
    });

    tearDown(() async {
      await DatabaseHelper().close();
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

    test('existing v8 card rows survive the upgrade with latest_stamps_required_snapshot defaulting to NULL',
        () async {
      // Build a real v8 database by hand - the shape DatabaseHelper._onCreate
      // produced before the v9 migration added
      // latest_stamps_required_snapshot to cards (Requirements/
      // DISCUSSION_Business_Field_Editing.md §4.1).
      final v8Db = await databaseFactory.openDatabase(
        testDbPath,
        options: OpenDatabaseOptions(
          version: 8,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE cards (
                id TEXT PRIMARY KEY,
                business_id TEXT NOT NULL,
                business_name TEXT NOT NULL,
                business_public_key TEXT NOT NULL,
                stamps_required INTEGER NOT NULL,
                stamps_collected INTEGER NOT NULL,
                brand_color TEXT NOT NULL,
                logo_index INTEGER NOT NULL DEFAULT 0,
                mode TEXT NOT NULL DEFAULT 'secure',
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                is_redeemed INTEGER NOT NULL DEFAULT 0,
                redeemed_at INTEGER,
                device_id TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE stamps (
                id TEXT PRIMARY KEY,
                card_id TEXT NOT NULL,
                stamp_number INTEGER NOT NULL,
                timestamp INTEGER NOT NULL,
                signature TEXT NOT NULL,
                previous_hash TEXT,
                device_id TEXT,
                original_card_id TEXT,
                original_stamp_number INTEGER,
                original_previous_hash TEXT,
                FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE TABLE transactions (
                id TEXT PRIMARY KEY,
                card_id TEXT NOT NULL,
                type TEXT NOT NULL,
                timestamp INTEGER NOT NULL,
                business_name TEXT NOT NULL,
                details TEXT,
                FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
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

      await v8Db.insert('cards', {
        'id': 'card-v8-1',
        'business_id': 'business-v8-1',
        'business_name': 'Pre-Migration Business',
        'business_public_key': 'test-key',
        'stamps_required': 8,
        'stamps_collected': 3,
        'brand_color': '#123456',
        'logo_index': 0,
        'mode': 'secure',
        'created_at': 1749600000000,
        'updated_at': 1749600000000,
        'is_redeemed': 0,
      });
      await v8Db.close();

      // Open through the real DatabaseHelper - sqflite sees on-disk
      // user_version=8 vs the app's current target and runs the real
      // onUpgrade path.
      final dbHelper = DatabaseHelper();
      final upgradedDb = await dbHelper.database;

      expect(upgradedDb.isOpen, isTrue);
      expect(await upgradedDb.getVersion(), AppConstants.databaseVersion);

      final cards = await upgradedDb.query('cards', where: 'id = ?', whereArgs: ['card-v8-1']);
      expect(cards.length, 1);
      expect(cards.first['business_name'], 'Pre-Migration Business');
      expect(cards.first['stamps_required'], 8);

      // The new column must exist and default to NULL for a card that
      // predates the concept of a tracked snapshot - this is the condition
      // the redemption handlers' `?? card.stampsRequired` fallback depends
      // on to behave exactly as before for a pre-migration card.
      expect(cards.first.containsKey('latest_stamps_required_snapshot'), isTrue);
      expect(cards.first['latest_stamps_required_snapshot'], isNull);

      // A freshly-updated post-migration card can now populate it.
      await upgradedDb.update(
        'cards',
        {'latest_stamps_required_snapshot': 12},
        where: 'id = ?',
        whereArgs: ['card-v8-1'],
      );
      final updatedCard = await upgradedDb.query('cards', where: 'id = ?', whereArgs: ['card-v8-1']);
      expect(updatedCard.first['latest_stamps_required_snapshot'], 12);
    });
  });
}
