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
/// `printIssueCard()` since switched from `Printing.layoutPdf` to
/// `Printing.sharePdf` (2026-08-27, see `ConfigBackupService.printBackup`'s
/// doc comment) - the guard tested here is independent of which `printing`
/// API is used underneath.
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
  late int sharePdfCallCount;
  late int shareCallCount;

  setUp(() async {
    sharePdfCallCount = 0;
    shareCallCount = 0;

    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    await SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_supplier_issue_card.db');
    businessRepo = BusinessRepository();
    keyManager = KeyManager();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      printingChannel,
      (call) async {
        if (call.method == 'sharePdf') {
          sharePdfCallCount++;
          await Future.delayed(const Duration(milliseconds: 30));
          return 1;
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
        sharePdfCallCount,
        1,
        reason: 'The _isPrinting guard should reject the second call outright, '
            'so the native printing plugin should only ever be asked to share '
            'one PDF.',
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

  /// A legacy business created before the stampsRequired ceiling
  /// tightened can still have a much higher value stored (up to 20, the
  /// historical maximum) - mirrors the real-device scenario that
  /// surfaced both TEST-021 (silent QR-capacity failure) and
  /// DECISION-017 (no self-service way to fix an out-of-range business
  /// short of a full reset).
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
    'DECISION-017: a legacy 20-stamp business is blocked from issuing until fixed, then issues successfully once reconfigured',
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
        if (find.text("New cards can't be issued").evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();

      // DECISION-017: a business outside the supported range is blocked
      // before ever reaching QR generation - the customer app would
      // reject the token anyway (TEST-019), so there's no point letting
      // the supplier generate one at all. This also means TEST-021's
      // compact-encoding fix is no longer reachable via this specific
      // 20-stamp scenario through the UI - it remains verified directly
      // against the codec in card_issue_qr_codec_test.dart instead.
      expect(
        find.byType(QrImageView),
        findsNothing,
        reason: 'No QR should be generated for an out-of-range business.',
      );
      expect(find.text("New cards can't be issued"), findsOneWidget);
      expect(find.text('Fix Now'), findsOneWidget);

      await tester.tap(find.text('Fix Now'));
      await tester.pumpAndSettle();

      // The dialog defaults to business.stampsRequired clamped into
      // range - 20 clamps to the max (12), so Save works immediately
      // with no further interaction needed.
      expect(find.text('Fix Stamps Required'), findsOneWidget);
      expect(find.text('12 stamps'), findsOneWidget);

      await tester.tap(find.text('Save'));
      await tester.pump();
      for (var attempt = 0; attempt < 50; attempt++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        if (find.byType(QrImageView).evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();

      expect(
        find.byType(QrImageView),
        findsOneWidget,
        reason: 'Once reconfigured to a supported value, issuance should proceed normally.',
      );
      expect(find.text("New cards can't be issued"), findsNothing);

      // TEST-022: once reconfigured into the supported range (12), the
      // payload fits comfortably as plain JSON (measured ~2,221 of ~2,953
      // bytes) - should NOT need the compact fallback, so a customer app
      // older than TEST-021/022 can still read this QR.
      final state = tester.state(find.byType(SupplierIssueCard));
      expect(
        // ignore: avoid_dynamic_calls
        (state as dynamic).issueQrUsedCompactEncodingForTesting as bool,
        isFalse,
        reason: 'A reconfigured in-range business should use plain JSON, not the compact fallback.',
      );

      // Secure Mode starts a countdown Timer.periodic (_startCountdown) -
      // dispose the widget before the test ends so it gets cancelled,
      // otherwise flutter_test's pending-timer invariant check fails.
      await tester.pumpWidget(const SizedBox());
    },
  );

  /// TEST-022: TEST-021's original fix compact-encoded every issue-card QR
  /// unconditionally, which broke issuance for any customer app older than
  /// that fix - Base45 is never valid JSON, so a pre-TEST-021 customer app
  /// scanning ANY issuance from an updated supplier (not just a
  /// high-initial-stamp-count one) would see a generic "not a valid QR
  /// code" error. Confirmed on a real device: supplier v2.1.0+27, customer
  /// v2.0.3+23, ordinary issuance failed outright. Fixed by preferring
  /// plain JSON whenever it fits, falling back to compact encoding only
  /// for the genuine legacy edge case.
  const ordinaryBusinessId = 'business-issue-card-ordinary-test022';
  Future<void> seedOrdinaryBusiness(WidgetTester tester) async {
    await tester.runAsync(() async {
      final keyPair = await keyManager.generateKeyPair();
      await keyManager.storePrivateKey(ordinaryBusinessId, keyPair.privateKey as ECPrivateKey);
      await keyManager.storePublicKey(ordinaryBusinessId, keyPair.publicKey as ECPublicKey);
      final publicKeyEncoded = (await keyManager.getPublicKeyString(ordinaryBusinessId))!;

      await businessRepo.insertBusiness(Business(
        id: ordinaryBusinessId,
        name: 'Test Coffee Shop',
        publicKey: publicKeyEncoded,
        privateKey: 'unused-plaintext-field',
        stampsRequired: 10,
        brandColor: '#FF5733',
        mode: OperationMode.secure,
        createdAt: DateTime.now(),
      ));
    });
  }

  testWidgets(
    'TEST-022: an ordinary in-range business issues a plain-JSON QR, not compact-encoded',
    (tester) async {
      await tester.runAsync(
        () => SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_supplier_issue_card_ordinary.db'),
      );
      await seedOrdinaryBusiness(tester);

      await tester.pumpWidget(const MaterialApp(home: SupplierIssueCard()));
      await tester.pump();
      for (var attempt = 0; attempt < 50; attempt++) {
        await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
        if (find.byType(QrImageView).evaluate().isNotEmpty) break;
      }
      await tester.pumpAndSettle();

      expect(find.byType(QrImageView), findsOneWidget);

      final state = tester.state(find.byType(SupplierIssueCard));
      expect(
        // ignore: avoid_dynamic_calls
        (state as dynamic).issueQrUsedCompactEncodingForTesting as bool,
        isFalse,
        reason: 'An ordinary business well within the supported range should never need the '
            'compact fallback - readable by any customer app version, however old.',
      );

      await tester.pumpWidget(const SizedBox());
    },
  );
}
