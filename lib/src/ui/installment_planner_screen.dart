import 'package:flutter/material.dart';

import '../controller.dart';
import '../models.dart';
import '../theme.dart';
import 'common_widgets.dart';

class InstallmentPlannerScreen extends StatefulWidget {
  const InstallmentPlannerScreen({
    super.key,
    required this.controller,
    required this.customer,
  });

  final HisabRakhoController controller;
  final Customer customer;

  @override
  State<InstallmentPlannerScreen> createState() =>
      _InstallmentPlannerScreenState();
}

class _InstallmentPlannerScreenState extends State<InstallmentPlannerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _countController = TextEditingController(
    text: '3',
  );
  final TextEditingController _intervalController = TextEditingController(
    text: '30',
  );
  final TextEditingController _noteController = TextEditingController();
  DateTime _firstDueDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final insight = widget.controller.insightFor(widget.customer.id);
    _amountController.text = insight.balance.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _countController.dispose();
    _intervalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFirstDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _firstDueDate = picked;
    });
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    await widget.controller.createInstallmentPlan(
      customerId: widget.customer.id,
      totalAmount: double.parse(_amountController.text.replaceAll(',', '')),
      installmentCount: int.parse(_countController.text),
      intervalDays: int.parse(_intervalController.text),
      firstDueDate: _firstDueDate,
      note: _noteController.text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Installment plan create ho gaya.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Installment Planner')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final plans = widget.controller.installmentPlansFor(
            widget.customer.id,
          );
          final activePlan = widget.controller.activeInstallmentPlanFor(
            widget.customer.id,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: <Widget>[
              Text(
                widget.customer.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Pending balance ${widget.controller.displayCurrency(widget.controller.insightFor(widget.customer.id).balance)}',
              ),
              const SizedBox(height: 20),
              if (activePlan != null)
                _ActivePlanCard(
                  controller: widget.controller,
                  plan: activePlan,
                  onRecordInstallment: () async {
                    await widget.controller.recordInstallmentPayment(
                      activePlan.id,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Installment payment record ho gayi.'),
                      ),
                    );
                  },
                  onTogglePause: () =>
                      widget.controller.toggleInstallmentPlanPause(
                        activePlan.id,
                        isPaused: !activePlan.isPaused,
                      ),
                )
              else
                const EmptyStateCard(
                  title: 'Active plan nahi hai',
                  message:
                      'Neeche se kisti plan bana kar due reminders aur tracking start karein.',
                ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Create New Plan',
                subtitle:
                    'Balance ko realistic kistion mein tod kar next due reminders schedule karein.',
              ),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Plan amount',
                          ),
                          validator: (value) {
                            final amount = double.tryParse(
                              (value ?? '').replaceAll(',', ''),
                            );
                            if (amount == null || amount <= 0) {
                              return 'Valid amount dein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _countController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Installments count',
                          ),
                          validator: (value) {
                            final count = int.tryParse(value ?? '');
                            if (count == null || count <= 0) {
                              return 'Count sahi dein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _intervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Gap between installments (days)',
                          ),
                          validator: (value) {
                            final days = int.tryParse(value ?? '');
                            if (days == null || days <= 0) {
                              return 'Days sahi dein';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickFirstDueDate,
                          icon: const Icon(Icons.event_available_rounded),
                          label: Text(
                            'First due ${widget.controller.formatDate(_firstDueDate)}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Plan note',
                            hintText: 'Example: monthly recovery plan',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _saving ? null : _createPlan,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.event_repeat_rounded),
                          label: Text(_saving ? 'Saving...' : 'Create Plan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Plan History',
                subtitle: 'Customer ke tamam kisti plans ka local record.',
              ),
              const SizedBox(height: 12),
              if (plans.isEmpty)
                const EmptyStateCard(
                  title: 'Koi plan history nahi',
                  message:
                      'Naya plan create karne ke baad history yahan aayegi.',
                )
              else
                ...plans.map(
                  (plan) => Padding(
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
                                    '${plan.completedInstallments}/${plan.installmentCount} installments',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                InsightChip(
                                  label: plan.isCompleted
                                      ? 'Completed'
                                      : plan.isPaused
                                      ? 'Paused'
                                      : 'Active',
                                  color: plan.isCompleted
                                      ? kKhataSuccess
                                      : plan.isPaused
                                      ? kKhataAmber
                                      : kKhataGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Each installment ${widget.controller.displayCurrency(plan.installmentAmount)} | next due ${widget.controller.formatDate(plan.nextDueDate)}',
                            ),
                            if (plan.note.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(plan.note),
                            ],
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

class _ActivePlanCard extends StatelessWidget {
  const _ActivePlanCard({
    required this.controller,
    required this.plan,
    required this.onRecordInstallment,
    required this.onTogglePause,
  });

  final HisabRakhoController controller;
  final InstallmentPlan plan;
  final VoidCallback onRecordInstallment;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context) {
    final progress = plan.installmentCount == 0
        ? 0.0
        : plan.completedInstallments / plan.installmentCount;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Active Kisti Plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                InsightChip(
                  label:
                      '${plan.completedInstallments}/${plan.installmentCount} done',
                  color: kKhataSuccess,
                ),
                InsightChip(
                  label: controller.displayCurrency(plan.installmentAmount),
                  color: kKhataAmber,
                ),
                InsightChip(
                  label: 'Next ${controller.formatDate(plan.nextDueDate)}',
                  color: plan.nextDueDate.isBefore(DateTime.now())
                      ? kKhataDanger
                      : kKhataGreen,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Remaining ${controller.displayCurrency(plan.remainingAmount)} in ${plan.remainingInstallments} installments.',
            ),
            if (plan.note.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(plan.note),
            ],
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: plan.isPaused ? null : onRecordInstallment,
                    icon: const Icon(Icons.payments_rounded),
                    label: const Text('Record installment'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTogglePause,
                    icon: Icon(
                      plan.isPaused
                          ? Icons.play_circle_outline_rounded
                          : Icons.pause_circle_outline_rounded,
                    ),
                    label: Text(plan.isPaused ? 'Resume' : 'Pause'),
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
