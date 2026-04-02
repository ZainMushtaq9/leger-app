import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'browser_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('clicks major customer and recovery flows in Chrome', (
    tester,
  ) async {
    await pumpSeededApp(tester);
    logStep('customer-flow: home');

    expect(find.text('Test General Store'), findsOneWidget);
    expect(find.text('Quick Backup'), findsOneWidget);

    logStep('customer-flow: reminder inbox');
    await tapAndSettle(tester, find.byIcon(Icons.notifications_none_rounded));
    expect(find.text('Reminder Inbox'), findsOneWidget);
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Done').first,
    );
    expect(find.text('Handled'), findsOneWidget);
    await goBack(tester);

    logStep('customer-flow: customer tab');
    await tapAndSettle(tester, find.text('Customers').last);
    expect(find.text('Ali Raza'), findsWidgets);
    await tapAndSettle(tester, find.text('Ali Raza').first);

    logStep('customer-flow: reminder composer');
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Compose Reminder'),
    );
    expect(find.text('Reminder Composer'), findsOneWidget);
    await tapAndSettle(tester, find.text('SMS'));
    await tapAndSettle(tester, find.text('Name'));
    await goBack(tester);

    logStep('customer-flow: installment planner');
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Installment Plan'),
    );
    expect(find.text('Installment Planner'), findsOneWidget);
    await tapAndSettle(tester, find.widgetWithText(OutlinedButton, 'Pause'));
    await tapAndSettle(tester, find.widgetWithText(OutlinedButton, 'Resume'));
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Record installment'),
    );
    expect(find.textContaining('2/4'), findsWidgets);
    await goBack(tester);

    logStep('customer-flow: visit log');
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Log Visit'));
    await tester.enterText(
      find.widgetWithText(TextField, 'Visit note'),
      'Browser integration visit',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Location label'),
      'Market lane',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Latitude'),
      '24.8607',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Longitude'),
      '67.0011',
    );
    await tapAndSettle(tester, find.widgetWithText(FilledButton, 'Save Visit'));
    expect(find.textContaining('Browser integration visit'), findsWidgets);

    logStep('customer-flow: portal');
    await scrollUntilVisible(tester, find.text('Portal & QR'));
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Portal & QR'),
    );
    expect(find.text('Customer Portal Access'), findsOneWidget);
    await goBack(tester);

    logStep('customer-flow: negotiation');
    await scrollUntilVisible(tester, find.text('Negotiation'));
    await tapAndSettle(
      tester,
      find.widgetWithText(OutlinedButton, 'Negotiation'),
    );
    expect(find.text('Negotiation Helper'), findsOneWidget);
    await goBack(tester);

    logStep('customer-flow: community blacklist');
    await scrollUntilVisible(
      tester,
      find.textContaining('Community Blacklist'),
    );
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Community Blacklist (1)'),
    );
    expect(find.text('Community Blacklist'), findsOneWidget);
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Report This Customer'),
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Reason'),
      'Integration test risk note',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Note'),
      'Saved during Chrome integration flow.',
    );
    await tapAndSettle(
      tester,
      find.widgetWithText(FilledButton, 'Save Report'),
    );
    expect(find.textContaining('2 matching community report'), findsOneWidget);
  });
}
