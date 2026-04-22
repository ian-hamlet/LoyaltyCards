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
    // Runtime validation (works in production builds)
    if (business.id.isEmpty) {
      throw ArgumentError('Business ID must not be empty');
    }
    if (business.name.isEmpty) {
      throw ArgumentError('Business name must not be empty');
    }
    if (business.publicKey.isEmpty) {
      throw ArgumentError('Public key must not be empty');
    }
    if (business.stampsRequired <= 0) {
      throw ArgumentError('Stamps required must be positive, got: ${business.stampsRequired}');
    }
    if (business.stampsRequired > 100) {
      throw ArgumentError('Stamps required must be <= 100, got: ${business.stampsRequired}');
    }
    
    AppLogger.database('Inserting business "${business.name}" (ID: ${business.id})');
    final db = await _dbHelper.database;
    
    try {
      await db.insert(
        'business',
        business.toJson(includePrivateKey: false), // Don't store private key in DB
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      AppLogger.database('Business inserted successfully');
    } on DatabaseException catch (e) {
      AppLogger.error('Failed to insert business: $e');
      rethrow;
    }
  }

  /// Update business configuration
  Future<void> updateBusiness(models.Business business) async {
    // Runtime validation (works in production builds)
    if (business.id.isEmpty) {
      throw ArgumentError('Business ID must not be empty');
    }
    if (business.name.isEmpty) {
      throw ArgumentError('Business name must not be empty');
    }
    if (business.publicKey.isEmpty) {
      throw ArgumentError('Public key must not be empty');
    }
    if (business.stampsRequired <= 0) {
      throw ArgumentError('Stamps required must be positive, got: ${business.stampsRequired}');
    }
    if (business.stampsRequired > 100) {
      throw ArgumentError('Stamps required must be <= 100, got: ${business.stampsRequired}');
    }
    
    final db = await _dbHelper.database;
    
    try {
      await db.update(
        'business',
        business.toJson(includePrivateKey: false),
        where: 'id = ?',
        whereArgs: [business.id],
      );
    } on DatabaseException catch (e) {
      AppLogger.error('Failed to update business: $e');
      rethrow;
    }
  }

  /// Check if business is configured
  Future<bool> hasBusinessConfiguration() async {
    final business = await getBusiness();
    return business != null;
  }

  /// Delete business configuration
  Future<void> deleteBusiness(String id) async {
    AppLogger.database('Deleting business with ID: $id');
    final db = await _dbHelper.database;
    await db.delete(
      'business',
      where: 'id = ?',
      whereArgs: [id],
    );
    AppLogger.database('Business deleted');
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

  /// Get count of unique active cards (cards that have been stamped at least once)
  Future<int> getActiveCardCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(DISTINCT card_id) FROM stamp_history'),
    );
    return count ?? 0;
  }

  /// Log card activity when supplier scans a stamp request
  /// This tracks which cards are actively being used, even if stamp token
  /// generation fails or customer doesn't scan it
  Future<void> logCardActivity(String cardId, String businessId) async {
    final db = await _dbHelper.database;
    // Use timestamp as part of ID to allow multiple activities for same card
    final activityId = '${cardId}_activity_${DateTime.now().millisecondsSinceEpoch}';
    
    await db.insert(
      'stamp_history',
      {
        'id': activityId,
        'card_id': cardId,
        'stamp_number': 0, // 0 indicates activity log, not actual stamp
        'issued_at': DateTime.now().millisecondsSinceEpoch,
        'business_id': businessId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore if duplicate
    );
  }

  /// Log a redemption when customer redeems a completed card
  Future<void> logRedemption({
    required String cardId,
    required int stampsRedeemed,
    required String businessId,
  }) async {
    final db = await _dbHelper.database;
    await db.insert(
      'redemptions',
      {
        'id': '${cardId}_redemption_${DateTime.now().millisecondsSinceEpoch}',
        'card_id': cardId,
        'stamps_redeemed': stampsRedeemed,
        'redeemed_at': DateTime.now().millisecondsSinceEpoch,
        'business_id': businessId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get count of redemptions
  Future<int> getRedemptionCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM redemptions'),
    );
    return count ?? 0;
  }
}
