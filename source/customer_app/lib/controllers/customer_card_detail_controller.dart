import 'dart:convert';

import 'package:qr_flutter/qr_flutter.dart' show QrCode, QrErrorCorrectLevel;
import 'package:shared/models/card.dart' as models;
import 'package:shared/models/stamp.dart';
import 'package:shared/models/transaction.dart' as models;
import 'package:shared/utils/alphanumeric_qr.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:shared/utils/qr_capacity.dart';
import 'package:shared/utils/redemption_qr_codec.dart';
import 'package:uuid/uuid.dart';

import '../services/card_repository.dart';
import '../services/database_helper.dart';
import '../services/device_service.dart';
import '../services/qr_token_generator.dart';
import '../services/stamp_repository.dart';
import '../services/transaction_repository.dart';
import '../utils/error_message_mapper.dart';
import 'controller_results.dart';

/// ============================================================================
/// CONTROLLER CONVENTION - copy this shape for the remaining screen
/// extractions. This is the first file written to it; treat it as the
/// template rather than reinventing anything.
/// ============================================================================
///
/// 1. **Plain Dart class, never a ChangeNotifier.** The State classes in this
///    app already rebuild by `setState()`-ing after awaiting a controller
///    call; a second notification mechanism would just be a way for the two
///    to disagree.
///
/// 2. **No UI imports.** No `BuildContext`, no `Widget`, no
///    `package:flutter/material.dart`, and deliberately no
///    `package:shared/shared.dart` either - that barrel re-exports
///    `widgets/`, so importing it would quietly drag the whole widget layer
///    back in. Import the specific `shared/models/...` and `shared/utils/...`
///    files instead. That restriction is the entire point: it is what lets
///    these tests run without pumping a widget tree.
///
///    The one unavoidable exception is `qr_flutter`, which is where the
///    `QrCode` *data* type lives (it is re-exported from the `qr` package,
///    which is not a direct dependency of this app). Only the data types are
///    imported, never `QrImageView`; `shared/utils/qr_capacity.dart` already
///    does exactly this.
///
/// 3. **Dependencies are optional named constructor params with real
///    defaults**, so production callers construct the controller with no
///    arguments exactly as they used to construct repositories inline
///    (`final CardRepository _cardRepo = CardRepository(...)`), while tests
///    inject fakes.
///
/// 4. **Result objects, not thrown exceptions, for expected failures.** The
///    precedent is `supplier_app/lib/models/backup_result.dart`
///    (`BackupResult`): a bool `isSuccess`, a success payload, and a failure
///    reason plus message. Every controller method that can fail in an
///    ordinary way - a card that is missing, a QR that is too large, a write
///    that the database rejects - returns one of those instead of throwing.
///    `throw` stays reserved for genuine programmer error / unreachable
///    states, matching how the rest of this codebase uses it. Shared result
///    types live in `controllers/controller_results.dart`.
///
/// 5. **Mid-flow dialogs split prepare/commit.** Where a flow needs a
///    confirmation in the middle, the controller exposes the work on either
///    side of it as separate methods and the dialog itself stays in the State
///    class as pure UI - see `processRedemption()`, which the State calls
///    only after its own confirmation dialog returns true, and whose result
///    then feeds the success dialog.
///
/// ============================================================================
///
/// Business and QR-generation logic for `CustomerCardDetail`, extracted from
/// the screen so it can be tested without a widget tree
/// (CODE_QUALITY_REVIEW_2026-08-21.md). Holds the loaded card/stamp data and
/// the QR artefacts derived from it; the screen reads them back through
/// getters and rebuilds with `setState()`.
class CustomerCardDetailController {
  CustomerCardDetailController({
    required this.cardId,
    CardRepository? cardRepository,
    StampRepository? stampRepository,
    TransactionRepository? transactionRepository,
    QRTokenGenerator? qrTokenGenerator,
    Future<String> Function()? deviceIdProvider,
  })  : _cardRepo = cardRepository ?? CardRepository(DatabaseHelper()),
        _stampRepo = stampRepository ?? StampRepository(DatabaseHelper()),
        _transactionRepo = transactionRepository ?? TransactionRepository(DatabaseHelper()),
        _qrTokenGenerator = qrTokenGenerator ?? QRTokenGenerator(),
        _deviceIdProvider = deviceIdProvider ?? DeviceService.getDeviceId;

  final String cardId;

  final CardRepository _cardRepo;
  final StampRepository _stampRepo;
  final TransactionRepository _transactionRepo;
  final QRTokenGenerator _qrTokenGenerator;
  final Future<String> Function() _deviceIdProvider;

  models.Card? _card;
  List<Stamp> _stamps = [];
  String? _currentDeviceId; // V-005: Cache device ID for QR generation

  // Q-007: cache the generated QR string instead of regenerating it on every
  // build - it embeds a live timestamp, so any incidental rebuild (rotation,
  // an unrelated setState elsewhere on screen) produced a visibly different
  // QR code even though nothing the user did changed. Recomputed only when
  // card/stamp data is actually reloaded.
  String? _cachedQrData;

  // TEST-017/TEST-020: a redemption QR for a high-stamp-count Secure Mode
  // card (or one with several overflow-relocated stamps) can exceed a QR
  // code's maximum encodable capacity. TEST-020 makes this dramatically
  // less likely (gzip+Base45+alphanumeric-mode encoding via
  // RedemptionQrCodec/AlphanumericQr - see DEFECT_TRACKER.md), but doesn't
  // make it impossible for an arbitrarily large payload, and an
  // already-issued pre-TEST-020 card could still be affected. Built once
  // when card data loads, alongside _qrTooLargeToRender, so the screen's
  // build() can check without redoing the (non-trivial - tries QR versions
  // 1-40) work on every rebuild.
  QrCode? _redemptionQrCode;
  bool _qrTooLargeToRender = false;

  models.Card? get card => _card;
  List<Stamp> get stamps => _stamps;
  String? get currentDeviceId => _currentDeviceId;
  String? get cachedQrData => _cachedQrData;
  QrCode? get redemptionQrCode => _redemptionQrCode;
  bool get qrTooLargeToRender => _qrTooLargeToRender;

  /// Load this card and its stamps, then rebuild whichever QR artefact the
  /// card's state calls for.
  ///
  /// On failure the previously loaded card/stamp data is left untouched, the
  /// same as before the extraction: the assignment only happens once both
  /// reads have succeeded.
  Future<CardDetailLoadResult> load() async {
    // V-005: Get device ID for redemption QR (fetch once, cache).
    // Deliberately outside the try, matching the original ordering -
    // DeviceService.getDeviceId() handles its own failures internally and
    // falls back rather than throwing.
    _currentDeviceId = await _deviceIdProvider();

    try {
      final card = await _cardRepo.getCardById(cardId);
      final stamps = await _stampRepo.getStampsByCard(cardId);

      AppLogger.debug('Card data loaded: ${card?.businessName} (${card?.id})', 'CardDetail');
      AppLogger.debug('Stamps collected: ${card?.stampsCollected}', 'CardDetail');
      AppLogger.debug('Stamp records in DB: ${stamps.length}', 'CardDetail');
      for (var stamp in stamps) {
        AppLogger.debug('  Stamp #${stamp.stampNumber} at ${stamp.timestamp}', 'CardDetail');
      }

      _card = card;
      _stamps = stamps;

      // generateCardQr()/buildRedemptionQrCode() read _card/_stamps, which
      // were just assigned above, so this reflects the freshly-loaded data.
      if (card != null && card.isComplete && !card.isRedeemed) {
        _cachedQrData = null;
        _redemptionQrCode = buildRedemptionQrCode();
        _qrTooLargeToRender = _redemptionQrCode == null;
      } else {
        _redemptionQrCode = null;
        _qrTooLargeToRender = false;
        _cachedQrData = generateCardQr();
      }

      return CardDetailLoadResult.success();
    } catch (e) {
      AppLogger.error('Error loading card data', error: e, tag: 'CardDetail');
      return CardDetailLoadResult.failure(
        CardDetailFailureReason.loadFailed,
        ErrorMessageMapper.forOperation(e, 'load card'),
      );
    }
  }

  // TEST-020: builds the redemption QR as an alphanumeric-mode QrCode via
  // RedemptionQrCodec (gzip + Base45) instead of the plain-JSON byte-mode
  // string generateCardQr() used to produce for this case - see
  // DEFECT_TRACKER.md TEST-020 for the size comparison that motivated
  // this. Returns null if the payload doesn't fit even at the largest QR
  // version, or if the generator rejects inconsistent card/stamp data -
  // either way, the caller falls back to the "too large to display" panel
  // (stamp history below it still proves what's been earned).
  // TEST-022: same fix as the supplier app's issue-card QR - prefer plain
  // JSON (readable by any supplier app version) whenever it actually
  // fits, and only fall back to the compact encoding for the genuinely
  // oversized case (high stamp count and/or heavily overflow-relocated).
  // The decode side (supplier_redeem_card.dart) already tries plain JSON
  // first, so no change needed there.
  QrCode? buildRedemptionQrCode() {
    final card = _card;
    if (card == null) return null;
    AppLogger.qr('Card is COMPLETE - generating REDEMPTION QR (TEST-020 compact encoding)');
    AppLogger.qr('Including ${_stamps.length} stamps for redemption');
    try {
      final token = _qrTokenGenerator.generateRedemptionRequest(
        card: card,
        stamps: _stamps,
        cardDeviceId: card.deviceId, // V-005: Device where card was created
        currentDeviceId: _currentDeviceId, // V-005: Device showing redemption QR (cached)
      );
      final plainJson = token.toQRString();
      if (QrCapacity.fits(plainJson)) {
        return QrCode.fromData(data: plainJson, errorCorrectLevel: QrErrorCorrectLevel.L);
      }
      final compact = RedemptionQrCodec.encode(token);
      return AlphanumericQr.build(compact);
    } catch (e) {
      AppLogger.error('Failed to build redemption QR', error: e, tag: 'QR');
      return null;
    }
  }

  /// The stamp-request QR payload shown to the supplier.
  ///
  /// CROSS-APP CONTRACT: the supplier app parses this exact JSON through
  /// `CardStampRequestToken.fromJson` (see
  /// `supplier_app/lib/screens/supplier/supplier_stamp_card.dart`'s
  /// `_handleQRCode`). The field names and types below must stay
  /// byte-compatible with that model - every card already in circulation
  /// depends on it. `customer_card_detail_controller_test.dart` pins the
  /// shape against `CardStampRequestToken` itself.
  String generateCardQr() {
    final card = _card;
    if (card == null) return '';

    // If card has been redeemed, don't generate any QR
    if (card.isRedeemed) {
      AppLogger.qr('Card REDEEMED - no QR generation');
      return 'REDEEMED'; // Special marker to show redeemed message instead of QR
    }

    // Redemption QR (card complete) is handled separately by
    // buildRedemptionQrCode() - TEST-020.

    // Otherwise, generate stamp request QR
    String lastStampHash = '';
    if (_stamps.isNotEmpty) {
      lastStampHash = _stamps.last.signature;
      AppLogger.qr('Including lastStampHash from stamp #${_stamps.last.stampNumber}');
      final hashPreview = lastStampHash.length > 20 ? '${lastStampHash.substring(0, 20)}...' : lastStampHash;
      AppLogger.qr('Hash = "$hashPreview"');
    } else {
      AppLogger.qr('No stamps, lastStampHash will be empty');
    }

    final qrData = {
      'type': 'card_stamp_request',
      'cardId': card.id,
      'businessId': card.businessId,
      'currentStamps': card.stampsCollected,
      'publicKey': card.businessPublicKey,
      'lastStampHash': lastStampHash,  // NOW INCLUDED!
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(qrData);
  }

  /// Commit half of the Express Mode redemption flow.
  ///
  /// The confirmation dialog that gates this stays in the State class - by
  /// the time this runs, the customer has already said yes. Everything here
  /// is database work, so the success dialog can be driven entirely off the
  /// returned result (notably [RedemptionResult.newCardCreated], which it
  /// must not guess at - see Q-004 below).
  ///
  /// The caller is expected to [load] again afterwards before showing that
  /// dialog, so the screen reflects the redeemed state.
  Future<RedemptionResult> processRedemption() async {
    final card = _card;
    if (card == null) {
      // Unreachable: the Redeem button only exists once a card is loaded and
      // complete. A genuine programmer error, so it throws rather than
      // returning a failure result the UI would have to render.
      throw StateError('processRedemption() called before a card was loaded');
    }

    try {
      final now = DateTime.now();

      // Mark card as redeemed
      await _cardRepo.markCardAsRedeemed(card.id);

      // Log redemption transaction
      final redemptionTransaction = models.Transaction(
        id: const Uuid().v4(),
        cardId: card.id,
        type: models.TransactionType.redemption,
        timestamp: now,
        businessName: card.businessName,
        details: 'Reward redeemed: ${card.stampsCollected} stamps',
      );
      await _transactionRepo.insertTransaction(redemptionTransaction);

      AppLogger.business('Simple Mode Redemption');
      AppLogger.debug('Card ID: ${card.id}', 'Redemption');
      AppLogger.debug('Business: ${card.businessName}', 'Redemption');
      AppLogger.debug('Stamps: ${card.stampsCollected}', 'Redemption');
      AppLogger.debug('Redeemed at: ${now.toIso8601String()}', 'Redemption');

      // Check for existing card with available space before creating new card
      final existingCard = await _cardRepo.findCardWithSpace(card.businessId);
      // Q-004 fix: track whether a new card was actually created so the
      // success dialog can say so accurately - it previously claimed
      // "a new card has been added" unconditionally, even when an existing
      // under-filled card was reused instead.
      bool newCardCreated = false;

      if (existingCard != null) {
        AppLogger.business('Found existing card with space: ${existingCard.id}');
        AppLogger.business('  Existing card has ${existingCard.stampsCollected}/${existingCard.stampsRequired} stamps');
        AppLogger.business('  Skipping new card creation - will use existing card');
      } else {
        AppLogger.business('No existing cards with space found - creating new card');

        // Auto-create new card for continued loyalty
        //
        // businessName/brandColor/logoIndex are already kept fresh on the
        // old card by every ordinary stamp scan (see
        // QrScannerController.handleStampToken §4.1), so cloning them here is
        // already correct. stampsRequired uses the separately-tracked
        // snapshot, falling back to the old card's own value if none was
        // ever seen - see the matching comment in
        // QrScannerController.handleRedemptionToken (Requirements/
        // DISCUSSION_Business_Field_Editing.md §4.1).
        final newCardId = '${card.businessId}_${DateTime.now().millisecondsSinceEpoch}';
        final newCard = models.Card(
          id: newCardId,
          businessId: card.businessId,
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

      return RedemptionResult.success(newCardCreated: newCardCreated, redeemedAt: now);
    } catch (e) {
      AppLogger.error('Error redeeming card', error: e, tag: 'CardDetail');
      return RedemptionResult.failure(
        CardDetailFailureReason.redeemFailed,
        ErrorMessageMapper.forOperation(e, 'redeem card'),
      );
    }
  }
}
