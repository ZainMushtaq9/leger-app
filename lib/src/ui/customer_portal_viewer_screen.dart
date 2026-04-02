import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class CustomerPortalViewerScreen extends StatefulWidget {
  const CustomerPortalViewerScreen({
    super.key,
    required this.controller,
    required this.payload,
  });

  final HisabRakhoController controller;
  final PortalSharePayload payload;

  @override
  State<CustomerPortalViewerScreen> createState() =>
      _CustomerPortalViewerScreenState();
}

class _CustomerPortalViewerScreenState
    extends State<CustomerPortalViewerScreen> {
  late final TextEditingController _amountController;
  DateTime? _promiseDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.payload.promiseAmount == null
          ? ''
          : widget.payload.promiseAmount!.toStringAsFixed(
              widget.payload.promiseAmount! % 1 == 0 ? 0 : 2,
            ),
    );
    _promiseDate = widget.payload.promiseDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickPromiseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _promiseDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _promiseDate = picked;
    });
  }

  String _promiseMessage() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final promiseDate =
        _promiseDate ?? DateTime.now().add(const Duration(days: 1));
    return widget.controller.buildPortalPromiseMessage(
      widget.payload,
      amount: amount <= 0 ? widget.payload.balance : amount,
      promiseDate: promiseDate,
    );
  }

  Future<void> _copyPromiseMessage() async {
    await Clipboard.setData(ClipboardData(text: _promiseMessage()));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Promise message copied.')));
  }

  Future<void> _sharePromiseMessage() async {
    await SharePlus.instance.share(
      ShareParams(
        title: '${widget.payload.customerName} promise update',
        text: _promiseMessage(),
      ),
    );
  }

  Future<void> _sendPromiseSms() async {
    final launched = await launchUrl(
      Uri(
        scheme: 'sms',
        path: _normalizePakPhone(widget.payload.shopPhone),
        queryParameters: <String, String>{'body': _promiseMessage()},
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launched ? 'SMS composer opened.' : 'SMS composer is not available.',
        ),
      ),
    );
  }

  Future<void> _sendPromiseWhatsApp() async {
    final launched = await launchUrl(
      Uri.parse(
        'https://wa.me/${_normalizePakPhone(widget.payload.shopPhone)}?text=${Uri.encodeComponent(_promiseMessage())}',
      ),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launched ? 'WhatsApp opened.' : 'WhatsApp could not be opened.',
        ),
      ),
    );
  }

  String _normalizePakPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('92')) {
      return digits;
    }
    if (digits.startsWith('0') && digits.length >= 11) {
      return '92${digits.substring(1)}';
    }
    if (digits.length == 10) {
      return '92$digits';
    }
    return digits;
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.payload;
    return Scaffold(
      appBar: AppBar(title: Text('${payload.customerName} Portal')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: <Widget>[
          SummaryCard(
            title: payload.customerName,
            value: widget.controller.formatCurrency(payload.balance),
            subtitle:
                '${payload.shopName} | Recovery ${payload.recoveryScore}% | Code ${payload.shareCode}',
            accentColor: payload.balance > 0 ? kKhataAmber : kKhataSuccess,
            icon: Icons.account_balance_wallet_rounded,
            prominent: true,
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Statement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This read-only portal shows the latest balance and recent activity shared by the shopkeeper.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  if (payload.promiseDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Current promise: ${widget.controller.formatDate(payload.promiseDate!)}'
                        '${payload.promiseAmount == null ? '' : ' | ${widget.controller.formatCurrency(payload.promiseAmount!)}'}',
                      ),
                    ),
                  ...payload.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: entry.isCredit
                              ? kKhataAmber.withValues(alpha: 0.15)
                              : kKhataGreen.withValues(alpha: 0.15),
                          child: Icon(
                            entry.isCredit
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: entry.isCredit ? kKhataAmber : kKhataGreen,
                          ),
                        ),
                        title: Text(entry.label),
                        subtitle: Text(
                          '${widget.controller.formatDate(entry.date)}'
                          '${entry.note.trim().isEmpty ? '' : ' | ${entry.note.trim()}'}',
                        ),
                        trailing: Text(
                          widget.controller.formatCurrency(entry.amount),
                        ),
                      ),
                    ),
                  ),
                  if (payload.entries.isEmpty)
                    const EmptyStateCard(
                      title: 'No recent entries',
                      message:
                          'The shop has not shared any recent activity yet.',
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
                  Text(
                    'Promise To Pay',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Send a clear payment commitment back to the shop using copy, share, SMS, or WhatsApp.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Promise amount',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickPromiseDate,
                    icon: const Icon(Icons.event_rounded),
                    label: Text(
                      _promiseDate == null
                          ? 'Pick promise date'
                          : 'Promise date: ${widget.controller.formatDate(_promiseDate!)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: kKhataGreen.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: SelectableText(_promiseMessage()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _copyPromiseMessage,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copy'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _sharePromiseMessage,
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share'),
                      ),
                      OutlinedButton.icon(
                        onPressed: payload.shopPhone.trim().isEmpty
                            ? null
                            : _sendPromiseSms,
                        icon: const Icon(Icons.sms_rounded),
                        label: const Text('SMS'),
                      ),
                      OutlinedButton.icon(
                        onPressed: payload.shopPhone.trim().isEmpty
                            ? null
                            : _sendPromiseWhatsApp,
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('WhatsApp'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
