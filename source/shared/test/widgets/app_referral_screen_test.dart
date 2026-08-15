import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

/// CRASH-001-style regression test for AppReferralScreen's Share button -
/// used by every companion-app/friend referral flow across both apps. Same
/// interception approach as the supplier app's print/share guard tests (see
/// docs/project-management/CRASH-001-stamp-print-race-condition.md): mock
/// share_plus's method channel to count native calls, then fire the guarded
/// handler twice back-to-back - the shape of a fast double-tap - and confirm
/// only one native call goes out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');

  late int shareCallCount;

  Widget buildScreen() {
    return const MaterialApp(
      home: AppReferralScreen(
        appBarTitle: 'Tell a Friend',
        appBarColor: Color(0xFF673AB7),
        icon: Icons.people_outline,
        headline: "Know someone who'd like this?",
        bodyText: 'Show them this code to get the app.',
        qrData: 'https://apple.co/example',
        shareText: 'Get the app: https://apple.co/example',
        errorTag: 'TestReferral',
      ),
    );
  }

  setUp(() {
    shareCallCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      shareChannel,
      (call) async {
        if (call.method == 'share') {
          shareCallCount++;
          // Real async gap so the test can observe the button's disabled
          // state before the share resolves - an instant mock response
          // completes the whole guarded call inside runAsync before pump()
          // ever runs, hiding the intermediate disabled state from the test.
          await Future.delayed(const Duration(milliseconds: 30));
          return 'dev.fluttercommunity.plus/share/completed';
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, null);
  });

  testWidgets('shows the headline, QR code, and share button', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text("Know someone who'd like this?"), findsOneWidget);
    expect(find.text('Share the Link'), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);
  });

  testWidgets(
    'CRASH-001 lesson applied: guarded _share disables the button and ignores a second call',
    (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final shareButtonFinder = find.widgetWithText(ElevatedButton, 'Share the Link');
      expect(shareButtonFinder, findsOneWidget);
      expect(tester.widget<ElevatedButton>(shareButtonFinder).onPressed, isNotNull);

      final state = tester.state(find.byType(AppReferralScreen));
      late Future<void> firstCall;
      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        firstCall = (state as dynamic).shareForTesting() as Future<void>;
      });
      await tester.pump();

      expect(
        tester.widget<ElevatedButton>(shareButtonFinder).onPressed,
        isNull,
        reason: 'Share button should disable itself immediately once a share '
            'is in flight, so a rapid second tap cannot reach onPressed at all.',
      );

      await tester.runAsync(() async {
        // ignore: avoid_dynamic_calls
        final secondCall = (state as dynamic).shareForTesting() as Future<void>;
        await Future.wait([firstCall, secondCall]);
      });
      await tester.pumpAndSettle();

      expect(
        shareCallCount,
        1,
        reason: 'Only one native share call should fire despite two rapid calls.',
      );
      expect(
        tester.widget<ElevatedButton>(shareButtonFinder).onPressed,
        isNotNull,
        reason: 'Share button should re-enable once the share sheet opens.',
      );
    },
  );
}
