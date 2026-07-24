import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:customer_app/services/transaction_repository.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared/models/card.dart';
import 'package:shared/models/transaction.dart' as models;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late TransactionRepository repository;
  late CardRepository cardRepository;
  late DatabaseHelper dbHelper;

  const testCardId = 'test-card-1';

  setUp(() async {
    await DatabaseHelper.resetForTesting(testDatabaseName: 'test_transaction_repository.db');
    dbHelper = DatabaseHelper();
    repository = TransactionRepository(dbHelper);
    cardRepository = CardRepository(dbHelper);

    // transactions.card_id has a FOREIGN KEY constraint against cards.id
    await cardRepository.insertCard(Card(
      id: testCardId,
      businessId: 'business-1',
      businessName: 'Test Business',
      businessPublicKey: 'test-public-key',
      stampsRequired: 10,
      stampsCollected: 0,
      brandColor: '#FF0000',
      mode: OperationMode.secure,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRedeemed: false,
    ));
  });

  tearDown(() async {
    try {
      await dbHelper.clearAllData();
      await dbHelper.close();
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  models.Transaction createTestTransaction({
    String? id,
    String? cardId,
    models.TransactionType? type,
    DateTime? timestamp,
    String? details,
  }) {
    return models.Transaction(
      id: id ?? 'txn-1',
      cardId: cardId ?? testCardId,
      type: type ?? models.TransactionType.stamp,
      timestamp: timestamp ?? DateTime.now(),
      businessName: 'Test Business',
      details: details,
    );
  }

  group('TransactionRepository - CRUD', () {
    test('insertTransaction then getTransactionById returns the same transaction', () async {
      final txn = createTestTransaction(id: 'txn-1', type: models.TransactionType.pickup);
      await repository.insertTransaction(txn);

      final result = await repository.getTransactionById('txn-1');
      expect(result, isNotNull);
      expect(result!.cardId, testCardId);
      expect(result.type, models.TransactionType.pickup);
    });

    test('getTransactionById returns null for a non-existent transaction', () async {
      final result = await repository.getTransactionById('does-not-exist');
      expect(result, isNull);
    });

    test('getTransactionsByCard returns only that card\'s transactions', () async {
      await cardRepository.insertCard(Card(
        id: 'other-card',
        businessId: 'business-1',
        businessName: 'Test Business',
        businessPublicKey: 'test-public-key',
        stampsRequired: 10,
        stampsCollected: 0,
        brandColor: '#FF0000',
        mode: OperationMode.secure,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRedeemed: false,
      ));
      await repository.insertTransaction(createTestTransaction(id: 't1', cardId: testCardId));
      await repository.insertTransaction(createTestTransaction(id: 't2', cardId: 'other-card'));

      final results = await repository.getTransactionsByCard(testCardId);
      expect(results.length, 1);
      expect(results.first.id, 't1');
    });

    test('getTransactionsByType filters correctly', () async {
      await repository.insertTransaction(createTestTransaction(id: 't1', type: models.TransactionType.pickup));
      await repository.insertTransaction(createTestTransaction(id: 't2', type: models.TransactionType.stamp));
      await repository.insertTransaction(createTestTransaction(id: 't3', type: models.TransactionType.stamp));

      final stamps = await repository.getTransactionsByType(models.TransactionType.stamp);
      expect(stamps.length, 2);
      expect(stamps.every((t) => t.type == models.TransactionType.stamp), isTrue);
    });

    test('getTransactionCount and getTransactionCountByType are accurate', () async {
      await repository.insertTransaction(createTestTransaction(id: 't1', type: models.TransactionType.pickup));
      await repository.insertTransaction(createTestTransaction(id: 't2', type: models.TransactionType.stamp));
      await repository.insertTransaction(createTestTransaction(id: 't3', type: models.TransactionType.stamp));

      expect(await repository.getTransactionCount(), 3);
      expect(await repository.getTransactionCountByType(models.TransactionType.stamp), 2);
      expect(await repository.getTransactionCountByType(models.TransactionType.redemption), 0);
    });

    test('getRecentTransactions respects the limit and orders by timestamp descending', () async {
      final now = DateTime.now();
      await repository.insertTransaction(createTestTransaction(
        id: 't1',
        timestamp: now.subtract(const Duration(minutes: 2)),
      ));
      await repository.insertTransaction(createTestTransaction(
        id: 't2',
        timestamp: now.subtract(const Duration(minutes: 1)),
      ));
      await repository.insertTransaction(createTestTransaction(id: 't3', timestamp: now));

      final recent = await repository.getRecentTransactions(limit: 2);
      expect(recent.length, 2);
      expect(recent.first.id, 't3'); // most recent first
    });

    test('deleteTransaction removes only that transaction', () async {
      await repository.insertTransaction(createTestTransaction(id: 't1'));
      await repository.insertTransaction(createTestTransaction(id: 't2'));

      await repository.deleteTransaction('t1');

      expect(await repository.getTransactionById('t1'), isNull);
      expect(await repository.getTransactionById('t2'), isNotNull);
    });

    test('deleteTransactionsByCard removes all transactions for that card only', () async {
      await cardRepository.insertCard(Card(
        id: 'other-card',
        businessId: 'business-1',
        businessName: 'Test Business',
        businessPublicKey: 'test-public-key',
        stampsRequired: 10,
        stampsCollected: 0,
        brandColor: '#FF0000',
        mode: OperationMode.secure,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRedeemed: false,
      ));
      await repository.insertTransaction(createTestTransaction(id: 't1', cardId: testCardId));
      await repository.insertTransaction(createTestTransaction(id: 't2', cardId: 'other-card'));

      await repository.deleteTransactionsByCard(testCardId);

      expect(await repository.getTransactionsByCard(testCardId), isEmpty);
      expect(await repository.getTransactionsByCard('other-card'), isNotEmpty);
    });
  });
}
