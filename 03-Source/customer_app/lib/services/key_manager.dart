import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

/// Service for verifying cryptographic signatures
/// Customer app only needs verification, not signing
class KeyManager {
  /// Verify signature with public key using ECDSA
  static bool verifySignature(String data, String signatureBase64, String publicKeyEncoded) {
    try {
      final publicKey = _decodePublicKey(publicKeyEncoded);
      if (publicKey == null) return false;

      final signer = ECDSASigner(SHA256Digest());
      signer.init(false, PublicKeyParameter<ECPublicKey>(publicKey));

      final dataBytes = utf8.encode(data);
      final signatureBytes = base64Decode(signatureBase64);

      // Decode signature
      var offset = 0;
      final rLength = _decodeLength(signatureBytes, offset);
      offset += 4;
      final rBytes = signatureBytes.sublist(offset, offset + rLength);
      offset += rLength;
      
      final sLength = _decodeLength(signatureBytes, offset);
      offset += 4;
      final sBytes = signatureBytes.sublist(offset, offset + sLength);

      final r = BigInt.parse(rBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      final s = BigInt.parse(sBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);

      final signature = ECSignature(r, s);

      return signer.verifySignature(Uint8List.fromList(dataBytes), signature);
    } catch (e) {
      return false;
    }
  }

  /// Decode public key from base64 string
  static ECPublicKey? _decodePublicKey(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      
      var offset = 0;
      final xLength = _decodeLength(bytes, offset);
      offset += 4;
      final xBytes = bytes.sublist(offset, offset + xLength);
      offset += xLength;
      
      final yLength = _decodeLength(bytes, offset);
      offset += 4;
      final yBytes = bytes.sublist(offset, offset + yLength);
      
      final x = BigInt.parse(xBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      final y = BigInt.parse(yBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      
      final params = ECCurve_secp256r1();
      final q = params.curve.createPoint(x, y);
      
      return ECPublicKey(q, params);
    } catch (e) {
      return null;
    }
  }

  static int _decodeLength(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}
