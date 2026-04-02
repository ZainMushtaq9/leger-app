import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/customer_portal_viewer_screen.dart';

void main() {
  group('Phase 14 portal and community flow', () {
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
        promisedPaymentDate: DateTime(2026, 1, 15),
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
          ),
          LedgerTransaction(
            id: 'payment-1',
            customerId: customer.id,
            shopId: shop.id,
            amount: 2500,
            type: TransactionType.payment,
            note: 'Partial recovery',
            date: DateTime(2026, 1, 5),
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
        ),
      );
    }

    test(
      'builds encoded portal links that can be reopened as a viewer payload',
      () async {
        final controller = HisabRakhoController(
          repository: InMemoryLedgerRepository(
            initialSnapshot: buildSnapshot(),
          ),
        );
        await controller.load();

        final link = controller.buildCustomerStatementLink(customer);
        final payload = controller.portalPayloadFromUri(Uri.parse(link));

        expect(payload, isNotNull);
        expect(payload!.customerName, customer.name);
        expect(payload.shopName, shop.name);
        expect(payload.entries, isNotEmpty);
        expect(payload.entries.first.label, isNotEmpty);
      },
    );

    test('stores visit location labels and coordinates', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();

      final visit = await controller.logCustomerVisit(
        customerId: customer.id,
        note: 'Visited home after shop hours',
        locationLabel: 'Nazimabad block A',
        latitude: 24.92012,
        longitude: 67.03123,
      );

      expect(
        controller.customerVisitLocationSummary(visit),
        contains('Nazimabad'),
      );
      expect(
        controller.customerVisitsFor(customer.id).first.latitude,
        24.92012,
      );
      expect(
        controller.customerVisitsFor(customer.id).first.longitude,
        67.03123,
      );
    });

    testWidgets('renders the shared portal viewer with promise tools', (
      tester,
    ) async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();
      final payload = controller.buildCustomerPortalPayload(customer);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerPortalViewerScreen(
            controller: controller,
            payload: payload,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('${customer.name} Portal'), findsOneWidget);
      expect(find.text('Statement'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Promise To Pay'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Promise To Pay'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    });
  });
}
