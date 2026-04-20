import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import '../models/verification_result.dart';
import 'app_logger.dart';

/// Shared cryptographic utilities for signature verification
/// 
/// Used by both Customer and Supplier apps to verify ECDSA signatures
/// using secp256r1 (P-256) curve with SHA256 hashing.
/// 
/// ERROR HANDLING PATTERN (CR-1.4):
/// Signature verification returns VerificationResult with detailed failure reasons:
/// - Returns VerificationResult.success() if signature is valid
/// - Returns VerificationResult.failure(reason) with specific failure reason
/// - Enables production debugging and better error messages
/// - Does NOT throw exceptions (validation failures are expected)
/// 
/// Use cases:
/// - QR code signature verification
/// - Stamp chain validation
/// - Public key validation
class CryptoUtils {
  /// Verify ECDSA signature using secp256r1 (P-256) curve with SHA256
  /// 
  /// CR-1.4: Returns detailed verification result instead of boolean
  /// 
  /// Parameters:
  /// - [data]: The original data that was signed (will be UTF-8 encoded)
  /// - [signatureBase64]: Base64-encoded signature bytes
  /// - [publicKeyEncoded]: Base64-encoded public key (custom encoding format)
  /// 
  /// Returns VerificationResult with success/failure and detailed reason
  static VerificationResult verifySignature({
    required String data,
    required String signatureBase64,
    required String publicKeyEncoded,
  }) {
    try {
      // Decode the public key
      final publicKey = _decodePublicKey(publicKeyEncoded);
      if (publicKey == null) {
        AppLogger.error('Failed to decode public key for signature verification');
        return VerificationResult.failure('invalid_public_key');
      }

      // Decode signature from base64
      final signatureBytes = base64Decode(signatureBase64);
      
      // Validate signature length (should be 64 bytes for P-256: 32 bytes r + 32 bytes s)
      // Note: Custom encoding uses 4-byte length headers, so actual size varies
      if (signatureBytes.length < 8) {
        AppLogger.error('Signature too short: ${signatureBytes.length} bytes');
        return VerificationResult.failure(
          'invalid_signature_length: ${signatureBytes.length}'
        );
      }

      // Initialize ECDSA verifier with SHA256
      final signer = ECDSASigner(SHA256Digest());
      signer.init(false, PublicKeyParameter<ECPublicKey>(publicKey));

      // Encode data as UTF-8 bytes
      final dataBytes = utf8.encode(data);

      // Parse signature components (r and s values)
      var offset = 0;
      
      // Validate buffer for r length
      if (offset + 4 > signatureBytes.length) {
        AppLogger.error('Insufficient bytes for r length header');
        return VerificationResult.failure('invalid_signature_format');
      }
      
      final rLength = _decodeLength(signatureBytes, offset);
      offset += 4;
      
      // Validate r bytes
      if (offset + rLength > signatureBytes.length) {
        AppLogger.error('Invalid rLength: $rLength exceeds buffer');
        return VerificationResult.failure('invalid_signature_format');
      }
      
      final rBytes = signatureBytes.sublist(offset, offset + rLength);
      offset += rLength;
      
      // Validate buffer for s length
      if (offset + 4 > signatureBytes.length) {
        AppLogger.error('Insufficient bytes for s length header');
        return VerificationResult.failure('invalid_signature_format');
      }
      
      final sLength = _decodeLength(signatureBytes, offset);
      offset += 4;
      
      // Validate s bytes
      if (offset + sLength > signatureBytes.length) {
        AppLogger.error('Invalid sLength: $sLength exceeds buffer');
        return VerificationResult.failure('invalid_signature_format');
      }
      
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
        return VerificationResult.success();
      } else {
        AppLogger.warning('Signature verification failed - signature mismatch', 'Crypto');
        return VerificationResult.failure('signature_mismatch');
      }
    } catch (e, stack) {
      // Log the failure reason for debugging
      AppLogger.error('Signature verification exception: $e', stackTrace: stack);
      return VerificationResult.failure('verification_error: ${e.runtimeType}');
    }
  }

  /// Decode public key from custom base64-encoded format
  /// 
  /// Format: [x_length (4 bytes)][x_bytes][y_length (4 bytes)][y_bytes]
  /// 
  /// Returns ECPublicKey on success, null on failure
  /// 
  /// CR-1.1: Includes bounds checking to prevent out-of-bounds access
  static ECPublicKey? _decodePublicKey(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      
      // Validate minimum length for headers (CR-1.1: bounds checking)
      if (bytes.length < 8) {
        AppLogger.error('Public key too short: ${bytes.length} bytes');
        return null;
      }
      
      // Read x coordinate
      var offset = 0;
      final xLength = _decodeLength(bytes, offset);
      offset += 4;
      
      // Bounds check for x coordinate (CR-1.1)
      if (offset + xLength > bytes.length) {
        AppLogger.error('Invalid xLength: $xLength exceeds buffer');
        return null;
      }
      
      final xBytes = bytes.sublist(offset, offset + xLength);
      offset += xLength;
      
      // Validate remaining length for y header (CR-1.1)
      if (offset + 4 > bytes.length) {
        AppLogger.error('Insufficient bytes for yLength header');
        return null;
      }
      
      // Read y coordinate
      final yLength = _decodeLength(bytes, offset);
      offset += 4;
      
      // Bounds check for y coordinate (CR-1.1)
      if (offset + yLength > bytes.length) {
        AppLogger.error('Invalid yLength: $yLength exceeds buffer');
        return null;
      }
      
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
