import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/domain/usecases/calculate_customer_insight_use_case.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  group('CalculateCustomerInsightUseCase', () {
    test('calculates balance, overdue days, and recovery score', () {
      final useCase = CalculateCustomerInsightUseCase();
      final customer = Customer(
        id: 'customer-1',
        shopId: 'shop-1',
        shareCode: 'share-1',
        name: 'Ali',
        phone: '03001234567',
        createdAt: DateTime(2025, 12, 1),
      );

      final insight = useCase(
        customer: customer,
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-settled',
            customerId: customer.id,
            shopId: customer.shopId,
            amount: 1000,
            type: TransactionType.credit,
            note: 'Old entry',
            date: DateTime(2026, 1, 1),
            dueDate: DateTime(2026, 1, 10),
            paidOnTime: true,
          ),
          LedgerTransaction(
            id: 'payment-settled',
            customerId: customer.id,
            shopId: customer.shopId,
            amount: 1000,
            type: TransactionType.payment,
            note: 'Old payment',
            date: DateTime(2026, 1, 9),
          ),
          LedgerTransaction(
            id: 'credit-open',
            customerId: customer.id,
            shopId: customer.shopId,
            amount: 800,
            type: TransactionType.credit,
            note: 'Current entry',
            date: DateTime(2026, 1, 20),
            dueDate: DateTime(2026, 1, 25),
          ),
          LedgerTransaction(
            id: 'payment-partial',
            customerId: customer.id,
            shopId: customer.shopId,
            amount: 300,
            type: TransactionType.payment,
            note: 'Partial',
            date: DateTime(2026, 1, 22),
          ),
        ],
        now: DateTime(2026, 2, 1),
      );

      expect(insight.balance, 500);
      expect(insight.overdueDays, 7);
      expect(insight.recoveryScore, 100);
      expect(insight.paymentChance, PaymentChance.high);
      expect(insight.recommendedTone, ReminderTone.soft);
    });

    test('uses neutral defaults when no transactions exist', () {
      final useCase = CalculateCustomerInsightUseCase();

      final customer = Customer(
        id: 'customer-1',
        shopId: 'shop-1',
        shareCode: 'share-1',
        name: 'Sana',
        phone: '03451234567',
        createdAt: DateTime(2026, 1, 1),
      );

      final insight = useCase(
        customer: customer,
        transactions: const <LedgerTransaction>[],
        now: DateTime(2026, 2, 1),
      );

      expect(insight.balance, 0);
      expect(insight.overdueDays, 0);
      expect(insight.recoveryScore, 75);
      expect(insight.paymentChance, PaymentChance.high);
      expect(insight.recommendedTone, ReminderTone.normal);
    });
  });
}
