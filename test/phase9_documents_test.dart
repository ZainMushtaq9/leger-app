import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/reports_screen.dart';

void main() {
  group('Phase 9 documents', () {
    test('builds branded invoice and quotation documents', () async {
      final shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Traders',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 2, 1),
        address: 'Main Bazaar, Lahore',
        email: 'billing@rehmat.pk',
        tagline: 'Wholesale and ledger care',
        ntn: '1234567-8',
        strn: '3274832748327',
        invoicePrefix: 'INV',
        quotationPrefix: 'QTN',
        salesTaxPercent: 18,
      );
      final customer = Customer(
        id: 'customer-1',
        shopId: shop.id,
        shareCode: 'share-1',
        name: 'Usman Foods',
        phone: '03111222333',
        createdAt: DateTime(2026, 2, 1),
        address: 'Shah Alam Market',
        category: 'Wholesale',
      );
      final sale = SaleRecord(
        id: 'sale01a',
        shopId: shop.id,
        type: SaleRecordType.udhaar,
        date: DateTime(2026, 2, 2, 14, 30),
        customerId: customer.id,
        linkedTransactionId: 'txn-1',
        lineItems: const <SaleLineItem>[
          SaleLineItem(
            inventoryItemId: 'inv-1',
            itemName: 'Tea Cartons',
            quantity: 4,
            unitPrice: 1250,
            costPrice: 950,
          ),
        ],
        note: 'Deliver before evening',
      );

      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(
          initialSnapshot: AppDataSnapshot(
            shops: <ShopProfile>[shop],
            customers: <Customer>[customer],
            transactions: <LedgerTransaction>[
              LedgerTransaction(
                id: 'txn-1',
                customerId: customer.id,
                shopId: shop.id,
                amount: 5000,
                type: TransactionType.credit,
                note: 'POS sale converted to udhaar',
                date: DateTime(2026, 2, 2, 14, 30),
                dueDate: DateTime(2026, 2, 10),
              ),
            ],
            saleRecords: <SaleRecord>[sale],
            settings: const AppSettings(
              shopName: 'Rehmat Traders',
              organizationPhone: '03001234567',
              userType: UserType.shopkeeper,
              hasCompletedOnboarding: true,
              isPaidUser: true,
              lowDataMode: false,
              activeShopId: 'shop-1',
            ),
          ),
        ),
      );
      await controller.load();

      final invoice = controller.buildSaleInvoiceDocument(sale);
      expect(invoice, contains('SALES INVOICE'));
      expect(invoice, contains('Rehmat Traders'));
      expect(invoice, contains('Wholesale and ledger care'));
      expect(invoice, contains('Main Bazaar, Lahore'));
      expect(invoice, contains('billing@rehmat.pk'));
      expect(invoice, contains('NTN: 1234567-8'));
      expect(invoice, contains('STRN: 3274832748327'));
      expect(invoice, contains('Invoice No: INV-20260202-SALE01'));
      expect(invoice, contains('Customer: Usman Foods'));
      expect(invoice, contains('Tea Cartons'));
      expect(invoice, contains('GST 18% (included)'));
      expect(invoice, contains('Grand total: Rs 5,000'));

      final quotation = controller.buildQuotationDocument(
        customer: customer,
        lineItems: sale.lineItems,
        note: 'Delivery within 24 hours',
        issuedAt: DateTime(2026, 2, 3, 9, 45),
        validDays: 10,
      );
      expect(quotation, contains('QUOTATION / ESTIMATE'));
      expect(quotation, contains('Quotation No: QTN-20260203-0945'));
      expect(quotation, contains('Valid until: 13 Feb'));
      expect(quotation, contains('Customer: Usman Foods'));
      expect(quotation, contains('Quoted total: Rs 5,000'));
      expect(quotation, contains('Delivery within 24 hours'));
    });

    testWidgets('shows document tools in reports', (tester) async {
      final shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Traders',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 2, 1),
        invoicePrefix: 'INV',
        quotationPrefix: 'QTN',
      );
      final customer = Customer(
        id: 'customer-1',
        shopId: shop.id,
        shareCode: 'share-1',
        name: 'Usman Foods',
        phone: '03111222333',
        createdAt: DateTime(2026, 2, 1),
      );
      final sale = SaleRecord(
        id: 'sale01a',
        shopId: shop.id,
        type: SaleRecordType.cash,
        date: DateTime(2026, 2, 2, 14, 30),
        customerId: customer.id,
        lineItems: const <SaleLineItem>[
          SaleLineItem(
            inventoryItemId: 'inv-1',
            itemName: 'Tea Cartons',
            quantity: 4,
            unitPrice: 1250,
            costPrice: 950,
          ),
        ],
      );

      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(
          initialSnapshot: AppDataSnapshot(
            shops: <ShopProfile>[shop],
            customers: <Customer>[customer],
            transactions: const <LedgerTransaction>[],
            saleRecords: <SaleRecord>[sale],
            settings: const AppSettings(
              shopName: 'Rehmat Traders',
              organizationPhone: '03001234567',
              userType: UserType.shopkeeper,
              hasCompletedOnboarding: true,
              isPaidUser: true,
              lowDataMode: false,
              activeShopId: 'shop-1',
            ),
          ),
        ),
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportsScreen(
              controller: controller,
              adsEnabled: false,
              onOpenCustomer: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Invoices and Quotations'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Invoices and Quotations'), findsOneWidget);
      expect(find.text('New Quotation'), findsOneWidget);
      expect(find.text('Usman Foods', skipOffstage: false), findsOneWidget);
    });
  });
}
