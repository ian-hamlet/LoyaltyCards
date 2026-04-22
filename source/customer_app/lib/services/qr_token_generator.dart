import 'package:shared/shared.dart';
import 'stamp_repository.dart';
import 'card_repository.dart';
import 'database_helper.dart';
import '../exceptions/qr_generation_exception.dart';

/// Service to generate QR tokens for customer operations
/// 
/// ERROR HANDLING PATTERN (FIX HIGH-1):
/// - All generation methods have comprehensive error handling
/// - Throws QRGenerationException with context on failure
/// - Logs errors with stack traces for debugging
/// - Input validation before processing
/// - User-friendly error messages via exception.getUserMessage()
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
        AppLogger.error('Card not found in database: ${card.id}', tag: 'QR');
        throw QRGenerationException(
          'Card not found in database',
          originalError: 'Card ID: ${card.id}',
        );
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
      AppLogger.error(
        'Failed to generate stamp request: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'QR',
      );
      
      // If already a QRGenerationException, rethrow it
      if (e is QRGenerationException) {
        rethrow;
      }
      
      // Wrap other exceptions
      throw QRGenerationException(
        'Failed to generate stamp request QR',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Generate a Redemption Request token to show supplier for reward
  /// 
  /// FIX HIGH-1: Added input validation and error handling
  RedemptionRequestToken generateRedemptionRequest({
    required Card card,
    required List<Stamp> stamps,
  }) {
    try {
      // Validate inputs
      if (card.stampsCollected != stamps.length) {
        AppLogger.warning(
          'Stamp count mismatch: card has ${card.stampsCollected} but ${stamps.length} stamps provided',
          'QR',
        );
        throw QRGenerationException(
          'Stamp data inconsistent: card indicates ${card.stampsCollected} stamps but ${stamps.length} provided',
        );
      }
      
      if (stamps.isEmpty) {
        AppLogger.error('Cannot generate redemption QR: no stamps', tag: 'QR');
        throw QRGenerationException('No stamps to redeem');
      }
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      AppLogger.qr('Generating redemption request for card ${card.id} with ${stamps.length} stamps');
      
      // Extract all stamp signatures
      final signatures = stamps.map((s) => s.signature).toList();
      
      // Validate all signatures are present
      if (signatures.any((sig) => sig.isEmpty)) {
        AppLogger.error('Found stamps with empty signatures', tag: 'QR');
        throw QRGenerationException('Stamp data incomplete: missing signatures');
      }
      
      return RedemptionRequestToken(
        cardId: card.id,
        businessId: card.businessId,
        stampsCollected: card.stampsCollected,
        stampSignatures: signatures,
        timestamp: timestamp,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to generate redemption request: $e',
        error: e,
        stackTrace: stackTrace,
        tag: 'QR',
      );
      
      // If already a QRGenerationException, rethrow it
      if (e is QRGenerationException) {
        rethrow;
      }
      
      // Wrap other exceptions
      throw QRGenerationException(
        'Failed to generate redemption request QR',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }
}
