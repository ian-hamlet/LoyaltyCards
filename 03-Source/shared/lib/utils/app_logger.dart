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
      printTime: false,
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
  static void error(String message, {dynamic error, StackTrace? stackTrace, String? tag}) {
    final msg = tag != null ? '[$tag] $message' : message;
    _logger.e(msg, error: error, stackTrace: stackTrace);
  }

  /// Log version information (always logged)
  static void version(String version) {
    _logger.i('🚀 App Version: $version');
  }

  /// Log key generation/storage operations
  static void crypto(String message) {
    debug(message, 'CRYPTO');
  }

  /// Log database operations
  static void database(String message) {
    debug(message, 'DATABASE');
  }

  /// Log QR code operations
  static void qr(String message) {
    debug(message, 'QR');
  }

  /// Log business logic operations
  static void business(String message) {
    debug(message, 'BUSINESS');
  }
}
