import 'package:sqflite/sqflite.dart';
import 'package:shared/models/card.dart' as models;
import 'package:shared/shared.dart';
import 'database_helper.dart';

/// Repository for managing loyalty cards in the database
/// 
/// ERROR HANDLING PATTERN:
/// All mutation methods (insert, update, delete) return Future<void>:
/// - Throws CardValidationException on invalid input (works in ALL builds)
/// - Throws DatabaseConstraintException on database constraint violations
/// - Caller must catch and handle exceptions at UI boundary
/// - Database operations are critical - failures indicate serious problems
/// 
/// Query methods return Future<List<T>> or Future<T?>:
/// - Empty list for no results (not an error)
/// - null for not found (not an error)
/// - Throws exceptions for database errors only
/// 
/// VALIDATION:
/// - Runtime validation via _validateCard() helper (works in production builds)
/// - Database constraints provide additional safety layer
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
  ///
  /// Accepts an optional [executor] so this can participate in a shared
  /// `db.transaction()` - see [updateStampCount] for why this matters.
  Future<List<models.Card>> getCardsByBusiness(String businessId, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cards',
      where: 'business_id = ?',
      whereArgs: [businessId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => models.Card.fromJson(map)).toList();
  }

  /// Insert a new card
  ///
  /// Accepts an optional [executor] so this can participate in a shared
  /// `db.transaction()` - see [updateStampCount] for why this matters.
  Future<void> insertCard(models.Card card, {DatabaseExecutor? executor}) async {
    // Runtime validation (works in ALL build modes)
    _validateCard(card);

    final db = executor ?? await _dbHelper.database;

    try {
      await db.insert(
        'cards',
        card.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on DatabaseException catch (e) {
      // Check error message since DatabaseException doesn't have type-checking methods
      if (e.toString().contains('UNIQUE constraint')) {
        throw DatabaseConstraintException(
          'Card with ID ${card.id} already exists',
          cause: e,
        );
      }
      if (e.toString().contains('FOREIGN KEY constraint')) {
        throw DatabaseConstraintException(
          'Business not found: ${card.businessId}',
          cause: e,
        );
      }
      rethrow;
    }
  }

  /// Update an existing card
  ///
  /// Accepts an optional [executor] (same pattern as [updateStampCount])
  /// so a profile-snapshot update (Requirements/DISCUSSION_Business_Field_Editing.md
  /// §4.1) can be folded into the same atomic transaction as the stamp
  /// credit it rides alongside, instead of being a separate write.
  Future<void> updateCard(models.Card card, {DatabaseExecutor? executor}) async {
    // Runtime validation (works in ALL build modes)
    _validateCard(card);

    final db = executor ?? await _dbHelper.database;

    try {
      await db.update(
        'cards',
        card.toJson(),
        where: 'id = ?',
        whereArgs: [card.id],
      );
    } on DatabaseException catch (e) {
      // Check error message since DatabaseException doesn't have type-checking methods
      if (e.toString().contains('FOREIGN KEY constraint')) {
        throw DatabaseConstraintException(
          'Business not found: ${card.businessId}',
          cause: e,
        );
      }
      rethrow;
    }
  }

  /// Update stamp count for a card
  ///
  /// Q-003: accepts an optional [executor] (a `Transaction` from
  /// `db.transaction()`) so this can be the final step of an atomic stamp
  /// credit alongside the stamp insert and transaction log. Defaults to a
  /// plain connection when not provided.
  Future<void> updateStampCount(String cardId, int newCount, {DatabaseExecutor? executor}) async {
    final db = executor ?? await _dbHelper.database;
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
  ///
  /// Accepts an optional [executor] so this can participate in a shared
  /// `db.transaction()` - see [updateStampCount] for why this matters.
  Future<models.Card?> findCardWithSpace(String businessId, {String? excludeCardId, DatabaseExecutor? executor}) async {
    AppLogger.database('Searching for cards with available space for business: $businessId');

    // Get all cards for this business
    final allCards = await getCardsByBusiness(businessId, executor: executor);
    AppLogger.database('Found ${allCards.length} total cards for business');

    // Filter to non-redeemed cards with available space, excluding the
    // caller's own card (e.g. the one currently being marked complete -
    // it still shows space here because this read happens before that
    // update, and matching itself would overwrite its own new count).
    final availableCards = allCards.where((card) {
      if (card.id == excludeCardId) return false;
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

  /// Validate card data before insert/update
  /// Throws CardValidationException if invalid
  /// Works in ALL build modes (debug/release/profile)
  void _validateCard(models.Card card) {
    if (card.id.isEmpty) {
      throw CardValidationException('Card ID must not be empty');
    }
    
    if (card.businessId.isEmpty) {
      throw CardValidationException('Business ID must not be empty');
    }
    
    if (card.businessName.isEmpty) {
      throw CardValidationException('Business name must not be empty');
    }
    
    if (card.stampsRequired <= 0) {
      throw CardValidationException(
        'Stamps required must be positive, got: ${card.stampsRequired}'
      );
    }
    
    if (card.stampsRequired > AppConstants.stampsRequiredHardCeiling) {
      throw CardValidationException(
        'Stamps required must be <= ${AppConstants.stampsRequiredHardCeiling}, got: ${card.stampsRequired}'
      );
    }
    
    if (card.stampsCollected < 0) {
      throw CardValidationException(
        'Stamps collected must be non-negative, got: ${card.stampsCollected}'
      );
    }
    
    if (card.stampsCollected > card.stampsRequired) {
      throw CardValidationException(
        'Stamps collected (${card.stampsCollected}) cannot exceed required (${card.stampsRequired})'
      );
    }
  }
}
