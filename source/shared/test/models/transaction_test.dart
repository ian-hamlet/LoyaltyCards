/// Tests for Transaction model
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import '../fixtures/test_fixtures.dart';

void main() {
  group('Transaction Model', () {
    group('Constructor and Getters', () {
      test('creates card_issued transaction', () {
        final txn = TestFixtures.testTransactionCardIssued;

        expect(txn.id, 'test-txn-001');
        expect(txn.cardId, 'test-card-001');
        expect(txn.type, TransactionType.pickup);
        expect(txn.timestamp, TestFixtures.testTimestamp1);
        expect(txn.businessName, 'Test Coffee Shop');
        expect(txn.details, contains('Card issued'));
      });

      test('creates stamp_added transaction', () {
        final txn = TestFixtures.testTransactionStampAdded;

        expect(txn.type, TransactionType.stamp);
        expect(txn.details, contains('Stamp #1'));
      });

      test('creates card_redeemed transaction', () {
        final txn = TestFixtures.testTransactionCardRedeemed;

        expect(txn.type, TransactionType.redemption);
        expect(txn.details, contains('redeemed'));
      });

      test('creates transaction with null details', () {
        final txn = TestDataBuilder.createTransaction(details: null);

        expect(txn.details, isNull);
      });
    });

    group('JSON Serialization', () {
      test('toJson includes all fields', () {
        final txn = TestFixtures.testTransactionStampAdded;
        final json = txn.toJson();

        expect(json['id'], txn.id);
        expect(json['card_id'], txn.cardId);
        expect(json['type'], txn.type.name);
        expect(json['timestamp'], txn.timestamp.millisecondsSinceEpoch);
        expect(json['business_name'], txn.businessName);
        expect(json['details'], txn.details);
      });

      test('toJson handles null details', () {
        final txn = TestDataBuilder.createTransaction(details: null);
        final json = txn.toJson();

        expect(json.containsKey('details'), true);
        expect(json['details'], isNull);
      });

      test('fromJson creates transaction correctly', () {
        final original = TestFixtures.testTransactionStampAdded;
        final json = original.toJson();
        final decoded = Transaction.fromJson(json);

        expect(decoded.id, original.id);
        expect(decoded.cardId, original.cardId);
        expect(decoded.type, original.type);
        expect(decoded.timestamp.millisecondsSinceEpoch,
               original.timestamp.millisecondsSinceEpoch);
        expect(decoded.businessName, original.businessName);
        expect(decoded.details, original.details);
      });

      test('fromJson roundtrip preserves all data', () {
        final original = TestFixtures.testTransactionStampAdded;
        final json = original.toJson();
        final decoded = Transaction.fromJson(json);
        final json2 = decoded.toJson();

        expect(json2, equals(json));
      });

      test('fromJson handles null details', () {
        final original = TestDataBuilder.createTransaction(details: null);
        final json = original.toJson();
        final decoded = Transaction.fromJson(json);

        expect(decoded.details, isNull);
      });
    });

    group('copyWith', () {
      test('copyWith creates new instance', () {
        final original = TestFixtures.testTransactionStampAdded;
        final copy = original.copyWith();

        expect(copy, isNot(same(original)));
        expect(copy.id, original.id);
      });

      test('copyWith updates single field', () {
        final original = TestFixtures.testTransactionStampAdded;
        final updated = original.copyWith(type: TransactionType.redemption);

        expect(updated.type, TransactionType.redemption);
        expect(updated.id, original.id);
        expect(updated.cardId, original.cardId);
      });

      test('copyWith updates multiple fields', () {
        final original = TestFixtures.testTransactionStampAdded;
        final newTime = DateTime.now();
        final updated = original.copyWith(
          timestamp: newTime,
          details: 'Updated details',
        );

        expect(updated.timestamp, newTime);
        expect(updated.details, 'Updated details');
        expect(updated.id, original.id);
      });

      test('copyWith preserves details when null passed', () {
        final txn = TestFixtures.testTransactionStampAdded;
        final updated = txn.copyWith(details: null);

        // Due to ?? operator in copyWith, null preserves original value
        expect(updated.details, txn.details);
      });
    });

    group('Transaction Types', () {
      test('supports pickup type', () {
        final txn = TestDataBuilder.createTransaction(type: TransactionType.pickup);
        expect(txn.type, TransactionType.pickup);
      });

      test('supports stamp type', () {
        final txn = TestDataBuilder.createTransaction(type: TransactionType.stamp);
        expect(txn.type, TransactionType.stamp);
      });

      test('supports redemption type', () {
        final txn = TestDataBuilder.createTransaction(type: TransactionType.redemption);
        expect(txn.type, TransactionType.redemption);
      });

      test('enum supports name property', () {
        expect(TransactionType.pickup.name, 'pickup');
        expect(TransactionType.stamp.name, 'stamp');
        expect(TransactionType.redemption.name, 'redemption');
      });
    });

    group('Edge Cases', () {
      test('handles very long business names', () {
        final longName = 'A' * 200;
        final txn = TestDataBuilder.createTransaction(businessName: longName);
        final json = txn.toJson();
        final decoded = Transaction.fromJson(json);

        expect(decoded.businessName, longName);
      });

      test('handles very long details', () {
        final longDetails = 'Detail ' * 100;
        final txn = TestDataBuilder.createTransaction(details: longDetails);
        final json = txn.toJson();
        final decoded = Transaction.fromJson(json);

        expect(decoded.details, longDetails);
      });

      test('handles special characters in details', () {
        final special = 'Details with "quotes" and <symbols> & émojis ☕';
        final txn = TestDataBuilder.createTransaction(details: special);
        final json = txn.toJson();
        final decoded = Transaction.fromJson(json);

        expect(decoded.details, special);
      });

      test('preserves timestamp precision', () {
        final now = DateTime.now();
        final txn = TestDataBuilder.createTransaction(timestamp: now);
        final json = txn.toJson();
        final decoded = Transaction.fromJson(json);

        expect(decoded.timestamp.millisecondsSinceEpoch,
               now.millisecondsSinceEpoch);
      });

      test('handles various ID formats', () {
        final uuidTxn = TestDataBuilder.createTransaction(
          id: '123e4567-e89b-12d3-a456-426614174000',
        );
        final json = uuidTxn.toJson();
        final decoded = Transaction.fromJson(json);

        expect(decoded.id, uuidTxn.id);
      });
    });

    group('Chronological Ordering', () {
      test('transactions can be sorted by timestamp', () {
        final txns = [
          TestFixtures.testTransactionCardRedeemed,  // timestamp3
          TestFixtures.testTransactionCardIssued,    // timestamp1
          TestFixtures.testTransactionStampAdded,    // timestamp2
        ];

        final sorted = List<Transaction>.from(txns)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

        expect(sorted[0].type, TransactionType.pickup);
        expect(sorted[1].type, TransactionType.stamp);
        expect(sorted[2].type, TransactionType.redemption);
      });
    });
  });
}
