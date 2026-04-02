import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class GroupAccountsScreen extends StatelessWidget {
  const GroupAccountsScreen({
    super.key,
    required this.controller,
    required this.onOpenCustomer,
  });

  final HisabRakhoController controller;
  final Future<void> Function(Customer customer) onOpenCustomer;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final groupTotals = controller.groupOutstandingTotals.entries.toList()
          ..sort((left, right) => right.value.compareTo(left.value));

        return Scaffold(
          appBar: AppBar(title: const Text('Group Accounts')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: <Widget>[
              const SectionHeader(
                title: 'Family and group totals',
                subtitle:
                    'Review shared balances, open member profiles, and send reminders to an entire group.',
              ),
              const SizedBox(height: 12),
              if (groupTotals.isEmpty)
                const EmptyStateCard(
                  title: 'No group accounts yet',
                  message:
                      'Add a group or family name to customer profiles and their combined totals will appear here.',
                )
              else
                ...groupTotals.map((entry) {
                  final members = controller.groupedCustomers(entry.key);
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
                                  child: Text(
                                    entry.key,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                Text(
                                  controller.displayCurrency(entry.value),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: kKhataDanger),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: members
                                  .map(
                                    (customer) => ActionChip(
                                      label: Text(customer.name),
                                      onPressed: () => onOpenCustomer(customer),
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.tonalIcon(
                              onPressed: !controller.canWriteData
                                  ? null
                                  : () async {
                                      final result = await controller
                                          .sendGroupReminders(entry.key);
                                      if (!context.mounted) {
                                        return;
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Opened reminders for ${result.opened} of ${result.totalEligible} group members.',
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.groups_rounded),
                              label: const Text('Remind All'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
