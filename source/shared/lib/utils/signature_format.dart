/// Canonical signature data formats for cryptographic operations.
///
/// A signing call site and its matching verification call site must build
/// the *exact* same string, or verification silently fails (or, worse,
/// verifies against a weaker string than intended - see V-010/V-011 in
/// docs/quality/VULNERABILITIES.md, both caused by a signed-data format
/// that omitted a field). Centralizing the formats here means there's one
/// place to update, not several hand-duplicated string literals that can
/// drift out of sync.
///
/// (A previous version of this class documented formats that weren't
/// actually used by any signing/verification call site - it was replaced
/// during the 2026-07-25 security review with the two formats genuinely in
/// use, wired into both their signing and verifying call sites.)
class SignatureFormat {
  SignatureFormat._(); // Private constructor to prevent instantiation

  /// Canonical format for a stamp's signed data.
  ///
  /// Used by both StampToken.getSignatureData() (verification) and
  /// QRTokenGenerator.generateStampToken (signing, supplier_app) - keep
  /// both call sites passing this the same arguments.
  ///
  /// stampCount/expiryDate/scanInterval were added in the V-010 fix
  /// (2026-07-25): a single stamp token's stampCount previously wasn't
  /// signed, so tampering it after signing could mint many unverified
  /// stamp rows from one genuine scan.
  static String stampChainData({
    required String cardId,
    required int stampNumber,
    required int timestampMs,
    required String previousHash,
    required int stampCount,
    int? expiryDate,
    int? scanInterval,
  }) {
    return '$cardId:$stampNumber:$timestampMs:$previousHash:$stampCount:${expiryDate ?? ""}:${scanInterval ?? ""}';
  }

  /// Canonical format for a redemption token's signed data.
  ///
  /// Used by both RedemptionToken.getSignatureData() (verification) and
  /// supplier_redeem_card.dart's _showSecureModeRedemptionConfirmation
  /// (signing) - keep both call sites passing this the same arguments.
  static String redemptionTokenData({
    required String cardId,
    required int stampsRedeemed,
    required int timestampMs,
  }) {
    return '$cardId:$stampsRedeemed:$timestampMs';
  }
}
