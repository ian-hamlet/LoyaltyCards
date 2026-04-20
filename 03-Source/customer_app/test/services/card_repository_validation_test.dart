import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/services/card_repository.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:shared/shared.dart';
import 'package:shared/fixtures/test_fixtures.dart';

void main() {
  late CardRepository repository;
  late DatabaseHelper dbHelper;

  setUp(() async {
    // Use in-memory database for tests
    dbHelper = DatabaseHelper();
    repository = CardRepository(dbHelper);
  });

  tearDown(() async {
    await dbHelper.clearAllData();
  });

  group('CardRepository Validation Tests', () {
    test('insertCard throws when card ID is empty', () async {
      final invalidCard = TestFixtures.createCard(id: '');
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('Card ID must not be empty'))
        ),
      );
    });
    
    test('insertCard throws when business ID is empty', () async {
      final invalidCard = TestFixtures.createCard(businessId: '');
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('Business ID must not be empty'))
        ),
      );
    });
    
    test('insertCard throws when business name is empty', () async {
      final invalidCard = TestFixtures.createCard(businessName: '');
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('Business name must not be empty'))
        ),
      );
    });
    
    test('insertCard throws when stamps required is zero', () async {
      final invalidCard = TestFixtures.createCard(stampsRequired: 0);
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('must be positive'))
        ),
      );
    });
    
    test('insertCard throws when stamps required is negative', () async {
      final invalidCard = TestFixtures.createCard(stampsRequired: -5);
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('must be positive'))
        ),
      );
    });
    
    test('insertCard throws when stamps required exceeds 100', () async {
      final invalidCard = TestFixtures.createCard(stampsRequired: 150);
      
      expect(
        () => repository.insertCard(invalidCard),
        throwsA(isA<CardValidationException>()
          .having((e) => e.message, 'message', contains('must be <= 100'))
        ),
      );
    });
    
    test('insertCard throws when stamps collected is negative', () async {
      final invalidCard = TestFixtures.createCard(
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
      final invalidCard = TestFixtures.createCard(
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
      final validCard = TestFixtures.createCard();
      
      // Should not throw
      await repository.insertCard(validCard);
      
      // Verify it was actually inserted
      final retrieved = await repository.getCardById(validCard.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.id, validCard.id);
      expect(retrieved.businessId, validCard.businessId);
    });
    
    test('updateCard throws when validation fails', () async {
      final invalidCard = TestFixtures.createCard(stampsRequired: -1);
      
      expect(
        () => repository.updateCard(invalidCard),
        throwsA(isA<CardValidationException>()),
      );
    });
    
    test('updateCard succeeds with valid card', () async {
      // Insert a card first
      final card = TestFixtures.createCard(stampsCollected: 3);
      await repository.insertCard(card);
      
      // Update it
      final updatedCard = card.copyWith(stampsCollected: 5);
      await repository.updateCard(updatedCard);
      
      // Verify update
      final retrieved = await repository.getCardById(card.id);
      expect(retrieved!.stampsCollected, 5);
    });
  });

  group('CardRepository Edge Cases', () {
    test('validation accepts card at exact limits', () async {
      final card = TestFixtures.createCard(
        stampsRequired: 100, // Maximum
        stampsCollected: 100, // Equal to required (at limit)
      );
      
      // Should not throw
      await repository.insertCard(card);
      
      final retrieved = await repository.getCardById(card.id);
      expect(retrieved, isNotNull);
    });
    
    test('validation accepts minimum valid values', () async {
      final card = TestFixtures.createCard(
        stampsRequired: 1, // Minimum valid
        stampsCollected: 0, // Minimum valid
      );
      
      // Should not throw
      await repository.insertCard(card);
      
      final retrieved = await repository.getCardById(card.id);
      expect(retrieved, isNotNull);
    });
  });
}
