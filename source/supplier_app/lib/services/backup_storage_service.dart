import 'dart:async';
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
import '../models/backup_result.dart';

/// Service for managing supplier configuration backup storage
/// 
/// Supports four backup methods:
/// 1. Save to Photos - Saves QR code image to device photo library
/// 2. Print Backup - Generates PDF and opens system print dialog
/// 3. Share via Email - Creates temp file and opens email share sheet
/// 4. Save to Files - Opens system file picker to save QR image
/// 
/// ERROR HANDLING PATTERN (HP-1 FIX):
/// All methods return Future<BackupResult>:
/// - Returns BackupResult.success() on success
/// - Returns BackupResult.failure(reason, message) on failure
/// - Provides detailed error context via failureReason and message
/// - Allows UI to show specific guidance based on failure type
/// - Common failures: Permission denied, disk full, timeout, user cancelled
/// 
/// Cross-platform compatible (iOS & Android)
class BackupStorageService {
  /// 1. Save backup QR code to device photo gallery
  /// Works on both iOS (Photos app) and Android (Gallery)
  static Future<BackupResult> saveToPhotos(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes,
  ) async {
    try {
      AppLogger.debug('=== saveToPhotos START ===', 'BackupService');
      final fileName = _generateFileName(backup, 'png');
      AppLogger.debug('Generated filename: $fileName', 'BackupService');
      AppLogger.debug('Image bytes size: ${qrImageBytes.length}', 'BackupService');

      AppLogger.debug('Calling ImageGallerySaver.saveImage...', 'BackupService');
      
      // CR-1.2: Use timeout with explicit error handling
      // Previously: timeout returned success (false positive risk)
      // Now: timeout throws exception (fails gracefully)
      final result = await Future.value(ImageGallerySaver.saveImage(
        qrImageBytes,
        quality: 100,
        name: fileName,
        isReturnImagePathOfIOS: true,
      )).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.error(
            'Photo save timeout - operation uncertain. User should try alternative backup method.',
            tag: 'BackupService',
          );
          throw TimeoutException('Photo save timeout after 10 seconds');
        },
      );

      AppLogger.debug('ImageGallerySaver result: $result', 'BackupService');
      
      // CR-1.2: Verify actual success, not just absence of exception
      final success = result is Map && result['isSuccess'] == true;
      
      if (success) {
        AppLogger.debug('Photo saved successfully to gallery', 'BackupService');
        if (result['filePath'] != null) {
          AppLogger.debug('File path: ${result['filePath']}', 'BackupService');
        }
      } else {
        AppLogger.error(
          'ImageGallerySaver returned isSuccess=false or unexpected format',
          tag: 'BackupService',
        );
        AppLogger.debug('Full result object: $result', 'BackupService');
      }
      
      AppLogger.debug('=== saveToPhotos END (success: $success) ===', 'BackupService');
      return success 
        ? BackupResult.success() 
        : BackupResult.failure(BackupFailureReason.unknown, 'Failed to save to photos. Check storage permissions.');
    } on TimeoutException catch (e) {
      AppLogger.error(
        'Photo save timeout: $e. User should try Email or PDF backup.',
        tag: 'BackupService',
      );
      return BackupResult.failure(
        BackupFailureReason.timeout,
        'Operation timed out. Try an alternative backup method.',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error saving backup to photos: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');
      
      // Check for specific error types
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission')) {
        return BackupResult.failure(
          BackupFailureReason.permissionDenied,
          'Storage permission denied. Enable in Settings.',
        );
      } else if (errorString.contains('space') || errorString.contains('disk full')) {
        return BackupResult.failure(
          BackupFailureReason.diskFull,
          'Not enough storage space. Free up space and try again.',
        );
      }
      
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to save to photos: ${e.toString()}',
      );
    }
  }

  /// 2. Generate and print PDF with backup QR code
  /// Opens system print dialog on both iOS and Android
  static Future<BackupResult> printBackup(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes,
  ) async {
    try {
      AppLogger.debug('=== printBackup START ===', 'BackupService');
      AppLogger.debug('Generating PDF...', 'BackupService');
      final pdf = await _generateBackupPDF(backup, qrImageBytes);
      AppLogger.debug('PDF generated successfully', 'BackupService');

      final fileName = _generateFileName(backup, 'pdf');
      AppLogger.debug('Calling Printing.layoutPdf with name: $fileName', 'BackupService');
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );

      AppLogger.debug('Print dialog opened successfully', 'BackupService');
      AppLogger.debug('=== printBackup END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Error printing backup: $e', tag: 'BackupService');
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

  /// 3. Share backup via email (or other apps)
  /// Opens system share sheet with pre-filled email option
  static Future<BackupResult> shareViaEmail(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      AppLogger.debug('=== shareViaEmail START ===', 'BackupService');
      
      // Save QR image to temporary file
      AppLogger.debug('Getting temporary directory...', 'BackupService');
      final tempDir = await getTemporaryDirectory();
      AppLogger.debug('Temp directory: ${tempDir.path}', 'BackupService');
      
      final fileName = _generateFileName(backup, 'png');
      final filePath = '${tempDir.path}/$fileName';
      AppLogger.debug('Creating temp file at: $filePath', 'BackupService');
      
      final file = File(filePath);
      await file.writeAsBytes(qrImageBytes);
      AppLogger.debug('Temp file created, size: ${await file.length()} bytes', 'BackupService');

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

      AppLogger.debug('Email subject: $subject', 'BackupService');
      AppLogger.debug('Calling Share.shareXFiles...', 'BackupService');
      
      // Share with email as preferred method
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
        text: body,
        sharePositionOrigin: sharePositionOrigin,
      );

      AppLogger.debug('Share result: ${result.status}', 'BackupService');
      AppLogger.debug('=== shareViaEmail END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Error sharing via email: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to share: ${e.toString()}',
      );
    }
  }

  /// 4. Save backup to Files app / file system
  /// iOS: Saves to Files app, Android: Saves to Downloads
  static Future<BackupResult> saveToFiles(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes, {
    Rect? sharePositionOrigin,
  }) async {
    try {
      AppLogger.debug('=== saveToFiles START ===', 'BackupService');
      final fileName = _generateFileName(backup, 'png');
      AppLogger.debug('Generated filename: $fileName', 'BackupService');
      
      // Get appropriate directory based on platform
      AppLogger.debug('Platform: iOS=${Platform.isIOS}, Android=${Platform.isAndroid}', 'BackupService');
      Directory directory;
      if (Platform.isIOS) {
        // iOS: Application Documents Directory (accessible via Files app)
        AppLogger.debug('Getting iOS application documents directory...', 'BackupService');
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        // Android: Downloads directory
        AppLogger.debug('Using Android downloads directory...', 'BackupService');
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage
          AppLogger.debug('Downloads dir not found, falling back to external storage', 'BackupService');
          directory = (await getExternalStorageDirectory())!;
        }
      } else {
        throw UnsupportedError('Platform not supported');
      }

      AppLogger.debug('Target directory: ${directory.path}', 'BackupService');
      final filePath = '${directory.path}/$fileName';
      AppLogger.debug('Writing file to: $filePath', 'BackupService');
      
      final file = File(filePath);
      await file.writeAsBytes(qrImageBytes);
      AppLogger.debug('File written, size: ${await file.length()} bytes', 'BackupService');

      // On iOS, also offer to share so user can move to iCloud Drive
      if (Platform.isIOS) {
        AppLogger.debug('iOS: Opening share sheet for file...', 'BackupService');
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'LoyaltyCards Backup - ${backup.businessName}',
          text: 'Save this backup to a secure location',
          sharePositionOrigin: sharePositionOrigin,
        );
        AppLogger.debug('Share result: ${result.status}', 'BackupService');
      }

      AppLogger.debug('=== saveToFiles END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } on UnsupportedError catch (e) {
      AppLogger.error('Platform not supported: $e', tag: 'BackupService');
      return BackupResult.failure(
        BackupFailureReason.platformNotSupported,
        'This backup method is not supported on your device.',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error saving backup to files: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission')) {
        return BackupResult.failure(
          BackupFailureReason.permissionDenied,
          'Storage permission denied. Enable in Settings.',
        );
      } else if (errorString.contains('space') || errorString.contains('disk full')) {
        return BackupResult.failure(
          BackupFailureReason.diskFull,
          'Not enough storage space. Free up space and try again.',
        );
      }
      
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to save to files: ${e.toString()}',
      );
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

  // ============================================================================
  // SIMPLE MODE STAMP TOKEN METHODS
  // ============================================================================

  /// Generate file name for Simple Mode stamp token QR codes
  /// Format: LoyaltyCards-SimpleToken-{stamps}Stamp-{BusinessName}-{Date}.{ext}
  /// Example: LoyaltyCards-SimpleToken-2Stamps-CoffeeShop-2026-04-20.png
  static String _generateSimpleTokenFileName({
    required String businessName,
    required int stampCount,
    required DateTime date,
    required String extension,
  }) {
    final timestamp = DateFormat('yyyy-MM-dd').format(date);
    final sanitizedBusinessName = businessName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '-');
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

  /// Save Simple Mode stamp token QR to photo gallery
  static Future<BackupResult> saveSimpleTokenToPhotos({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
  }) async {
    try {
      AppLogger.debug('=== saveSimpleTokenToPhotos START ===', 'BackupService');
      
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
      
      AppLogger.debug('Generated filename: $fileName', 'BackupService');
      AppLogger.debug('Image bytes size: ${qrImageBytes.length}', 'BackupService');

      // CR-1.2: Use timeout with explicit error handling
      final result = await Future.value(ImageGallerySaver.saveImage(
        qrImageBytes,
        quality: 100,
        name: fileName,
        isReturnImagePathOfIOS: true,
      )).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.error(
            'Simple token photo save timeout - operation uncertain',
            tag: 'BackupService',
          );
          throw TimeoutException('Photo save timeout after 10 seconds');
        },
      );

      final success = result is Map && result['isSuccess'] == true;
      AppLogger.debug('=== saveSimpleTokenToPhotos END (success: $success) ===', 'BackupService');
      return success
        ? BackupResult.success()
        : BackupResult.failure(BackupFailureReason.unknown, 'Failed to save to photos.');
    } on TimeoutException catch (e) {
      AppLogger.error(
        'Simple token photo save timeout: $e',
        tag: 'BackupService',
      );
      return BackupResult.failure(
        BackupFailureReason.timeout,
        'Operation timed out. Try another method.',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error saving simple token to photos: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission')) {
        return BackupResult.failure(
          BackupFailureReason.permissionDenied,
          'Storage permission denied.',
        );
      }
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to save: ${e.toString()}',
      );
    }
  }

  /// Print Simple Mode stamp token QR
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
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );

      AppLogger.debug('=== printSimpleToken END (success: true) ===', 'BackupService');
      return BackupResult.success();
    } catch (e, stackTrace) {
      AppLogger.error('Error printing simple token: $e', tag: 'BackupService');
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

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
        text: body,
        sharePositionOrigin: sharePositionOrigin,
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
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'LoyaltyCards Stamp Token - $stampText',
          text: 'Save this stamp token to a secure location',
          sharePositionOrigin: sharePositionOrigin,
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
    
    final stampText = stampCount == 1 ? '1 Stamp' : '$stampCount Stamps';
    final expiryText = expiryDate != null
        ? 'Expires: ${DateFormat('MMMM d, yyyy').format(expiryDate)}'
        : 'No Expiry Date';

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
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200, width: 2),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Stamp Token: $stampText',
                        style: pw.TextStyle(
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
                        style: pw.TextStyle(
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

  // ============================================================================
  // ISSUE CARD QR CODE METHODS (Simple Mode)
  // ============================================================================

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
    required String qrData,
    required String businessName,
    required int initialStamps,
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

  /// Save Simple Mode issue card QR to photo gallery
  static Future<BackupResult> saveIssueCardToPhotos({
    required String qrData,
    required String businessName,
    required int initialStamps,
  }) async {
    try {
      AppLogger.debug('=== saveIssueCardToPhotos START ===', 'BackupService');
      
      final qrImageBytes = await generateIssueCardQRImageBytes(
        qrData: qrData,
        businessName: businessName,
        initialStamps: initialStamps,
      );
      
      final fileName = _generateIssueCardFileName(
        businessName: businessName,
        initialStamps: initialStamps,
        date: DateTime.now(),
        extension: 'png',
      );
      
      AppLogger.debug('Generated filename: $fileName', 'BackupService');
      AppLogger.debug('Image bytes size: ${qrImageBytes.length}', 'BackupService');

      final result = await Future.value(ImageGallerySaver.saveImage(
        qrImageBytes,
        quality: 100,
        name: fileName,
        isReturnImagePathOfIOS: true,
      )).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLogger.error(
            'Issue card photo save timeout - operation uncertain',
            tag: 'BackupService',
          );
          throw TimeoutException('Photo save timeout after 10 seconds');
        },
      );

      final success = result is Map && result['isSuccess'] == true;
      AppLogger.debug('=== saveIssueCardToPhotos END (success: $success) ===', 'BackupService');
      return success
        ? BackupResult.success()
        : BackupResult.failure(BackupFailureReason.unknown, 'Failed to save to photos.');
    } on TimeoutException catch (e) {
      AppLogger.error(
        'Issue card photo save timeout: $e',
        tag: 'BackupService',
      );
      return BackupResult.failure(
        BackupFailureReason.timeout,
        'Operation timed out. Try another method.',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error saving issue card to photos: $e', tag: 'BackupService');
      AppLogger.error('Stack trace: $stackTrace', tag: 'BackupService');
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('permission')) {
        return BackupResult.failure(
          BackupFailureReason.permissionDenied,
          'Storage permission denied.',
        );
      }
      return BackupResult.failure(
        BackupFailureReason.unknown,
        'Failed to save: ${e.toString()}',
      );
    }
  }

  /// Print Simple Mode issue card QR
  static Future<BackupResult> printIssueCard({
    required String qrData,
    required String businessName,
    required int initialStamps,
  }) async {
    try {
      AppLogger.debug('=== printIssueCard START ===', 'BackupService');
      
      final qrImageBytes = await generateIssueCardQRImageBytes(
        qrData: qrData,
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
        onLayout: (PdfPageFormat format) async => pdf.save(),
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
    required String qrData,
    required String businessName,
    required int initialStamps,
    Rect? sharePositionOrigin,
  }) async {
    try {
      AppLogger.debug('=== shareIssueCard START ===', 'BackupService');
      
      final qrImageBytes = await generateIssueCardQRImageBytes(
        qrData: qrData,
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
