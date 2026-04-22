import 'package:shared/shared.dart';

/// Service for verifying cryptographic signatures
/// Customer app only needs verification, not signing
/// 
/// Note: Uses shared CryptoUtils for signature verification
class KeyManager {
  /// Verify signature with public key using ECDSA
  /// 
  /// CR-1.4: Returns VerificationResult with detailed failure reasons
  /// Delegates to shared CryptoUtils.verifySignature for consistency
  /// across customer and supplier apps
  static VerificationResult verifySignature(String data, String signatureBase64, String publicKeyEncoded) {
    return CryptoUtils.verifySignature(
      data: data,
      signatureBase64: signatureBase64,
      publicKeyEncoded: publicKeyEncoded,
    );
  }
}

