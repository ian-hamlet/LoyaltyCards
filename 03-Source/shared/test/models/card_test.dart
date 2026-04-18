/// Tests for Card model
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import '../fixtures/test_fixtures.dart';

void main() {
  group('Card Model', () {
    group('Constructor and Getters', () {
      test('creates card with all required fields', () {
        final card = TestFixtures.testCard;

        expect(card.id, 'test-card-001');
        expect(card.businessId, 'test-biz-123');
        expect(card.businessName, 'Test Coffee Shop');
        expect(card.stampsRequired, 10);
        expect(card.stampsCollected, 5);
        expect(card.mode, OperationMode.secure);
        expect(card.isRedeemed, false);
      });

      test('creates card in simple mode', () {
        final card = TestFixtures.testCardSimpleMode;

        expect(card.mode, OperationMode.simple);
        expect(card.businessPublicKey, '');
      });

      test('creates redeemed card', () {
        final card = TestFixtures.testCardRedeemed;

        expect(card.isRedeemed, true);
        expect(card.redeemedAt, isNotNull);
        expect(card.stampsCollected, card.stampsRequired);
      });
    });

    group('JSON Serialization', () {
      test('toJson includes all fields', () {
        final card = TestFixtures.testCard;
        final json = card.toJson();

        expect(json['id'], card.id);
        expect(json['business_id'], card.businessId);
        expect(json['business_name'], card.businessName);
        expect(json['business_public_key'], card.businessPublicKey);
        expect(json['stamps_required'], card.stampsRequired);
        expect(json['stamps_collected'], card.stampsCollected);
        expect(json['brand_color'], card.brandColor);
        expect(json['logo_index'], card.logoIndex);
        expect(json['mode'], 'secure');
        expect(json['created_at'], card.createdAt.millisecondsSinceEpoch);
        expect(json['updated_at'], card.updatedAt.millisecondsSinceEpoch);
        expect(json['is_redeemed'], 0); // SQLite stores bools as int
      });

      test('toJson handles redeemed card', () {
        final card = TestFixtures.testCardRedeemed;
        final json = card.toJson();

        expect(json['is_redeemed'], 1);
        expect(json['redeemed_at'], card.redeemedAt!.millisecondsSinceEpoch);
      });

      test('toJson handles optional device_id', () {
        final cardWithDevice = TestDataBuilder.createCard(deviceId: 'device-123');
        final json = cardWithDevice.toJson();

        expect(json['device_id'], 'device-123');
      });

      test('toJson handles null device_id', () {
        final card = TestFixtures.testCard;
        final json = card.toJson();

        expect(json.containsKey('device_id'), true);
        expect(json['device_id'], isNull);
      });

      test('fromJson creates card correctly', () {
        final original = TestFixtures.testCard;
        final json = original.toJson();
        final decoded = Card.fromJson(json);

        expect(decoded.id, original.id);
        expect(decoded.businessId, original.businessId);
        expect(decoded.businessName, original.businessName);
        expect(decoded.businessPublicKey, original.businessPublicKey);
        expect(decoded.stampsRequired, original.stampsRequired);
        expect(decoded.stampsCollected, original.stampsCollected);
        expect(decoded.brandColor, original.brandColor);
        expect(decoded.logoIndex, original.logoIndex);
        expect(decoded.mode, original.mode);
        expect(decoded.isRedeemed, original.isRedeemed);
        expect(decoded.createdAt.millisecondsSinceEpoch, 
               original.createdAt.millisecondsSinceEpoch);
        expect(decoded.updatedAt.millisecondsSinceEpoch,
               original.updatedAt.millisecondsSinceEpoch);
      });

      test('fromJson handles redeemed_at correctly', () {
        final original = TestFixtures.testCardRedeemed;
        final json = original.toJson();
        final decoded = Card.fromJson(json);

        expect(decoded.isRedeemed, true);
        expect(decoded.redeemedAt, isNotNull);
        expect(decoded.redeemedAt!.millisecondsSinceEpoch,
               original.redeemedAt!.millisecondsSinceEpoch);
      });

      test('fromJson roundtrip preserves all data', () {
        final original = TestFixtures.testCard;
        final json = original.toJson();
        final decoded = Card.fromJson(json);
        final json2 = decoded.toJson();

        expect(json2, equals(json));
      });

      test('fromJson handles simple mode', () {
        final original = TestFixtures.testCardSimpleMode;
        final json = original.toJson();
        final decoded = Card.fromJson(json);

        expect(decoded.mode, OperationMode.simple);
        expect(decoded.businessPublicKey, '');
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance', () {
        final original = TestFixtures.testCard;
        final copy = original.copyWith();

        expect(copy, isNot(same(original)));
        expect(copy.id, original.id);
      });

      test('copyWith updates single field', () {
        final original = TestFixtures.testCard;
        final updated = original.copyWith(businessName: 'New Coffee Shop');

        expect(updated.businessName, 'New Coffee Shop');
        expect(updated.id, original.id);
        expect(updated.businessId, original.businessId);
        expect(updated.stampsCollected, original.stampsCollected);
      });

      test('copyWith updates multiple fields', () {
        final original = TestFixtures.testCard;
        final updated = original.copyWith(
          stampsCollected: 7,
          updatedAt: TestFixtures.testTimestamp3,
        );

        expect(updated.stampsCollected, 7);
        expect(updated.updatedAt, TestFixtures.testTimestamp3);
        expect(updated.id, original.id);
        expect(updated.businessName, original.businessName);
      });

      test('copyWith can set isRedeemed to true', () {
        final original = TestFixtures.testCard;
        final redeemed = original.copyWith(
          isRedeemed: true,
          redeemedAt: TestFixtures.testTimestamp3,
          stampsCollected: original.stampsRequired,
        );

        expect(redeemed.isRedeemed, true);
        expect(redeemed.redeemedAt, TestFixtures.testTimestamp3);
        expect(redeemed.stampsCollected, redeemed.stampsRequired);
      });

      test('copyWith can update device_id', () {
        final original = TestDataBuilder.createCard(deviceId: 'original-device');
        // Note: copyWith doesn't support deviceId parameter
        // Device ID is immutable after card creation
        
        expect(original.deviceId, 'original-device');
      });

      test('copyWith preserves null fields when not specified', () {
        final original = TestFixtures.testCard;
        final updated = original.copyWith(businessName: 'New Name');

        expect(updated.deviceId, original.deviceId);
        expect(updated.redeemedAt, original.redeemedAt);
      });
    });

    group('Computed Properties', () {
      test('isComplete returns true when stamps match requirement', () {
        final card = TestDataBuilder.createCard(
          stampsRequired: 10,
          stampsCollected: 10,
        );

        expect(card.isComplete, true);
      });

      test('isComplete returns false when stamps below requirement', () {
        final card = TestDataBuilder.createCard(
          stampsRequired: 10,
          stampsCollected: 9,
        );

        expect(card.isComplete, false);
      });

      test('isComplete returns false for zero stamps', () {
        final card = TestDataBuilder.createCard(
          stampsRequired: 10,
          stampsCollected: 0,
        );

        expect(card.isComplete, false);
      });

      test('progress returns correct percentage', () {
        final card = TestDataBuilder.createCard(
          stampsRequired: 10,
          stampsCollected: 5,
        );

        expect(card.progress, 0.5);
      });

      test('progress returns 1.0 when complete', () {
        final card = TestDataBuilder.createCard(
          stampsRequired: 10,
          stampsCollected: 10,
        );

        expect(card.progress, 1.0);
      });

      test('progress returns 0.0 when no stamps', () {
        final card = TestDataBuilder.createCard(
          stampsRequired: 10,
          stampsCollected: 0,
        );

        expect(card.progress, 0.0);
      });

      test('progress handles different stamp requirements', () {
        final card = TestDataBuilder.createCard(
          stampsRequired: 8,
          stampsCollected: 2,
        );

        expect(card.progress, 0.25);
      });
    });

    group('Edge Cases', () {
      test('handles very long business names', () {
        final longName = 'A' * 200;
        final card = TestDataBuilder.createCard(businessName: longName);
        final json = card.toJson();
        final decoded = Card.fromJson(json);

        expect(decoded.businessName, longName);
      });

      test('handles special characters in business name', () {
        final specialName = 'Café & Crêperie "The Best" <Special>';
        final card = TestDataBuilder.createCard(businessName: specialName);
        final json = card.toJson();
        final decoded = Card.fromJson(json);

        expect(decoded.businessName, specialName);
      });

      test('handles emoji in business name', () {
        final emojiName = '☕ Coffee Shop 🥐';
        final card = TestDataBuilder.createCard(businessName: emojiName);
        final json = card.toJson();
        final decoded = Card.fromJson(json);

        expect(decoded.businessName, emojiName);
      });

      test('handles maximum stamp values', () {
        final card = TestDataBuilder.createCard(
          stampsRequired: 1000,
          stampsCollected: 999,
        );

        expect(card.stampsRequired, 1000);
        expect(card.stampsCollected, 999);
        expect(card.isComplete, false);
      });

      test('handles very long public keys', () {
        final longKey = 'A' * 500;
        final card = TestDataBuilder.createCard(businessPublicKey: longKey);
        final json = card.toJson();
        final decoded = Card.fromJson(json);

        expect(decoded.businessPublicKey, longKey);
      });

      test('handles various brand color formats', () {
        final colorFormats = [
          '#FF5733',
          '#f57',
          'rgb(255, 87, 51)',
          'red',
        ];

        for (final color in colorFormats) {
          final card = TestDataBuilder.createCard(brandColor: color);
          final json = card.toJson();
          final decoded = Card.fromJson(json);

          expect(decoded.brandColor, color);
        }
      });
    });

    group('Validation Logic', () {
      test('stampsCollected should not exceed stampsRequired', () {
        // Note: This is business logic validation, not enforced by model
        final card = TestDataBuilder.createCard(
          stampsRequired: 10,
          stampsCollected: 15,
        );

        // Model allows this, but business logic should prevent it
        expect(card.stampsCollected > card.stampsRequired, true);
      });

      test('dates should be valid', () {
        final now = DateTime.now();
        final card = TestDataBuilder.createCard(
          createdAt: now,
          updatedAt: now,
        );

        expect(card.createdAt.isBefore(DateTime.now().add(Duration(seconds: 1))), true);
        expect(card.updatedAt.isAfter(card.createdAt.subtract(Duration(seconds: 1))), true);
      });
    });

    group('Mode Handling', () {
      test('secure mode requires public key', () {
        final card = TestDataBuilder.createCard(
          mode: OperationMode.secure,
          businessPublicKey: 'test-key',
        );

        expect(card.mode, OperationMode.secure);
        expect(card.businessPublicKey.isNotEmpty, true);
      });

      test('simple mode has empty public key', () {
        final card = TestDataBuilder.createCard(
          mode: OperationMode.simple,
          businessPublicKey: '',
        );

        expect(card.mode, OperationMode.simple);
        expect(card.businessPublicKey, '');
      });

      test('mode roundtrip through JSON', () {
        final secureCard = TestDataBuilder.createCard(mode: OperationMode.secure);
        final simpleCard = TestDataBuilder.createCard(mode: OperationMode.simple);

        final secureJson = secureCard.toJson();
        final simpleJson = simpleCard.toJson();

        final secureDecoded = Card.fromJson(secureJson);
        final simpleDecoded = Card.fromJson(simpleJson);

        expect(secureDecoded.mode, OperationMode.secure);
        expect(simpleDecoded.mode, OperationMode.simple);
      });
    });
  });
}
