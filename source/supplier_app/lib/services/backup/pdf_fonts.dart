import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;

/// Shared PDF font loading for every backup-generation service in
/// `services/backup/` (and `AuditTrailPdfService`). The `pdf` package's
/// default base-14 fonts (Helvetica/Helvetica-Bold) only support WinAnsi
/// encoding - business names are free-text user input and can contain
/// characters those fonts can't render (accents beyond Latin-1, non-Latin
/// scripts, emoji). NotoSans is bundled as an asset so this works fully
/// offline, matching the app's offline-first design - notably, backup
/// printing is itself an offline-security workflow.
class PdfFonts {
  static pw.Font? _regular;
  static pw.Font? _bold;

  static Future<pw.Font> regular() async =>
      _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));

  static Future<pw.Font> bold() async =>
      _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));

  /// Convenience for `pw.Page(theme: ..., build: ...)`.
  static Future<pw.ThemeData> theme() async => pw.ThemeData.withFont(
        base: await regular(),
        bold: await bold(),
      );
}
