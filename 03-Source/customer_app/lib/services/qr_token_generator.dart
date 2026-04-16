import 'package:shared/shared.dart';
import 'stamp_repository.dart';
import 'card_repository.dart';
import 'database_helper.dart';

/// Service to generate QR tokens for customer operations
class QRTokenGenerator {
  /// Generate a Card Stamp Request token to show supplier for stamping  
  /// Fetches fresh card and stamp data from database to ensure accuracy
  Future<CardStampRequestToken> generateStampRequest({
    required Card card,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      AppLogger.qr('Generating stamp request for card ${card.id}');
      
      // IMPORTANT: Reload card from database to get fresh stamp count
      // The widget might have stale data if stamps were recently added
      final cardRepo = CardRepository(DatabaseHelper());
      final freshCard = await cardRepo.getCardById(card.id);
      
      if (freshCard == null) {
        AppLogger.error('Card not found in database', tag: 'QR');
        throw Exception('Card not found');
      }
      
      AppLogger.debug('Card has ${freshCard.stampsCollected} stamps', 'QR');
      
      // Get the last stamp's signature for hash chain validation
      String lastStampHash = '';
      if (freshCard.stampsCollected > 0) {
        final stampRepo = StampRepository(DatabaseHelper());
        final stamps = await stampRepo.getStampsByCard(freshCard.id);
        
        if (stamps.isNotEmpty) {
          lastStampHash = stamps.last.signature;
          AppLogger.debug('Using hash from stamp #${stamps.last.stampNumber}', 'QR');
        } else {
          AppLogger.warning('Card indicates ${freshCard.stampsCollected} stamps but DB has 0', 'QR');
        }
      }
      
      return CardStampRequestToken(
        cardId: freshCard.id,
        businessId: freshCard.businessId,
        currentStamps: freshCard.stampsCollected,
        publicKey: freshCard.businessPublicKey,
        lastStampHash: lastStampHash,
        timestamp: timestamp,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to generate stamp request', error: e, stackTrace: stackTrace, tag: 'QR');
      rethrow;
    }
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
