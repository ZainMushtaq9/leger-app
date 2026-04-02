import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/ui/reports_screen.dart';

void main() {
  group('Phase 11 business reporting', () {
    late ShopProfile shop;
    late Customer customer;

    AppDataSnapshot buildSnapshot() {
      shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Store',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 1, 1),
        salesTaxPercent: 18,
      );
      customer = Customer(
        id: 'customer-1',
        shopId: shop.id,
        shareCode: 'share-1',
        name: 'Usman',
        phone: '03111222333',
        createdAt: DateTime(2026, 1, 1),
        category: 'Wholesale',
      );

      return AppDataSnapshot(
        shops: <ShopProfile>[shop],
        customers: <Customer>[customer],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: customer.id,
            shopId: shop.id,
            amount: 500,
            type: TransactionType.credit,
            note: 'Tea cartons',
            date: DateTime(2026, 3, 12),
          ),
          LedgerTransaction(
            id: 'payment-1',
            customerId: customer.id,
            shopId: shop.id,
            amount: 300,
            type: TransactionType.payment,
            note: 'Cash received',
            date: DateTime(2026, 3, 14),
          ),
        ],
        saleRecords: <SaleRecord>[
          SaleRecord(
            id: 'sale-1',
            shopId: shop.id,
            type: SaleRecordType.cash,
            date: DateTime(2026, 3, 11),
            lineItems: const <SaleLineItem>[
              SaleLineItem(
                inventoryItemId: 'item-1',
                itemName: 'Tea',
                quantity: 2,
                unitPrice: 300,
                costPrice: 200,
              ),
            ],
          ),
          SaleRecord(
            id: 'sale-2',
            shopId: shop.id,
            type: SaleRecordType.udhaar,
            date: DateTime(2026, 3, 13),
            customerId: 'customer-1',
            linkedTransactionId: 'credit-1',
            lineItems: const <SaleLineItem>[
              SaleLineItem(
                inventoryItemId: 'item-1',
                itemName: 'Tea',
                quantity: 1,
                unitPrice: 300,
                costPrice: 200,
              ),
              SaleLineItem(
                inventoryItemId: 'item-2',
                itemName: 'Sugar',
                quantity: 1,
                unitPrice: 500,
                costPrice: 350,
              ),
            ],
          ),
        ],
        supplierLedgerEntries: <SupplierLedgerEntry>[
          SupplierLedgerEntry(
            id: 'supplier-purchase-1',
            shopId: shop.id,
            supplierId: 'supplier-1',
            amount: 900,
            type: SupplierEntryType.purchase,
            date: DateTime(2026, 3, 10),
            note: 'Restock',
          ),
          SupplierLedgerEntry(
            id: 'supplier-payment-1',
            shopId: shop.id,
            supplierId: 'supplier-1',
            amount: 400,
            type: SupplierEntryType.payment,
            date: DateTime(2026, 3, 15),
            note: 'Settlement',
          ),
        ],
        staffPayrollRuns: <StaffPayrollRun>[
          StaffPayrollRun(
            id: 'payroll-1',
            shopId: shop.id,
            staffId: 'staff-1',
            payType: StaffPayType.monthly,
            periodStart: DateTime(2026, 3, 1),
            periodEnd: DateTime(2026, 3, 31),
            payDate: DateTime(2026, 3, 28),
            createdAt: DateTime(2026, 3, 28),
            basePay: 1000,
            overtimePay: 200,
            advanceDeduction: 100,
            netPay: 1100,
            paidUnits: 1,
            workingHours: 208,
            overtimeHours: 8,
          ),
        ],
        settings: AppSettings(
          shopName: shop.name,
          organizationPhone: shop.phone,
          userType: UserType.shopkeeper,
          hasCompletedOnboarding: true,
          isPaidUser: true,
          lowDataMode: false,
          activeShopId: shop.id,
        ),
      );
    }

    test('calculates profit, tax, sales drilldown, and exports', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();

      final range = ReportRange(
        label: 'March window',
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 31),
      );

      final profitLoss = controller.profitLossSummaryForRange(range);
      expect(profitLoss.totalSales, closeTo(1400, 0.001));
      expect(profitLoss.cashSales, closeTo(600, 0.001));
      expect(profitLoss.udhaarSales, closeTo(800, 0.001));
      expect(profitLoss.costOfGoodsSold, closeTo(950, 0.001));
      expect(profitLoss.grossProfit, closeTo(450, 0.001));
      expect(profitLoss.payrollExpense, closeTo(1200, 0.001));
      expect(profitLoss.operatingProfit, closeTo(-750, 0.001));

      final taxSummary = controller.taxSummaryForRange(range);
      expect(taxSummary.grossSales, closeTo(1400, 0.001));
      expect(taxSummary.taxableSales, closeTo(1186.44, 0.02));
      expect(taxSummary.salesTaxAmount, closeTo(213.56, 0.02));

      expect(controller.supplierPurchasesForRange(range), 900);
      expect(controller.supplierPaymentsForRange(range), 400);
      expect(controller.balanceSheetDiscrepancyForRange(range), 0);

      final topItems = controller.topSellingItemsForRange(range);
      expect(topItems, hasLength(2));
      expect(topItems.first.itemName, 'Tea');
      expect(topItems.first.quantity, 3);
      expect(topItems.first.salesAmount, closeTo(900, 0.001));

      final weekly = controller.weeklyBusinessSummaries(
        count: 2,
        now: DateTime(2026, 3, 20),
      );
      final monthly = controller.monthlyBusinessSummaries(
        count: 2,
        now: DateTime(2026, 3, 20),
      );
      expect(weekly, hasLength(2));
      expect(monthly, hasLength(2));

      final reportDocument = controller.buildReportDocumentText(range);
      expect(reportDocument, contains('PROFIT AND LOSS'));
      expect(reportDocument, contains('TOP SELLING ITEMS'));
      expect(reportDocument, contains('TAX SUMMARY'));

      final csv = controller.exportReportCsv(range);
      expect(csv, contains('Summary,Operating Result,-750.00'));
      expect(csv, contains('Summary,Sales Tax,213.56'));
      expect(csv, contains('Item,Quantity,Sales Amount,Margin'));
    });

    testWidgets('shows phase 11 reporting sections', (tester) async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
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
        find.text('Profit and Loss'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Profit and Loss'), findsOneWidget);
      expect(find.text('Weekly and Monthly Pulse'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Sales Drilldown'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Sales Drilldown'), findsOneWidget);
    });
  });
}
