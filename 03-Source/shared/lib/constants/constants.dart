import 'dart:ui';

/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // Application Info
  static const String appName = 'LoyaltyCards';
  static const String customerAppName = 'LoyaltyCards';
  static const String supplierAppName = 'Configure Your Customer Loyalty Cards';
  
  // Version
  static const String version = '0.1.0';
  
  // Defaults
  static const int defaultStampsRequired = 10;
  static const String defaultBrandColor = '#673AB7'; // Deep Purple
  
  // Database
  static const String databaseName = 'loyalty_cards.db';
  static const int databaseVersion = 5;
  
  // QR Code Settings
  static const int qrCodeSize = 300;
  static const double qrCodePadding = 16.0;
  
  // UI Constraints
  static const double cardAspectRatio = 1.586; // Credit card ratio (85.60 × 53.98 mm)
  static const double cardBorderRadius = 16.0;
  static const double cardElevation = 2.0;
  
  // Timing
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration qrScanSuccessDelay = Duration(milliseconds: 500);
}

/// Typography scale for consistent text sizing
class AppTypography {
  AppTypography._();

  // Display
  static const double displayLarge = 28.0;   // Card titles
  static const double displayMedium = 24.0;  // Section headers
  static const double displaySmall = 20.0;   // Subsection headers
  
  // Title
  static const double titleLarge = 18.0;     // AppBar titles
  static const double titleMedium = 16.0;    // Card titles
  static const double titleSmall = 15.0;     // List item titles
  
  // Body
  static const double bodyLarge = 14.0;      // Primary content
  static const double bodyMedium = 13.0;     // Secondary content
  static const double bodySmall = 12.0;      // Tertiary content
  
  // Label
  static const double labelLarge = 13.0;     // Important labels
  static const double labelMedium = 12.0;    // Standard labels
  static const double labelSmall = 11.0;     // Minor labels
}

/// Spacing scale for consistent layout
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;    // Minimal spacing
  static const double sm = 8.0;    // Small spacing
  static const double md = 16.0;   // Medium spacing (DEFAULT)
  static const double lg = 24.0;   // Large spacing
  static const double xl = 32.0;   // Extra large spacing
  static const double xxl = 48.0;  // Huge spacing
}

/// Brand color palette
class BrandColors {
  BrandColors._();

  // Primary Colors
  static const Color primary = Color(0xFF673AB7); // Deep Purple
  static const Color secondary = Color(0xFF9C27B0); // Purple
  static const Color accent = Color(0xFFE91E63); // Pink
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50); // Green
  static const Color error = Color(0xFFF44336); // Red
  static const Color warning = Color(0xFFFF9800); // Orange
  static const Color info = Color(0xFF2196F3); // Blue
  
  // Neutral Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFBDBDBD);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  
  // Container Colors (light variants for backgrounds)
  static const Color primaryContainer = Color(0xFFEDE7F6);   // Light purple
  static const Color successContainer = Color(0xFFE8F5E9);   // Light green
  static const Color errorContainer = Color(0xFFFFEBEE);     // Light red
  static const Color warningContainer = Color(0xFFFFF3E0);   // Light orange
  static const Color infoContainer = Color(0xFFE3F2FD);      // Light blue
  
  // Predefined card colors for businesses
  static const List<String> cardColorOptions = [
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#009688', // Teal
    '#4CAF50', // Green
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#795548', // Brown
  ];
  
  /// Convert hex string to Color
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
  
  /// Convert Color to hex string
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

/// UI text constants
class AppStrings {
  AppStrings._();

  // Customer App
  static const String customerWelcome = 'Your Digital Wallet';
  static const String customerNoCards = 'No cards yet';
  static const String customerNoCardsHint = 'Scan a QR code from a supplier to add your first loyalty card';
  static const String customerAddCard = 'Add Card';
  static const String customerScanQr = 'Scan Supplier QR Code';
  
  // Supplier App
  static const String supplierWelcome = 'Business Dashboard';
  static const String supplierIssueCard = 'Issue Card';
  static const String supplierStampCard = 'Add Stamp';
  static const String supplierRedeemCard = 'Redeem Card';
  static const String supplierSettings = 'Settings';
  
  // Common
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String delete = 'Delete';
  static const String save = 'Save';
  static const String error = 'Error';
  static const String success = 'Success';
  
  // Stamps
  static const String stampsCollected = 'stamps collected';
  static const String stampComplete = 'Card Complete!';
  static const String stampReadyToRedeem = 'Ready to redeem your reward';
}
