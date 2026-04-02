import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  group('Phase 4 report exports', () {
    test('builds period balances and CSV exports', () async {
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
        category: 'Wholesale',
      );
      final snapshot = AppDataSnapshot(
        shops: <ShopProfile>[shop],
        customers: <Customer>[customer],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-before',
            customerId: customer.id,
            shopId: shop.id,
            amount: 1000,
            type: TransactionType.credit,
            note: 'Opening stock',
            date: DateTime(2026, 1, 1),
          ),
          LedgerTransaction(
            id: 'payment-before',
            customerId: customer.id,
            shopId: shop.id,
            amount: 200,
            type: TransactionType.payment,
            note: 'Opening payment',
            date: DateTime(2026, 1, 2),
          ),
          LedgerTransaction(
            id: 'credit-range',
            customerId: customer.id,
            shopId: shop.id,
            amount: 500,
            type: TransactionType.credit,
            note: 'Tea cartons',
            date: DateTime(2026, 1, 10),
          ),
          LedgerTransaction(
            id: 'payment-range',
            customerId: customer.id,
            shopId: shop.id,
            amount: 300,
            type: TransactionType.payment,
            note: 'Cash received',
            date: DateTime(2026, 1, 12),
          ),
        ],
        settings: const AppSettings(
          shopName: 'Rehmat Store',
          organizationPhone: '03001234567',
          userType: UserType.shopkeeper,
          hasCompletedOnboarding: true,
          isPaidUser: true,
          lowDataMode: false,
          activeShopId: 'shop-1',
        ),
        reminderLogs: <ReminderLog>[
          ReminderLog(
            id: 'reminder-1',
            customerId: customer.id,
            message: 'Reminder',
            tone: ReminderTone.normal,
            sentAt: DateTime(2026, 1, 11),
            channel: 'whatsapp',
            wasSuccessful: true,
          ),
        ],
      );
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: snapshot),
      );
      await controller.load();

      final range = ReportRange(
        label: '10 Jan - 12 Jan',
        start: DateTime(2026, 1, 10),
        end: DateTime(2026, 1, 12),
      );

      expect(controller.openingBalanceForRange(range), 800);
      expect(controller.creditsIssuedForRange(range), 500);
      expect(controller.paymentsReceivedForRange(range), 300);
      expect(controller.closingBalanceForRange(range), 1000);
      expect(controller.netCashFlowForRange(range), -200);
      expect(controller.remindersSentForRange(range), 1);

      final csv = controller.exportReportCsv(range);
      expect(csv, contains('Summary,Range,10 Jan - 12 Jan'));
      expect(csv, contains('Usman'));
      expect(csv, contains('Wholesale'));

      final summary = controller.buildReportSummaryText(range);
      expect(summary, contains('Opening balance: Rs 800'));
      expect(summary, contains('Closing balance: Rs 1,000'));

      final reportDocument = controller.buildReportDocumentText(range);
      expect(reportDocument, contains('HISAB RAKHO REPORT'));
      expect(reportDocument, contains('ACTIVE PROFILES'));

      final statementCsv = controller.exportCustomerStatementCsv(
        customer,
        range: range,
      );
      expect(statementCsv, contains('Customer,Phone,Range,Opening Balance'));
      expect(statementCsv, contains('Tea cartons'));
    });
  });
}
