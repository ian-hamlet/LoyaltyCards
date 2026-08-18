import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

/// Generates realistic, high-entropy (non-repeating) fake signature/ID
/// data - see the same class in redemption_qr_codec_test.dart for why a
/// repeated-character placeholder would understate real-world payload
/// sizes.
class _RealisticData {
  final Random _rng;
  _RealisticData(int seed) : _rng = Random(seed);

  String signature() {
    final bytes = List<int>.generate(66, (_) => _rng.nextInt(256));
    return base64Encode(bytes);
  }

  String uuid() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  CardIssueToken buildToken(int initialStampCount, {int stampsRequired = 12}) {
    final initialStamps = List.generate(
      initialStampCount,
      (i) => InitialStamp(
        stampNumber: i + 1,
        signature: signature(),
        timestamp: DateTime.now().millisecondsSinceEpoch + i,
      ),
    );
    return CardIssueToken(
      businessId: uuid(),
      businessName: "Maria's Luxury Spa & Wellness Centre",
      publicKey: signature(),
      stampsRequired: stampsRequired,
      brandColor: '#6A1B9A',
      logoIndex: 4,
      mode: OperationMode.secure,
      signature: signature(),
      cardId: '${uuid()}_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      initialStamps: initialStamps,
    );
  }
}

void main() {
  group('CardIssueQrCodec - TEST-021', () {
    test('round-trip preserves all fields, including initial stamps', () {
      final data = _RealisticData(1);
      final token = data.buildToken(6);

      final decoded = CardIssueQrCodec.decode(CardIssueQrCodec.encode(token));

      expect(decoded.businessId, token.businessId);
      expect(decoded.businessName, token.businessName);
      expect(decoded.publicKey, token.publicKey);
      expect(decoded.stampsRequired, token.stampsRequired);
      expect(decoded.brandColor, token.brandColor);
      expect(decoded.logoIndex, token.logoIndex);
      expect(decoded.mode, token.mode);
      expect(decoded.signature, token.signature);
      expect(decoded.cardId, token.cardId);
      expect(decoded.initialStamps.length, token.initialStamps.length);
      for (var i = 0; i < token.initialStamps.length; i++) {
        expect(decoded.initialStamps[i].stampNumber, token.initialStamps[i].stampNumber);
        expect(decoded.initialStamps[i].signature, token.initialStamps[i].signature);
        expect(decoded.initialStamps[i].timestamp, token.initialStamps[i].timestamp);
      }
    });

    test('round-trip preserves a token with zero initial stamps', () {
      final data = _RealisticData(2);
      final token = data.buildToken(0);

      final decoded = CardIssueQrCodec.decode(CardIssueQrCodec.encode(token));

      expect(decoded.initialStamps, isEmpty);
      expect(decoded.isValid(), true);
    });

    test('the encoded string is valid Base45 (QR alphanumeric-mode compatible)', () {
      final data = _RealisticData(3);
      final token = data.buildToken(4);
      final encoded = CardIssueQrCodec.encode(token);

      const alphabet = r'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:';
      for (final char in encoded.split('')) {
        expect(alphabet.contains(char), true, reason: '"$char" is not alphanumeric-mode compatible');
      }
    });

    test('the encoded string is never valid JSON - the decode-fallback dispatch relies on this', () {
      final data = _RealisticData(4);
      final token = data.buildToken(3);
      final encoded = CardIssueQrCodec.encode(token);

      expect(() => jsonDecode(encoded), throwsFormatException);
    });

    test('includes the current version marker in the decompressed payload', () {
      final data = _RealisticData(5);
      final token = data.buildToken(3);
      final encoded = CardIssueQrCodec.encode(token);

      final compressed = Base45.decode(encoded);
      final json = jsonDecode(utf8.decode(gzip.decode(compressed))) as Map<String, dynamic>;
      expect(json['v'], CardIssueQrCodec.currentVersion);
    });

    test('decode throws on garbage input', () {
      expect(() => CardIssueQrCodec.decode('not valid base45 at all !!'), throwsA(anything));
      expect(() => CardIssueQrCodec.decode(''), throwsA(anything));
    });

    group('worst-case size verification against the real qr package', () {
      // TEST-021: an issue card's initial-stamp count is capped by the
      // business's stampsRequired for any *new* business (max 12), but a
      // legacy business created before that cap existed can still have a
      // much higher stampsRequired stored (up to 20, the historical
      // maximum) - the initial-stamp slider's max tracks that stored
      // value, not the current onboarding range. These mirror the exact
      // scenarios measured manually during investigation.
      bool fitsAsQr(CardIssueToken token) {
        final encoded = CardIssueQrCodec.encode(token);
        return AlphanumericQr.build(encoded) != null;
      }

      test('12 initial stamps (max for any new business today): fits', () {
        expect(fitsAsQr(_RealisticData(10).buildToken(12)), true);
      });

      test('16 initial stamps (roughly where the old plain-JSON encoding failed): fits', () {
        expect(fitsAsQr(_RealisticData(11).buildToken(16, stampsRequired: 20)), true);
      });

      test('20 initial stamps (the historical maximum stampsRequired, worst case): fits', () {
        // The headline guarantee TEST-021 was built to provide - a legacy
        // business still configured for the old maximum of 20 stamps can
        // issue a card with every single stamp pre-applied.
        expect(fitsAsQr(_RealisticData(12).buildToken(20, stampsRequired: 20)), true);
      });

      test('35 initial stamps: does not fit (far beyond any real configuration, sanity check)', () {
        expect(fitsAsQr(_RealisticData(13).buildToken(35, stampsRequired: 35)), false);
      });
    });
  });
}
