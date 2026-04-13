/// Operation mode for loyalty card system
/// 
/// Determines the security/trust model used for card operations
/// 
/// - Simple: Fast, trust-based stamping with time limits
/// - Secure: Full cryptographic validation (current implementation)

enum OperationMode {
  /// Simple mode: Trust-based stamping with time limits
  /// 
  /// Best for:
  /// - Coffee shops and low-value rewards
  /// - High-trust environments (regulars)
  /// - Speed is critical
  /// - Minimal supplier hardware
  /// 
  /// Features:
  /// - Static QR codes for card issuance
  /// - Time-limited self-stamping
  /// - Visual verification at redemption
  /// - No cryptographic validation
  simple,

  /// Secure mode: Full cryptographic validation
  /// 
  /// Best for:
  /// - High-value rewards
  /// - Lower-trust environments
  /// - Fraud prevention critical
  /// - Supplier has device for each transaction
  /// 
  /// Features:
  /// - Cryptographically signed tokens
  /// - Hash chain validation
  /// - Two-way QR exchange per stamp
  /// - Tamper-proof records
  secure,
}

/// Extension methods for OperationMode
extension OperationModeExtension on OperationMode {
  /// Get user-friendly display name
  String get displayName {
    switch (this) {
      case OperationMode.simple:
        return 'Simple Mode';
      case OperationMode.secure:
        return 'Secure Mode';
    }
  }

  /// Get description for UI
  String get description {
    switch (this) {
      case OperationMode.simple:
        return 'Fast & easy - trust-based stamping';
      case OperationMode.secure:
        return 'Cryptographic validation - maximum security';
    }
  }

  /// Get recommended use cases
  String get recommendedFor {
    switch (this) {
      case OperationMode.simple:
        return 'Recommended for coffee shops, restaurants, and low-value rewards';
      case OperationMode.secure:
        return 'Recommended for gyms, salons, and high-value rewards';
    }
  }

  /// Check if mode requires supplier device for stamping
  bool get requiresSupplierDevice {
    switch (this) {
      case OperationMode.simple:
        return false; // Can use static QR codes
      case OperationMode.secure:
        return true; // Needs device for each transaction
    }
  }

  /// Parse from string (for database/QR storage)
  static OperationMode fromString(String value) {
    switch (value.toLowerCase()) {
      case 'simple':
        return OperationMode.simple;
      case 'secure':
        return OperationMode.secure;
      default:
        return OperationMode.secure; // Safe default
    }
  }

  /// Convert to string for storage
  String toStorageString() {
    return name; // 'simple' or 'secure'
  }
}
