import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'app_logger.dart';

/// Shared cryptographic utilities for signature verification
/// Used by both Customer and Supplier apps to verify ECDSA signatures
class CryptoUtils {
  /// Verify ECDSA signature using secp256r1 (P-256) curve with SHA256
  /// 
  /// Parameters:
  /// - [data]: The original data that was signed (will be UTF-8 encoded)
  /// - [signatureBase64]: Base64-encoded signature bytes
  /// - [publicKeyEncoded]: Base64-encoded public key (custom encoding format)
  /// 
  /// Returns true if signature is valid, false otherwise
  static bool verifySignature({
    required String data,
    required String signatureBase64,
    required String publicKeyEncoded,
  }) {
    try {
      // Decode the public key
      final publicKey = _decodePublicKey(publicKeyEncoded);
      if (publicKey == null) return false;

      // Initialize ECDSA verifier with SHA256
      final signer = ECDSASigner(SHA256Digest());
      signer.init(false, PublicKeyParameter<ECPublicKey>(publicKey));

      // Encode data as UTF-8 bytes
      final dataBytes = utf8.encode(data);
      
      // Decode signature from base64
      final signatureBytes = base64Decode(signatureBase64);

      // Parse signature components (r and s values)
      var offset = 0;
      final rLength = _decodeLength(signatureBytes, offset);
      offset += 4;
      final rBytes = signatureBytes.sublist(offset, offset + rLength);
      offset += rLength;
      
      final sLength = _decodeLength(signatureBytes, offset);
      offset += 4;
      final sBytes = signatureBytes.sublist(offset, offset + sLength);

      // Convert to BigInt
      final r = BigInt.parse(
        rBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16,
      );
      final s = BigInt.parse(
        sBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16,
      );

      final signature = ECSignature(r, s);

      // Verify the signature
      final isValid = signer.verifySignature(Uint8List.fromList(dataBytes), signature);
      
      if (isValid) {
        AppLogger.debug('Signature verification successful', 'Crypto');
      } else {
        AppLogger.warning('Signature verification failed - invalid signature', 'Crypto');
      }
      
      return isValid;
    } catch (e) {
      // Log the failure reason for debugging
      AppLogger.error('Signature verification exception: $e');
      return false;
    }
  }

  /// Decode public key from custom base64-encoded format
  /// 
  /// Format: [x_length (4 bytes)][x_bytes][y_length (4 bytes)][y_bytes]
  /// 
  /// Returns ECPublicKey on success, null on failure
  static ECPublicKey? _decodePublicKey(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      
      // Read x coordinate
      var offset = 0;
      final xLength = _decodeLength(bytes, offset);
      offset += 4;
      final xBytes = bytes.sublist(offset, offset + xLength);
      offset += xLength;
      
      // Read y coordinate
      final yLength = _decodeLength(bytes, offset);
      offset += 4;
      final yBytes = bytes.sublist(offset, offset + yLength);
      
      // Convert to BigInt
      final x = BigInt.parse(
        xBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16,
      );
      final y = BigInt.parse(
        yBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16,
      );
      
      // Create point on secp256r1 curve
      final params = ECCurve_secp256r1();
      final q = params.curve.createPoint(x, y);
      
      AppLogger.debug('Public key decoded successfully', 'Crypto');
      return ECPublicKey(q, params);
    } catch (e) {
      AppLogger.error('Failed to decode public key: $e');
      return null;
    }
  }

  /// Decode 4-byte length field (big-endian)
  static int _decodeLength(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}
