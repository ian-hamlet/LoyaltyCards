/// Result objects returned by the screen controllers in this directory.
///
/// Mirrors the convention established in
/// `customer_app/lib/controllers/controller_results.dart` (see that file and
/// `customer_card_detail_controller.dart`'s header for the full template) -
/// this is the same shape applied to the supplier app's screens, not a new
/// design: a bool `isSuccess`, a nullable failure reason enum, a message, and
/// any success payload as further fields. `throw` remains reserved for
/// genuine programmer error / unreachable states.
library;

import 'package:shared/models/qr_tokens.dart';

/// Why a `SupplierStampCardController` or `SupplierRedeemCardController`
/// operation failed. Shared across both controllers since their failure
/// vocabulary overlaps heavily (parsing/validating a scanned token).
enum SupplierScanFailureReason {
  /// The business record could not be loaded.
  loadFailed,

  /// The scanned data was not a token this screen/mode understands at all,
  /// or was readable but the wrong type.
  invalidQr,

  /// A readable, correctly-typed token that failed its own structural
  /// validation (`token.isValid()`).
  invalidToken,

  /// The token's `businessId` doesn't match this device's business.
  businessMismatch,

  /// The stamp-request QR aged out before the supplier processed it.
  qrExpired,

  /// Generating the outgoing stamp/redemption token failed.
  generationFailed,

  /// Redemption-specific: the card this token identifies wasn't found.
  cardNotFound,

  /// Redemption-specific: signature/chain verification failed.
  verificationFailed,

  /// Redemption-specific: this card was already redeemed.
  alreadyRedeemed,

  /// Redemption-specific: a completed-card QR was scanned in stamp mode -
  /// not an error, just the customer's card isn't full yet.
  notReadyYet,

  /// Redemption-specific: the device that's currently showing the
  /// redemption QR isn't the device the card was created on (V-005).
  deviceMismatch,

  /// Anything that escaped as an exception - the catch-all the screens used
  /// to render as a generic error message.
  unexpectedError,
}

/// Outcome of `loadBusiness()` on either supplier-screen controller.
class SupplierLoadResult {
  final bool isSuccess;
  final SupplierScanFailureReason? failureReason;
  final String? errorMessage;

  SupplierLoadResult.success()
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  SupplierLoadResult.failure(this.failureReason, this.errorMessage) : isSuccess = false;
}

/// Outcome of `SupplierStampCardController.parseStampRequest()`.
///
/// [token]/[previousHash] are only meaningful when [isSuccess] is true - the
/// [token] is already known valid at that point, so the State class doesn't
/// need to re-null-check it before showing the stamp-count selector dialog.
class ParsedStampRequest {
  final bool isSuccess;
  final SupplierScanFailureReason? failureReason;
  final String? errorMessage;
  final CardStampRequestToken? token;
  final String? previousHash;

  ParsedStampRequest.success(this.token, this.previousHash)
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  ParsedStampRequest.failure(this.failureReason, this.errorMessage)
      : isSuccess = false,
        token = null,
        previousHash = null;
}

/// Outcome of `SupplierStampCardController.generateStampToken()` /
/// `generateExpressModeToken()`.
class StampGenerationResult {
  final bool isSuccess;
  final SupplierScanFailureReason? failureReason;
  final String? errorMessage;
  final StampToken? stampToken;

  StampGenerationResult.success(this.stampToken)
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  StampGenerationResult.failure(this.failureReason, this.errorMessage)
      : isSuccess = false,
        stampToken = null;
}

/// Outcome of `SupplierRedeemCardController.parseRedemptionQr()`.
///
/// [token] is null on a legacy-format match (`LOYALTYCARD:REDEEM:...`) even
/// on success - that format never carried a full token, only a bare
/// cardId/stamp count, exactly mirroring the pre-extraction code's own
/// `_showSecureModeRedemptionConfirmation(context, cardId, stamps)` call
/// with no `token:` argument.
class ParsedRedemptionQr {
  final bool isSuccess;
  final SupplierScanFailureReason? failureReason;
  final String? errorMessage;
  final String? cardId;
  final int? stampsCollected;
  final RedemptionRequestToken? token;

  ParsedRedemptionQr.success({required this.cardId, required this.stampsCollected, this.token})
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  ParsedRedemptionQr.failure(this.failureReason, this.errorMessage)
      : isSuccess = false,
        cardId = null,
        stampsCollected = null,
        token = null;
}

/// Outcome of `SupplierRedeemCardController.validateRedemptionToken()`.
///
/// A [failureReason] of [SupplierScanFailureReason.deviceMismatch] means
/// this isn't a hard failure - the State class shows the device-mismatch
/// confirmation dialog rather than a plain error, and may call
/// `confirmRedemption` afterwards anyway if the supplier chooses to proceed.
class TokenValidationResult {
  final bool isSuccess;
  final SupplierScanFailureReason? failureReason;
  final String? errorMessage;

  TokenValidationResult.valid()
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  TokenValidationResult.failure(this.failureReason, this.errorMessage) : isSuccess = false;
}

/// Outcome of `SupplierRedeemCardController.confirmRedemption()`.
class RedemptionConfirmResult {
  final bool isSuccess;
  final SupplierScanFailureReason? failureReason;
  final String? errorMessage;
  final RedemptionToken? redemptionToken;
  final int? stampsRedeemed;

  RedemptionConfirmResult.success(this.redemptionToken, this.stampsRedeemed)
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  RedemptionConfirmResult.failure(this.failureReason, this.errorMessage)
      : isSuccess = false,
        redemptionToken = null,
        stampsRedeemed = null;
}

/// Outcome of `SupplierRedeemCardController.recordManualRedemption()`
/// (Express/Simple Mode's honor-based redemption path).
class ManualRedemptionResult {
  final bool isSuccess;
  final SupplierScanFailureReason? failureReason;
  final String? errorMessage;
  final DateTime? redeemedAt;
  final int? stampsRedeemed;

  ManualRedemptionResult.success(this.redeemedAt, this.stampsRedeemed)
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  ManualRedemptionResult.failure(this.failureReason, this.errorMessage)
      : isSuccess = false,
        redeemedAt = null,
        stampsRedeemed = null;
}
