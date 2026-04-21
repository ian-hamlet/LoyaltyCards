import '../exceptions/qr_generation_exception.dart';

/// Utility for converting exceptions to user-friendly messages
/// 
/// FIX HIGH-3: Maps technical exceptions to actionable user messages
/// instead of showing raw exception text
class ErrorMessageMapper {
  /// Convert any exception to a user-friendly message
  /// 
  /// Handles specific exception types and provides fallback for unknown errors
  static String getUserMessage(Object error, {String? context}) {
    // Check for our custom exceptions first
    if (error is QRGenerationException) {
      return error.getUserMessage();
    }
    
    // Check for database errors
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('sqliteexception') || errorStr.contains('database')) {
      if (errorStr.contains('locked')) {
        return 'Database is busy. Please try again in a moment.';
      }
      if (errorStr.contains('unique constraint')) {
        return 'This record already exists in the database.';
      }
      if (errorStr.contains('foreign key')) {
        return 'Cannot perform this operation due to related data.';
      }
      if (errorStr.contains('not found')) {
        return 'The requested data could not be found.';
      }
      return 'Could not access database. Please restart the app.';
    }
    
    // Check for file system errors
    if (errorStr.contains('filenotfound') || errorStr.contains('no such file')) {
      return 'File not found. Data may have been deleted.';
    }
    
    if (errorStr.contains('permission denied') || errorStr.contains('access denied')) {
      return 'Permission denied. Please check app permissions in Settings.';
    }
    
    // Check for network/QR scanning errors
    if (errorStr.contains('invalid qr') || errorStr.contains('malformed')) {
      return 'Invalid QR code. Please scan a valid LoyaltyCards QR code.';
    }
    
    if (errorStr.contains('expired')) {
      return 'This QR code has expired. Please request a new one.';
    }
    
    if (errorStr.contains('signature')) {
      return 'Security verification failed. QR code may be invalid.';
    }
    
    // Check for import/export errors
    if (errorStr.contains('exception: ')) {
      // Extract message after "Exception: " prefix
      final parts = error.toString().split('Exception: ');
      if (parts.length > 1) {
        return parts[1].trim();
      }
    }
    
    // Check for format errors
    if (errorStr.contains('formatexception') || errorStr.contains('parse')) {
      return 'Data format error. Please try again.';
    }
    
    // Fallback with context
    if (context != null) {
      return 'Unable to $context. Please try again.';
    }
    
    return 'An error occurred. Please try again.';
  }
  
  /// Get user message with operation context
  static String forOperation(Object error, String operation) {
    final baseMessage = getUserMessage(error);
    
    // If the message already mentions the operation, return as-is
    if (baseMessage.toLowerCase().contains(operation.toLowerCase())) {
      return baseMessage;
    }
    
    // For generic messages, add context
    if (baseMessage == 'An error occurred. Please try again.') {
      return 'Could not $operation. Please try again.';
    }
    
    return baseMessage;
  }
  
  /// Check if an error should be logged but not shown to user
  /// (e.g., user cancellations, expected states)
  static bool shouldShowToUser(Object error) {
    final errorStr = error.toString().toLowerCase();
    
    // Don't show cancellation messages
    if (errorStr.contains('cancelled') || errorStr.contains('canceled')) {
      return false;
    }
    
    // Don't show "user closed" type messages
    if (errorStr.contains('user closed') || errorStr.contains('user dismissed')) {
      return false;
    }
    
    return true;
  }
}
