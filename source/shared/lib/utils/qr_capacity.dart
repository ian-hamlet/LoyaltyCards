import 'package:qr_flutter/qr_flutter.dart';

/// TEST-017: checks whether a string can actually be encoded as a QR code
/// before attempting to render it.
///
/// `QrImageView` (from `qr_flutter`) has no reliable way to signal an
/// encode failure ahead of time - the underlying `qr` package's own
/// `QrValidator.validate()` doesn't check the largest QR version's true
/// capacity, so it can report success for data that still doesn't fit. The
/// real capacity check only happens lazily, inside the widget's own
/// `build()`, by which point an uncaught exception there just renders as
/// Flutter's default blank grey error box in release builds - no error
/// text, easy to mistake for a rendering bug rather than an oversized
/// payload.
///
/// This mirrors the exact internal path `QrImageView`'s painter uses, so a
/// caller can check first and show a real fallback instead.
class QrCapacity {
  QrCapacity._();

  static bool fits(String data, {int errorCorrectLevel = QrErrorCorrectLevel.L}) {
    try {
      final qrCode = QrCode.fromData(data: data, errorCorrectLevel: errorCorrectLevel);
      // ignore: invalid_use_of_internal_member
      qrCode.dataCache; // forces the real capacity check (lazy in the qr package)
      return true;
    } catch (e) {
      return false;
    }
  }
}
