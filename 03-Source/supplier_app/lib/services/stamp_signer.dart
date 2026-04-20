import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:shared/shared.dart';
import 'key_manager.dart';

/// Service for creating and signing stamp tokens
class StampSigner {
  final KeyManager _keyManager = KeyManager();
  final Uuid _uuid = const Uuid();

  /// Create a signed stamp token
  Future<Stamp> createStamp({
    required String businessId,
    required String cardId,
    required int stampNumber,
    String? previousHash,
  }) async {
    final privateKey = await _keyManager.getPrivateKey(businessId);
    
    if (privateKey == null) {
      throw Exception('Private key not found for business $businessId');
    }

    final timestamp = DateTime.now();
    final stampId = _uuid.v4();

    // Create data to sign using canonical format (CR-2.4)
    final dataToSign = SignatureFormat.stampData(
      cardId: cardId,
      stampNumber: stampNumber,
      timestampMs: timestamp.millisecondsSinceEpoch,
      previousHash: previousHash,
    );
    
    // Sign the data
    final signature = await _keyManager.signData(dataToSign, privateKey);
    
    if (signature == null) {
      throw Exception('Failed to sign stamp data for card $cardId');
    }

    return Stamp(
      id: stampId,
      cardId: cardId,
      stampNumber: stampNumber,
      timestamp: timestamp,
      signature: signature,
      previousHash: previousHash,
    );
  }

  /// Calculate hash of a stamp (for chaining)
  String calculateStampHash(Stamp stamp) {
    final data = '${stamp.id}:${stamp.cardId}:${stamp.stampNumber}:${stamp.timestamp.millisecondsSinceEpoch}:${stamp.signature}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify a stamp's signature (CR-1.4)
  /// 
  /// Returns detailed verification result for better debugging
  Future<VerificationResult> verifyStamp(Stamp stamp, String publicKey) async {
    // Use canonical signature format (CR-2.4)
    final dataToSign = SignatureFormat.stampData(
      cardId: stamp.cardId,
      stampNumber: stamp.stampNumber,
      timestampMs: stamp.timestamp.millisecondsSinceEpoch,
      previousHash: stamp.previousHash,
    );
    return KeyManager.verifySignature(dataToSign, stamp.signature, publicKey);
  }

  /// Verify an entire stamp chain
  Future<bool> verifyStampChain(List<Stamp> stamps, String publicKey) async {
    if (stamps.isEmpty) return true;

    // Sort by stamp number
    final sortedStamps = List<Stamp>.from(stamps)
      ..sort((a, b) => a.stampNumber.compareTo(b.stampNumber));

    String? expectedPreviousHash;

    for (final stamp in sortedStamps) {
      // Verify signature (CR-1.4)
      final verificationResult = await verifyStamp(stamp, publicKey);
      if (!verificationResult.isValid) {
        AppLogger.error('Stamp ${stamp.stampNumber} verification failed: ${verificationResult.failureReason}');
        return false;
      }

      // Verify chain integrity (except for first stamp)
      if (expectedPreviousHash != null) {
        if (stamp.previousHash != expectedPreviousHash) {
          AppLogger.error('Stamp ${stamp.stampNumber} chain broken: expected hash $expectedPreviousHash, got ${stamp.previousHash}');
          return false;
        }
      }

      // Calculate hash for next stamp
      expectedPreviousHash = calculateStampHash(stamp);
    }

    return true;
  }

  /// Create card issuance data (for QR code)
  Future<Map<String, dynamic>> createCardIssuanceToken({
    required String businessId,
    required String businessName,
    required int stampsRequired,
    required String brandColor,
  }) async {
    final publicKey = await _keyManager.getPublicKey(businessId);
    
    if (publicKey == null) {
      throw Exception('Public key not found for business $businessId');
    }

    final publicKeyEncoded = _encodePublicKey(publicKey);

    return {
      'type': 'card_issue',
      'businessId': businessId,
      'businessName': businessName,
      'publicKey': publicKeyEncoded,
      'stampsRequired': stampsRequired,
      'brandColor': brandColor,
      'issuedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Encode public key using KeyManager's cryptographic encoding
  String _encodePublicKey(dynamic publicKey) {
    return _keyManager.encodePublicKey(publicKey);
  }
}
