import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  group('Phase 3 controller workflows', () {
    test('logs a visit and schedules a visit follow-up reminder', () async {
      final shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Store',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 3, 1),
      );
      final customer = Customer(
        id: 'customer-1',
        shopId: shop.id,
        shareCode: 'share-1',
        name: 'Usman',
        phone: '03111222333',
        createdAt: DateTime(2026, 3, 5),
      );
      final snapshot = AppDataSnapshot(
        shops: <ShopProfile>[shop],
        customers: <Customer>[customer],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: customer.id,
            shopId: shop.id,
            amount: 1800,
            type: TransactionType.credit,
            note: 'Flour sacks',
            date: DateTime(2026, 3, 6),
            dueDate: DateTime(2026, 3, 12),
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
      );

      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: snapshot),
      );
      await controller.load();

      final followUpAt = DateTime(2026, 3, 30, 10);
      await controller.logCustomerVisit(
        customerId: customer.id,
        note: 'Visited shop and confirmed payment soon',
        followUpAt: followUpAt,
      );

      expect(controller.customerVisitsFor(customer.id), hasLength(1));
      expect(
        controller.customerVisitsFor(customer.id).single.note,
        'Visited shop and confirmed payment soon',
      );
      expect(controller.pendingReminderInbox, hasLength(1));
      expect(
        controller.pendingReminderInbox.single.type,
        ReminderInboxType.visitFollowUp,
      );
      expect(controller.pendingReminderInbox.single.dueAt, followUpAt);
    });
  });
}
