import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;

/// PDF well-formedness checks shared by every backup-generation service in
/// `services/backup/`. Extracted from the original monolithic
/// `BackupStorageService` (see that file's now-thin facade) so all three
/// generators (config backup, Simple Mode stamp token, Simple Mode issue
/// card) share one implementation instead of three copies.
class PdfValidation {
  /// "%PDF-" is the mandatory first 5 bytes of every valid PDF file (PDF
  /// spec section 7.5.2) - a cheap, reliable well-formedness check without
  /// parsing the whole document.
  static const _pdfMagic = [0x25, 0x50, 0x44, 0x46, 0x2D];

  /// CRASH-001 regression test hook - see [generateValidatedPdfBytes] for
  /// why this exists. Pulled out as its own pure function (bytes in, bool
  /// out) specifically so the reject path is independently testable without
  /// needing to coax `pw.Document.save()` itself into producing bad output.
  @visibleForTesting
  static bool isValidPdfBytesForTesting(Uint8List bytes) => isValidPdfBytes(bytes);

  static bool isValidPdfBytes(Uint8List bytes) {
    return bytes.length >= _pdfMagic.length &&
        _pdfMagic.indexed.every((entry) => bytes[entry.$1] == entry.$2);
  }

  /// CRASH-001 follow-up: `Printing.layoutPdf`'s `onLayout` callback used to
  /// hand `pdf.save()`'s result straight to the native printing plugin with
  /// no validation. If pdf.save() ever produced empty or malformed bytes -
  /// a rendering edge case, a truncated write - the plugin would still try
  /// to construct a native CGPDFDocument from it, which is a second,
  /// single-tap-reachable path to the same EXC_BAD_ACCESS crash the
  /// re-entrancy guard doesn't cover (that guard only stops a *second*
  /// concurrent call, not a first call with bad data). Validating here
  /// converts that native crash into a caught Dart exception, surfaced to
  /// the user as an ordinary "Failed to print" error instead.
  static Future<Uint8List> generateValidatedPdfBytes(pw.Document pdf) async {
    final bytes = await pdf.save();
    if (!isValidPdfBytes(bytes)) {
      throw StateError('Generated PDF is empty or has an invalid header');
    }
    return bytes;
  }
}
