import 'package:flutter/material.dart';

class ReceiptScanResult {
  const ReceiptScanResult({
    required this.amount,
    required this.customerName,
    required this.phone,
    required this.detectedDate,
    required this.note,
    required this.rawText,
    required this.warnings,
  });

  final double amount;
  final String customerName;
  final String phone;
  final DateTime? detectedDate;
  final String note;
  final String rawText;
  final List<String> warnings;
}

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  final TextEditingController _rawTextController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  List<String> _warnings = const <String>[];

  @override
  void dispose() {
    _rawTextController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _parseText() {
    final raw = _rawTextController.text.trim();
    if (raw.isEmpty) {
      return;
    }

    final lines = raw
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final amountText = _detectAmountText(raw, lines);
    final phoneMatch = RegExp(
      r'(?:(?:\+92|0092|92|0)?3\d{2}[- ]?\d{7})',
      caseSensitive: false,
    ).firstMatch(raw);
    final detectedPhone =
        phoneMatch?.group(0)?.replaceAll(RegExp(r'[\s-]'), '') ?? '';
    final detectedDate = _parseDateFromText(raw);
    final warnings = <String>[];

    String customerName = '';
    for (final line in lines) {
      if (RegExp(r'customer|name|party', caseSensitive: false).hasMatch(line)) {
        final cleaned = line.split(':').last.trim();
        if (cleaned.isNotEmpty) {
          customerName = cleaned;
          break;
        }
      }
    }
    if (customerName.isEmpty && lines.isNotEmpty) {
      customerName = lines.firstWhere(
        (line) => !RegExp(r'rs|pkr|\d', caseSensitive: false).hasMatch(line),
        orElse: () => '',
      );
    }

    if (amountText.isEmpty) {
      warnings.add(
        'No amount was detected. Enter it manually before confirming.',
      );
    }
    if (customerName.isEmpty) {
      warnings.add(
        'No customer name was detected. Review the details manually.',
      );
    }
    if (detectedPhone.isEmpty) {
      warnings.add('No phone number was detected.');
    }
    if (detectedDate == null) {
      warnings.add('No transaction date was detected.');
    }

    setState(() {
      if (customerName.isNotEmpty) {
        _nameController.text = customerName;
      }
      if (detectedPhone.isNotEmpty) {
        _phoneController.text = detectedPhone;
      }
      if (amountText.isNotEmpty) {
        _amountController.text = amountText;
      }
      if (detectedDate != null) {
        _dateController.text = _formatDate(detectedDate);
      }
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = 'Receipt scan import';
      }
      _warnings = warnings;
    });
  }

  void _confirm() {
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );
    final detectedDate = _parseDateFromText(_dateController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid amount before confirming.'),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      ReceiptScanResult(
        amount: amount,
        customerName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        detectedDate: detectedDate,
        note: _noteController.text.trim(),
        rawText: _rawTextController.text.trim(),
        warnings: List<String>.from(_warnings),
      ),
    );
  }

  String _detectAmountText(String raw, List<String> lines) {
    final preferredPatterns = <RegExp>[
      RegExp(
        r'(?:rs\.?|pkr|amount|total|balance|due|bill)\s*[:\-]?\s*([\d,]+(?:\.\d{1,2})?)',
        caseSensitive: false,
      ),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:rs\.?|pkr)', caseSensitive: false),
    ];

    for (final line in lines) {
      for (final pattern in preferredPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final amount = match.group(1)?.replaceAll(',', '') ?? '';
          if (amount.isNotEmpty) {
            return amount;
          }
        }
      }
    }

    final genericMatches = RegExp(
      r'\b([\d,]+(?:\.\d{1,2})?)\b',
      caseSensitive: false,
    ).allMatches(raw);
    for (final match in genericMatches) {
      final value = match.group(1)?.replaceAll(',', '') ?? '';
      if (value.isEmpty) {
        continue;
      }
      if (RegExp(r'^(?:92|0)?3\d{9}$').hasMatch(value)) {
        continue;
      }
      if (value.length == 8 && value.startsWith('20')) {
        continue;
      }
      return value;
    }

    return '';
  }

  DateTime? _parseDateFromText(String raw) {
    if (raw.trim().isEmpty) {
      return null;
    }

    final yearFirst = RegExp(
      r'\b(\d{4})[-/](\d{1,2})[-/](\d{1,2})\b',
    ).firstMatch(raw);
    if (yearFirst != null) {
      return _safeDate(
        int.tryParse(yearFirst.group(1)!),
        int.tryParse(yearFirst.group(2)!),
        int.tryParse(yearFirst.group(3)!),
      );
    }

    final dayFirst = RegExp(
      r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\b',
    ).firstMatch(raw);
    if (dayFirst != null) {
      final rawYear = int.tryParse(dayFirst.group(3)!);
      final normalizedYear = rawYear == null
          ? null
          : rawYear < 100
          ? 2000 + rawYear
          : rawYear;
      return _safeDate(
        normalizedYear,
        int.tryParse(dayFirst.group(2)!),
        int.tryParse(dayFirst.group(1)!),
      );
    }

    return null;
  }

  DateTime? _safeDate(int? year, int? month, int? day) {
    if (year == null || month == null || day == null) {
      return null;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt Scan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          const Text(
            'Paste receipt or khata text below. The app will extract the amount and customer name for review before adding credit.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _rawTextController,
            minLines: 8,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Scanned text',
              hintText: 'Paste OCR text from a receipt, diary page, or bill...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _parseText,
            icon: const Icon(Icons.document_scanner_outlined),
            label: const Text('Parse Text'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Customer name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Detected phone'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Detected amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dateController,
            decoration: const InputDecoration(labelText: 'Detected date'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          if (_warnings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            ..._warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  warning,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _confirm,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Confirm And Use'),
          ),
        ],
      ),
    );
  }
}
