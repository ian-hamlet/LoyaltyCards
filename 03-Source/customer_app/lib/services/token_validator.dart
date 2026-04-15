import 'package:shared/shared.dart';
import '../services/key_manager.dart';

/// Service to validate QR tokens and stamps received from suppliers
class TokenValidator {
  /// Validate a Card Issue Token
  /// Checks token structure and signature validity
  /// 
  /// For simple mode: Skips timestamp validation (tokens are reusable)
  /// For secure mode: Enforces 5-minute expiry
  static Future<ValidationResult> validateCardIssueToken(
    CardIssueToken token,
  ) async {
    // Check basic structure
    if (!token.isValid()) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid token structure',
      );
    }

    // Simple mode: Skip timestamp check (tokens are reusable/static)
    if (token.mode == OperationMode.simple) {
      AppLogger.debug('Simple mode: Skipping timestamp validation (reusable token)', 'Token');
      // Still verify signature for simple mode
      try {
        final signatureData = token.getSignatureData();
        final isSignatureValid = KeyManager.verifySignature(
          signatureData,
          token.signature,
          token.publicKey,
        );

        if (!isSignatureValid) {
          return ValidationResult(
            isValid: false,
            error: 'Invalid signature',
          );
        }

        return ValidationResult(isValid: true);
      } catch (e) {
        return ValidationResult(
          isValid: false,
          error: 'Signature verification failed: $e',
        );
      }
    }

    // Secure mode: Check timestamp (reject tokens older than 5 minutes)
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - token.timestamp;
    if (age > 5 * 60 * 1000) {
      return ValidationResult(
        isValid: false,
        error: 'Token expired (older than 5 minutes)',
      );
    }

    // Verify signature
    try {
      final signatureData = token.getSignatureData();
      final isSignatureValid = KeyManager.verifySignature(
        signatureData,
        token.signature,
        token.publicKey,
      );

      if (!isSignatureValid) {
        return ValidationResult(
          isValid: false,
          error: 'Invalid signature',
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Signature verification failed: $e',
      );
    }
  }

  /// Validate a Stamp Token
  /// Checks token structure, signature, and previous hash chain
  /// 
  /// For simple mode: Skips timestamp validation (tokens are reusable)
  /// For secure mode: Enforces 2-minute expiry
  static Future<ValidationResult> validateStampToken({
    required StampToken token,
    required String businessPublicKey,
    required String expectedPreviousHash,
    required OperationMode mode,
  }) async {
    // Check basic structure
    if (!token.isValid()) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid token structure',
      );
    }

    // Simple mode: Skip timestamp check (tokens are reusable/static)
    // Secure mode: Check timestamp (reject stamps older than 2 minutes)
    if (mode == OperationMode.secure) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - token.timestamp;
      if (age > 2 * 60 * 1000) {
        return ValidationResult(
          isValid: false,
          error: 'Stamp expired (older than 2 minutes)',
        );
      }
    } else {
      AppLogger.debug('Simple mode: Skipping timestamp validation (reusable token)', 'Token');
    }

    // Verify previous hash chain
    if (token.previousHash != expectedPreviousHash) {
      // Debug: Log the mismatch details
      AppLogger.warning(
        'Hash mismatch - Token previousHash: "${token.previousHash}", '
        'Expected: "$expectedPreviousHash", '
        'Stamp: ${token.stampNumber}',
        'Token'
      );
      
      return ValidationResult(
        isValid: false,
        error: 'Previous hash mismatch - stamp chain broken',
      );
    }

    // Verify signature
    try {
      final signatureData = token.getSignatureData();
      final isSignatureValid = KeyManager.verifySignature(
        signatureData,
        token.signature,
        businessPublicKey,
      );

      if (!isSignatureValid) {
        return ValidationResult(
          isValid: false,
          error: 'Invalid signature',
        );
      }

      return ValidationResult(isValid: true);
    } catch (e) {
      return ValidationResult(
        isValid: false,
        error: 'Signature verification failed: $e',
      );
    }
  }

  /// Validate a Stamp Request Token (supplier side)
  static ValidationResult validateStampRequest(
    CardStampRequestToken token,
    String expectedBusinessId,
  ) {
    // Check basic structure
    if (!token.isValid()) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid token structure',
      );
    }

    // Check business ID matches
    if (token.businessId != expectedBusinessId) {
      return ValidationResult(
        isValid: false,
        error: 'Card belongs to different business',
      );
    }

    // Check timestamp (reject requests older than 1 minute)
    final now = DateTime.now().millisecondsSinceEpoch;
    final age = now - token.timestamp;
    if (age > 60 * 1000) {
      return ValidationResult(
        isValid: false,
        error: 'Request expired (older than 1 minute)',
      );
    }

    return ValidationResult(isValid: true);
  }

  /// Validate a Redemption Request Token (supplier side)
  static Future<ValidationResult> validateRedemptionRequest({
    required RedemptionRequestToken token,
    required String expectedBusinessId,
    required String businessPublicKey,
    required List<Stamp> stamps,
  }) async {
    // Check basic structure
    if (!token.isValid()) {
      return ValidationResult(
        isValid: false,
        error: 'Invalid token structure',
      );
    }

    // Check business ID matches
    if (token.businessId != expectedBusinessId) {
      return ValidationResult(
        isValid: false,
        error: 'Card belongs to different business',
      );
    }

    // Check stamp count matches
    if (stamps.length != token.stampsCollected) {
      return ValidationResult(
        isValid: false,
        error: 'Stamp count mismatch',
      );
    }

    // Verify all stamp signatures
    for (int i = 0; i < stamps.length; i++) {
      final stamp = stamps[i];
      final expectedPrevHash = i > 0 ? stamps[i - 1].signature : '';
      
      final signatureData = '${token.cardId}:${i + 1}:${stamp.timestamp}:$expectedPrevHash';
      final isValid = KeyManager.verifySignature(
        signatureData,
        stamp.signature,
        businessPublicKey,
      );

      if (!isValid) {
        return ValidationResult(
          isValid: false,
          error: 'Invalid signature on stamp ${i + 1}',
        );
      }
    }

    return ValidationResult(isValid: true);
  }
}

/// Result of token validation
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({
    required this.isValid,
    this.error,
  });
}
