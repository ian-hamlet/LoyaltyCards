import 'dart:io';
import 'dart:typed_data';
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

/// Generates, prints, and shares the local audit trail as a simple PDF
/// table (Requirements/DISCUSSION_Business_Field_Editing.md §7.4). A
/// small, focused sibling to BackupStorageService rather than another
/// addition to that already-large file - reuses the same PDF-validation
/// and file-naming conventions, not the same class.
class AuditTrailPdfService {
  static const _pdfMagic = [0x25, 0x50, 0x44, 0x46, 0x2D]; // "%PDF-"

  static bool _isValidPdfBytes(Uint8List bytes) {
    return bytes.length >= _pdfMagic.length &&
        _pdfMagic.indexed.every((entry) => bytes[entry.$1] == entry.$2);
  }

  /// Same safety net as BackupStorageService._generateValidatedPdfBytes -
  /// converts a malformed-PDF edge case into a caught Dart exception
  /// instead of handing bad bytes to the native print/share plugin.
  static Future<Uint8List> _generateValidatedPdfBytes(pw.Document pdf) async {
    final bytes = await pdf.save();
    if (!_isValidPdfBytes(bytes)) {
      throw StateError('Generated PDF is empty or has an invalid header');
    }
    return bytes;
  }

  static String _fileName(Business business) {
    final timestamp = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final businessName = business.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '-');
    return 'LoyaltyCards-AuditTrail-$businessName-$timestamp.pdf';
  }

  static Future<pw.Document> _generatePdf(Business business, List<AuditEntry> entries) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('LoyaltyCards Audit Trail', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text('Business: ${business.name}'),
          pw.Text('Business ID: ${business.id}'),
          pw.Text('Generated: ${dateFormat.format(DateTime.now())}'),
          pw.SizedBox(height: 16),
          if (entries.isEmpty)
            pw.Text('No audit trail entries yet.')
          else
            pw.Table.fromTextArray(
              headers: const ['Date/Time', 'Property', 'New Value', 'App Version'],
              data: entries
                  .map((e) => [
                        dateFormat.format(e.timestamp),
                        e.propertyName,
                        e.newValue ?? '',
                        e.appVersion,
                      ])
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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

  /// Opens the system print dialog with the audit trail table.
  static Future<BackupResult> printAuditTrail(Business business, List<AuditEntry> entries) async {
    try {
      final pdf = await _generatePdf(business, entries);
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => _generateValidatedPdfBytes(pdf),
        name: _fileName(business),
      );
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
      final bytes = await _generateValidatedPdfBytes(pdf);

      final tempDir = await getTemporaryDirectory();
      final fileName = _fileName(business);
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'LoyaltyCards Audit Trail - ${business.name}',
        text: 'Audit trail for ${business.name}, generated ${DateFormat('MMMM d, yyyy').format(DateTime.now())}.',
        sharePositionOrigin: sharePositionOrigin,
      );

      AppLogger.debug('Audit trail share result: ${result.status}', 'AuditTrail');
      return BackupResult.success();
    } catch (e) {
      return BackupResult.failure(BackupFailureReason.unknown, 'Failed to share: $e');
    }
  }
}
