import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'business_card_screen.dart';
import 'common_widgets.dart';
import 'group_accounts_screen.dart';
import 'offline_assistant_screen.dart';
import 'pos_sale_screen.dart';
import 'staff_payroll_screen.dart';
import 'wholesale_marketplace_screen.dart';

class BusinessScreen extends StatefulWidget {
  const BusinessScreen({
    super.key,
    required this.controller,
    required this.onOpenCustomer,
  });

  final HisabRakhoController controller;
  final Future<void> Function(Customer customer) onOpenCustomer;

  @override
  State<BusinessScreen> createState() => _BusinessScreenState();
}

class _BusinessScreenState extends State<BusinessScreen> {
  Future<void> _openPos() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => PosSaleScreen(controller: widget.controller),
      ),
    );
    if (saved != true || !mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sale saved successfully.')));
  }

  Future<void> _openInventoryEditor([InventoryItem? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final skuController = TextEditingController(text: existing?.sku ?? '');
    final barcodeController = TextEditingController(
      text: existing?.barcode ?? '',
    );
    final unitController = TextEditingController(text: existing?.unit ?? 'pcs');
    final stockController = TextEditingController(
      text: existing?.stockQuantity.toString() ?? '0',
    );
    final reorderController = TextEditingController(
      text: existing?.reorderLevel.toString() ?? '0',
    );
    final costController = TextEditingController(
      text: existing == null ? '' : existing.costPrice.toStringAsFixed(0),
    );
    final saleController = TextEditingController(
      text: existing == null ? '' : existing.salePrice.toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    String? selectedSupplierId = existing == null || existing.supplierId.isEmpty
        ? null
        : existing.supplierId;
    var archived = existing?.isArchived ?? false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      existing == null
                          ? 'Add inventory item'
                          : 'Edit inventory item',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Item name'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: skuController,
                            decoration: const InputDecoration(labelText: 'SKU'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: barcodeController,
                            decoration: const InputDecoration(
                              labelText: 'Barcode',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: unitController,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Opening stock',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: reorderController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Low stock at',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedSupplierId,
                            decoration: const InputDecoration(
                              labelText: 'Preferred supplier',
                            ),
                            items: <DropdownMenuItem<String>>[
                              const DropdownMenuItem<String>(
                                value: '',
                                child: Text('No supplier'),
                              ),
                              ...widget.controller.suppliers.map(
                                (supplier) => DropdownMenuItem<String>(
                                  value: supplier.id,
                                  child: Text(supplier.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                selectedSupplierId =
                                    (value == null || value.isEmpty)
                                    ? null
                                    : value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: costController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Cost price',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: saleController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Sale price',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes'),
                      minLines: 1,
                      maxLines: 2,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Archive item'),
                      subtitle: const Text('Hide from active inventory list'),
                      value: archived,
                      onChanged: (value) {
                        setModalState(() {
                          archived = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          return;
                        }
                        await widget.controller.saveInventoryItem(
                          inventoryItemId: existing?.id,
                          name: nameController.text.trim(),
                          sku: skuController.text.trim(),
                          barcode: barcodeController.text.trim(),
                          unit: unitController.text.trim(),
                          stockQuantity:
                              int.tryParse(stockController.text.trim()) ?? 0,
                          reorderLevel:
                              int.tryParse(reorderController.text.trim()) ?? 0,
                          costPrice:
                              double.tryParse(costController.text.trim()) ?? 0,
                          salePrice:
                              double.tryParse(saleController.text.trim()) ?? 0,
                          supplierId: selectedSupplierId ?? '',
                          notes: notesController.text.trim(),
                          isArchived: archived,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: Text(existing == null ? 'Add item' : 'Save item'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    nameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    unitController.dispose();
    stockController.dispose();
    reorderController.dispose();
    costController.dispose();
    saleController.dispose();
    notesController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inventory item saved successfully.')),
      );
    }
  }

  Future<void> _openGroupAccounts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GroupAccountsScreen(
          controller: widget.controller,
          onOpenCustomer: widget.onOpenCustomer,
        ),
      ),
    );
  }

  Future<void> _openStaffPayroll() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StaffPayrollScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openWholesaleMarketplace() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            WholesaleMarketplaceScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openBusinessCard() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BusinessCardScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openOfflineAssistant() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            OfflineAssistantScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openSupplierEditor([Supplier? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                existing == null ? 'Add supplier' : 'Edit supplier',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Supplier name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 1,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    return;
                  }
                  await widget.controller.saveSupplier(
                    supplierId: existing?.id,
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    notes: notesController.text.trim(),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                child: Text(
                  existing == null ? 'Add supplier' : 'Save supplier',
                ),
              ),
            ],
          ),
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    notesController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier saved successfully.')),
      );
    }
  }

  Future<void> _openSupplierPurchase(Supplier supplier) async {
    final quantityController = TextEditingController(text: '1');
    final unitCostController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedInventoryItemId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Record purchase - ${supplier.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedInventoryItemId,
                    decoration: const InputDecoration(
                      labelText: 'Inventory item',
                    ),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('No stock link'),
                      ),
                      ...widget.controller.inventoryItems.map(
                        (item) => DropdownMenuItem<String>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedInventoryItemId =
                            (value == null || value.isEmpty) ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: unitCostController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Unit cost',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Purchase note',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await widget.controller.recordSupplierPurchase(
                        supplierId: supplier.id,
                        inventoryItemId: selectedInventoryItemId ?? '',
                        quantity:
                            int.tryParse(quantityController.text.trim()) ?? 0,
                        unitCost:
                            double.tryParse(unitCostController.text.trim()) ??
                            0,
                        note: noteController.text.trim(),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Save purchase'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    quantityController.dispose();
    unitCostController.dispose();
    noteController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier purchase saved successfully.')),
      );
    }
  }

  Future<void> _openSupplierPayment(Supplier supplier) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Record payment - ${supplier.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Payment amount'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Payment note'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await widget.controller.recordSupplierPayment(
                    supplierId: supplier.id,
                    amount: double.tryParse(amountController.text.trim()) ?? 0,
                    note: noteController.text.trim(),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                child: const Text('Save payment'),
              ),
            ],
          ),
        );
      },
    );

    amountController.dispose();
    noteController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier payment saved successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final inventoryItems = widget.controller.inventoryItems;
          final suppliers = widget.controller.suppliers;
          final saleRecords = widget.controller.saleRecords.take(5).toList();
          final groupTotals = widget.controller.groupOutstandingTotals.entries
              .take(5)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: <Widget>[
              Text(
                'Business',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Manage inventory, suppliers, POS sales, and group totals in one place.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              SummaryCard(
                title: 'Stock retail value',
                value: widget.controller.displayCurrency(
                  widget.controller.totalInventoryRetailValue,
                ),
                subtitle:
                    '${widget.controller.inventoryItemCount} items • Cost ${widget.controller.displayCurrency(widget.controller.totalInventoryCostValue)}',
                accentColor: kKhataGreen,
                icon: Icons.inventory_2_rounded,
                prominent: true,
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Low stock',
                      value: '${widget.controller.lowStockItemCount}',
                      subtitle: 'Need attention',
                      accentColor: kKhataDanger,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Payables',
                      value: widget.controller.displayCurrency(
                        widget.controller.totalSupplierPayables,
                      ),
                      subtitle: '${widget.controller.supplierCount} suppliers',
                      accentColor: kKhataAmber,
                      icon: Icons.local_shipping_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Cash sales',
                      value: widget.controller.displayCurrency(
                        widget.controller.monthlyCashSales,
                      ),
                      subtitle: 'This month',
                      accentColor: kKhataSuccess,
                      icon: Icons.point_of_sale_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Gross margin',
                      value: widget.controller.displayCurrency(
                        widget.controller.monthlySalesMargin,
                      ),
                      subtitle: 'This month',
                      accentColor: kKhataGreen,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openGroupAccounts,
                      icon: const Icon(Icons.groups_rounded),
                      label: const Text('Group Accounts'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openStaffPayroll,
                      icon: const Icon(Icons.badge_rounded),
                      label: const Text('Staff & Payroll'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openWholesaleMarketplace,
                      icon: const Icon(Icons.storefront_rounded),
                      label: const Text('Wholesale'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openBusinessCard,
                      icon: const Icon(Icons.badge_outlined),
                      label: const Text('Business Card'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _openOfflineAssistant,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Offline Assistant'),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Staff Snapshot',
                subtitle:
                    'Track attendance, advances, payroll runs, and salary slips for your team.',
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Staff',
                      value: '${widget.controller.staffMembers.length}',
                      subtitle:
                          '${widget.controller.presentStaffTodayCount} marked today',
                      accentColor: kKhataGreen,
                      icon: Icons.badge_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Payroll',
                      value: widget.controller.displayCurrency(
                        widget.controller.monthlyPayrollNet,
                      ),
                      subtitle: 'Net this month',
                      accentColor: kKhataSuccess,
                      icon: Icons.payments_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Advances',
                      value: widget.controller.displayCurrency(
                        widget.controller.totalOutstandingStaffAdvances,
                      ),
                      subtitle: 'Outstanding deductions',
                      accentColor: kKhataAmber,
                      icon: Icons.request_quote_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Overtime',
                      value: widget.controller.monthlyStaffOvertimeHours
                          .toStringAsFixed(1),
                      subtitle: 'Hours this month',
                      accentColor: kKhataDanger,
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Inventory',
                subtitle: 'Manage low stock, pricing, and preferred suppliers.',
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.controller.canWriteData
                          ? () => _openInventoryEditor()
                          : null,
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text('Add item'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.controller.canWriteData
                          ? _openPos
                          : null,
                      icon: const Icon(Icons.point_of_sale_rounded),
                      label: const Text('POS sale'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (inventoryItems.isEmpty)
                const EmptyStateCard(
                  title: 'Inventory is empty',
                  message:
                      'Add an item first, then start a POS sale or a supplier purchase.',
                )
              else
                ...inventoryItems.map((item) {
                  final supplier = item.supplierId.trim().isEmpty
                      ? null
                      : widget.controller.supplierById(item.supplierId);
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
                                    item.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                if (item.isLowStock)
                                  const InsightChip(
                                    label: 'Low stock',
                                    color: kKhataDanger,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Stock ${item.stockQuantity} ${item.unit} • Sale ${widget.controller.displayCurrency(item.salePrice)} • Cost ${widget.controller.displayCurrency(item.costPrice)}',
                            ),
                            if (supplier != null) ...<Widget>[
                              const SizedBox(height: 4),
                              Text('Supplier: ${supplier.name}'),
                            ],
                            if (item.sku.trim().isNotEmpty ||
                                item.barcode.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  if (item.sku.trim().isNotEmpty)
                                    InsightChip(
                                      label: 'SKU ${item.sku}',
                                      color: kKhataGreen,
                                    ),
                                  if (item.barcode.trim().isNotEmpty)
                                    InsightChip(
                                      label: 'Code ${item.barcode}',
                                      color: kKhataAmber,
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: FilledButton.tonal(
                                    onPressed: widget.controller.canWriteData
                                        ? () => _openInventoryEditor(item)
                                        : null,
                                    child: const Text('Edit'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: widget.controller.canWriteData
                                        ? _openPos
                                        : null,
                                    child: const Text('Sell'),
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
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Suppliers',
                subtitle:
                    'Track payable balances using purchase and payment entries.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: widget.controller.canWriteData
                    ? () => _openSupplierEditor()
                    : null,
                icon: const Icon(Icons.person_add_alt_rounded),
                label: const Text('Add supplier'),
              ),
              const SizedBox(height: 12),
              if (suppliers.isEmpty)
                const EmptyStateCard(
                  title: 'No suppliers yet',
                  message:
                      'Add a supplier to start the purchase and payment ledger.',
                )
              else
                ...suppliers.map(
                  (supplier) => Padding(
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
                                    supplier.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  widget.controller.displayCurrency(
                                    widget.controller
                                        .supplierOutstandingBalance(
                                          supplier.id,
                                        ),
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: kKhataAmber),
                                ),
                              ],
                            ),
                            if (supplier.phone.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(supplier.phone),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _openSupplierEditor(supplier)
                                      : null,
                                  icon: const Icon(Icons.edit_rounded),
                                  label: const Text('Edit'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _openSupplierPurchase(supplier)
                                      : null,
                                  icon: const Icon(Icons.add_business_rounded),
                                  label: const Text('Purchase'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _openSupplierPayment(supplier)
                                      : null,
                                  icon: const Icon(Icons.payments_rounded),
                                  label: const Text('Payment'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Recent sales',
                subtitle: 'A live snapshot of recent cash and credit sales.',
              ),
              const SizedBox(height: 12),
              if (saleRecords.isEmpty)
                const EmptyStateCard(
                  title: 'No sales recorded yet',
                  message:
                      'Recent sales will appear here as soon as a POS sale is saved.',
                )
              else
                ...saleRecords.map((sale) {
                  final customer = sale.customerId == null
                      ? null
                      : widget.controller.customerById(sale.customerId!);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        title: Text(
                          sale.type == SaleRecordType.cash
                              ? 'Cash sale'
                              : 'Udhaar sale',
                        ),
                        subtitle: Text(
                          '${sale.lineItems.length} items • ${sale.totalUnits} units'
                          '${customer == null ? '' : ' • ${customer.name}'}'
                          '\n${widget.controller.formatDateTime(sale.date)}',
                        ),
                        trailing: Text(
                          widget.controller.displayCurrency(sale.totalAmount),
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(color: kKhataGreen),
                        ),
                        onTap: customer == null
                            ? null
                            : () => widget.onOpenCustomer(customer),
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Group totals',
                subtitle: 'Family or group-based credit summary.',
              ),
              const SizedBox(height: 12),
              if (groupTotals.isEmpty)
                const EmptyStateCard(
                  title: 'No group balance yet',
                  message:
                      'The summary will appear here once customer profiles have group names.',
                )
              else
                ...groupTotals.map((entry) {
                  final members = widget.controller.groupedCustomers(entry.key);
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
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  widget.controller.displayCurrency(
                                    entry.value,
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: kKhataDanger),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${members.length} members • ${members.map((customer) => customer.name).take(4).join(', ')}',
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
