import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/exceptions/qr_generation_exception.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:customer_app/services/qr_token_generator.dart';
import 'package:customer_app/services/stamp_repository.dart';
import 'package:shared/shared.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late QRTokenGenerator generator;
  late DatabaseHelper dbHelper;
  late CardRepository cardRepository;
  late StampRepository stampRepository;

  const testCardId = 'test-card-1';

  Card testCard({int stampsCollected = 0}) {
    return Card(
      id: testCardId,
      businessId: 'business-1',
      businessName: 'Test Business',
      businessPublicKey: 'test-public-key',
      stampsRequired: 10,
      stampsCollected: stampsCollected,
      brandColor: '#FF0000',
      mode: OperationMode.secure,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRedeemed: false,
    );
  }

  Stamp testStamp({required String id, required int stampNumber, String? signature}) {
    return Stamp(
      id: id,
      cardId: testCardId,
      stampNumber: stampNumber,
      timestamp: DateTime.now(),
      signature: signature ?? 'sig-$stampNumber',
    );
  }

  setUp(() async {
    generator = QRTokenGenerator();
    await DatabaseHelper.resetForTesting(testDatabaseName: 'test_qr_token_generator.db');
    dbHelper = DatabaseHelper();
    cardRepository = CardRepository(dbHelper);
    stampRepository = StampRepository(dbHelper);
  });

  tearDown(() async {
    try {
      await dbHelper.clearAllData();
      await dbHelper.close();
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('QRTokenGenerator.generateRedemptionRequest', () {
    test('builds a valid token with a matching stampProof per stamp', () {
      final card = testCard(stampsCollected: 2);
      final stamps = [
        testStamp(id: 's1', stampNumber: 1, signature: 'sig-1'),
        testStamp(id: 's2', stampNumber: 2, signature: 'sig-2'),
      ];

      final token = generator.generateRedemptionRequest(card: card, stamps: stamps);

      expect(token.cardId, testCardId);
      expect(token.businessId, 'business-1');
      expect(token.stampsCollected, 2);
      expect(token.stampProofs.length, 2);
      expect(token.stampProofs[0].signature, 'sig-1');
      expect(token.stampProofs[0].timestamp, stamps[0].timestamp.millisecondsSinceEpoch);
      expect(token.stampProofs[1].signature, 'sig-2');
    });

    test('throws when stamps.length does not match card.stampsCollected', () {
      final card = testCard(stampsCollected: 3);
      final stamps = [testStamp(id: 's1', stampNumber: 1)];

      expect(
        () => generator.generateRedemptionRequest(card: card, stamps: stamps),
        throwsA(isA<QRGenerationException>()),
      );
    });

    test('throws when there are no stamps to redeem', () {
      final card = testCard(stampsCollected: 0);

      expect(
        () => generator.generateRedemptionRequest(card: card, stamps: []),
        throwsA(isA<QRGenerationException>()),
      );
    });

    test('throws when a stamp has an empty signature', () {
      final card = testCard(stampsCollected: 1);
      final stamps = [testStamp(id: 's1', stampNumber: 1, signature: '')];

      expect(
        () => generator.generateRedemptionRequest(card: card, stamps: stamps),
        throwsA(isA<QRGenerationException>()),
      );
    });
  });

  group('QRTokenGenerator.generateStampRequest', () {
    test('reloads the card from the database and uses fresh stamp count', () async {
      await cardRepository.insertCard(testCard(stampsCollected: 0));

      // Simulate the DB having moved on since the caller's in-memory `card`
      // was read - this is exactly the staleness this method exists to fix.
      final staleCardView = testCard(stampsCollected: 0);
      await cardRepository.updateCard(testCard(stampsCollected: 3));
      await stampRepository.insertStamp(testStamp(id: 's1', stampNumber: 1, signature: 'sig-1'));
      await stampRepository.insertStamp(testStamp(id: 's2', stampNumber: 2, signature: 'sig-2'));
      await stampRepository.insertStamp(testStamp(id: 's3', stampNumber: 3, signature: 'sig-3'));

      final token = await generator.generateStampRequest(card: staleCardView);

      expect(token.currentStamps, 3, reason: 'should reflect the DB, not the stale in-memory card');
      expect(token.lastStampHash, 'sig-3', reason: 'should chain from the highest stamp number');
    });

    test('throws QRGenerationException when the card no longer exists', () async {
      final card = testCard();

      expect(
        () => generator.generateStampRequest(card: card),
        throwsA(isA<QRGenerationException>()),
      );
    });

    test('uses an empty hash when the card has no stamps yet', () async {
      await cardRepository.insertCard(testCard(stampsCollected: 0));
      final card = testCard(stampsCollected: 0);

      final token = await generator.generateStampRequest(card: card);

      expect(token.currentStamps, 0);
      expect(token.lastStampHash, '');
    });
  });
}
