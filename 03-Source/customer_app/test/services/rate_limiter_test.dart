import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:customer_app/services/rate_limiter.dart';
import 'package:customer_app/services/database_helper.dart';
import 'package:shared/shared.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

@GenerateMocks([DatabaseHelper, Database])
import 'rate_limiter_test.mocks.dart';

void main() {
  late RateLimiter rateLimiter;
  late MockDatabaseHelper mockDbHelper;
  late MockDatabase mockDb;

  setUp(() {
    mockDbHelper = MockDatabaseHelper();
    mockDb = MockDatabase();
    rateLimiter = RateLimiter(mockDbHelper);

    // Default: return mockDb when database getter is called
    when(mockDbHelper.database).thenAnswer((_) async => mockDb);
  });

  group('RateLimiter - canReceiveStamp', () {
    const testCardId = 'test-card-123';
    const testBusinessId = 'test-business-123';

    test('allows first stamp when no stamps exist', () async {
      // Mock: no stamps in database
      when(mockDb.query(
        'stamps',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => []);

      final result = await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: testBusinessId,
        mode: OperationMode.secure,
      );

      expect(result.canProceed, true);
      expect(result.message, isNull);
      expect(result.waitTimeMs, isNull);
    });

    test('allows stamp when last stamp is older than rate limit', () async {
      // Mock: last stamp was 5 seconds ago (well beyond 1 second rate limit)
      // Use larger buffer to account for test execution time
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 5000;
      when(mockDb.query(
        'stamps',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [
            {'timestamp': lastStampTime}
          ]);

      final result = await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: testBusinessId,
        mode: OperationMode.secure,
      );

      expect(result.canProceed, true);
      expect(result.message, isNull);
      expect(result.waitTimeMs, isNull);
    });

    test('rejects stamp when last stamp is within rate limit window', () async {
      // Mock: last stamp was 100ms ago (well within 1000ms rate limit)
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 100;
      when(mockDb.query(
        'stamps',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [
            {'timestamp': lastStampTime}
          ]);

      final result = await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: testBusinessId,
        mode: OperationMode.secure,
      );

      expect(result.canProceed, false);
      expect(result.message, isNotNull);
      expect(result.message, contains('wait'));
      expect(result.waitTimeMs, greaterThan(0));
    });

    test('allows stamp exactly at rate limit boundary', () async {
      // Mock: last stamp was exactly 1000ms ago
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - AppConstants.stampRateLimitMs;
      when(mockDb.query(
        'stamps',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [
            {'timestamp': lastStampTime}
          ]);

      final result = await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: testBusinessId,
        mode: OperationMode.secure,
      );

      expect(result.canProceed, true);
    });

    test('applies same rate limit for simple mode', () async {
      // Mock: last stamp was 100ms ago (well within rate limit)
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 100;
      when(mockDb.query(
        'stamps',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [
            {'timestamp': lastStampTime}
          ]);

      final result = await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: testBusinessId,
        mode: OperationMode.simple,
      );

      // Should also be rate-limited
      expect(result.canProceed, false);
      expect(result.waitTimeMs, greaterThan(0));
    });

    test('queries correct card stamps from database', () async {
      when(mockDb.query(
        'stamps',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => []);

      await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: testBusinessId,
        mode: OperationMode.secure,
      );

      // Verify correct query parameters
      verify(mockDb.query(
        'stamps',
        where: 'card_id = ?',
        whereArgs: [testCardId],
        orderBy: 'timestamp DESC',
        limit: 1,
      )).called(1);
    });
  });

  group('RateLimitResult', () {
    test('creates successful result', () {
      final result = RateLimitResult(canProceed: true);

      expect(result.canProceed, true);
      expect(result.message, isNull);
      expect(result.waitTimeMs, isNull);
    });

    test('creates blocked result with wait time', () {
      final result = RateLimitResult(
        canProceed: false,
        waitTimeMs: 500,
        message: 'Wait 500ms',
      );

      expect(result.canProceed, false);
      expect(result.waitTimeMs, 500);
      expect(result.message, 'Wait 500ms');
    });
  });
}
