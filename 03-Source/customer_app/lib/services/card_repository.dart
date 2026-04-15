import 'package:sqflite/sqflite.dart';
import 'package:shared/models/card.dart' as models;
import 'package:shared/shared.dart';
import 'database_helper.dart';

/// Repository for managing loyalty cards in the database
class CardRepository {
  final DatabaseHelper _dbHelper;

  CardRepository(this._dbHelper);

  /// Get all cards from database
  Future<List<models.Card>> getAllCards() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => models.Card.fromJson(map)).toList();
  }

  /// Get a specific card by ID
  Future<models.Card?> getCardById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return models.Card.fromJson(maps.first);
  }

  /// Get all cards for a specific business
  Future<List<models.Card>> getCardsByBusiness(String businessId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => models.Card.fromJson(map)).toList();
  }

  /// Insert a new card
  Future<void> insertCard(models.Card card) async {
    // Input validation
    assert(card.id.isNotEmpty, 'Card ID must not be empty');
    assert(card.businessId.isNotEmpty, 'Business ID must not be empty');
    assert(card.businessName.isNotEmpty, 'Business name must not be empty');
    assert(card.stampsRequired > 0, 'Stamps required must be positive');
    assert(card.stampsRequired <= 100, 'Stamps required must be <= 100');
    assert(card.stampsCollected >= 0, 'Stamps collected must be non-negative');
    assert(card.stampsCollected <= card.stampsRequired, 
      'Stamps collected cannot exceed stamps required');
    
    final db = await _dbHelper.database;
    await db.insert(
      'cards',
      card.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update an existing card
  Future<void> updateCard(models.Card card) async {
    // Input validation
    assert(card.id.isNotEmpty, 'Card ID must not be empty');
    assert(card.businessId.isNotEmpty, 'Business ID must not be empty');
    assert(card.businessName.isNotEmpty, 'Business name must not be empty');
    assert(card.stampsRequired > 0, 'Stamps required must be positive');
    assert(card.stampsRequired <= 100, 'Stamps required must be <= 100');
    assert(card.stampsCollected >= 0, 'Stamps collected must be non-negative');
    assert(card.stampsCollected <= card.stampsRequired, 
      'Stamps collected cannot exceed stamps required');
    
    final db = await _dbHelper.database;
    await db.update(
      'cards',
      card.toJson(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  /// Update stamp count for a card
  Future<void> updateStampCount(String cardId, int newCount) async {
    final db = await _dbHelper.database;
    await db.update(
      'cards',
      {
        'stamps_collected': newCount,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }

  /// Delete a card (and all related stamps/transactions via CASCADE)
  Future<void> deleteCard(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Check if a card exists
  Future<bool> cardExists(String id) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cards WHERE id = ?', [id]),
    );
    return (count ?? 0) > 0;
  }

  /// Get count of all cards
  Future<int> getCardCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cards'),
    );
    return count ?? 0;
  }

  /// Get count of completed cards
  Future<int> getCompletedCardCount() async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM cards WHERE stamps_collected >= stamps_required',
      ),
    );
    return count ?? 0;
  }

  /// Delete all cards (for testing)
  Future<void> deleteAllCards() async {
    AppLogger.database('Deleting all cards from database');
    final db = await _dbHelper.database;
    await db.delete('cards');
    AppLogger.database('All cards deleted');
  }

  /// Mark a card as redeemed (prevents double redemption)
  Future<void> markCardAsRedeemed(String cardId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'cards',
      {
        'is_redeemed': 1,
        'redeemed_at': now,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [cardId],
    );
  }
}
