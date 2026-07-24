import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/services/business_repository.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// V-013: direct coverage of the duplicate-redemption guard. Each
/// stamp-collection cycle gets a brand-new cardId, so "has this cardId ever
/// been redeemed" is safe and won't block legitimate repeat business - see
/// docs/quality/VULNERABILITIES.md for the full exploit this closes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late BusinessRepository repository;
  final dbHelper = SupplierDatabaseHelper();

  setUp(() async {
    repository = BusinessRepository();
    await dbHelper.clearAllData();
    // redemptions.business_id has a FOREIGN KEY constraint against business.id
    await repository.insertBusiness(Business(
      id: 'business-001',
      name: 'Test Coffee Shop',
      publicKey: 'test-public-key',
      privateKey: 'test-private-key',
      stampsRequired: 10,
      brandColor: '#FF5733',
      createdAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    await dbHelper.clearAllData();
  });

  group('BusinessRepository.hasBeenRedeemed', () {
    test('returns false for a card with no redemption history', () async {
      final result = await repository.hasBeenRedeemed('card-never-redeemed');
      expect(result, isFalse);
    });

    test('returns true after logRedemption is called for that card', () async {
      const cardId = 'card-001';
      await repository.logRedemption(
        cardId: cardId,
        stampsRedeemed: 10,
        businessId: 'business-001',
      );

      final result = await repository.hasBeenRedeemed(cardId);
      expect(result, isTrue);
    });

    test('does not flag an unrelated card as redeemed', () async {
      await repository.logRedemption(
        cardId: 'card-001',
        stampsRedeemed: 10,
        businessId: 'business-001',
      );

      final result = await repository.hasBeenRedeemed('card-002');
      expect(result, isFalse);
    });

    test('V-013: rejects a replayed redemption of the same card', () async {
      const cardId = 'card-replay-test';

      // Legitimate first redemption.
      final firstCheck = await repository.hasBeenRedeemed(cardId);
      expect(firstCheck, isFalse, reason: 'card should be redeemable the first time');
      await repository.logRedemption(
        cardId: cardId,
        stampsRedeemed: 10,
        businessId: 'business-001',
      );

      // Customer restores a pre-redemption backup and replays the same
      // genuinely-signed redemption request a second time.
      final secondCheck = await repository.hasBeenRedeemed(cardId);
      expect(secondCheck, isTrue, reason: 'replayed redemption of the same card must be caught');
    });
  });
}
