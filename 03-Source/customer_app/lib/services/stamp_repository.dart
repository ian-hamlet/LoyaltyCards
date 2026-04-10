import 'package:sqflite/sqflite.dart';
import 'package:shared/shared.dart';
import 'database_helper.dart';

/// Repository for managing stamps in the database
class StampRepository {
  final DatabaseHelper _dbHelper;

  StampRepository(this._dbHelper);

  /// Get all stamps across all cards
  Future<List<Stamp>> getAllStamps() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stamps',
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => Stamp.fromJson(map)).toList();
  }

  /// Get all stamps for a specific card
  Future<List<Stamp>> getStampsByCard(String cardId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stamps',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'stamp_number ASC',
    );

    return maps.map((map) => Stamp.fromJson(map)).toList();
  }

  /// Get a specific stamp by ID
  Future<Stamp?> getStampById(String id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stamps',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Stamp.fromJson(maps.first);
  }

  /// Get the latest stamp for a card
  Future<Stamp?> getLatestStamp(String cardId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stamps',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'stamp_number DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Stamp.fromJson(maps.first);
  }

  /// Insert a new stamp
  Future<void> insertStamp(Stamp stamp) async {
    final db = await _dbHelper.database;
    await db.insert(
      'stamps',
      stamp.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get stamp count for a card
  Future<int> getStampCount(String cardId) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM stamps WHERE card_id = ?',
        [cardId],
      ),
    );
    return count ?? 0;
  }

  /// Delete all stamps for a card (when redemption happens)
  Future<void> deleteStampsByCard(String cardId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'stamps',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
  }

  /// Delete a specific stamp
  Future<void> deleteStamp(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'stamps',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Check if a stamp exists
  Future<bool> stampExists(String id) async {
    final db = await _dbHelper.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM stamps WHERE id = ?', [id]),
    );
    return (count ?? 0) > 0;
  }

  /// Verify stamp chain integrity
  Future<bool> verifyStampChain(String cardId) async {
    final stamps = await getStampsByCard(cardId);
    
    if (stamps.isEmpty) return true;
    
    // Check that stamp numbers are sequential
    for (int i = 0; i < stamps.length; i++) {
      if (stamps[i].stampNumber != i + 1) {
        return false;
      }
      
      // Check hash chain (if not first stamp)
      if (i > 0 && stamps[i].previousHash == null) {
        return false;
      }
    }
    
    return true;
  }

  /// Delete all stamps (for testing)
  Future<void> deleteAllStamps() async {
    print('StampRepository: Deleting all stamps from database');
    final db = await _dbHelper.database;
    await db.delete('stamps');
    print('StampRepository: All stamps deleted');
  }
}
