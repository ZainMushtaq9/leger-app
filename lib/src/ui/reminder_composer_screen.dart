import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class ReminderComposerScreen extends StatefulWidget {
  const ReminderComposerScreen({
    super.key,
    required this.controller,
    required this.customer,
  });

  final HisabRakhoController controller;
  final Customer customer;

  @override
  State<ReminderComposerScreen> createState() => _ReminderComposerScreenState();
}

class _ReminderComposerScreenState extends State<ReminderComposerScreen> {
  late ReminderTone _selectedTone;
  late TextEditingController _messageController;
  String _selectedChannel = 'whatsapp';
  bool _sending = false;
  bool _scheduling = false;

  @override
  void initState() {
    super.initState();
    _selectedTone = widget.controller
        .insightFor(widget.customer.id)
        .recommendedTone;
    _messageController = TextEditingController(
      text: widget.controller.generateReminderMessage(
        widget.customer,
        tone: _selectedTone,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _applyTone(ReminderTone tone) {
    setState(() {
      _selectedTone = tone;
      _messageController.text = widget.controller.generateReminderMessage(
        widget.customer,
        tone: tone,
      );
    });
  }

  void _insertVariable(String value) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;
    final updated = text.replaceRange(start, end, value);
    _messageController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

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

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    setState(() {
      _sending = true;
    });

    final launched = await widget.controller.sendCustomReminder(
      widget.customer,
      message: message,
      tone: _selectedTone,
      channel: _selectedChannel,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _sending = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launched
              ? '${_selectedChannel == 'sms' ? 'SMS' : 'WhatsApp'} reminder open ho gaya.'
              : 'Reminder open nahi ho saka.',
        ),
      ),
    );
    if (launched) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _schedule() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      return;
    }

    final scheduledAt = await _pickScheduleDateTime();
    if (scheduledAt == null || !mounted) {
      return;
    }

    setState(() {
      _scheduling = true;
    });

    await widget.controller.scheduleReminderFollowUp(
      customerId: widget.customer.id,
      dueAt: scheduledAt,
      tone: _selectedTone,
      type: widget.customer.promisedPaymentDate != null
          ? ReminderInboxType.promiseFollowUp
          : ReminderInboxType.scheduledReminder,
      channel: _selectedChannel,
      message: message,
      note: 'Reminder composer schedule',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _scheduling = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder ${widget.controller.formatDateTime(scheduledAt)} ke liye schedule ho gaya.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final insight = widget.controller.insightFor(widget.customer.id);
    final history = widget.controller.remindersFor(widget.customer.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Composer')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: <Widget>[
              Text(
                widget.customer.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Pending balance ${widget.controller.displayCurrency(insight.balance)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ReminderTone.values.map((tone) {
                  return ChoiceChip(
                    label: Text(widget.controller.reminderToneLabel(tone)),
                    selected: _selectedTone == tone,
                    onSelected: (_) => _applyTone(tone),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(
                    value: 'whatsapp',
                    icon: Icon(Icons.chat_rounded),
                    label: Text('WhatsApp'),
                  ),
                  ButtonSegment<String>(
                    value: 'sms',
                    icon: Icon(Icons.sms_outlined),
                    label: Text('SMS'),
                  ),
                ],
                selected: <String>{_selectedChannel},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedChannel = selection.first;
                  });
                },
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _messageController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Editable message',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ActionChip(
                    label: const Text('Name'),
                    onPressed: () => _insertVariable(widget.customer.name),
                  ),
                  ActionChip(
                    label: const Text('Balance'),
                    onPressed: () => _insertVariable(
                      widget.controller.displayCurrency(insight.balance),
                    ),
                  ),
                  if (widget.customer.promisedPaymentDate != null)
                    ActionChip(
                      label: const Text('Promise Date'),
                      onPressed: () => _insertVariable(
                        widget.controller.formatDate(
                          widget.customer.promisedPaymentDate!,
                        ),
                      ),
                    ),
                  ActionChip(
                    label: const Text('Shop Name'),
                    onPressed: () =>
                        _insertVariable(widget.controller.organizationName),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  if (widget.customer.promisedPaymentDate != null)
                    InsightChip(
                      label:
                          'Promise ${widget.controller.formatDate(widget.customer.promisedPaymentDate!)}',
                      color: kKhataAmber,
                    ),
                  if (insight.seasonalPauseActive) ...<Widget>[
                    const SizedBox(width: 8),
                    const InsightChip(
                      label: 'Seasonal pause',
                      color: kKhataSuccess,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _sending
                            ? 'Sending...'
                            : 'Send ${_selectedChannel == 'sms' ? 'SMS' : 'WhatsApp'} Reminder',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _scheduling ? null : _schedule,
                      icon: _scheduling
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.schedule_rounded),
                      label: Text(_scheduling ? 'Scheduling...' : 'Schedule'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Reminder History',
                subtitle:
                    'Har sent reminder ka tone aur preview yahan local history mein save rehta hai.',
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                const EmptyStateCard(
                  title: 'Abhi koi reminder log nahi',
                  message:
                      'Yahan WhatsApp aur SMS reminder history nazar aayegi.',
                )
              else
                ...history.map(
                  (log) => Padding(
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
                                  label: widget.controller.reminderToneLabel(
                                    log.tone,
                                  ),
                                  color: log.wasSuccessful
                                      ? kKhataSuccess
                                      : kKhataDanger,
                                ),
                                const SizedBox(width: 8),
                                InsightChip(
                                  label: log.channel,
                                  color: kKhataAmber,
                                ),
                                const Spacer(),
                                Text(
                                  widget.controller.formatDateTime(log.sentAt),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(log.message),
                          ],
                        ),
                      ),
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
