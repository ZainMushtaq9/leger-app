import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class NegotiationHelperScreen extends StatelessWidget {
  const NegotiationHelperScreen({
    super.key,
    required this.controller,
    required this.customer,
  });

  final HisabRakhoController controller;
  final Customer customer;

  Future<void> _copyScript(BuildContext context, String script) async {
    await Clipboard.setData(ClipboardData(text: script));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Negotiation script copied.')));
  }

  Future<void> _shareScript(
    BuildContext context,
    Customer liveCustomer,
    String script,
  ) async {
    await SharePlus.instance.share(
      ShareParams(title: '${liveCustomer.name} negotiation plan', text: script),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Negotiation script shared.')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final liveCustomer = controller.customerById(customer.id) ?? customer;
        final insight = controller.insightFor(liveCustomer.id);
        final script = controller.buildNegotiationScript(liveCustomer);
        final matches = controller.communityBlacklistMatchesForCustomer(
          liveCustomer.id,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Negotiation Helper')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        liveCustomer.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          InsightChip(
                            label:
                                'Tone ${controller.reminderToneLabel(insight.recommendedTone)}',
                            color: _toneColor(insight.recommendedTone),
                          ),
                          InsightChip(
                            label:
                                'Balance ${controller.displayCurrency(insight.balance)}',
                            color: insight.balance > 0
                                ? kKhataAmber
                                : kKhataSuccess,
                          ),
                          InsightChip(
                            label: '${insight.overdueDays} overdue days',
                            color: insight.overdueDays >= 30
                                ? kKhataDanger
                                : kKhataAmber,
                          ),
                          if (matches.isNotEmpty)
                            InsightChip(
                              label: '${matches.length} community flags',
                              color: kKhataDanger,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'The offline negotiation helper uses the live balance, overdue status, promise dates, visits, and installment plans to build a ready-to-use script.',
                        style: Theme.of(context).textTheme.bodyMedium,
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
                      onPressed: () => _copyScript(context, script),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Script'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _shareScript(context, liveCustomer, script),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share Script'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Negotiation Playbook',
                subtitle:
                    'A ready-to-use script for calls, WhatsApp follow-ups, or in-person visits.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SelectableText(script),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Color _toneColor(ReminderTone tone) {
  switch (tone) {
    case ReminderTone.soft:
      return kKhataSuccess;
    case ReminderTone.normal:
      return kKhataAmber;
    case ReminderTone.strict:
      return kKhataDanger;
  }
}
