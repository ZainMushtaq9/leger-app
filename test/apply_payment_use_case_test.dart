import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/domain/usecases/apply_payment_use_case.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  group('ApplyPaymentUseCase', () {
    test('marks a settled overdue credit as late', () {
      final useCase = ApplyPaymentUseCase();

      final updated = useCase(
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: 'customer-1',
            shopId: 'shop-1',
            amount: 5000,
            type: TransactionType.credit,
            note: 'Monthly ration',
            date: DateTime(2026, 1, 1),
            dueDate: DateTime(2026, 1, 5),
          ),
        ],
        customerId: 'customer-1',
        shopId: 'shop-1',
        amount: 5000,
        paymentId: 'payment-1',
        paymentDate: DateTime(2026, 1, 8),
        note: 'Cash',
      );

      final credit = updated.singleWhere((item) => item.id == 'credit-1');
      final payment = updated.singleWhere((item) => item.id == 'payment-1');

      expect(payment.type, TransactionType.payment);
      expect(credit.paidOnTime, isFalse);
    });

    test('marks a settled due-date credit as on time', () {
      final useCase = ApplyPaymentUseCase();

      final updated = useCase(
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: 'customer-1',
            shopId: 'shop-1',
            amount: 3200,
            type: TransactionType.credit,
            note: 'Snacks',
            date: DateTime(2026, 2, 1),
            dueDate: DateTime(2026, 2, 10),
          ),
        ],
        customerId: 'customer-1',
        shopId: 'shop-1',
        amount: 3200,
        paymentId: 'payment-1',
        paymentDate: DateTime(2026, 2, 10, 18),
        note: 'Wallet transfer',
      );

      final credit = updated.singleWhere((item) => item.id == 'credit-1');

      expect(credit.paidOnTime, isTrue);
    });
  });
}
