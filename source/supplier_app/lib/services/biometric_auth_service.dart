import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared/shared.dart';
import '../models/biometric_auth_result.dart';

/// Service for handling biometric authentication (Face ID, Touch ID, Passcode)
/// Used to protect sensitive operations like viewing private keys and backup QR codes
/// 
/// FIX HIGH-2: Returns structured BiometricAuthResult with specific failure reasons
/// instead of generic bool, allowing callers to provide appropriate feedback
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
  /// FIX HIGH-2: Returns BiometricAuthResult with specific failure reason
  /// instead of generic bool
  /// 
  /// [reason] - Message to show to user explaining why authentication is needed
  /// [useErrorDialogs] - Whether to show error dialogs (default: true)
  /// [stickyAuth] - Whether to keep authentication sticky (default: false)
  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      AppLogger.debug('Requesting biometric authentication...', 'BiometricAuth');
      
      // Check if available first
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        AppLogger.warning('Biometric auth not available on device', 'BiometricAuth');
        return const BiometricAuthResult.notAvailable();
      }
      
      final bool isAuthenticated = await _auth.authenticate(
        localizedReason: reason,
      );

      if (isAuthenticated) {
        AppLogger.debug('✅ Authentication successful', 'BiometricAuth');
        return const BiometricAuthResult.success();
      } else {
        AppLogger.debug('❌ Authentication failed or cancelled', 'BiometricAuth');
        return const BiometricAuthResult.cancelled();
      }
    } on PlatformException catch (e) {
      AppLogger.error('Platform exception during authentication: ${e.code}', error: e, tag: 'BiometricAuth');
      
      // Parse specific error codes from local_auth package
      // Note: local_auth 3.0+ removed error_codes, using string matching instead
      switch (e.code) {
        case 'NotAvailable':
        case 'notAvailable':
          return const BiometricAuthResult.notAvailable('Biometric authentication is not available');
        case 'NotEnrolled':
        case 'notEnrolled':
        case 'PasscodeNotSet':
        case 'passcodeNotSet':
          return const BiometricAuthResult.notEnrolled();
        case 'PermanentlyLockedOut':
        case 'permanentlyLockedOut':
          return BiometricAuthResult.platformError(e, 'Too many failed attempts. Please try again later.');
        case 'LockedOut':
        case 'lockedOut':
          return BiometricAuthResult.platformError(e, 'Temporarily locked. Please try again later.');
        default:
          return BiometricAuthResult.platformError(e, 'Authentication error: ${e.message}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected authentication error', error: e, stackTrace: stackTrace, tag: 'BiometricAuth');
      return BiometricAuthResult.platformError(e, 'Unexpected error during authentication');
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
