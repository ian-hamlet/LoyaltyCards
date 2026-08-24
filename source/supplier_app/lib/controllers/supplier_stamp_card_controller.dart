import 'package:shared/models/business.dart';
import 'package:shared/models/qr_tokens.dart';
import 'package:shared/constants/constants.dart';
import 'package:shared/utils/app_logger.dart';

import '../services/business_repository.dart';
import '../services/key_manager.dart';
import '../services/qr_token_generator.dart';
import 'controller_results.dart';

/// Business/crypto logic for `SupplierStampCard`, extracted from the screen
/// so it can be tested without a widget tree
/// (CODE_QUALITY_REVIEW_2026-08-21.md).
///
/// Follows the controller convention established in
/// `customer_app/lib/controllers/customer_card_detail_controller.dart` -
/// read that file's header first; this is the same pattern applied to the
/// supplier side, not a new design: plain Dart class, no UI imports,
/// dependencies as optional named constructor params with real defaults,
/// Result objects instead of thrown exceptions for expected failures.
///
/// SCOPE: this is orchestration and token generation only. Signing itself
/// still happens inside `QRTokenGenerator`/`KeyManager`, unchanged - nothing
/// about signature generation is reimplemented here. What moved is the
/// sequence: parse the scanned stamp-request token, validate it, check it
/// against this business, then generate the outgoing stamp token(s).
///
/// The one haptic call this controller makes is via [onTokenRecognized] in
/// [parseStampRequest] - fired the moment a scanned payload is recognized as
/// a plausible `CardStampRequestToken`, before deeper validation runs,
/// mirroring exactly when the pre-extraction code fired its own success
/// haptic. Every other haptic/error-display decision stays in the State
/// class, driven off the returned Result.
class SupplierStampCardController {
  SupplierStampCardController({
    BusinessRepository? businessRepository,
    QRTokenGenerator? tokenGenerator,
  })  : _businessRepo = businessRepository ?? BusinessRepository(),
        _tokenGenerator = tokenGenerator ?? QRTokenGenerator(KeyManager());

  final BusinessRepository _businessRepo;
  final QRTokenGenerator _tokenGenerator;

  Business? _business;
  Business? get business => _business;

  /// Load the business record this device belongs to.
  Future<SupplierLoadResult> loadBusiness() async {
    try {
      _business = await _businessRepo.getBusiness();
      return SupplierLoadResult.success();
    } catch (e) {
      return SupplierLoadResult.failure(
        SupplierScanFailureReason.loadFailed,
        'Error loading business: $e',
      );
    }
  }

  /// Parse and validate a scanned stamp-request QR payload against the
  /// currently loaded business.
  ///
  /// [onTokenRecognized] fires once the payload is confirmed to be a
  /// well-typed `CardStampRequestToken` - the same "the camera registered
  /// something" moment the pre-extraction code signalled with its success
  /// haptic - regardless of whether the deeper validation below it
  /// subsequently fails. Requires [loadBusiness] to have already succeeded;
  /// throws if not, since the screen only reaches the scanner once a
  /// business is loaded (a genuine programmer error otherwise, not a
  /// user-facing failure).
  Future<ParsedStampRequest> parseStampRequest(
    String qrData, {
    void Function()? onTokenRecognized,
  }) async {
    final business = _business;
    if (business == null) {
      throw StateError('parseStampRequest() called before a business was loaded');
    }

    try {
      final token = QRToken.fromQRString(qrData);

      if (token is! CardStampRequestToken) {
        return ParsedStampRequest.failure(
          SupplierScanFailureReason.invalidQr,
          'Invalid QR code. Please scan a stamp request QR.',
        );
      }

      // A readable, correctly-typed code was recognized - the main
      // non-visual signal that the camera registered anything at all,
      // distinct from whether the request is ultimately accepted below.
      onTokenRecognized?.call();

      if (!token.isValid()) {
        return ParsedStampRequest.failure(
          SupplierScanFailureReason.invalidToken,
          'Invalid token format',
        );
      }

      if (token.businessId != business.id) {
        return ParsedStampRequest.failure(
          SupplierScanFailureReason.businessMismatch,
          'This card belongs to a different business',
        );
      }

      // Log card activity (tracks unique cards using the system)
      await _businessRepo.logCardActivity(token.cardId, business.id);

      // Check timestamp (must be < 1 minute old)
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = now - token.timestamp;
      if (age > AppConstants.stampRequestExpiryMs) {
        return ParsedStampRequest.failure(
          SupplierScanFailureReason.qrExpired,
          'QR code expired. Customer needs to generate a new one.',
        );
      }

      final previousHash = token.lastStampHash; // Use customer's last stamp hash

      AppLogger.business(
        'Processing stamp request - Card: ${token.cardId.substring(0, 8)}, '
        'Stamps: ${token.currentStamps} → ${token.currentStamps + 1}',
      );
      AppLogger.debug(
        'Last stamp hash: "${token.lastStampHash.isEmpty ? "(empty)" : "${token.lastStampHash.substring(0, 20)}..."}"',
        'Stamp',
      );

      return ParsedStampRequest.success(token, previousHash);
    } catch (e) {
      return ParsedStampRequest.failure(
        SupplierScanFailureReason.unexpectedError,
        'Error processing QR: $e',
      );
    }
  }

  /// Generate the outgoing (Secure Mode) stamp token once the supplier has
  /// chosen how many stamps to award via the count-selector dialog - which
  /// stays in the State class as pure UI, gating the call to this method.
  Future<StampGenerationResult> generateStampToken(
    CardStampRequestToken token,
    String previousHash,
    int stampCount,
  ) async {
    final business = _business;
    if (business == null) {
      throw StateError('generateStampToken() called before a business was loaded');
    }

    try {
      final additionalStampCount = stampCount - 1; // First stamp is main, rest are additional

      final stampToken = await _tokenGenerator.generateStampToken(
        businessId: business.id,
        cardId: token.cardId,
        stampNumber: token.currentStamps + 1,
        previousHash: previousHash,
        additionalStampCount: additionalStampCount,
        businessName: business.name,
        brandColor: business.brandColor,
        logoIndex: business.logoIndex,
        stampsRequired: business.stampsRequired,
      );

      // NOTE: Stamps are logged when CUSTOMER successfully scans and validates,
      // not when supplier generates the token. This prevents counting stamps
      // that were generated but never received due to errors.

      return StampGenerationResult.success(stampToken);
    } catch (e) {
      return StampGenerationResult.failure(
        SupplierScanFailureReason.generationFailed,
        'Error generating stamp: $e',
      );
    }
  }

  /// Generate an Express Mode stamp token - reusable, not tied to any
  /// specific customer card, REQ-022 multi-denomination/expiry aware.
  Future<StampGenerationResult> generateExpressModeToken({
    required int stampCount,
    DateTime? expiryDate,
  }) async {
    final business = _business;
    if (business == null) {
      throw StateError('generateExpressModeToken() called before a business was loaded');
    }

    try {
      // REQ-022: Validate stamp count
      if (stampCount < 1 || stampCount > business.stampsRequired) {
        throw Exception('Invalid stamp count: must be 1-${business.stampsRequired}');
      }

      // Calculate expiry timestamp if applicable
      int? expiryTimestamp;
      if (expiryDate != null) {
        expiryTimestamp = expiryDate.millisecondsSinceEpoch;
        AppLogger.debug('Token expiry set to: $expiryDate', 'StampToken');
      }

      // For simple mode, generate a generic stamp token.
      // It's reusable and doesn't require customer card info.
      final stampToken = await _tokenGenerator.generateStampToken(
        businessId: business.id,
        cardId: 'express-mode-stamp', // Generic ID for express mode
        stampNumber: 1, // Generic stamp number
        previousHash: '', // No hash chain in simple mode
        additionalStampCount: 0,
        stampCount: stampCount, // REQ-022: Multi-denomination support
        expiryDate: expiryTimestamp, // REQ-022: Optional expiry
        scanInterval: business.scanInterval, // REQ-022: Supplier-specific rate limit
        businessName: business.name,
        brandColor: business.brandColor,
        logoIndex: business.logoIndex,
        stampsRequired: business.stampsRequired,
      );

      AppLogger.debug('Generated $stampCount-stamp token for ${business.name}', 'StampToken');
      return StampGenerationResult.success(stampToken);
    } catch (e) {
      AppLogger.error('Failed to generate simple mode token: $e', tag: 'StampToken');
      return StampGenerationResult.failure(
        SupplierScanFailureReason.generationFailed,
        'Error generating stamp: $e',
      );
    }
  }
}
