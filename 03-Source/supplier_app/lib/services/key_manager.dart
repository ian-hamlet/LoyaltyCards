import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing cryptographic keys and signing operations
/// Uses ECDSA (Elliptic Curve Digital Signature Algorithm) with secp256r1 curve
class KeyManager {
  static final KeyManager _instance = KeyManager._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  factory KeyManager() => _instance;

  KeyManager._internal();

  // Storage keys
  static const String _privateKeyPrefix = 'business_private_key_';
  static const String _publicKeyPrefix = 'business_public_key_';

  /// Generate a new ECDSA key pair using secp256r1 (P-256) curve
  Future<AsymmetricKeyPair<PublicKey, PrivateKey>> generateKeyPair() async {
    print('KeyManager: Generating ECDSA P-256 key pair...');
    final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
    final random = FortunaRandom();
    
    // Seed the random number generator
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    final generator = ECKeyGenerator()
      ..init(ParametersWithRandom(keyParams, random));

    final keyPair = generator.generateKeyPair();
    print('KeyManager: Key pair generated (P-256 curve)');
    return keyPair;
  }

  /// Store private key securely in device keychain/keystore
  Future<void> storePrivateKey(String businessId, ECPrivateKey privateKey) async {
    print('KeyManager: Storing private key for business: $businessId');
    final keyBytes = _bigIntToBytes(privateKey.d!);
    final keyBase64 = base64Encode(keyBytes);
    
    await _storage.write(
      key: '$_privateKeyPrefix$businessId',
      value: keyBase64,
    );
    print('KeyManager: Private key stored securely in keychain');
  }

  /// Store public key (can be stored less securely as it's meant to be shared)
  Future<void> storePublicKey(String businessId, ECPublicKey publicKey) async {
    print('KeyManager: Storing public key for business: $businessId');
    final encoded = _encodePublicKey(publicKey);
    
    await _storage.write(
      key: '$_publicKeyPrefix$businessId',
      value: encoded,
    );
    print('KeyManager: Public key stored (${encoded.length} chars)');
  }

  /// Retrieve private key from secure storage
  Future<ECPrivateKey?> getPrivateKey(String businessId) async {
    final keyBase64 = await _storage.read(key: '$_privateKeyPrefix$businessId');
    
    if (keyBase64 == null) return null;

    final keyBytes = base64Decode(keyBase64);
    final d = BigInt.parse(keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
    
    final params = ECCurve_secp256r1();
    return ECPrivateKey(d, params);
  }

  /// Retrieve public key from storage
  Future<ECPublicKey?> getPublicKey(String businessId) async {
    final encoded = await _storage.read(key: '$_publicKeyPrefix$businessId');
    
    if (encoded == null) return null;

    return _decodePublicKey(encoded);
  }

  /// Retrieve public key as encoded string for sharing/transmission
  Future<String?> getPublicKeyString(String businessId) async {
    final encoded = await _storage.read(key: '$_publicKeyPrefix$businessId');
    return encoded;
  }

  /// Sign data with private key using ECDSA
  Future<String> signData(String data, ECPrivateKey privateKey) async {
    final signer = ECDSASigner(SHA256Digest());
    final params = ParametersWithRandom(
      PrivateKeyParameter<ECPrivateKey>(privateKey),
      _getSecureRandom(),
    );
    
    signer.init(true, params);

    final dataBytes = utf8.encode(data);
    final signature = signer.generateSignature(Uint8List.fromList(dataBytes)) as ECSignature;

    // Encode signature as base64
    final rBytes = _bigIntToBytes(signature.r);
    final sBytes = _bigIntToBytes(signature.s);
    
    final combined = <int>[];
    combined.addAll(_encodeLength(rBytes.length));
    combined.addAll(rBytes);
    combined.addAll(_encodeLength(sBytes.length));
    combined.addAll(sBytes);

    return base64Encode(combined);
  }

  /// Verify signature with public key
  static bool verifySignature(String data, String signatureBase64, String publicKeyEncoded) {
    try {
      final publicKey = KeyManager()._decodePublicKey(publicKeyEncoded);
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

  /// Check if keys exist for a business
  Future<bool> hasKeys(String businessId) async {
    final privateKey = await _storage.read(key: '$_privateKeyPrefix$businessId');
    final publicKey = await _storage.read(key: '$_publicKeyPrefix$businessId');
    return privateKey != null && publicKey != null;
  }

  /// Delete keys for a business
  Future<void> deleteKeys(String businessId) async {
    print('KeyManager: Deleting cryptographic keys for business: $businessId');
    await _storage.delete(key: '$_privateKeyPrefix$businessId');
    await _storage.delete(key: '$_publicKeyPrefix$businessId');
    print('KeyManager: Private and public keys deleted');
  }

  /// Encode public key to base64 string for storage/transmission
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

  /// Decode public key from base64 string
  ECPublicKey? _decodePublicKey(String encoded) {
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

  // Helper methods
  List<int> _encodeLength(int length) {
    return [
      (length >> 24) & 0xFF,
      (length >> 16) & 0xFF,
      (length >> 8) & 0xFF,
      length & 0xFF,
    ];
  }

  static int _decodeLength(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  SecureRandom _getSecureRandom() {
    final random = FortunaRandom();
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seeds)));
    return random;
  }

  // Helper to convert BigInt to bytes
  List<int> _bigIntToBytes(BigInt number) {
    final hex = number.toRadixString(16);
    final padded = hex.length.isOdd ? '0$hex' : hex;
    final bytes = <int>[];
    for (int i = 0; i < padded.length; i += 2) {
      bytes.add(int.parse(padded.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}
