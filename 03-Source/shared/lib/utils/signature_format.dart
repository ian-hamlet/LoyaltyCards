/// Canonical signature data formats for cryptographic operations
/// 
/// This class provides a single source of truth for signature data format strings,
/// ensuring consistency between signature generation and verification across the app.
/// 
/// Any inconsistency in format between generation and verification would completely
/// break the security model, so these formats MUST be used for all signature operations.
class SignatureFormat {
  SignatureFormat._(); // Private constructor to prevent instantiation

  /// Canonical format for stamp signature data
  /// 
  /// Format: `cardId:stampNumber:timestampMs:previousHash`
  /// 
  /// Where:
  /// - `cardId`: Unique card identifier
  /// - `stampNumber`: Sequential stamp number (1-based)
  /// - `timestampMs`: Timestamp in milliseconds since epoch
  /// - `previousHash`: Hash of previous stamp (empty string if none/first stamp)
  /// 
  /// Example: `card_123:5:1713648000000:abc123...`
  static String stampData({
    required String cardId,
    required int stampNumber,
    required int timestampMs,
    String? previousHash,
  }) {
    return '$cardId:$stampNumber:$timestampMs:${previousHash ?? ""}';
  }

  /// Format for card issuance signature (Secure Mode)
  /// 
  /// Format: `businessId:cardId:stampsRequired:mode:publicKey`
  /// 
  /// Where:
  /// - `businessId`: Unique business identifier
  /// - `cardId`: Unique card identifier
  /// - `stampsRequired`: Number of stamps required for redemption
  /// - `mode`: Operation mode (SECURE or SIMPLE)
  /// - `publicKey`: Customer's public key (for secure mode)
  /// 
  /// Example: `biz_456:card_123:10:SECURE:MFkwEwYH...`
  static String cardIssueData({
    required String businessId,
    required String cardId,
    required int stampsRequired,
    required String mode,
    String? publicKey,
  }) {
    return '$businessId:$cardId:$stampsRequired:$mode:${publicKey ?? ""}';
  }

  /// Format for card issuance signature (with business name - legacy/extended)
  /// 
  /// Format: `businessId:businessName:stampsRequired:mode:cardId:publicKey`
  /// 
  /// This is an extended format that includes business name for additional verification.
  /// Used in some token types for backward compatibility.
  /// 
  /// Example: `biz_456:Coffee Shop:10:SECURE:card_123:MFkwEwYH...`
  static String cardIssueDataWithName({
    required String businessId,
    required String businessName,
    required int stampsRequired,
    required String mode,
    String? cardId,
    String? publicKey,
  }) {
    return '$businessId:$businessName:$stampsRequired:$mode:${cardId ?? ""}:${publicKey ?? ""}';
  }

  /// Format for redemption signature
  /// 
  /// Format: `cardId:customerId:businessId:stampsRedeemed:timestampMs`
  /// 
  /// Where:
  /// - `cardId`: Unique card identifier
  /// - `customerId`: Customer identifier (device ID or customer ID)
  /// - `businessId`: Business identifier
  /// - `stampsRedeemed`: Number of stamps being redeemed
  /// - `timestampMs`: Redemption timestamp in milliseconds
  /// 
  /// Example: `card_123:cust_789:biz_456:10:1713648000000`
  static String redemptionData({
    required String cardId,
    required String customerId,
    required String businessId,
    required int stampsRedeemed,
    required int timestampMs,
  }) {
    return '$cardId:$customerId:$businessId:$stampsRedeemed:$timestampMs';
  }
}
