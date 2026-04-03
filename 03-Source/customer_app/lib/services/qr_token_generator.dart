import 'package:shared/shared.dart';

/// Service to generate QR tokens for customer operations
class QRTokenGenerator {
  /// Generate a Card Stamp Request token to show supplier for stamping
  CardStampRequestToken generateStampRequest({
    required Card card,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    return CardStampRequestToken(
      cardId: card.id,
      businessId: card.businessId,
      currentStamps: card.stampsCollected,
      publicKey: card.businessPublicKey,
      timestamp: timestamp,
    );
  }

  /// Generate a Redemption Request token to show supplier for reward
  RedemptionRequestToken generateRedemptionRequest({
    required Card card,
    required List<Stamp> stamps,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Extract all stamp signatures
    final signatures = stamps.map((s) => s.signature).toList();
    
    return RedemptionRequestToken(
      cardId: card.id,
      businessId: card.businessId,
      stampsCollected: card.stampsCollected,
      stampSignatures: signatures,
      timestamp: timestamp,
    );
  }
}
