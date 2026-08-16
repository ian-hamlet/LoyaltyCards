import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

/// Generates realistic, high-entropy (non-repeating) fake signature/ID data
/// - a repeated-character placeholder would compress unrealistically well
/// with gzip and understate real-world payload sizes (a mistake made and
/// caught during manual investigation of this fix - see DEFECT_TRACKER.md
/// TEST-020).
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

  String cardId() => '${uuid()}_${DateTime.now().millisecondsSinceEpoch}';

  RedemptionRequestToken buildToken(int totalStamps, int relocatedCount) {
    final proofs = List.generate(totalStamps, (i) {
      final relocated = i < relocatedCount;
      return RedemptionStampProof(
        signature: signature(),
        timestamp: DateTime.now().millisecondsSinceEpoch + i,
        originalCardId: relocated ? cardId() : null,
        originalStampNumber: relocated ? i + 1 : null,
        originalPreviousHash: relocated ? signature() : null,
      );
    });
    return RedemptionRequestToken(
      cardId: cardId(),
      businessId: uuid(),
      stampsCollected: totalStamps,
      stampProofs: proofs,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      cardDeviceId: uuid(),
      currentDeviceId: uuid(),
    );
  }
}

void main() {
  group('RedemptionQrCodec - TEST-020', () {
    test('round-trip preserves all fields, including relocated-stamp provenance', () {
      final data = _RealisticData(1);
      final token = data.buildToken(6, 3);

      final encoded = RedemptionQrCodec.encode(token);
      final decoded = RedemptionQrCodec.decode(encoded);

      expect(decoded.cardId, token.cardId);
      expect(decoded.businessId, token.businessId);
      expect(decoded.stampsCollected, token.stampsCollected);
      expect(decoded.cardDeviceId, token.cardDeviceId);
      expect(decoded.currentDeviceId, token.currentDeviceId);
      expect(decoded.stampProofs.length, token.stampProofs.length);
      for (var i = 0; i < token.stampProofs.length; i++) {
        expect(decoded.stampProofs[i].signature, token.stampProofs[i].signature);
        expect(decoded.stampProofs[i].timestamp, token.stampProofs[i].timestamp);
        expect(decoded.stampProofs[i].originalCardId, token.stampProofs[i].originalCardId);
        expect(decoded.stampProofs[i].originalStampNumber, token.stampProofs[i].originalStampNumber);
        expect(decoded.stampProofs[i].originalPreviousHash, token.stampProofs[i].originalPreviousHash);
      }
    });

    test('round-trip preserves a token with zero relocated stamps', () {
      final data = _RealisticData(2);
      final token = data.buildToken(5, 0);

      final decoded = RedemptionQrCodec.decode(RedemptionQrCodec.encode(token));

      expect(decoded.stampProofs.every((p) => p.originalCardId == null), true);
      expect(decoded.isValid(), true);
    });

    test('the encoded string is valid Base45 (QR alphanumeric-mode compatible)', () {
      final data = _RealisticData(3);
      final token = data.buildToken(4, 2);
      final encoded = RedemptionQrCodec.encode(token);

      const alphabet = r'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ $%*+-./:';
      for (final char in encoded.split('')) {
        expect(alphabet.contains(char), true, reason: '"$char" is not alphanumeric-mode compatible');
      }
    });

    test('the encoded string is never valid JSON - the decode-fallback dispatch relies on this', () {
      final data = _RealisticData(4);
      final token = data.buildToken(3, 0);
      final encoded = RedemptionQrCodec.encode(token);

      expect(() => jsonDecode(encoded), throwsFormatException);
    });

    test('includes the current version marker in the decompressed payload', () {
      final data = _RealisticData(5);
      final token = data.buildToken(3, 0);
      final encoded = RedemptionQrCodec.encode(token);

      final compressed = Base45.decode(encoded);
      final json = jsonDecode(utf8.decode(gzip.decode(compressed))) as Map<String, dynamic>;
      expect(json['v'], RedemptionQrCodec.currentVersion);
    });

    test('decode throws on garbage input', () {
      expect(() => RedemptionQrCodec.decode('not valid base45 at all !!'), throwsA(anything));
      expect(() => RedemptionQrCodec.decode(''), throwsA(anything));
    });

    group('worst-case size verification against the real qr package', () {
      // These mirror the exact scenarios measured manually during
      // investigation (DEFECT_TRACKER.md TEST-020) - re-verified here as
      // real, automated tests rather than one-off scratch scripts, so a
      // future change to the codec or its dependencies can't silently
      // regress the guarantee TEST-020 was built to provide.
      bool fitsAsQr(RedemptionRequestToken token) {
        final encoded = RedemptionQrCodec.encode(token);
        return AlphanumericQr.build(encoded) != null;
      }

      test('10 stamps, 0% relocated: fits', () {
        expect(fitsAsQr(_RealisticData(10).buildToken(10, 0)), true);
      });

      test('10 stamps, 100% relocated (worst case): fits', () {
        expect(fitsAsQr(_RealisticData(11).buildToken(10, 10)), true);
      });

      test('12 stamps, 0% relocated: fits', () {
        expect(fitsAsQr(_RealisticData(12).buildToken(12, 0)), true);
      });

      test('12 stamps, 50% relocated: fits', () {
        expect(fitsAsQr(_RealisticData(13).buildToken(12, 6)), true);
      });

      test('12 stamps, 100% relocated (the new maximum, worst case): fits', () {
        // This is the headline guarantee TEST-020 was built to provide -
        // a 12-stamp card is safe even if every single stamp on it was
        // relocated by the overflow-splitting logic (TEST-018's scenario).
        expect(fitsAsQr(_RealisticData(14).buildToken(12, 12)), true);
      });

      test('20 stamps, 100% relocated: does not fit (not a supported configuration, sanity check)', () {
        // stampsRequired is capped at 12 (TEST-020) so a business can't
        // actually configure this - this just confirms the ceiling is
        // real and the tests above aren't vacuously true for any size.
        expect(fitsAsQr(_RealisticData(15).buildToken(20, 20)), false);
      });
    });
  });
}
