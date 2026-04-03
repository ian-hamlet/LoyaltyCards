import 'package:shared/shared.dart';
import 'key_manager.dart';

/// Service to generate QR tokens for supplier operations
class QRTokenGenerator {
  final KeyManager _keyManager;

  QRTokenGenerator(this._keyManager);

  /// Generate a Card Issue Token for customers to scan
  /// This token contains business information and allows customers to add the card
  Future<CardIssueToken> generateCardIssueToken({
    required Business business,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Create token with basic data
    final token = CardIssueToken(
      businessId: business.id,
      businessName: business.name,
      publicKey: business.publicKey,
      stampsRequired: business.stampsRequired,
      brandColor: '#${business.brandColor}',
      signature: '', // Will be filled below
      timestamp: timestamp,
    );

    // Sign the token data
    final privateKey = await _keyManager.getPrivateKey(business.id);
    if (privateKey == null) {
      throw Exception('Private key not found for business');
    }

    final signatureData = token.getSignatureData();
    final signature = await _keyManager.signData(signatureData, privateKey);

    // Return token with signature
    return CardIssueToken(
      businessId: business.id,
      businessName: business.name,
      publicKey: business.publicKey,
      stampsRequired: business.stampsRequired,
      brandColor: '#${business.brandColor}',
      signature: signature,
      timestamp: timestamp,
    );
  }

  /// Generate a Stamp Token for customer to scan and add to their card
  Future<StampToken> generateStampToken({
    required String businessId,
    required String cardId,
    required int stampNumber,
    required String previousHash,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Create signature data
    final signatureData = '$cardId:$stampNumber:$timestamp:$previousHash';
    
    // Get private key and sign
    final privateKey = await _keyManager.getPrivateKey(businessId);
    if (privateKey == null) {
      throw Exception('Private key not found for business');
    }
    
    final signature = await _keyManager.signData(signatureData, privateKey);
    
    // Generate unique stamp ID
    final stampId = '${cardId}_stamp_$stampNumber';
    
    return StampToken(
      id: stampId,
      cardId: cardId,
      stampNumber: stampNumber,
      previousHash: previousHash,
      signature: signature,
      timestamp: timestamp,
    );
  }
}
