import 'package:shared/shared.dart';

/// Result of a backup operation
/// 
/// HP-1: Replaced Future<bool> pattern with detailed result object
/// This provides specific error context instead of silently losing information.
/// 
/// Pattern matches VerificationResult (praised in code review as exemplary)
class BackupResult {
  final bool isSuccess;
  final BackupFailureReason? failureReason;
  final String? message;

  BackupResult.success()
      : isSuccess = true,
        failureReason = null,
        message = null;

  BackupResult.failure(this.failureReason, this.message) : isSuccess = false;
  
  /// Get user-friendly message for display
  String getUserMessage() {
    if (isSuccess) return 'Backup saved successfully';
    
    if (failureReason != null) {
      switch (failureReason!) {
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
          return message ?? 'Backup failed';
      }
    }
    
    return message ?? 'Backup failed';
  }
}
