import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:shared/shared.dart';

/// Service for getting device identification
/// Used for V-005 multi-device duplication detection
class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String? _cachedDeviceId;

  static const String _androidInstallIdKey = 'device_service_android_install_id';

  /// Get a unique identifier for this device
  ///
  /// iOS: Uses identifierForVendor (unique per app vendor, persists across app reinstalls)
  /// Android: a random UUID generated on first run and persisted locally. There's no
  /// equivalent to identifierForVendor available here: `ANDROID_ID` access has since been
  /// restricted for privacy reasons (device_info_plus no longer exposes it at all), and
  /// `Build.ID` (what this used to read) is a per-OS-build tag shared by every device on
  /// the same firmware image - not per-device - which silently broke the V-005 mismatch
  /// check for any two Android devices on identical firmware.
  ///
  /// Returns a shortened hash for privacy (first 12 chars of SHA256)
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      String identifier;

      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // identifierForVendor is unique per vendor, persists across reinstalls
        identifier = iosInfo.identifierForVendor ?? 'unknown-ios-${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isAndroid) {
        identifier = await getOrCreateAndroidInstallId();
      } else {
        // Fallback for other platforms (macOS, Windows, Linux, Web)
        identifier = 'unknown-platform-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Hash and truncate for privacy (12 chars is enough for collision avoidance)
      final bytes = utf8.encode(identifier);
      final digest = sha256.convert(bytes);
      final hash = digest.toString();
      _cachedDeviceId = hash.substring(0, 12);
      
      AppLogger.debug('Device ID: $_cachedDeviceId');
      return _cachedDeviceId!;
    } catch (e) {
      AppLogger.error('Error getting device ID: $e');
      // Fallback to timestamp-based ID
      final fallbackId = 'fallback-${DateTime.now().millisecondsSinceEpoch}';
      final bytes = utf8.encode(fallbackId);
      final digest = sha256.convert(bytes);
      final hash = digest.toString();
      _cachedDeviceId = hash.substring(0, 12);
      return _cachedDeviceId!;
    }
  }

  /// Reads the persisted per-install Android identifier, generating and
  /// storing one on first call. Deliberately not itself gated on
  /// `Platform.isAndroid` (only [getDeviceId] cares which platform it's
  /// running on) - that's what lets device_service_test.dart exercise this
  /// directly, since `flutter test` always runs as the host platform and
  /// can't fake `Platform.isAndroid` being true.
  @visibleForTesting
  static Future<String> getOrCreateAndroidInstallId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_androidInstallIdKey);
    if (existing != null) {
      return existing;
    }
    final generated = const Uuid().v4();
    await prefs.setString(_androidInstallIdKey, generated);
    return generated;
  }

  /// Get a user-friendly device name
  /// Returns something like "iPhone 13 Pro" or "Pixel 6"
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.utsname.machine;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      AppLogger.error('Error getting device name: $e');
      return 'Unknown Device';
    }
  }

  /// Clear cached device ID (for testing purposes)
  static void clearCache() {
    _cachedDeviceId = null;
  }
}
