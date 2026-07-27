import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart' as models;
import 'package:shared/models/transaction.dart' as models;
import '../../services/token_validator.dart';
import '../../services/card_repository.dart';
import '../../services/stamp_repository.dart';
import '../../services/transaction_repository.dart';
import '../../services/rate_limiter.dart';
import '../../services/database_helper.dart';
import '../../services/key_manager.dart';
import '../../services/device_orientation_service.dart';
import '../../services/device_service.dart';
import '../../utils/error_message_mapper.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Scanner screen for adding new cards or receiving stamps
/// 
/// **SMART ROUTING** (Simple Mode):
/// When scanning a stamp QR code, the app uses "smart routing" to ensure
/// stamps always go to the correct business card, regardless of which card
/// screen you're currently viewing. For example:
/// - You have cards for "Coffee Shop" and "Restaurant" 
/// - You open the "Coffee Shop" card screen
/// - You scan a "Restaurant" stamp QR code
/// - The stamp is intelligently routed to your "Restaurant" card (not Coffee Shop)
/// - This happens automatically based on the businessId in the QR code
/// 
/// This makes the scanning experience more forgiving - you don't need to be on
/// the correct card screen to receive stamps. The system finds the right card for you.
/// 
/// **SECURE MODE:**
/// Uses exact cardId matching - each card has a unique ID that must match the QR code.
/// 
/// **AUTO NEW CARD CREATION:**
/// When a card reaches stampsRequired (is complete), a new card is automatically
/// created for the same business. If there are overflow stamps from the scan,
/// they are placed on the new card. Users are notified with a success message.
class QRScannerScreen extends StatefulWidget {
  final QRScanMode mode;

  const QRScannerScreen({
    super.key,
    required this.mode,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _errorMessage;
  DateTime? _cooldownUntil;
  static const Duration _errorCooldownDuration = Duration(seconds: 2);
  int _manualRotationOffset = 1; // 0, 1, 2, or 3 quarter turns (1 = 90° to fix mobile_scanner 7.2.0)

  @override
  void initState() {
    super.initState();
    _loadRotationPreference();
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  /// Load saved camera rotation preference from SharedPreferences
  Future<void> _loadRotationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRotation = prefs.getInt('camera_rotation') ?? 1;
      if (mounted) {
        setState(() {
          _manualRotationOffset = savedRotation;
        });
        AppLogger.debug('Loaded camera rotation preference: $savedRotation (${savedRotation * 90}°)', 'Camera');
      }
    } catch (e) {
      AppLogger.warning('Failed to load camera rotation preference: $e', 'Camera');
    }
  }

  /// Save camera rotation preference to SharedPreferences
  Future<void> _saveRotationPreference(int rotation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('camera_rotation', rotation);
      AppLogger.debug('Saved camera rotation preference: $rotation (${rotation * 90}°)', 'Camera');
    } catch (e) {
      AppLogger.warning('Failed to save camera rotation preference: $e', 'Camera');
    }
  }

  Future<void> _handleQRCode(String qrData) async {
    if (_isProcessing) return;
    if (_cooldownUntil != null && DateTime.now().isBefore(_cooldownUntil!)) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final token = QRToken.fromQRString(qrData);

      if (token == null) {
        final message = widget.mode == QRScanMode.receiveStamp
            ? 'This is not a valid stamp QR code. Please scan a stamp QR from the supplier app.'
            : 'This is not a valid card QR code. Please scan a card issuance QR.';
        _showScanError(message);
        return;
      }

      // Immediate feedback that a readable code was recognized, distinct
      // from whether the scan ultimately succeeds - this is the main
      // signal a non-visual user has that the camera actually registered
      // anything at all, since there's no other non-visual affordance on
      // this screen. _showScanError below covers all rejection paths.
      Haptics.success();

      switch (widget.mode) {
        case QRScanMode.addCard:
          await _handleCardIssue(token);
          break;
        case QRScanMode.receiveStamp:
          await _handleStampToken(token);
          break;
      }
    } catch (e) {
      _showScanError('Error processing QR: $e');
    }
  }

  void _showScanError(String message) {
    Haptics.error();
    setState(() {
      _errorMessage = message;
      _isProcessing = false;
      _cooldownUntil = DateTime.now().add(_errorCooldownDuration);
    });
  }

  Future<void> _handleCardIssue(QRToken token) async {
    if (token is! CardIssueToken) {
      _showScanError('Wrong QR type. Please scan a card issuance QR.');
      return;
    }

    // Validate token
    final validation = await TokenValidator.validateCardIssueToken(token);
    if (!validation.isValid) {
      _showScanError(ErrorMessageMapper.getUserMessage(validation.error ?? 'Invalid token'));
      return;
    }

    // Note: In simple mode, signature validation is skipped (trust-based)
    // In secure mode, full cryptographic validation is performed
    AppLogger.business('Card operation mode: ${token.mode.displayName}');

    // Use card ID from token if present (for multi-stamp consistency)
    // Otherwise generate new one (backward compatibility)
    final cardId = token.cardId ?? '${token.businessId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Check if this specific card already exists (prevents duplicate scans of same QR)
    final cardRepository = CardRepository(DatabaseHelper());
    final existingCard = await cardRepository.getCardById(cardId);
    
    if (existingCard != null) {
      // This exact card has already been scanned
      if (mounted) {
        Navigator.pop(context, 'Card has already been scanned: ${token.businessName}');
      }
      return;
    }
    
    final initialStampCount = token.initialStamps.length;
    
    // Get device ID for multi-device tracking (V-005)
    final deviceId = await DeviceService.getDeviceId();
    
    final card = models.Card(
      id: cardId,
      businessId: token.businessId,
      businessName: token.businessName,
      businessPublicKey: token.publicKey,
      stampsRequired: token.stampsRequired,
      stampsCollected: initialStampCount,
      brandColor: token.brandColor.replaceAll('#', ''),
      logoIndex: token.logoIndex,
      mode: token.mode, // Store the operation mode from token
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      deviceId: deviceId, // V-005: Track device where card was created
    );

    // Save card to database (duplicate check already performed above)
    await cardRepository.insertCard(card);
    
    // Log card pickup transaction
    final transactionRepo = TransactionRepository(DatabaseHelper());
    final pickupTransaction = models.Transaction(
      id: const Uuid().v4(),
      cardId: cardId,
      type: TransactionType.pickup,
      timestamp: DateTime.now(),
      businessName: token.businessName,
      details: 'Card added to wallet',
    );
    await transactionRepo.insertTransaction(pickupTransaction);
    AppLogger.database('Logged pickup transaction for card $cardId');
    
    AppLogger.qr('Processing Card Issuance');
    AppLogger.business('Card ID: $cardId');
    AppLogger.business('Initial stamps to process: $initialStampCount');

    // Process initial stamps if present
    if (initialStampCount > 0) {
      final stampRepository = StampRepository(DatabaseHelper());
      String previousHash = ''; // First stamp has empty previous hash

      for (var initialStamp in token.initialStamps) {
        AppLogger.qr('Processing initial stamp #${initialStamp.stampNumber}');
        AppLogger.qr('  Card ID for stamp: $cardId');
        
        // Verify stamp signature (skip in simple mode) (CR-1.4)
        if (token.mode == OperationMode.secure) {
          final signatureData = '$cardId:${initialStamp.stampNumber}:${initialStamp.timestamp}:$previousHash';
          final verificationResult = KeyManager.verifySignature(
            signatureData,
            initialStamp.signature,
            token.publicKey,
          );

          if (!verificationResult.isValid) {
            AppLogger.error('Initial stamp signature verification failed: ${verificationResult.failureReason}');
            _showScanError('Invalid stamp signature: ${verificationResult.failureReason}');
            // Rollback: delete the card
            await cardRepository.deleteCard(cardId);
            return;
          }
        } else {
          AppLogger.debug('  Simple mode: Skipping signature validation');
        }

        // Create and save stamp
        final stamp = Stamp(
          id: '${cardId}_stamp_${initialStamp.stampNumber}',
          cardId: cardId,
          stampNumber: initialStamp.stampNumber,
          timestamp: DateTime.fromMillisecondsSinceEpoch(initialStamp.timestamp),
          signature: initialStamp.signature,
          previousHash: previousHash.isEmpty ? null : previousHash,
          deviceId: deviceId, // V-005: Track device where stamp was collected
        );

        await stampRepository.insertStamp(stamp);
        AppLogger.database('  Initial stamp #${initialStamp.stampNumber} saved to DB');
        
        // Log stamp transaction
        final stampTransaction = models.Transaction(
          id: const Uuid().v4(),
          cardId: cardId,
          type: TransactionType.stamp,
          timestamp: DateTime.now(),
          businessName: token.businessName,
          details: 'Stamp #${initialStamp.stampNumber} earned',
        );
        await transactionRepo.insertTransaction(stampTransaction);
        
        // Next stamp's previous hash is this stamp's signature
        previousHash = initialStamp.signature;
      }
      
      // Verify stamps were saved
      final savedStamps = await stampRepository.getStampsByCard(cardId);
      AppLogger.database('Verification: ${savedStamps.length} stamps found in DB for card $cardId');
      for (var s in savedStamps) {
        final sigPreview = s.signature.length > 20 ? '${s.signature.substring(0, 20)}...' : s.signature;
        AppLogger.debug('  Stamp #${s.stampNumber}: $sigPreview');
      }
      AppLogger.qr('End Card Issuance Processing');
    }

    if (mounted) {
      // Success! Return to home with success message
      final stampText = initialStampCount > 0 
          ? ' with $initialStampCount stamp${initialStampCount > 1 ? 's' : ''}' 
          : '';
      Navigator.pop(context, 'Card added: ${card.businessName}$stampText');
    }
  }

  Future<void> _handleStampToken(QRToken token) async {
    // Get device ID for multi-device tracking (V-005)
    final deviceId = await DeviceService.getDeviceId();
    
    // Handle redemption tokens
    if (token is RedemptionToken) {
      await _handleRedemptionToken(token);
      return;
    }
    
    // Handle stamp tokens
    if (token is! StampToken) {
      final message = token is CardIssueToken
          ? 'This QR is for adding a new card, not collecting a stamp. Use Add Card to scan it.'
          : 'Wrong QR type. Please scan a stamp or redemption token QR.';
      _showScanError(message);
      return;
    }

    // Get the card this stamp is for
    final repository = CardRepository(DatabaseHelper());
    models.Card? card;
    
    // SMART ROUTING: For simple mode stamps, look up by businessId since cardId is generic
    // This ensures stamps go to the correct business card, regardless of which card screen
    // the user is currently viewing. Stamps are intelligently routed based on the QR code's
    // businessId, not the opened card.
    if ((token.cardId == 'express-mode-stamp' || token.cardId == 'simple-mode-stamp') && token.businessId.isNotEmpty) {
      AppLogger.qr('Express Mode Stamp Detected');
      AppLogger.business('Looking up card by businessId: ${token.businessId}');
      final allCards = await repository.getAllCards();
      try {
        card = allCards.firstWhere(
          (c) => c.businessId == token.businessId,
        );
        AppLogger.business('Found card with ID: ${card.id}');
      } catch (e) {
        AppLogger.debug('No card found for businessId: ${token.businessId}');
        card = null;
      }
    } else {
      // Secure mode: look up by exact cardId
      card = await repository.getCardById(token.cardId);
    }

    if (card == null) {
      _showScanError('Card not found. Please add the card first.');
      return;
    }

    // Check rate limiting (REQ-022: Use token's scanInterval if present)
    final rateLimiter = RateLimiter(DatabaseHelper());
    final rateLimit = await rateLimiter.canReceiveStamp(
      cardId: card.id,
      businessId: card.businessId,
      mode: card.mode,
      scanInterval: token.scanInterval, // REQ-022: Supplier-specific rate limit
    );

    if (!rateLimit.canProceed) {
      // Rate limit hit - immediately return to card screen to prevent abuse
      // This prevents customers from waiting on camera screen and scanning again after timeout
      AppLogger.warning('Rate limit hit - returning to card screen', 'RateLimit');
      
      if (mounted) {
        // Clear any existing snackbars to prevent stacking
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Show error feedback
        AppFeedback.error(
          context,
          rateLimit.message ?? 'Please wait before scanning again',
        );
        
        // Immediately pop back to card screen
        // Don't stay on camera - prevents easy re-scanning after timeout
        Navigator.pop(context, null);
      }
      return;
    }

    // Get expected previous hash
    final stampRepo = StampRepository(DatabaseHelper());
    final stamps = await stampRepo.getStampsByCard(card.id);
    final expectedPrevHash = stamps.isNotEmpty ? stamps.last.signature : '';
    
    AppLogger.qr('Validating Stamp Token');
    AppLogger.qr('Card ID: ${card.id}');
    AppLogger.debug('Card mode: ${card.mode.displayName}');
    AppLogger.database('Stamps in DB: ${stamps.length}');
    AppLogger.business('Expected next stamp: #${stamps.length + 1}');
    AppLogger.qr('Token stamp number: ${token.stampNumber}');
    final expectedPrevHashPreview = expectedPrevHash.isEmpty ? "(empty)" : (expectedPrevHash.length > 20 ? '${expectedPrevHash.substring(0, 20)}...' : expectedPrevHash);
    final tokenPrevHashPreview = token.previousHash.isEmpty ? "(empty)" : (token.previousHash.length > 20 ? '${token.previousHash.substring(0, 20)}...' : token.previousHash);
    AppLogger.qr('Expected previousHash: "$expectedPrevHashPreview"');
    AppLogger.qr('Token previousHash: "$tokenPrevHashPreview"');
    AppLogger.qr('End Validation');

    // Validate stamp token (skip crypto validation for simple mode)
    if (card.mode == OperationMode.secure) {
      final validation = await TokenValidator.validateStampToken(
        token: token,
        businessPublicKey: card.businessPublicKey,
        expectedPreviousHash: expectedPrevHash,
        mode: card.mode,
        stampsRequired: card.stampsRequired, // REQ-022
      );

      if (!validation.isValid) {
        _showScanError(ErrorMessageMapper.getUserMessage(validation.error ?? 'Invalid stamp'));
        return;
      }

      // V-010: REQ-022 multi-denomination (stampCount) is a Simple/Express
      // Mode feature only - Secure Mode issuance never sets it above 1
      // (see supplier_stamp_card.dart's _generateAndShowStamp). A Secure
      // Mode token with stampCount != 1 can now only mean the field was
      // tampered post-signing (the signature covers it, so this would also
      // fail the check above) or a bug - reject outright either way, since
      // the crediting loop below would otherwise mint multiple stamp rows
      // from a single scan.
      if (token.stampCount != 1) {
        AppLogger.error(
          'Secure Mode token has stampCount=${token.stampCount}, expected 1 - rejecting',
          tag: 'Security',
        );
        _showScanError('Invalid stamp token');
        return;
      }
    } else {
      // REQ-022: Simple mode - validate expiry date and stamp count (skip crypto)
      AppLogger.debug('Simple mode: Validating expiry and stamp count only', 'Token');
      
      // Check expiry date if present
      if (token.expiryDate != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > token.expiryDate!) {
          _showScanError('This stamp token has expired');
          return;
        }
      }
      
      // Validate stamp count
      if (token.stampCount > card!.stampsRequired) {
        _showScanError('Invalid stamp count: ${token.stampCount} exceeds ${card!.stampsRequired}');
        return;
      }
    }

    // Add stamp to card
    AppLogger.database('Saving Main Stamp');
    
    // In simple mode, generate unique stamp details since QR is reusable
    final nextStampNumber = stamps.length + 1;
    final stampId = card.mode == OperationMode.simple 
        ? '${card.id}_stamp_$nextStampNumber'
        : token.id;
    final stampNumber = card.mode == OperationMode.simple
        ? nextStampNumber
        : token.stampNumber;
    final stampTimestamp = card.mode == OperationMode.simple
        ? DateTime.now()
        : DateTime.fromMillisecondsSinceEpoch(token.timestamp);
    final stampPreviousHash = card.mode == OperationMode.simple
        ? expectedPrevHash
        : token.previousHash;
    
    AppLogger.qr('Stamp #$stampNumber');
    AppLogger.qr('Card ID: ${card.id}');
    AppLogger.qr('Stamp ID: $stampId');
    AppLogger.debug('Mode: ${card.mode.displayName}');
    final prevHashPreview = stampPreviousHash.isEmpty ? "(empty -> will be null)" : (stampPreviousHash.length > 20 ? '${stampPreviousHash.substring(0, 20)}...' : stampPreviousHash);
    final sigPreview = token.signature.length > 20 ? '${token.signature.substring(0, 20)}...' : token.signature;
    AppLogger.qr('previousHash: "$prevHashPreview"');
    AppLogger.qr('signature: "$sigPreview"');
    
    final stamp = Stamp(
      id: stampId,
      cardId: card.id,  // Use the actual card ID we found, not token.cardId
      stampNumber: stampNumber,
      timestamp: stampTimestamp,
      signature: token.signature,
      previousHash: stampPreviousHash.isEmpty ? null : stampPreviousHash,
      deviceId: deviceId, // V-005: Track device where stamp was collected
    );

    // Log stamp transaction
    final transactionRepo = TransactionRepository(DatabaseHelper());
    final dbHelper = DatabaseHelper();

    // REQ-022: Process multi-denomination stamps (Simple Mode)
    int totalStampsAdded = 1;

    // Q-003 fix: wrap every stamp/transaction-log insert for this crediting
    // event in one atomic transaction. Previously these were separate
    // writes - a failure partway through (e.g. an additional stamp's
    // signature legitimately failing verification mid-loop) could leave
    // stamp rows persisted with no matching transaction log entry, or vice
    // versa, desyncing the card's stampsCollected count from the actual
    // stamps table. This also fixes an acknowledged gap in the original
    // code ("we've already added some stamps... you might want to
    // implement a transaction rollback here") - throwing
    // _StampCreditingAborted now genuinely rolls back everything inserted
    // earlier in this same event, instead of leaving partial state.
    try {
      await dbHelper.runInTransaction((txn) async {
        await stampRepo.insertStamp(stamp, executor: txn);
        AppLogger.database('Main stamp saved to DB');

        final stampTransaction = models.Transaction(
          id: const Uuid().v4(),
          cardId: card!.id,
          type: TransactionType.stamp,
          timestamp: DateTime.now(),
          businessName: card.businessName,
          details: 'Stamp #$stampNumber earned',
        );
        await transactionRepo.insertTransaction(stampTransaction, executor: txn);

        if (token.stampCount > 1) {
          AppLogger.qr('REQ-022: Processing ${token.stampCount - 1} additional stamps from multi-denomination token');

          for (int i = 2; i <= token.stampCount; i++) {
            final additionalStampNumber = stamps.length + i;
            final additionalStampId = '${card.id}_stamp_$additionalStampNumber';

            AppLogger.debug('Adding denomination stamp $i of ${token.stampCount}', 'Stamp');

            final additionalStamp = Stamp(
              id: additionalStampId,
              cardId: card.id,
              stampNumber: additionalStampNumber,
              timestamp: DateTime.now().add(Duration(milliseconds: i)), // Slight offset
              signature: token.signature, // Same signature for all in simple mode
              previousHash: null, // Simple mode doesn't use hash chains
              deviceId: deviceId,
            );

            await stampRepo.insertStamp(additionalStamp, executor: txn);
            totalStampsAdded++;
            AppLogger.database('  Multi-denomination stamp $i saved to DB');

            // Log stamp transaction
            final addlStampTransaction = models.Transaction(
              id: const Uuid().v4(),
              cardId: card.id,
              type: TransactionType.stamp,
              timestamp: DateTime.now(),
              businessName: card.businessName,
              details: 'Stamp #$additionalStampNumber earned (multi-denomination)',
            );
            await transactionRepo.insertTransaction(addlStampTransaction, executor: txn);
          }
          AppLogger.qr('REQ-022: All ${token.stampCount} stamps processed');
        }

        // Process additional stamps if present (Secure Mode)
        if (token.additionalStamps.isNotEmpty) {
          AppLogger.qr('Processing ${token.additionalStamps.length} Additional Stamps ===');
          String currentPreviousHash = token.signature; // First additional stamp uses main stamp's signature

          for (var additionalStamp in token.additionalStamps) {
            AppLogger.qr('Additional Stamp #${additionalStamp.stampNumber}:');
            final prevHashPreview = currentPreviousHash.length > 20 ? '${currentPreviousHash.substring(0, 20)}...' : currentPreviousHash;
            final addlSigPreview = additionalStamp.signature.length > 20 ? '${additionalStamp.signature.substring(0, 20)}...' : additionalStamp.signature;
            AppLogger.qr('  previousHash: "$prevHashPreview"');
            AppLogger.qr('  signature: "$addlSigPreview"');

            // Verify stamp signature (skip in simple mode) (CR-1.4)
            if (card.mode == OperationMode.secure) {
              // Must match SignatureFormat.stampChainData exactly - see the
              // matching comment in qr_token_generator.dart's signing side.
              final signatureData = SignatureFormat.stampChainData(
                cardId: card.id,
                stampNumber: additionalStamp.stampNumber,
                timestampMs: additionalStamp.timestamp,
                previousHash: currentPreviousHash,
                stampCount: 1,
              );
              final verificationResult = KeyManager.verifySignature(
                signatureData,
                additionalStamp.signature,
                card.businessPublicKey,
              );

              if (!verificationResult.isValid) {
                AppLogger.error('Additional stamp signature verification failed: ${verificationResult.failureReason}');
                // Q-003 fix: throw to roll back the whole transaction
                // (including any stamps already inserted earlier in this
                // loop), instead of leaving partial state.
                throw _StampCreditingAborted('Invalid stamp signature: ${verificationResult.failureReason}');
              }
              AppLogger.qr('  Signature verified OK');
            } else {
              AppLogger.debug('  Simple mode: Skipping signature validation');
            }

            // Create and save stamp
            final additionalStampRecord = Stamp(
              id: '${card.id}_stamp_${additionalStamp.stampNumber}',
              cardId: card.id,
              stampNumber: additionalStamp.stampNumber,
              timestamp: DateTime.fromMillisecondsSinceEpoch(additionalStamp.timestamp),
              signature: additionalStamp.signature,
              previousHash: currentPreviousHash.isEmpty ? null : currentPreviousHash,
              deviceId: deviceId, // V-005: Track device where stamp was collected
            );

            await stampRepo.insertStamp(additionalStampRecord, executor: txn);
            totalStampsAdded++;
            AppLogger.database('  Additional stamp saved to DB');

            // Log stamp transaction
            final addlStampTransaction = models.Transaction(
              id: const Uuid().v4(),
              cardId: card.id,
              type: TransactionType.stamp,
              timestamp: DateTime.now(),
              businessName: card.businessName,
              details: 'Stamp #${additionalStamp.stampNumber} earned',
            );
            await transactionRepo.insertTransaction(addlStampTransaction, executor: txn);

            // Next stamp's previous hash is this stamp's signature
            currentPreviousHash = additionalStamp.signature;
          }
          AppLogger.qr('All Additional Stamps Processed');
        }
      });
    } on _StampCreditingAborted catch (e) {
      _showScanError(e.message);
      return;
    }
    
    // Check for card completion or overflow
    final newTotalStamps = card.stampsCollected + totalStampsAdded;
    if (newTotalStamps >= card.stampsRequired) {
      AppLogger.business('╔═══════════════════════════════════════════════════════════╗');
      AppLogger.business('║ CARD COMPLETE - AUTO-CREATING NEW CARD                   ║');
      AppLogger.business('╚═══════════════════════════════════════════════════════════╝');
      AppLogger.business('Current stamps: ${card.stampsCollected}');
      AppLogger.business('Adding: $totalStampsAdded');
      AppLogger.business('Total would be: $newTotalStamps');
      AppLogger.business('Required: ${card.stampsRequired}');
      
      final overflow = newTotalStamps - card.stampsRequired;
      final stampsForCurrentCard = card.stampsRequired - card.stampsCollected;

      AppLogger.business('Stamps to complete current card: $stampsForCurrentCard');
      AppLogger.business('Overflow stamps: $overflow');

      // Handle overflow stamps - check for existing card with space first (TEST-008 fix)
      // excludeCardId: the card being completed right here still shows
      // space at this point (it isn't marked complete until inside the
      // transaction below), so without this it would match itself and
      // overwrite its own just-set completed count with its stale one.
      final existingCard = await repository.findCardWithSpace(card.businessId, excludeCardId: card.id);

      // The rest of this branch (marking the current card complete, bumping
      // a destination card's count, and moving stamp rows via delete+insert
      // pairs) used to be separate, un-transacted writes. A crash partway
      // through - e.g. after the destination card's count was bumped but
      // before every stamp row finished moving - permanently lost stamp
      // rows while the count field claimed they existed, with no
      // adversarial input required (an ordinary OS-initiated app kill mid-
      // scan was enough). Wrapping the whole sequence in one transaction
      // means any failure rolls back to the pre-scan state instead of
      // leaving a card marked complete with missing stamps.
      int stampsToExistingCard = 0;
      int remainingOverflow = 0;

      await dbHelper.runInTransaction((txn) async {
        // Mark current card as complete
        await repository.updateStampCount(card!.id, card.stampsRequired, executor: txn);
        AppLogger.business('Current card now complete with ${card.stampsRequired} stamps');

        if (existingCard != null) {
          AppLogger.business('Found existing card with space: ${existingCard.id}');
          AppLogger.business('  Existing card: ${existingCard.stampsCollected}/${existingCard.stampsRequired}');

          // Calculate how many stamps can fit in existing card
          final availableSpace = existingCard.stampsRequired - existingCard.stampsCollected;
          stampsToExistingCard = overflow < availableSpace ? overflow : availableSpace;
          remainingOverflow = overflow - stampsToExistingCard;

          AppLogger.business('  Available space in existing card: $availableSpace');
          AppLogger.business('  Adding $stampsToExistingCard stamps to existing card');
          AppLogger.business('  Remaining overflow after: $remainingOverflow');

          // Update existing card with new stamp count
          await repository.updateStampCount(existingCard.id, existingCard.stampsCollected + stampsToExistingCard, executor: txn);

          // Move overflow stamps to existing card
          final allStamps = await stampRepo.getStampsByCard(card.id, executor: txn);
          final stampsToMove = allStamps.skip(_safeSkipCount(allStamps.length, overflow)).take(stampsToExistingCard).toList();

          AppLogger.database('Moving ${stampsToMove.length} stamps to existing card ${existingCard.id}...');

          for (var i = 0; i < stampsToMove.length; i++) {
            final oldStamp = stampsToMove[i];
            final newStampNumber = existingCard.stampsCollected + i + 1;

            // Delete from old card
            await stampRepo.deleteStamp(oldStamp.id, executor: txn);

            // Get previous hash (last stamp on existing card, or null if empty)
            final existingStamps = await stampRepo.getStampsByCard(existingCard.id, executor: txn);
            final previousHash = existingStamps.isNotEmpty ? existingStamps.last.signature : null;

            // Create on existing card
            //
            // originalCardId/originalStampNumber/originalPreviousHash: the
            // signature carried over unchanged below was signed against
            // oldStamp's position on its OLD card, not this new one - it
            // can't be recomputed here (only the supplier's private key
            // could re-sign it), so record what it was actually signed for,
            // carrying forward the true original if oldStamp was itself
            // already a moved stamp from an earlier overflow event.
            final newStamp = Stamp(
              id: '${existingCard.id}_stamp_$newStampNumber',
              cardId: existingCard.id,
              stampNumber: newStampNumber,
              timestamp: oldStamp.timestamp,
              signature: oldStamp.signature,
              previousHash: i == 0 ? previousHash : stampsToMove[i - 1].signature,
              deviceId: oldStamp.deviceId, // V-005: Preserve original device ID
              originalCardId: oldStamp.originalCardId ?? oldStamp.cardId,
              originalStampNumber: oldStamp.originalStampNumber ?? oldStamp.stampNumber,
              originalPreviousHash: oldStamp.originalPreviousHash ?? oldStamp.previousHash,
            );

            await stampRepo.insertStamp(newStamp, executor: txn);
            AppLogger.database('  Moved stamp #${oldStamp.stampNumber} -> existing card stamp #$newStampNumber');
          }

          // If there's STILL overflow after filling existing card, create new card for remainder
          if (remainingOverflow > 0) {
            AppLogger.business('Still have $remainingOverflow stamps after filling existing card');
            AppLogger.business('Creating new card for remaining overflow stamps');

            final newCardId = '${card.businessId}_${DateTime.now().millisecondsSinceEpoch}';
            final now = DateTime.now();
            final newCard = models.Card(
              id: newCardId,
              businessId: card.businessId,
              businessName: card.businessName,
              businessPublicKey: card.businessPublicKey,
              brandColor: card.brandColor,
              logoIndex: card.logoIndex,
              mode: card.mode,
              stampsRequired: card.stampsRequired,
              stampsCollected: remainingOverflow,
              createdAt: now,
              updatedAt: now,
            );

            await repository.insertCard(newCard, executor: txn);
            AppLogger.business('Created new card: $newCardId with $remainingOverflow stamps');

            // Move remaining overflow stamps to new card
            final remainingStamps = allStamps.skip(_safeSkipCount(allStamps.length, remainingOverflow)).toList();
            AppLogger.database('Moving ${remainingStamps.length} remaining stamps to new card...');

            for (var i = 0; i < remainingStamps.length; i++) {
              final oldStamp = remainingStamps[i];
              final newStampNumber = i + 1;

              // Delete from old card
              await stampRepo.deleteStamp(oldStamp.id, executor: txn);

              // Create on new card
              final newStamp = Stamp(
                id: '${newCardId}_stamp_$newStampNumber',
                cardId: newCardId,
                stampNumber: newStampNumber,
                timestamp: oldStamp.timestamp,
                signature: oldStamp.signature,
                previousHash: i == 0 ? null : remainingStamps[i - 1].signature,
                deviceId: oldStamp.deviceId, // V-005: Preserve original device ID
              );

              await stampRepo.insertStamp(newStamp, executor: txn);
              AppLogger.database('  Moved stamp #${oldStamp.stampNumber} -> new card stamp #$newStampNumber');
            }

            AppLogger.business('Overflow complete! Cards cascade:');
            AppLogger.business('  Original card (COMPLETE): ${card.stampsRequired} stamps');
            AppLogger.business('  Existing card (FILLED): ${existingCard.stampsCollected + stampsToExistingCard}/${existingCard.stampsRequired} stamps');
            AppLogger.business('  New card: $remainingOverflow stamps');
          } else {
            AppLogger.business('Overflow complete! All stamps placed in existing cards');
            AppLogger.business('  Original card (COMPLETE): ${card.stampsRequired} stamps');
            AppLogger.business('  Existing card: ${existingCard.stampsCollected + stampsToExistingCard}/${existingCard.stampsRequired} stamps');
          }
        } else {
          // No existing card with space - create new card (original behavior)
          AppLogger.business('No existing cards with space - creating new card');

          final newCardId = '${card.businessId}_${DateTime.now().millisecondsSinceEpoch}';
          final now = DateTime.now();
          final newCard = models.Card(
            id: newCardId,
            businessId: card.businessId,
            businessName: card.businessName,
            businessPublicKey: card.businessPublicKey,
            brandColor: card.brandColor,
            logoIndex: card.logoIndex,
            mode: card.mode, // Preserve the operation mode
            stampsRequired: card.stampsRequired,
            stampsCollected: overflow,
            createdAt: now,
            updatedAt: now,
          );

          await repository.insertCard(newCard, executor: txn);
          AppLogger.business('Created new card: $newCardId with $overflow stamps');

          // Move overflow stamps to new card
          // Get all stamps for the original card
          final allStamps = await stampRepo.getStampsByCard(card.id, executor: txn);
          AppLogger.database('Total stamps in original card: ${allStamps.length}');

          // Take the last 'overflow' stamps and move them to new card
          final stampsToMove = allStamps.skip(_safeSkipCount(allStamps.length, overflow)).toList();
          AppLogger.database('Moving ${stampsToMove.length} stamps to new card...');

          for (var i = 0; i < stampsToMove.length; i++) {
            final oldStamp = stampsToMove[i];
            final newStampNumber = i + 1;

            // Delete from old card
            await stampRepo.deleteStamp(oldStamp.id, executor: txn);

            // Create on new card with renumbered stamp number
            //
            // originalCardId/originalStampNumber/originalPreviousHash: see
            // the matching comment in the existing-card merge branch above -
            // the carried-over signature was signed for oldStamp's position
            // on its old card, not this new one.
            final newStamp = Stamp(
              id: '${newCardId}_stamp_$newStampNumber',
              cardId: newCardId,
              stampNumber: newStampNumber,
              timestamp: oldStamp.timestamp,
              signature: oldStamp.signature,
              previousHash: i == 0 ? null : stampsToMove[i - 1].signature,
              deviceId: oldStamp.deviceId, // V-005: Preserve original device ID
              originalCardId: oldStamp.originalCardId ?? oldStamp.cardId,
              originalStampNumber: oldStamp.originalStampNumber ?? oldStamp.stampNumber,
              originalPreviousHash: oldStamp.originalPreviousHash ?? oldStamp.previousHash,
            );

            await stampRepo.insertStamp(newStamp, executor: txn);
            AppLogger.database('  Moved stamp #${oldStamp.stampNumber} -> new card stamp #$newStampNumber');
          }

          AppLogger.business('Card split complete!');
          AppLogger.business('  Card 1 (COMPLETE): ${card.stampsRequired} stamps');
          AppLogger.business('  Card 2 (NEW): $overflow stamps');
        }
      });

      if (mounted) {
        String message;
        if (existingCard != null) {
          if (overflow == 0) {
            message = 'Card complete! 🎉 New card ready for ${card.businessName}';
          } else if (remainingOverflow > 0) {
            message = 'Card complete! 🎉 $stampsToExistingCard stamp${stampsToExistingCard > 1 ? 's' : ''} added to existing card, new card started with $remainingOverflow';
          } else {
            message = 'Card complete! 🎉 $stampsToExistingCard stamp${stampsToExistingCard > 1 ? 's' : ''} added to existing card';
          }
        } else {
          if (overflow == 0) {
            message = 'Card complete! 🎉 New card ready for ${card.businessName}';
          } else {
            message = 'Card complete! 🎉 New card started with $overflow stamp${overflow > 1 ? 's' : ''}';
          }
        }
        Navigator.pop(context, message);
      }
    } else {
      // No overflow - just update stamp count
      await repository.updateStampCount(card.id, newTotalStamps);
      AppLogger.business('Card updated: $newTotalStamps / ${card.stampsRequired} stamps');
      
      if (mounted) {
        final stampText = totalStampsAdded > 1 
            ? '$totalStampsAdded stamps added successfully!' 
            : 'Stamp added successfully!';
        Navigator.pop(context, stampText);
      }
    }
  }

  Future<void> _handleRedemptionToken(RedemptionToken token) async {
    AppLogger.qr('Processing Redemption Token ===');
    AppLogger.qr('Card ID: ${token.cardId}');
    AppLogger.business('Stamps redeemed: ${token.stampsRedeemed}');
    AppLogger.qr('Business ID: ${token.businessId}');

    // Get the card to verify it matches
    final repository = CardRepository(DatabaseHelper());
    final transactionRepo = TransactionRepository(DatabaseHelper());
    final card = await repository.getCardById(token.cardId);

    if (card == null) {
      _showScanError('Card not found. Please add the card first.');
      return;
    }

    // Verify card is from the same business
    if (card.businessId != token.businessId) {
      _showScanError('Card business mismatch');
      return;
    }

    // Verify card is complete
    if (!card.isComplete) {
      final remaining = card.stampsRequired - card.stampsCollected;
      _showScanError('This card isn\'t complete yet. You need $remaining more stamp${remaining > 1 ? 's' : ''} before you can redeem.');
      return;
    }

    // Check if card was already redeemed
    if (card.isRedeemed) {
      _showScanError('This card has already been redeemed!');
      return;
    }

    // Verify the redemption token signature (CR-1.4)
    final signatureData = token.getSignatureData();
    final verificationResult = KeyManager.verifySignature(
      signatureData,
      token.signature,
      card.businessPublicKey,
    );

    if (!verificationResult.isValid) {
      AppLogger.error('Redemption token signature verification failed: ${verificationResult.failureReason}');
      _showScanError('Invalid redemption signature: ${verificationResult.failureReason}');
      return;
    }

    AppLogger.qr('Redemption token signature verified OK');

    // Mark card as redeemed
    await repository.markCardAsRedeemed(card.id);
    AppLogger.database('Card marked as redeemed in database');
    
    // Log redemption transaction
    final redemptionTransaction = models.Transaction(
      id: const Uuid().v4(),
      cardId: card.id,
      type: TransactionType.redemption,
      timestamp: DateTime.now(),
      businessName: card.businessName,
      details: 'Reward redeemed: ${card.stampsCollected} stamps (secure mode)',
    );
    await transactionRepo.insertTransaction(redemptionTransaction);
    
    // Check for existing card with available space before creating new card
    final existingCard = await repository.findCardWithSpace(card.businessId);
    bool newCardCreated = false;
    
    if (existingCard != null) {
      AppLogger.business('Found existing card with space: ${existingCard.id}');
      AppLogger.business('  Existing card has ${existingCard.stampsCollected}/${existingCard.stampsRequired} stamps');
      AppLogger.business('  Skipping new card creation - will use existing card');
    } else {
      AppLogger.business('No existing cards with space found - creating new card');
      
      // Auto-create new card for continued loyalty
      final newCardId = '${card.businessId}_${DateTime.now().millisecondsSinceEpoch}';
      final now = DateTime.now();
      final newCard = models.Card(
        id: newCardId,
        businessId: card.businessId,
        businessName: card.businessName,
        businessPublicKey: card.businessPublicKey,
        brandColor: card.brandColor,
        logoIndex: card.logoIndex,
        mode: card.mode,
        stampsRequired: card.stampsRequired,
        stampsCollected: 0,
        createdAt: now,
        updatedAt: now,
      );
      
      await repository.insertCard(newCard);
      AppLogger.database('New card auto-created: $newCardId');
      newCardCreated = true;
    }

    AppLogger.qr('Redemption Complete');

    if (mounted) {
      Navigator.pop(context, 
        newCardCreated 
          ? '🎉 Redemption confirmed! New card added to your wallet.'
          : '🎉 Redemption confirmed!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == QRScanMode.addCard
        ? 'Scan your shop\'s card QR'
        : 'Scan Stamp QR';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF2C3E50),
      ),
      body: Stack(
        children: [
          // Camera view
          LayoutBuilder(
            builder: (context, constraints) {
              final mediaQuery = MediaQuery.of(context);
              final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
              
              // Apply rotation: base + manual offset
              final baseQuarterTurns = isLandscape ? 3 : 0;
              final quarterTurns = (baseQuarterTurns + _manualRotationOffset) % 4;
              
              AppLogger.debug('QR Scanner Orientation');
              AppLogger.debug('Orientation: ${isLandscape ? "Landscape" : "Portrait"}');
              AppLogger.debug('Base quarterTurns: $baseQuarterTurns, Manual offset: $_manualRotationOffset');
              AppLogger.debug('Applying quarterTurns: $quarterTurns (${quarterTurns * 90} degrees)');
              
              return RotatedBox(
                quarterTurns: quarterTurns,
                child: MobileScanner(
                  controller: _controller,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error) => ScannerPermissionErrorView(error: error),
                  onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  _handleQRCode(code);
                }
                  }
                },
                ),
              );
            },
          ),
          // Camera controls
          Positioned(
            top: 80,
            right: 16,
            child: Column(
              children: [
                // Camera flip (front/back switch)
                FloatingActionButton(
                  heroTag: 'flip_camera',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: () {
                    _controller.switchCamera();
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flip_camera_ios, size: 16, color: Colors.blue),
                      Text('Flip', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Rotate 90°
                FloatingActionButton(
                  heroTag: 'rotate90',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: () {
                    final newRotation = (_manualRotationOffset + 1) % 4;
                    setState(() {
                      _manualRotationOffset = newRotation;
                    });
                    _saveRotationPreference(newRotation);
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rotate_90_degrees_cw, size: 16, color: Colors.blue),
                      Text('90°', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.blue)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Rotate 180°
                FloatingActionButton(
                  heroTag: 'rotate180',
                  mini: true,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  onPressed: () {
                    final newRotation = (_manualRotationOffset + 2) % 4;
                    setState(() {
                      _manualRotationOffset = newRotation;
                    });
                    _saveRotationPreference(newRotation);
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flip, size: 16, color: Colors.blue),
                      Text('180°', style: TextStyle(fontSize: 8, height: 1.0, color: Colors.blue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Scanning frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  Text(
                    widget.mode == QRScanMode.addCard
                        ? 'Point camera at business QR code'
                        : 'Point camera at stamp token',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Flashlight toggle
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white, size: 32),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
        ],
      ),
    );
  }
}

enum QRScanMode {
  addCard,
  receiveStamp,
}

/// Q-003: thrown inside the stamp-crediting transaction to trigger a real
/// rollback (instead of a bare early return that leaves already-inserted
/// stamps in place), then caught outside the transaction to show the error.
class _StampCreditingAborted implements Exception {
  final String message;
  _StampCreditingAborted(this.message);
}

/// Q-006: `Iterable.skip()` throws `RangeError` for a negative count.
/// `length - wanted` can go negative if the actual stamp-row count is out
/// of sync with the expected overflow amount (e.g. legacy data, or a
/// previous crediting event that didn't fully complete) - clamping avoids
/// crashing the overflow-move flow on desynced data, moving as many stamps
/// as actually exist instead.
int _safeSkipCount(int length, int wanted) => (length - wanted).clamp(0, length);
