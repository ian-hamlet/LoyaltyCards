import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared/shared.dart';

/// Database helper for customer app
/// Manages SQLite database creation, migrations, and connections
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static String? _testDatabaseName; // Custom database name for testing

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Reset singleton instance for testing
  /// Call this in test setUp() with a unique database name per test file
  static Future<void> resetForTesting({String? testDatabaseName}) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _testDatabaseName = testDatabaseName;
  }

  /// Run [action] inside a single atomic SQLite transaction.
  ///
  /// Q-003: multi-step writes that must succeed or fail together (e.g.
  /// crediting a stamp: insert the stamp row, log a transaction, update the
  /// card's stampsCollected count) should go through this rather than
  /// separate top-level `db.insert`/`update` calls - otherwise a failure
  /// partway through leaves the database in an inconsistent state (stamp
  /// rows exist but the count was never incremented).
  Future<T> runInTransaction<T>(Future<T> Function(DatabaseExecutor txn) action) async {
    final db = await database;
    return db.transaction((txn) => action(txn));
  }

  /// Get database instance (creates if doesn't exist)
  /// HP-2: Added timeout protection to prevent indefinite hangs
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    try {
      _database = await _initDatabase().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.error('Database initialization timeout - database may be locked or corrupted', tag: 'Database');
          throw TimeoutException('Database initialization failed after 10 seconds');
        },
      );
      return _database!;
    } on TimeoutException {
      // Attempt recovery: delete corrupted database and recreate
      AppLogger.error('Attempting database recovery after timeout', tag: 'Database');
      await _attemptDatabaseRecovery();
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Database initialization error: $e', error: e, stackTrace: stack, tag: 'Database');
      rethrow;
    }
  }
  
  /// Test-only accessor for [_attemptDatabaseRecovery] (Q-002).
  ///
  /// The real trigger for recovery is a 10-second open timeout, which isn't
  /// reliably or quickly reproducible in a test environment. This calls the
  /// exact same recovery logic directly so tests can verify the actual
  /// delete-vs-preserve decision (based on the SQLite file header) without
  /// needing to simulate a hang.
  @visibleForTesting
  Future<void> attemptDatabaseRecoveryForTesting() => _attemptDatabaseRecovery();

  /// Attempt to recover from corrupted database
  ///
  /// Q-002 fix: this previously deleted the database file unconditionally
  /// on ANY open timeout - a slow/throttled device or a transient OS-level
  /// file lock (not actual corruption) would cause total, unrecoverable
  /// data loss, since this is a P2P app with no server backup. Now checks
  /// the SQLite file header first (cheap, doesn't require opening a
  /// connection, so it can't hang the way the failed open did) and only
  /// deletes if the file doesn't even look like a valid SQLite database.
  /// A merely slow/locked-but-intact file is left alone; the caller still
  /// sees the TimeoutException and can retry, but the user's data survives.
  Future<void> _attemptDatabaseRecovery() async {
    try {
      final databasesPath = await getDatabasesPath();
      final dbName = _testDatabaseName ?? AppConstants.databaseName;
      final path = join(databasesPath, dbName);
      final file = File(path);

      if (await file.exists()) {
        if (await _looksLikeValidSqliteFile(file)) {
          AppLogger.warning(
            'Database open timed out, but the file has a valid SQLite header - '
            'treating as slow/locked rather than corrupted. Not deleting.',
            'Database',
          );
        } else {
          await file.delete();
          AppLogger.warning('Deleted corrupted database file (invalid header): $path', 'Database');
        }
      }

      // Reset database instance to allow recreation
      _database = null;
    } catch (e, stack) {
      AppLogger.error('Database recovery failed: $e', error: e, stackTrace: stack, tag: 'Database');
    }
  }

  /// Checks the SQLite file header magic bytes ("SQLite format 3\0")
  /// without opening a database connection - a cheap, non-blocking
  /// corruption signal that can't hang the way a real open attempt can.
  static Future<bool> _looksLikeValidSqliteFile(File file) async {
    const header = 'SQLite format 3\x00';
    RandomAccessFile? raf;
    try {
      raf = await file.open();
      final bytes = await raf.read(header.length);
      if (bytes.length < header.length) return false;
      for (int i = 0; i < header.length; i++) {
        if (bytes[i] != header.codeUnitAt(i)) return false;
      }
      return true;
    } catch (e) {
      // Can't even read the file - treat as invalid/corrupted.
      return false;
    } finally {
      await raf?.close();
    }
  }

  /// Initialize database with schema
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    // Use custom test database name if set, otherwise use production name
    final dbName = _testDatabaseName ?? AppConstants.databaseName;
    final path = join(databasesPath, dbName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgradeWithSafety,
      onConfigure: _onConfigure,
    );
  }

  /// Enable foreign keys
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    // Cards table
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

    // Stamps table
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

    // Transactions table
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

    // App settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute('''
      CREATE INDEX idx_stamps_card_id ON stamps (card_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_card_id ON transactions (card_id)
    ''');
    
    // Performance indexes for common queries (v0.3.0+)
    await db.execute('''
      CREATE INDEX idx_cards_business_id ON cards (business_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_cards_device_id ON cards (device_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_cards_is_redeemed ON cards (is_redeemed)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_cards_created_at ON cards (created_at DESC)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.database('Database upgrade from version $oldVersion to $newVersion');
    
    // Migration from v1 to v2: Add is_redeemed column
    if (oldVersion < 2) {
      AppLogger.database('Migration v1 → v2: Adding is_redeemed column to cards table');
      await db.execute('''
        ALTER TABLE cards ADD COLUMN is_redeemed INTEGER NOT NULL DEFAULT 0
      ''');
      AppLogger.database('Migration complete: is_redeemed column added');
    }
    
    // Migration from v2 to v3: Add logo_index column
    if (oldVersion < 3) {
      AppLogger.database('Migration v2 → v3: Adding logo_index column to cards table');
      await db.execute('''
        ALTER TABLE cards ADD COLUMN logo_index INTEGER NOT NULL DEFAULT 0
      ''');
      AppLogger.database('Migration complete: logo_index column added');
    }
    
    // Migration from v3 to v4: Add mode column
    if (oldVersion < 4) {
      AppLogger.database('Migration v3 → v4: Adding mode column to cards table');
      await db.execute('''
        ALTER TABLE cards ADD COLUMN mode TEXT NOT NULL DEFAULT 'secure'
      ''');
      AppLogger.database('Migration complete: mode column added (default: secure)');
    }
    
    // Migration from v4 to v5: Add redeemed_at column
    if (oldVersion < 5) {
      AppLogger.database('Migration v4 → v5: Adding redeemed_at column to cards table');
      await db.execute('''
        ALTER TABLE cards ADD COLUMN redeemed_at INTEGER
      ''');
      AppLogger.database('Migration complete: redeemed_at column added');
    }
    
    // Migration from v5 to v6: Add device_id columns (V-005 Multi-Device Duplication Detection)
    if (oldVersion < 6) {
      AppLogger.database('Migration v5 → v6: Adding device_id columns for multi-device tracking');
      await db.execute('''
        ALTER TABLE cards ADD COLUMN device_id TEXT
      ''');
      await db.execute('''
        ALTER TABLE stamps ADD COLUMN device_id TEXT
      ''');
      AppLogger.database('Migration complete: device_id columns added');
    }
    
    // Migration from v6 to v7: Add performance indexes
    if (oldVersion < 7) {
      AppLogger.database('Migration v6 → v7: Adding performance indexes');
      try {
        // Add indexes for common queries
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_cards_business_id ON cards (business_id)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_cards_device_id ON cards (device_id)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_cards_is_redeemed ON cards (is_redeemed)
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_cards_created_at ON cards (created_at DESC)
        ''');
        AppLogger.database('Migration complete: Performance indexes added');
      } catch (e) {
        AppLogger.error('Failed to add indexes (non-critical): $e');
        // Don't fail migration if indexes already exist or can't be created
      }
    }
  }

  /// Safety wrapper for database migrations with backup and rollback
  Future<void> _onUpgradeWithSafety(Database db, int oldVersion, int newVersion) async {
    AppLogger.database('Starting safe migration from v$oldVersion to v$newVersion');
    
    // Step 1: Create backup before migration
    String? backupPath;
    try {
      backupPath = await _createDatabaseBackup(oldVersion);
      AppLogger.database('Backup created at: $backupPath');
    } catch (e, stack) {
      AppLogger.error('Failed to create database backup: $e', error: e, stackTrace: stack);
      // Continue migration even if backup fails (better than blocking)
      // But log prominently for debugging if migration fails
    }

    // Step 2: Attempt migration
    try {
      await _onUpgrade(db, oldVersion, newVersion);
      
      // Step 3: Validate schema after migration
      final isValid = await _validateDatabaseSchema(db);
      if (!isValid) {
        throw Exception('Database schema validation failed after migration');
      }
      
      AppLogger.database('Migration successful and validated');
      
      // Step 4: Clean up backup on success (keep last backup)
      if (backupPath != null) {
        await _cleanupOldBackups(keepLatest: 1);
      }
    } catch (e, stack) {
      AppLogger.error('Migration v$oldVersion → v$newVersion FAILED: $e', error: e, stackTrace: stack);
      
      // Step 5: Attempt rollback if backup exists
      if (backupPath != null) {
        try {
          await _restoreDatabaseBackup(backupPath);
          AppLogger.database('Successfully rolled back to v$oldVersion');

          // Q-008 fix: this cleanup previously only ran on the success
          // path, so every failed-then-rolled-back migration attempt left
          // another backup_v*_<timestamp>.db file on disk permanently - a
          // device stuck retrying the same failing upgrade across app
          // launches would accumulate them indefinitely. Prune to the
          // latest here too, matching the success path's behavior. Wrapped
          // separately so a cleanup failure doesn't mask the real
          // rollback-succeeded exception below.
          try {
            await _cleanupOldBackups(keepLatest: 1);
          } catch (cleanupError) {
            AppLogger.warning('Backup cleanup after rollback failed (non-fatal): $cleanupError', 'Database');
          }

          throw Exception('Migration failed and rolled back to v$oldVersion. Error: $e');
        } catch (rollbackError, rollbackStack) {
          AppLogger.error('Rollback FAILED: $rollbackError', error: rollbackError, stackTrace: rollbackStack);
          throw Exception(
            'CRITICAL: Migration failed AND rollback failed. '
            'Original error: $e. Rollback error: $rollbackError. '
            'Manual recovery may be required.'
          );
        }
      } else {
        // No backup available, can't rollback
        throw Exception('Migration failed and no backup available for rollback. Error: $e');
      }
    }
  }

  /// Create a backup copy of the database file
  ///
  /// Q-010 fix: this previously hardcoded AppConstants.databaseName instead
  /// of respecting _testDatabaseName (which _initDatabase/
  /// _attemptDatabaseRecovery in this same file already did correctly) -
  /// so any migration test using a custom test DB name silently backed up
  /// the production filename instead (usually nonexistent), an error
  /// swallowed by the outer "continue migration even if backup fails" catch.
  /// This meant the migration safety net was never actually exercised by
  /// any test.
  Future<String> _createDatabaseBackup(int version) async {
    final databasesPath = await getDatabasesPath();
    final dbName = _testDatabaseName ?? AppConstants.databaseName;
    final sourcePath = join(databasesPath, dbName);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = join(databasesPath, 'backup_v${version}_$timestamp.db');
    
    // Close current connection before copying
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    // Copy database file
    final sourceFile = await File(sourcePath).readAsBytes();
    await File(backupPath).writeAsBytes(sourceFile);
    
    AppLogger.database('Database backup created: $backupPath');
    return backupPath;
  }

  /// Restore database from backup
  Future<void> _restoreDatabaseBackup(String backupPath) async {
    final databasesPath = await getDatabasesPath();
    final dbName = _testDatabaseName ?? AppConstants.databaseName;
    final targetPath = join(databasesPath, dbName);
    
    // Close current connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    // Copy backup over current database
    final backupFile = await File(backupPath).readAsBytes();
    await File(targetPath).writeAsBytes(backupFile);
    
    AppLogger.database('Database restored from backup: $backupPath');
  }

  /// Clean up old backup files, keeping only the most recent ones
  Future<void> _cleanupOldBackups({int keepLatest = 1}) async {
    try {
      final databasesPath = await getDatabasesPath();
      final directory = Directory(databasesPath);
      
      // Find all backup files
      final backupFiles = directory
          .listSync()
          .whereType<File>()
          .where((file) => basename(file.path).startsWith('backup_v'))
          .toList();
      
      // Sort by modification time (newest first)
      backupFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      // Delete old backups
      for (int i = keepLatest; i < backupFiles.length; i++) {
        await backupFiles[i].delete();
        AppLogger.database('Deleted old backup: ${backupFiles[i].path}');
      }
    } catch (e) {
      AppLogger.error('Failed to clean up old backups (non-critical): $e');
    }
  }

  /// Validate database schema integrity
  Future<bool> _validateDatabaseSchema(Database db) async {
    try {
      // Check that critical tables exist
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"
      );
      
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      final requiredTables = {'cards', 'stamps', 'transactions', 'app_settings'};
      
      if (!requiredTables.every((table) => tableNames.contains(table))) {
        AppLogger.error('Critical tables missing. Expected: $requiredTables, Found: $tableNames');
        return false;
      }
      
      // Verify cards table has required columns
      final cardsInfo = await db.rawQuery('PRAGMA table_info(cards)');
      final cardsColumns = cardsInfo.map((c) => c['name'] as String).toSet();
      final requiredCardsColumns = {
        'id', 'business_id', 'business_name', 'business_public_key',
        'stamps_required', 'stamps_collected', 'brand_color', 'logo_index',
        'mode', 'created_at', 'updated_at', 'is_redeemed'
      };
      
      if (!requiredCardsColumns.every((col) => cardsColumns.contains(col))) {
        AppLogger.error('Cards table missing required columns');
        return false;
      }
      
      // Verify foreign keys are enabled
      final fkResult = await db.rawQuery('PRAGMA foreign_keys');
      final fkEnabled = fkResult.isNotEmpty && fkResult.first['foreign_keys'] == 1;
      
      if (!fkEnabled) {
        AppLogger.error('Foreign keys are not enabled');
        return false;
      }
      
      AppLogger.database('Database schema validation passed');
      return true;
    } catch (e, stack) {
      AppLogger.error('Schema validation error: $e', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    AppLogger.database('Clearing all tables');
    final db = await database;
    await db.delete('cards');
    await db.delete('stamps');
    await db.delete('transactions');
    await db.delete('app_settings');
    AppLogger.database('All tables cleared');
  }

  /// Delete database file (complete reset)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    // Use custom test database name if set, otherwise use production name
    final dbName = _testDatabaseName ?? AppConstants.databaseName;
    final path = join(databasesPath, dbName);
    AppLogger.database('Deleting database file: $path');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    AppLogger.database('Database file deleted');
  }
}
