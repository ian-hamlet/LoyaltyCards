import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared/models/supplier_config_backup.dart';
import 'package:shared/shared.dart';

/// Service for managing supplier configuration backup storage
/// Supports four methods: Print, Photos, Email, and Files
/// Cross-platform compatible (iOS & Android)
class BackupStorageService {
  /// 1. Save backup QR code to device photo gallery
  /// Works on both iOS (Photos app) and Android (Gallery)
  static Future<bool> saveToPhotos(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes,
  ) async {
    try {
      final fileName = _generateFileName(backup, 'png');

      final result = await ImageGallerySaver.saveImage(
        qrImageBytes,
        quality: 100,
        name: fileName,
        isReturnImagePathOfIOS: true,
      );

      return result['isSuccess'] == true;
    } catch (e) {
      AppLogger.error('Error saving backup to photos: $e');
      return false;
    }
  }

  /// 2. Generate and print PDF with backup QR code
  /// Opens system print dialog on both iOS and Android
  static Future<bool> printBackup(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes,
  ) async {
    try {
      final pdf = await _generateBackupPDF(backup, qrImageBytes);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: _generateFileName(backup, 'pdf'),
      );

      return true;
    } catch (e) {
      AppLogger.error('Error printing backup: $e');
      return false;
    }
  }

  /// 3. Share backup via email (or other apps)
  /// Opens system share sheet with pre-filled email option
  static Future<bool> shareViaEmail(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      // Save QR image to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName = _generateFileName(backup, 'png');
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(qrImageBytes);

      // Create email content
      final subject = 'LoyaltyCards Backup - ${backup.businessName}';
      final body = '''
This is your LoyaltyCards business recovery backup.

WARNING: KEEP THIS EMAIL SECURE - Do not forward to anyone.

Business: ${backup.businessName}
Created: ${DateFormat('MMMM d, yyyy').format(backup.timestamp)}
Type: ${backup.type == 'recovery' ? 'Recovery Backup (No Expiry)' : 'Clone QR (Expires ${DateFormat('MMM d, h:mm a').format(backup.expiresAt!)})'}

To recover your business:
1. Open LoyaltyCards supplier app on your new device
2. Tap "Recover Existing Business"
3. Scan the QR code attached to this email

The QR code image is attached to this email.
''';

      // Share with email as preferred method
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
        text: body,
        sharePositionOrigin: sharePositionOrigin,
      );

      return true;
    } catch (e) {
      AppLogger.error('Error sharing via email: $e');
      return false;
    }
  }

  /// 4. Save backup to Files app / file system
  /// iOS: Saves to Files app, Android: Saves to Downloads
  static Future<bool> saveToFiles(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      final fileName = _generateFileName(backup, 'png');
      
      // Get appropriate directory based on platform
      Directory directory;
      if (Platform.isIOS) {
        // iOS: Application Documents Directory (accessible via Files app)
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        // Android: Downloads directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage
          directory = (await getExternalStorageDirectory())!;
        }
      } else {
        throw UnsupportedError('Platform not supported');
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(qrImageBytes);

      // On iOS, also offer to share so user can move to iCloud Drive
      if (Platform.isIOS) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'LoyaltyCards Backup - ${backup.businessName}',
          text: 'Save this backup to a secure location',
          sharePositionOrigin: sharePositionOrigin,
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('Error saving backup to files: $e');
      return false;
    }
  }

  /// Generate QR code image as bytes
  static Future<Uint8List> generateQRImageBytes(
    SupplierConfigBackup backup, {
    double size = 800.0,
  }) async {
    final qrValidationResult = QrValidator.validate(
      data: backup.toQRString(),
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    if (qrValidationResult.status == QrValidationStatus.valid) {
      final qrCode = qrValidationResult.qrCode!;
      final painter = QrPainter.withQr(
        qr: qrCode,
        color: const Color(0xFF000000),
        gapless: true,
        embeddedImageStyle: null,
        embeddedImage: null,
      );

      final picturRecorder = ui.PictureRecorder();
      final canvas = Canvas(picturRecorder);
      painter.paint(canvas, Size(size, size));
      final picture = picturRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } else {
      throw Exception('Failed to generate QR code: ${qrValidationResult.error}');
    }
  }

  /// Generate PDF document with backup QR code
  static Future<pw.Document> _generateBackupPDF(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes,
  ) async {
    final pdf = pw.Document();
    final qrImage = pw.MemoryImage(qrImageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Title
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 2),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'LOYALTYCARDS RECOVERY BACKUP',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        backup.businessName,
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Created: ${DateFormat('MMMM d, yyyy').format(backup.timestamp)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        backup.type == 'recovery'
                            ? 'Type: Recovery Backup (No Expiry)'
                            : 'Type: Clone QR (Expires ${DateFormat('MMM d, h:mm a').format(backup.expiresAt!)})',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // QR Code
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                  ),
                  child: pw.Image(qrImage, width: 300, height: 300),
                ),

                pw.SizedBox(height: 30),

                // Warning
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red, width: 2),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'WARNING: KEEP THIS SECURE',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'This QR code restores your business.',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        'Anyone with it can impersonate your business.',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Storage instructions
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Storage Recommendations:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('- Store in a locked safe or drawer',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('- Keep in a safety deposit box',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('- Do not leave in plain sight',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Recovery Instructions:',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('1. Install LoyaltyCards supplier app on new device',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('2. Tap "Recover Existing Business"',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('3. Scan this QR code',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('4. Your business will be fully restored',
                          style: const pw.TextStyle(fontSize: 11)),
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

  /// Generate consistent file names for backups
  static String _generateFileName(SupplierConfigBackup backup, String extension) {
    final timestamp = DateFormat('yyyy-MM-dd').format(backup.timestamp);
    final businessName = backup.businessName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '-');
    final type = backup.type == 'recovery' ? 'Recovery' : 'Clone';
    
    return 'LoyaltyCards-$type-$businessName-$timestamp.$extension';
  }
}
