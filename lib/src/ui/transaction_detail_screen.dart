import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'add_udhaar_screen.dart';
import 'common_widgets.dart';
import 'record_payment_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  const TransactionDetailScreen({
    super.key,
    required this.controller,
    required this.transactionId,
  });

  final HisabRakhoController controller;
  final String transactionId;

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  Future<void> _openEdit(LedgerTransaction transaction) async {
    final route = transaction.type == TransactionType.credit
        ? MaterialPageRoute<void>(
            builder: (context) => AddUdhaarScreen(
              controller: widget.controller,
              selectedCustomerId: transaction.customerId,
              initialTransaction: transaction,
            ),
          )
        : MaterialPageRoute<void>(
            builder: (context) => RecordPaymentScreen(
              controller: widget.controller,
              customerId: transaction.customerId,
              initialTransaction: transaction,
            ),
          );
    await Navigator.of(context).push(route);
  }

  Future<void> _toggleDispute(LedgerTransaction transaction) async {
    await widget.controller.setTransactionDispute(
      transaction.id,
      isDisputed: !transaction.isDisputed,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          transaction.isDisputed
              ? 'Dispute flag remove ho gaya.'
              : 'Transaction disputed mark ho gayi.',
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(LedgerTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction'),
        content: const Text(
          'Yeh transaction permanently remove ho jayegi aur customer balance dobara recalculate hoga.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await widget.controller.deleteTransaction(transaction.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction delete ho gayi.')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _openAttachment(String path) async {
    final uri = Uri.file(path);
    final launched = await launchUrl(uri);
    if (launched || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attachment open nahi ho saki.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final transaction = widget.controller.transactionById(
          widget.transactionId,
        );
        if (transaction == null) {
          return const Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: EmptyStateCard(
                  title: 'Transaction not found',
                  message: 'Yeh entry ab available nahi rahi.',
                ),
              ),
            ),
          );
        }

        final customer = widget.controller.customerById(transaction.customerId);
        final isCredit = transaction.type == TransactionType.credit;
        final accentColor = isCredit ? kKhataDanger : kKhataSuccess;
        final canWriteData = widget.controller.canWriteData;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.controller.transactionTypeLabel(transaction.type),
            ),
            actions: <Widget>[
              IconButton(
                onPressed: canWriteData ? () => _openEdit(transaction) : null,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: canWriteData
                    ? () => _toggleDispute(transaction)
                    : null,
                icon: Icon(
                  transaction.isDisputed
                      ? Icons.flag_circle_rounded
                      : Icons.outlined_flag_rounded,
                ),
                tooltip: transaction.isDisputed
                    ? 'Clear dispute'
                    : 'Mark dispute',
              ),
              IconButton(
                onPressed: canWriteData
                    ? () => _deleteTransaction(transaction)
                    : null,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              isCredit
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.payments_rounded,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  customer?.name ?? 'Unknown customer',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.controller.formatDateTime(
                                    transaction.date,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${isCredit ? '+' : '-'} ${widget.controller.displayCurrency(transaction.amount)}',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineLarge?.copyWith(color: accentColor),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          InsightChip(
                            label: widget.controller.transactionTypeLabel(
                              transaction.type,
                            ),
                            color: accentColor,
                          ),
                          if (transaction.paidOnTime != null)
                            InsightChip(
                              label: transaction.paidOnTime!
                                  ? 'On time'
                                  : 'Late paid',
                              color: transaction.paidOnTime!
                                  ? kKhataSuccess
                                  : kKhataAmber,
                            ),
                          if (transaction.isDisputed)
                            const InsightChip(
                              label: 'Disputed',
                              color: kKhataDanger,
                            ),
                          if (transaction.receiptPath.isNotEmpty)
                            const InsightChip(
                              label: 'Receipt attached',
                              color: kKhataAmber,
                            ),
                          if (transaction.audioNotePath.isNotEmpty)
                            const InsightChip(
                              label: 'Audio attached',
                              color: kKhataAmber,
                            ),
                        ],
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
                        'Entry Notes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        transaction.note.trim().isEmpty
                            ? 'No note added.'
                            : transaction.note,
                      ),
                      if (transaction.reference.trim().isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        Text('Reference: ${transaction.reference}'),
                      ],
                      if (transaction.dueDate != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          'Due date: ${widget.controller.formatDate(transaction.dueDate!)}',
                        ),
                      ],
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
                        'Attachments',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _AttachmentTile(
                        icon: Icons.receipt_long_rounded,
                        title: 'Receipt photo',
                        subtitle: transaction.receiptPath.isEmpty
                            ? 'Abhi attach nahi ki gayi.'
                            : p.basename(transaction.receiptPath),
                        enabled: transaction.receiptPath.isNotEmpty,
                        onTap: transaction.receiptPath.isEmpty
                            ? null
                            : () => _openAttachment(transaction.receiptPath),
                      ),
                      const SizedBox(height: 10),
                      _AttachmentTile(
                        icon: Icons.mic_rounded,
                        title: 'Audio note',
                        subtitle: transaction.audioNotePath.isEmpty
                            ? 'Abhi attach nahi ki gayi.'
                            : p.basename(transaction.audioNotePath),
                        enabled: transaction.audioNotePath.isNotEmpty,
                        onTap: transaction.audioNotePath.isEmpty
                            ? null
                            : () => _openAttachment(transaction.audioNotePath),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canWriteData
                          ? () => _openEdit(transaction)
                          : null,
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canWriteData
                          ? () => _toggleDispute(transaction)
                          : null,
                      icon: Icon(
                        transaction.isDisputed
                            ? Icons.outlined_flag_rounded
                            : Icons.flag_circle_rounded,
                      ),
                      label: Text(
                        transaction.isDisputed ? 'Clear dispute' : 'Dispute',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: enabled ? kKhataGreen : kKhataInk),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            Icon(enabled ? Icons.open_in_new_rounded : Icons.block_rounded),
          ],
        ),
      ),
    );
  }
}
