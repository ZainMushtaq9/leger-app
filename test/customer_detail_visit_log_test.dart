import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/customer_detail_screen.dart';

void main() {
  testWidgets('visit log sheet saves without controller disposal errors', (
    tester,
  ) async {
    final shop = ShopProfile(
      id: 'shop-1',
      name: 'Rehmat Store',
      phone: '03001234567',
      userType: UserType.shopkeeper,
      createdAt: DateTime(2026, 1, 1),
    );
    final customer = Customer(
      id: 'customer-1',
      shopId: shop.id,
      shareCode: 'share-1',
      name: 'Usman',
      phone: '03111222333',
      createdAt: DateTime(2026, 1, 1),
    );

    final controller = HisabRakhoController(
      repository: InMemoryLedgerRepository(
        initialSnapshot: AppDataSnapshot(
          shops: <ShopProfile>[shop],
          customers: <Customer>[customer],
          transactions: <LedgerTransaction>[
            LedgerTransaction(
              id: 'credit-1',
              customerId: customer.id,
              shopId: shop.id,
              amount: 4000,
              type: TransactionType.credit,
              note: 'Groceries',
              date: DateTime(2026, 1, 2),
            ),
          ],
          settings: AppSettings(
            shopName: shop.name,
            organizationPhone: shop.phone,
            userType: shop.userType,
            hasCompletedOnboarding: true,
            isPaidUser: true,
            lowDataMode: false,
            activeShopId: shop.id,
          ),
        ),
      ),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailScreen(
          controller: controller,
          customer: customer,
          adsEnabled: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Log Visit'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Log Visit'));
    await tester.pumpAndSettle();

    expect(find.text('Save Visit'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Visited customer');
    await tester.tap(find.widgetWithText(FilledButton, 'Save Visit'));
    await tester.pumpAndSettle();

    expect(controller.customerVisitsFor(customer.id), hasLength(1));
    expect(
      controller.customerVisitsFor(customer.id).first.note,
      'Visited customer',
    );
    expect(tester.takeException(), isNull);
  });
}
