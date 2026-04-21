/// Result of a biometric authentication attempt
/// 
/// FIX HIGH-2: Provides specific failure reasons instead of silent bool
/// Allows UI to show appropriate messages and handle different scenarios
enum BiometricAuthStatus {
  /// Authentication was successful
  success,
  
  /// User explicitly cancelled the authentication
  userCancelled,
  
  /// Biometric authentication not available on device
  notAvailable,
  
  /// User has not enrolled any biometrics (e.g., no Face ID set up)
  notEnrolled,
  
  /// App does not have permission to use biometrics
  permissionDenied,
  
  /// Platform error occurred during authentication
  platformError,
}

/// Result of biometric authentication with detailed status
class BiometricAuthResult {
  final BiometricAuthStatus status;
  final String? errorMessage;
  final Object? originalError;

  const BiometricAuthResult({
    required this.status,
    this.errorMessage,
    this.originalError,
  });

  /// Constructor for successful authentication
  const BiometricAuthResult.success()
      : status = BiometricAuthStatus.success,
        errorMessage = null,
        originalError = null;

  /// Constructor for user cancellation
  const BiometricAuthResult.cancelled()
      : status = BiometricAuthStatus.userCancelled,
        errorMessage = 'User cancelled authentication',
        originalError = null;

  /// Constructor for not available
  const BiometricAuthResult.notAvailable([String? message])
      : status = BiometricAuthStatus.notAvailable,
        errorMessage = message ?? 'Biometric authentication not available',
        originalError = null;

  /// Constructor for not enrolled
  const BiometricAuthResult.notEnrolled()
      : status = BiometricAuthStatus.notEnrolled,
        errorMessage = 'No biometrics enrolled on device',
        originalError = null;

  /// Constructor for permission denied
  const BiometricAuthResult.permissionDenied()
      : status = BiometricAuthStatus.permissionDenied,
        errorMessage = 'Permission denied to use biometric authentication',
        originalError = null;

  /// Constructor for platform error
  BiometricAuthResult.platformError(Object error, [String? message])
      : status = BiometricAuthStatus.platformError,
        errorMessage = message ?? 'Authentication error occurred',
        originalError = error;

  /// Whether authentication was successful
  bool get isSuccess => status == BiometricAuthStatus.success;

  /// Whether authentication failed (any non-success status)
  bool get isFailed => !isSuccess;

  /// Whether user can retry (not a permanent failure)
  bool get canRetry {
    switch (status) {
      case BiometricAuthStatus.success:
        return false;
      case BiometricAuthStatus.userCancelled:
        return true;
      case BiometricAuthStatus.notAvailable:
      case BiometricAuthStatus.notEnrolled:
      case BiometricAuthStatus.permissionDenied:
        return false; // Need to set up biometrics/permissions first
      case BiometricAuthStatus.platformError:
        return true; // Might be transient
    }
  }

  /// Get user-friendly message for this result
  String getUserMessage() {
    switch (status) {
      case BiometricAuthStatus.success:
        return 'Authentication successful';
      case BiometricAuthStatus.userCancelled:
        return 'Authentication cancelled';
      case BiometricAuthStatus.notAvailable:
        return 'Biometric authentication is not available on this device. Please use passcode.';
      case BiometricAuthStatus.notEnrolled:
        return 'No Face ID or Touch ID is set up. Please enable it in Settings or use passcode.';
      case BiometricAuthStatus.permissionDenied:
        return 'Permission denied. Please enable biometric access in Settings.';
      case BiometricAuthStatus.platformError:
        return errorMessage ?? 'Authentication error. Please try again.';
    }
  }

  /// Get actionable guidance for the user
  String? getActionableGuidance() {
    switch (status) {
      case BiometricAuthStatus.success:
      case BiometricAuthStatus.userCancelled:
        return null;
      case BiometricAuthStatus.notAvailable:
        return 'Your device may not support biometric authentication. Use passcode instead.';
      case BiometricAuthStatus.notEnrolled:
        return 'Go to Settings → Face ID & Passcode to set up biometric authentication.';
      case BiometricAuthStatus.permissionDenied:
        return 'Go to Settings → LoyaltyCards to enable biometric access.';
      case BiometricAuthStatus.platformError:
        return canRetry ? 'Try again or restart the app.' : null;
    }
  }

  @override
  String toString() => 'BiometricAuthResult($status${errorMessage != null ? ': $errorMessage' : ''})';
}
