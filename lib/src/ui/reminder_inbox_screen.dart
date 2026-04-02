import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class ReminderInboxScreen extends StatelessWidget {
  const ReminderInboxScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Inbox')),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final pending = controller.pendingReminderInbox;
          final handled = controller.handledReminderInbox;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: <Widget>[
              const SectionHeader(
                title: 'Pending Follow-ups',
                subtitle:
                    'Yahan scheduled reminders, promise follow-ups, aur kisti due items ek jagah milte hain.',
              ),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                const EmptyStateCard(
                  title: 'Inbox clear hai',
                  message:
                      'Naye scheduled reminders aur installment due items yahan nazar aayenge.',
                )
              else
                ...pending.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReminderInboxCard(
                      controller: controller,
                      item: item,
                      onOpen: () async {
                        final launched = await controller.openReminderInboxItem(
                          item.id,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              launched
                                  ? 'Reminder open ho gaya.'
                                  : 'Reminder open nahi ho saka.',
                            ),
                          ),
                        );
                      },
                      onSkip: () => controller.skipReminderInboxItem(item.id),
                      onComplete: () =>
                          controller.completeReminderInboxItem(item.id),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Handled',
                subtitle: 'Opened, skipped, ya completed follow-ups.',
              ),
              const SizedBox(height: 12),
              if (handled.isEmpty)
                const EmptyStateCard(
                  title: 'Abhi koi handled item nahi',
                  message:
                      'Pending follow-ups complete karne par history yahan aayegi.',
                )
              else
                ...handled.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ReminderInboxCard(
                      controller: controller,
                      item: item,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReminderInboxCard extends StatelessWidget {
  const _ReminderInboxCard({
    required this.controller,
    required this.item,
    this.onOpen,
    this.onSkip,
    this.onComplete,
  });

  final HisabRakhoController controller;
  final ReminderInboxItem item;
  final VoidCallback? onOpen;
  final VoidCallback? onSkip;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final customer = controller.customerById(item.customerId);
    final statusColor = switch (item.status) {
      ReminderInboxStatus.pending => kKhataAmber,
      ReminderInboxStatus.opened => kKhataSuccess,
      ReminderInboxStatus.skipped => kKhataDanger,
      ReminderInboxStatus.completed => kKhataSuccess,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(customer?.name ?? 'Deleted customer'),
                    ],
                  ),
                ),
                InsightChip(
                  label: controller.reminderInboxTypeLabel(item.type),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                InsightChip(
                  label: 'Due ${controller.formatDateTime(item.dueAt)}',
                  color:
                      item.dueAt.isBefore(DateTime.now()) &&
                          item.status == ReminderInboxStatus.pending
                      ? kKhataDanger
                      : kKhataAmber,
                ),
                InsightChip(label: item.status.name, color: statusColor),
              ],
            ),
            if (item.note.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(item.note),
            ],
            if (item.status == ReminderInboxStatus.pending) ...<Widget>[
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Open now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSkip,
                      icon: const Icon(Icons.skip_next_rounded),
                      label: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ] else if (item.handledAt != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                'Handled ${controller.formatDateTime(item.handledAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
