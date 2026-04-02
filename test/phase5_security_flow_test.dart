import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  group('Phase 5 security flow', () {
    AppDataSnapshot buildSnapshot() {
      final shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Store',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 1, 1),
      );
      final visibleCustomer = Customer(
        id: 'customer-1',
        shopId: shop.id,
        shareCode: 'share-1',
        name: 'Usman',
        phone: '03111222333',
        createdAt: DateTime(2026, 1, 1),
      );
      final hiddenCustomer = Customer(
        id: 'customer-2',
        shopId: shop.id,
        shareCode: 'share-2',
        name: 'Bilal',
        phone: '03211234567',
        createdAt: DateTime(2026, 1, 2),
        isHidden: true,
      );

      return AppDataSnapshot(
        shops: <ShopProfile>[shop],
        customers: <Customer>[visibleCustomer, hiddenCustomer],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: visibleCustomer.id,
            shopId: shop.id,
            amount: 2500,
            type: TransactionType.credit,
            note: 'Tea cartons',
            date: DateTime(2026, 1, 3),
          ),
          LedgerTransaction(
            id: 'credit-2',
            customerId: hiddenCustomer.id,
            shopId: shop.id,
            amount: 900,
            type: TransactionType.credit,
            note: 'Hidden profile entry',
            date: DateTime(2026, 1, 4),
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
      'supports main PIN, decoy unlock, hidden balances, and read-only mode',
      () async {
        final controller = HisabRakhoController(
          repository: InMemoryLedgerRepository(
            initialSnapshot: buildSnapshot(),
          ),
        );
        await controller.load();

        expect(controller.customers, hasLength(2));
        expect(controller.displayCurrency(2500), 'Rs 2,500');

        await controller.setSecurityPin('1234');
        await controller.setDecoyPin('4321');

        expect(controller.isSecurityEnabled, isTrue);
        expect(controller.hasPinConfigured, isTrue);
        expect(controller.hasDecoyPinConfigured, isTrue);

        await controller.lockApp();
        expect(controller.isLocked, isTrue);

        expect(controller.unlockWithPin('4321'), isTrue);
        expect(controller.isDecoySession, isTrue);
        expect(controller.canWriteData, isFalse);
        expect(controller.shouldHideBalances, isTrue);
        expect(controller.shouldHideHiddenCustomers, isTrue);
        expect(controller.securityModeLabel(), 'Decoy mode active');
        expect(controller.displayCurrency(2500), '****');
        expect(controller.customers.map((customer) => customer.name), <String>[
          'Usman',
        ]);
        expect(() => controller.buildBackupExport(), throwsStateError);

        await controller.lockApp();
        expect(controller.unlockWithPin('1234'), isTrue);
        expect(controller.isDecoySession, isFalse);
        expect(controller.canWriteData, isTrue);
        expect(controller.displayCurrency(2500), 'Rs 2,500');
      },
    );

    test('persists hide balance and hidden profile privacy toggles', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();

      await controller.updateSettings(
        controller.settings.copyWith(
          hideBalances: true,
          hideHiddenCustomers: true,
        ),
      );

      expect(controller.shouldHideBalances, isTrue);
      expect(controller.shouldHideHiddenCustomers, isTrue);
      expect(controller.displayCurrency(900), '****');
      expect(controller.customers.map((customer) => customer.name), <String>[
        'Usman',
      ]);

      await controller.setSecurityPin('1234');
      await controller.clearSecurityPin();

      expect(controller.isSecurityEnabled, isFalse);
      expect(controller.hasPinConfigured, isFalse);
      expect(controller.securityModeLabel(), 'Security off');
    });

    test('supports biometric and timed auto-lock behavior', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();
      await controller.setSecurityPin('1234');
      await controller.updateSettings(
        controller.settings.copyWith(
          appLockEnabled: true,
          biometricUnlockEnabled: true,
          autoLockMinutes: 5,
        ),
      );

      await controller.lockApp();
      expect(controller.isLocked, isTrue);

      controller.unlockWithBiometrics();
      expect(controller.isLocked, isFalse);

      final backgroundedAt = DateTime(2026, 1, 5, 10, 0);
      expect(
        controller.shouldAutoLockAfterBackground(
          backgroundedAt,
          now: DateTime(2026, 1, 5, 10, 4),
        ),
        isFalse,
      );
      expect(
        controller.shouldAutoLockAfterBackground(
          backgroundedAt,
          now: DateTime(2026, 1, 5, 10, 5),
        ),
        isTrue,
      );
    });
  });
}
