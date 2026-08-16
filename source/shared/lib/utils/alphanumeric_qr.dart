import 'package:qr_flutter/qr_flutter.dart';

/// TEST-020: builds a [QrCode] using QR's "alphanumeric" encoding mode
/// (~5.5 bits/character) instead of the default byte mode (8 bits/char)
/// that `QrImageView(data: ...)` always uses via `QrCode.fromData()`. Pair
/// with [Base45]-encoded data, whose alphabet is exactly QR's alphanumeric
/// character set.
///
/// The `qr` package has no equivalent of `QrVersions.auto` for
/// alphanumeric mode - `QrCode.addAlphaNumeric()` requires a fixed version
/// chosen up front, and there's no dynamic-sizing helper for it the way
/// there is for byte mode. This tries successively larger versions itself
/// (the same approach the byte-mode path uses internally), so a small
/// payload still gets a small, easy-to-scan QR code instead of always
/// forcing the largest, densest version regardless of how little data
/// there is to encode.
class AlphanumericQr {
  AlphanumericQr._();

  /// Returns the smallest [QrCode] (by version, 1-40) that can hold
  /// [alphanumericData] at [errorCorrectLevel], or `null` if even version
  /// 40 can't fit it - the caller's cue to fall back to something else
  /// (see CustomerCardDetail's _qrTooLargeToRender fallback panel).
  static QrCode? build(
    String alphanumericData, {
    int errorCorrectLevel = QrErrorCorrectLevel.L,
  }) {
    for (var version = 1; version <= 40; version++) {
      try {
        final qrCode = QrCode(version, errorCorrectLevel)
          ..addAlphaNumeric(alphanumericData);
        // ignore: invalid_use_of_internal_member
        qrCode.dataCache; // forces the real capacity check (lazy in the qr package)
        return qrCode;
      } catch (e) {
        continue;
      }
    }
    return null;
  }
}
