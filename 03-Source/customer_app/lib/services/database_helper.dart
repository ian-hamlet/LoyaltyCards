import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared/shared.dart';

/// Database helper for customer app
/// Manages SQLite database creation, migrations, and connections
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance (creates if doesn't exist)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database with schema
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
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
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
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
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations will go here
    // Example: if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
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
    await db.delete('cards');
    print('  Cleared cards table');
    await db.delete('stamps');
    print('  Cleared stamps table');
    await db.delete('transactions');
    print('  Cleared transactions table');
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
    final path = join(databasesPath, AppConstants.databaseName);
    print('Database path: $path');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('DATABASE FILE DELETED');
    print('='.padRight(60, '='));
  }
}
