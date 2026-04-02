import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import 'common_widgets.dart';

class QuickLedgerEntrySheet extends StatefulWidget {
  const QuickLedgerEntrySheet({
    super.key,
    required this.controller,
    this.initialCustomerId,
    this.initialType = TransactionType.credit,
  });

  final HisabRakhoController controller;
  final String? initialCustomerId;
  final TransactionType initialType;

  @override
  State<QuickLedgerEntrySheet> createState() => _QuickLedgerEntrySheetState();
}

class _QuickLedgerEntrySheetState extends State<QuickLedgerEntrySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late TransactionType _type;
  String? _selectedCustomerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedCustomerId =
        widget.initialCustomerId ??
        (widget.controller.customers.length == 1
            ? widget.controller.customers.first.id
            : null);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCustomerId == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final note = _noteController.text.trim();
    if (_type == TransactionType.credit) {
      await widget.controller.addUdhaar(
        customerId: _selectedCustomerId!,
        amount: amount,
        note: note,
      );
    } else {
      await widget.controller.recordPayment(
        customerId: _selectedCustomerId!,
        amount: amount,
        note: note.isEmpty ? 'Quick payment' : note,
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.controller.customers;
    final selectedInsight = _selectedCustomerId == null
        ? null
        : widget.controller.insightFor(_selectedCustomerId!);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          18,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: customers.isEmpty
            ? const EmptyStateCard(
                title: 'Customers required',
                message:
                    'Quick ledger entry se pehle kam az kam ek customer banana zaroori hai.',
              )
            : Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Text(
                      'Quick ledger entry',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Home shell se seedha credit ya payment save karein.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    SegmentedButton<TransactionType>(
                      segments: <ButtonSegment<TransactionType>>[
                        ButtonSegment<TransactionType>(
                          value: TransactionType.credit,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: Text(widget.controller.creditLabel),
                        ),
                        const ButtonSegment<TransactionType>(
                          value: TransactionType.payment,
                          icon: Icon(Icons.payments_rounded),
                          label: Text('Payment'),
                        ),
                      ],
                      selected: <TransactionType>{_type},
                      onSelectionChanged: (value) {
                        setState(() {
                          _type = value.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCustomerId,
                      decoration: InputDecoration(
                        labelText: widget.controller.entitySingularLabel,
                      ),
                      items: customers
                          .map(
                            (customer) => DropdownMenuItem<String>(
                              value: customer.id,
                              child: Text(customer.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCustomerId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Customer select karein';
                        }
                        return null;
                      },
                    ),
                    if (selectedInsight != null) ...<Widget>[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          InsightChip(
                            label:
                                'Balance ${widget.controller.displayCurrency(selectedInsight.balance)}',
                            color: selectedInsight.balance > 0
                                ? const Color(0xFFD85848)
                                : const Color(0xFF2F8E63),
                          ),
                          InsightChip(
                            label: '${selectedInsight.recoveryScore}% score',
                            color: selectedInsight.recoveryScore < 40
                                ? const Color(0xFFD85848)
                                : const Color(0xFFF1B94F),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: _type == TransactionType.credit
                            ? 'Credit amount'
                            : 'Payment amount',
                        hintText: '2500',
                      ),
                      validator: (value) {
                        final amount = double.tryParse(
                          (value ?? '').replaceAll(',', ''),
                        );
                        if (amount == null || amount <= 0) {
                          return 'Valid amount dein';
                        }
                        if (_type == TransactionType.payment &&
                            selectedInsight != null &&
                            amount > selectedInsight.balance) {
                          return 'Outstanding balance se zyada payment na dein';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Quick note',
                        hintText: 'Optional',
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _type == TransactionType.credit
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.payments_rounded,
                            ),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : _type == TransactionType.credit
                            ? 'Save ${widget.controller.creditLabel}'
                            : 'Save Payment',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
