/// Exception thrown when QR token generation fails
/// 
/// FIX HIGH-1: Provides specific error context for QR generation failures
/// instead of allowing raw exceptions to propagate to UI.
class QRGenerationException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  QRGenerationException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'QRGenerationException: $message';

  /// Get user-friendly message for this error
  String getUserMessage() {
    if (message.contains('Card not found')) {
      return 'Card data not found. Please try refreshing.';
    }
    if (message.contains('stamps')) {
      return 'Stamp data incomplete. Please sync and try again.';
    }
    if (message.contains('Invalid')) {
      return 'Card data is invalid. Please contact support.';
    }
    return 'Could not generate QR code. Please try again.';
  }
}
