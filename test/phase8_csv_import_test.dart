import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  group('Phase 8 CSV import', () {
    test(
      'previews and imports customer ledger data with duplicate protection',
      () async {
        final shop = ShopProfile(
          id: 'shop-1',
          name: 'Rehmat Store',
          phone: '03001234567',
          userType: UserType.shopkeeper,
          createdAt: DateTime(2026, 1, 1),
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
                isPaidUser: false,
                lowDataMode: false,
                activeShopId: shop.id,
              ),
            ),
          ),
        );
        await controller.load();

        const rawCsv = '''
Customer Name,Phone,Type,Amount,Date,Due Date,Notes,City
Usman,03111222333,Credit,5000,2026-01-02,2026-01-10,Monthly groceries,Karachi
Usman,03111222333,Payment,1500,2026-01-05,,Cash received,Karachi
Sana,03222233444,Credit,2200,2026-01-04,2026-01-12,Tea boxes,Lahore
''';

        final preview = controller.previewCsvImport(
          rawCsv,
          source: CsvImportSource.okCredit,
        );
        expect(preview.importableRowCount, 3);
        expect(preview.customerCount, 2);
        expect(preview.creditRowCount, 2);
        expect(preview.paymentRowCount, 1);
        expect(preview.totalCredits, 7200);
        expect(preview.totalPayments, 1500);

        final result = await controller.importCsvData(
          rawCsv,
          source: CsvImportSource.okCredit,
        );
        expect(result.createdCustomerCount, 2);
        expect(result.updatedCustomerCount, 0);
        expect(result.creditCount, 2);
        expect(result.paymentCount, 1);
        expect(controller.customers, hasLength(2));
        expect(controller.transactionCount, 3);

        final secondImport = await controller.importCsvData(
          rawCsv,
          source: CsvImportSource.okCredit,
        );
        expect(secondImport.duplicateTransactionCount, 3);
        expect(controller.customers, hasLength(2));
        expect(controller.transactionCount, 3);
      },
    );
  });
}
