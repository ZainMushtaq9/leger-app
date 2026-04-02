import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class BulkReminderScreen extends StatefulWidget {
  const BulkReminderScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  @override
  State<BulkReminderScreen> createState() => _BulkReminderScreenState();
}

class _BulkReminderScreenState extends State<BulkReminderScreen> {
  final Set<String> _completed = <String>{};
  final Set<String> _skipped = <String>{};
  final Set<String> _paused = <String>{};
  bool _sendingAll = false;

  Future<DateTime?> _pickScheduleDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !mounted) {
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

  Future<void> _sendNow(Customer customer) async {
    final launched = await widget.controller.sendReminder(customer);
    if (!mounted) {
      return;
    }
    setState(() {
      _completed.add(customer.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launched
              ? '${customer.name} ka reminder open ho gaya.'
              : '${customer.name} ka reminder open nahi ho saka.',
        ),
      ),
    );
  }

  Future<void> _schedule(Customer customer) async {
    final scheduledAt = await _pickScheduleDateTime();
    if (scheduledAt == null) {
      return;
    }

    await widget.controller.scheduleReminderFollowUp(
      customerId: customer.id,
      dueAt: scheduledAt,
      type: ReminderInboxType.bulkReminder,
      note: 'Bulk queue scheduled reminder',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _completed.add(customer.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${customer.name} ke liye ${widget.controller.formatDateTime(scheduledAt)} par reminder schedule ho gaya.',
        ),
      ),
    );
  }

  Future<void> _pause(Customer customer) async {
    final dueAt = DateTime.now().add(const Duration(days: 7));
    await widget.controller.scheduleReminderFollowUp(
      customerId: customer.id,
      dueAt: dueAt,
      type: ReminderInboxType.bulkReminder,
      note: 'Bulk queue paused for 7 days',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _paused.add(customer.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${customer.name} ko 7 din ke liye pause kar diya gaya.'),
      ),
    );
  }

  Future<void> _sendRemaining(List<Customer> customers) async {
    setState(() {
      _sendingAll = true;
    });

    for (final customer in customers) {
      if (_completed.contains(customer.id) ||
          _skipped.contains(customer.id) ||
          _paused.contains(customer.id)) {
        continue;
      }
      await _sendNow(customer);
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _sendingAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Reminder Queue')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final customers = widget.controller.customersWithPendingBalance;
          final remaining = customers.where(
            (customer) =>
                !_completed.contains(customer.id) &&
                !_skipped.contains(customer.id) &&
                !_paused.contains(customer.id),
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: <Widget>[
              const SectionHeader(
                title: 'Recovery Queue',
                subtitle:
                    'Har customer ke liye send now, schedule, ya skip ka clean flow.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  InsightChip(
                    label: '${customers.length} eligible',
                    color: kKhataAmber,
                  ),
                  InsightChip(
                    label: '${_completed.length} done',
                    color: kKhataSuccess,
                  ),
                  InsightChip(
                    label: '${_skipped.length} skipped',
                    color: kKhataDanger,
                  ),
                  InsightChip(
                    label: '${_paused.length} paused',
                    color: kKhataGreen,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _sendingAll || remaining.isEmpty
                    ? null
                    : () => _sendRemaining(remaining.toList()),
                icon: _sendingAll
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_to_mobile_rounded),
                label: Text(_sendingAll ? 'Sending...' : 'Send Remaining Now'),
              ),
              const SizedBox(height: 18),
              if (customers.isEmpty)
                const EmptyStateCard(
                  title: 'Bulk queue empty hai',
                  message: 'Pending balances hone par customers yahan aayenge.',
                )
              else
                ...customers.map((customer) {
                  final insight = widget.controller.insightFor(customer.id);
                  final isDone = _completed.contains(customer.id);
                  final isSkipped = _skipped.contains(customer.id);
                  final isPaused = _paused.contains(customer.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        customer.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(customer.phone),
                                    ],
                                  ),
                                ),
                                Text(
                                  widget.controller.displayCurrency(
                                    insight.balance,
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: kKhataDanger),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                InsightChip(
                                  label: '${insight.overdueDays} overdue days',
                                  color: insight.overdueDays > 30
                                      ? kKhataDanger
                                      : kKhataAmber,
                                ),
                                InsightChip(
                                  label: widget.controller.reminderToneLabel(
                                    insight.recommendedTone,
                                  ),
                                  color: kKhataSuccess,
                                ),
                                if (isDone)
                                  const InsightChip(
                                    label: 'Handled',
                                    color: kKhataSuccess,
                                  ),
                                if (isSkipped)
                                  const InsightChip(
                                    label: 'Skipped',
                                    color: kKhataDanger,
                                  ),
                                if (isPaused)
                                  const InsightChip(
                                    label: 'Paused',
                                    color: kKhataGreen,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: isDone || isSkipped || isPaused
                                        ? null
                                        : () => _sendNow(customer),
                                    icon: const Icon(Icons.send_rounded),
                                    label: const Text('Send now'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isDone || isSkipped || isPaused
                                        ? null
                                        : () => _schedule(customer),
                                    icon: const Icon(Icons.schedule_rounded),
                                    label: const Text('Schedule'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isDone || isSkipped || isPaused
                                        ? null
                                        : () => _pause(customer),
                                    icon: const Icon(Icons.pause_rounded),
                                    label: const Text('Pause'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: isDone || isSkipped || isPaused
                                        ? null
                                        : () {
                                            setState(() {
                                              _skipped.add(customer.id);
                                            });
                                          },
                                    icon: const Icon(Icons.skip_next_rounded),
                                    label: const Text('Skip'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
