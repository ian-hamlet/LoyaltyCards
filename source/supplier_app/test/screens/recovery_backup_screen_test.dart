import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:supplier_app/screens/supplier/recovery_backup_screen.dart';
import 'package:supplier_app/services/key_manager.dart';

/// CRASH-001 regression test (wider-audit fix) for the Recovery Backup
/// screen's Print Backup / Share via Email / Save to Files buttons - the
/// same unguarded-button gap as the original Stamp Setup crash, found by
/// auditing every call site of BackupStorageService's print/share/save
/// methods. See docs/project-management/CRASH-001-stamp-print-race-condition.md.
///
/// Same method-channel-interception approach as the other CRASH-001 tests.
/// This screen additionally requires biometric authentication before it
/// generates a backup at all (RecoveryBackupScreen._authenticateAndGenerate,
/// called from initState) - under flutter_test, local_auth's platform
/// implementations never get registered (no native plugin registration
/// happens in the test embedder), so LocalAuthPlatform.instance falls back
/// to DefaultLocalAuthPlatform, a plain MethodChannel
/// ('plugins.flutter.io/local_auth') - mocked below to report biometrics
/// available and authentication successful, otherwise the screen would
/// always pop itself before any button under test ever appears.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const printingChannel = MethodChannel('net.nfet.printing');
  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
  const businessId = 'business-recovery-backup-test';

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
        if (call.method == 'getTemporaryDirectory' ||
            call.method == 'getApplicationDocumentsDirectory') {
          return Directory.systemTemp.path;
        }
        return null;
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      localAuthChannel,
      (call) async {
        switch (call.method) {
          case 'getAvailableBiometrics':
            return <String>['fingerprint'];
          case 'isDeviceSupported':
            return true;
          case 'authenticate':
            return true;
          default:
            return null;
        }
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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(localAuthChannel, null);
  });

  /// RecoveryBackupScreen._generateBackup() reads the private key straight
  /// from secure storage via KeyManager - the Business passed to the widget
  /// doesn't need real key material in its own fields (mirrors the
  /// 'unused-plaintext-field' convention already used in the other
  /// CRASH-001 tests), only the secure-storage entry keyed by business id
  /// matters.
  Future<Business> seedBusiness(WidgetTester tester) async {
    final business = await tester.runAsync(() async {
      final keyPair = await keyManager.generateKeyPair();
      await keyManager.storePrivateKey(businessId, keyPair.privateKey as ECPrivateKey);
      await keyManager.storePublicKey(businessId, keyPair.publicKey as ECPublicKey);
      final publicKeyEncoded = (await keyManager.getPublicKeyString(businessId))!;

      return Business(
        id: businessId,
        name: 'Test Coffee Shop',
        publicKey: publicKeyEncoded,
        privateKey: 'unused-plaintext-field',
        stampsRequired: 10,
        brandColor: '#FF5733',
        mode: OperationMode.simple,
        createdAt: DateTime.now(),
      );
    });
    return business!;
  }

  /// Waits out both the biometric-auth round trip and backup generation
  /// (QR canvas painting) that initState() kicks off - see
  /// supplier_stamp_card_test.dart's settleAfterMount for why this polls
  /// for the actual signal (Print Backup appearing) rather than using one
  /// fixed delay.
  Future<void> settleAfterMount(WidgetTester tester) async {
    await tester.pump();
    for (var attempt = 0; attempt < 50; attempt++) {
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      if (find.text('Print Backup').evaluate().isNotEmpty) break;
    }
    await tester.pumpAndSettle();
  }

  /// The three storage options are ListTiles (via _buildStorageOption), not
  /// buttons with an `onPressed` getter - the disabled state lives on the
  /// ListTile's `onTap`.
  ListTile storageOptionFor(WidgetTester tester, String title) {
    final finder = find.ancestor(
      of: find.text(title),
      matching: find.byType(ListTile),
    );
    expect(finder, findsOneWidget);
    return tester.widget<ListTile>(finder);
  }

  /// _buildStorageOption's Container applies a background color/border
  /// directly around each ListTile, which triggers a pre-existing (and
  /// unrelated to CRASH-001) Flutter framework assertion about ink splashes
  /// being potentially invisible. Consumes it the same way
  /// supplier_redeem_card_test.dart consumes its screen's known, pre-existing
  /// RenderFlex overflow - anything else still fails the test.
  ///
  /// IMPORTANT: when several exceptions land in the same pump, Flutter
  /// coalesces them into one "Multiple exceptions (N) were detected"
  /// wrapper - matching on that phrase alone (without checking what's
  /// bundled inside it) would silently swallow a real `expect()` failure
  /// riding along with genuine ListTile warnings (confirmed by hand: a
  /// deliberately-broken assertion elsewhere in a test got hidden this way
  /// until the `Expected:`/`TestFailure` markers were checked for below).
  /// A real assertion failure's message always contains one of those
  /// markers; the ListTile warning's message never does.
  void consumeKnownListTileWarning(WidgetTester tester) {
    final exception = tester.takeException();
    if (exception == null) return;
    final message = exception.toString();
    final looksLikeARealTestFailure =
        message.contains('TestFailure') || message.contains('Expected:');
    final isKnownWarning = !looksLikeARealTestFailure &&
        (message.contains(
              'ListTile background color or ink splashes may be invisible',
            ) ||
            RegExp(r'Multiple exceptions \(\d+\) were detected').hasMatch(message));
    expect(
      isKnownWarning,
      isTrue,
      reason: 'Only the known ListTile/DecoratedBox background-color warning '
          '(pre-existing, unrelated to CRASH-001) should occur here - any '
          'other exception is a real, new failure. Got: $message',
    );
  }

  testWidgets(
    'first frame shows the loading indicator, not a premature backup body',
    (tester) async {
      // Deliberately no settleAfterMount() here - this test is specifically
      // about the frame that renders immediately after pumpWidget(), before
      // initState()'s async authenticate-then-generate work has had any
      // chance to resolve. Regression test for a bug where _isGenerating
      // started false: that first frame rendered assuming _backup already
      // existed, instead of showing the loading state that was already
      // genuinely in flight underneath.
      final business = await seedBusiness(tester);

      await tester.pumpWidget(MaterialApp(home: RecoveryBackupScreen(business: business)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Let the pending auth/generate work and its timers finish before the
      // next test's setUp() tears down the mocks it depends on.
      await settleAfterMount(tester);
      consumeKnownListTileWarning(tester);
    },
  );

  testWidgets(
    'CRASH-001: guarded _printBackup disables Print Backup and ignores a second call',
    (tester) async {
      final business = await seedBusiness(tester);

      await tester.pumpWidget(MaterialApp(home: RecoveryBackupScreen(business: business)));
      await settleAfterMount(tester);
      consumeKnownListTileWarning(tester);

      expect(storageOptionFor(tester, 'Print Backup').onTap, isNotNull);

      final state = tester.state(find.byType(RecoveryBackupScreen));
      late Future<void> firstCall;
      late bool isPrintingRightAfterStart;
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        firstCall = (state as dynamic).printBackupForTesting() as Future<void>;
        // The synchronous setState(_isPrinting = true) inside _printBackup()
        // has already run by the time control returns here (right after its
        // first internal await) - checking the flag directly avoids relying
        // on how much real async time the native call underneath happens to
        // take before the widget rebuilds. Only capture the value here -
        // NEVER call expect() inside a runAsync callback: a failure there is
        // recorded via the binding's single pending-exception slot rather
        // than thrown normally, and a later, unrelated exception (this
        // screen's known ListTile warning, further down) can silently
        // overwrite that slot before anything ever reports it - confirmed by
        // hand, this exact mistake let a broken guard pass silently.
        // ignore: avoid_dynamic_calls
        isPrintingRightAfterStart = (state as dynamic).isPrintingForTesting as bool;
      });
      expect(isPrintingRightAfterStart, isTrue);

      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        final secondCall = (state as dynamic).printBackupForTesting() as Future<void>;
        await Future.wait([firstCall, secondCall]);
      });
      await tester.pumpAndSettle();
      consumeKnownListTileWarning(tester);

      expect(
        printPdfCallCount,
        1,
        reason: 'The _isPrinting guard should reject the second call outright, '
            'so the native printing plugin should only ever be asked to start '
            'one print job.',
      );
      // ignore: avoid_dynamic_calls
      expect((state as dynamic).isPrintingForTesting as bool, isFalse);
      expect(storageOptionFor(tester, 'Print Backup').onTap, isNotNull);
    },
  );

  testWidgets(
    'CRASH-001: guarded _shareViaEmail disables Share via Email and ignores a second call',
    (tester) async {
      final business = await seedBusiness(tester);

      await tester.pumpWidget(MaterialApp(home: RecoveryBackupScreen(business: business)));
      await settleAfterMount(tester);
      consumeKnownListTileWarning(tester);

      expect(storageOptionFor(tester, 'Share via Email').onTap, isNotNull);

      final state = tester.state(find.byType(RecoveryBackupScreen));
      late Future<void> firstCall;
      late bool isSharingRightAfterStart;
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        firstCall = (state as dynamic).shareViaEmailForTesting() as Future<void>;
        // See the Print Backup test above for why this is captured here
        // rather than asserted with expect() inside this callback.
        // ignore: avoid_dynamic_calls
        isSharingRightAfterStart = (state as dynamic).isSharingEmailForTesting as bool;
      });
      expect(isSharingRightAfterStart, isTrue);

      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        final secondCall = (state as dynamic).shareViaEmailForTesting() as Future<void>;
        await Future.wait([firstCall, secondCall]);
      });
      await tester.pumpAndSettle();
      consumeKnownListTileWarning(tester);

      expect(
        shareCallCount,
        1,
        reason: 'The _isSharingEmail guard should reject the second call '
            'outright, so the native share_plus plugin should only ever be '
            'asked to open one share sheet.',
      );
      // ignore: avoid_dynamic_calls
      expect((state as dynamic).isSharingEmailForTesting as bool, isFalse);
      expect(storageOptionFor(tester, 'Share via Email').onTap, isNotNull);
    },
  );

  testWidgets(
    'CRASH-001: guarded _saveToFiles disables Save to Files and ignores a second call',
    (tester) async {
      final business = await seedBusiness(tester);

      await tester.pumpWidget(MaterialApp(home: RecoveryBackupScreen(business: business)));
      await settleAfterMount(tester);
      consumeKnownListTileWarning(tester);

      expect(storageOptionFor(tester, 'Save to Files').onTap, isNotNull);

      final state = tester.state(find.byType(RecoveryBackupScreen));
      late Future<void> firstCall;
      late bool isSavingRightAfterStart;
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        firstCall = (state as dynamic).saveToFilesForTesting() as Future<void>;
        // See the Print Backup test above for why this is captured here
        // rather than asserted with expect() inside this callback.
        // ignore: avoid_dynamic_calls
        isSavingRightAfterStart = (state as dynamic).isSavingToFilesForTesting as bool;
      });
      expect(isSavingRightAfterStart, isTrue);

      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        final secondCall = (state as dynamic).saveToFilesForTesting() as Future<void>;
        await Future.wait([firstCall, secondCall]);
      });
      await tester.pumpAndSettle();
      consumeKnownListTileWarning(tester);

      // Note: unlike Print Backup / Share via Email, this handler's native
      // call can't be counted here - BackupStorageService.saveToFiles()
      // throws synchronously on any platform that isn't iOS or Android
      // (which is all a `flutter test` host ever is), so it never reaches
      // Share.shareXFiles() regardless of the guard. The guard's engagement
      // is proven directly via isSavingToFilesForTesting above instead.
      // ignore: avoid_dynamic_calls
      expect((state as dynamic).isSavingToFilesForTesting as bool, isFalse);
      expect(storageOptionFor(tester, 'Save to Files').onTap, isNotNull);
    },
  );
}
