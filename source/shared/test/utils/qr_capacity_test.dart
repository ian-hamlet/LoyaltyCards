import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('QrCapacity.fits - TEST-017', () {
    test('short data fits', () {
      expect(QrCapacity.fits('hello'), true);
    });

    test('data right at the level-L byte ceiling (2953 bytes) fits', () {
      final data = 'a' * 2953;
      expect(QrCapacity.fits(data), true);
    });

    test('data past the level-L byte ceiling does not fit', () {
      final data = 'a' * 3000;
      expect(QrCapacity.fits(data), false);
    });

    test('a realistic 10-stamp redemption payload (the new max) fits', () {
      // Mirrors CustomerCardDetail._generateCardQR()'s redemption shape,
      // using a realistic ~88-char base64 ECDSA signature per stamp.
      final signature = 'A' * 87 + '=';
      final stampProofs = List.generate(
        10,
        (i) => '{"signature":"$signature","timestamp":${1700000000000 + i}}',
      ).join(',');
      final data =
          '{"type":"redemption_request","cardId":"12345678-1234-1234-1234-123456789012_1700000000000",'
          '"businessId":"12345678-1234-1234-1234-123456789012","stampsCollected":10,'
          '"stampProofs":[$stampProofs],"timestamp":1700000000000,'
          '"cardDeviceId":"12345678-1234-1234-1234-123456789012",'
          '"currentDeviceId":"12345678-1234-1234-1234-123456789012"}';
      expect(QrCapacity.fits(data), true);
    });

    test('a fully-relocated 20-stamp redemption payload (the old max) does not fit', () {
      // The exact shape that motivated lowering the max from 20 to 10 -
      // a card built entirely from overflow-relocated stamps.
      final signature = 'A' * 87 + '=';
      final stampProofs = List.generate(
        20,
        (i) => '{"signature":"$signature","timestamp":${1700000000000 + i},'
            '"originalCardId":"12345678-1234-1234-1234-123456789012_${1700000000000 + i}",'
            '"originalStampNumber":${i + 1},'
            '"originalPreviousHash":"$signature"}',
      ).join(',');
      final data =
          '{"type":"redemption_request","cardId":"12345678-1234-1234-1234-123456789012_1700000000000",'
          '"businessId":"12345678-1234-1234-1234-123456789012","stampsCollected":20,'
          '"stampProofs":[$stampProofs],"timestamp":1700000000000,'
          '"cardDeviceId":"12345678-1234-1234-1234-123456789012",'
          '"currentDeviceId":"12345678-1234-1234-1234-123456789012"}';
      expect(QrCapacity.fits(data), false);
    });
  });
}
