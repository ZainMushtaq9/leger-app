import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/domain/usecases/build_reminder_message_use_case.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  group('BuildReminderMessageUseCase', () {
    test('uses the seasonal template when a seasonal pause is active', () {
      final useCase = BuildReminderMessageUseCase();
      final customer = Customer(
        id: 'customer-1',
        shopId: 'shop-1',
        shareCode: 'share-1',
        name: 'Areeba',
        phone: '03001234567',
        createdAt: DateTime(2026, 3, 1),
      );

      final message = useCase(
        customer: customer,
        insight: const CustomerInsight(
          balance: 2400,
          overdueDays: 6,
          recoveryScore: 82,
          paymentChance: PaymentChance.high,
          urgency: UrgencyLevel.normal,
          recommendedTone: ReminderTone.soft,
          totalCredits: 2400,
          totalPayments: 0,
          pendingSince: null,
          lastReminderAt: null,
          seasonalPauseActive: true,
          isOverCreditLimit: false,
          creditLimit: null,
        ),
        terminology: AppTerminology.forUserType(UserType.shopkeeper),
        formattedAmount: 'Rs 2,400',
        shopName: 'Rehmat Store',
        tone: ReminderTone.strict,
      );

      expect(message, contains('Seasonal days'));
      expect(message, contains('Rs 2,400'));
      expect(message, contains('Rehmat Store'));
    });
  });
}
