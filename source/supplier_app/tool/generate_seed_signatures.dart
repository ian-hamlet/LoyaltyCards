// Dev tool: generates genuinely valid ECDSA key pairs and stamp-chain
// signatures for the Secure Mode test cards in scripts/seed_customer_*.sh.
//
// Those scripts insert stamp rows directly via sqlite3, bypassing the real
// signing flow, so they previously used placeholder strings ('sig-test',
// 'pubkey-test-00X'). That was fine until V-012 (2026-07-25) wired up real
// redemption-chain verification (CryptoUtils.verifyRedemptionStampChain) -
// placeholder signatures now fail that check. This tool produces real
// signatures matching the exact production format so seeded Secure Mode
// cards can still be redeemed in the seeded test environment.
//
// Deliberately reimplements (rather than imports) KeyManager's key
// generation/signing/encoding: importing key_manager.dart pulls in
// flutter_secure_storage, which crashes plain `dart run`'s ffi-transform
// step. The logic below is copied verbatim from
// supplier_app/lib/services/key_manager.dart - keep both in sync.
//
// Run from source/supplier_app/:
//   dart run tool/generate_seed_signatures.dart
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

SecureRandom _getSecureRandom() {
  final random = FortunaRandom();
  final seedSource = Random.secure();
  final seeds = List<int>.generate(32, (_) => seedSource.nextInt(256));
  random.seed(KeyParameter(Uint8List.fromList(seeds)));
  return random;
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

AsymmetricKeyPair<PublicKey, PrivateKey> generateKeyPair() {
  final keyParams = ECKeyGeneratorParameters(ECCurve_secp256r1());
  final random = _getSecureRandom();
  final generator = ECKeyGenerator()..init(ParametersWithRandom(keyParams, random));
  return generator.generateKeyPair();
}

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

String signData(String data, ECPrivateKey privateKey) {
  final signer = ECDSASigner(SHA256Digest());
  final params = ParametersWithRandom(
    PrivateKeyParameter<ECPrivateKey>(privateKey),
    _getSecureRandom(),
  );
  signer.init(true, params);

  final dataBytes = utf8.encode(data);
  final signature = signer.generateSignature(Uint8List.fromList(dataBytes)) as ECSignature;

  final rBytes = _bigIntToBytes(signature.r);
  final sBytes = _bigIntToBytes(signature.s);

  final combined = <int>[];
  combined.addAll(_encodeLength(rBytes.length));
  combined.addAll(rBytes);
  combined.addAll(_encodeLength(sBytes.length));
  combined.addAll(sBytes);

  return base64Encode(combined);
}

// Mirrors CryptoUtils.verifyRedemptionStampChain's reconstruction:
// '$cardId:$stampNumber:$timestamp:$previousHash:1::' with previousHash
// starting at '' and becoming each prior stamp's own signature.
void generateForCard(String label, String cardId, List<int> timestamps) {
  final keyPair = generateKeyPair();
  final publicKey = keyPair.publicKey as ECPublicKey;
  final privateKey = keyPair.privateKey as ECPrivateKey;
  final encodedPublicKey = encodePublicKey(publicKey);

  print('-- $label ($cardId) --');
  print('business_public_key: $encodedPublicKey');
  print('');

  String previousHash = '';
  for (var i = 0; i < timestamps.length; i++) {
    final stampNumber = i + 1;
    final ts = timestamps[i];
    final data = '$cardId:$stampNumber:$ts:$previousHash:1::';
    final sig = signData(data, privateKey);
    final prevSqlValue = previousHash.isEmpty ? 'NULL' : "'$previousHash'";
    print("('stamp-${cardId.substring(5)}-$stampNumber', '$cardId', $stampNumber, $ts, '$sig', $prevSqlValue, DEVICE_ID),");
    previousHash = sig;
  }
  print('');
}

void main() {
  generateForCard('Metro Deli', 'card-003', [
    1749600201000,
    1749600202000,
    1749600203000,
    1749600204000,
  ]);

  generateForCard('Zen Spa', 'card-005', [
    1749600401000,
    1749600402000,
    1749600403000,
    1749600404000,
    1749600405000,
    1749600406000,
    1749600407000,
    1749600408000,
  ]);
}
