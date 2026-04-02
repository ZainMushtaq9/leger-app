import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import 'common_widgets.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key, required this.controller, this.customer});

  final HisabRakhoController controller;
  final Customer? customer;

  bool get isEditing => customer != null;

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _promiseAmountController =
      TextEditingController();

  String _selectedCategory = 'Regular';
  String? _selectedReferralCustomerId;
  bool _isFavourite = false;
  bool _isHidden = false;
  bool _saving = false;
  DateTime? _promisedPaymentDate;
  final Set<int> _seasonalPauseMonths = <int>{};

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    if (customer == null) {
      return;
    }

    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _addressController.text = customer.address;
    _notesController.text = customer.notes;
    _tagController.text = customer.tag;
    _cityController.text = customer.city;
    _cnicController.text = customer.cnic;
    _groupNameController.text = customer.groupName;
    _creditLimitController.text =
        customer.creditLimit?.toStringAsFixed(0) ?? '';
    _promiseAmountController.text =
        customer.promisedPaymentAmount?.toStringAsFixed(0) ?? '';
    _selectedCategory = customer.category;
    _selectedReferralCustomerId = customer.referredByCustomerId;
    _isFavourite = customer.isFavourite;
    _isHidden = customer.isHidden;
    _promisedPaymentDate = customer.promisedPaymentDate;
    _seasonalPauseMonths.addAll(customer.seasonalPauseMonths);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _cityController.dispose();
    _cnicController.dispose();
    _groupNameController.dispose();
    _creditLimitController.dispose();
    _promiseAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickPromiseDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _promisedPaymentDate ?? now.add(const Duration(days: 3)),
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _promisedPaymentDate = picked;
    });
  }

  double? _parseNumber(String raw) {
    final value = raw.replaceAll(',', '').trim();
    if (value.isEmpty) {
      return null;
    }
    return double.tryParse(value);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    await widget.controller.upsertCustomer(
      customerId: widget.customer?.id,
      name: _nameController.text,
      phone: _phoneController.text,
      category: _selectedCategory,
      address: _addressController.text,
      notes: _notesController.text,
      tag: _tagController.text,
      city: _cityController.text,
      cnic: _cnicController.text,
      referredByCustomerId: _selectedReferralCustomerId,
      groupName: _groupNameController.text,
      creditLimit: _parseNumber(_creditLimitController.text),
      isFavourite: _isFavourite,
      isHidden: _isHidden,
      seasonalPauseMonths: _seasonalPauseMonths.toList()..sort(),
      promisedPaymentDate: _promisedPaymentDate,
      promisedPaymentAmount: _parseNumber(_promiseAmountController.text),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing
              ? '${widget.controller.entitySingularLabel} updated successfully.'
              : '${widget.controller.entitySingularLabel} saved successfully.',
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.controller.categoryOptions;
    final referralOptions = widget.controller.availableReferralCustomers(
      excludeCustomerId: widget.customer?.id,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? 'Edit ${widget.controller.entitySingularLabel}'
              : 'Add ${widget.controller.entitySingularLabel}',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: <Widget>[
            Text(
              widget.isEditing
                  ? 'Update this profile'
                  : 'Create a new profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Capture the contact details, recovery notes, hidden status, and payment planning for this customer.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: widget.controller.entitySingularLabel == 'Student'
                    ? 'Student Name'
                    : 'Name',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name zaroori hai';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: widget.controller.categoryLabel,
              ),
              items: categories
                  .map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '03001234567',
              ),
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (digits.length < 10) {
                  return 'Valid phone number dein';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _selectedReferralCustomerId,
              decoration: const InputDecoration(labelText: 'Referred By'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No referral'),
                ),
                ...referralOptions.map(
                  (customer) => DropdownMenuItem<String?>(
                    value: customer.id,
                    child: Text(customer.name),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedReferralCustomerId = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cnicController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CNIC',
                      hintText: '35202...',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Mohalla, street, area',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group / Family',
                hintText: 'Family account, staff, class...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      labelText: 'Tag',
                      hintText: 'trusted / often late',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _creditLimitController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Credit Limit',
                      hintText: '5000',
                    ),
                    validator: (value) {
                      final amount = _parseNumber(value ?? '');
                      if (amount != null && amount < 0) {
                        return 'Negative limit valid nahi hai';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Recovery planning',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickPromiseDate,
                            icon: const Icon(Icons.event_available_rounded),
                            label: Text(
                              _promisedPaymentDate == null
                                  ? 'Promise date'
                                  : 'Promise ${widget.controller.formatDate(_promisedPaymentDate!)}',
                            ),
                          ),
                        ),
                        if (_promisedPaymentDate != null) ...<Widget>[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _promisedPaymentDate = null;
                              });
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _promiseAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Promised Amount',
                        hintText: '2500',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seasonal pause months',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List<Widget>.generate(12, (index) {
                        final month = index + 1;
                        final active = _seasonalPauseMonths.contains(month);
                        return FilterChip(
                          label: Text(_monthLabel(month)),
                          selected: active,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _seasonalPauseMonths.add(month);
                              } else {
                                _seasonalPauseMonths.remove(month);
                              }
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Favourite profile'),
                      subtitle: const Text(
                        'List ke top par aur dashboard par highlight hoga',
                      ),
                      value: _isFavourite,
                      onChanged: (value) {
                        setState(() {
                          _isFavourite = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hidden profile'),
                      subtitle: const Text(
                        'Private badge ke sath visible rahega',
                      ),
                      value: _isHidden,
                      onChanged: (value) {
                        setState(() {
                          _isHidden = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Private Notes',
                        hintText:
                            'Payment behavior, relationship, reminders...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Profile'),
            ),
            const SizedBox(height: 14),
            const EmptyStateCard(
              title: 'How this profile is used',
              message:
                  'This data is used directly by reminders, reports, smart recovery actions, and customer statements.',
            ),
          ],
        ),
      ),
    );
  }

  String _monthLabel(int month) {
    const labels = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return labels[month - 1];
  }
}
