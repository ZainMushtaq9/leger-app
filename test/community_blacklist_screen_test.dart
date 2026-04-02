import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/community_blacklist_screen.dart';

void main() {
  testWidgets(
    'community report sheet saves without controller disposal errors',
    (tester) async {
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
        city: 'Karachi',
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
              communityBlacklistEnabled: true,
            ),
          ),
        ),
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: CommunityBlacklistScreen(
            controller: controller,
            customer: customer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, 'Report This Customer'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save Report'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Reason'),
        'Repeated broken promises',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Note'),
        'Saved from regression test',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Save Report'));
      await tester.pumpAndSettle();

      expect(controller.communityBlacklistCount, 1);
      expect(
        controller.communityBlacklistMatchesForCustomer(customer.id),
        hasLength(1),
      );
      expect(
        controller
            .communityBlacklistMatchesForCustomer(customer.id)
            .first
            .reason,
        'Repeated broken promises',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
