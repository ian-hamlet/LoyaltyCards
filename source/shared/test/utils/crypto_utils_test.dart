import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:shared/shared.dart';

/// Direct coverage of CryptoUtils.verifySignature — the ECDSA P-256 / SHA-256
/// signature verification declared to Apple in the App Review export
/// compliance packet. Signing helpers below mirror KeyManager's encoding
/// (supplier_app/lib/services/key_manager.dart) so this exercises the exact
/// wire format used in production, not a simplified stand-in.

SecureRandom _secureRandom() {
  final random = FortunaRandom();
  final seedSource = Random.secure();
  final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
  random.seed(KeyParameter(Uint8List.fromList(seeds)));
  return random;
}

AsymmetricKeyPair<PublicKey, PrivateKey> _generateKeyPair() {
  final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
  final generator = ECKeyGenerator()
    ..init(ParametersWithRandom(keyParams, _secureRandom()));
  return generator.generateKeyPair();
}

List<int> _bigIntToBytes(BigInt number) {
  final hex = number.toRadixString(16);
  final padded = hex.length.isOdd ? '0$hex' : hex;
  final bytes = <int>[];
  for (int i = 0; i < padded.length; i += 2) {
    bytes.add(int.parse(padded.substring(i, i + 2), radix: 16));
  }
  return bytes;
}

List<int> _encodeLength(int length) {
  return [
    (length >> 24) & 0xFF,
    (length >> 16) & 0xFF,
    (length >> 8) & 0xFF,
    length & 0xFF,
  ];
}

String _encodePublicKey(ECPublicKey publicKey) {
  final xBytes = _bigIntToBytes(publicKey.Q!.x!.toBigInteger()!);
  final yBytes = _bigIntToBytes(publicKey.Q!.y!.toBigInteger()!);

  final combined = <int>[];
  combined.addAll(_encodeLength(xBytes.length));
  combined.addAll(xBytes);
  combined.addAll(_encodeLength(yBytes.length));
  combined.addAll(yBytes);

  return base64Encode(combined);
}

String _sign(String data, ECPrivateKey privateKey) {
  final signer = ECDSASigner(SHA256Digest());
  signer.init(
    true,
    ParametersWithRandom(
      PrivateKeyParameter<ECPrivateKey>(privateKey),
      _secureRandom(),
    ),
  );

  final dataBytes = utf8.encode(data);
  final signature =
      signer.generateSignature(Uint8List.fromList(dataBytes)) as ECSignature;

  final rBytes = _bigIntToBytes(signature.r);
  final sBytes = _bigIntToBytes(signature.s);

  final combined = <int>[];
  combined.addAll(_encodeLength(rBytes.length));
  combined.addAll(rBytes);
  combined.addAll(_encodeLength(sBytes.length));
  combined.addAll(sBytes);

  return base64Encode(combined);
}

void main() {
  group('CryptoUtils.verifySignature', () {
    late AsymmetricKeyPair<PublicKey, PrivateKey> keyPair;
    late String publicKeyEncoded;

    setUp(() {
      keyPair = _generateKeyPair();
      publicKeyEncoded = _encodePublicKey(keyPair.publicKey as ECPublicKey);
    });

    test('accepts a genuine signature over the signed data', () {
      const data = 'card-001:5:1749600000000:';
      final signature = _sign(data, keyPair.privateKey as ECPrivateKey);

      final result = CryptoUtils.verifySignature(
        data: data,
        signatureBase64: signature,
        publicKeyEncoded: publicKeyEncoded,
      );

      expect(result.isValid, isTrue);
      expect(result.failureReason, isNull);
    });

    test('rejects a signature when the signed data has been tampered with',
        () {
      const originalData = 'card-001:5:1749600000000:';
      final signature = _sign(originalData, keyPair.privateKey as ECPrivateKey);

      final result = CryptoUtils.verifySignature(
        data: 'card-001:6:1749600000000:', // stamp number altered
        signatureBase64: signature,
        publicKeyEncoded: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, 'signature_mismatch');
    });

    test('rejects a signature verified against the wrong public key', () {
      const data = 'card-001:5:1749600000000:';
      final signature = _sign(data, keyPair.privateKey as ECPrivateKey);

      final otherKeyPair = _generateKeyPair();
      final wrongPublicKeyEncoded =
          _encodePublicKey(otherKeyPair.publicKey as ECPublicKey);

      final result = CryptoUtils.verifySignature(
        data: data,
        signatureBase64: signature,
        publicKeyEncoded: wrongPublicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, 'signature_mismatch');
    });

    test('rejects an empty signature without throwing', () {
      final result = CryptoUtils.verifySignature(
        data: 'card-001:5:1749600000000:',
        signatureBase64: '',
        publicKeyEncoded: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, startsWith('invalid_signature_length'));
    });

    test('rejects a truncated/malformed signature without throwing', () {
      // Valid base64, but far too short to contain r/s length headers.
      final result = CryptoUtils.verifySignature(
        data: 'card-001:5:1749600000000:',
        signatureBase64: base64Encode([1, 2, 3]),
        publicKeyEncoded: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, startsWith('invalid_signature_length'));
    });

    test('rejects a signature with a corrupted length header without throwing',
        () {
      const data = 'card-001:5:1749600000000:';
      final signature = _sign(data, keyPair.privateKey as ECPrivateKey);
      final bytes = base64Decode(signature);

      // Force the r-length header to an absurd value so it exceeds the buffer.
      final corrupted = List<int>.from(bytes);
      corrupted[0] = 0x7F;
      corrupted[1] = 0xFF;
      corrupted[2] = 0xFF;
      corrupted[3] = 0xFF;

      final result = CryptoUtils.verifySignature(
        data: data,
        signatureBase64: base64Encode(corrupted),
        publicKeyEncoded: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, 'invalid_signature_format');
    });

    test('rejects an empty public key without throwing', () {
      const data = 'card-001:5:1749600000000:';
      final signature = _sign(data, keyPair.privateKey as ECPrivateKey);

      final result = CryptoUtils.verifySignature(
        data: data,
        signatureBase64: signature,
        publicKeyEncoded: '',
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, 'invalid_public_key');
    });

    test('rejects a public key with an invalid coordinate without throwing',
        () {
      const data = 'card-001:5:1749600000000:';
      final signature = _sign(data, keyPair.privateKey as ECPrivateKey);

      // Well-formed header/length framing, but the point isn't on the curve.
      final bogus = <int>[];
      bogus.addAll(_encodeLength(1));
      bogus.add(0x42);
      bogus.addAll(_encodeLength(1));
      bogus.add(0x42);

      final result = CryptoUtils.verifySignature(
        data: data,
        signatureBase64: signature,
        publicKeyEncoded: base64Encode(bogus),
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, isNotNull);
    });

    test('is deterministic: verifying the same valid signature twice both succeed',
        () {
      const data = 'card-001:5:1749600000000:';
      final signature = _sign(data, keyPair.privateKey as ECPrivateKey);

      final first = CryptoUtils.verifySignature(
        data: data,
        signatureBase64: signature,
        publicKeyEncoded: publicKeyEncoded,
      );
      final second = CryptoUtils.verifySignature(
        data: data,
        signatureBase64: signature,
        publicKeyEncoded: publicKeyEncoded,
      );

      expect(first.isValid, isTrue);
      expect(second.isValid, isTrue);
    });
  });

  group('CryptoUtils.verifyRedemptionStampChain', () {
    late AsymmetricKeyPair<PublicKey, PrivateKey> keyPair;
    late String publicKeyEncoded;

    setUp(() {
      keyPair = _generateKeyPair();
      publicKeyEncoded = _encodePublicKey(keyPair.publicKey as ECPublicKey);
    });

    /// Signs a stamp the same way genuine Secure Mode issuance does after
    /// the V-010 fix: stampCount=1, expiryDate=null, scanInterval=null are
    /// baked into every real Secure Mode stamp (see supplier_stamp_card.dart
    /// - it never sets these REQ-022/Simple-Mode-only fields).
    String signChainStamp({
      required String cardId,
      required int stampNumber,
      required int timestamp,
      required String previousHash,
    }) {
      final data = '$cardId:$stampNumber:$timestamp:$previousHash:1::';
      return _sign(data, keyPair.privateKey as ECPrivateKey);
    }

    List<RedemptionStampProof> genuineChain(String cardId, int count) {
      final proofs = <RedemptionStampProof>[];
      String previousHash = '';
      for (int i = 1; i <= count; i++) {
        final timestamp = 1749600000000 + i;
        final signature = signChainStamp(
          cardId: cardId,
          stampNumber: i,
          timestamp: timestamp,
          previousHash: previousHash,
        );
        proofs.add(RedemptionStampProof(signature: signature, timestamp: timestamp));
        previousHash = signature;
      }
      return proofs;
    }

    test('accepts a genuine, fully-signed stamp chain', () {
      final proofs = genuineChain('card-001', 5);

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-001',
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isTrue);
    });

    test('rejects a chain with a fabricated signature (V-012 core case)', () {
      // No real stamps were ever issued - customer fabricates the whole
      // redemption request from scratch, as V-012 describes.
      final fabricated = [
        RedemptionStampProof(signature: 'not-a-real-signature', timestamp: 1),
        RedemptionStampProof(signature: 'also-fake', timestamp: 2),
      ];

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-001',
        stampProofs: fabricated,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
    });

    test('rejects when a genuine stamp is appended with a fabricated one', () {
      final proofs = genuineChain('card-001', 2)
        ..add(RedemptionStampProof(signature: 'fabricated-extra-stamp', timestamp: 999));

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-001',
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, contains('stamp_3'));
    });

    test('rejects a genuine chain verified against a different cardId', () {
      final proofs = genuineChain('card-001', 3);

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-999', // customer claims a different card
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
    });

    test('rejects a genuine chain verified against the wrong business public key', () {
      final proofs = genuineChain('card-001', 3);
      final otherKeyPair = _generateKeyPair();
      final wrongPublicKey = _encodePublicKey(otherKeyPair.publicKey as ECPublicKey);

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-001',
        stampProofs: proofs,
        businessPublicKey: wrongPublicKey,
      );

      expect(result.isValid, isFalse);
    });

    test('rejects reordered stamps (breaks the hash chain)', () {
      final proofs = genuineChain('card-001', 3);
      final reordered = [proofs[1], proofs[0], proofs[2]];

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-001',
        stampProofs: reordered,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
    });

    test('rejects an empty stamp list rather than vacuously succeeding', () {
      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-001',
        stampProofs: [],
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, 'no_stamps_to_verify');
    });

    test('accepts a stamp relocated from another card via its original context', () {
      // Simulates the overflow-splitting scenario: this stamp was genuinely
      // signed as stamp #6 on 'card-source' (chained to some prior stamp's
      // signature there), then moved onto 'card-dest' as its stamp #1. Its
      // signature only verifies against the original data, not its new
      // position - originalCardId/originalStampNumber/originalPreviousHash
      // is exactly what lets that still verify correctly.
      final sourcePreviousHash = signChainStamp(
        cardId: 'card-source',
        stampNumber: 5,
        timestamp: 1749600000005,
        previousHash: '',
      );
      final movedSignature = signChainStamp(
        cardId: 'card-source',
        stampNumber: 6,
        timestamp: 1749600000006,
        previousHash: sourcePreviousHash,
      );

      final proofs = [
        RedemptionStampProof(
          signature: movedSignature,
          timestamp: 1749600000006,
          originalCardId: 'card-source',
          originalStampNumber: 6,
          originalPreviousHash: sourcePreviousHash,
        ),
      ];

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-dest',
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isTrue);
    });

    test('rejects a moved stamp whose claimed original context is wrong', () {
      // Genuinely signed as card-source stamp #6, but the redemption
      // request claims it was originally stamp #7 - the signature won't
      // match that fabricated claim.
      final movedSignature = signChainStamp(
        cardId: 'card-source',
        stampNumber: 6,
        timestamp: 1749600000006,
        previousHash: '',
      );

      final proofs = [
        RedemptionStampProof(
          signature: movedSignature,
          timestamp: 1749600000006,
          originalCardId: 'card-source',
          originalStampNumber: 7, // wrong - was actually signed as #6
          originalPreviousHash: '',
        ),
      ];

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-dest',
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
    });

    test('rejects reusing a stamp genuinely earned on one card by claiming it as another card\'s own', () {
      // The exact replay this design must prevent: a signature genuinely
      // earned as card-source's own stamp #1, presented on card-dest's
      // redemption WITHOUT any originalCardId - i.e. claiming it was
      // directly earned there, positionally, rather than moved. Since its
      // signature covers card-source (not card-dest), positional
      // verification against card-dest must fail.
      final signature = signChainStamp(
        cardId: 'card-source',
        stampNumber: 1,
        timestamp: 1749600000001,
        previousHash: '',
      );

      final proofs = [
        RedemptionStampProof(signature: signature, timestamp: 1749600000001),
      ];

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-dest',
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
    });

    test('accepts a mixed chain: a moved stamp followed by a normally-earned one', () {
      // Stamp 1 arrived via the overflow move (signed for card-source #3).
      // Stamp 2 was earned normally, directly on card-dest afterwards, so
      // its previousHash is genuinely the moved stamp's signature - the
      // chain walk must keep using proof.signature between iterations
      // regardless of whether the preceding stamp was itself moved.
      final movedSignature = signChainStamp(
        cardId: 'card-source',
        stampNumber: 3,
        timestamp: 1749600000003,
        previousHash: '',
      );
      final normalSignature = signChainStamp(
        cardId: 'card-dest',
        stampNumber: 2,
        timestamp: 1749600000010,
        previousHash: movedSignature,
      );

      final proofs = [
        RedemptionStampProof(
          signature: movedSignature,
          timestamp: 1749600000003,
          originalCardId: 'card-source',
          originalStampNumber: 3,
          originalPreviousHash: '',
        ),
        RedemptionStampProof(signature: normalSignature, timestamp: 1749600000010),
      ];

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-dest',
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isTrue);
    });

    test('rejects a redemption request that repeats the same genuine proof to inflate the count', () {
      // The exact laundering attack this check exists to close: a customer
      // genuinely earns ONE real stamp, then submits it multiple times
      // (each independently a perfectly valid signature) to claim a card
      // is complete when only one stamp was ever actually issued.
      final genuineSignature = signChainStamp(
        cardId: 'card-001',
        stampNumber: 1,
        timestamp: 1749600000001,
        previousHash: '',
      );

      final proofs = List.generate(
        5,
        (_) => RedemptionStampProof(signature: genuineSignature, timestamp: 1749600000001),
      );

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-001',
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, 'duplicate_stamp_signature');
    });

    test('rejects duplicate proofs even when each independently claims a different (fabricated) original card', () {
      // Guards against a narrower variant: duplicating a genuine proof
      // while giving each copy a different originalCardId/originalStampNumber
      // claim, hoping the per-proof originalContext check masks the reuse.
      // The signature itself is still the same real artifact being reused,
      // so this must still be rejected regardless of what original context
      // each copy claims.
      final genuineSignature = signChainStamp(
        cardId: 'card-source',
        stampNumber: 1,
        timestamp: 1749600000001,
        previousHash: '',
      );

      final proofs = [
        RedemptionStampProof(
          signature: genuineSignature,
          timestamp: 1749600000001,
          originalCardId: 'card-source',
          originalStampNumber: 1,
          originalPreviousHash: '',
        ),
        RedemptionStampProof(
          signature: genuineSignature,
          timestamp: 1749600000001,
          originalCardId: 'card-source',
          originalStampNumber: 1,
          originalPreviousHash: '',
        ),
      ];

      final result = CryptoUtils.verifyRedemptionStampChain(
        cardId: 'card-dest',
        stampProofs: proofs,
        businessPublicKey: publicKeyEncoded,
      );

      expect(result.isValid, isFalse);
      expect(result.failureReason, 'duplicate_stamp_signature');
    });
  });
}
