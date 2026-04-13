import 'package:flutter/material.dart';

/// Utility class for calculating optimal QR code size
/// Ensures consistent sizing across all screens and apps
class QRCodeSize {
  /// Calculate optimal QR code size based on screen dimensions
  /// 
  /// Portrait: 65% of screen width
  /// Landscape: 40% of screen height
  /// Clamped between 200-300px for optimal scannability
  static double calculate(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;
    
    double size;
    
    if (isPortrait) {
      // Portrait: 65% of screen width
      size = screenWidth * 0.65;
    } else {
      // Landscape: 40% of screen height (more constrained vertically)
      size = screenHeight * 0.40;
    }
    
    // Clamp between min and max for optimal scanning
    return size.clamp(200.0, 300.0);
  }
  
  /// Minimum recommended QR code size (pixels)
  static const double minSize = 200.0;
  
  /// Maximum recommended QR code size (pixels)
  static const double maxSize = 300.0;
}
