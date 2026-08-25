/// Shared error-string classification for the backup services in
/// `services/backup/` - extracted during a follow-up code-quality pass
/// after the original split left this check duplicated (and, on the print
/// paths, missing entirely) across four call sites, with an overly broad
/// match (`contains('space')`) that could misclassify unrelated errors
/// mentioning "namespace"/"workspace"/"whitespace" as a disk-full failure.
class BackupErrorClassification {
  /// True if [errorString] (already lowercased by the caller) looks like a
  /// genuine out-of-storage failure, using specific phrasing rather than
  /// the bare word "space".
  static bool isDiskFullError(String errorString) {
    return errorString.contains('disk full') ||
        errorString.contains('no space left') ||
        errorString.contains('not enough space') ||
        errorString.contains('insufficient space') ||
        errorString.contains('insufficient storage');
  }
}
