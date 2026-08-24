import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart';
import '../../models/backup_result.dart';
import 'pdf_validation.dart';

/// Simple Mode issue-card QR distribution (Print, Share) and the
/// annotated-QR/PDF generation behind it. One of four focused services
/// split out of the original monolithic `BackupStorageService` - see that
/// file's now-thin facade for the full split.
class IssueCardBackupService {
  /// Generate file name for Simple Mode issue card QR codes
  /// Format: LoyaltyCards-IssueCard-{InitialStamps}-{BusinessName}-{Date}.{ext}
  /// Example: LoyaltyCards-IssueCard-2Stamps-CoffeeShop-2026-04-21.png
  static String _generateIssueCardFileName({
    required String businessName,
    required int initialStamps,
    required DateTime date,
    required String extension,
  }) {
    final timestamp = DateFormat('yyyy-MM-dd').format(date);
    final sanitizedBusinessName = businessName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '-');
    final stampLabel = initialStamps == 0 ? 'NoStamps' : (initialStamps == 1 ? '1Stamp' : '${initialStamps}Stamps');

    return 'LoyaltyCards-IssueCard-$stampLabel-$sanitizedBusinessName-$timestamp.$extension';
  }

  /// Generate QR code image WITH visual annotations for Simple Mode issue cards
  /// Includes business name and initial stamp count on the image
  static Future<Uint8List> generateIssueCardQRImageBytes({
    required QrCode qrCode,
    required String businessName,
    required int initialStamps,
    double size = 800.0,
  }) async {
    // TEST-021: qrCode is now built ahead of time by the caller (compact
    // gzip+Base45+alphanumeric encoding via CardIssueQrCodec/AlphanumericQr
    // - see DEFECT_TRACKER.md TEST-021) instead of being derived here from
    // a raw data string via QrValidator.validate(). That path used
    // errorCorrectionLevel M, which has *less* capacity than the L level
    // QrImageView defaults to on-screen - the print/share QR was actually
    // hitting this bug's capacity ceiling before the on-screen one did.

    // Create canvas with extra space for annotations
    final totalWidth = size;
    final totalHeight = size + 200; // Extra space for text

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Fill white background
    final paint = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, totalWidth, totalHeight), paint);

    // Draw QR code in center (with margin)
    const margin = 60.0;
    final qrSize = size - (margin * 2);
    final qrPainter = QrPainter.withQr(
      qr: qrCode,
      color: const Color(0xFF000000),
      gapless: true,
      embeddedImageStyle: null,
      embeddedImage: null,
    );

    canvas.save();
    canvas.translate(margin, margin + 80); // Offset for top text
    qrPainter.paint(canvas, Size(qrSize, qrSize));
    canvas.restore();

    // Draw text annotations
    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Business name (top)
    textPainter.text = TextSpan(
      text: businessName,
      style: const TextStyle(
        color: Color(0xFF000000),
        fontSize: 36,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((totalWidth - textPainter.width) / 2, 20),
    );

    // "SCAN TO ADD CARD" (bottom - large and prominent)
    textPainter.text = const TextSpan(
      text: 'SCAN TO ADD CARD',
      style: TextStyle(
        color: Color(0xFF000000),
        fontSize: 42,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((totalWidth - textPainter.width) / 2, size + 20),
    );

    // Initial stamps info (bottom - below main text)
    if (initialStamps > 0) {
      final stampText = initialStamps == 1 ? 'Starts with 1 stamp' : 'Starts with $initialStamps stamps';
      textPainter.text = TextSpan(
        text: stampText,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 24,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((totalWidth - textPainter.width) / 2, size + 90),
      );
    }

    // Convert to image
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Print Simple Mode issue card QR
  static Future<BackupResult> printIssueCard({
    required QrCode qrCode,
    required String businessName,
    required int initialStamps,
  }) async {
    try {
      AppLogger.debug('=== printIssueCard START ===', 'BackupService');

      final qrImageBytes = await generateIssueCardQRImageBytes(
        qrCode: qrCode,
        businessName: businessName,
        initialStamps: initialStamps,
      );

      final pdf = await _generateIssueCardPDF(
        qrImageBytes: qrImageBytes,
        businessName: businessName,
        initialStamps: initialStamps,
      );

      final fileName = _generateIssueCardFileName(
        businessName: businessName,
        initialStamps: initialStamps,
        date: DateTime.now(),
        extension: 'pdf',
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => PdfValidation.generateValidatedPdfBytes(pdf),
        name: fileName,
      );

      AppLogger.debug('=== printIssueCard END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Error printing issue card: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');

      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cancel')) {
        return BackupResult.failure(
          BackupFailureReason.userCancelled,
          'Print cancelled.',
        );
      }
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to print: ${e.toString()}',
      );
    }
  }

  /// Generate PDF for Simple Mode issue card
  static Future<pw.Document> _generateIssueCardPDF({
    required Uint8List qrImageBytes,
    required String businessName,
    required int initialStamps,
  }) async {
    final pdf = pw.Document();
    final qrImage = pw.MemoryImage(qrImageBytes);

    final stampInfo = initialStamps == 0
        ? 'New card with no initial stamps'
        : (initialStamps == 1 ? 'Card starts with 1 stamp' : 'Card starts with $initialStamps stamps');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Title
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

                pw.SizedBox(height: 20),

                // QR Code with annotations (already includes text)
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    color: PdfColors.white,
                  ),
                  child: pw.Image(qrImage, width: 400, height: 480),
                ),

                pw.SizedBox(height: 30),

                // Instructions
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    color: PdfColors.blue50,
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Loyalty Card Issue QR',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        stampInfo,
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Instructions:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '1. Display this QR code to customers\n2. Customer scans to add loyalty card to their device\n3. Card can be scanned multiple times (reusable)\n4. Keep this QR code accessible for new customers',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf;
  }

  /// Share Simple Mode issue card via native share sheet
  static Future<BackupResult> shareIssueCard({
    required QrCode qrCode,
    required String businessName,
    required int initialStamps,
    Rect? sharePositionOrigin,
  }) async {
    try {
      AppLogger.debug('=== shareIssueCard START ===', 'BackupService');

      final qrImageBytes = await generateIssueCardQRImageBytes(
        qrCode: qrCode,
        businessName: businessName,
        initialStamps: initialStamps,
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = _generateIssueCardFileName(
        businessName: businessName,
        initialStamps: initialStamps,
        date: DateTime.now(),
        extension: 'png',
      );
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(qrImageBytes);

      final stampInfo = initialStamps == 0
          ? 'New card with no initial stamps'
          : (initialStamps == 1 ? 'Card starts with 1 stamp' : 'Card starts with $initialStamps stamps');

      final subject = 'LoyaltyCards Issue Card - $businessName';

      final body = '''
Loyalty Card Issue QR for $businessName

$stampInfo

Display this QR code to customers so they can add your loyalty card to their device.

This QR code is reusable and can be scanned by multiple customers.

For best results:
1. Display on a screen or print and laminate
2. Place where customers can easily scan
3. Keep accessible for new customers
''';

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
        text: body,
        sharePositionOrigin: sharePositionOrigin,
      );

      AppLogger.debug('=== shareIssueCard END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Error sharing issue card: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to share: ${e.toString()}',
      );
    }
  }
}
