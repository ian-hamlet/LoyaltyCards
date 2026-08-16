import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('AlphanumericQr - TEST-020', () {
    test('builds a QrCode for short data', () {
      final qr = AlphanumericQr.build('HELLO');
      expect(qr, isNotNull);
    });

    test('picks a small version for a small payload, not always the largest', () {
      // A tiny payload should not need anywhere near version 40 - if it
      // did, every low-relocation, low-stamp-count redemption QR would be
      // needlessly dense and harder to scan for no reason.
      final qr = AlphanumericQr.build('HELLO WORLD 123');
      expect(qr, isNotNull);
      expect(qr!.typeNumber, lessThan(10));
    });

    test('picks a larger version as the payload grows', () {
      final small = AlphanumericQr.build('A' * 20)!;
      final large = AlphanumericQr.build('A' * 2000)!;
      expect(large.typeNumber, greaterThan(small.typeNumber));
    });

    test('returns null when data exceeds even version 40 capacity', () {
      // Alphanumeric mode's version-40/level-L capacity is 4296 characters.
      final tooLarge = 'A' * 5000;
      expect(AlphanumericQr.build(tooLarge), isNull);
    });

    test('fits data right at the version-40/level-L alphanumeric ceiling (4296 chars)', () {
      final atCeiling = 'A' * 4296;
      final qr = AlphanumericQr.build(atCeiling);
      expect(qr, isNotNull);
      expect(qr!.typeNumber, 40);
    });

    test('rejects data one character past the ceiling', () {
      final overCeiling = 'A' * 4297;
      expect(AlphanumericQr.build(overCeiling), isNull);
    });

    test('works with a real Base45-encoded string (the intended pairing)', () {
      final data = List<int>.generate(300, (i) => i % 256);
      final base45 = Base45.encode(data);
      final qr = AlphanumericQr.build(base45);
      expect(qr, isNotNull);
    });
  });
}
