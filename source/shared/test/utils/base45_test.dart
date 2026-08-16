import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('Base45 - TEST-020', () {
    // Official RFC 9285 test vectors.
    test('matches RFC 9285 test vector "AB" -> "BB8"', () {
      expect(Base45.encode('AB'.codeUnits), 'BB8');
    });

    test('matches RFC 9285 test vector "Hello!!" -> "%69 VD92EX0"', () {
      expect(Base45.encode('Hello!!'.codeUnits), r'%69 VD92EX0');
    });

    test('matches RFC 9285 test vector "base-45" -> "UJCLQE7W581"', () {
      expect(Base45.encode('base-45'.codeUnits), 'UJCLQE7W581');
    });

    test('decode reverses each RFC 9285 test vector', () {
      expect(Base45.decode('BB8'), 'AB'.codeUnits);
      expect(Base45.decode(r'%69 VD92EX0'), 'Hello!!'.codeUnits);
      expect(Base45.decode('UJCLQE7W581'), 'base-45'.codeUnits);
    });

    test('round-trips empty input', () {
      expect(Base45.encode([]), '');
      expect(Base45.decode(''), <int>[]);
    });

    test('round-trips a single byte', () {
      final data = [200];
      expect(Base45.decode(Base45.encode(data)), data);
    });

    test('round-trips random data across a range of lengths, including odd lengths', () {
      final rng = Random(7);
      for (final len in [1, 2, 3, 4, 5, 10, 66, 132, 999]) {
        final data = List<int>.generate(len, (_) => rng.nextInt(256));
        final encoded = Base45.encode(data);
        final decoded = Base45.decode(encoded);
        expect(decoded, data, reason: 'round-trip failed at length $len');
      }
    });

    test('only produces characters from the QR alphanumeric-mode alphabet', () {
      final rng = Random(3);
      const alphanumericAlphabet = r'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:';
      final data = List<int>.generate(200, (_) => rng.nextInt(256));
      final encoded = Base45.encode(data);
      for (final char in encoded.split('')) {
        expect(alphanumericAlphabet.contains(char), true, reason: '"$char" is not in the alphanumeric alphabet');
      }
    });

    test('decode throws FormatException on an invalid character', () {
      expect(() => Base45.decode('ab'), throwsFormatException); // lowercase not in alphabet
      expect(() => Base45.decode('BB!'), throwsFormatException);
    });

    test('decode throws FormatException on a dangling single-character group', () {
      expect(() => Base45.decode('BB8B'), throwsFormatException); // 4 chars: one full group + 1 dangling
    });

    test('decode throws FormatException when a trailing 2-char group exceeds one byte', () {
      // 'FZ' -> value = 15 + 35*45 = 1590, which doesn't fit in a byte -
      // only valid as part of a 3-char (2-byte) group, not a trailing pair.
      expect(() => Base45.decode('FZ'), throwsFormatException);
    });
  });
}
