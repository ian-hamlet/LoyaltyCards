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
      
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('!!! GENERATING STAMP REQUEST QR - BUILD 4 !!!');
      print('!!! This log MUST appear if new code is running !!!');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('Input card ID: ${card.id}');
      print('Input card stamps collected: ${card.stampsCollected}');
      
      // IMPORTANT: Reload card from database to get fresh stamp count
      // The widget might have stale data if stamps were recently added
      final cardRepo = CardRepository(DatabaseHelper());
      final freshCard = await cardRepo.getCardById(card.id);
      
      if (freshCard == null) {
        print('ERROR: Card not found in database!');
        throw Exception('Card not found');
      }
      
      print('Fresh card stamps collected: ${freshCard.stampsCollected}');
      
      // Get the last stamp's signature for hash chain validation
      String lastStampHash = '';
      if (freshCard.stampsCollected > 0) {
        final stampRepo = StampRepository(DatabaseHelper());
        final stamps = await stampRepo.getStampsByCard(freshCard.id);
        print('Stamps found in DB: ${stamps.length}');
        if (stamps.isNotEmpty) {
          for (var i = 0; i < stamps.length; i++) {
            print('  Stamp #${stamps[i].stampNumber}: signature="${stamps[i].signature.substring(0, 20)}..."');
          }
          lastStampHash = stamps.last.signature;
          print('Using lastStampHash: "${lastStampHash.substring(0, 20)}..."');
        } else {
          print('WARNING: Card says ${freshCard.stampsCollected} stamps but DB has 0!');
        }
      } else {
        print('First stamp (no previous hash)');
      }
      print('=== End Stamp Request QR ===');
      
      return CardStampRequestToken(
        cardId: freshCard.id,
        businessId: freshCard.businessId,
        currentStamps: freshCard.stampsCollected,
        publicKey: freshCard.businessPublicKey,
        lastStampHash: lastStampHash,
        timestamp: timestamp,
      );
    } catch (e, stackTrace) {
      print('ERROR in generateStampRequest: $e');
      print('Stack trace: $stackTrace');
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
