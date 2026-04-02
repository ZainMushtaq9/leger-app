import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/customer_portal_screen.dart';
import 'package:hisab_rakho/src/ui/receipt_scan_screen.dart';

void main() {
  group('Phase 8 access and risk tools', () {
    late ShopProfile shop;
    late Customer customer;

    AppDataSnapshot buildSnapshot() {
      shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Store',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 1, 1),
      );
      customer = Customer(
        id: 'customer-1',
        shopId: shop.id,
        shareCode: 'share-1',
        name: 'Usman',
        phone: '03111222333',
        createdAt: DateTime(2026, 1, 1),
        city: 'Karachi',
        cnic: '42101-1234567-1',
        promisedPaymentDate: DateTime(2026, 1, 12),
        promisedPaymentAmount: 3000,
      );

      return AppDataSnapshot(
        shops: <ShopProfile>[shop],
        customers: <Customer>[customer],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: customer.id,
            shopId: shop.id,
            amount: 12000,
            type: TransactionType.credit,
            note: 'Monthly groceries',
            date: DateTime(2026, 1, 2),
            dueDate: DateTime(2026, 1, 10),
          ),
        ],
        settings: AppSettings(
          shopName: shop.name,
          organizationPhone: shop.phone,
          userType: shop.userType,
          hasCompletedOnboarding: true,
          isPaidUser: false,
          lowDataMode: false,
          activeShopId: shop.id,
          communityBlacklistEnabled: true,
        ),
        customerVisits: <CustomerVisit>[
          CustomerVisit(
            id: 'visit-1',
            customerId: customer.id,
            visitedAt: DateTime(2026, 1, 11, 10),
            note: 'Customer requested one more week',
          ),
        ],
      );
    }

    test(
      'persists community blacklist reports and matches customer data',
      () async {
        final controller = HisabRakhoController(
          repository: InMemoryLedgerRepository(
            initialSnapshot: buildSnapshot(),
          ),
        );
        await controller.load();

        final entry = await controller.reportCustomerToCommunityBlacklist(
          customerId: customer.id,
          reason: 'Repeated broken promises',
          note: 'Stopped answering after due date',
          riskLevel: CommunityRiskLevel.blacklist,
        );

        expect(entry.customerName, customer.name);
        expect(controller.communityBlacklistCount, 1);
        expect(
          controller.communityBlacklistMatchesForCustomer(customer.id),
          hasLength(1),
        );
        expect(
          controller.searchCommunityBlacklist(query: customer.phone),
          hasLength(1),
        );
        expect(
          controller.searchCommunityBlacklist(city: 'Karachi'),
          isNotEmpty,
        );
        expect(
          controller.searchCommunityBlacklist(
            riskLevel: CommunityRiskLevel.blacklist,
          ),
          hasLength(1),
        );
        expect(
          controller.buildBackupExport().rawJson,
          contains('"communityBlacklistEntries"'),
        );
      },
    );

    test(
      'builds portal summary and negotiation script from live customer data',
      () async {
        final controller = HisabRakhoController(
          repository: InMemoryLedgerRepository(
            initialSnapshot: buildSnapshot(),
          ),
        );
        await controller.load();

        final portalSummary = controller.buildCustomerPortalSummary(customer);
        final script = controller.buildNegotiationScript(customer);

        expect(portalSummary, contains('Portal access summary'));
        expect(portalSummary, contains(customer.name));
        expect(portalSummary, contains('Portal link:'));
        expect(script, contains('Negotiation playbook'));
        expect(script, contains('Today ask'));
        expect(script, contains('Latest visit:'));
        expect(script, contains('Recommended tone'));
        expect(script, contains('Hello ${customer.name}'));
      },
    );

    testWidgets('renders portal tools for the selected customer', (
      tester,
    ) async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerPortalScreen(
            controller: controller,
            customer: customer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('${customer.name} Portal'), findsOneWidget);
      expect(find.text('Customer Portal Access'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Share Portal Summary'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Share Portal Summary'), findsOneWidget);
      expect(find.text('Portal Summary'), findsOneWidget);
    });

    testWidgets('parses receipt text into editable fields', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ReceiptScanScreen()));

      await tester.enterText(
        find.widgetWithText(TextField, 'Scanned text'),
        'Customer: Usman\nPhone: 03111222333\nRs 1,250\n2026-01-12',
      );
      await tester.tap(find.text('Parse Text'));
      await tester.pumpAndSettle();

      final parsedValues = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((widget) => widget.controller.text)
          .toList();

      expect(parsedValues, contains('Usman'));
      expect(parsedValues, contains('03111222333'));
      expect(parsedValues, contains('1250'));
      await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Detected date'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final lowerParsedValues = tester
          .widgetList<EditableText>(find.byType(EditableText))
          .map((widget) => widget.controller.text)
          .toList();

      expect(lowerParsedValues, contains('12/01/2026'));
      expect(find.text('Receipt scan import'), findsOneWidget);
    });
  });
}
