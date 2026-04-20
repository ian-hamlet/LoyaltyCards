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

  group('REQ-022: Dynamic Scan Interval Support', () {
    const testCardId = 'test-card-123';
    const testBusinessId = 'test-business-123';

    test('uses default rate limit when scanInterval not provided', () async {
      // Mock: last stamp was 3 seconds ago
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 3000;
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
        // No scanInterval provided, should use default (5000ms)
      );

      // 3 seconds < 5 seconds, should be blocked
      expect(result.canProceed, false);
      expect(result.waitTimeMs, greaterThan(0));
    });

    test('uses custom scanInterval from token (30 seconds)', () async {
      // Mock: last stamp was 10 seconds ago
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 10000;
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
        scanInterval: 30000, // REQ-022: 30 second custom interval
      );

      // 10 seconds < 30 seconds, should be blocked
      expect(result.canProceed, false);
      expect(result.waitTimeMs, greaterThan(0));
      expect(result.waitTimeMs, lessThan(30000));
    });

    test('allows stamp when custom scanInterval has elapsed', () async {
      // Mock: last stamp was 35 seconds ago
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 35000;
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
        scanInterval: 30000, // 30 seconds
      );

      // 35 seconds > 30 seconds, should be allowed
      expect(result.canProceed, true);
    });

    test('uses minimum scanInterval (5 seconds)', () async {
      // Mock: last stamp was 3 seconds ago
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 3000;
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
        scanInterval: 5000, // 5 seconds (minimum)
      );

      // 3 seconds < 5 seconds, should be blocked
      expect(result.canProceed, false);
    });

    test('uses maximum scanInterval (60 seconds)', () async {
      // Mock: last stamp was 45 seconds ago
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 45000;
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
        scanInterval: 60000, // 60 seconds (maximum)
      );

      // 45 seconds < 60 seconds, should be blocked
      expect(result.canProceed, false);
      expect(result.waitTimeMs, greaterThan(0));
      expect(result.waitTimeMs, lessThan(60000));
    });

    test('different suppliers can have different scanIntervals', () async {
      // Mock: last stamp was 8 seconds ago
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 8000;
      when(mockDb.query(
        'stamps',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [
            {'timestamp': lastStampTime}
          ]);

      // Scenario 1: Coffee shop with 5 second interval - should pass
      final result1 = await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: 'coffee-shop',
        mode: OperationMode.simple,
        scanInterval: 5000,
      );
      expect(result1.canProceed, true);

      // Scenario 2: Restaurant with 15 second interval - should fail
      final result2 = await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: 'restaurant',
        mode: OperationMode.simple,
        scanInterval: 15000,
      );
      expect(result2.canProceed, false);
    });

    test('backward compatibility: works without scanInterval parameter', () async {
      // Ensure existing code without scanInterval still works
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastStampTime = now - 6000;
      when(mockDb.query(
        'stamps',
        where: anyNamed('where'),
        whereArgs: anyNamed('whereArgs'),
        orderBy: anyNamed('orderBy'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [
            {'timestamp': lastStampTime}
          ]);

      // Old code doesn't pass scanInterval
      final result = await rateLimiter.canReceiveStamp(
        cardId: testCardId,
        businessId: testBusinessId,
        mode: OperationMode.simple,
      );

      // Should use default AppConstants.stampRateLimitMs (5000)
      // 6 seconds > 5 seconds, should be allowed
      expect(result.canProceed, true);
    });
  });
}
