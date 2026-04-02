import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'add_customer_screen.dart';
import 'common_widgets.dart';
import 'reminder_composer_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({
    super.key,
    required this.controller,
    required this.adsEnabled,
    required this.onOpenCustomer,
    required this.onAddCustomer,
    required this.onAddUdhaar,
    required this.onRecordPayment,
  });

  final HisabRakhoController controller;
  final bool adsEnabled;
  final Future<void> Function(Customer customer) onOpenCustomer;
  final Future<void> Function() onAddCustomer;
  final Future<void> Function(String customerId) onAddUdhaar;
  final Future<void> Function(String customerId) onRecordPayment;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  CustomerFilter _selectedFilter = CustomerFilter.all;
  CustomerSort _selectedSort = CustomerSort.name;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editCustomer(Customer customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AddCustomerScreen(
          controller: widget.controller,
          customer: customer,
        ),
      ),
    );
  }

  Future<void> _toggleHidden(Customer customer) async {
    await widget.controller.upsertCustomer(
      customerId: customer.id,
      name: customer.name,
      phone: customer.phone,
      category: customer.category,
      address: customer.address,
      notes: customer.notes,
      tag: customer.tag,
      city: customer.city,
      cnic: customer.cnic,
      referredByCustomerId: customer.referredByCustomerId,
      groupName: customer.groupName,
      creditLimit: customer.creditLimit,
      isFavourite: customer.isFavourite,
      isHidden: !customer.isHidden,
      seasonalPauseMonths: customer.seasonalPauseMonths,
      promisedPaymentDate: customer.promisedPaymentDate,
      promisedPaymentAmount: customer.promisedPaymentAmount,
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${customer.name}?'),
          content: const Text(
            'This will remove the profile, transactions, and reminder history for this customer.',
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
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await widget.controller.deleteCustomer(customer.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${customer.name} was deleted.')));
  }

  Future<void> _openCustomerActions(Customer customer) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose a quick action for this profile.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit profile'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _editCustomer(customer);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    customer.isHidden
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  title: Text(
                    customer.isHidden ? 'Unhide profile' : 'Hide profile',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _toggleHidden(customer);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    customer.isFavourite
                        ? Icons.star_outline_rounded
                        : Icons.star_rounded,
                  ),
                  title: Text(
                    customer.isFavourite
                        ? 'Remove from favourites'
                        : 'Add to favourites',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.controller.toggleFavourite(customer.id);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: kKhataDanger,
                  ),
                  title: const Text('Delete profile'),
                  textColor: kKhataDanger,
                  iconColor: kKhataDanger,
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteCustomer(customer);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openReminder(Customer customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReminderComposerScreen(
          controller: widget.controller,
          customer: customer,
        ),
      ),
    );
  }

  void _showFilterHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Use the chips for quick filters. Search supports name, phone, category, city, and tags.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final customers = widget.controller.filteredCustomers(
            query: _searchController.text,
            filter: _selectedFilter,
            sort: _selectedSort,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    '${widget.controller.entityPluralLabel} (${customers.length})',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: _showFilterHelp,
                    icon: const Icon(Icons.filter_alt_outlined),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<CustomerSort>(
                    initialValue: _selectedSort,
                    onSelected: (value) {
                      setState(() {
                        _selectedSort = value;
                      });
                    },
                    itemBuilder: (context) {
                      return CustomerSort.values
                          .map(
                            (sort) => PopupMenuItem<CustomerSort>(
                              value: sort,
                              child: Text(
                                widget.controller.customerSortLabel(sort),
                              ),
                            ),
                          )
                          .toList();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(Icons.swap_vert_rounded),
                          const SizedBox(width: 8),
                          Text(
                            widget.controller.customerSortLabel(_selectedSort),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search name, phone, category, city, tag...',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: CustomerFilter.values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = CustomerFilter.values[index];
                    return ChoiceChip(
                      label: Text(
                        widget.controller.customerFilterLabel(filter),
                      ),
                      selected: _selectedFilter == filter,
                      onSelected: (_) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.controller.canWriteData
                          ? widget.onAddCustomer
                          : null,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(
                        'Add ${widget.controller.entitySingularLabel}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (customers.isEmpty)
                const EmptyStateCard(
                  title: 'No profiles found',
                  message:
                      'Try a different search, filter, or sort option, or add a new profile.',
                )
              else
                ...customers.map(
                  (customer) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey<String>('customer-${customer.id}'),
                      background: const _SwipeActionBackground(
                        icon: Icons.payments_rounded,
                        label: 'Record payment',
                        alignment: Alignment.centerLeft,
                        color: kKhataSuccess,
                      ),
                      secondaryBackground: const _SwipeActionBackground(
                        icon: Icons.message_outlined,
                        label: 'Send reminder',
                        alignment: Alignment.centerRight,
                        color: kKhataAmber,
                      ),
                      confirmDismiss: (direction) async {
                        if (!widget.controller.canWriteData) {
                          return false;
                        }
                        if (direction == DismissDirection.startToEnd) {
                          await widget.onRecordPayment(customer.id);
                        } else {
                          await _openReminder(customer);
                        }
                        return false;
                      },
                      child: CustomerListTileCard(
                        customer: customer,
                        controller: widget.controller,
                        onTap: () => widget.onOpenCustomer(customer),
                        onLongPress: () => _openCustomerActions(customer),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              AdBannerStrip(
                enabled:
                    widget.adsEnabled &&
                    widget.controller.settings.adsEnabled &&
                    !widget.controller.settings.isPaidUser,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SwipeActionBackground extends StatelessWidget {
  const _SwipeActionBackground({
    required this.icon,
    required this.label,
    required this.alignment,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerLeft
            ? <Widget>[
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(label, style: TextStyle(color: color)),
              ]
            : <Widget>[
                Text(label, style: TextStyle(color: color)),
                const SizedBox(width: 10),
                Icon(icon, color: color),
              ],
      ),
    );
  }
}

class CustomerListTileCard extends StatelessWidget {
  const CustomerListTileCard({
    super.key,
    required this.customer,
    required this.controller,
    required this.onTap,
    this.onLongPress,
  });

  final Customer customer;
  final HisabRakhoController controller;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final insight = controller.insightFor(customer.id);
    final color = _urgencyColor(insight.urgency);

    return Card(
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          foregroundColor: color,
          child: Text(customer.name.characters.first.toUpperCase()),
        ),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                customer.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (customer.isFavourite)
              const Icon(Icons.star_rounded, color: kKhataAmber, size: 20),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${customer.phone} | ${customer.category}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kKhataInk.withValues(alpha: 0.62),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (customer.isHidden)
                    const InsightChip(label: 'Hidden', color: kKhataDanger),
                  if (customer.groupName.trim().isNotEmpty)
                    InsightChip(label: customer.groupName, color: kKhataAmber),
                  InsightChip(
                    label: '${insight.recoveryScore}% score',
                    color: insight.paymentChance == PaymentChance.low
                        ? kKhataDanger
                        : kKhataSuccess,
                  ),
                  if (insight.overdueDays > 0)
                    InsightChip(
                      label: '${insight.overdueDays} days overdue',
                      color: kKhataDanger,
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              controller.displayCurrency(insight.balance),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () async {
                await controller.toggleFavourite(customer.id);
              },
              child: Text(
                customer.isFavourite ? 'Unpin' : 'Pin',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: kKhataGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
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
