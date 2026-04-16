import 'package:sqflite/sqflite.dart';
import 'package:shared/models/card.dart' as models;
import 'package:shared/shared.dart';
import 'database_helper.dart';

/// Repository for managing loyalty cards in the database
/// 
/// ERROR HANDLING PATTERN:
/// All mutation methods (insert, update, delete) return Future<void>:
/// - Throws exceptions on failure (database errors, constraint violations)
/// - Uses assert() for input validation in debug mode
/// - Caller must catch and handle exceptions at UI boundary
/// - Database operations are critical - failures indicate serious problems
/// 
/// Query methods return Future<List<T>> or Future<T?>:
/// - Empty list for no results (not an error)
/// - null for not found (not an error)
/// - Throws exceptions for database errors only
/// 
/// VALIDATION:
/// - Input validation via assert() statements (debug mode only)
/// - Production: Database constraints enforce data integrity
/// - Examples: Non-empty IDs, positive stamp counts, valid ranges
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

  /// Find an existing non-redeemed card with available space for stamps
  /// Returns the card with the MOST stamps if multiple cards exist
  /// Returns null if no cards with available space exist
  Future<models.Card?> findCardWithSpace(String businessId) async {
    AppLogger.database('Searching for cards with available space for business: $businessId');
    
    // Get all cards for this business
    final allCards = await getCardsByBusiness(businessId);
    AppLogger.database('Found ${allCards.length} total cards for business');
    
    // Filter to non-redeemed cards with available space
    final availableCards = allCards.where((card) {
      final hasSpace = !card.isRedeemed && card.stampsCollected < card.stampsRequired;
      if (hasSpace) {
        AppLogger.database('  Card ${card.id}: ${card.stampsCollected}/${card.stampsRequired} stamps, redeemed=${card.isRedeemed}');
      }
      return hasSpace;
    }).toList();
    
    AppLogger.database('Found ${availableCards.length} cards with available space');
    
    // If no cards with space, return null
    if (availableCards.isEmpty) {
      AppLogger.database('No cards with available space found');
      return null;
    }
    
    // Sort by stampsCollected descending (most stamps first)
    availableCards.sort((a, b) => b.stampsCollected.compareTo(a.stampsCollected));
    
    final selectedCard = availableCards.first;
    AppLogger.database('Selected card with most stamps: ${selectedCard.id} (${selectedCard.stampsCollected}/${selectedCard.stampsRequired})');
    
    return selectedCard;
  }
}
