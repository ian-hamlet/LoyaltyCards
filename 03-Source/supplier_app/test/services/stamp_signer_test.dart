import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:supplier_app/services/stamp_signer.dart';
import 'package:supplier_app/services/key_manager.dart';
import 'package:shared/shared.dart';
import 'package:pointycastle/export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StampSigner Cryptographic Tests', () {
    StampSigner stampSigner = StampSigner();
    KeyManager keyManager = KeyManager();

    setUp() {
      stampSigner = StampSigner();
      keyManager = KeyManager();
    }

    test('stamp hash is deterministic', () {
      final timestamp = DateTime.now();
      
      final stamp1 = Stamp(
        id: 'stamp-1',
        cardId: 'card-1',
        stampNumber: 1,
        timestamp: timestamp,
        signature: 'test-signature',
        previousHash: null,
      );

      final hash1 = stampSigner.calculateStampHash(stamp1);
      final hash2 = stampSigner.calculateStampHash(stamp1);

      expect(hash1, equals(hash2), reason: 'Hash should be deterministic');
      expect(hash1.length, equals(64), reason: 'SHA-256 produces 64 hex chars');
    });

    test('stamp hash changes with different data', () {
      final timestamp = DateTime.now();
      
      final stamp1 = Stamp(
        id: 'stamp-1',
        cardId: 'card-1',
        stampNumber: 1,
        timestamp: timestamp,
        signature: 'signature-1',
      );

      final stamp2 = Stamp(
        id: 'stamp-1',
        cardId: 'card-2', // Different card
        stampNumber: 1,
        timestamp: timestamp,
        signature: 'signature-1',
      );

      final hash1 = stampSigner.calculateStampHash(stamp1);
      final hash2 = stampSigner.calculateStampHash(stamp2);

      expect(hash1, isNot(equals(hash2)), reason: 'Different data should produce different hash');
    });

    test('stamp hash is unique for each stamp', () {
      final hashes = <String>{};
      
      for (int i = 1; i <= 10; i++) {
        final stamp = Stamp(
          id: 'stamp-$i',
          cardId: 'card-1',
          stampNumber: i,
          timestamp: DateTime.now(),
          signature: 'signature-$i',
        );
        
        final hash = stampSigner.calculateStampHash(stamp);
        hashes.add(hash);
      }

      expect(hashes.length, equals(10), reason: 'Each stamp should have unique hash');
    });

    test('key pair generation works', () async {
      final keyPair = await keyManager.generateKeyPair();
      
      expect(keyPair, isNotNull);
      expect(keyPair.privateKey, isA<ECPrivateKey>());
      expect(keyPair.publicKey, isA<ECPublicKey>());
    });

    test('public key can be encoded and decoded', () async {
      final keyPair = await keyManager.generateKeyPair();
      final publicKey = keyPair.publicKey as ECPublicKey;
      
      final encoded = keyManager.encodePublicKey(publicKey);
      
      expect(encoded, isNotEmpty);
      expect(encoded, isA<String>());
      
      // Should be base64 encoded
      expect(() => base64Decode(encoded), returnsNormally);
    });

    test('signature format uses canonical ordering', () {
      final data = SignatureFormat.stampData(
        cardId: 'card-123',
        stampNumber: 5,
        timestampMs: 1234567890,
        previousHash: 'prev-hash',
      );

      expect(data, contains('card-123'));
      expect(data, contains('5'));
      expect(data, contains('1234567890'));
      expect(data, contains('prev-hash'));
    });

    test('signature format handles null previous hash', () {
      final data = SignatureFormat.stampData(
        cardId: 'card-123',
        stampNumber: 1,
        timestampMs: 1234567890,
        previousHash: null,
      );

      expect(data, isNotEmpty);
      expect(data, contains('card-123'));
    });

    test('stamp chain validation handles empty chain', () async {
      final keyPair = await keyManager.generateKeyPair();
      final publicKey = keyPair.publicKey as ECPublicKey;
      final encodedKey = keyManager.encodePublicKey(publicKey);
      
      final isValid = await stampSigner.verifyStampChain([], encodedKey);
      
      expect(isValid, isTrue, reason: 'Empty chain should be valid');
    });

    test('stamp hash chain integrity with manual stamps', () {
      final stamp1 = Stamp(
        id: 'stamp-1',
        cardId: 'card-1',
        stampNumber: 1,
        timestamp: DateTime.now(),
        signature: 'sig-1',
        previousHash: null,
      );

      final hash1 = stampSigner.calculateStampHash(stamp1);

      final stamp2 = Stamp(
        id: 'stamp-2',
        cardId: 'card-1',
        stampNumber: 2,
        timestamp: DateTime.now(),
        signature: 'sig-2',
        previousHash: hash1, // Correctly references previous
      );

      final hash2 = stampSigner.calculateStampHash(stamp2);

      final stamp3 = Stamp(
        id: 'stamp-3',
        cardId: 'card-1',
        stampNumber: 3,
        timestamp: DateTime.now(),
        signature: 'sig-3',
        previousHash: hash2, // Correctly references previous
      );

      // Verify chain linkage
      expect(stamp2.previousHash, equals(hash1));
      expect(stamp3.previousHash, equals(hash2));
      expect(hash1, isNot(equals(hash2)));
      expect(hash2, isNot(equals(stampSigner.calculateStampHash(stamp3))));
    });

    test('different signatures for different stamp numbers', () {
      final timestamp = DateTime.now();
      
      final stamps = List.generate(5, (i) => Stamp(
        id: 'stamp-${i+1}',
        cardId: 'card-1',
        stampNumber: i + 1,
        timestamp: timestamp,
        signature: 'signature-${i+1}',
      ));

      final hashes = stamps.map((s) => stampSigner.calculateStampHash(s)).toSet();
      expect(hashes.length, equals(5), reason: 'Different stamp numbers should produce different hashes');
    });

    test('hash includes all stamp properties', () {
      final stamp = Stamp(
        id: 'stamp-1',
        cardId: 'card-1',
        stampNumber: 1,
        timestamp: DateTime(2024, 1, 1),
        signature: 'sig-1',
      );

      final hash1 = stampSigner.calculateStampHash(stamp);

      // Change each property and verify hash changes
      final stamp2 = stamp.copyWith(id: 'stamp-2');
      expect(stampSigner.calculateStampHash(stamp2), isNot(equals(hash1)));

      final stamp3 = stamp.copyWith(cardId: 'card-2');
      expect(stampSigner.calculateStampHash(stamp3), isNot(equals(hash1)));

      final stamp4 = stamp.copyWith(stampNumber: 2);
      expect(stampSigner.calculateStampHash(stamp4), isNot(equals(hash1)));

      final stamp5 = stamp.copyWith(timestamp: DateTime(2024, 1, 2));
      expect(stampSigner.calculateStampHash(stamp5), isNot(equals(hash1)));

      final stamp6 = stamp.copyWith(signature: 'sig-2');
      expect(stampSigner.calculateStampHash(stamp6), isNot(equals(hash1)));
    });
  });

  group('SignatureFormat Tests', () {
    test('stamp data format is consistent', () {
      final data1 = SignatureFormat.stampData(
        cardId: 'card-123',
        stampNumber: 5,
        timestampMs: 1234567890,
        previousHash: 'hash-abc',
      );

      final data2 = SignatureFormat.stampData(
        cardId: 'card-123',
        stampNumber: 5,
        timestampMs: 1234567890,
        previousHash: 'hash-abc',
      );

      expect(data1, equals(data2), reason: 'Same input should produce same formatted data');
    });

    test('different inputs produce different formatted data', () {
      final data1 = SignatureFormat.stampData(
        cardId: 'card-1',
        stampNumber: 1,
        timestampMs: 100,
        previousHash: null,
      );

      final data2 = SignatureFormat.stampData(
        cardId: 'card-2',
        stampNumber: 1,
        timestampMs: 100,
        previousHash: null,
      );

      expect(data1, isNot(equals(data2)));
    });
  });
}
