import '../../models.dart';

class BuildReminderMessageUseCase {
  String call({
    required Customer customer,
    required CustomerInsight insight,
    required AppTerminology terminology,
    required String formattedAmount,
    required String shopName,
    required ReminderTone tone,
  }) {
    final overdueLabel = insight.overdueDays > 0
        ? ' ${insight.overdueDays} din se pending hai.'
        : '';
    if (insight.seasonalPauseActive) {
      return 'Assalamualaikum ${customer.name},\n'
          'Seasonal days ko madde nazar rakhte hue halka sa reminder share kar raha hun. '
          'Aap ka $formattedAmount ${terminology.reminderSubject} baki hai.'
          '$overdueLabel\n'
          'Jab asani ho to payment update bata dein.\n'
          '- $shopName';
    }

    switch (tone) {
      case ReminderTone.soft:
        return 'Assalamualaikum ${customer.name},\n'
            'Gentle reminder ke liye message kar raha hun. '
            'Aap ka $formattedAmount ${terminology.reminderSubject} baki hai.'
            '$overdueLabel\n'
            'Jab convenient ho ada kar dein.\n'
            '- $shopName';
      case ReminderTone.normal:
        return 'Assalamualaikum ${customer.name},\n'
            'Aap ka $formattedAmount ${terminology.reminderSubject} baki hai.'
            '$overdueLabel\n'
            'Meherbani karke jald ada kar dein.\n'
            '- $shopName';
      case ReminderTone.strict:
        return 'Assalamualaikum ${customer.name},\n'
            'Aap ka $formattedAmount ${terminology.reminderSubject} kafi arsay se baki hai.'
            '$overdueLabel\n'
            'Barah-e-karam foran ada karein.\n'
            '- $shopName';
    }
  }
}
