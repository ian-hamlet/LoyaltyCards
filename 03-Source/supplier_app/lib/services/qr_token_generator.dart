import 'package:shared/shared.dart';
import 'key_manager.dart';

/// Service to generate QR tokens for supplier operations
class QRTokenGenerator {
  final KeyManager _keyManager;

  QRTokenGenerator(this._keyManager);

  /// Generate a Card Issue Token for customers to scan
  /// This token contains business information and allows customers to add the card
  /// 
  /// If [initialStampCount] is provided (1-7), the token will include pre-applied stamps
  /// with valid signatures and hash chain. This allows issuing cards with multiple stamps
  /// in a single QR scan operation.
  Future<CardIssueToken> generateCardIssueToken({
    required Business business,
    int initialStampCount = 0,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Generate card ID that will be used by both supplier and customer
    final cardId = '${business.id}_${timestamp}';
    
    // Generate initial stamps if requested
    final List<InitialStamp> initialStamps = [];
    if (initialStampCount > 0) {
      final privateKey = await _keyManager.getPrivateKey(business.id);
      if (privateKey == null) {
        throw Exception('Private key not found for business');
      }

      String previousHash = ''; // First stamp has empty previous hash

      for (int i = 1; i <= initialStampCount; i++) {
        final stampTimestamp = timestamp + i; // Slight offset to ensure unique timestamps
        final signatureData = '$cardId:$i:$stampTimestamp:$previousHash';
        final signature = await _keyManager.signData(signatureData, privateKey);
        
        if (signature == null) {
          throw Exception('Failed to sign initial stamp #$i');
        }

        initialStamps.add(InitialStamp(
          stampNumber: i,
          signature: signature,
          timestamp: stampTimestamp,
        ));

        // Next stamp's previous hash is this stamp's signature
        previousHash = signature;
      }
    }
    
    // Create token with basic data
    final token = CardIssueToken(
      businessId: business.id,
      businessName: business.name,
      publicKey: business.publicKey,
      stampsRequired: business.stampsRequired,
      brandColor: business.brandColor,
      logoIndex: business.logoIndex,
      mode: business.mode,
      signature: '', // Will be filled below
      cardId: cardId,
      timestamp: timestamp,
      initialStamps: initialStamps,
    );

    // Sign the token data
    final privateKey = await _keyManager.getPrivateKey(business.id);
    if (privateKey == null) {
      throw Exception('Private key not found for business');
    }

    final signatureData = token.getSignatureData();
    final signature = await _keyManager.signData(signatureData, privateKey);
    
    if (signature == null) {
      throw Exception('Failed to sign card issuance token');
    }

    // Return token with signature
    return CardIssueToken(
      businessId: business.id,
      businessName: business.name,
      publicKey: business.publicKey,
      stampsRequired: business.stampsRequired,
      brandColor: business.brandColor,
      logoIndex: business.logoIndex,
      mode: business.mode,
      signature: signature,
      cardId: cardId,
      timestamp: timestamp,
      initialStamps: initialStamps,
    );
  }

  /// Generate a Stamp Token for customer to scan and add to their card
  /// 
  /// If [additionalStampCount] is provided (1-6), the token will include additional
  /// stamps with valid signatures and hash chain. This allows adding multiple stamps
  /// in a single QR scan operation.
  Future<StampToken> generateStampToken({
    required String businessId,
    required String cardId,
    required int stampNumber,
    required String previousHash,
    int additionalStampCount = 0,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Create signature data for first stamp
    final signatureData = '$cardId:$stampNumber:$timestamp:$previousHash';
    
    // Get private key and sign
    final privateKey = await _keyManager.getPrivateKey(businessId);
    if (privateKey == null) {
      throw Exception('Private key not found for business');
    }
    
    final signature = await _keyManager.signData(signatureData, privateKey);
    
    if (signature == null) {
      throw Exception('Failed to sign stamp token');
    }
    
    // Generate unique stamp ID
    final stampId = '${cardId}_stamp_$stampNumber';
    
    // Generate additional stamps if requested
    final List<AdditionalStamp> additionalStamps = [];
    if (additionalStampCount > 0) {
      String currentPreviousHash = signature; // First additional stamp uses main stamp's signature

      for (int i = 1; i <= additionalStampCount; i++) {
        final additionalStampNumber = stampNumber + i;
        final additionalTimestamp = timestamp + i; // Slight offset
        final additionalSignatureData = '$cardId:$additionalStampNumber:$additionalTimestamp:$currentPreviousHash';
        final additionalSignature = await _keyManager.signData(additionalSignatureData, privateKey);
        
        if (additionalSignature == null) {
          throw Exception('Failed to sign additional stamp #$i');
        }

        additionalStamps.add(AdditionalStamp(
          stampNumber: additionalStampNumber,
          signature: additionalSignature,
          timestamp: additionalTimestamp,
        ));

        // Next stamp's previous hash is this stamp's signature
        currentPreviousHash = additionalSignature;
      }
    }
    
    return StampToken(
      id: stampId,
      cardId: cardId,
      businessId: businessId,
      stampNumber: stampNumber,
      previousHash: previousHash,
      signature: signature,
      timestamp: timestamp,
      additionalStamps: additionalStamps,
    );
  }
}
