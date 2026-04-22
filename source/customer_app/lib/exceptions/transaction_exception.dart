/// Exception thrown when transaction repository operations fail
/// 
/// FIX ERROR-001: Provides specific error context instead of allowing
/// raw database exceptions to propagate to UI.
class TransactionException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  TransactionException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'TransactionException: $message';

  /// Get user-friendly message for this error
  String getUserMessage() {
    if (originalError.toString().contains('UNIQUE constraint failed')) {
      return 'This transaction has already been recorded.';
    }
    if (originalError.toString().contains('database')) {
      return 'Could not access transaction history. Please try again.';
    }
    return 'An error occurred while saving transaction. Please try again.';
  }
}
