import 'package:shared/shared.dart';
import 'database_helper.dart';

/// Service to enforce rate limiting on stamp operations
/// Prevents duplicate stamps and rapid stamping abuse
class RateLimiter {
  final DatabaseHelper _dbHelper;

  RateLimiter(this._dbHelper);

  /// Check if a card can receive a new stamp
  /// 
  /// Simple mode: 1 stamp per hour per business (trust-based, prevent abuse)
  /// Secure mode: 1 stamp per second (prevent accidental duplicate scans)
  /// 
  /// TODO: Review UX - multiple purchases (e.g., 4 coffees) require 4 separate
  /// scan cycles. Consider adding "Add Multiple Stamps" feature to match
  /// physical card UX where supplier can stamp multiple times instantly.
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

    // Rate limit based on operation mode
    final rateLimitMs = mode == OperationMode.simple
        ? 60 * 60 * 1000  // Simple mode: 1 hour (prevents abuse of static QRs)
        : 1000;            // Secure mode: 1 second (prevents duplicate scans)

    if (timeSinceLastStamp < rateLimitMs) {
      final remainingMs = rateLimitMs - timeSinceLastStamp;
      final remainingMinutes = (remainingMs / (60 * 1000)).ceil();
      
      final message = mode == OperationMode.simple
          ? 'You can get another stamp from this business in $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}'
          : 'Please wait a moment before getting another stamp';

      return RateLimitResult(
        canProceed: false,
        waitTimeMs: remainingMs,
        message: message,
      );
    }

    return RateLimitResult(canProceed: true);
  }

  /// Check if a supplier can issue a stamp to a card
  /// Prevents duplicate processing within short time window
  Future<RateLimitResult> canIssueStamp({
    required String cardId,
  }) async {
    final db = await _dbHelper.database;

    // Get the most recent stamp issuance in the log
    final results = await db.query(
      'stamp_log',
      where: 'card_id = ?',
      whereArgs: [cardId],
      orderBy: 'issued_at DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      // No stamps issued yet, allow
      return RateLimitResult(canProceed: true);
    }

    // Check timestamp of last issuance
    final lastIssueTime = results.first['issued_at'] as int;
    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastIssue = now - lastIssueTime;

    // Prevent duplicate issuance within 30 seconds
    const minIntervalMs = 30 * 1000;

    if (timeSinceLastIssue < minIntervalMs) {
      final remainingMs = minIntervalMs - timeSinceLastIssue;
      final remainingSeconds = (remainingMs / 1000).ceil();

      return RateLimitResult(
        canProceed: false,
        waitTimeMs: remainingMs,
        message: 'Stamp recently issued. Wait $remainingSeconds more seconds',
      );
    }

    return RateLimitResult(canProceed: true);
  }

  /// Record stamp timestamp for rate limiting
  Future<void> recordStampReceived({
    required String cardId,
  }) async {
    // No need to record separately - stamp is already in stamps table
    // This method exists for future analytics or additional tracking
  }

  /// Record stamp issuance for rate limiting
  Future<void> recordStampIssued({
    required String stampLogId,
    required String cardId,
    required int stampNumber,
    required String signature,
  }) async {
    final db = await _dbHelper.database;

    await db.insert(
      'stamp_log',
      {
        'id': stampLogId,
        'card_id': cardId,
        'stamp_number': stampNumber,
        'signature': signature,
        'issued_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
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
