import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/data/shared_preferences_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/services/security_vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesLedgerRepository', () {
    test('persists and reloads the full local snapshot', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final repository = SharedPreferencesLedgerRepository(
        preferences: prefs,
        securityVaultService: InMemorySecurityVaultService(),
      );
      final shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Store',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 1, 1),
      );

      final snapshot = AppDataSnapshot(
        shops: <ShopProfile>[shop],
        customers: <Customer>[
          Customer(
            id: 'customer-1',
            shopId: shop.id,
            shareCode: 'share-1',
            name: 'Usman',
            phone: '03111222333',
            createdAt: DateTime(2026, 1, 1),
            category: 'Wholesale',
          ),
        ],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: 'customer-1',
            shopId: shop.id,
            amount: 2500,
            type: TransactionType.credit,
            note: 'Dry fruit boxes',
            date: DateTime(2026, 1, 2),
            dueDate: DateTime(2026, 1, 9),
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
        customerVisits: <CustomerVisit>[
          CustomerVisit(
            id: 'visit-1',
            customerId: 'customer-1',
            visitedAt: DateTime(2026, 1, 3, 15),
            note: 'Customer promised payment next week',
            followUpDueAt: DateTime(2026, 1, 10, 10),
          ),
        ],
      );

      await repository.save(snapshot);
      final stored = prefs.getString('hisab_rakho.snapshot.v1');
      expect(stored, isNotNull);
      expect(stored, isNot(contains('Usman')));
      expect(stored, contains('hisab_rakho.encrypted_snapshot'));

      final loaded = await repository.load();
      final protection = await repository.protectionStatus();

      expect(loaded.customers.single.name, 'Usman');
      expect(loaded.transactions.single.dueDate, DateTime(2026, 1, 9));
      expect(loaded.settings.shopName, 'Rehmat Store');
      expect(loaded.settings.isPaidUser, isTrue);
      expect(
        loaded.customerVisits.single.followUpDueAt,
        DateTime(2026, 1, 10, 10),
      );
      expect(protection.encryptedAtRest, isTrue);
      expect(protection.keyStoredSecurely, isTrue);
    });
  });
}
