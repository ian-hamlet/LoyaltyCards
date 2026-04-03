import 'package:sqflite/sqflite.dart';
import 'package:shared/shared.dart';
import 'package:shared/models/business.dart' as models;
import 'supplier_database_helper.dart';

/// Repository for managing business configuration in the database
class BusinessRepository {
  final SupplierDatabaseHelper _dbHelper = SupplierDatabaseHelper();

  /// Get the business configuration (should only be one)
  Future<models.Business?> getBusiness() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('business');

    if (maps.isEmpty) return null;
    return models.Business.fromJson(maps.first);
  }

  /// Insert business configuration
  Future<void> insertBusiness(models.Business business) async {
    final db = await _dbHelper.database;
    await db.insert(
      'business',
      business.toJson(includePrivateKey: false), // Don't store private key in DB
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update business configuration
  Future<void> updateBusiness(models.Business business) async {
    final db = await _dbHelper.database;
    await db.update(
      'business',
      business.toJson(includePrivateKey: false),
      where: 'id = ?',
      whereArgs: [business.id],
    );
  }

  /// Check if business is configured
  Future<bool> hasBusinessConfiguration() async {
    final business = await getBusiness();
    return business != null;
  }

  /// Delete business configuration
  Future<void> deleteBusiness(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'business',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Log an issued card (for analytics)
  Future<void> logIssuedCard(String cardId, String businessId) async {
    final db = await _dbHelper.database;
    await db.insert(
      'issued_cards',
      {
        'id': cardId,
        'business_id': businessId,
        'issued_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Log a stamp issuance (for analytics)
  Future<void> logStampIssued({
    required String stampId,
    required String cardId,
    required int stampNumber,
    required String businessId,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(
      'stamp_history',
      {
        'id': stampId,
        'card_id': cardId,
        'stamp_number': stampNumber,
        'issued_at': DateTime.now().millisecondsSinceEpoch,
        'business_id': businessId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get statistics about issued cards
  Future<int> getIssuedCardCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM issued_cards'),
    );
    return count ?? 0;
  }

  /// Get statistics about issued stamps
  Future<int> getIssuedStampCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM stamp_history'),
    );
    return count ?? 0;
  }
}
