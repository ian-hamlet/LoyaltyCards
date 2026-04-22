/// Exception thrown when backup operations fail
/// 
/// Provides specific failure reasons to help users understand what went wrong
/// and guide them toward alternative backup methods.
/// 
/// HP-1: Replaced Future<bool> pattern with specific exceptions
/// This allows callers to provide better user guidance based on failure type.
class BackupException implements Exception {
  final String message;
  final BackupFailureReason reason;
  final Object? originalError;
  final StackTrace? stackTrace;

  BackupException(
    this.message,
    this.reason, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'BackupException: $message (${reason.name})';
  
  /// Get user-friendly message for this failure
  String getUserMessage() {
    switch (reason) {
      case BackupFailureReason.permissionDenied:
        return 'Permission denied. Enable storage permissions in Settings.';
      case BackupFailureReason.diskFull:
        return 'Not enough storage space. Free up space and try again.';
      case BackupFailureReason.timeout:
        return 'Operation timed out. Try an alternative backup method.';
      case BackupFailureReason.networkError:
        return 'Network error occurred. Check your connection.';
      case BackupFailureReason.invalidData:
        return 'Invalid backup data. Contact support if this persists.';
      case BackupFailureReason.userCancelled:
        return 'Backup cancelled.';
      case BackupFailureReason.platformNotSupported:
        return 'This backup method is not supported on your device.';
      case BackupFailureReason.unknown:
      default:
        return message;
    }
  }
}

/// Specific reasons why backup operations can fail
enum BackupFailureReason {
  /// User denied storage/photo permissions
  permissionDenied,
  
  /// Device storage is full
  diskFull,
  
  /// Operation exceeded timeout limit
  timeout,
  
  /// Network connectivity issue (for email/cloud)
  networkError,
  
  /// QR data validation failed
  invalidData,
  
  /// User cancelled the operation
  userCancelled,
  
  /// Platform doesn't support this backup method
  platformNotSupported,
  
  /// Unknown or unclassified error
  unknown,
}
