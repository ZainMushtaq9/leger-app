import '../../models.dart';

class ApplyPaymentUseCase {
  List<LedgerTransaction> call({
    required List<LedgerTransaction> transactions,
    required String customerId,
    required String shopId,
    required double amount,
    required String paymentId,
    required DateTime paymentDate,
    required String note,
  }) {
    final customerTimeline =
        transactions.where((entry) => entry.customerId == customerId).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final credits = <_CreditCursor>[];
    for (final entry in customerTimeline) {
      if (entry.type == TransactionType.credit) {
        credits.add(_CreditCursor(transaction: entry, remaining: entry.amount));
        continue;
      }

      _applyAmount(
        credits: credits,
        amount: entry.amount,
        paymentDate: entry.date,
      );
    }

    final settledStatuses = <String, bool>{};
    _applyAmount(
      credits: credits,
      amount: amount,
      paymentDate: paymentDate,
      settledStatuses: settledStatuses,
    );

    final updatedTransactions = transactions.map((entry) {
      final paidOnTime = settledStatuses[entry.id];
      if (paidOnTime == null) {
        return entry;
      }
      return entry.copyWith(paidOnTime: paidOnTime);
    }).toList();

    final payment = LedgerTransaction(
      id: paymentId,
      customerId: customerId,
      shopId: shopId,
      amount: amount,
      type: TransactionType.payment,
      note: note,
      date: paymentDate,
    );

    return <LedgerTransaction>[payment, ...updatedTransactions];
  }

  void _applyAmount({
    required List<_CreditCursor> credits,
    required double amount,
    required DateTime paymentDate,
    Map<String, bool>? settledStatuses,
  }) {
    var remainingPayment = amount;
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

      final settledNow = credit.remaining <= 0.0001;
      if (!settledNow || settledStatuses == null) {
        continue;
      }
      if (credit.transaction.paidOnTime != null) {
        continue;
      }
      settledStatuses[credit.transaction.id] = _isOnTime(
        credit.transaction,
        paymentDate,
      );
    }
  }

  bool _isOnTime(LedgerTransaction credit, DateTime paymentDate) {
    final reference = credit.dueDate ?? credit.date;
    final deadline = DateTime(
      reference.year,
      reference.month,
      reference.day,
      23,
      59,
      59,
      999,
    );
    return !paymentDate.isAfter(deadline);
  }
}

class _CreditCursor {
  _CreditCursor({required this.transaction, required this.remaining});

  final LedgerTransaction transaction;
  double remaining;
}
