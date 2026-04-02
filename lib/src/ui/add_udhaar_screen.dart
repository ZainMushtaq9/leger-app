import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../controller.dart';
import '../models.dart';
import 'common_widgets.dart';
import 'receipt_scan_screen.dart';

class AddUdhaarScreen extends StatefulWidget {
  const AddUdhaarScreen({
    super.key,
    required this.controller,
    this.selectedCustomerId,
    this.initialTransaction,
  });

  final HisabRakhoController controller;
  final String? selectedCustomerId;
  final LedgerTransaction? initialTransaction;

  @override
  State<AddUdhaarScreen> createState() => _AddUdhaarScreenState();
}

class _AddUdhaarScreenState extends State<AddUdhaarScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();

  String? _selectedCustomerId;
  DateTime _transactionDate = DateTime.now();
  DateTime? _selectedDueDate;
  String _receiptPath = '';
  String _audioNotePath = '';
  bool _saving = false;
  bool _speechReady = false;
  String _recognizedWords = '';
  String _voiceStatus = 'Urdu voice input se bolo: "Ali ko 5000 udhaar likho"';

  bool get _isEditing => widget.initialTransaction != null;

  @override
  void initState() {
    super.initState();
    final initialTransaction = widget.initialTransaction;
    _selectedCustomerId =
        initialTransaction?.customerId ??
        widget.selectedCustomerId ??
        (widget.controller.customers.length == 1
            ? widget.controller.customers.first.id
            : null);
    if (initialTransaction != null) {
      _amountController.text = initialTransaction.amount.toStringAsFixed(0);
      _noteController.text = initialTransaction.note;
      _referenceController.text = initialTransaction.reference;
      _transactionDate = initialTransaction.date;
      _selectedDueDate = initialTransaction.dueDate;
      _receiptPath = initialTransaction.receiptPath;
      _audioNotePath = initialTransaction.audioNotePath;
      _voiceStatus = 'Existing transaction edit mode active hai.';
    }
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final ready = await _speechToText.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _speechReady = ready;
      if (!ready) {
        _voiceStatus = 'Speech input is device par available nahi hai.';
      }
    });
  }

  @override
  void dispose() {
    _speechToText.stop();
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

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 7)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDueDate = selected;
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

  Future<void> _openReceiptScan() async {
    final result = await Navigator.of(context).push<ReceiptScanResult>(
      MaterialPageRoute<ReceiptScanResult>(
        builder: (context) => const ReceiptScanScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == null || !mounted) {
      return;
    }

    String? matchedCustomerId = _selectedCustomerId;
    if (!_isEditing && result.phone.trim().isNotEmpty) {
      for (final customer in widget.controller.customers) {
        final left = customer.phone.replaceAll(RegExp(r'[^0-9]'), '');
        final right = result.phone.replaceAll(RegExp(r'[^0-9]'), '');
        if (left.isNotEmpty && left == right) {
          matchedCustomerId = customer.id;
          break;
        }
      }
    }
    if (!_isEditing &&
        matchedCustomerId == _selectedCustomerId &&
        result.customerName.trim().isNotEmpty) {
      for (final customer in widget.controller.customers) {
        if (customer.name.trim().toLowerCase() ==
            result.customerName.trim().toLowerCase()) {
          matchedCustomerId = customer.id;
          break;
        }
      }
    }

    setState(() {
      _selectedCustomerId = matchedCustomerId;
      _amountController.text = result.amount.toStringAsFixed(0);
      if (!_isEditing && result.detectedDate != null) {
        _transactionDate = result.detectedDate!;
      }
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = result.note.isEmpty
            ? 'Receipt scan import'
            : result.note;
      }
      if (_referenceController.text.trim().isEmpty &&
          result.rawText.trim().isNotEmpty) {
        _referenceController.text = 'Receipt scan';
      }
      _voiceStatus = result.customerName.trim().isEmpty
          ? 'Receipt scan parsed the amount. Review the details before saving.'
          : 'Receipt scan parsed ${result.customerName}. Review the details before saving.';
      if (result.warnings.isNotEmpty) {
        _voiceStatus = '$_voiceStatus ${result.warnings.first}';
      }
    });
  }

  bool _isHighRisk(CustomerInsight insight) {
    return insight.recoveryScore < 40 || insight.overdueDays > 30;
  }

  Future<bool> _confirmHighRiskIfNeeded() async {
    final customerId = _selectedCustomerId;
    if (customerId == null) {
      return false;
    }

    final insight = widget.controller.insightFor(customerId);
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final limitWarning = widget.controller.creditLimitWarning(
      customerId,
      amount,
    );
    if (!_isHighRisk(insight) && limitWarning == null) {
      return true;
    }

    final customer = widget.controller.customerById(customerId)!;
    return (await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Risk alert'),
            content: Text(
              '${customer.name} ka recovery score ${insight.recoveryScore}% hai aur ${insight.overdueDays} din overdue balance bhi maujood hai.'
              '${limitWarning == null ? '' : '\n\n$limitWarning'}\n\nKya phir bhi entry save karni hai?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        )) ??
        false;
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = 'Voice stopped.';
      });
      return;
    }

    setState(() {
      _voiceStatus = 'Listening... Urdu ya Roman Urdu mein boliye.';
    });

    try {
      await _speechToText.listen(onResult: _onSpeechResult, localeId: 'ur_PK');
    } catch (_) {
      await _speechToText.listen(onResult: _onSpeechResult);
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) {
      return;
    }

    setState(() {
      _recognizedWords = result.recognizedWords;
    });

    if (!result.finalResult) {
      return;
    }

    final parsed = widget.controller.parseVoiceCredit(result.recognizedWords);
    if (parsed == null) {
      setState(() {
        _voiceStatus =
            'Name ya amount samajh nahi aya. Customer manually select karein.';
      });
      return;
    }

    setState(() {
      if (!_isEditing) {
        _selectedCustomerId = parsed.customerId;
      }
      _amountController.text = parsed.amount.toStringAsFixed(0);
      if (_noteController.text.trim().isEmpty) {
        _noteController.text = 'Voice entry: ${parsed.rawWords}';
      }
      _voiceStatus = 'Voice se customer aur amount fill ho gaya.';
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final shouldContinue = await _confirmHighRiskIfNeeded();
    if (!shouldContinue || !mounted) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final amount = double.parse(_amountController.text.replaceAll(',', ''));
    final attachmentLabel = _attachmentLabel();

    if (_isEditing) {
      await widget.controller.updateTransaction(
        transactionId: widget.initialTransaction!.id,
        amount: amount,
        note: _noteController.text,
        date: _transactionDate,
        dueDate: _selectedDueDate,
        reference: _referenceController.text,
        attachmentLabel: attachmentLabel,
        receiptPath: _receiptPath,
        audioNotePath: _audioNotePath,
        isDisputed: widget.initialTransaction!.isDisputed,
      );
    } else {
      await widget.controller.addUdhaar(
        customerId: _selectedCustomerId!,
        amount: amount,
        note: _noteController.text,
        dueDate: _selectedDueDate,
        date: _transactionDate,
        reference: _referenceController.text,
        attachmentLabel: attachmentLabel,
        receiptPath: _receiptPath,
        audioNotePath: _audioNotePath,
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
              ? '${widget.controller.creditLabel} update ho gaya.'
              : 'Udhaar entry save ho gayi.',
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
    final customers = widget.controller.customers;
    final selectedCustomer = _selectedCustomerId == null
        ? null
        : widget.controller.customerById(_selectedCustomerId!);
    final selectedInsight = _selectedCustomerId == null
        ? null
        : widget.controller.insightFor(_selectedCustomerId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Edit ${widget.controller.creditLabel}'
              : 'Add ${widget.controller.creditLabel}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: customers.isEmpty
            ? const EmptyStateCard(
                title: 'Pehle customer add karein',
                message:
                    'Udhaar save karne se pehle customer banana zaroori hai.',
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    Text(
                      _isEditing
                          ? '${widget.controller.creditLabel} edit karein'
                          : 'Naya ${widget.controller.creditLabel.toLowerCase()} likhein',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount, date, due date, note aur attachments ke sath entry complete karein.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
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
                      onChanged: _isEditing
                          ? null
                          : (value) {
                              setState(() {
                                _selectedCustomerId = value;
                              });
                            },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '${widget.controller.entitySingularLabel} select karein';
                        }
                        return null;
                      },
                    ),
                    if (selectedCustomer != null &&
                        selectedInsight != null) ...<Widget>[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                selectedCustomer.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  InsightChip(
                                    label:
                                        'Balance ${widget.controller.displayCurrency(selectedInsight.balance)}',
                                    color: const Color(0xFF2F8E63),
                                  ),
                                  InsightChip(
                                    label:
                                        'Score ${selectedInsight.recoveryScore}%',
                                    color: selectedInsight.recoveryScore < 40
                                        ? const Color(0xFFD85848)
                                        : const Color(0xFFF1B94F),
                                  ),
                                  InsightChip(
                                    label:
                                        '${selectedInsight.overdueDays} days overdue',
                                    color: selectedInsight.overdueDays > 30
                                        ? const Color(0xFFD85848)
                                        : const Color(0xFFF1B94F),
                                  ),
                                  if (selectedInsight.creditLimit != null)
                                    InsightChip(
                                      label:
                                          'Limit ${widget.controller.displayCurrency(selectedInsight.creditLimit!)}',
                                      color: selectedInsight.isOverCreditLimit
                                          ? const Color(0xFFD85848)
                                          : const Color(0xFF2F8E63),
                                    ),
                                ],
                              ),
                              if (_isHighRisk(selectedInsight)) ...<Widget>[
                                const SizedBox(height: 12),
                                Text(
                                  'Risk alert: is ${widget.controller.entitySingularLabel.toLowerCase()} par nayi entry dene se pehle sochna chahiye.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              if (selectedInsight.seasonalPauseActive)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Seasonal pause active hai, is liye soft reminder recommend hoga.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: '5000',
                      ),
                      validator: (value) {
                        final amount = double.tryParse(
                          (value ?? '').replaceAll(',', ''),
                        );
                        if (amount == null || amount <= 0) {
                          return 'Valid amount dein';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickTransactionDate,
                            icon: const Icon(Icons.event_note_rounded),
                            label: Text(
                              'Date ${widget.controller.formatDate(_transactionDate)}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.event_available_rounded),
                            label: Text(
                              _selectedDueDate == null
                                  ? 'Set due date'
                                  : 'Due ${widget.controller.formatDate(_selectedDueDate!)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDueDate != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedDueDate = null;
                            });
                          },
                          child: const Text('Clear due date'),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        hintText: 'Example: ration, drinks, milk',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Reference',
                        hintText: 'Invoice no, diary page, slip no',
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
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: _openReceiptScan,
                              icon: const Icon(Icons.document_scanner_outlined),
                              label: const Text('Receipt Scan'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                const Icon(Icons.mic_rounded),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Urdu voice input',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: _speechReady
                                      ? _toggleListening
                                      : null,
                                  icon: Icon(
                                    _speechToText.isListening
                                        ? Icons.stop_circle_rounded
                                        : Icons.keyboard_voice_rounded,
                                  ),
                                  label: Text(
                                    _speechToText.isListening
                                        ? 'Stop'
                                        : 'Speak',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _voiceStatus,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (_recognizedWords.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(_recognizedWords),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
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
                            ? 'Update'
                            : 'Save',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
