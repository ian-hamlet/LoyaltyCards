/// Error Handling Utilities and Conventions
/// 
/// This file documents the error handling patterns used throughout the LoyaltyCards app
/// and provides helper utilities for consistent error handling.
/// 
/// CONVENTIONS:
/// 
/// 1. Future<bool> - Optional/graceful operations
///    - Used for: Backup operations, optional features, non-critical actions
///    - Returns true on success, false on failure
///    - Always logs failures via AppLogger.error()
///    - Example: BackupStorageService.saveToPhotos()
/// 
/// 2. Future<void> - Critical operations that must succeed
///    - Used for: Database writes, essential state changes
///    - Throws exceptions on failure
///    - Caller must catch and handle
///    - Example: CardRepository.insertCard()
/// 
/// 3. bool - Synchronous validation
///    - Used for: Data validation, signature verification, QR parsing
///    - Returns true if valid, false if invalid
///    - Silent failures (no logging needed - validation failures are normal)
///    - Example: CryptoUtils.verifySignature()
/// 
/// 4. Exceptions - Exceptional conditions only
///    - Used for: Programming errors, invalid state, unrecoverable errors
///    - Should NOT be used for normal control flow
///    - Caught at UI boundary and shown to user
/// 
/// GUIDELINES:
/// 
/// - Choose Future<bool> when failure is acceptable and expected
/// - Choose Future<void> + exceptions when failure indicates a serious problem
/// - Choose bool for pure validation functions
/// - Always provide context in error messages ("Backup to photos failed" not "Operation failed")
/// - Log all exceptions with stack traces for debugging

import 'package:shared/shared.dart';

/// Helper to safely execute an async operation that can fail
/// Returns true on success, false on failure (with logging)
/// 
/// Example:
/// ```dart
/// final success = await safeExecute(
///   () => backupService.save(data),
///   context: 'Backup to photos',
/// );
/// ```
Future<bool> safeExecute(
  Future<void> Function() operation, {
  required String context,
  String? tag,
}) async {
  try {
    await operation();
    AppLogger.debug('$context completed successfully', tag ?? 'SafeExecute');
    return true;
  } catch (e, stackTrace) {
    AppLogger.error('$context failed: $e', tag: tag ?? 'SafeExecute');
    AppLogger.error('Stack trace: $stackTrace', tag: tag ?? 'SafeExecute');
    return false;
  }
}

/// Helper to safely execute a synchronous operation that can fail
/// Returns true on success, false on failure (with logging)
/// 
/// Example:
/// ```dart
/// final success = safeExecuteSync(
///   () => validator.validate(data),
///   context: 'Data validation',
/// );
/// ```
bool safeExecuteSync(
  void Function() operation, {
  required String context,
  String? tag,
}) {
  try {
    operation();
    AppLogger.debug('$context completed successfully', tag ?? 'SafeExecute');
    return true;
  } catch (e, stackTrace) {
    AppLogger.error('$context failed: $e', tag: tag ?? 'SafeExecute');
    AppLogger.error('Stack trace: $stackTrace', tag: tag ?? 'SafeExecute');
    return false;
  }
}

/// Helper to execute with a result value
/// Returns the result on success, null on failure (with logging)
/// 
/// Example:
/// ```dart
/// final card = await safeExecuteWithResult(
///   () => repository.getCard(id),
///   context: 'Load card',
/// );
/// if (card == null) {
///   // Handle error
/// }
/// ```
Future<T?> safeExecuteWithResult<T>(
  Future<T> Function() operation, {
  required String context,
  String? tag,
}) async {
  try {
    final result = await operation();
    AppLogger.debug('$context completed successfully', tag ?? 'SafeExecute');
    return result;
  } catch (e, stackTrace) {
    AppLogger.error('$context failed: $e', tag: tag ?? 'SafeExecute');
    AppLogger.error('Stack trace: $stackTrace', tag: tag ?? 'SafeExecute');
    return null;
  }
}
