/// Tests for Stamp model
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import '../fixtures/test_fixtures.dart';

void main() {
  group('Stamp Model', () {
    group('Constructor and Getters', () {
      test('creates stamp with all required fields', () {
        final stamp = TestFixtures.testStamp1;

        expect(stamp.id, 'test-stamp-001');
        expect(stamp.cardId, 'test-card-001');
        expect(stamp.stampNumber, 1);
        expect(stamp.timestamp, TestFixtures.testTimestamp1);
        expect(stamp.signature, 'test-signature-1');
        expect(stamp.previousHash, isNull);
      });

      test('creates stamp with previous hash', () {
        final stamp = TestFixtures.testStamp2;

        expect(stamp.stampNumber, 2);
        expect(stamp.previousHash, 'hash-of-stamp-1');
      });

      test('creates stamp with device ID', () {
        final stamp = TestDataBuilder.createStamp(deviceId: 'device-123');

        expect(stamp.deviceId, 'device-123');
      });
    });

    group('JSON Serialization', () {
      test('toJson includes all required fields', () {
        final stamp = TestFixtures.testStamp1;
        final json = stamp.toJson();

        expect(json['id'], stamp.id);
        expect(json['card_id'], stamp.cardId);
        expect(json['stamp_number'], stamp.stampNumber);
        expect(json['timestamp'], stamp.timestamp.millisecondsSinceEpoch);
        expect(json['signature'], stamp.signature);
      });

      test('toJson includes previous_hash when present', () {
        final stamp = TestFixtures.testStamp2;
        final json = stamp.toJson();

        expect(json['previous_hash'], 'hash-of-stamp-1');
      });

      test('toJson handles null previous_hash', () {
        final stamp = TestFixtures.testStamp1;
        final json = stamp.toJson();

        expect(json.containsKey('previous_hash'), true);
        expect(json['previous_hash'], isNull);
      });

      test('toJson includes device_id when present', () {
        final stamp = TestDataBuilder.createStamp(deviceId: 'device-456');
        final json = stamp.toJson();

        expect(json['device_id'], 'device-456');
      });

      test('fromJson creates stamp correctly', () {
        final original = TestFixtures.testStamp2;
        final json = original.toJson();
        final decoded = Stamp.fromJson(json);

        expect(decoded.id, original.id);
        expect(decoded.cardId, original.cardId);
        expect(decoded.stampNumber, original.stampNumber);
        expect(decoded.timestamp.millisecondsSinceEpoch,
               original.timestamp.millisecondsSinceEpoch);
        expect(decoded.signature, original.signature);
        expect(decoded.previousHash, original.previousHash);
      });

      test('fromJson roundtrip preserves all data', () {
        final original = TestFixtures.testStamp2;
        final json = original.toJson();
        final decoded = Stamp.fromJson(json);
        final json2 = decoded.toJson();

        expect(json2, equals(json));
      });

      test('fromJson handles null previous_hash', () {
        final original = TestFixtures.testStamp1;
        final json = original.toJson();
        final decoded = Stamp.fromJson(json);

        expect(decoded.previousHash, isNull);
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance', () {
        final original = TestFixtures.testStamp1;
        final copy = original.copyWith();

        expect(copy, isNot(same(original)));
        expect(copy.id, original.id);
      });

      test('copyWith updates single field', () {
        final original = TestFixtures.testStamp1;
        final updated = original.copyWith(signature: 'new-signature');

        expect(updated.signature, 'new-signature');
        expect(updated.id, original.id);
        expect(updated.stampNumber, original.stampNumber);
      });

      test('copyWith updates multiple fields', () {
        final original = TestFixtures.testStamp1;
        final newTime = DateTime.now();
        final updated = original.copyWith(
          timestamp: newTime,
          previousHash: 'new-hash',
        );

        expect(updated.timestamp, newTime);
        expect(updated.previousHash, 'new-hash');
        expect(updated.id, original.id);
      });

      test('copyWith can update device_id', () {
        final original = TestFixtures.testStamp1;
        final updated = original.copyWith(deviceId: 'new-device');

        expect(updated.deviceId, 'new-device');
      });
    });

    group('Stamp Chain Logic', () {
      test('first stamp has no previous hash', () {
        final stamp = TestFixtures.testStamp1;

        expect(stamp.stampNumber, 1);
        expect(stamp.previousHash, isNull);
      });

      test('subsequent stamps have previous hash', () {
        final stamps = TestFixtures.testStampChain;

        expect(stamps[0].previousHash, isNull);
        expect(stamps[1].previousHash, isNotNull);
        expect(stamps[2].previousHash, isNotNull);
      });

      test('stamp numbers increment correctly', () {
        final stamps = TestFixtures.testStampChain;

        expect(stamps[0].stampNumber, 1);
        expect(stamps[1].stampNumber, 2);
        expect(stamps[2].stampNumber, 3);
      });

      test('timestamps should be chronological', () {
        final stamps = TestFixtures.testStampChain;

        expect(stamps[0].timestamp.isBefore(stamps[1].timestamp), true);
        expect(stamps[1].timestamp.isBefore(stamps[2].timestamp), true);
      });
    });

    group('Edge Cases', () {
      test('handles very long signatures', () {
        final longSig = 'A' * 500;
        final stamp = TestDataBuilder.createStamp(signature: longSig);
        final json = stamp.toJson();
        final decoded = Stamp.fromJson(json);

        expect(decoded.signature, longSig);
      });

      test('handles very long hashes', () {
        final longHash = 'B' * 256;
        final stamp = TestDataBuilder.createStamp(previousHash: longHash);
        final json = stamp.toJson();
        final decoded = Stamp.fromJson(json);

        expect(decoded.previousHash, longHash);
      });

      test('handles high stamp numbers', () {
        final stamp = TestDataBuilder.createStamp(stampNumber: 9999);

        expect(stamp.stampNumber, 9999);
      });

      test('handles various ID formats', () {
        final uuidStamp = TestDataBuilder.createStamp(
          id: '123e4567-e89b-12d3-a456-426614174000',
        );
        final json = uuidStamp.toJson();
        final decoded = Stamp.fromJson(json);

        expect(decoded.id, uuidStamp.id);
      });

      test('preserves timestamp precision', () {
        final now = DateTime.now();
        final stamp = TestDataBuilder.createStamp(timestamp: now);
        final json = stamp.toJson();
        final decoded = Stamp.fromJson(json);

        expect(decoded.timestamp.millisecondsSinceEpoch,
               now.millisecondsSinceEpoch);
      });
    });
  });
}
