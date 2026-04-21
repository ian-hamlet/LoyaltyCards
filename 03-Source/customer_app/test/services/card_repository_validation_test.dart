import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:shared/shared.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize sqflite for testing
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late CardRepository repository;
  late DatabaseHelper dbHelper;

  setUp(() async {
    // Use unique database name for this test file to prevent locking
    await DatabaseHelper.resetForTesting(testDatabaseName: 'test_card_repository_validation.db');
    
    dbHelper = DatabaseHelper();
    repository = CardRepository(dbHelper);
  });

  tearDown() async {
    try {
      await dbHelper.clearAllData();
      await dbHelper.close();
    } catch (e) {
      // Ignore cleanup errors
    }
  };

  tearDownAll() async {
    // Clean up test database file
    try {
      await DatabaseHelper.resetForTesting();
      final dbHelper = DatabaseHelper();
      await dbHelper.deleteDatabase();
    } catch (e) {
      // Ignore
    }
  };

  /// Helper function to create test cards
  Card createTestCard({
    String? id,
    String? businessId,
    String? businessName,
    String? publicKey,
    int? stampsRequired,
    int? stampsCollected,
    String? brandColor,
    int? logoIndex,
    OperationMode? mode,
    String? deviceId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Card(
      id: id ?? 'test-card-$now',
      businessId: businessId ?? 'business-1',
      businessName: businessName ?? 'Test Business',
      businessPublicKey: publicKey ?? 'test-public-key',
      stampsRequired: stampsRequired ?? 10,
      stampsCollected: stampsCollected ?? 0,
      brandColor: brandColor ?? '#FF0000',
      logoIndex: logoIndex ?? 0,
      mode: mode ?? OperationMode.secure,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRedeemed: false,
      deviceId: deviceId,
    );
  }

  group('CardRepository Validation Tests', () {
    test('insertCard throws when card ID is empty', () async {
      final invalidCard = createTestCard(id: '');
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('Card ID must not be empty'))
        ),
      );
    });
    
    test('insertCard throws when business ID is empty', () async {
      final invalidCard = createTestCard(businessId: '');
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('Business ID must not be empty'))
        ),
      );
    });
    
    test('insertCard throws when business name is empty', () async {
      final invalidCard = createTestCard(businessName: '');
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('Business name must not be empty'))
        ),
      );
    });
    
    test('insertCard throws when stamps required is zero', () async {
      final invalidCard = createTestCard(stampsRequired: 0);
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('must be positive'))
        ),
      );
    });
    
    test('insertCard throws when stamps required is negative', () async {
      final invalidCard = createTestCard(stampsRequired: -5);
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('must be positive'))
        ),
      );
    });
    
    test('insertCard throws when stamps required exceeds 100', () async {
      final invalidCard = createTestCard(stampsRequired: 150);
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('must be <= 100'))
        ),
      );
    });
    
    test('insertCard throws when stamps collected is negative', () async {
      final invalidCard = createTestCard(
        stampsRequired: 10,
        stampsCollected: -3,
      );
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('must be non-negative'))
        ),
      );
    });
    
    test('insertCard throws when stamps collected exceeds required', () async {
      final invalidCard = createTestCard(
        stampsRequired: 10,
        stampsCollected: 15,
      );
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('cannot exceed'))
        ),
      );
    });
    
    test('insertCard succeeds with valid card', () async {
      final validCard = createTestCard();
      
      await repository.insertCard(validCard);
      
      final retrieved = await repository.getCardById(validCard.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, validCard.id);
      expect(retrieved.businessId, validCard.businessId);
    });
    
    test('updateCard throws when validation fails', () async {
      final invalidCard = createTestCard(stampsRequired: -1);
      
      expect(
        () => repository.updateCard(invalidCard),
        throwsA(isA<CardValidationException>()),
      );
    });
    
    test('updateCard succeeds with valid card', () async {
      final card = createTestCard(stampsCollected: 3);
      await repository.insertCard(card);
      
      final updatedCard = card.copyWith(stampsCollected: 5);
      await repository.updateCard(updatedCard);
      
      final retrieved = await repository.getCardById(card.id);
      expect(retrieved!.stampsCollected, 5);
    });
  });

  group('CardRepository Edge Cases', () {
    test('validation accepts card at exact limits', () async {
      final card = createTestCard(
        stampsRequired: 100,
        stampsCollected: 100,
      );
      
      await repository.insertCard(card);
      
      final retrieved = await repository.getCardById(card.id);
      expect(retrieved, isNotNull);
    });
    
    test('validation accepts minimum valid values', () async {
      final card = createTestCard(
        stampsRequired: 1,
        stampsCollected: 0,
      );
      
      await repository.insertCard(card);
      
      final retrieved = await repository.getCardById(card.id);
      expect(retrieved, isNotNull);
    });
  });
}
