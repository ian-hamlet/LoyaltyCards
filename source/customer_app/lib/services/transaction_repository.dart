import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:shared/models/transaction.dart' as models;
import 'package:shared/shared.dart' show TransactionType, AppLogger;
import 'database_helper.dart';

/// Repository for managing transactions in the database
class TransactionRepository {
  final DatabaseHelper _dbHelper;

  TransactionRepository(this._dbHelper);

  /// Get all transactions
  Future<List<models.Transaction>> getAllTransactions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => models.Transaction.fromJson(map)).toList();
  }

  /// Get transactions for a specific card
  Future<List<models.Transaction>> getTransactionsByCard(String cardId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => models.Transaction.fromJson(map)).toList();
  }

  /// Get transactions by type
  Future<List<models.Transaction>> getTransactionsByType(
    TransactionType type,
  ) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => models.Transaction.fromJson(map)).toList();
  }

  /// Get a specific transaction by ID
  Future<models.Transaction?> getTransactionById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return models.Transaction.fromJson(maps.first);
  }

  /// Insert a new transaction
  Future<void> insertTransaction(models.Transaction transaction) async {
    final db = await _dbHelper.database;
    await db.insert(
      'transactions',
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get recent transactions (last N transactions)
  Future<List<models.Transaction>> getRecentTransactions({int limit = 20}) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return maps.map((map) => models.Transaction.fromJson(map)).toList();
  }

  /// Get transaction count
  Future<int> getTransactionCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM transactions'),
    );
    return count ?? 0;
  }

  /// Get transaction count by type
  Future<int> getTransactionCountByType(TransactionType type) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM transactions WHERE type = ?',
        [type.name],
      ),
    );
    return count ?? 0;
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete transactions for a specific card
  Future<void> deleteTransactionsByCard(String cardId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'transactions',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
  }

  /// Delete all transactions (for testing)
  Future<void> deleteAllTransactions() async {
    AppLogger.database('Deleting all transactions from database');
    final db = await _dbHelper.database;
    await db.delete('transactions');
    AppLogger.database('All transactions deleted');
  }
}
