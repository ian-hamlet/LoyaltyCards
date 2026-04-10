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
      version: 1,
      onCreate: _onCreate,
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
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing)
  Future<void> clearAllData() async {
    print('='.padRight(60, '='));
    print('DATABASE: Clearing all tables - ${DateTime.now().toIso8601String()}');
    final db = await database;
    await db.delete('business');
    print('  Cleared business table');
    await db.delete('issued_cards');
    print('  Cleared issued_cards table');
    await db.delete('stamp_history');
    print('  Cleared stamp_history table');
    await db.delete('app_settings');
    print('  Cleared app_settings table');
    print('ALL TABLES CLEARED');
    print('='.padRight(60, '='));
  }

  /// Delete database file (complete reset)
  Future<void> deleteDatabase() async {
    print('='.padRight(60, '='));
    print('DATABASE: DELETING DATABASE FILE - ${DateTime.now().toIso8601String()}');
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'loyalty_cards_supplier.db');
    print('Database path: $path');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('DATABASE FILE DELETED');
    print('='.padRight(60, '='));
  }
}
