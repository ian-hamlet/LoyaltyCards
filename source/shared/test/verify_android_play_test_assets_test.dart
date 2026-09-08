// Regression coverage for testing/android_play_assets/generate_test_assets.py:
// loads whatever that script most recently generated
// (output/generated_tokens.json) and runs each payload through this
// package's OWN real signature-verification code - exactly what the
// customer app does when a tester scans a printed QR. This is the actual
// proof the generator's hand-rolled crypto (a Python re-implementation of
// KeyManager's encoding, since the generator runs outside Flutter) produces
// tokens the real app accepts, not just self-consistent with the Python
// script's own logic.
//
// Deliberately kept as `flutter test`, not a plain `dart run` script: the
// import chain (crypto_utils.dart -> app_logger.dart ->
// package:flutter/foundation.dart -> dart:ui) needs Flutter's test binding
// to resolve at all - a bare `dart run` fails with "dart:ui is not
// available on this platform".
//
// If this test ever starts failing after an unrelated change elsewhere in
// this package, don't just fix it here - it means a real app-side change
// (a signature format, a field name, the Smart Routing sentinel string)
// would also invalidate every QR code already printed and handed to
// testers. Re-run generate_test_assets.py to produce a fresh, compatible
// PDF instead.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared/models/qr_tokens.dart';
import 'package:shared/models/supplier_config_backup.dart';
import 'package:shared/utils/crypto_utils.dart';

void main() {
  final tokensFile = File(
    '../../testing/android_play_assets/output/generated_tokens.json',
  );

  if (!tokensFile.existsSync()) {
    test(
      'generated_tokens.json not found - run generate_test_assets.py first',
      () {
        fail(
          'Expected ${tokensFile.path} - run '
          'testing/android_play_assets/generate_test_assets.py before this test.',
        );
      },
    );
    return;
  }

  final data = jsonDecode(tokensFile.readAsStringSync()) as Map<String, dynamic>;

  for (final entry in data.entries) {
    final businessName = entry.key;
    final tokens = entry.value as Map<String, dynamic>;

    group(businessName, () {
      test('Add Card QR has a genuine, verifiable ECDSA signature', () {
        final cardJson = tokens['card_issue'] as Map<String, dynamic>;
        final cardToken = CardIssueToken.fromJson(cardJson);

        expect(cardToken.validationError(), isNull);

        final result = CryptoUtils.verifySignature(
          data: cardToken.getSignatureData(),
          signatureBase64: cardToken.signature,
          publicKeyEncoded: cardToken.publicKey,
        );
        expect(
          result.isValid,
          isTrue,
          reason: result.failureReason ?? 'signature did not verify',
        );
      });

      for (final key in ['stamp_1', 'stamp_2', 'stamp_3']) {
        final expectedCount = int.parse(key.split('_').last);

        test(
          '$key QR is structurally valid with stampCount=$expectedCount and the Smart Routing sentinel',
          () {
            final stampJson = tokens[key] as Map<String, dynamic>;
            final stampToken = StampToken.fromJson(stampJson);

            expect(stampToken.isValid(), isTrue);
            // The literal string QrScannerController checks for in Express
            // Mode to route by businessId instead of exact cardId.
            expect(stampToken.cardId, equals('express-mode-stamp'));
            expect(stampToken.stampCount, equals(expectedCount));
            expect(stampToken.scanInterval, equals(10000));
          },
        );
      }

      test(
        'Business Backup QR has a genuine HMAC and its timestamp round-trips exactly',
        () async {
          final backupJson = tokens['backup'] as Map<String, dynamic>;
          final backup = SupplierConfigBackup.fromJson(backupJson);

          // The HMAC is computed over the *parsed-then-reformatted*
          // timestamp (backup.timestamp.toIso8601String()), not the raw
          // JSON string - if the Python generator's timestamp format
          // doesn't round-trip through Dart's DateTime parser/formatter
          // byte-for-byte, the signature silently fails to verify even
          // though every other field is correct.
          final roundTripped = backup.timestamp.toIso8601String();
          expect(roundTripped, equals(backupJson['timestamp']));

          expect(backup.type, equals('recovery'));
          expect(backup.expiresAt, isNull);
          expect(await backup.verifySignature(), isTrue);
        },
      );
    });
  }
}
