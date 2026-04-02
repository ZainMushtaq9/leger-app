import '../../models.dart';

class ParseVoiceCreditUseCase {
  ParsedVoiceCredit? call({
    required String rawWords,
    required List<Customer> customers,
  }) {
    final words = rawWords.trim();
    if (words.isEmpty) {
      return null;
    }

    final amountMatch = RegExp(r'(\d[\d,]*)').firstMatch(words);
    if (amountMatch == null) {
      return null;
    }

    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return null;
    }

    final normalized = words.toLowerCase();
    Customer? match;
    for (final customer in customers) {
      if (normalized.contains(customer.name.toLowerCase())) {
        match = customer;
        break;
      }
    }

    if (match == null) {
      final nameMatch = RegExp(
        r'^\s*([\w\s]+?)\s+ko\s+\d',
      ).firstMatch(normalized);
      if (nameMatch != null) {
        final guessedName = nameMatch.group(1)!.trim();
        for (final customer in customers) {
          if (customer.name.toLowerCase().startsWith(guessedName)) {
            match = customer;
            break;
          }
        }
      }
    }

    if (match == null) {
      return null;
    }

    return ParsedVoiceCredit(
      customerId: match.id,
      amount: amount,
      rawWords: words,
    );
  }
}
