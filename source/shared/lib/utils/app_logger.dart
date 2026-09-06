import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Shared logging utility for both Customer and Supplier apps
/// 
/// Provides structured logging with different levels:
/// - debug: Development/debugging information (only in debug mode)
/// - info: General informational messages
/// - warning: Warning messages
/// - error: Error messages with optional error object and stack trace
/// 
/// In release builds, only warning and error messages are logged
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Don't include method stack trace
      errorMethodCount: 5, // Include stack trace for errors
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  /// Log debug message (only in debug mode)
  static void debug(String message, [String? tag]) {
    final msg = tag != null ? '[$tag] $message' : message;
    _logger.d(msg);
  }

  /// Log informational message
  static void info(String message, [String? tag]) {
    final msg = tag != null ? '[$tag] $message' : message;
    _logger.i(msg);
  }

  /// Log warning message
  static void warning(String message, [String? tag]) {
    final msg = tag != null ? '[$tag] $message' : message;
    _logger.w(msg);
  }

  /// Log error message with optional error object and stack trace
  ///
  /// The [stackTrace] is only included in debug builds. `error`-level calls
  /// stay active in release builds (only the *minimum* logged severity is
  /// gated by kDebugMode, not what an error call includes), and this app
  /// has no remote crash-reporting pipeline - these logs only ever reach
  /// the local OS unified log. A stack trace there is internal-structure
  /// exposure (class/method names) to anyone with brief physical access to
  /// an unlocked device, for debugging value that's mostly theoretical
  /// without an established way to actually collect it from real users.
  /// The error [message] itself (often a caught exception's toString())
  /// still logs in both modes - it's useful support context and reveals
  /// far less.
  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    final msg = tag != null ? '[$tag] $message' : message;
    _logger.e(msg, error: error, stackTrace: kDebugMode ? stackTrace : null);
  }

  /// Log version information (always logged, even in release builds)
  /// 
  /// Use this at app startup to confirm which version is running.
  /// Example: `AppLogger.version('v0.2.0+8')`
  static void version(String version) {
    _logger.i('🚀 App Version: $version');
  }

  /// Log cryptographic operations (key generation, signing, verification)
  /// 
  /// Only logs in debug mode. Use for tracking security-related operations
  /// like key pair generation, signature creation/verification, and encryption.
  /// 
  /// Example: `AppLogger.crypto('Generating ECDSA P-256 key pair')`
  static void crypto(String message) {
    debug(message, 'CRYPTO');
  }

  /// Log database operations (queries, inserts, updates, deletes)
  /// 
  /// Only logs in debug mode. Use for tracking SQLite database operations,
  /// schema migrations, and data persistence operations.
  /// 
  /// Example: `AppLogger.database('Inserting card with ID: abc123')`
  static void database(String message) {
    debug(message, 'DATABASE');
  }

  /// Log QR code operations (generation, scanning, parsing)
  /// 
  /// Only logs in debug mode. Use for tracking QR code lifecycle:
  /// - QR generation (card issuance, stamp tokens, redemption)
  /// - QR scanning (camera detection, decode results)
  /// - QR parsing and validation
  /// 
  /// Example: 
  /// - `AppLogger.qr('Generating redemption QR for card abc123')`
  /// - `AppLogger.qr('Scanned QR data: ${data.substring(0, 50)}...')`
  static void qr(String message) {
    debug(message, 'QR');
  }

  /// Log business logic operations (card issuance, stamping, redemption)
  /// 
  /// Only logs in debug mode. Use for tracking high-level business operations
  /// and workflows like loyalty card issuance, stamp collection, and rewards.
  /// 
  /// Example: `AppLogger.business('Card issued: ${card.businessName}')`
  static void business(String message) {
    debug(message, 'BUSINESS');
  }
}
