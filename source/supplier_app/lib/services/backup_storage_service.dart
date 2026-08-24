import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/models/supplier_config_backup.dart';
import 'backup/config_backup_service.dart';
import 'backup/simple_token_backup_service.dart';
import 'backup/issue_card_backup_service.dart';
import 'backup/pdf_validation.dart';
import '../models/backup_result.dart';

/// Facade preserving `BackupStorageService`'s original call surface after
/// the class was split into four focused services under `services/backup/`
/// (config backups, Express Mode stamp tokens, issue cards, and shared PDF
/// validation) - see those files for the actual implementations. Kept at
/// this same path/API so every existing caller and the existing 20-test
/// suite (`test/services/backup_storage_service_test.dart`) need zero edits.
class BackupStorageService {
  static Future<BackupResult> printBackup(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes,
  ) =>
      ConfigBackupService.printBackup(backup, qrImageBytes);

  static Future<BackupResult> shareViaEmail(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes, {
    Rect? sharePositionOrigin,
  }) =>
      ConfigBackupService.shareViaEmail(backup, qrImageBytes, sharePositionOrigin: sharePositionOrigin);

  static Future<BackupResult> saveToFiles(
    SupplierConfigBackup backup,
    Uint8List qrImageBytes, {
    Rect? sharePositionOrigin,
  }) =>
      ConfigBackupService.saveToFiles(backup, qrImageBytes, sharePositionOrigin: sharePositionOrigin);

  static Future<Uint8List> generateQRImageBytes(
    SupplierConfigBackup backup, {
    double size = 800.0,
  }) =>
      ConfigBackupService.generateQRImageBytes(backup, size: size);

  @visibleForTesting
  static bool isValidPdfBytesForTesting(Uint8List bytes) => PdfValidation.isValidPdfBytes(bytes);

  static Future<Uint8List> generateSimpleTokenQRImageBytes({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
    double size = 800.0,
  }) =>
      SimpleTokenBackupService.generateSimpleTokenQRImageBytes(
        qrData: qrData,
        businessName: businessName,
        stampCount: stampCount,
        expiryDate: expiryDate,
        size: size,
      );

  static Future<BackupResult> printSimpleToken({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
  }) =>
      SimpleTokenBackupService.printSimpleToken(
        qrData: qrData,
        businessName: businessName,
        stampCount: stampCount,
        expiryDate: expiryDate,
      );

  static Future<BackupResult> shareSimpleTokenViaEmail({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
    Rect? sharePositionOrigin,
  }) =>
      SimpleTokenBackupService.shareSimpleTokenViaEmail(
        qrData: qrData,
        businessName: businessName,
        stampCount: stampCount,
        expiryDate: expiryDate,
        sharePositionOrigin: sharePositionOrigin,
      );

  static Future<BackupResult> saveSimpleTokenToFiles({
    required String qrData,
    required String businessName,
    required int stampCount,
    DateTime? expiryDate,
    Rect? sharePositionOrigin,
  }) =>
      SimpleTokenBackupService.saveSimpleTokenToFiles(
        qrData: qrData,
        businessName: businessName,
        stampCount: stampCount,
        expiryDate: expiryDate,
        sharePositionOrigin: sharePositionOrigin,
      );

  static Future<Uint8List> generateIssueCardQRImageBytes({
    required QrCode qrCode,
    required String businessName,
    required int initialStamps,
    double size = 800.0,
  }) =>
      IssueCardBackupService.generateIssueCardQRImageBytes(
        qrCode: qrCode,
        businessName: businessName,
        initialStamps: initialStamps,
        size: size,
      );

  static Future<BackupResult> printIssueCard({
    required QrCode qrCode,
    required String businessName,
    required int initialStamps,
  }) =>
      IssueCardBackupService.printIssueCard(
        qrCode: qrCode,
        businessName: businessName,
        initialStamps: initialStamps,
      );

  static Future<BackupResult> shareIssueCard({
    required QrCode qrCode,
    required String businessName,
    required int initialStamps,
    Rect? sharePositionOrigin,
  }) =>
      IssueCardBackupService.shareIssueCard(
        qrCode: qrCode,
        businessName: businessName,
        initialStamps: initialStamps,
        sharePositionOrigin: sharePositionOrigin,
      );
}
