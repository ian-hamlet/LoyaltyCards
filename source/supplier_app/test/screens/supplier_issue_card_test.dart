import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/screens/supplier/supplier_issue_card.dart';
import 'package:supplier_app/services/business_repository.dart';
import 'package:supplier_app/services/key_manager.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// CRASH-001 regression test (wider-audit fix) for the Issue Card screen's
/// Print and Share buttons - the same unguarded-button gap as the original
/// Stamp Setup crash, found by auditing every call site of
/// BackupStorageService's print/share/save methods. See
/// docs/project-management/CRASH-001-stamp-print-race-condition.md.
///
/// Same interception approach as supplier_stamp_card_test.dart: mock the
/// printing plugin's method channel (net.nfet.printing) and share_plus's
/// (dev.fluttercommunity.plus/share) to count native calls, then fire the
/// guarded handler twice back-to-back - the shape of a fast double-tap -
/// and confirm only one native call goes out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const printingChannel = MethodChannel('net.nfet.printing');
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const businessId = 'business-issue-card-print-test';

  late BusinessRepository businessRepo;
  late KeyManager keyManager;
  late int printPdfCallCount;
  late int shareCallCount;
  late Set<int> completedJobIndices;

  Future<void> completeJob(int jobIndex) async {
    if (!completedJobIndices.add(jobIndex)) return;
    const codec = StandardMethodCodec();
    final data = codec.encodeMethodCall(
      MethodCall('onCompleted', {'job': jobIndex, 'completed': true}),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(printingChannel.name, data, (_) {});
  }

  setUp(() async {
    printPdfCallCount = 0;
    shareCallCount = 0;
    completedJobIndices = {};

    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    await SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_supplier_issue_card.db');
    businessRepo = BusinessRepository();
    keyManager = KeyManager();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      printingChannel,
      (call) async {
        if (call.method == 'printPdf') {
          printPdfCallCount++;
          final jobIndex = call.arguments['job'] as int;
          unawaited(
            Future.delayed(const Duration(milliseconds: 30), () => completeJob(jobIndex)),
          );
          return jobIndex;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      (call) async {
        if (call.method == 'share') {
          shareCallCount++;
          return 'dev.fluttercommunity.plus/share/completed';
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (call) async {
        if (call.method == 'getTemporaryDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(printingChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
  });

  /// QRTokenGenerator.generateCardIssueToken() unconditionally signs the
  /// whole token (regardless of initialStampCount), so a stored private key
  /// is required even at the default initialStampCount of 0.
  Future<void> seedSimpleModeBusiness(WidgetTester tester) async {
    await tester.runAsync(() async {
      final keyPair = await keyManager.generateKeyPair();
      await keyManager.storePrivateKey(businessId, keyPair.privateKey as ECPrivateKey);
      await keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);
      final publicKeyEncoded = (await keyManager.getPublicKeyString(businessId))!;

      await businessRepo.insertBusiness(Business(
        id: businessId,
        name: 'Test Coffee Shop',
        publicKey: publicKeyEncoded,
        privateKey: 'unused-plaintext-field',
        stampsRequired: 10,
        brandColor: '#FF5733',
        mode: OperationMode.simple,
        createdAt: DateTime.now(),
      ));
    });
  }

  /// See supplier_stamp_card_test.dart's settleAfterMount for why this polls
  /// instead of using a single fixed delay.
  Future<void> settleAfterMount(WidgetTester tester) async {
    await tester.pump();
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.text('Print').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'CRASH-001: guarded _printToken disables the Print button and ignores a second call',
    (tester) async {
      await seedSimpleModeBusiness(tester);

      await tester.pumpWidget(const MaterialApp(home: SupplierIssueCard()));
      await settleAfterMount(tester);

      final printButtonFinder = find.widgetWithText(OutlinedButton, 'Print');
      expect(printButtonFinder, findsOneWidget);
      expect(tester.widget<OutlinedButton>(printButtonFinder).onPressed, isNotNull);

      final state = tester.state(find.byType(SupplierIssueCard));
      late Future<void> firstCall;
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        firstCall = (state as dynamic).printTokenForTesting() as Future<void>;
      });
      await tester.pump();

      expect(
        tester.widget<OutlinedButton>(printButtonFinder).onPressed,
        isNull,
        reason: 'Print button should disable itself immediately once a print '
            'job starts, so a rapid second tap cannot reach onPressed at all.',
      );

      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        final secondCall = (state as dynamic).printTokenForTesting() as Future<void>;
        await Future.wait([firstCall, secondCall]);
      });
      await tester.pumpAndSettle();

      expect(
        printPdfCallCount,
        1,
        reason: 'The _isPrinting guard should reject the second call outright, '
            'so the native printing plugin should only ever be asked to start '
            'one print job.',
      );
      expect(
        tester.widget<OutlinedButton>(printButtonFinder).onPressed,
        isNotNull,
        reason: 'Print button should re-enable once the print job completes.',
      );
    },
  );

  testWidgets(
    'CRASH-001: guarded _shareToken disables the Share button and ignores a second call',
    (tester) async {
      await seedSimpleModeBusiness(tester);

      await tester.pumpWidget(const MaterialApp(home: SupplierIssueCard()));
      await settleAfterMount(tester);

      final shareButtonFinder = find.widgetWithText(OutlinedButton, 'Share QR');
      expect(shareButtonFinder, findsOneWidget);
      expect(tester.widget<OutlinedButton>(shareButtonFinder).onPressed, isNotNull);

      final state = tester.state(find.byType(SupplierIssueCard));
      late Future<void> firstCall;
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        firstCall = (state as dynamic).shareTokenForTesting() as Future<void>;
      });
      await tester.pump();

      expect(
        tester.widget<OutlinedButton>(shareButtonFinder).onPressed,
        isNull,
        reason: 'Share button should disable itself immediately once a share '
            'is in flight, so a rapid second tap cannot reach onPressed at all.',
      );

      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        final secondCall = (state as dynamic).shareTokenForTesting() as Future<void>;
        await Future.wait([firstCall, secondCall]);
      });
      await tester.pumpAndSettle();

      expect(
        shareCallCount,
        1,
        reason: 'The _isSharing guard should reject the second call outright, '
            'so the native share_plus plugin should only ever be asked to '
            'open one share sheet.',
      );
      expect(
        tester.widget<OutlinedButton>(shareButtonFinder).onPressed,
        isNotNull,
        reason: 'Share button should re-enable once the share call completes.',
      );
    },
  );

  /// TEST-021: a legacy business created before the stampsRequired ceiling
  /// tightened can still have a much higher value stored (up to 20, the
  /// historical maximum) - the initial-stamp slider's max tracks that
  /// stored value, not the current onboarding range, so a supplier can
  /// still set a high initial stamp count on one of these. Mirrors the
  /// real-device scenario that surfaced this bug.
  const legacyBusinessId = 'business-issue-card-legacy-20-stamp';
  Future<void> seedLegacyHighStampBusiness(WidgetTester tester) async {
    await tester.runAsync(() async {
      final keyPair = await keyManager.generateKeyPair();
      await keyManager.storePrivateKey(legacyBusinessId, keyPair.privateKey as ECPrivateKey);
      await keyManager.storePublicKey(legacyBusinessId, keyPair.publicKey as ECPublicKey);
      final publicKeyEncoded = (await keyManager.getPublicKeyString(legacyBusinessId))!;

      await businessRepo.insertBusiness(Business(
        id: legacyBusinessId,
        name: "Maria's Luxury Spa & Wellness Centre",
        publicKey: publicKeyEncoded,
        privateKey: 'unused-plaintext-field',
        stampsRequired: 20,
        brandColor: '#6A1B9A',
        mode: OperationMode.secure,
        createdAt: DateTime.now(),
      ));
    });
  }

  testWidgets(
    'TEST-021: a legacy 20-stamp business can issue a card with 16+ pre-applied stamps without the QR failing silently',
    (tester) async {
      // resetForTesting only closes the connection and clears the cached
      // in-memory handle - it doesn't delete the on-disk file (see
      // supplier_database_helper.dart), so reusing the same test DB name
      // as the earlier tests in this file would leave their business rows
      // still present, and getBusiness() (no ID filter, single-business
      // model) could return one of those instead of this test's business.
      // A distinct name gives this test a genuinely empty database.
      await tester.runAsync(
        () => SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_supplier_issue_card_legacy.db'),
      );
      await seedLegacyHighStampBusiness(tester);

      await tester.pumpWidget(const MaterialApp(home: SupplierIssueCard()));
      await tester.pump();
      for (var attempt = 0; attempt < 50; attempt++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        if (find.byType(QrImageView).evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget, reason: 'QR should render at 0 initial stamps');

      final state = tester.state(find.byType(SupplierIssueCard));
      // 17 was the exact point the old plain-JSON/byte-mode encoding
      // first failed for this business shape (measured in
      // DEFECT_TRACKER.md TEST-021) - well past the max any *new*
      // business can reach (12), only possible via a legacy business
      // like this one.
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        await (state as dynamic).setInitialStampCountForTesting(17);
      });
      await tester.pumpAndSettle();

      expect(
        find.byType(QrImageView),
        findsOneWidget,
        reason: 'QR should still render at 17 pre-applied stamps with the compact encoding, '
            'not fall back to the "too large to display" panel.',
      );
      expect(find.text("This card's code is too large to display"), findsNothing);

      // The historical maximum stampsRequired ever allowed - the true
      // worst case for this business.
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        await (state as dynamic).setInitialStampCountForTesting(20);
      });
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget, reason: 'QR should still render at 20/20 pre-applied stamps');
      expect(find.text("This card's code is too large to display"), findsNothing);

      // Secure Mode starts a countdown Timer.periodic (_startCountdown) -
      // dispose the widget before the test ends so it gets cancelled,
      // otherwise flutter_test's pending-timer invariant check fails.
      await tester.pumpWidget(const SizedBox());
    },
  );
}
