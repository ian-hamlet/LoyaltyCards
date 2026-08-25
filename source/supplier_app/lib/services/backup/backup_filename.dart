import 'package:intl/intl.dart';

/// Filename-building primitives shared by every backup-generation service in
/// `services/backup/` - extracted from three near-identical copies (one
/// each in config_backup_service.dart, simple_token_backup_service.dart,
/// issue_card_backup_service.dart) found during a follow-up code-quality
/// pass on the original split.
class BackupFilename {
  /// Strips characters that aren't safe in a filename (keeping word
  /// characters, whitespace, and hyphens) and collapses spaces to hyphens.
  static String sanitizeBusinessName(String businessName) {
    return businessName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '-');
  }

  /// The `yyyy-MM-dd` date segment every generated filename ends with.
  static String dateStamp(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
}
