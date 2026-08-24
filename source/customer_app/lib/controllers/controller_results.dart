/// Result objects returned by the screen controllers in this directory.
///
/// CONVENTION (see the header of `customer_card_detail_controller.dart` for
/// the full template): controller methods that can fail in an *expected* way
/// return one of these instead of throwing. The shape is copied deliberately
/// from `supplier_app/lib/models/backup_result.dart` (`BackupResult`, itself
/// modelled on `VerificationResult`, which a prior code review singled out as
/// exemplary): a bool `isSuccess`, a nullable failure reason enum, a message,
/// and any success payload as further fields.
///
/// `throw` remains reserved for genuine programmer error / unreachable states.
library;

/// Why a `CustomerCardDetailController` operation failed.
enum CardDetailFailureReason {
  /// The card or its stamps could not be read from the database.
  loadFailed,

  /// A write in the redemption sequence failed.
  redeemFailed,
}

/// Outcome of `CustomerCardDetailController.load()`.
///
/// On success the loaded card, stamps and derived QR artefacts are readable
/// from the controller's own getters - there is no payload here, because the
/// screen renders from the controller rather than from a snapshot.
class CardDetailLoadResult {
  final bool isSuccess;
  final CardDetailFailureReason? failureReason;
  final String? errorMessage;

  CardDetailLoadResult.success()
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  CardDetailLoadResult.failure(this.failureReason, this.errorMessage) : isSuccess = false;
}

/// Outcome of `CustomerCardDetailController.processRedemption()`.
class RedemptionResult {
  final bool isSuccess;
  final CardDetailFailureReason? failureReason;
  final String? errorMessage;

  /// Q-004: whether a genuinely new card was inserted, as opposed to an
  /// existing under-filled card being reused. The success dialog must render
  /// this rather than assume it - claiming "a new card has been added"
  /// unconditionally was the original defect.
  final bool newCardCreated;

  /// The timestamp the redemption was recorded at, so the success dialog
  /// shows the same instant that was written to the database.
  final DateTime? redeemedAt;

  RedemptionResult.success({required this.newCardCreated, required this.redeemedAt})
      : isSuccess = true,
        failureReason = null,
        errorMessage = null;

  RedemptionResult.failure(this.failureReason, this.errorMessage)
      : isSuccess = false,
        newCardCreated = false,
        redeemedAt = null;
}

/// Why a `QrScannerController` scan did not end in a credited stamp / added
/// card. Each value maps to a distinct piece of screen behaviour, so the
/// State class can branch on the reason instead of on message text.
enum ScanFailureReason {
  /// The scanned data was not a token this mode understands at all.
  invalidQr,

  /// A readable token, but the wrong type for the current scan mode.
  wrongTokenType,

  /// `TokenValidator` (or an inline structural check) rejected the token.
  validationFailed,

  /// No local card the token could apply to.
  cardNotFound,

  /// The card belongs to a different business than the token.
  businessMismatch,

  /// A signature check failed - initial, additional, or redemption.
  signatureInvalid,

  /// Scanned again inside the cooldown window. Handled distinctly by the
  /// screen: a snackbar plus an immediate pop, never the inline error panel.
  rateLimited,

  /// This exact card is already in the wallet and still active. Not an error
  /// condition - the screen pops with the message rather than showing it as
  /// a scan failure.
  alreadyScanned,

  /// The card has already been redeemed.
  alreadyRedeemed,

  /// A redemption was attempted on a card that is not full yet.
  cardNotComplete,

  /// The atomic stamp-crediting transaction was rolled back (Q-003).
  creditingAborted,

  /// Anything that escaped as an exception - the catch-all the screen used to
  /// render as "Error processing QR: ...".
  unexpectedError,
}

/// Outcome of a `QrScannerController` scan handler.
///
/// [message] carries the user-facing text either way: on success it is what
/// the screen pops with, on failure it is what the screen displays (or pops
/// with, for [ScanFailureReason.alreadyScanned]).
class ScanResult {
  final bool isSuccess;
  final ScanFailureReason? failureReason;
  final String? message;

  ScanResult.success(this.message)
      : isSuccess = true,
        failureReason = null;

  ScanResult.failure(this.failureReason, this.message) : isSuccess = false;
}
