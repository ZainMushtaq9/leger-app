import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../controller.dart';
import '../models.dart';
import 'common_widgets.dart';

class RecordPaymentScreen extends StatefulWidget {
  const RecordPaymentScreen({
    super.key,
    required this.controller,
    required this.customerId,
    this.initialTransaction,
  });

  final HisabRakhoController controller;
  final String customerId;
  final LedgerTransaction? initialTransaction;

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();

  DateTime _transactionDate = DateTime.now();
  String _receiptPath = '';
  String _audioNotePath = '';
  bool _saving = false;
  bool _sendConfirmation = true;

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initialTransaction = widget.initialTransaction;
    if (initialTransaction != null) {
      _amountController.text = initialTransaction.amount.toStringAsFixed(0);
      _noteController.text = initialTransaction.note;
      _referenceController.text = initialTransaction.reference;
      _transactionDate = initialTransaction.date;
      _receiptPath = initialTransaction.receiptPath;
      _audioNotePath = initialTransaction.audioNotePath;
      _sendConfirmation = false;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickTransactionDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _transactionDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _transactionDate.hour,
        _transactionDate.minute,
      );
    });
  }

  Future<void> _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _receiptPath = path;
    });
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['aac', 'm4a', 'mp3', 'ogg', 'wav'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) {
      return;
    }

    setState(() {
      _audioNotePath = path;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    setState(() {
      _saving = true;
    });

    final attachmentLabel = _attachmentLabel();
    if (_isEditing) {
      await widget.controller.updateTransaction(
        transactionId: widget.initialTransaction!.id,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? 'Payment receive hui'
            : _noteController.text.trim(),
        date: _transactionDate,
        reference: _referenceController.text,
        attachmentLabel: attachmentLabel,
        receiptPath: _receiptPath,
        audioNotePath: _audioNotePath,
        isDisputed: widget.initialTransaction!.isDisputed,
      );
    } else {
      await widget.controller.recordPayment(
        customerId: widget.customerId,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? 'Payment receive hui'
            : _noteController.text.trim(),
        date: _transactionDate,
        reference: _referenceController.text,
        attachmentLabel: attachmentLabel,
        receiptPath: _receiptPath,
        audioNotePath: _audioNotePath,
      );
    }

    final customer = widget.controller.customerById(widget.customerId)!;
    var confirmationSent = false;
    if (!_isEditing && _sendConfirmation) {
      confirmationSent = await widget.controller.sendPaymentConfirmation(
        customer,
        amount: amount,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing
              ? 'Payment update ho gayi.'
              : confirmationSent
              ? 'Payment record ho gayi aur confirmation open ho gaya.'
              : 'Payment record ho gayi.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  String _attachmentLabel() {
    final labels = <String>[];
    if (_receiptPath.isNotEmpty) {
      labels.add('Receipt ${p.basename(_receiptPath)}');
    }
    if (_audioNotePath.isNotEmpty) {
      labels.add('Audio ${p.basename(_audioNotePath)}');
    }
    return labels.join(' | ');
  }

  Widget _buildAttachmentTile({
    required BuildContext context,
    required String title,
    required String path,
    required IconData icon,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  path.isEmpty ? 'Abhi attach nahi ki gayi.' : p.basename(path),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onPick,
            child: Text(path.isEmpty ? 'Attach' : 'Replace'),
          ),
          if (path.isNotEmpty)
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear',
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.controller.customerById(widget.customerId)!;
    final insight = widget.controller.insightFor(customer.id);
    final maxEditableAmount =
        insight.balance + (_isEditing ? widget.initialTransaction!.amount : 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Payment' : 'Record Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                customer.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Current balance: ${widget.controller.displayCurrency(insight.balance)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount Paid',
                  hintText: '2000',
                ),
                validator: (value) {
                  final amount = double.tryParse(
                    (value ?? '').replaceAll(',', ''),
                  );
                  if (amount == null || amount <= 0) {
                    return 'Valid amount dein';
                  }
                  if (amount > maxEditableAmount) {
                    return 'Outstanding balance se zyada payment record na karein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickTransactionDate,
                icon: const Icon(Icons.event_note_rounded),
                label: Text(
                  'Date ${widget.controller.formatDate(_transactionDate)}',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Cash counter par payment receive hui',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText: 'Reference',
                  hintText: 'Receipt no, diary page, voucher',
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Attachments',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      _buildAttachmentTile(
                        context: context,
                        title: 'Receipt photo',
                        path: _receiptPath,
                        icon: Icons.receipt_long_rounded,
                        onPick: _pickReceipt,
                        onClear: () {
                          setState(() {
                            _receiptPath = '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildAttachmentTile(
                        context: context,
                        title: 'Audio note',
                        path: _audioNotePath,
                        icon: Icons.mic_rounded,
                        onPick: _pickAudio,
                        onClear: () {
                          setState(() {
                            _audioNotePath = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (!_isEditing) ...<Widget>[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Send WhatsApp confirmation'),
                  subtitle: const Text(
                    'Customer ko instant payment confirmation bhejein',
                  ),
                  value: _sendConfirmation,
                  onChanged: (value) {
                    setState(() {
                      _sendConfirmation = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _saving
                      ? 'Saving...'
                      : _isEditing
                      ? 'Update Payment'
                      : 'Save Payment',
                ),
              ),
              if (_isEditing) ...<Widget>[
                const SizedBox(height: 16),
                const EmptyStateCard(
                  title: 'Edit mode',
                  message:
                      'Existing payment update karte waqt customer ko dobara confirmation nahi bheja jata.',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
