import 'dart:convert';
import 'dart:io';

import 'base45.dart';
import '../models/qr_tokens.dart';

/// TEST-020: compact QR encoding for [RedemptionRequestToken].
///
/// The plain JSON produced by RedemptionRequestToken.toJson() bundles one
/// signature-bearing proof per stamp - for a high-stamp-count or heavily
/// overflow-relocated card, that payload can exceed a QR code's maximum
/// encodable capacity, causing QrImageView to fail silently (see TEST-017
/// in DEFECT_TRACKER.md for the full history). This codec compresses that
/// JSON (gzip) and encodes the result as Base45 text, which lets the QR
/// code use its more space-efficient "alphanumeric" mode via
/// [AlphanumericQr] instead of the default byte mode a plain string would
/// force - see DEFECT_TRACKER.md TEST-020 for the measured size
/// comparisons that motivated this.
///
/// Cryptographic signatures are high-entropy/effectively-random data, so
/// gzip alone only compresses the surrounding JSON structure (repeated
/// key names, punctuation) - not the signature bytes themselves. Combined
/// with Base45/alphanumeric mode's larger effective capacity, this is
/// enough to make a 12-stamp card safe even when every one of its stamps
/// is overflow-relocated (the worst case); it is not unlimited - see
/// AlphanumericQr.build's null case and CustomerCardDetail's fallback UI
/// for what happens if a payload still doesn't fit.
class RedemptionQrCodec {
  RedemptionQrCodec._();

  /// Bumped whenever the compact payload's own JSON shape changes in a
  /// way a decoder needs to know about (not the QR-transport encoding
  /// itself, which is signaled by the data simply not being plain JSON -
  /// see [decode]'s doc comment).
  static const int currentVersion = 2;

  /// Compresses and Base45-encodes [token] for QR display.
  static String encode(RedemptionRequestToken token) {
    final json = jsonEncode({...token.toJson(), 'v': currentVersion});
    final compressed = gzip.encode(utf8.encode(json));
    return Base45.encode(compressed);
  }

  /// Reverses [encode]. Throws if [data] isn't valid Base45, doesn't
  /// gunzip, or doesn't decode to a valid [RedemptionRequestToken] - the
  /// same "let the caller's existing try/catch handle it" contract
  /// `RedemptionRequestToken.fromJson` already has.
  ///
  /// There's no separate wire-level marker distinguishing this format
  /// from plain JSON: Base45's alphabet (digits, uppercase letters, and a
  /// handful of symbols - no `{`, `"`, or lowercase letters) can never be
  /// valid JSON text, so a caller can simply try `jsonDecode` first and
  /// fall back to this on failure, exactly as `supplier_redeem_card.dart`
  /// already does for its pre-existing legacy-format fallback.
  static RedemptionRequestToken decode(String data) {
    final compressed = Base45.decode(data);
    final json = utf8.decode(gzip.decode(compressed));
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return RedemptionRequestToken.fromJson(decoded);
  }
}
