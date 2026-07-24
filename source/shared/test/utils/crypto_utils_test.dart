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
}
