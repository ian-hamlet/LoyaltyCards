import 'package:flutter/services.dart';

/// Service to get exact device orientation from native iOS
class DeviceOrientationService {
  static const platform = MethodChannel('device_orientation');

  /// Get the current device orientation from iOS
  /// Returns: 'portrait', 'portraitUpsideDown', 'landscapeLeft', 'landscapeRight', 'faceUp', 'faceDown', or 'unknown'
  static Future<String> getOrientation() async {
    print('DeviceOrientationService: Starting getOrientation call');
    try {
      print('DeviceOrientationService: Invoking platform method');
      final String result = await platform.invokeMethod('getOrientation');
      print('DeviceOrientationService: Got result from platform: $result');
      return result;
    } on PlatformException catch (e) {
      print('DeviceOrientationService: PlatformException - ${e.code}: ${e.message}');
      return 'unknown';
    } catch (e) {
      print('DeviceOrientationService: Exception - $e');
      return 'unknown';
    }
  }

  /// Determine the quarter turns needed to correct camera orientation
  /// based on the exact device orientation
  static int getQuarterTurnsForOrientation(String orientation) {
    switch (orientation) {
      case 'portrait':
        // Portrait needs -90 degree correction
        return 3; // -90 degrees (or +270)
      case 'portraitUpsideDown':
        // Portrait upside down needs +90 degree correction
        return 1; // +90 degrees
      case 'landscapeLeft':
        // One landscape direction works correctly
        return 0; // No rotation
      case 'landscapeRight':
        // Other landscape is 180 out
        return 2; // 180 degrees
      case 'landscape':
        // Generic landscape fallback - no rotation
        return 0;
      default:
        // Unknown - try no rotation
        return 0;
    }
  }
}
