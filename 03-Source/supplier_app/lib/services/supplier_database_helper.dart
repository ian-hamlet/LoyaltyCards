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
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with schema
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'loyalty_cards_supplier.db');

    return await openDatabase(
      path,
      version: 4, // Incremented for mode column
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        created_at INTEGER NOT NULL
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
