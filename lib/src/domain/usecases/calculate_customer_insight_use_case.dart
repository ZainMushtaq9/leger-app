import '../../models.dart';

class CalculateCustomerInsightUseCase {
  CustomerInsight call({
    required Customer? customer,
    required List<LedgerTransaction> transactions,
    DateTime? now,
  }) {
    final referenceNow = now ?? DateTime.now();
    final timeline = <LedgerTransaction>[...transactions]
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalCredits = timeline
        .where((entry) => entry.type == TransactionType.credit)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final totalPayments = timeline
        .where((entry) => entry.type == TransactionType.payment)
        .fold<double>(0, (sum, entry) => sum + entry.amount);
    final balance = (totalCredits - totalPayments).clamp(0, double.infinity);

    final outstandingCredits = _buildOutstandingCredits(timeline);
    final firstOutstanding = outstandingCredits.isEmpty
        ? null
        : outstandingCredits.first;
    final pendingSince = firstOutstanding?.transaction.date;
    final overdueDays = firstOutstanding == null
        ? 0
        : _daysSince(referenceNow, firstOutstanding.referenceDate);

    final settledCredits = timeline
        .where(
          (entry) =>
              entry.type == TransactionType.credit && entry.paidOnTime != null,
        )
        .toList();
    final onTimeCredits = settledCredits
        .where((entry) => entry.paidOnTime ?? false)
        .length;
    final recoveryScore = settledCredits.isEmpty
        ? 75
        : ((onTimeCredits / settledCredits.length) * 100).round().clamp(0, 100);

    final latestPayment = timeline
        .where((entry) => entry.type == TransactionType.payment)
        .fold<DateTime?>(
          null,
          (latest, entry) => latest == null || latest.isBefore(entry.date)
              ? entry.date
              : latest,
        );
    final lastPaymentDays = latestPayment == null
        ? 999
        : _daysSince(referenceNow, latestPayment);

    final paymentChance = overdueDays >= 45 || recoveryScore < 40
        ? PaymentChance.low
        : overdueDays >= 15 || recoveryScore < 70
        ? PaymentChance.medium
        : PaymentChance.high;

    final seasonalPauseActive = customer == null
        ? false
        : customer.seasonalPauseMonths.contains(referenceNow.month);
    final isOverCreditLimit =
        customer?.creditLimit != null && balance > (customer?.creditLimit ?? 0);

    final recommendedTone = seasonalPauseActive
        ? ReminderTone.soft
        : recoveryScore > 70 && overdueDays <= 7 && lastPaymentDays <= 30
        ? ReminderTone.soft
        : recoveryScore >= 40 && overdueDays < 60
        ? ReminderTone.normal
        : ReminderTone.strict;

    final urgency = overdueDays > 30
        ? UrgencyLevel.danger
        : overdueDays > 7
        ? UrgencyLevel.warning
        : UrgencyLevel.normal;

    return CustomerInsight(
      balance: balance.toDouble(),
      overdueDays: overdueDays,
      recoveryScore: recoveryScore,
      paymentChance: paymentChance,
      urgency: urgency,
      recommendedTone: recommendedTone,
      totalCredits: totalCredits,
      totalPayments: totalPayments,
      pendingSince: pendingSince,
      lastReminderAt: customer?.lastReminderAt,
      seasonalPauseActive: seasonalPauseActive,
      isOverCreditLimit: isOverCreditLimit,
      creditLimit: customer?.creditLimit,
    );
  }

  List<_OutstandingCredit> _buildOutstandingCredits(
    List<LedgerTransaction> timeline,
  ) {
    final credits = <_OutstandingCredit>[];
    for (final entry in timeline) {
      if (entry.type == TransactionType.credit) {
        credits.add(
          _OutstandingCredit(transaction: entry, remaining: entry.amount),
        );
        continue;
      }

      var remainingPayment = entry.amount;
      for (final credit in credits) {
        if (remainingPayment <= 0) {
          break;
        }
        if (credit.remaining <= 0) {
          continue;
        }

        final appliedAmount = remainingPayment < credit.remaining
            ? remainingPayment
            : credit.remaining;
        credit.remaining -= appliedAmount;
        remainingPayment -= appliedAmount;
      }
    }

    return credits.where((credit) => credit.remaining > 0.0001).toList();
  }

  int _daysSince(DateTime now, DateTime target) {
    final normalizedNow = DateTime(now.year, now.month, now.day);
    final normalizedTarget = DateTime(target.year, target.month, target.day);
    final days = normalizedNow.difference(normalizedTarget).inDays;
    return days < 0 ? 0 : days;
  }
}

class _OutstandingCredit {
  _OutstandingCredit({required this.transaction, required this.remaining});

  final LedgerTransaction transaction;
  double remaining;

  DateTime get referenceDate => transaction.dueDate ?? transaction.date;
}
