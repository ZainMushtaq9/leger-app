import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'bulk_reminder_screen.dart';
import 'common_widgets.dart';
import 'reminder_composer_screen.dart';
import 'reminder_inbox_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.adsEnabled,
    required this.onOpenCustomer,
    required this.onAddUdhaar,
    required this.onShowCustomers,
    required this.onOpenReports,
    required this.onOpenSettings,
    required this.onOpenBusiness,
  });

  final HisabRakhoController controller;
  final bool adsEnabled;
  final Future<void> Function(Customer customer) onOpenCustomer;
  final Future<void> Function([String? customerId]) onAddUdhaar;
  final VoidCallback onShowCustomers;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onOpenBusiness;

  Future<void> _openBulkReminderQueue(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BulkReminderScreen(controller: controller),
      ),
    );
  }

  Future<void> _openReminderInbox(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReminderInboxScreen(controller: controller),
      ),
    );
  }

  Future<void> _openReminderComposer(
    BuildContext context,
    Customer customer,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ReminderComposerScreen(controller: controller, customer: customer),
      ),
    );
  }

  String _autoBackupLabel(int days) {
    switch (days) {
      case 0:
        return 'Manual';
      case 1:
        return 'Daily';
      case 7:
        return 'Weekly';
      default:
        return 'Every $days days';
    }
  }

  Future<void> _quickBackupToClipboard(BuildContext context) async {
    final bundle = controller.buildBackupExport(source: 'home-clipboard');
    await Clipboard.setData(ClipboardData(text: bundle.rawJson));
    await controller.recordBackupEvent(
      preview: bundle.preview,
      source: 'home-clipboard',
      status: 'copied',
      note: 'Quick backup from home screen',
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quick backup copied to the clipboard.')),
    );
  }

  Future<DateTime?> _pickScheduleDateTime(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !context.mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (pickedTime == null) {
      return null;
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _scheduleDailyAction(
    BuildContext context,
    Customer customer,
    DailyAction action,
  ) async {
    final scheduledAt = await _pickScheduleDateTime(context);
    if (scheduledAt == null) {
      return;
    }

    await controller.scheduleReminderFollowUp(
      customerId: customer.id,
      dueAt: scheduledAt,
      tone: action.tone,
      type: ReminderInboxType.dailyAction,
      note: 'Scheduled from daily actions',
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Follow-up for ${customer.name} was scheduled for ${controller.formatDateTime(scheduledAt)}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, child) {
          final topCustomers = controller.topCustomers;
          final actions = controller.todayActions;
          final lastBackupAt = controller.settings.lastBackupAt;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: <Widget>[
              Row(
                children: <Widget>[
                  const BrandMark(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          controller.activeShop.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          controller.dashboardSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: kKhataInk.withValues(alpha: 0.65),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      IconButton.filledTonal(
                        onPressed: () => _openReminderInbox(context),
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                      if (controller.pendingReminderInboxCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: kKhataDanger,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${controller.pendingReminderInboxCount}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kKhataGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: kKhataGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              controller.copy.homeWorkspaceLabel,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${controller.activeShop.name} • ${controller.shops.length} ${controller.copy.workspaceCountLabel}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        controller.hasStorageError
                            ? Icons.sd_card_alert_rounded
                            : Icons.phone_android_rounded,
                        color: controller.hasStorageError
                            ? kKhataDanger
                            : kKhataSuccess,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              controller.hasStorageError
                              ? 'A local save or load issue was detected. The current session is still running, but you should verify your data before closing the app.'
                              : 'Offline-first mode is active. Core business data is stored locally on this device.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  (controller.isAutoBackupDue
                                          ? kKhataAmber
                                          : kKhataSuccess)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              controller.isAutoBackupDue
                                  ? Icons.backup_rounded
                                  : Icons.verified_rounded,
                              color: controller.isAutoBackupDue
                                  ? kKhataAmber
                                  : kKhataSuccess,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Backup health',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  controller.isAutoBackupDue
                                      ? 'A fresh backup is due.'
                                      : 'The latest backup looks healthy.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label: _autoBackupLabel(
                              controller.settings.autoBackupDays,
                            ),
                            color: controller.isAutoBackupDue
                                ? kKhataAmber
                                : kKhataSuccess,
                          ),
                          InsightChip(
                            label: lastBackupAt == null
                                ? 'No backup yet'
                                : 'Last ${controller.formatDateTime(lastBackupAt)}',
                            color: kKhataGreen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      FilledButton.tonalIcon(
                        onPressed: controller.canWriteData
                            ? () => _quickBackupToClipboard(context)
                            : null,
                        icon: const Icon(Icons.copy_all_rounded),
                        label: const Text('Quick Backup'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.tonalIcon(
                        onPressed: onShowCustomers,
                        icon: const Icon(Icons.people_alt_rounded),
                        label: const Text('Customers'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: onOpenReports,
                        icon: const Icon(Icons.insights_rounded),
                        label: const Text('Reports'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => onOpenBusiness(),
                        icon: const Icon(Icons.store_mall_directory_rounded),
                        label: const Text('Business Hub'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SummaryCard(
                title: controller.outstandingLabel,
                value: controller.displayCurrency(controller.totalUdhaar),
                subtitle:
                    '${controller.customersWithPendingBalance.length} ${controller.entityPluralLabel.toLowerCase()} pending',
                accentColor: kKhataGreen,
                icon: Icons.account_balance_wallet_rounded,
                prominent: true,
              ),
              const SizedBox(height: 14),
              AdBannerStrip(
                enabled:
                    adsEnabled &&
                    controller.settings.adsEnabled &&
                    !controller.settings.isPaidUser,
              ),
              const SizedBox(height: 14),
              if (controller.pendingReminderInboxCount > 0) ...<Widget>[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications_active_rounded),
                    title: Text(
                      '${controller.pendingReminderInboxCount} follow-ups pending',
                    ),
                    subtitle: const Text(
                      'Scheduled reminders and installment follow-ups are waiting in the inbox.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openReminderInbox(context),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Overdue',
                      value: controller.displayCurrency(
                        controller.overdueAmount,
                      ),
                      subtitle: '30+ days',
                      accentColor: kKhataDanger,
                      icon: Icons.warning_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'This Month',
                      value: controller.displayCurrency(
                        controller.monthlyRecovery,
                      ),
                      subtitle: 'Recovery',
                      accentColor: kKhataSuccess,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: InfoPill(
                          icon: Icons.local_fire_department_rounded,
                          color: kKhataAmber,
                          title: '${controller.streakDays} days active',
                          subtitle: 'Recovery streak',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InfoPill(
                          icon: controller.beatLastMonth
                              ? Icons.emoji_events_rounded
                              : Icons.insights_rounded,
                          color: controller.beatLastMonth
                              ? kKhataSuccess
                              : kKhataAmber,
                          title: controller.beatLastMonth
                              ? 'You beat last month'
                              : 'Almost there',
                          subtitle: controller.beatLastMonth
                              ? '${controller.displayCurrency(controller.monthlyRecovery)} recovered'
                              : 'Focus on today actions',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: "Today's actions",
                subtitle: 'Priority follow-ups based on overdue balances and payment behavior.',
              ),
              const SizedBox(height: 12),
              if (actions.isEmpty)
                const EmptyStateCard(
                  title: 'Nothing urgent today',
                  message: 'New credits and overdue reminders will appear here automatically.',
                )
              else
                ...actions.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DailyActionCard(
                      action: action,
                      customer: controller.customerById(action.customerId)!,
                      controller: controller,
                      onOpenCustomer: onOpenCustomer,
                      onComposeReminder: () => _openReminderComposer(
                        context,
                        controller.customerById(action.customerId)!,
                      ),
                      onScheduleReminder: () => _scheduleDailyAction(
                        context,
                        controller.customerById(action.customerId)!,
                        action,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.canWriteData ? onAddUdhaar : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text('Add ${controller.creditLabel}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.canWriteData
                          ? () => _openBulkReminderQueue(context)
                          : null,
                      icon: const Icon(Icons.send_to_mobile_rounded),
                      label: const Text('Send All Reminders'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Top ${controller.entityPluralLabel}',
                subtitle: 'Highest outstanding balances in the active shop.',
              ),
              const SizedBox(height: 12),
              if (topCustomers.isEmpty)
                EmptyStateCard(
                  title:
                      'No pending ${controller.entitySingularLabel.toLowerCase()} profiles',
                  message:
                      'Add a new ${controller.entitySingularLabel.toLowerCase()} and record ${controller.creditLabel.toLowerCase()} to get started.',
                )
              else
                ...topCustomers.map(
                  (customer) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CustomerOverviewCard(
                      customer: customer,
                      controller: controller,
                      onTap: () => onOpenCustomer(customer),
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

class DailyActionCard extends StatelessWidget {
  const DailyActionCard({
    super.key,
    required this.action,
    required this.customer,
    required this.controller,
    required this.onOpenCustomer,
    required this.onComposeReminder,
    required this.onScheduleReminder,
  });

  final DailyAction action;
  final Customer customer;
  final HisabRakhoController controller;
  final Future<void> Function(Customer customer) onOpenCustomer;
  final Future<void> Function() onComposeReminder;
  final Future<void> Function() onScheduleReminder;

  @override
  Widget build(BuildContext context) {
    final insight = controller.insightFor(customer.id);
    final color = _urgencyColor(insight.urgency);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onOpenCustomer(customer),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.flash_on_rounded, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      action.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                action.subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kKhataInk.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  InsightChip(
                    label: controller.reminderToneLabel(action.tone),
                    color: color,
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: controller.canWriteData ? onComposeReminder : null,
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('Compose'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: controller.canWriteData ? onScheduleReminder : null,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Schedule'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: controller.canWriteData
                        ? () async {
                      final launched = await controller.sendReminder(
                        customer,
                        tone: action.tone,
                      );
                      if (!context.mounted) {
                        return;
                      }
                          ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            launched
                                ? 'WhatsApp reminder opened.'
                                : 'The reminder could not be opened.',
                            ),
                          ),
                        );
                    }
                        : null,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Smart Remind'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerOverviewCard extends StatelessWidget {
  const CustomerOverviewCard({
    super.key,
    required this.customer,
    required this.controller,
    required this.onTap,
  });

  final Customer customer;
  final HisabRakhoController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final insight = controller.insightFor(customer.id);
    final urgencyColor = _urgencyColor(insight.urgency);
    final chanceColor = _chanceColor(insight.paymentChance);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          customer.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: kKhataInk.withValues(alpha: 0.62),
                              ),
                        ),
                        if (customer.category.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            customer.category,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: kKhataInk.withValues(alpha: 0.58),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    controller.displayCurrency(insight.balance),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: urgencyColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  InsightChip(
                    label: '${insight.recoveryScore}% score',
                    color: chanceColor,
                  ),
                  const SizedBox(width: 8),
                  InsightChip(
                    label: controller.paymentChanceLabel(insight.paymentChance),
                    color: chanceColor,
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: controller.canWriteData
                        ? () async {
                      final launched = await controller.sendReminder(
                        customer,
                        tone: ReminderTone.normal,
                      );
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            launched
                                ? 'WhatsApp reminder opened.'
                                : 'The reminder could not be opened.',
                            ),
                          ),
                        );
                    }
                        : null,
                    icon: const Icon(Icons.message_rounded),
                    label: const Text('Remind'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _urgencyColor(UrgencyLevel urgency) {
  switch (urgency) {
    case UrgencyLevel.normal:
      return kKhataSuccess;
    case UrgencyLevel.warning:
      return kKhataAmber;
    case UrgencyLevel.danger:
      return kKhataDanger;
  }
}

Color _chanceColor(PaymentChance chance) {
  switch (chance) {
    case PaymentChance.high:
      return kKhataSuccess;
    case PaymentChance.medium:
      return kKhataAmber;
    case PaymentChance.low:
      return kKhataDanger;
  }
}
