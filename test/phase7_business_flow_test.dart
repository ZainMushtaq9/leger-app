import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/business_screen.dart';

void main() {
  group('Phase 7 business flow', () {
    test('tracks suppliers, stock, cash sales, and udhaar sales', () async {
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
        groupName: 'Family A',
      );
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(
          initialSnapshot: AppDataSnapshot(
            shops: <ShopProfile>[shop],
            customers: <Customer>[customer],
            transactions: const <LedgerTransaction>[],
            settings: AppSettings(
              shopName: shop.name,
              organizationPhone: shop.phone,
              userType: shop.userType,
              hasCompletedOnboarding: true,
              isPaidUser: false,
              lowDataMode: false,
              activeShopId: shop.id,
            ),
          ),
        ),
      );
      await controller.load();

      final supplier = await controller.saveSupplier(
        name: 'Karachi Foods',
        phone: '03211234567',
      );
      final item = await controller.saveInventoryItem(
        name: 'Tea Pack',
        stockQuantity: 5,
        reorderLevel: 3,
        costPrice: 80,
        salePrice: 120,
        supplierId: supplier.id,
      );

      await controller.recordSupplierPurchase(
        supplierId: supplier.id,
        inventoryItemId: item.id,
        quantity: 10,
        unitCost: 90,
        note: 'Restock',
      );

      expect(controller.inventoryItemById(item.id)?.stockQuantity, 15);
      expect(controller.totalSupplierPayables, 900);

      await controller.recordSupplierPayment(
        supplierId: supplier.id,
        amount: 200,
        note: 'Partial payment',
      );

      expect(controller.totalSupplierPayables, 700);

      final cashSale = await controller.recordCashSale(
        lineItems: <SaleLineItem>[
          SaleLineItem(
            inventoryItemId: item.id,
            itemName: item.name,
            quantity: 2,
            unitPrice: 120,
            costPrice: 90,
          ),
        ],
        note: 'Walk-in sale',
      );

      expect(cashSale.type, SaleRecordType.cash);
      expect(controller.inventoryItemById(item.id)?.stockQuantity, 13);
      expect(controller.saleRecords.length, 1);

      final udhaarSale = await controller.recordInventorySaleAsUdhaar(
        customerId: customer.id,
        lineItems: <SaleLineItem>[
          SaleLineItem(
            inventoryItemId: item.id,
            itemName: item.name,
            quantity: 3,
            unitPrice: 120,
            costPrice: 90,
          ),
        ],
        note: 'Family monthly sale',
      );

      expect(udhaarSale.type, SaleRecordType.udhaar);
      expect(controller.inventoryItemById(item.id)?.stockQuantity, 10);
      expect(controller.transactionsFor(customer.id).first.amount, 360);
      expect(controller.saleRecords.length, 2);
      expect(controller.groupOutstandingTotals['Family A'], 360);
    });

    testWidgets(
      'renders the business hub with inventory and supplier sections',
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
          groupName: 'Family A',
        );
        final controller = HisabRakhoController(
          repository: InMemoryLedgerRepository(
            initialSnapshot: AppDataSnapshot(
              shops: <ShopProfile>[shop],
              customers: <Customer>[customer],
              transactions: const <LedgerTransaction>[],
              settings: AppSettings(
                shopName: shop.name,
                organizationPhone: shop.phone,
                userType: shop.userType,
                hasCompletedOnboarding: true,
                isPaidUser: false,
                lowDataMode: false,
                activeShopId: shop.id,
              ),
            ),
          ),
        );
        await controller.load();
        final supplier = await controller.saveSupplier(
          name: 'Karachi Foods',
          phone: '03211234567',
        );
        await controller.saveInventoryItem(
          name: 'Tea Pack',
          stockQuantity: 5,
          reorderLevel: 3,
          costPrice: 80,
          salePrice: 120,
          supplierId: supplier.id,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BusinessScreen(
              controller: controller,
              onOpenCustomer: (_) async {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Business'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Inventory'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Inventory'), findsOneWidget);
        expect(find.text('Suppliers'), findsOneWidget);
        expect(find.text('POS sale'), findsOneWidget);
      },
    );
  });
}
