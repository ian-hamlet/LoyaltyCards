import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart' hide Card;
import 'package:supplier_app/screens/supplier/supplier_onboarding.dart';

/// Covers the mode-selection UI added this session (v1.0.3+11) - previously
/// untested. Scoped to the mode selector, tooltip, and warning banner only;
/// doesn't submit the form (that touches BusinessRepository/KeyManager,
/// which need real device storage - out of scope for a widget test).
void main() {
  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupplierOnboarding()));
    await tester.pumpAndSettle();
  }

  // The mode radio tiles sit below the fold on the default 800x600 test
  // viewport - scroll them into view before tapping, or the tap silently
  // misses (Flutter reports a hit-test warning rather than throwing).
  Future<void> tapModeOption(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('SupplierOnboarding - mode selection', () {
    testWidgets('defaults to Express Mode (OperationMode.simple)', (tester) async {
      await pumpOnboarding(tester);

      final radioGroup = tester.widget<RadioGroup<OperationMode>>(find.byType(RadioGroup<OperationMode>));
      expect(radioGroup.groupValue, OperationMode.simple);

      // The scan-cooldown section is Simple-Mode-only - visible by default.
      expect(find.text('Customer Scan Cooldown'), findsOneWidget);
    });

    testWidgets('renders both modes with their name and recommendation text', (tester) async {
      await pumpOnboarding(tester);

      expect(find.text(OperationMode.simple.displayName), findsOneWidget);
      expect(find.text(OperationMode.simple.recommendedFor), findsOneWidget);
      expect(find.text(OperationMode.secure.displayName), findsOneWidget);
      expect(find.text(OperationMode.secure.recommendedFor), findsOneWidget);
    });

    testWidgets('tapping Secure Mode switches selection and hides the Simple-Mode-only scan cooldown section',
        (tester) async {
      await pumpOnboarding(tester);
      expect(find.text('Customer Scan Cooldown'), findsOneWidget);

      await tapModeOption(tester, find.text(OperationMode.secure.displayName));

      final radioGroup = tester.widget<RadioGroup<OperationMode>>(find.byType(RadioGroup<OperationMode>));
      expect(radioGroup.groupValue, OperationMode.secure);
      expect(find.text('Customer Scan Cooldown'), findsNothing);
    });

    testWidgets('switching back to Express Mode restores the scan cooldown section', (tester) async {
      await pumpOnboarding(tester);

      await tapModeOption(tester, find.text(OperationMode.secure.displayName));
      expect(find.text('Customer Scan Cooldown'), findsNothing);

      await tapModeOption(tester, find.text(OperationMode.simple.displayName));
      expect(find.text('Customer Scan Cooldown'), findsOneWidget);
    });

    testWidgets('shows the mode-switch warning banner regardless of selected mode', (tester) async {
      await pumpOnboarding(tester);
      const warningText =
          'Choose carefully: switching modes later requires a full business reset, which invalidates every card your customers currently hold. Tap the ⓘ above to compare the two modes, or see the full User Guide for more detail.';

      expect(find.text(warningText), findsOneWidget);

      await tapModeOption(tester, find.text(OperationMode.secure.displayName));

      expect(find.text(warningText), findsOneWidget);
    });

    testWidgets('info tooltip explains both modes when tapped', (tester) async {
      await pumpOnboarding(tester);

      // The screen also has a separate tooltip for the Simple-Mode-only
      // scan cooldown section, so find this one by its content specifically.
      final tooltipFinder = find.byWidgetPredicate(
        (widget) => widget is Tooltip && (widget.message?.contains('EXPRESS MODE') ?? false),
      );
      expect(tooltipFinder, findsOneWidget);

      final tooltip = tester.widget<Tooltip>(tooltipFinder);
      expect(tooltip.message, contains('EXPRESS MODE'));
      expect(tooltip.message, contains('SECURE MODE'));
      expect(tooltip.message, contains('cryptographically signed'));
      expect(tooltip.message, contains('cooldown you set (5-60 sec, default 30)'));
    });
  });
}
