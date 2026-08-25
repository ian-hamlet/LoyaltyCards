/// Result objects returned by the screen controllers in this directory.
///
/// Mirrors the convention established in
/// `customer_app/lib/controllers/controller_results.dart` (see that file and
/// `customer_card_detail_controller.dart`'s header for the full template) -
/// this is the same shape applied to the supplier app's screens, not a new
/// design: a bool `isSuccess`, a nullable failure reason enum, a message, and
/// any success payload as further fields. `throw` remains reserved for
/// genuine programmer error / unreachable states.
///
/// Every class below shares that exact 3-field shape (`isSuccess`,
/// `failureReason`, `errorMessage`) via the [SupplierResult] base - a
/// follow-up code-quality pass found the original 7 classes hand-copying
/// those fields and their `.success()`/`.failure()` constructors instead of
/// sharing one base. Only ever add a payload field a class actually needs,
/// exactly as before - the base just removes the duplication of the common
/// three.
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

/// Shared shape for every result class below: a success/failure flag, a
/// nullable [SupplierScanFailureReason], and an error message (always null
/// on success, matching every one of these classes' original behavior).
/// Subclasses add whatever payload fields their own operation needs and
/// forward to [SupplierResult.success]/[SupplierResult.failure] from their
/// own `.success()`/`.failure()` constructors - the public API of every
/// subclass (name, constructor signature, field names) is unchanged from
/// before this base existed.
abstract class SupplierResult {
  final bool isSuccess;
  final SupplierScanFailureReason? failureReason;
  final String? errorMessage;

  const SupplierResult.success()
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  const SupplierResult.failure(this.failureReason, this.errorMessage) : isSuccess = false;
}

/// Outcome of `loadBusiness()` on either supplier-screen controller.
class SupplierLoadResult extends SupplierResult {
  const SupplierLoadResult.success() : super.success();

  const SupplierLoadResult.failure(super.failureReason, super.errorMessage) : super.failure();
}

/// Outcome of `SupplierStampCardController.parseStampRequest()`.
///
/// [token]/[previousHash] are only meaningful when [SupplierResult.isSuccess]
/// is true - the [token] is already known valid at that point, so the State
/// class doesn't need to re-null-check it before showing the stamp-count
/// selector dialog.
class ParsedStampRequest extends SupplierResult {
  final CardStampRequestToken? token;
  final String? previousHash;

  ParsedStampRequest.success(this.token, this.previousHash) : super.success();

  ParsedStampRequest.failure(super.failureReason, super.errorMessage)
      : token = null,
        previousHash = null,
        super.failure();
}

/// Outcome of `SupplierStampCardController.generateStampToken()` /
/// `generateExpressModeToken()`.
class StampGenerationResult extends SupplierResult {
  final StampToken? stampToken;

  StampGenerationResult.success(this.stampToken) : super.success();

  StampGenerationResult.failure(super.failureReason, super.errorMessage)
      : stampToken = null,
        super.failure();
}

/// Outcome of `SupplierRedeemCardController.parseRedemptionQr()`.
///
/// [token] is null on a legacy-format match (`LOYALTYCARD:REDEEM:...`) even
/// on success - that format never carried a full token, only a bare
/// cardId/stamp count, exactly mirroring the pre-extraction code's own
/// `_showSecureModeRedemptionConfirmation(context, cardId, stamps)` call
/// with no `token:` argument.
class ParsedRedemptionQr extends SupplierResult {
  final String? cardId;
  final int? stampsCollected;
  final RedemptionRequestToken? token;

  ParsedRedemptionQr.success({required this.cardId, required this.stampsCollected, this.token}) : super.success();

  ParsedRedemptionQr.failure(super.failureReason, super.errorMessage)
      : cardId = null,
        stampsCollected = null,
        token = null,
        super.failure();
}

/// Outcome of `SupplierRedeemCardController.validateRedemptionToken()`.
///
/// A [SupplierResult.failureReason] of
/// [SupplierScanFailureReason.deviceMismatch] means this isn't a hard
/// failure - the State class shows the device-mismatch confirmation dialog
/// rather than a plain error, and may call `confirmRedemption` afterwards
/// anyway if the supplier chooses to proceed.
class TokenValidationResult extends SupplierResult {
  const TokenValidationResult.valid() : super.success();

  const TokenValidationResult.failure(super.failureReason, super.errorMessage) : super.failure();
}

/// Outcome of `SupplierRedeemCardController.confirmRedemption()`.
class RedemptionConfirmResult extends SupplierResult {
  final RedemptionToken? redemptionToken;
  final int? stampsRedeemed;

  RedemptionConfirmResult.success(this.redemptionToken, this.stampsRedeemed) : super.success();

  RedemptionConfirmResult.failure(super.failureReason, super.errorMessage)
      : redemptionToken = null,
        stampsRedeemed = null,
        super.failure();
}

/// Outcome of `SupplierRedeemCardController.recordManualRedemption()`
/// (Express/Simple Mode's honor-based redemption path).
class ManualRedemptionResult extends SupplierResult {
  final DateTime? redeemedAt;
  final int? stampsRedeemed;

  ManualRedemptionResult.success(this.redeemedAt, this.stampsRedeemed) : super.success();

  ManualRedemptionResult.failure(super.failureReason, super.errorMessage)
      : redeemedAt = null,
        stampsRedeemed = null,
        super.failure();
}
