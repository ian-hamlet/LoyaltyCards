import 'package:local_auth/local_auth.dart';
import 'package:shared/shared.dart';

/// Service for handling biometric authentication (Face ID, Touch ID, Passcode)
/// Used to protect app access when enabled by user in Settings
class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric authentication is available on this device
  Future<bool> isAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      AppLogger.error('Error checking biometric availability: $e', tag: 'BiometricAuth');
      return false;
    }
  }

  /// Get list of available biometric types (Face ID, Touch ID, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.error('Error getting available biometrics: $e', tag: 'BiometricAuth');
      return [];
    }
  }

  /// Authenticate user with biometrics or device passcode
  /// 
  /// Returns true if authentication successful, false otherwise
  /// 
  /// [reason] - Message to show to user explaining why authentication is needed
  /// [useErrorDialogs] - Whether to show error dialogs (default: true)
  /// [stickyAuth] - Whether to keep authentication sticky (default: false)
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      AppLogger.debug('Requesting biometric authentication...', 'BiometricAuth');
      
      final bool isAuthenticated = await _auth.authenticate(
        localizedReason: reason,
      );

      if (isAuthenticated) {
        AppLogger.debug('✅ Authentication successful', 'BiometricAuth');
      } else {
        AppLogger.debug('❌ Authentication failed or cancelled', 'BiometricAuth');
      }

      return isAuthenticated;
    } catch (e) {
      AppLogger.error('Authentication error: $e', tag: 'BiometricAuth');
      return false;
    }
  }

  /// Stop authentication (useful for dismissing auth dialog)
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (e) {
      AppLogger.error('Error stopping authentication: $e', tag: 'BiometricAuth');
    }
  }

  /// Get user-friendly name for authentication method
  /// Returns "Face ID", "Touch ID", or "Passcode" based on available biometrics
  Future<String> getAuthMethodName() async {
    final biometrics = await getAvailableBiometrics();
    
    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Touch ID';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Iris Scan';
    } else {
      return 'Passcode';
    }
  }
}
