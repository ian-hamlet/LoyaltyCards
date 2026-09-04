import 'dart:io';
import 'package:flutter/material.dart' show Rect;
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart';
import '../models/audit_entry.dart';
import '../models/backup_result.dart';
import 'backup/backup_filename.dart';
import 'backup/pdf_fonts.dart';
import 'backup/pdf_validation.dart';

/// Generates, prints, and shares the local audit trail as a simple PDF
/// table (Requirements/DISCUSSION_Business_Field_Editing.md §7.4). A
/// small, focused sibling to BackupStorageService rather than another
/// addition to that already-large file - reuses the same PDF-validation
/// and file-naming conventions (via `PdfValidation`/`BackupFilename`,
/// factored out of the backup services during a follow-up code-quality
/// pass), not the same class.
class AuditTrailPdfService {
  static String _fileName(Business business) {
    final timestamp = BackupFilename.dateStamp(DateTime.now());
    final businessName = BackupFilename.sanitizeBusinessName(business.name);
    return 'LoyaltyCards-AuditTrail-$businessName-$timestamp.pdf';
  }

  static Future<pw.Document> _generatePdf(Business business, List<AuditEntry> entries) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final theme = await PdfFonts.theme();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        theme: theme,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('LoyaltyCards Audit Trail', style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Business: ${business.name}'),
          pw.Text('Business ID: ${business.id}'),
          pw.Text('Generated: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 16),
          if (entries.isEmpty)
            pw.Text('No audit trail entries yet.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Date/Time', 'Property', 'New Value', 'App Version'],
              data: entries
                  .map((e) => [
                        dateFormat.format(e.timestamp),
                        e.propertyName,
                        e.newValue ?? '',
                        e.appVersion,
                      ])
                  .toList(),
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(1.2),
              },
            ),
        ],
      ),
    );

    return pdf;
  }

  /// Opens the OS share sheet with the audit trail table PDF.
  ///
  /// Uses `Printing.sharePdf` rather than `Printing.layoutPdf` - see the
  /// doc comment on `ConfigBackupService.printBackup` for why (CRASH-001's
  /// native print-preview subsystem, which this deliberately avoids).
  static Future<BackupResult> printAuditTrail(Business business, List<AuditEntry> entries) async {
    try {
      final pdf = await _generatePdf(business, entries);
      final bytes = await PdfValidation.generateValidatedPdfBytes(pdf);
      await Printing.sharePdf(bytes: bytes, filename: _fileName(business));
      return BackupResult.success();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cancel')) {
        return BackupResult.failure(BackupFailureReason.userCancelled, 'Print cancelled.');
      }
      return BackupResult.failure(BackupFailureReason.unknown, 'Failed to print: $e');
    }
  }

  /// Opens the system share sheet with the audit trail table as a PDF.
  static Future<BackupResult> shareAuditTrail(Business business, List<AuditEntry> entries, {Rect? sharePositionOrigin}) async {
    try {
      final pdf = await _generatePdf(business, entries);
      final bytes = await PdfValidation.generateValidatedPdfBytes(pdf);

      final tempDir = await getTemporaryDirectory();
      final fileName = _fileName(business);
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'LoyaltyCards Audit Trail - ${business.name}',
          text: 'Audit trail for ${business.name}, generated ${DateFormat('MMMM d, yyyy').format(DateTime.now())}.',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      AppLogger.debug('Audit trail share result: ${result.status}', 'AuditTrail');
      return BackupResult.success();
    } catch (e) {
      return BackupResult.failure(BackupFailureReason.unknown, 'Failed to share: $e');
    }
  }
}
