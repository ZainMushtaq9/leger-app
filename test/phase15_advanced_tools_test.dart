import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/business_screen.dart';

void main() {
  group('Phase 15 advanced tools', () {
    test(
      'supports wholesale listings, offline assistant answers, and business card output',
      () async {
        final shop = ShopProfile(
          id: 'shop-1',
          name: 'Rehmat Traders',
          phone: '03001234567',
          userType: UserType.shopkeeper,
          createdAt: DateTime(2026, 3, 1),
          address: 'Main Bazaar, Lahore',
          email: 'billing@rehmat.pk',
          tagline: 'Wholesale and ledger care',
        );
        final customer = Customer(
          id: 'customer-1',
          shopId: shop.id,
          shareCode: 'share-1',
          name: 'Usman Foods',
          phone: '03111222333',
          createdAt: DateTime(2026, 3, 1),
          promisedPaymentDate: DateTime(2026, 3, 12),
          promisedPaymentAmount: 3000,
        );
        final supplier = Supplier(
          id: 'supplier-1',
          shopId: shop.id,
          name: 'Bismillah Supply',
          phone: '03211234567',
          createdAt: DateTime(2026, 3, 1),
        );
        final item = InventoryItem(
          id: 'item-1',
          shopId: shop.id,
          name: 'Tea Cartons',
          createdAt: DateTime(2026, 3, 1),
          unit: 'carton',
          stockQuantity: 2,
          reorderLevel: 5,
          costPrice: 700,
          salePrice: 1000,
          supplierId: supplier.id,
        );
        final sale = SaleRecord(
          id: 'sale-1',
          shopId: shop.id,
          type: SaleRecordType.cash,
          date: DateTime(2026, 3, 10),
          lineItems: <SaleLineItem>[
            const SaleLineItem(
              inventoryItemId: 'item-1',
              itemName: 'Tea Cartons',
              quantity: 3,
              unitPrice: 1000,
              costPrice: 700,
            ),
          ],
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
                  amount: 12000,
                  type: TransactionType.credit,
                  note: 'Monthly groceries',
                  date: DateTime(2026, 3, 2),
                  dueDate: DateTime(2026, 3, 8),
                ),
              ],
              suppliers: <Supplier>[supplier],
              supplierLedgerEntries: <SupplierLedgerEntry>[
                SupplierLedgerEntry(
                  id: 'purchase-1',
                  shopId: shop.id,
                  supplierId: supplier.id,
                  amount: 18000,
                  type: SupplierEntryType.purchase,
                  date: DateTime(2026, 3, 3),
                ),
              ],
              inventoryItems: <InventoryItem>[item],
              saleRecords: <SaleRecord>[sale],
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

        final listing = await controller.saveWholesaleListing(
          title: 'Premium basmati rice',
          price: 5600,
          category: 'Grains',
          unit: 'bag',
          minQuantity: 5,
          phone: '03001234567',
          note: 'Fresh stock available',
        );

        expect(controller.wholesaleListings, hasLength(1));
        expect(
          controller.buildWholesaleListingShareText(listing),
          contains('Premium basmati rice'),
        );
        expect(
          controller.answerOfflineAssistantQuery('Who needs follow-up today?'),
          contains('Recovery priorities'),
        );
        expect(
          controller.answerOfflineAssistantQuery('Who needs follow-up today?'),
          contains('Usman Foods'),
        );
        expect(
          controller.answerOfflineAssistantQuery('What stock needs attention?'),
          contains('Stock watch'),
        );
        expect(
          controller.answerOfflineAssistantQuery('What stock needs attention?'),
          contains('Tea Cartons'),
        );
        expect(
          controller.answerOfflineAssistantQuery(
            'Show supplier pressure points.',
          ),
          contains('Bismillah Supply'),
        );
        expect(controller.buildBusinessCardText(), contains('Rehmat Traders'));
        expect(
          controller.buildBusinessCardText(),
          contains('Wholesale and ledger care'),
        );
        expect(controller.buildBusinessCardQrData(), contains('BEGIN:VCARD'));
      },
    );

    testWidgets('business screen exposes phase 15 tools', (tester) async {
      final shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Traders',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 3, 1),
      );
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(
          initialSnapshot: AppDataSnapshot(
            shops: <ShopProfile>[shop],
            customers: const <Customer>[],
            transactions: const <LedgerTransaction>[],
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
          home: Scaffold(
            body: BusinessScreen(
              controller: controller,
              onOpenCustomer: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Wholesale'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Wholesale'), findsOneWidget);
      expect(find.text('Business Card'), findsOneWidget);
      expect(find.text('Offline Assistant'), findsOneWidget);
    });
  });
}
