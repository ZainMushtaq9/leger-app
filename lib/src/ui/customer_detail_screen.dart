import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'add_customer_screen.dart';
import 'add_udhaar_screen.dart';
import 'community_blacklist_screen.dart';
import 'common_widgets.dart';
import 'customer_portal_screen.dart';
import 'installment_planner_screen.dart';
import 'negotiation_helper_screen.dart';
import 'record_payment_screen.dart';
import 'reminder_composer_screen.dart';
import 'transaction_detail_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({
    super.key,
    required this.controller,
    required this.customer,
    required this.adsEnabled,
  });

  final HisabRakhoController controller;
  final Customer customer;
  final bool adsEnabled;

  Future<void> _shareStatement(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        title: '${liveCustomer.name} statement',
        text: controller.buildStatementShareText(liveCustomer),
      ),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer view link shared.')));
  }

  Future<void> _copyStatementLink(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    await Clipboard.setData(
      ClipboardData(text: controller.buildCustomerStatementLink(liveCustomer)),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer view link copied.')));
  }

  Future<void> _openEditProfile(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            AddCustomerScreen(controller: controller, customer: liveCustomer),
      ),
    );
  }

  Future<void> _openReminderComposer(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReminderComposerScreen(
          controller: controller,
          customer: liveCustomer,
        ),
      ),
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

  Future<void> _scheduleFollowUp(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    final scheduledAt = await _pickScheduleDateTime(context);
    if (scheduledAt == null) {
      return;
    }

    await controller.scheduleReminderFollowUp(
      customerId: liveCustomer.id,
      dueAt: scheduledAt,
      tone: controller.insightFor(liveCustomer.id).recommendedTone,
      type: liveCustomer.promisedPaymentDate != null
          ? ReminderInboxType.promiseFollowUp
          : ReminderInboxType.scheduledReminder,
      note: 'Scheduled from customer detail',
    );

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'A follow-up was scheduled for ${controller.formatDateTime(scheduledAt)}.',
        ),
      ),
    );
  }

  Future<void> _openInstallmentPlanner(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => InstallmentPlannerScreen(
          controller: controller,
          customer: liveCustomer,
        ),
      ),
    );
  }

  Future<void> _openPortalScreen(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CustomerPortalScreen(
          controller: controller,
          customer: liveCustomer,
        ),
      ),
    );
  }

  Future<void> _openNegotiationHelper(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => NegotiationHelperScreen(
          controller: controller,
          customer: liveCustomer,
        ),
      ),
    );
  }

  Future<void> _openCommunityBlacklist(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CommunityBlacklistScreen(
          controller: controller,
          customer: liveCustomer,
        ),
      ),
    );
  }

  Future<void> _logVisit(BuildContext context, Customer liveCustomer) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    final draft = await showModalBottomSheet<_VisitLogDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _VisitLogSheet(
          controller: controller,
          initialFollowUpAt: DateTime(
            tomorrow.year,
            tomorrow.month,
            tomorrow.day,
            10,
          ),
        );
      },
    );

    if (draft == null) {
      return;
    }

    await controller.logCustomerVisit(
      customerId: liveCustomer.id,
      note: draft.note,
      followUpAt: draft.followUpAt,
      locationLabel: draft.locationLabel,
      latitude: draft.latitude,
      longitude: draft.longitude,
    );

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          draft.followUpAt == null
              ? 'Visit log saved.'
              : 'Visit and follow-up were saved for ${controller.formatDateTime(draft.followUpAt!)}.',
        ),
      ),
    );
  }

  Future<void> _sendGroupReminders(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    final groupName = liveCustomer.groupName.trim();
    if (groupName.isEmpty) {
      return;
    }
    final result = await controller.sendGroupReminders(groupName);
    if (!context.mounted) {
      return;
    }
    final limitedText = result.limitedByPlan
        ? ' Free mode opened only 3 reminders.'
        : '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$groupName group ke ${result.opened} reminders open hue.$limitedText',
        ),
      ),
    );
  }

  Future<void> _openTransactionDetail(
    BuildContext context,
    LedgerTransaction transaction,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TransactionDetailScreen(
          controller: controller,
          transactionId: transaction.id,
        ),
      ),
    );
  }

  Future<void> _deleteCustomer(
    BuildContext context,
    Customer liveCustomer,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete customer'),
        content: Text(
          '${liveCustomer.name} and all linked transactions will be removed permanently.',
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

    if (confirmed != true || !context.mounted) {
      return;
    }

    await controller.deleteCustomer(liveCustomer.id);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer deleted.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final liveCustomer = controller.customerById(customer.id) ?? customer;
        final insight = controller.insightFor(liveCustomer.id);
        final transactions = controller.transactionsFor(liveCustomer.id);
        final reminders = controller.remindersFor(liveCustomer.id);
        final pendingFollowUps = controller.pendingReminderInboxForCustomer(
          liveCustomer.id,
        );
        final activePlan = controller.activeInstallmentPlanFor(liveCustomer.id);
        final visits = controller.customerVisitsFor(liveCustomer.id);
        final blacklistMatches = controller
            .communityBlacklistMatchesForCustomer(liveCustomer.id);
        final latestVisit = visits.isEmpty ? null : visits.first;
        final visitFollowUpCount = pendingFollowUps
            .where((item) => item.type == ReminderInboxType.visitFollowUp)
            .length;
        final referredBy = controller.referredByFor(liveCustomer);
        final inheritedTrustBoost = controller.inheritedTrustBoost(
          liveCustomer,
        );
        final urgencyColor = _urgencyColor(insight.urgency);
        final chanceColor = _chanceColor(insight.paymentChance);
        final canWriteData = controller.canWriteData;

        return Scaffold(
          appBar: AppBar(
            title: Text(liveCustomer.name),
            actions: <Widget>[
              IconButton(
                onPressed: canWriteData
                    ? () => _openEditProfile(context, liveCustomer)
                    : null,
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit profile',
              ),
              IconButton(
                onPressed: canWriteData
                    ? () => _copyStatementLink(context, liveCustomer)
                    : null,
                icon: const Icon(Icons.link_rounded),
                tooltip: 'Copy view link',
              ),
              IconButton(
                onPressed: canWriteData
                    ? () => _shareStatement(context, liveCustomer)
                    : null,
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share',
              ),
              IconButton(
                onPressed: canWriteData
                    ? () => _deleteCustomer(context, liveCustomer)
                    : null,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete customer',
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  liveCustomer.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  liveCustomer.phone,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: kKhataInk.withValues(
                                          alpha: 0.65,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (liveCustomer.isFavourite)
                            const Icon(Icons.star_rounded, color: kKhataAmber),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        controller.displayCurrency(insight.balance),
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(color: urgencyColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.outstandingLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: kKhataInk.withValues(alpha: 0.62),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label: 'Recovery Score ${insight.recoveryScore}%',
                            color: chanceColor,
                          ),
                          InsightChip(
                            label:
                                'Chance ${controller.paymentChanceLabel(insight.paymentChance)}',
                            color: chanceColor,
                          ),
                          InsightChip(
                            label:
                                '${controller.urgencyLabel(insight.urgency)} | ${insight.overdueDays} days',
                            color: urgencyColor,
                          ),
                          if (insight.creditLimit != null)
                            InsightChip(
                              label:
                                  'Limit ${controller.displayCurrency(insight.creditLimit!)}',
                              color: insight.isOverCreditLimit
                                  ? kKhataDanger
                                  : kKhataSuccess,
                            ),
                          if (liveCustomer.groupName.trim().isNotEmpty)
                            InsightChip(
                              label: 'Group ${liveCustomer.groupName}',
                              color: kKhataAmber,
                            ),
                          if (liveCustomer.isHidden)
                            const InsightChip(
                              label: 'Hidden profile',
                              color: kKhataDanger,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: kKhataPaper,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: urgencyColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Smart suggest: ${controller.reminderToneLabel(insight.recommendedTone)}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canWriteData
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => AddUdhaarScreen(
                                    controller: controller,
                                    selectedCustomerId: liveCustomer.id,
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text('Add ${controller.creditLabel}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canWriteData
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => RecordPaymentScreen(
                                    controller: controller,
                                    customerId: liveCustomer.id,
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.payments_rounded),
                      label: const Text('Record Payment'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canWriteData
                          ? () => _openReminderComposer(context, liveCustomer)
                          : null,
                      icon: const Icon(Icons.message_rounded),
                      label: const Text('Compose Reminder'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: canWriteData
                          ? () async {
                              final launched = await controller.sendReminder(
                                liveCustomer,
                                tone: insight.recommendedTone,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    launched
                                        ? 'Smart reminder opened.'
                                        : 'The reminder could not be opened.',
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Smart Remind'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canWriteData
                          ? () => _scheduleFollowUp(context, liveCustomer)
                          : null,
                      icon: const Icon(Icons.schedule_rounded),
                      label: const Text('Schedule Follow-up'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: canWriteData
                          ? () => _openInstallmentPlanner(context, liveCustomer)
                          : null,
                      icon: const Icon(Icons.event_repeat_rounded),
                      label: const Text('Installment Plan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: canWriteData
                    ? () => _logVisit(context, liveCustomer)
                    : null,
                icon: const Icon(Icons.pin_drop_rounded),
                label: const Text('Log Visit'),
              ),
              if (liveCustomer.groupName.trim().isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: canWriteData
                      ? () => _sendGroupReminders(context, liveCustomer)
                      : null,
                  icon: const Icon(Icons.groups_rounded),
                  label: Text(
                    'Group Remind (${liveCustomer.groupName.trim()})',
                  ),
                ),
              ],
              const SizedBox(height: 18),
              if (pendingFollowUps.isNotEmpty ||
                  activePlan != null ||
                  latestVisit != null) ...<Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Follow-up tools',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        if (pendingFollowUps.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${pendingFollowUps.length} scheduled follow-ups pending.',
                            ),
                          ),
                        if (visitFollowUpCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '$visitFollowUpCount visit follow-up${visitFollowUpCount == 1 ? '' : 's'} pending.',
                            ),
                          ),
                        if (activePlan != null)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: latestVisit != null ? 10 : 0,
                            ),
                            child: Text(
                              'Active installment plan: ${activePlan.completedInstallments}/${activePlan.installmentCount} installments completed | next ${controller.formatDate(activePlan.nextDueDate)}',
                            ),
                          ),
                        if (latestVisit != null)
                          Text(
                            'Last visit: ${controller.formatDateTime(latestVisit.visitedAt)}'
                            '${latestVisit.note.isEmpty ? '' : ' | ${latestVisit.note}'}'
                            '${controller.customerVisitLocationSummary(latestVisit).isEmpty ? '' : ' | ${controller.customerVisitLocationSummary(latestVisit)}'}',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Access and risk tools',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage portal sharing, QR access, the local community risk wall, and the negotiation helper from here.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label: 'Portal code ${liveCustomer.shareCode}',
                            color: kKhataGreen,
                          ),
                          InsightChip(
                            label: blacklistMatches.isEmpty
                                ? 'No blacklist matches'
                                : '${blacklistMatches.length} blacklist matches',
                            color: blacklistMatches.isEmpty
                                ? kKhataSuccess
                                : kKhataDanger,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: canWriteData
                                  ? () =>
                                        _openPortalScreen(context, liveCustomer)
                                  : null,
                              icon: const Icon(Icons.qr_code_rounded),
                              label: const Text('Portal & QR'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openNegotiationHelper(context, liveCustomer),
                              icon: const Icon(Icons.record_voice_over_rounded),
                              label: const Text('Negotiation'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _openCommunityBlacklist(context, liveCustomer),
                        icon: const Icon(Icons.gpp_bad_rounded),
                        label: Text(
                          blacklistMatches.isEmpty
                              ? 'Community Blacklist'
                              : 'Community Blacklist (${blacklistMatches.length})',
                        ),
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
                        'Profile Notes',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (liveCustomer.address.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Address: ${liveCustomer.address}'),
                        ),
                      if (liveCustomer.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(liveCustomer.notes),
                        ),
                      if (liveCustomer.tag.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Tag: ${liveCustomer.tag}'),
                        ),
                      if (referredBy != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Referred by: ${referredBy.name}'
                            '${inheritedTrustBoost == 0 ? '' : ' | trust +$inheritedTrustBoost'}',
                          ),
                        ),
                      if (liveCustomer.groupName.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Group / Family: ${liveCustomer.groupName}',
                          ),
                        ),
                      if (liveCustomer.promisedPaymentDate != null)
                        Text(
                          'Promise: ${controller.formatDate(liveCustomer.promisedPaymentDate!)}'
                          '${liveCustomer.promisedPaymentAmount == null ? '' : ' | ${controller.displayCurrency(liveCustomer.promisedPaymentAmount!)}'}',
                        ),
                      if (liveCustomer.address.isEmpty &&
                          liveCustomer.notes.isEmpty &&
                          liveCustomer.tag.isEmpty &&
                          liveCustomer.promisedPaymentDate == null)
                        const Text('No extra notes yet.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              AdBannerStrip(
                enabled:
                    adsEnabled &&
                    controller.settings.adsEnabled &&
                    !controller.settings.isPaidUser,
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Reminder History',
                subtitle:
                    'WhatsApp actions and the follow-up trail are saved in local history.',
              ),
              const SizedBox(height: 12),
              if (reminders.isEmpty)
                const EmptyStateCard(
                  title: 'No reminder history yet',
                  message: 'Logs will appear here after reminders are sent.',
                )
              else
                ...reminders
                    .take(5)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    InsightChip(
                                      label: controller.reminderToneLabel(
                                        entry.tone,
                                      ),
                                      color: entry.wasSuccessful
                                          ? kKhataSuccess
                                          : kKhataDanger,
                                    ),
                                    const Spacer(),
                                    Text(
                                      controller.formatDateTime(entry.sentAt),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(entry.message),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Visit History',
                subtitle: 'Shop visits and manual visit logs are saved here.',
              ),
              const SizedBox(height: 12),
              if (visits.isEmpty)
                const EmptyStateCard(
                  title: 'No visit history yet',
                  message:
                      'Use Log Visit to build a stronger customer follow-up trail.',
                )
              else
                ...visits
                    .take(5)
                    .map(
                      (visit) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.pin_drop_rounded),
                            title: Text(
                              controller.formatDateTime(visit.visitedAt),
                            ),
                            subtitle: Text(
                              [
                                    visit.note.isEmpty
                                        ? 'Visit logged'
                                        : visit.note,
                                    controller.customerVisitLocationSummary(
                                      visit,
                                    ),
                                  ]
                                  .where((part) => part.trim().isNotEmpty)
                                  .join(' | '),
                            ),
                            trailing: visit.followUpDueAt == null
                                ? null
                                : Text(
                                    controller.formatDateTime(
                                      visit.followUpDueAt!,
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Transactions',
                subtitle:
                    'All credit (+) and payment (-) entries in one place.',
              ),
              const SizedBox(height: 12),
              if (transactions.isEmpty)
                const EmptyStateCard(
                  title: 'No transactions yet',
                  message:
                      'This customer first credit or payment entry will appear here.',
                )
              else
                ...transactions.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TransactionTile(
                      controller: controller,
                      transaction: entry,
                      onTap: () => _openTransactionDetail(context, entry),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _VisitLogSheet extends StatefulWidget {
  const _VisitLogSheet({
    required this.controller,
    required this.initialFollowUpAt,
  });

  final HisabRakhoController controller;
  final DateTime initialFollowUpAt;

  @override
  State<_VisitLogSheet> createState() => _VisitLogSheetState();
}

class _VisitLogSheetState extends State<_VisitLogSheet> {
  late final TextEditingController _noteController;
  late final TextEditingController _locationController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  late DateTime _followUpAt;
  bool _shouldScheduleFollowUp = true;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
    _locationController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _followUpAt = widget.initialFollowUpAt;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _locationController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _followUpAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_followUpAt),
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

  void _save() {
    Navigator.of(context).pop(
      _VisitLogDraft(
        note: _noteController.text.trim(),
        followUpAt: _shouldScheduleFollowUp ? _followUpAt : null,
        locationLabel: _locationController.text.trim(),
        latitude: double.tryParse(_latitudeController.text.trim()),
        longitude: double.tryParse(_longitudeController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Log Visit', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Save a visit note and schedule a follow-up if needed.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Visit note',
                hintText: 'Met the customer, received a payment promise, etc.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location label',
                hintText: 'Shop visit, home address, market lane, etc.',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _shouldScheduleFollowUp,
              contentPadding: EdgeInsets.zero,
              title: const Text('Schedule follow-up'),
              subtitle: const Text(
                'The next reminder will be added to the inbox after this visit.',
              ),
              onChanged: (value) {
                setState(() {
                  _shouldScheduleFollowUp = value;
                });
              },
            ),
            if (_shouldScheduleFollowUp) ...<Widget>[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await _pickScheduleDateTime();
                  if (picked == null || !mounted) {
                    return;
                  }
                  setState(() {
                    _followUpAt = picked;
                  });
                },
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  'Follow-up: ${widget.controller.formatDateTime(_followUpAt)}',
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save Visit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VisitLogDraft {
  const _VisitLogDraft({
    required this.note,
    required this.followUpAt,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
  });

  final String note;
  final DateTime? followUpAt;
  final String locationLabel;
  final double? latitude;
  final double? longitude;
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
