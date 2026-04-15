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
    AppLogger.crypto('Generating ECDSA P-256 key pair');
    final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
    final random = FortunaRandom();
    
    // Seed the random number generator
    final seedSource = Random.secure();
    final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
    random.seed(KeyParameter(Uint8List.fromList(seeds)));

    final generator = ECKeyGenerator()
      ..init(ParametersWithRandom(keyParams, random));

    final keyPair = generator.generateKeyPair();
    AppLogger.crypto('Key pair generated (P-256 curve)');
    return keyPair;
  }

  /// Store private key securely in device keychain/keystore
  Future<void> storePrivateKey(String businessId, ECPrivateKey privateKey) async {
    AppLogger.crypto('Storing private key for business: $businessId');
    final keyBytes = _bigIntToBytes(privateKey.d!);
    final keyBase64 = base64Encode(keyBytes);
    
    await _storage.write(
      key: '$_privateKeyPrefix$businessId',
      value: keyBase64,
    );
    AppLogger.crypto('Private key stored securely in keychain');
  }

  /// Store public key (can be stored less securely as it's meant to be shared)
  Future<void> storePublicKey(String businessId, ECPublicKey publicKey) async {
    AppLogger.crypto('Storing public key for business: $businessId');
    final encoded = encodePublicKey(publicKey);
    
    await _storage.write(
      key: '$_publicKeyPrefix$businessId',
      value: encoded,
    );
    AppLogger.crypto('Public key stored (${encoded.length} chars)');
  }

  /// Retrieve private key from secure storage
  Future<ECPrivateKey?> getPrivateKey(String businessId) async {
    try {
      final keyBase64 = await _storage.read(key: '$_privateKeyPrefix$businessId');
      
      if (keyBase64 == null) {
        AppLogger.warning('No private key found for business: $businessId', 'Crypto');
        return null;
      }

      final keyBytes = base64Decode(keyBase64);
      final d = BigInt.parse(keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      
      final params = ECCurve_secp256r1();
      AppLogger.debug('Private key retrieved for business: $businessId', 'Crypto');
      return ECPrivateKey(d, params);
    } catch (e) {
      AppLogger.error('Failed to retrieve private key for business $businessId: $e');
      return null;
    }
  }

  /// Retrieve public key from storage
  Future<ECPublicKey?> getPublicKey(String businessId) async {
    try {
      final encoded = await _storage.read(key: '$_publicKeyPrefix$businessId');
      
      if (encoded == null) {
        AppLogger.warning('No public key found for business: $businessId', 'Crypto');
        return null;
      }

      return _decodePublicKey(encoded);
    } catch (e) {
      AppLogger.error('Failed to retrieve public key for business $businessId: $e');
      return null;
    }
  }

  /// Retrieve public key as encoded string for sharing/transmission
  Future<String?> getPublicKeyString(String businessId) async {
    final encoded = await _storage.read(key: '$_publicKeyPrefix$businessId');
    return encoded;
  }

  /// Retrieve private key as base64 string (for backup creation)
  Future<String?> getPrivateKeyString(String businessId) async {
    final keyBase64 = await _storage.read(key: '$_privateKeyPrefix$businessId');
    return keyBase64;
  }

  /// Sign data with private key using ECDSA
  Future<String?> signData(String data, ECPrivateKey privateKey) async {
    try {
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

      final signatureBase64 = base64Encode(combined);
      AppLogger.debug('Data signed successfully', 'Crypto');
      return signatureBase64;
    } catch (e) {
      AppLogger.error('Failed to sign data: $e');
      return null;
    }
  }

  /// Verify signature with public key
  /// 
  /// Delegates to shared CryptoUtils for consistency with customer app
  static bool verifySignature(String data, String signatureBase64, String publicKeyEncoded) {
    return CryptoUtils.verifySignature(
      data: data,
      signatureBase64: signatureBase64,
      publicKeyEncoded: publicKeyEncoded,
    );
  }

  /// Check if keys exist for a business
  Future<bool> hasKeys(String businessId) async {
    final privateKey = await _storage.read(key: '$_privateKeyPrefix$businessId');
    final publicKey = await _storage.read(key: '$_publicKeyPrefix$businessId');
    return privateKey != null && publicKey != null;
  }

  /// Decode private key from base64 string (for backup restore)
  ECPrivateKey? decodePrivateKey(String keyBase64) {
    try {
      final keyBytes = base64Decode(keyBase64);
      final d = BigInt.parse(keyBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      
      final params = ECCurve_secp256r1();
      AppLogger.debug('Private key decoded successfully', 'Crypto');
      return ECPrivateKey(d, params);
    } catch (e) {
      AppLogger.error('Failed to decode private key: $e');
      return null;
    }
  }

  /// Decode public key from encoded string (for backup restore)
  ECPublicKey? decodePublicKey(String encoded) {
    return _decodePublicKey(encoded);
  }

  /// Delete keys for a business
  Future<void> deleteKeys(String businessId) async {
    AppLogger.crypto('Deleting cryptographic keys for business: $businessId');
    await _storage.delete(key: '$_privateKeyPrefix$businessId');
    await _storage.delete(key: '$_publicKeyPrefix$businessId');
    AppLogger.crypto('Private and public keys deleted');
  }

  /// Encode public key to base64 string for storage/transmission
  String encodePublicKey(ECPublicKey publicKey) {
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
      
      AppLogger.debug('Public key decoded successfully (supplier)', 'Crypto');
      return ECPublicKey(q, params);
    } catch (e) {
      AppLogger.error('Failed to decode public key (supplier): $e');
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
