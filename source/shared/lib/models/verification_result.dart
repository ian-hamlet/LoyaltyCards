/// Result of cryptographic signature verification
/// 
/// CR-1.4: Provides detailed failure reasons for better debugging
/// and production issue diagnosis.
/// 
/// Used by CryptoUtils.verifySignature to distinguish:
/// - Invalid public key format
/// - Signature length mismatches
/// - Actual signature verification failures
/// - Exceptions during verification
class VerificationResult {
  /// Whether the signature is valid
  final bool isValid;
  
  /// Reason for failure (null if valid)
  /// 
  /// Common failure reasons:
  /// - 'invalid_public_key': Public key couldn't be decoded
  /// - 'invalid_signature_length: N': Signature not 64 bytes
  /// - 'signature_mismatch': Cryptographic verification failed
  /// - 'verification_error: ExceptionType': Unexpected exception
  final String? failureReason;
  
  /// Create successful verification result
  VerificationResult.success() 
      : isValid = true, 
        failureReason = null;
  
  /// Create failed verification result with reason
  VerificationResult.failure(this.failureReason) : isValid = false;
  
  @override
  String toString() => isValid 
      ? 'Valid' 
      : 'Invalid: $failureReason';
  
  /// Get user-friendly error message
  String get userMessage {
    if (isValid) return 'Signature verified successfully';
    
    switch (failureReason) {
      case 'invalid_public_key':
        return 'Invalid business credentials';
      case 'signature_mismatch':
        return 'Stamp signature verification failed';
      default:
        if (failureReason?.startsWith('invalid_signature_length') ?? false) {
          return 'Malformed stamp signature';
        }
        return 'Signature verification error';
    }
  }
}
