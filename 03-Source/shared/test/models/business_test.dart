/// Tests for Business model
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import '../fixtures/test_fixtures.dart';

void main() {
  group('Business Model', () {
    group('Constructor and Getters', () {
      test('creates business with all required fields', () {
        final business = TestFixtures.testBusiness;

        expect(business.id, 'test-biz-123');
        expect(business.name, 'Test Coffee Shop');
        expect(business.stampsRequired, 10);
        expect(business.brandColor, '#FF5733');
        expect(business.logoIndex, 0);
      });

      test('creates business with different logo', () {
        final business = TestFixtures.testBusiness2;

        expect(business.logoIndex, 1);
      });
    });

    group('JSON Serialization', () {
      test('toJson includes all fields', () {
        final business = TestFixtures.testBusiness;
        final json = business.toJson(includePrivateKey: true);

        expect(json['id'], business.id);
        expect(json['name'], business.name);
        expect(json['public_key'], business.publicKey);
        expect(json['private_key'], business.privateKey);
        expect(json['stamps_required'], business.stampsRequired);
        expect(json['brand_color'], business.brandColor);
        expect(json['logo_index'], business.logoIndex);
      });

      test('toJson excludes private key by default', () {
        final business = TestFixtures.testBusiness;
        final json = business.toJson();

        expect(json.containsKey('private_key'), false);
        expect(json['public_key'], business.publicKey);
      });

      test('fromJson creates business correctly', () {
        final original = TestFixtures.testBusiness;
        final json = original.toJson(includePrivateKey: true);
        final decoded = Business.fromJson(json);

        expect(decoded.id, original.id);
        expect(decoded.name, original.name);
        expect(decoded.publicKey, original.publicKey);
        expect(decoded.privateKey, original.privateKey);
        expect(decoded.stampsRequired, original.stampsRequired);
        expect(decoded.brandColor, original.brandColor);
        expect(decoded.logoIndex, original.logoIndex);
      });

      test('fromJson roundtrip preserves all data', () {
        final original = TestFixtures.testBusiness;
        final json = original.toJson(includePrivateKey: true);
        final decoded = Business.fromJson(json);
        final json2 = decoded.toJson(includePrivateKey: true);

        expect(json2, equals(json));
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance', () {
        final original = TestFixtures.testBusiness;
        final copy = original.copyWith();

        expect(copy, isNot(same(original)));
        expect(copy.id, original.id);
      });

      test('copyWith updates single field', () {
        final original = TestFixtures.testBusiness;
        final updated = original.copyWith(name: 'New Coffee Shop');

        expect(updated.name, 'New Coffee Shop');
        expect(updated.id, original.id);
        expect(updated.stampsRequired, original.stampsRequired);
      });

      test('copyWith updates multiple fields', () {
        final original = TestFixtures.testBusiness;
        final updated = original.copyWith(
          stampsRequired: 15,
          brandColor: '#123456',
        );

        expect(updated.stampsRequired, 15);
        expect(updated.brandColor, '#123456');
        expect(updated.id, original.id);
      });

      test('copyWith can update logo', () {
        final original = TestFixtures.testBusiness;
        final updated = original.copyWith(logoIndex: 5);

        expect(updated.logoIndex, 5);
        expect(updated.id, original.id);
      });
    });

    group('Edge Cases', () {
      test('handles very long business names', () {
        final longName = 'A' * 200;
        final business = TestDataBuilder.createBusiness(name: longName);
        final json = business.toJson();
        final decoded = Business.fromJson(json);

        expect(decoded.name, longName);
      });

      test('handles special characters in name', () {
        final specialName = 'Café & Crêperie "The Best" <Special>';
        final business = TestDataBuilder.createBusiness(name: specialName);
        final json = business.toJson();
        final decoded = Business.fromJson(json);

        expect(decoded.name, specialName);
      });

      test('handles emoji in name', () {
        final emojiName = '☕ Coffee Shop 🥐';
        final business = TestDataBuilder.createBusiness(name: emojiName);
        final json = business.toJson();
        final decoded = Business.fromJson(json);

        expect(decoded.name, emojiName);
      });

      test('handles minimum stamp requirement', () {
        final business = TestDataBuilder.createBusiness(stampsRequired: 1);
        expect(business.stampsRequired, 1);
      });

      test('handles maximum stamp requirement', () {
        final business = TestDataBuilder.createBusiness(stampsRequired: 1000);
        expect(business.stampsRequired, 1000);
      });

      test('handles various brand color formats', () {
        final colors = ['#FF5733', '#f57', 'rgb(255,87,51)', 'red'];
        for (final color in colors) {
          final business = TestDataBuilder.createBusiness(brandColor: color);
          final json = business.toJson();
          final decoded = Business.fromJson(json);
          expect(decoded.brandColor, color);
        }
      });

      test('handles various logo indexes', () {
        for (var i = 0; i < 10; i++) {
          final business = TestDataBuilder.createBusiness(logoIndex: i);
          final json = business.toJson();
          final decoded = Business.fromJson(json);
          expect(decoded.logoIndex, i);
        }
      });
    });

    group('REQ-022: Scan Interval Support', () {
      test('creates business with default scan interval', () {
        final business = Business(
          id: 'test-123',
          name: 'Test Business',
          publicKey: 'key',
          privateKey: 'private',
          stampsRequired: 10,
          brandColor: '#FF5733',
          createdAt: DateTime.now(),
        );

        expect(business.scanInterval, 30000); // Default 30 seconds in ms
      });

      test('creates business with custom scan interval', () {
        final business = Business(
          id: 'test-123',
          name: 'Test Business',
          publicKey: 'key',
          privateKey: 'private',
          stampsRequired: 10,
          brandColor: '#FF5733',
          createdAt: DateTime.now(),
          scanInterval: 60000, // 60 seconds
        );

        expect(business.scanInterval, 60000);
      });

      test('toJson converts scan interval to seconds', () {
        final business = Business(
          id: 'test-123',
          name: 'Test Business',
          publicKey: 'key',
          privateKey: 'private',
          stampsRequired: 10,
          brandColor: '#FF5733',
          createdAt: DateTime.now(),
          scanInterval: 45000, // 45 seconds in ms
        );

        final json = business.toJson();
        expect(json['scan_interval_seconds'], 45); // Stored as seconds
      });

      test('fromJson converts seconds back to milliseconds', () {
        final json = {
          'id': 'test-123',
          'name': 'Test Business',
          'public_key': 'key',
          'private_key': 'private',
          'stamps_required': 10,
          'brand_color': '#FF5733',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'scan_interval_seconds': 20, // 20 seconds
        };

        final business = Business.fromJson(json);
        expect(business.scanInterval, 20000); // Converted to ms
      });

      test('fromJson handles missing scan_interval_seconds (backward compatibility)', () {
        final json = {
          'id': 'test-123',
          'name': 'Test Business',
          'public_key': 'key',
          'private_key': 'private',
          'stamps_required': 10,
          'brand_color': '#FF5733',
          'created_at': DateTime.now().millisecondsSinceEpoch,
          // No scan_interval_seconds
        };

        final business = Business.fromJson(json);
        expect(business.scanInterval, 30000); // Default 30 seconds
      });

      test('copyWith updates scan interval', () {
        final original = Business(
          id: 'test-123',
          name: 'Test Business',
          publicKey: 'key',
          privateKey: 'private',
          stampsRequired: 10,
          brandColor: '#FF5733',
          createdAt: DateTime.now(),
          scanInterval: 30000,
        );

        final updated = original.copyWith(scanInterval: 15000);
        
        expect(updated.scanInterval, 15000);
        expect(original.scanInterval, 30000); // Original unchanged
      });

      test('roundtrip preserves scan interval', () {
        final original = Business(
          id: 'test-123',
          name: 'Test Business',
          publicKey: 'key',
          privateKey: 'private',
          stampsRequired: 10,
          brandColor: '#FF5733',
          createdAt: DateTime.now(),
          scanInterval: 55000, // 55 seconds
        );

        final json = original.toJson(includePrivateKey: true);
        final decoded = Business.fromJson(json);

        expect(decoded.scanInterval, 55000);
      });

      test('handles minimum scan interval (5 seconds)', () {
        final business = Business(
          id: 'test-123',
          name: 'Test Business',
          publicKey: 'key',
          privateKey: 'private',
          stampsRequired: 10,
          brandColor: '#FF5733',
          createdAt: DateTime.now(),
          scanInterval: 5000,
        );

        expect(business.scanInterval, 5000);
        
        final json = business.toJson();
        final decoded = Business.fromJson(json);
        expect(decoded.scanInterval, 5000);
      });

      test('handles maximum scan interval (60 seconds)', () {
        final business = Business(
          id: 'test-123',
          name: 'Test Business',
          publicKey: 'key',
          privateKey: 'private',
          stampsRequired: 10,
          brandColor: '#FF5733',
          createdAt: DateTime.now(),
          scanInterval: 60000,
        );

        expect(business.scanInterval, 60000);
        
        final json = business.toJson();
        final decoded = Business.fromJson(json);
        expect(decoded.scanInterval, 60000);
      });
    });
  });
}
