import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pointycastle/export.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supplier_app/screens/supplier/supplier_stamp_card.dart';
import 'package:supplier_app/services/business_repository.dart';
import 'package:supplier_app/services/key_manager.dart';
import 'package:supplier_app/services/supplier_database_helper.dart';

/// CRASH-001 regression test.
///
/// Apple reported a production EXC_BAD_ACCESS crash inside the `printing`
/// plugin's native print-preview page-count query (CGPDFDocumentGetNumberOfPages),
/// most plausibly triggered by a double-tap on the Stamp Setup screen's
/// unguarded "Print" button firing two concurrent `Printing.layoutPdf()`
/// calls. See docs/project-management/CRASH-001-stamp-print-race-condition.md
/// for the full crash report and root cause analysis.
///
/// Reproducing the actual native race isn't feasible in `flutter_test` (it
/// requires real UIKit/CoreGraphics on-device timing). Instead, this test
/// proves the *mechanism* directly: it intercepts the `printing` plugin's
/// method channel (`net.nfet.printing`) to count how many times the native
/// side is asked to start a print job (`printPdf`), then calls the screen's
/// print handler twice back-to-back without awaiting the first - exactly
/// the shape of a fast double-tap, minus needing real frame/gesture timing
/// to force it. Without the `_isPrinting` guard, both calls reach
/// `Printing.layoutPdf()` and `printPdf` fires twice (the concurrent-print-job
/// race that crashed on-device); with the guard, the second call is a no-op
/// and `printPdf` fires exactly once.
///
/// Fake MobileScannerPlatform so the widget can mount under `flutter_test`
/// without a real camera platform channel. Simple Mode (tested here) never
/// actually builds a MobileScanner widget, but the controller is constructed
/// unconditionally in State - mirrors supplier_redeem_card_test.dart's own
/// fixture (and mobile_scanner's own widget test fixture) for consistency.
class _FakeMobileScannerPlatform extends MobileScannerPlatform {
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();

  @override
  Stream<TorchState> get torchStateStream => Stream.value(TorchState.unavailable);

  @override
  Stream<double> get zoomScaleStateStream => Stream.value(1);

  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) {
    return Future.value(const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(200, 200),
      numberOfCameras: 1,
    ));
  }

  @override
  Widget buildCameraView() => const SizedBox.square(dimension: 100);

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  MobileScannerPlatform.instance = _FakeMobileScannerPlatform();

  const printingChannel = MethodChannel('net.nfet.printing');
  const businessId = 'business-stamp-print-test';

  late KeyManager keyManager;
  late BusinessRepository businessRepo;
  late int printPdfCallCount;
  late Set<int> completedJobIndices;

  /// Echoes back the `onCompleted` message the real `printing` plugin sends
  /// natively once a print job finishes, so `Printing.layoutPdf()`'s Future
  /// (and therefore `_printToken()`) actually resolves instead of hanging
  /// forever - without this, the job's internal Completer never completes.
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
    completedJobIndices = {};

    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({});
    // supplier_stamp_card.dart's _loadRotationPreference() calls the legacy
    // SharedPreferences.getInstance() facade - without this it hangs forever
    // under flutter_test waiting on an unmocked platform channel.
    SharedPreferences.setMockInitialValues({});
    await SupplierDatabaseHelper.resetForTesting(testDatabaseName: 'test_supplier_stamp_card.db');
    keyManager = KeyManager();
    businessRepo = BusinessRepository();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      printingChannel,
      (call) async {
        if (call.method == 'printPdf') {
          printPdfCallCount++;
          final jobIndex = call.arguments['job'] as int;
          // Real device: native takes real, non-zero time to set up the
          // print job/preview before signaling completion - that window is
          // exactly what CRASH-001's race lives in. A short delay here
          // (rather than completing inline) keeps both calls genuinely
          // in flight at once when the guard is bypassed.
          unawaited(
            Future.delayed(const Duration(milliseconds: 30), () => completeJob(jobIndex)),
          );
          return jobIndex;
        }
        return null;
      },
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(printingChannel, null);
  });

  /// Mirrors supplier_redeem_card_test.dart's setupBusiness(): real I/O
  /// (secure storage key generation/storage, DB insert) needs a real,
  /// non-fake-async zone to actually resolve under flutter_test.
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

  /// SupplierStampCard.initState() kicks off its own real I/O (business
  /// load, then - for Simple Mode - an auto QR-token generation involving
  /// secure-storage signing) that a plain pumpAndSettle() can't observe
  /// completing. A fixed real-time delay here is exactly the kind of
  /// flakiness this codebase has hit before: it passes in isolation but
  /// falls short (leaving _stampToken still null) once the full suite runs
  /// several test files' worth of concurrent I/O and the same wall-clock
  /// budget no longer covers it (confirmed: 500ms was enough alone, not
  /// under `flutter test`'s full-suite concurrency). Poll for the actual
  /// signal - the Print button existing, i.e. _stampToken is set - giving
  /// real wall-clock time between checks, instead of gambling on one fixed
  /// wait being long enough regardless of system load.
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
    'CRASH-001: guarded _printToken ignores a second call fired before the first completes',
    (tester) async {
      await seedSimpleModeBusiness(tester);

      await tester.pumpWidget(const MaterialApp(home: SupplierStampCard()));
      await settleAfterMount(tester);

      // Simple Mode auto-generates the QR token on load - the Print button
      // should now be present and enabled.
      expect(find.text('Print'), findsOneWidget);

      final state = tester.state(find.byType(SupplierStampCard));
      // Both calls - not just the await on them - must be made inside
      // runAsync: _printToken()'s chain does real (non-fake-clock) engine
      // work (QR canvas painting, image encoding) that never progresses if
      // started from the surrounding fake-async test zone. Not awaited
      // back-to-back: this is the exact shape of a fast double-tap - the
      // second call fires before the first call's Printing.layoutPdf() has
      // resolved.
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        final firstCall = (state as dynamic).printTokenForTesting() as Future<void>;
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
            'one print job - this is the exact concurrent-job race CRASH-001 '
            'crashed on. If this is 2, the guard was bypassed or removed.',
      );
    },
  );

  testWidgets(
    'CRASH-001: Print button disables itself while a print job is in flight',
    (tester) async {
      await seedSimpleModeBusiness(tester);

      await tester.pumpWidget(const MaterialApp(home: SupplierStampCard()));
      await settleAfterMount(tester);

      final printButtonFinder = find.widgetWithText(OutlinedButton, 'Print');
      expect(printButtonFinder, findsOneWidget);
      expect(tester.widget<OutlinedButton>(printButtonFinder).onPressed, isNotNull);

      final state = tester.state(find.byType(SupplierStampCard));
      // Started inside runAsync (see the other test for why), but not
      // awaited to completion here - the goal is just to observe the
      // synchronous setState(_isPrinting = true) that happens before
      // _printToken()'s first await, which runs regardless of which zone
      // started the call.
      late Future<void> printFuture;
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        printFuture = (state as dynamic).printTokenForTesting() as Future<void>;
      });
      await tester.pump();

      expect(
        tester.widget<OutlinedButton>(printButtonFinder).onPressed,
        isNull,
        reason: 'Print button should disable itself immediately once a print '
            'job starts, so a rapid second tap cannot reach onPressed at all.',
      );

      await tester.runAsync(() => printFuture);
      await tester.pumpAndSettle();

      expect(
        tester.widget<OutlinedButton>(printButtonFinder).onPressed,
        isNotNull,
        reason: 'Print button should re-enable once the print job completes.',
      );
    },
  );
}
