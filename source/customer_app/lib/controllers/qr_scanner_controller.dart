import 'package:shared/models/card.dart' as models;
import 'package:shared/models/operation_mode.dart';
import 'package:shared/models/qr_tokens.dart';
import 'package:shared/models/stamp.dart';
import 'package:shared/models/transaction.dart' as models;
import 'package:shared/utils/app_logger.dart';
import 'package:shared/utils/card_issue_qr_codec.dart';
import 'package:shared/utils/signature_format.dart';
import 'package:uuid/uuid.dart';

import '../services/card_repository.dart';
import '../services/database_helper.dart';
import '../services/device_service.dart';
import '../services/key_manager.dart';
import '../services/rate_limiter.dart';
import '../services/stamp_repository.dart';
import '../services/token_validator.dart';
import '../services/transaction_repository.dart';
import '../utils/error_message_mapper.dart';
import 'controller_results.dart';

/// Which kind of scan `QRScannerScreen` is performing.
///
/// Lives here rather than on the screen so the controller can branch on it
/// without importing any UI. `qr_scanner_screen.dart` re-exports it, so every
/// existing `import '.../qr_scanner_screen.dart'` call site is unaffected.
enum QRScanMode {
  addCard,
  receiveStamp,
}

/// Scan-handling logic for `QRScannerScreen`, extracted from the screen so it
/// is testable without a camera or a widget tree
/// (CODE_QUALITY_REVIEW_2026-08-21.md).
///
/// Follows the controller convention established in
/// `customer_card_detail_controller.dart` - read that file's header first;
/// this is the same pattern applied to a second screen, not a new design.
///
/// SCOPE: this is orchestration only. Every cryptographic step still runs in
/// the services it always did - `TokenValidator`, `SignatureFormat` +
/// `KeyManager` - and nothing about signature generation or verification is
/// reimplemented here. What moved is the sequence: look the card up, check the
/// rate limit, validate, apply the §4.1 profile snapshot, credit the stamps
/// atomically, then handle completion/overflow.
///
/// SMART ROUTING (Simple/Express Mode): a stamp token carrying the generic
/// `express-mode-stamp` / `simple-mode-stamp` card id is routed by
/// `businessId` to whichever of that business's cards has the most stamps and
/// still has room, so a stamp lands on the right card no matter which card
/// screen the customer happened to have open. Secure Mode matches on exact
/// card id instead.
class QrScannerController {
  QrScannerController({
    CardRepository? cardRepository,
    StampRepository? stampRepository,
    TransactionRepository? transactionRepository,
    RateLimiter? rateLimiter,
    DatabaseHelper? databaseHelper,
    Future<String> Function()? deviceIdProvider,
  })  : _cardRepo = cardRepository ?? CardRepository(DatabaseHelper()),
        _stampRepo = stampRepository ?? StampRepository(DatabaseHelper()),
        _transactionRepo = transactionRepository ?? TransactionRepository(DatabaseHelper()),
        _rateLimiter = rateLimiter ?? RateLimiter(DatabaseHelper()),
        _dbHelper = databaseHelper ?? DatabaseHelper(),
        _deviceIdProvider = deviceIdProvider ?? DeviceService.getDeviceId;

  final CardRepository _cardRepo;
  final StampRepository _stampRepo;
  final TransactionRepository _transactionRepo;
  final RateLimiter _rateLimiter;
  final DatabaseHelper _dbHelper;
  final Future<String> Function() _deviceIdProvider;

  /// Single entry point for a scanned payload.
  ///
  /// [onTokenRecognized] fires once the data has been parsed into a token but
  /// before any of the work it implies - that is the moment the screen gives
  /// its success haptic, which is the main signal a non-visual user gets that
  /// the camera registered anything at all, distinct from whether the scan
  /// ultimately succeeds. It is a callback rather than something this class
  /// does itself precisely so no UI dependency leaks in here.
  Future<ScanResult> handleQrCode(
    String qrData,
    QRScanMode mode, {
    void Function()? onTokenRecognized,
  }) async {
    try {
      QRToken? token = QRToken.fromQRString(qrData);

      // TEST-021: a card issued with pre-applied initial stamps may be
      // compact-encoded (gzip + Base45 + alphanumeric QR mode) instead of
      // plain JSON, the same way TEST-020 compact-encodes the redemption
      // QR - see DEFECT_TRACKER.md TEST-021. Base45's alphabet can never
      // be valid JSON, so QRToken.fromQRString above already fails
      // (returns null) on this data; only worth trying for addCard mode,
      // since that's the only token type using this encoding.
      if (token == null && mode == QRScanMode.addCard) {
        try {
          token = CardIssueQrCodec.decode(qrData);
        } catch (_) {
          // Not a compact-encoded card issue token either - fall through
          // to the "not valid" error below.
        }
      }

      if (token == null) {
        final message = mode == QRScanMode.receiveStamp
            ? 'This is not a valid stamp QR code. Please scan a stamp QR from the supplier app.'
            : 'This is not a valid card QR code. Please scan a card issuance QR.';
        return ScanResult.failure(ScanFailureReason.invalidQr, message);
      }

      onTokenRecognized?.call();

      switch (mode) {
        case QRScanMode.addCard:
          return await handleCardIssue(token);
        case QRScanMode.receiveStamp:
          return await handleStampToken(token);
      }
    } catch (e) {
      return ScanResult.failure(ScanFailureReason.unexpectedError, 'Error processing QR: $e');
    }
  }

  Future<ScanResult> handleCardIssue(QRToken token) async {
    if (token is! CardIssueToken) {
      return ScanResult.failure(
        ScanFailureReason.wrongTokenType,
        'Wrong QR type. Please scan a card issuance QR.',
      );
    }

    // Validate token
    final validation = await TokenValidator.validateCardIssueToken(token);
    if (!validation.isValid) {
      // TEST-019: TokenValidator now returns an already-specific,
      // user-facing message for structural failures (see
      // CardIssueToken.validationError()) - show it directly rather than
      // through ErrorMessageMapper, which would otherwise discard it for
      // a generic fallback since it doesn't match any of the mapper's
      // known technical-error substrings.
      return ScanResult.failure(
        ScanFailureReason.validationFailed,
        validation.error ?? ErrorMessageMapper.getUserMessage('Invalid token'),
      );
    }

    // Note: In simple mode, signature validation is skipped (trust-based)
    // In secure mode, full cryptographic validation is performed
    AppLogger.business('Card operation mode: ${token.mode.displayName}');

    // Use card ID from token if present (for multi-stamp consistency)
    // Otherwise generate new one (backward compatibility)
    final tokenCardId = token.cardId ?? '${token.businessId}_${DateTime.now().millisecondsSinceEpoch}';

    // Check if this specific card already exists (prevents duplicate scans of same QR)
    final existingCard = await _cardRepo.getCardById(tokenCardId);

    if (existingCard != null && !existingCard.isRedeemed) {
      // This exact card has already been scanned and is still active - block
      // to avoid a pointless duplicate. A business's "add card" QR is
      // static/reusable by design (Express Mode), so this is the ordinary
      // re-scan-the-same-QR-while-nothing-changed case, not a new cycle.
      //
      // Reported to the customer by returning to the previous screen with
      // this message, not as a scan error - hence its own failure reason.
      return ScanResult.failure(
        ScanFailureReason.alreadyScanned,
        'Card has already been scanned: ${token.businessName}',
      );
    }

    // A card with this exact (deterministic, QR-embedded) ID exists but has
    // already been redeemed - the customer is legitimately starting a new
    // loyalty cycle with the same business's reusable QR, not duplicating a
    // scan. Give the new card a fresh, unique ID instead of colliding with
    // the old redeemed row (which stays in their history) - this previously
    // blocked re-collecting from any business entirely once a card was
    // redeemed, since the QR's cardId never changes.
    //
    // If the QR also grants initial stamps, their signatures are
    // cryptographically bound to the original tokenCardId, not this new
    // cardId - same situation as an overflow-moved stamp, so the fix is the
    // same one: record originalCardId/originalStampNumber/originalPreviousHash
    // on each initial stamp so redemption verification checks it against
    // what it was actually signed for, instead of dropping the supplier's
    // grant.
    final isRepeatCycle = existingCard != null && existingCard.isRedeemed;
    final cardId = isRepeatCycle
        ? '${token.businessId}_${DateTime.now().millisecondsSinceEpoch}'
        : tokenCardId;

    final initialStampCount = token.initialStamps.length;

    // Get device ID for multi-device tracking (V-005)
    final deviceId = await _deviceIdProvider();

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
    await _cardRepo.insertCard(card);

    // Log card pickup transaction
    final pickupTransaction = models.Transaction(
      id: const Uuid().v4(),
      cardId: cardId,
      type: models.TransactionType.pickup,
      timestamp: DateTime.now(),
      businessName: token.businessName,
      details: 'Card added to wallet',
    );
    await _transactionRepo.insertTransaction(pickupTransaction);
    AppLogger.database('Logged pickup transaction for card $cardId');

    AppLogger.qr('Processing Card Issuance');
    AppLogger.business('Card ID: $cardId');
    AppLogger.business('Initial stamps to process: $initialStampCount');

    // Process initial stamps if present
    if (initialStampCount > 0) {
      String previousHash = ''; // First stamp has empty previous hash

      for (var initialStamp in token.initialStamps) {
        AppLogger.qr('Processing initial stamp #${initialStamp.stampNumber}');
        AppLogger.qr('  Card ID for stamp: $cardId');

        // Verify stamp signature (skip in simple mode) (CR-1.4)
        if (token.mode == OperationMode.secure) {
          // Must verify against tokenCardId - the ID this was actually
          // signed against - never the local storage cardId, which differs
          // from tokenCardId on a repeat cycle (see isRepeatCycle above).
          // Must match SignatureFormat.stampChainData exactly - see the
          // matching comment in qr_token_generator.dart's signing side.
          final signatureData = SignatureFormat.stampChainData(
            cardId: tokenCardId,
            stampNumber: initialStamp.stampNumber,
            timestampMs: initialStamp.timestamp,
            previousHash: previousHash,
            stampCount: 1,
          );
          final verificationResult = KeyManager.verifySignature(
            signatureData,
            initialStamp.signature,
            token.publicKey,
          );

          if (!verificationResult.isValid) {
            AppLogger.error('Initial stamp signature verification failed: ${verificationResult.failureReason}');
            // Rollback: delete the card
            await _cardRepo.deleteCard(cardId);
            return ScanResult.failure(
              ScanFailureReason.signatureInvalid,
              'Invalid stamp signature: ${verificationResult.failureReason}',
            );
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
          // On a repeat cycle, this stamp's signature was computed against
          // tokenCardId, not the fresh cardId it's being stored under here -
          // record what it was actually signed for so redemption
          // verification checks the right thing (same mechanism as an
          // overflow-moved stamp).
          originalCardId: isRepeatCycle ? tokenCardId : null,
          originalStampNumber: isRepeatCycle ? initialStamp.stampNumber : null,
          originalPreviousHash: isRepeatCycle ? (previousHash.isEmpty ? null : previousHash) : null,
        );

        await _stampRepo.insertStamp(stamp);
        AppLogger.database('  Initial stamp #${initialStamp.stampNumber} saved to DB');

        // Log stamp transaction
        final stampTransaction = models.Transaction(
          id: const Uuid().v4(),
          cardId: cardId,
          type: models.TransactionType.stamp,
          timestamp: DateTime.now(),
          businessName: token.businessName,
          details: 'Stamp #${initialStamp.stampNumber} earned',
        );
        await _transactionRepo.insertTransaction(stampTransaction);

        // Next stamp's previous hash is this stamp's signature
        previousHash = initialStamp.signature;
      }

      // Verify stamps were saved
      final savedStamps = await _stampRepo.getStampsByCard(cardId);
      AppLogger.database('Verification: ${savedStamps.length} stamps found in DB for card $cardId');
      for (var s in savedStamps) {
        final sigPreview = s.signature.length > 20 ? '${s.signature.substring(0, 20)}...' : s.signature;
        AppLogger.debug('  Stamp #${s.stampNumber}: $sigPreview');
      }
      AppLogger.qr('End Card Issuance Processing');
    }

    // Success! Return to home with success message
    final stampText = initialStampCount > 0
        ? ' with $initialStampCount stamp${initialStampCount > 1 ? 's' : ''}'
        : '';
    return ScanResult.success('Card added: ${card.businessName}$stampText');
  }

  Future<ScanResult> handleStampToken(QRToken token) async {
    // Get device ID for multi-device tracking (V-005)
    final deviceId = await _deviceIdProvider();

    // Handle redemption tokens
    if (token is RedemptionToken) {
      return handleRedemptionToken(token);
    }

    // Handle stamp tokens
    if (token is! StampToken) {
      final message = token is CardIssueToken
          ? 'This QR is for adding a new card, not collecting a stamp. Use Add Card to scan it.'
          : 'Wrong QR type. Please scan a stamp or redemption token QR.';
      return ScanResult.failure(ScanFailureReason.wrongTokenType, message);
    }

    // Get the card this stamp is for
    models.Card? matchedCard;

    // SMART ROUTING: For simple mode stamps, look up by businessId since cardId is generic
    // This ensures stamps go to the correct business card, regardless of which card screen
    // the user is currently viewing. Stamps are intelligently routed based on the QR code's
    // businessId, not the opened card.
    if ((token.cardId == 'express-mode-stamp' || token.cardId == 'simple-mode-stamp') && token.businessId.isNotEmpty) {
      AppLogger.qr('Express Mode Stamp Detected');
      AppLogger.business('Looking up card by businessId: ${token.businessId}');
      // findCardWithSpace (not getAllCards().firstWhere) - it excludes
      // redeemed/full cards and, when more than one active card exists for
      // this business (e.g. after an overflow-created empty card), picks
      // the one with the most stamps already collected rather than
      // whichever happens to match first. getAllCards() orders newest-first,
      // so the old firstWhere here always routed new stamps onto the most
      // recently created card instead of finishing off one already partway
      // full - reported as stamps landing on a fresh empty card while an
      // older, closer-to-complete card for the same business sat untouched.
      matchedCard = await _cardRepo.findCardWithSpace(token.businessId);
      if (matchedCard != null) {
        AppLogger.business('Found card with ID: ${matchedCard.id}');
      } else {
        AppLogger.debug('No card with space found for businessId: ${token.businessId}');
      }
    } else {
      // Secure mode: look up by exact cardId
      matchedCard = await _cardRepo.getCardById(token.cardId);
    }

    if (matchedCard == null) {
      return ScanResult.failure(
        ScanFailureReason.cardNotFound,
        'Card not found. Please add the card first.',
      );
    }

    // Non-nullable from here on. `card` is still reassigned below by the §4.1
    // copyWith chain; keeping it non-nullable is what lets that happen without
    // the force-unwraps the original needed once flow promotion was lost.
    var card = matchedCard;

    // Check rate limiting (REQ-022: Use token's scanInterval if present)
    final rateLimit = await _rateLimiter.canReceiveStamp(
      cardId: card.id,
      businessId: card.businessId,
      mode: card.mode,
      scanInterval: token.scanInterval, // REQ-022: Supplier-specific rate limit
    );

    if (!rateLimit.canProceed) {
      // Rate limit hit - the screen returns to the card screen immediately
      // rather than showing an inline error, to prevent customers waiting on
      // the camera screen and re-scanning the moment the timeout expires.
      AppLogger.warning('Rate limit hit - returning to card screen', 'RateLimit');
      return ScanResult.failure(
        ScanFailureReason.rateLimited,
        rateLimit.message ?? 'Please wait before scanning again',
      );
    }

    // Get expected previous hash
    final stamps = await _stampRepo.getStampsByCard(card.id);
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
        return ScanResult.failure(
          ScanFailureReason.validationFailed,
          ErrorMessageMapper.getUserMessage(validation.error ?? 'Invalid stamp'),
        );
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
        return ScanResult.failure(ScanFailureReason.validationFailed, 'Invalid stamp token');
      }
    } else {
      // REQ-022: Simple mode - validate expiry date and stamp count (skip crypto)
      AppLogger.debug('Simple mode: Validating expiry and stamp count only', 'Token');

      // Check expiry date if present
      if (token.expiryDate != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > token.expiryDate!) {
          return ScanResult.failure(ScanFailureReason.validationFailed, 'This stamp token has expired');
        }
      }

      // Validate stamp count
      if (token.stampCount > card.stampsRequired) {
        return ScanResult.failure(
          ScanFailureReason.validationFailed,
          'Invalid stamp count: ${token.stampCount} exceeds ${card.stampsRequired}',
        );
      }
    }

    // Requirements/DISCUSSION_Business_Field_Editing.md §4.1: apply this
    // token's business-profile snapshot, if it carries one. Name/icon/color
    // are purely cosmetic - always take the freshest known value. stampsRequired
    // follows the directional policy: an in-progress card only ever moves
    // DOWN (never a retroactive increase); any snapshot value (higher or
    // lower) is also recorded separately in latestStampsRequiredSnapshot,
    // for the *next* card to pick up at redemption (see
    // handleRedemptionToken/CustomerCardDetailController.processRedemption) -
    // never applied retroactively to this card. An older token/app version
    // that never sends these fields changes nothing here.
    bool cardProfileChanged = false;
    if (token.businessName != null && token.businessName != card.businessName) {
      card = card.copyWith(businessName: token.businessName);
      cardProfileChanged = true;
    }
    if (token.brandColor != null && token.brandColor != card.brandColor) {
      card = card.copyWith(brandColor: token.brandColor);
      cardProfileChanged = true;
    }
    if (token.logoIndex != null && token.logoIndex != card.logoIndex) {
      card = card.copyWith(logoIndex: token.logoIndex);
      cardProfileChanged = true;
    }
    if (token.stampsRequired != null) {
      if (token.stampsRequired != card.latestStampsRequiredSnapshot) {
        card = card.copyWith(latestStampsRequiredSnapshot: token.stampsRequired);
        cardProfileChanged = true;
      }
      if (token.stampsRequired! < card.stampsRequired) {
        card = card.copyWith(stampsRequired: token.stampsRequired);
        cardProfileChanged = true;
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
      await _dbHelper.runInTransaction((txn) async {
        await _stampRepo.insertStamp(stamp, executor: txn);
        AppLogger.database('Main stamp saved to DB');

        if (cardProfileChanged) {
          // A stampsRequired decrease can make the in-memory card's current
          // stampsCollected momentarily exceed the new target - the
          // completion/overflow check just below resolves this properly
          // (updateStampCount bypasses validation and is not affected by
          // this), but a direct write of `card` as-is here would trip
          // CardRepository's stampsCollected <= stampsRequired invariant.
          // Cap only the copy written here; `card` itself (used below for
          // newTotalStamps) is untouched.
          final cardForWrite = card.stampsCollected > card.stampsRequired
              ? card.copyWith(stampsCollected: card.stampsRequired)
              : card;
          await _cardRepo.updateCard(cardForWrite, executor: txn);
          AppLogger.database('Card profile snapshot applied (§4.1)');
        }

        final stampTransaction = models.Transaction(
          id: const Uuid().v4(),
          cardId: card.id,
          type: models.TransactionType.stamp,
          timestamp: DateTime.now(),
          businessName: card.businessName,
          details: 'Stamp #$stampNumber earned',
        );
        await _transactionRepo.insertTransaction(stampTransaction, executor: txn);

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

            await _stampRepo.insertStamp(additionalStamp, executor: txn);
            totalStampsAdded++;
            AppLogger.database('  Multi-denomination stamp $i saved to DB');

            // Log stamp transaction
            final addlStampTransaction = models.Transaction(
              id: const Uuid().v4(),
              cardId: card.id,
              type: models.TransactionType.stamp,
              timestamp: DateTime.now(),
              businessName: card.businessName,
              details: 'Stamp #$additionalStampNumber earned (multi-denomination)',
            );
            await _transactionRepo.insertTransaction(addlStampTransaction, executor: txn);
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

            await _stampRepo.insertStamp(additionalStampRecord, executor: txn);
            totalStampsAdded++;
            AppLogger.database('  Additional stamp saved to DB');

            // Log stamp transaction
            final addlStampTransaction = models.Transaction(
              id: const Uuid().v4(),
              cardId: card.id,
              type: models.TransactionType.stamp,
              timestamp: DateTime.now(),
              businessName: card.businessName,
              details: 'Stamp #${additionalStamp.stampNumber} earned',
            );
            await _transactionRepo.insertTransaction(addlStampTransaction, executor: txn);

            // Next stamp's previous hash is this stamp's signature
            currentPreviousHash = additionalStamp.signature;
          }
          AppLogger.qr('All Additional Stamps Processed');
        }
      });
    } on _StampCreditingAborted catch (e) {
      return ScanResult.failure(ScanFailureReason.creditingAborted, e.message);
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
      final existingCard = await _cardRepo.findCardWithSpace(card.businessId, excludeCardId: card.id);

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

      await _dbHelper.runInTransaction((txn) async {
        // Mark current card as complete
        await _cardRepo.updateStampCount(card.id, card.stampsRequired, executor: txn);
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
          await _cardRepo.updateStampCount(existingCard.id, existingCard.stampsCollected + stampsToExistingCard, executor: txn);

          // Move overflow stamps to existing card
          final allStamps = await _stampRepo.getStampsByCard(card.id, executor: txn);
          final stampsToMove = allStamps.skip(_safeSkipCount(allStamps.length, overflow)).take(stampsToExistingCard).toList();

          AppLogger.database('Moving ${stampsToMove.length} stamps to existing card ${existingCard.id}...');

          for (var i = 0; i < stampsToMove.length; i++) {
            final oldStamp = stampsToMove[i];
            final newStampNumber = existingCard.stampsCollected + i + 1;

            // Delete from old card
            await _stampRepo.deleteStamp(oldStamp.id, executor: txn);

            // Get previous hash (last stamp on existing card, or null if empty)
            final existingStamps = await _stampRepo.getStampsByCard(existingCard.id, executor: txn);
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
            final newStamp = oldStamp.relocateTo(
              id: '${existingCard.id}_stamp_$newStampNumber',
              cardId: existingCard.id,
              stampNumber: newStampNumber,
              previousHash: i == 0 ? previousHash : stampsToMove[i - 1].signature,
            );

            await _stampRepo.insertStamp(newStamp, executor: txn);
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
              // §4.1: this new card is exactly the "next card" a pending
              // increase should take effect on - card.stampsRequired alone
              // would still be whatever the just-completed card required,
              // since an increase never mutates that field directly.
              stampsRequired: card.latestStampsRequiredSnapshot ?? card.stampsRequired,
              stampsCollected: remainingOverflow,
              createdAt: now,
              updatedAt: now,
            );

            await _cardRepo.insertCard(newCard, executor: txn);
            AppLogger.business('Created new card: $newCardId with $remainingOverflow stamps');

            // Move remaining overflow stamps to new card
            final remainingStamps = allStamps.skip(_safeSkipCount(allStamps.length, remainingOverflow)).toList();
            AppLogger.database('Moving ${remainingStamps.length} remaining stamps to new card...');

            for (var i = 0; i < remainingStamps.length; i++) {
              final oldStamp = remainingStamps[i];
              final newStampNumber = i + 1;

              // Delete from old card
              await _stampRepo.deleteStamp(oldStamp.id, executor: txn);

              // Create on new card
              //
              // TEST-018: this branch previously built a plain Stamp(...)
              // here and omitted originalCardId/originalStampNumber/
              // originalPreviousHash entirely - silently dropping
              // provenance for stamps in this specific three-way split
              // (original card -> existing card -> new card for the
              // remainder), which would break signature verification for
              // them at redemption. relocateTo() sets these correctly.
              final newStamp = oldStamp.relocateTo(
                id: '${newCardId}_stamp_$newStampNumber',
                cardId: newCardId,
                stampNumber: newStampNumber,
                previousHash: i == 0 ? null : remainingStamps[i - 1].signature,
              );

              await _stampRepo.insertStamp(newStamp, executor: txn);
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
            // §4.1: this new card is exactly the "next card" a pending
            // increase should take effect on - card.stampsRequired alone
            // would still be whatever the just-completed card required,
            // since an increase never mutates that field directly.
            stampsRequired: card.latestStampsRequiredSnapshot ?? card.stampsRequired,
            stampsCollected: overflow,
            createdAt: now,
            updatedAt: now,
          );

          await _cardRepo.insertCard(newCard, executor: txn);
          AppLogger.business('Created new card: $newCardId with $overflow stamps');

          // Move overflow stamps to new card
          // Get all stamps for the original card
          final allStamps = await _stampRepo.getStampsByCard(card.id, executor: txn);
          AppLogger.database('Total stamps in original card: ${allStamps.length}');

          // Take the last 'overflow' stamps and move them to new card
          final stampsToMove = allStamps.skip(_safeSkipCount(allStamps.length, overflow)).toList();
          AppLogger.database('Moving ${stampsToMove.length} stamps to new card...');

          for (var i = 0; i < stampsToMove.length; i++) {
            final oldStamp = stampsToMove[i];
            final newStampNumber = i + 1;

            // Delete from old card
            await _stampRepo.deleteStamp(oldStamp.id, executor: txn);

            // Create on new card with renumbered stamp number
            final newStamp = oldStamp.relocateTo(
              id: '${newCardId}_stamp_$newStampNumber',
              cardId: newCardId,
              stampNumber: newStampNumber,
              previousHash: i == 0 ? null : stampsToMove[i - 1].signature,
            );

            await _stampRepo.insertStamp(newStamp, executor: txn);
            AppLogger.database('  Moved stamp #${oldStamp.stampNumber} -> new card stamp #$newStampNumber');
          }

          AppLogger.business('Card split complete!');
          AppLogger.business('  Card 1 (COMPLETE): ${card.stampsRequired} stamps');
          AppLogger.business('  Card 2 (NEW): $overflow stamps');
        }
      });

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
      return ScanResult.success(message);
    } else {
      // No overflow - just update stamp count
      await _cardRepo.updateStampCount(card.id, newTotalStamps);
      AppLogger.business('Card updated: $newTotalStamps / ${card.stampsRequired} stamps');

      final stampText = totalStampsAdded > 1
          ? '$totalStampsAdded stamps added successfully!'
          : 'Stamp added successfully!';
      return ScanResult.success(stampText);
    }
  }

  Future<ScanResult> handleRedemptionToken(RedemptionToken token) async {
    AppLogger.qr('Processing Redemption Token ===');
    AppLogger.qr('Card ID: ${token.cardId}');
    AppLogger.business('Stamps redeemed: ${token.stampsRedeemed}');
    AppLogger.qr('Business ID: ${token.businessId}');

    // Get the card to verify it matches
    final card = await _cardRepo.getCardById(token.cardId);

    if (card == null) {
      return ScanResult.failure(
        ScanFailureReason.cardNotFound,
        'Card not found. Please add the card first.',
      );
    }

    // Verify card is from the same business
    if (card.businessId != token.businessId) {
      return ScanResult.failure(ScanFailureReason.businessMismatch, 'Card business mismatch');
    }

    // Verify card is complete
    if (!card.isComplete) {
      final remaining = card.stampsRequired - card.stampsCollected;
      return ScanResult.failure(
        ScanFailureReason.cardNotComplete,
        'This card isn\'t complete yet. You need $remaining more stamp${remaining > 1 ? 's' : ''} before you can redeem.',
      );
    }

    // Check if card was already redeemed
    if (card.isRedeemed) {
      return ScanResult.failure(ScanFailureReason.alreadyRedeemed, 'This card has already been redeemed!');
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
      return ScanResult.failure(
        ScanFailureReason.signatureInvalid,
        'Invalid redemption signature: ${verificationResult.failureReason}',
      );
    }

    AppLogger.qr('Redemption token signature verified OK');

    // Mark card as redeemed
    await _cardRepo.markCardAsRedeemed(card.id);
    AppLogger.database('Card marked as redeemed in database');

    // Log redemption transaction
    final redemptionTransaction = models.Transaction(
      id: const Uuid().v4(),
      cardId: card.id,
      type: models.TransactionType.redemption,
      timestamp: DateTime.now(),
      businessName: card.businessName,
      details: 'Reward redeemed: ${card.stampsCollected} stamps (secure mode)',
    );
    await _transactionRepo.insertTransaction(redemptionTransaction);

    // Check for existing card with available space before creating new card
    final existingCard = await _cardRepo.findCardWithSpace(card.businessId);
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
        // businessName/brandColor/logoIndex are already kept fresh on the
        // old card by every ordinary stamp scan (see handleStampToken
        // §4.1), so cloning them here is already correct. stampsRequired is
        // the one field that's deliberately NOT kept fresh on an
        // in-progress card (an increase never applies retroactively) - the
        // snapshot recorded separately is what carries a genuine increase
        // forward to this new card. Falls back to the old card's own value
        // if no snapshot was ever seen (old-format tokens, or no scan since
        // the last change).
        businessName: card.businessName,
        businessPublicKey: card.businessPublicKey,
        brandColor: card.brandColor,
        logoIndex: card.logoIndex,
        mode: card.mode,
        stampsRequired: card.latestStampsRequiredSnapshot ?? card.stampsRequired,
        stampsCollected: 0,
        createdAt: now,
        updatedAt: now,
      );

      await _cardRepo.insertCard(newCard);
      AppLogger.database('New card auto-created: $newCardId');
      newCardCreated = true;
    }

    AppLogger.qr('Redemption Complete');

    return ScanResult.success(
      newCardCreated
          ? '🎉 Redemption confirmed! New card added to your wallet.'
          : '🎉 Redemption confirmed!',
    );
  }
}

/// Q-003: thrown inside the stamp-crediting transaction to trigger a real
/// rollback (instead of a bare early return that leaves already-inserted
/// stamps in place), then caught outside the transaction and turned into a
/// [ScanResult] failure.
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
