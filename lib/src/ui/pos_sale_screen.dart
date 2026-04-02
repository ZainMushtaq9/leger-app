import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class PosSaleScreen extends StatefulWidget {
  const PosSaleScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  @override
  State<PosSaleScreen> createState() => _PosSaleScreenState();
}

class _PosSaleScreenState extends State<PosSaleScreen> {
  final TextEditingController _noteController = TextEditingController();
  final Map<String, int> _quantities = <String, int>{};
  SaleRecordType _saleType = SaleRecordType.cash;
  String? _selectedCustomerId;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _dueDate = picked;
    });
  }

  void _changeQuantity(InventoryItem item, int delta) {
    final current = _quantities[item.id] ?? 0;
    final next = (current + delta).clamp(0, item.stockQuantity);
    setState(() {
      if (next == 0) {
        _quantities.remove(item.id);
      } else {
        _quantities[item.id] = next;
      }
    });
  }

  List<SaleLineItem> _selectedLineItems(List<InventoryItem> items) {
    return items
        .where((item) => (_quantities[item.id] ?? 0) > 0)
        .map(
          (item) => SaleLineItem(
            inventoryItemId: item.id,
            itemName: item.name,
            quantity: _quantities[item.id] ?? 0,
            unitPrice: item.salePrice,
            costPrice: item.costPrice,
          ),
        )
        .toList();
  }

  Future<void> _save(List<InventoryItem> items) async {
    final lineItems = _selectedLineItems(items);
    if (lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one item.')),
      );
      return;
    }
    if (_saleType == SaleRecordType.udhaar &&
        (_selectedCustomerId == null || _selectedCustomerId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a customer for the udhaar sale.')),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      if (_saleType == SaleRecordType.cash) {
        await widget.controller.recordCashSale(
          lineItems: lineItems,
          note: _noteController.text.trim(),
        );
      } else {
        await widget.controller.recordInventorySaleAsUdhaar(
          customerId: _selectedCustomerId!,
          lineItems: lineItems,
          note: _noteController.text.trim(),
          dueDate: _dueDate,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final items = widget.controller.inventoryItems
            .where((item) => item.stockQuantity > 0)
            .toList();
        final customers = widget.controller.customers;
        final lineItems = _selectedLineItems(items);
        final totalAmount = lineItems.fold<double>(
          0,
          (total, item) => total + item.lineTotal,
        );
        final totalMargin = lineItems.fold<double>(
          0,
          (total, item) => total + item.lineMargin,
        );
        final totalUnits = lineItems.fold<int>(
          0,
          (total, item) => total + item.quantity,
        );

        return Scaffold(
          appBar: AppBar(title: const Text('Mini POS')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: <Widget>[
                const SectionHeader(
                  title: 'Inventory sale',
                  subtitle:
                      'Save a cash sale or convert inventory directly into an udhaar entry.',
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DropdownButtonFormField<SaleRecordType>(
                          initialValue: _saleType,
                          decoration: const InputDecoration(
                            labelText: 'Sale type',
                          ),
                          items: const <DropdownMenuItem<SaleRecordType>>[
                            DropdownMenuItem(
                              value: SaleRecordType.cash,
                              child: Text('Cash sale'),
                            ),
                            DropdownMenuItem(
                              value: SaleRecordType.udhaar,
                              child: Text('Convert to udhaar'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _saleType = value;
                              if (_saleType == SaleRecordType.cash) {
                                _selectedCustomerId = null;
                                _dueDate = null;
                              }
                            });
                          },
                        ),
                        if (_saleType == SaleRecordType.udhaar) ...<Widget>[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCustomerId,
                            decoration: const InputDecoration(
                              labelText: 'Customer',
                            ),
                            items: customers
                                .map(
                                  (customer) => DropdownMenuItem<String>(
                                    value: customer.id,
                                    child: Text(customer.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCustomerId = value;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _pickDueDate,
                            icon: const Icon(Icons.event_rounded),
                            label: Text(
                              _dueDate == null
                                  ? 'Optional due date'
                                  : widget.controller.formatDate(_dueDate!),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Sale note',
                          ),
                          minLines: 1,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  const EmptyStateCard(
                    title: 'Inventory is empty',
                    message:
                        'Add inventory items first or increase stock through a supplier purchase.',
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      item.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stock ${item.stockQuantity} ${item.unit} • ${widget.controller.displayCurrency(item.salePrice)}',
                                    ),
                                    if (item.isLowStock) ...<Widget>[
                                      const SizedBox(height: 6),
                                      const InsightChip(
                                        label: 'Low stock',
                                        color: kKhataDanger,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => _changeQuantity(item, -1),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text(
                                '${_quantities[item.id] ?? 0}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              IconButton(
                                onPressed: () => _changeQuantity(item, 1),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                SummaryCard(
                  title: 'POS total',
                  value: widget.controller.displayCurrency(totalAmount),
                  subtitle:
                      '$totalUnits units • Margin ${widget.controller.displayCurrency(totalMargin)}',
                  accentColor: kKhataGreen,
                  icon: Icons.point_of_sale_rounded,
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: FilledButton.icon(
                onPressed: _saving || items.isEmpty ? null : () => _save(items),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _saleType == SaleRecordType.cash
                            ? Icons.payments_rounded
                            : Icons.receipt_long_rounded,
                      ),
                label: Text(
                  _saleType == SaleRecordType.cash
                      ? 'Save cash sale'
                      : 'Convert to udhaar',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
