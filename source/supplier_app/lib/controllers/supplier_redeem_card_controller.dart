import 'dart:convert';

import 'package:shared/models/business.dart';
import 'package:shared/models/operation_mode.dart';
import 'package:shared/models/qr_tokens.dart';
import 'package:shared/utils/app_logger.dart';
import 'package:shared/utils/crypto_utils.dart';
import 'package:shared/utils/redemption_qr_codec.dart';
import 'package:shared/utils/signature_format.dart';

import '../services/business_repository.dart';
import '../services/key_manager.dart';
import 'controller_results.dart';

/// Business/crypto logic for `SupplierRedeemCard`, extracted from the
/// screen so it can be tested without a widget tree
/// (CODE_QUALITY_REVIEW_2026-08-21.md).
///
/// Follows the controller convention established in
/// `customer_app/lib/controllers/customer_card_detail_controller.dart` -
/// read that file's header first; this is the same pattern applied to the
/// supplier side, mirroring the verification-side shape already applied to
/// `QrScannerController.handleRedemptionToken`, not a new design.
///
/// SCOPE: this is orchestration and token generation only. Signature
/// verification still happens inside `CryptoUtils`, signing inside
/// `KeyManager`, and QR decoding inside `RedemptionQrCodec` - nothing about
/// crypto itself is reimplemented here.
///
/// FLOW: [parseRedemptionQr] recognizes a scanned payload as one of three
/// formats (plain JSON, TEST-020 compact-encoded, or legacy
/// `LOYALTYCARD:REDEEM:`). For a real `RedemptionRequestToken` (the first
/// two formats), the State class then calls [validateRedemptionToken] -
/// which may report a device mismatch rather than a hard failure, in which
/// case the State shows its own confirmation dialog before optionally
/// calling [confirmRedemption] anyway. The legacy format skips straight to
/// [confirmRedemption] with no token, exactly mirroring the pre-extraction
/// code's own call shape.
class SupplierRedeemCardController {
  SupplierRedeemCardController({
    BusinessRepository? businessRepository,
    KeyManager? keyManager,
  })  : _businessRepo = businessRepository ?? BusinessRepository(),
        _keyManager = keyManager ?? KeyManager();

  final BusinessRepository _businessRepo;
  final KeyManager _keyManager;

  Business? _business;
  Business? get business => _business;

  /// Load the business record this device belongs to.
  Future<SupplierLoadResult> loadBusiness() async {
    try {
      _business = await _businessRepo.getBusiness();
      return SupplierLoadResult.success();
    } catch (e) {
      return SupplierLoadResult.failure(SupplierScanFailureReason.loadFailed, null);
    }
  }

  /// Record an Express/Simple Mode redemption - honor-based, no signature
  /// to verify (see V-001). Uses the business loaded by [loadBusiness].
  Future<ManualRedemptionResult> recordManualRedemption() async {
    final business = _business;
    if (business == null) {
      throw StateError('recordManualRedemption() called before a business was loaded');
    }

    try {
      final now = DateTime.now();
      final cardId = 'simple_redemption_${now.millisecondsSinceEpoch}';

      await _businessRepo.logRedemption(
        cardId: cardId,
        stampsRedeemed: business.stampsRequired,
        businessId: business.id,
      );

      AppLogger.business('Simple Mode Redemption Logged');
      AppLogger.debug('Business: ${business.name}', 'Redemption');
      AppLogger.debug('Stamps: ${business.stampsRequired}', 'Redemption');
      AppLogger.debug('Timestamp: ${now.toIso8601String()}', 'Redemption');

      return ManualRedemptionResult.success(now, business.stampsRequired);
    } catch (e) {
      return ManualRedemptionResult.failure(
        SupplierScanFailureReason.unexpectedError,
        'Error recording redemption: $e',
      );
    }
  }

  /// Parse a scanned redemption QR payload, trying plain JSON, then the
  /// TEST-020 compact gzip+Base45 encoding, then the legacy
  /// `LOYALTYCARD:REDEEM:cardId:stamps` format.
  ///
  /// [onTokenRecognized] fires as soon as *any* readable payload is
  /// recognized in one of these formats - the same "the camera registered
  /// something" moment the pre-extraction code signalled with its own
  /// `Haptics.success()` calls, at each of the three matching points,
  /// regardless of whether the payload later turns out to be a card that
  /// isn't ready to redeem, or of what [validateRedemptionToken] /
  /// [confirmRedemption] finds afterwards.
  Future<ParsedRedemptionQr> parseRedemptionQr(
    String qrData, {
    void Function()? onTokenRecognized,
  }) async {
    AppLogger.qr('Processing Redemption QR');
    AppLogger.qr('QR Data: ${qrData.substring(0, qrData.length > 100 ? 100 : qrData.length)}...');

    try {
      // Try parsing as JSON token first (plain-JSON format)
      final json = jsonDecode(qrData) as Map<String, dynamic>;
      onTokenRecognized?.call();

      if (json['type'] == 'redemption_request') {
        final token = RedemptionRequestToken.fromJson(json);
        return ParsedRedemptionQr.success(
          cardId: token.cardId,
          stampsCollected: token.stampsCollected,
          token: token,
        );
      } else if (json['type'] == 'card_stamp_request') {
        // Customer is showing a stamp request QR, not a redemption QR -
        // their card isn't complete yet.
        final stampToken = CardStampRequestToken.fromJson(json);
        final stampsCollected = stampToken.currentStamps;
        return ParsedRedemptionQr.failure(
          SupplierScanFailureReason.notReadyYet,
          "This card isn't ready to redeem yet.\n\nCustomer has $stampsCollected stamps but needs all stamps to be complete before redeeming.",
        );
      } else {
        return ParsedRedemptionQr.failure(
          SupplierScanFailureReason.invalidQr,
          'Please scan a completed loyalty card for redemption.',
        );
      }
    } catch (e) {
      AppLogger.debug('Failed to parse as plain-JSON token: $e', 'QR');

      // TEST-020: not valid JSON - try the compact gzip+Base45 redemption
      // encoding before falling back further. Base45's alphabet (digits,
      // uppercase letters, a handful of symbols - no `{`, `"`, or
      // lowercase) can never be valid JSON text, so there's no ambiguity
      // between this and the plain-JSON path above.
      try {
        final token = RedemptionQrCodec.decode(qrData);
        onTokenRecognized?.call();
        return ParsedRedemptionQr.success(
          cardId: token.cardId,
          stampsCollected: token.stampsCollected,
          token: token,
        );
      } catch (e2) {
        AppLogger.debug('Failed to parse as compact redemption token: $e2', 'QR');
      }

      // Fall back to legacy format: LOYALTYCARD:REDEEM:cardId:stamps
      if (qrData.startsWith('LOYALTYCARD:REDEEM:')) {
        final parts = qrData.split(':');
        if (parts.length >= 4) {
          final cardId = parts[2];
          final stamps = int.tryParse(parts[3]) ?? 0;
          AppLogger.qr('Legacy redemption format detected');
          onTokenRecognized?.call();
          return ParsedRedemptionQr.success(cardId: cardId, stampsCollected: stamps, token: null);
        }
      }

      return ParsedRedemptionQr.failure(
        SupplierScanFailureReason.invalidQr,
        'Unable to read this QR code. Please ask the customer to show their completed loyalty card.',
      );
    }
  }

  /// Structural validation of a real `RedemptionRequestToken` (the plain-JSON
  /// or compact-decode paths only - the legacy format never reaches this,
  /// exactly mirroring the pre-extraction code's own call shape). A
  /// [TokenValidationResult] with `failureReason ==
  /// SupplierScanFailureReason.deviceMismatch` isn't a hard failure - see
  /// this controller's own class-level FLOW note.
  TokenValidationResult validateRedemptionToken(RedemptionRequestToken token) {
    AppLogger.qr('Redemption token parsed successfully');
    AppLogger.qr('Card ID: ${token.cardId}');
    AppLogger.qr('Stamps collected: ${token.stampsCollected}');
    AppLogger.qr('Signatures to verify: ${token.stampProofs.length}');

    // Structural check, including stampProofs.length == stampsCollected -
    // without this, verifyRedemptionStampChain only confirms that
    // whichever proofs WERE submitted are individually valid, never
    // that their count actually backs the claimed stampsCollected used
    // to sign the reward in confirmRedemption below.
    if (!token.isValid()) {
      AppLogger.error(
        'Redemption rejected - malformed/inconsistent token for card ${token.cardId}',
        tag: 'Security',
      );
      return TokenValidationResult.failure(SupplierScanFailureReason.invalidToken, 'Invalid redemption request.');
    }

    // V-005: Check for device mismatch
    if (token.hasDeviceMismatch()) {
      AppLogger.warning('Device mismatch detected!', 'Security');
      AppLogger.warning('Card device: ${token.cardDeviceId}', 'Security');
      AppLogger.warning('Current device: ${token.currentDeviceId}', 'Security');
      return TokenValidationResult.failure(SupplierScanFailureReason.deviceMismatch, null);
    }

    return TokenValidationResult.valid();
  }

  /// Verify (Secure Mode only), sign, and log a redemption - the core
  /// operation behind both the primary scan flow and the "proceed anyway"
  /// path after a device-mismatch warning.
  ///
  /// Deliberately re-fetches the business record fresh via [_businessRepo]
  /// rather than using [_business] - matching the pre-extraction code's own
  /// `_showSecureModeRedemptionConfirmation`, which always read current
  /// business config at confirmation time rather than trusting whatever was
  /// cached when the screen first loaded.
  Future<RedemptionConfirmResult> confirmRedemption(
    String cardId,
    int stamps, {
    RedemptionRequestToken? token,
  }) async {
    final business = await _businessRepo.getBusiness();
    if (business == null) {
      return RedemptionConfirmResult.failure(SupplierScanFailureReason.loadFailed, 'Business not configured');
    }

    // V-013: refuse to redeem a card that's already been redeemed. Previously
    // nothing checked this - the only "already redeemed" state was the
    // isRedeemed flag on the customer's own device, which they fully
    // control (e.g. a restored pre-redemption local backup resets it).
    final alreadyRedeemed = await _businessRepo.hasBeenRedeemed(cardId);
    if (alreadyRedeemed) {
      AppLogger.warning('Redemption rejected - card $cardId already redeemed', 'Security');
      return RedemptionConfirmResult.failure(
        SupplierScanFailureReason.alreadyRedeemed,
        'This card has already been redeemed.',
      );
    }

    // V-012: independently verify the customer's claimed stamps before
    // signing off on a reward. Previously this flow trusted `stamps`
    // (the customer's self-reported count) outright, with no cryptographic
    // check at all - a fabricated or replayed redemption request would be
    // signed just as readily as a genuine one.
    //
    // Express/Simple Mode is intentionally honor-based (no stamp signatures
    // exist to check - see V-001), so verification only applies to Secure
    // Mode businesses.
    if (business.mode == OperationMode.secure) {
      if (token == null) {
        AppLogger.error(
          'Secure Mode redemption via unsigned/legacy format rejected for card $cardId',
          tag: 'Security',
        );
        return RedemptionConfirmResult.failure(
          SupplierScanFailureReason.verificationFailed,
          "This redemption method isn't supported for Secure Mode. Ask the customer to update their app.",
        );
      }

      final chainResult = CryptoUtils.verifyRedemptionStampChain(
        cardId: cardId,
        stampProofs: token.stampProofs,
        businessPublicKey: business.publicKey,
      );

      if (!chainResult.isValid) {
        AppLogger.error(
          'Redemption rejected - stamp chain verification failed for card $cardId: ${chainResult.failureReason}',
          tag: 'Security',
        );
        return RedemptionConfirmResult.failure(
          SupplierScanFailureReason.verificationFailed,
          "Unable to verify this card's stamps. Redemption denied.",
        );
      }

      // The chain check above only confirms the submitted proofs are
      // individually genuine and unique - it says nothing about whether
      // that's actually enough to complete THIS business's card. Without
      // this, a customer with a few genuinely-earned stamps on a card
      // that needs many more could still get a full reward signed.
      if (token.stampsCollected < business.stampsRequired) {
        AppLogger.error(
          'Redemption rejected - card $cardId claims ${token.stampsCollected} stamps but business requires ${business.stampsRequired}',
          tag: 'Security',
        );
        return RedemptionConfirmResult.failure(
          SupplierScanFailureReason.verificationFailed,
          "This card isn't complete yet.",
        );
      }

      AppLogger.business('Redemption stamp chain verified ($stamps stamps)');
    }

    // Generate redemption token
    final now = DateTime.now();
    final privateKey = await _keyManager.getPrivateKey(business.id);

    if (privateKey == null) {
      return RedemptionConfirmResult.failure(SupplierScanFailureReason.generationFailed, 'Private key not found');
    }

    // Signature data - single source of truth in SignatureFormat.redemptionTokenData,
    // shared with RedemptionToken.getSignatureData()
    final signatureData = SignatureFormat.redemptionTokenData(
      cardId: cardId,
      stampsRedeemed: stamps,
      timestampMs: now.millisecondsSinceEpoch,
    );
    final signature = await _keyManager.signData(signatureData, privateKey);

    if (signature == null) {
      return RedemptionConfirmResult.failure(SupplierScanFailureReason.generationFailed, 'Failed to sign redemption token');
    }

    final redemptionToken = RedemptionToken(
      cardId: cardId,
      businessId: business.id,
      stampsRedeemed: stamps,
      signature: signature,
      timestamp: now.millisecondsSinceEpoch,
    );

    AppLogger.business('Redemption Token Generated');
    AppLogger.debug('Card ID: $cardId', 'Redemption');
    AppLogger.debug('Stamps redeemed: $stamps', 'Redemption');
    AppLogger.debug('Signature: ${signature.substring(0, 20)}...', 'Redemption');
    AppLogger.debug('Token type: redemption_token', 'Redemption');

    // Log the redemption for analytics
    await _businessRepo.logRedemption(cardId: cardId, stampsRedeemed: stamps, businessId: business.id);
    AppLogger.database('Redemption logged to database');

    return RedemptionConfirmResult.success(redemptionToken, stamps);
  }
}
