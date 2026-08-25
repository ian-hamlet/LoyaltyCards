import 'package:flutter_test/flutter_test.dart';
import 'package:supplier_app/services/backup/backup_error_classification.dart';

/// A follow-up code-quality pass found the original disk-full heuristic
/// (`errorString.contains('space')`) too broad - it would misclassify any
/// exception whose message happens to contain "namespace"/"workspace"/
/// "whitespace" as a disk-full failure. This pins the tightened,
/// specific-phrase version.
void main() {
  group('BackupErrorClassification.isDiskFullError', () {
    test('matches common disk-full phrasings', () {
      expect(BackupErrorClassification.isDiskFullError('disk full'), isTrue);
      expect(BackupErrorClassification.isDiskFullError('no space left on device'), isTrue);
      expect(BackupErrorClassification.isDiskFullError('not enough space to complete operation'), isTrue);
      expect(BackupErrorClassification.isDiskFullError('insufficient space'), isTrue);
      expect(BackupErrorClassification.isDiskFullError('insufficient storage available'), isTrue);
    });

    test('does not misfire on unrelated messages that merely contain "space"', () {
      // The exact false-positive risk the original bare `contains('space')`
      // check had - none of these are disk-full errors.
      expect(BackupErrorClassification.isDiskFullError('invalid document name: trailing whitespace not allowed'), isFalse);
      expect(BackupErrorClassification.isDiskFullError('namespace error: xmlns not found'), isFalse);
      expect(BackupErrorClassification.isDiskFullError('workspace configuration invalid'), isFalse);
    });

    test('does not match an unrelated cancellation message', () {
      expect(BackupErrorClassification.isDiskFullError('print job cancelled by user'), isFalse);
    });

    test('is case-sensitive on the caller-lowercased input (matches how call sites use it)', () {
      // Call sites always lowercase before calling this - documenting that
      // expectation rather than re-lowercasing internally (would be
      // redundant work on every call).
      expect(BackupErrorClassification.isDiskFullError('DISK FULL'), isFalse);
      expect(BackupErrorClassification.isDiskFullError('disk full'), isTrue);
    });
  });
}
