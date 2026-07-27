import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:customer_app/services/stamp_repository.dart';
import 'package:shared/shared.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late StampRepository repository;
  late CardRepository cardRepository;
  late DatabaseHelper dbHelper;

  const testCardId = 'test-card-1';

  setUp(() async {
    await DatabaseHelper.resetForTesting(testDatabaseName: 'test_stamp_repository.db');
    dbHelper = DatabaseHelper();
    repository = StampRepository(dbHelper);
    cardRepository = CardRepository(dbHelper);

    // stamps.card_id has a FOREIGN KEY constraint against cards.id
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

  Stamp createTestStamp({
    String? id,
    String? cardId,
    int? stampNumber,
    DateTime? timestamp,
    String? signature,
    String? previousHash,
  }) {
    return Stamp(
      id: id ?? 'stamp-${stampNumber ?? 1}',
      cardId: cardId ?? testCardId,
      stampNumber: stampNumber ?? 1,
      timestamp: timestamp ?? DateTime.now(),
      signature: signature ?? 'test-signature',
      previousHash: previousHash,
    );
  }

  group('StampRepository - CRUD', () {
    test('insertStamp then getStampById returns the same stamp', () async {
      final stamp = createTestStamp(id: 'stamp-1', stampNumber: 1);
      await repository.insertStamp(stamp);

      final result = await repository.getStampById('stamp-1');
      expect(result, isNotNull);
      expect(result!.cardId, testCardId);
      expect(result.stampNumber, 1);
      expect(result.signature, 'test-signature');
    });

    test('getStampById returns null for a non-existent stamp', () async {
      final result = await repository.getStampById('does-not-exist');
      expect(result, isNull);
    });

    test('getStampsByCard returns stamps ordered by stampNumber ascending', () async {
      await repository.insertStamp(createTestStamp(id: 's3', stampNumber: 3));
      await repository.insertStamp(createTestStamp(id: 's1', stampNumber: 1));
      await repository.insertStamp(createTestStamp(id: 's2', stampNumber: 2));

      final stamps = await repository.getStampsByCard(testCardId);
      expect(stamps.map((s) => s.stampNumber).toList(), [1, 2, 3]);
    });

    test('getLatestStamp returns the highest stampNumber', () async {
      await repository.insertStamp(createTestStamp(id: 's1', stampNumber: 1));
      await repository.insertStamp(createTestStamp(id: 's2', stampNumber: 2));

      final latest = await repository.getLatestStamp(testCardId);
      expect(latest?.stampNumber, 2);
    });

    test('getLatestStamp returns null when the card has no stamps', () async {
      final latest = await repository.getLatestStamp(testCardId);
      expect(latest, isNull);
    });

    test('getStampCount matches the number of inserted stamps', () async {
      await repository.insertStamp(createTestStamp(id: 's1', stampNumber: 1));
      await repository.insertStamp(createTestStamp(id: 's2', stampNumber: 2));

      expect(await repository.getStampCount(testCardId), 2);
    });

    test('stampExists is true after insert, false before', () async {
      expect(await repository.stampExists('stamp-1'), isFalse);
      await repository.insertStamp(createTestStamp(id: 'stamp-1', stampNumber: 1));
      expect(await repository.stampExists('stamp-1'), isTrue);
    });

    test('deleteStamp removes only that stamp', () async {
      await repository.insertStamp(createTestStamp(id: 's1', stampNumber: 1));
      await repository.insertStamp(createTestStamp(id: 's2', stampNumber: 2));

      await repository.deleteStamp('s1');

      expect(await repository.stampExists('s1'), isFalse);
      expect(await repository.stampExists('s2'), isTrue);
    });

    test('deleteStampsByCard removes all stamps for that card only', () async {
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
      await repository.insertStamp(createTestStamp(id: 's1', cardId: testCardId, stampNumber: 1));
      await repository.insertStamp(createTestStamp(id: 's2', cardId: 'other-card', stampNumber: 1));

      await repository.deleteStampsByCard(testCardId);

      expect(await repository.getStampCount(testCardId), 0);
      expect(await repository.getStampCount('other-card'), 1);
    });

    test('insertStamp with the same id replaces rather than duplicates (V-003)', () async {
      await repository.insertStamp(createTestStamp(id: 'stamp-1', stampNumber: 1, signature: 'sig-a'));
      await repository.insertStamp(createTestStamp(id: 'stamp-1', stampNumber: 1, signature: 'sig-b'));

      expect(await repository.getStampCount(testCardId), 1);
      final stamp = await repository.getStampById('stamp-1');
      expect(stamp?.signature, 'sig-b');
    });
  });

  group('StampRepository.verifyStampChain', () {
    test('an empty chain is considered valid', () async {
      expect(await repository.verifyStampChain(testCardId), isTrue);
    });

    test('sequential stamp numbers starting at 1 are valid', () async {
      await repository.insertStamp(createTestStamp(id: 's1', stampNumber: 1, previousHash: null));
      await repository.insertStamp(createTestStamp(id: 's2', stampNumber: 2, previousHash: 'hash-1'));
      await repository.insertStamp(createTestStamp(id: 's3', stampNumber: 3, previousHash: 'hash-2'));

      expect(await repository.verifyStampChain(testCardId), isTrue);
    });

    test('a gap in stamp numbers is invalid', () async {
      await repository.insertStamp(createTestStamp(id: 's1', stampNumber: 1, previousHash: null));
      await repository.insertStamp(createTestStamp(id: 's3', stampNumber: 3, previousHash: 'hash-1'));

      expect(await repository.verifyStampChain(testCardId), isFalse);
    });

    test('a missing previousHash after the first stamp is invalid', () async {
      await repository.insertStamp(createTestStamp(id: 's1', stampNumber: 1, previousHash: null));
      await repository.insertStamp(createTestStamp(id: 's2', stampNumber: 2, previousHash: null));

      expect(await repository.verifyStampChain(testCardId), isFalse);
    });
  });
}
