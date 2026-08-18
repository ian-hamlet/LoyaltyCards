import 'dart:convert';
import 'dart:io';

import 'base45.dart';
import '../models/qr_tokens.dart';

/// TEST-021: compact QR encoding for [CardIssueToken].
///
/// A card issued with pre-applied initial stamps embeds one signature per
/// stamp (`initialStamps`), the same shape as [RedemptionRequestToken]'s
/// per-stamp proofs - and the plain-JSON/byte-mode QR this was previously
/// rendered with (`supplier_issue_card.dart`) has the exact same capacity
/// ceiling that caused TEST-017, just never fixed on the issuance side
/// when TEST-020 fixed it for redemption. See DEFECT_TRACKER.md TEST-021
/// for the measured sizes that motivated this.
///
/// Same approach as [RedemptionQrCodec]: gzip-compress the JSON, then
/// Base45-encode the result so the QR can use alphanumeric mode via
/// [AlphanumericQr] instead of the default byte mode.
class CardIssueQrCodec {
  CardIssueQrCodec._();

  /// Bumped whenever the compact payload's own JSON shape changes in a
  /// way a decoder needs to know about.
  static const int currentVersion = 1;

  /// Compresses and Base45-encodes [token] for QR display.
  static String encode(CardIssueToken token) {
    final json = jsonEncode({...token.toJson(), 'v': currentVersion});
    final compressed = gzip.encode(utf8.encode(json));
    return Base45.encode(compressed);
  }

  /// Reverses [encode]. Throws if [data] isn't valid Base45, doesn't
  /// gunzip, or doesn't decode to a valid [CardIssueToken].
  ///
  /// As with [RedemptionQrCodec], there's no separate wire-level marker -
  /// Base45's alphabet can never be valid JSON text, so a caller can try
  /// `jsonDecode`/`QRToken.fromQRString` first and fall back to this on
  /// failure.
  static CardIssueToken decode(String data) {
    final compressed = Base45.decode(data);
    final json = utf8.decode(gzip.decode(compressed));
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return CardIssueToken.fromJson(decoded);
  }
}
