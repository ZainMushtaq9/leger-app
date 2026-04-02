import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'browser_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clicks shell, reports, business, and settings flows in Chrome', (
    tester,
  ) async {
    await pumpSeededApp(tester);

    logStep('shell-flow: quick entry');
    await tapAndSettle(tester, find.byType(FloatingActionButton));
    expect(find.text('Quick ledger entry'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Credit amount'),
      '250',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quick note'),
      'Browser quick entry',
    );
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Save Udhaar'),
    );
    expect(find.text('Quick ledger entry'), findsNothing);

    logStep('shell-flow: reports');
    await tapAndSettle(tester, find.text('Reports').last);
    await tapAndSettle(tester, find.text('7 days'));
    await scrollUntilVisible(
      tester,
      find.widgetWithText(OutlinedButton, 'Preview'),
    );
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Preview').first,
    );
    expect(find.text('Report Preview'), findsOneWidget);
    await goBack(tester);

    logStep('shell-flow: settings');
    await tapAndSettle(tester, find.byIcon(Icons.settings_rounded).last);
    await scrollUntilVisible(
      tester,
      find.widgetWithText(FilledButton, 'Checkpoint'),
    );
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Checkpoint'));

    logStep('shell-flow: home to business hub');
    await tapAndSettle(tester, find.text('Home').last);
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Business Hub'),
    );
    expect(find.text('Business'), findsWidgets);

    logStep('shell-flow: group accounts');
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Group Accounts'),
    );
    expect(find.text('Group Accounts'), findsWidgets);
    await goBack(tester);

    logStep('shell-flow: staff payroll');
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Staff & Payroll'),
    );
    expect(find.text('Staff and Payroll'), findsWidgets);
    await goBack(tester);

    logStep('shell-flow: wholesale');
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Wholesale'),
    );
    expect(find.text('Wholesale Marketplace'), findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Add offer'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Product or service'),
      'Integration Offer',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Rate'), '9500');
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Add offer').last,
    );
    expect(find.text('Integration Offer'), findsOneWidget);
    await goBack(tester);

    logStep('shell-flow: business card');
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Business Card'),
    );
    expect(find.text('Business Card'), findsWidgets);
    await goBack(tester);

    logStep('shell-flow: offline assistant');
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Offline Assistant'),
    );
    expect(find.text('Offline Assistant'), findsOneWidget);
    await tapAndSettle(tester, find.text('Who needs follow-up today?'));
    expect(find.text('You'), findsWidgets);
  });
}
