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
import 'backup_error_classification.dart';
import 'backup_filename.dart';
import 'pdf_fonts.dart';
import 'pdf_validation.dart';

/// Express Mode stamp-token QR distribution (Print, Share via Email, Save
/// to Files) and the annotated-QR/PDF generation behind them. One of four
/// focused services split out of the original monolithic
/// `BackupStorageService` - see that file's now-thin facade for the full
/// split.
class SimpleTokenBackupService {
  /// Generate file name for Simple Mode stamp token QR codes
  /// Format: LoyaltyCards-SimpleToken-{stamps}Stamp-{BusinessName}-{Date}.{ext}
  /// Example: LoyaltyCards-SimpleToken-2Stamps-CoffeeShop-2026-04-20.png
  static String _generateSimpleTokenFileName({
    required String businessName,
    required int stampCount,
    required DateTime date,
    required String extension,
  }) {
    final timestamp = BackupFilename.dateStamp(date);
    final sanitizedBusinessName = BackupFilename.sanitizeBusinessName(businessName);
    final stampLabel = stampCount == 1 ? '1Stamp' : '${stampCount}Stamps';

    return 'LoyaltyCards-SimpleToken-$stampLabel-$sanitizedBusinessName-$timestamp.$extension';
  }

  /// Generate QR code image WITH visual annotations for Simple Mode stamp tokens
  /// Includes business name, stamp count, and optional expiry date on the image
  static Future<Uint8List> generateSimpleTokenQRImageBytes({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
    double size = 800.0,
  }) async {
    // Generate QR code
    final qrValidationResult = QrValidator.validate(
      data: qrData,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (qrValidationResult.status != QrValidationStatus.valid) {
      throw Exception('Failed to generate QR code: ${qrValidationResult.error}');
    }

    final qrCode = qrValidationResult.qrCode!;

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
      eyeStyle: const QrEyeStyle(color: Color(0xFF000000)),
      dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF000000)),
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

    // Stamp count (bottom - large and prominent)
    final stampText = stampCount == 1 ? '1 STAMP' : '$stampCount STAMPS';
    textPainter.text = TextSpan(
      text: stampText,
      style: const TextStyle(
        color: Color(0xFF000000),
        fontSize: 52,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((totalWidth - textPainter.width) / 2, size + 20),
    );

    // Expiry date (bottom - below stamp count)
    if (expiryDate != null) {
      final expiryText = 'Expires: ${DateFormat('MMM d, yyyy').format(expiryDate)}';
      textPainter.text = TextSpan(
        text: expiryText,
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

  /// Print Simple Mode stamp token QR via the OS share sheet.
  ///
  /// Uses `Printing.sharePdf` rather than `Printing.layoutPdf` - see the
  /// doc comment on `ConfigBackupService.printBackup` for why (CRASH-001's
  /// native print-preview subsystem, which this deliberately avoids).
  static Future<BackupResult> printSimpleToken({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
  }) async {
    try {
      AppLogger.debug('=== printSimpleToken START ===', 'BackupService');

      final qrImageBytes = await generateSimpleTokenQRImageBytes(
        qrData: qrData,
        businessName: businessName,
        stampCount: stampCount,
        expiryDate: expiryDate,
      );

      final pdf = await _generateSimpleTokenPDF(
        qrImageBytes: qrImageBytes,
        businessName: businessName,
        stampCount: stampCount,
        expiryDate: expiryDate,
      );

      final fileName = _generateSimpleTokenFileName(
        businessName: businessName,
        stampCount: stampCount,
        date: DateTime.now(),
        extension: 'pdf',
      );

      final bytes = await PdfValidation.generateValidatedPdfBytes(pdf);
      await Printing.sharePdf(bytes: bytes, filename: fileName);

      AppLogger.debug('=== printSimpleToken END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Error printing simple token: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');

      final errorString = e.toString().toLowerCase();
      if (BackupErrorClassification.isDiskFullError(errorString)) {
        return BackupResult.failure(
          BackupFailureReason.diskFull,
          'Not enough storage space. Free up space and try again.',
        );
      }
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

  /// Share Simple Mode stamp token via email
  static Future<BackupResult> shareSimpleTokenViaEmail({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
    Rect? sharePositionOrigin,
  }) async {
    try {
      AppLogger.debug('=== shareSimpleTokenViaEmail START ===', 'BackupService');

      final qrImageBytes = await generateSimpleTokenQRImageBytes(
        qrData: qrData,
        businessName: businessName,
        stampCount: stampCount,
        expiryDate: expiryDate,
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = _generateSimpleTokenFileName(
        businessName: businessName,
        stampCount: stampCount,
        date: DateTime.now(),
        extension: 'png',
      );
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(qrImageBytes);

      final stampText = stampCount == 1 ? '1 Stamp' : '$stampCount Stamps';
      final subject = 'LoyaltyCards Stamp Token - $stampText - $businessName';
      final expiryInfo = expiryDate != null
          ? 'Expires: ${DateFormat('MMMM d, yyyy').format(expiryDate)}'
          : 'No Expiry';

      final body = '''
Stamp Token for $businessName

Stamp Value: $stampText
$expiryInfo

Print this QR code and place it in your till for customer scanning.

For best results:
1. Print the attached image
2. Laminate for durability
3. Keep in cash drawer
4. Show to customers after purchase
''';

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: subject,
          text: body,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      AppLogger.debug('=== shareSimpleTokenViaEmail END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Error sharing simple token via email: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to share: ${e.toString()}',
      );
    }
  }

  /// Save Simple Mode stamp token to Files
  static Future<BackupResult> saveSimpleTokenToFiles({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
    Rect? sharePositionOrigin,
  }) async {
    try {
      AppLogger.debug('=== saveSimpleTokenToFiles START ===', 'BackupService');

      final qrImageBytes = await generateSimpleTokenQRImageBytes(
        qrData: qrData,
        businessName: businessName,
        stampCount: stampCount,
        expiryDate: expiryDate,
      );

      final fileName = _generateSimpleTokenFileName(
        businessName: businessName,
        stampCount: stampCount,
        date: DateTime.now(),
        extension: 'png',
      );

      final directory = Platform.isIOS
          ? await getApplicationDocumentsDirectory()
          : await getExternalStorageDirectory();

      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(qrImageBytes);

      if (Platform.isIOS) {
        final stampText = stampCount == 1 ? '1 Stamp' : '$stampCount Stamps';
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            subject: 'LoyaltyCards Stamp Token - $stampText',
            text: 'Save this stamp token to a secure location',
            sharePositionOrigin: sharePositionOrigin,
          ),
        );
        AppLogger.debug('Share result: ${result.status}', 'BackupService');
      }

      AppLogger.debug('=== saveSimpleTokenToFiles END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Error saving simple token to files: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');

      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission')) {
        return BackupResult.failure(
          BackupFailureReason.permissionDenied,
          'Storage permission denied.',
        );
      }
      if (BackupErrorClassification.isDiskFullError(errorString)) {
        return BackupResult.failure(
          BackupFailureReason.diskFull,
          'Not enough storage space. Free up space and try again.',
        );
      }
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to save: ${e.toString()}',
      );
    }
  }

  /// Generate PDF for Simple Mode stamp token
  static Future<pw.Document> _generateSimpleTokenPDF({
    required Uint8List qrImageBytes,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
  }) async {
    final pdf = pw.Document();
    final qrImage = pw.MemoryImage(qrImageBytes);
    final theme = await PdfFonts.theme();

    final stampText = stampCount == 1 ? '1 Stamp' : '$stampCount Stamps';
    final expiryText = expiryDate != null
        ? 'Expires: ${DateFormat('MMMM d, yyyy').format(expiryDate)}'
        : 'No Expiry Date';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Title
                pw.Text(
                  businessName,
                  style: const pw.TextStyle(
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
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200, width: 2),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Stamp Token: $stampText',
                        style: const pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        expiryText,
                        style: const pw.TextStyle(fontSize: 14),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Instructions:',
                        style: const pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '1. Print and laminate this page\n2. Keep in till/cash drawer\n3. Show to customers after purchase\n4. Customer scans to receive stamps',
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
}
