import 'package:shared/shared.dart';
import 'database_helper.dart';

/// Service to enforce rate limiting on stamp operations
/// Prevents duplicate stamps and rapid stamping abuse
/// 
/// In Simple Mode: QR codes don't change, so rate limiting is critical
/// to prevent customers from scanning the same QR multiple times in succession.
/// Camera immediately returns to card screen when rate-limited to prevent
/// easy abuse by waiting on camera screen.
/// 
/// In Secure Mode: Each stamp has unique cryptographic signature, but rate
/// limiting still prevents accidental duplicate scans.
class RateLimiter {
  final DatabaseHelper _dbHelper;

  RateLimiter(this._dbHelper);

  /// Check if a card can receive a new stamp
  /// 
  /// Rate limit: 5 seconds between stamps (prevents duplicate scans and abuse)
  /// REQ-022: Can be overridden by token's scanInterval for supplier-specific rate limits
  /// 
  /// Simple Mode: Critical anti-abuse measure since QR codes don't change.
  ///              When rate-limited, scanner immediately returns to card screen
  ///              to prevent customers from waiting and re-scanning.
  /// 
  /// Secure Mode: Prevents accidental duplicate scans (each stamp is cryptographically unique).
  /// 
  /// Note: For multiple legitimate purchases (e.g., 2 coffees), customer can scan
  /// multiple times with 5-second delays between each stamp.
  Future<RateLimitResult> canReceiveStamp({
    required String cardId,
    required String businessId,
    required OperationMode mode,
    int? scanInterval, // REQ-022: Optional supplier-specific rate limit in ms
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

    // REQ-022: Use token's scanInterval if provided, otherwise use default
    // This allows suppliers to configure their own rate limits (e.g., 30s for simple mode)
    final rateLimitMs = scanInterval ?? AppConstants.stampRateLimitMs;
    
    AppLogger.debug('Rate limit check: timeSince=${timeSinceLastStamp}ms, limit=${rateLimitMs}ms', 'RateLimit');

    if (timeSinceLastStamp < rateLimitMs) {
      final remainingMs = rateLimitMs - timeSinceLastStamp;
      final remainingSeconds = (remainingMs / 1000).ceil();
      
      return RateLimitResult(
        canProceed: false,
        waitTimeMs: remainingMs,
        message: mode == OperationMode.simple
            ? 'Stamp just added. Wait $remainingSeconds seconds before next scan'
            : 'Please wait $remainingSeconds seconds before getting another stamp',
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
