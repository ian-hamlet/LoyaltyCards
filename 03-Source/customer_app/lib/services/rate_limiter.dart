import 'package:shared/shared.dart';
import 'database_helper.dart';

/// Service to enforce rate limiting on stamp operations
/// Prevents duplicate stamps and rapid stamping abuse
class RateLimiter {
  final DatabaseHelper _dbHelper;

  RateLimiter(this._dbHelper);

  /// Check if a card can receive a new stamp
  /// 
  /// Both modes: 1 stamp per second (prevents accidental duplicate scans)
  /// 
  /// Note: For multiple purchases (e.g., 2 coffees), customer can scan
  /// repeatedly with 1-second delays between each stamp.
  Future<RateLimitResult> canReceiveStamp({
    required String cardId,
    required String businessId,
    required OperationMode mode,
  }) async {
    final db = await _dbHelper.database;

    // Get the most recent stamp for this card
    final results = await db.query(
      'stamps',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      // No stamps yet, allow first stamp
      return RateLimitResult(canProceed: true);
    }

    // Check timestamp of last stamp
    final lastStampTime = results.first['timestamp'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastStamp = now - lastStampTime;

    // Rate limit: prevents accidental duplicate scans
    final rateLimitMs = AppConstants.stampRateLimitMs;

    if (timeSinceLastStamp < rateLimitMs) {
      final remainingMs = rateLimitMs - timeSinceLastStamp;
      
      return RateLimitResult(
        canProceed: false,
        waitTimeMs: remainingMs,
        message: 'Please wait a moment before getting another stamp',
      );
    }

    return RateLimitResult(canProceed: true);
  }
}

/// Result of rate limit check
class RateLimitResult {
  final bool canProceed;
  final int? waitTimeMs;
  final String? message;

  RateLimitResult({
    required this.canProceed,
    this.waitTimeMs,
    this.message,
  });
}
