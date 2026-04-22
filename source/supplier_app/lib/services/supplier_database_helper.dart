import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared/shared.dart';

/// Database helper for supplier app
/// Manages SQLite database for business configuration and history
class SupplierDatabaseHelper {
  static final SupplierDatabaseHelper _instance = SupplierDatabaseHelper._internal();
  static Database? _database;

  factory SupplierDatabaseHelper() => _instance;

  SupplierDatabaseHelper._internal();

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
  
  /// Attempt to recover from corrupted database
  Future<void> _attemptDatabaseRecovery() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'loyalty_cards_supplier.db');
      final file = File(path);
      
      if (await file.exists()) {
        await file.delete();
        AppLogger.warning('Deleted corrupted database file: $path', 'Database');
      }
      
      // Reset database instance to allow recreation
      _database = null;
    } catch (e, stack) {
      AppLogger.error('Database recovery failed: $e', error: e, stackTrace: stack, tag: 'Database');
    }
  }

  /// Initialize database with schema
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'loyalty_cards_supplier.db');

    return await openDatabase(
      path,
      version: AppConstants.supplierDatabaseVersion,
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
    // Business table
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

    // Issued cards tracking (optional - for analytics)
    await db.execute('''
      CREATE TABLE issued_cards (
        id TEXT PRIMARY KEY,
        business_id TEXT NOT NULL,
        issued_at INTEGER NOT NULL,
        FOREIGN KEY (business_id) REFERENCES business (id) ON DELETE CASCADE
      )
    ''');

    // Stamp history (optional - for analytics)
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

    // Redemptions tracking (for analytics)
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

    // App settings
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('''
      CREATE INDEX idx_issued_cards_business ON issued_cards (business_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_stamp_history_business ON stamp_history (business_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_redemptions_business ON redemptions (business_id)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.database('Database upgrade from version $oldVersion to $newVersion');
    
    // Migration from v1 to v2: Add redemptions table
    if (oldVersion < 2) {
      AppLogger.database('Migration v1 → v2: Adding redemptions table');
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
        CREATE INDEX idx_redemptions_business ON redemptions (business_id)
      ''');
      AppLogger.database('Migration complete: redemptions table added');
    }
    
    // Migration from v2 to v3: Add logo_index column
    if (oldVersion < 3) {
      AppLogger.database('Migration v2 → v3: Adding logo_index column to business table');
      await db.execute('''
        ALTER TABLE business ADD COLUMN logo_index INTEGER NOT NULL DEFAULT 0
      ''');
      AppLogger.database('Migration complete: logo_index column added');
    }
    
    // Migration from v3 to v4: Add mode column
    if (oldVersion < 4) {
      AppLogger.database('Migration v3 → v4: Adding mode column to business table');
      await db.execute('''
        ALTER TABLE business ADD COLUMN mode TEXT NOT NULL DEFAULT 'secure'
      ''');
      AppLogger.database('Migration complete: mode column added (default: secure)');
    }
    
    // Migration from v4 to v5: Add scan_interval_seconds column (REQ-022)
    if (oldVersion < 5) {
      AppLogger.database('Migration v4 → v5: Adding scan_interval_seconds column to business table');
      await db.execute('''
        ALTER TABLE business ADD COLUMN scan_interval_seconds INTEGER NOT NULL DEFAULT 30
      ''');
      AppLogger.database('Migration complete: scan_interval_seconds column added (default: 30s)');
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
      
      // Step 4: Clean up backup on success
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
        throw Exception('Migration failed and no backup available for rollback. Error: $e');
      }
    }
  }

  /// Create a backup copy of the database file
  Future<String> _createDatabaseBackup(int version) async {
    final databasesPath = await getDatabasesPath();
    final sourcePath = join(databasesPath, 'loyalty_cards_supplier.db');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = join(databasesPath, 'backup_supplier_v${version}_$timestamp.db');
    
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
    final targetPath = join(databasesPath, 'loyalty_cards_supplier.db');
    
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

  /// Clean up old backup files
  Future<void> _cleanupOldBackups({int keepLatest = 1}) async {
    try {
      final databasesPath = await getDatabasesPath();
      final directory = Directory(databasesPath);
      
      // Find all backup files
      final backupFiles = directory
          .listSync()
          .whereType<File>()
          .where((file) => basename(file.path).startsWith('backup_supplier_v'))
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
      final requiredTables = {'business', 'issued_cards', 'stamp_history', 'redemptions', 'app_settings'};
      
      if (!requiredTables.every((table) => tableNames.contains(table))) {
        AppLogger.error('Critical tables missing. Expected: $requiredTables, Found: $tableNames');
        return false;
      }
      
      // Verify business table has required columns
      final businessInfo = await db.rawQuery('PRAGMA table_info(business)');
      final businessColumns = businessInfo.map((c) => c['name'] as String).toSet();
      final requiredBusinessColumns = {
        'id', 'name', 'public_key', 'stamps_required', 'brand_color',
        'logo_index', 'mode', 'created_at', 'scan_interval_seconds'
      };
      
      if (!requiredBusinessColumns.every((col) => businessColumns.contains(col))) {
        AppLogger.error('Business table missing required columns');
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
    await db.delete('business');
    await db.delete('issued_cards');
    await db.delete('stamp_history');
    await db.delete('redemptions');
    await db.delete('app_settings');
    AppLogger.database('All tables cleared');
  }

  /// Delete database file (complete reset)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'loyalty_cards_supplier.db');
    AppLogger.database('Deleting database file: $path');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    AppLogger.database('Database file deleted');
  }
}
