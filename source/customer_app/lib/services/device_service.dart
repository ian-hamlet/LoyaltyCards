import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared/shared.dart';

/// Service for getting device identification
/// Used for V-005 multi-device duplication detection
class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static String? _cachedDeviceId;

  /// Get a unique identifier for this device
  /// 
  /// iOS: Uses identifierForVendor (unique per app vendor, persists across app reinstalls)
  /// Android: Uses androidId (unique per device + app combination)
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
        final androidInfo = await _deviceInfo.androidInfo;
        // androidId is unique per device + app combination
        identifier = androidInfo.id;
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

  /// Get a user-friendly device name
  /// Returns something like "iPhone 13 Pro" or "Pixel 6"
  static Future<String> getDeviceName() async {
    try {
      if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.utsname.machine ?? 'iOS Device';
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
