import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../controller.dart';
import '../models.dart';
import '../services/document_export_service.dart';
import '../theme.dart';
import 'common_widgets.dart';
import 'document_preview_screen.dart';

class StaffPayrollScreen extends StatefulWidget {
  const StaffPayrollScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  @override
  State<StaffPayrollScreen> createState() => _StaffPayrollScreenState();
}

class _StaffPayrollScreenState extends State<StaffPayrollScreen> {
  final DocumentExportService _documentExportService =
      const DocumentExportService();

  String _safeFileName(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return normalized.isEmpty ? 'salary_slip' : normalized;
  }

  Future<void> _showSavedFileMessage(String fileLabel, String? path) async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null || path.trim().isEmpty
              ? '$fileLabel download started.'
              : '$fileLabel saved: $path',
        ),
      ),
    );
  }

  Future<void> _saveTextExport({
    required String fileLabel,
    required String content,
  }) async {
    final path = await _documentExportService.saveTextFile(
      fileLabel: fileLabel,
      content: content,
    );
    await _showSavedFileMessage(fileLabel, path);
  }

  Future<void> _savePdfExport({
    required String title,
    required String fileLabel,
    required String documentText,
  }) async {
    final pdfBytes = await _documentExportService.buildTextPdf(
      title: title,
      documentText: documentText,
    );
    final path = await _documentExportService.saveBinaryFile(
      fileLabel: fileLabel,
      bytes: pdfBytes,
    );
    await _showSavedFileMessage(fileLabel, path);
  }

  Future<void> _printPdfDocument({
    required String title,
    required String fileLabel,
    required String documentText,
  }) async {
    final pdfBytes = await _documentExportService.buildTextPdf(
      title: title,
      documentText: documentText,
    );
    await _documentExportService.printPdf(jobName: fileLabel, bytes: pdfBytes);
  }

  Future<void> _shareSlip(StaffPayrollRun run) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Salary Slip',
        text: widget.controller.buildSalarySlipDocument(run),
      ),
    );
  }

  Future<void> _openSlipPreview(StaffPayrollRun run) async {
    final staff = widget.controller.staffMemberById(run.staffId);
    final fileBase = _safeFileName(
      '${staff?.name ?? 'staff'}_${widget.controller.salarySlipNumberForRun(run)}',
    );
    final documentText = widget.controller.buildSalarySlipDocument(run);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DocumentPreviewScreen(
          title: 'Salary Slip',
          documentText: documentText,
          onShare: () => _shareSlip(run),
          onDownload: () => _saveTextExport(
            fileLabel: '$fileBase.txt',
            content: documentText,
          ),
          onPrint: () => _printPdfDocument(
            title: 'Salary Slip',
            fileLabel: '$fileBase.pdf',
            documentText: documentText,
          ),
        ),
      ),
    );
  }

  Future<void> _openStaffEditor([StaffMember? existing]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final roleController = TextEditingController(
      text: existing?.role ?? 'Staff member',
    );
    final baseRateController = TextEditingController(
      text: existing == null ? '' : existing.baseRate.toStringAsFixed(0),
    );
    final defaultHoursController = TextEditingController(
      text: existing == null
          ? '8'
          : existing.defaultHoursPerDay.toStringAsFixed(
              existing.defaultHoursPerDay % 1 == 0 ? 0 : 1,
            ),
    );
    final overtimeRateController = TextEditingController(
      text: existing == null || existing.overtimeRate <= 0
          ? ''
          : existing.overtimeRate.toStringAsFixed(
              existing.overtimeRate % 1 == 0 ? 0 : 1,
            ),
    );
    final notesController = TextEditingController(text: existing?.notes ?? '');
    var selectedPayType = existing?.payType ?? StaffPayType.monthly;
    var isActive = existing?.isActive ?? true;

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
                          ? 'Add staff member'
                          : 'Edit staff member',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: roleController,
                            decoration: const InputDecoration(
                              labelText: 'Role',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<StaffPayType>(
                      initialValue: selectedPayType,
                      decoration: const InputDecoration(labelText: 'Pay model'),
                      items: StaffPayType.values
                          .map(
                            (payType) => DropdownMenuItem<StaffPayType>(
                              value: payType,
                              child: Text(
                                widget.controller.staffPayTypeLabel(payType),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setModalState(() {
                          selectedPayType = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: baseRateController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: switch (selectedPayType) {
                                StaffPayType.daily => 'Daily rate',
                                StaffPayType.monthly => 'Monthly salary',
                                StaffPayType.hourly => 'Hourly rate',
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: defaultHoursController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Default hours / day',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: overtimeRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Overtime rate',
                        hintText: 'Leave empty to auto-calculate',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        alignLabelWithHint: true,
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active staff member'),
                      subtitle: const Text(
                        'Turn this off to archive the profile without removing payroll history.',
                      ),
                      value: isActive,
                      onChanged: (value) {
                        setModalState(() {
                          isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          return;
                        }
                        await widget.controller.saveStaffMember(
                          staffId: existing?.id,
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          role: roleController.text.trim(),
                          payType: selectedPayType,
                          baseRate:
                              double.tryParse(baseRateController.text.trim()) ??
                              0,
                          defaultHoursPerDay:
                              double.tryParse(
                                defaultHoursController.text.trim(),
                              ) ??
                              8,
                          overtimeRate:
                              double.tryParse(
                                overtimeRateController.text.trim(),
                              ) ??
                              0,
                          notes: notesController.text.trim(),
                          isActive: isActive,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        existing == null ? 'Add staff' : 'Save staff',
                      ),
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
    phoneController.dispose();
    roleController.dispose();
    baseRateController.dispose();
    defaultHoursController.dispose();
    overtimeRateController.dispose();
    notesController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff profile saved successfully.')),
      );
    }
  }

  Future<void> _openAttendanceEntry(StaffMember staff) async {
    var selectedDate = DateTime.now();
    var selectedStatus = StaffAttendanceStatus.present;
    final todayEntry = widget.controller.attendanceForStaffOnDate(
      staff.id,
      selectedDate,
    );
    final workedHoursController = TextEditingController(
      text: todayEntry == null || todayEntry.workedHours <= 0
          ? staff.defaultHoursPerDay.toStringAsFixed(
              staff.defaultHoursPerDay % 1 == 0 ? 0 : 1,
            )
          : todayEntry.workedHours.toStringAsFixed(
              todayEntry.workedHours % 1 == 0 ? 0 : 1,
            ),
    );
    final overtimeHoursController = TextEditingController(
      text: todayEntry == null || todayEntry.overtimeHours <= 0
          ? ''
          : todayEntry.overtimeHours.toStringAsFixed(
              todayEntry.overtimeHours % 1 == 0 ? 0 : 1,
            ),
    );
    final noteController = TextEditingController(text: todayEntry?.note ?? '');
    if (todayEntry != null) {
      selectedStatus = todayEntry.status;
    }

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
                    'Attendance - ${staff.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(DateTime.now().year - 1),
                        lastDate: DateTime(DateTime.now().year + 1),
                      );
                      if (picked == null) {
                        return;
                      }
                      final existing = widget.controller
                          .attendanceForStaffOnDate(staff.id, picked);
                      setModalState(() {
                        selectedDate = picked;
                        selectedStatus =
                            existing?.status ?? StaffAttendanceStatus.present;
                        workedHoursController.text =
                            existing == null || existing.workedHours <= 0
                            ? staff.defaultHoursPerDay.toStringAsFixed(
                                staff.defaultHoursPerDay % 1 == 0 ? 0 : 1,
                              )
                            : existing.workedHours.toStringAsFixed(
                                existing.workedHours % 1 == 0 ? 0 : 1,
                              );
                        overtimeHoursController.text =
                            existing == null || existing.overtimeHours <= 0
                            ? ''
                            : existing.overtimeHours.toStringAsFixed(
                                existing.overtimeHours % 1 == 0 ? 0 : 1,
                              );
                        noteController.text = existing?.note ?? '';
                      });
                    },
                    icon: const Icon(Icons.event_rounded),
                    label: Text(
                      'Attendance date: ${widget.controller.formatDate(selectedDate)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StaffAttendanceStatus>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: StaffAttendanceStatus.values
                        .map(
                          (status) => DropdownMenuItem<StaffAttendanceStatus>(
                            value: status,
                            child: Text(
                              widget.controller.staffAttendanceStatusLabel(
                                status,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setModalState(() {
                        selectedStatus = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: workedHoursController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Worked hours',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: overtimeHoursController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Overtime hours',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await widget.controller.saveStaffAttendance(
                        staffId: staff.id,
                        date: selectedDate,
                        status: selectedStatus,
                        workedHours:
                            double.tryParse(
                              workedHoursController.text.trim(),
                            ) ??
                            0,
                        overtimeHours:
                            double.tryParse(
                              overtimeHoursController.text.trim(),
                            ) ??
                            0,
                        note: noteController.text.trim(),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Save attendance'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    workedHoursController.dispose();
    overtimeHoursController.dispose();
    noteController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance saved successfully.')),
      );
    }
  }

  Future<void> _openAdvanceEntry(StaffMember staff) async {
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
                'Staff advance - ${staff.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Advance amount'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Advance note'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await widget.controller.recordStaffAdvance(
                    staffId: staff.id,
                    amount: double.tryParse(amountController.text.trim()) ?? 0,
                    note: noteController.text.trim(),
                  );
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).pop(true);
                },
                child: const Text('Save advance'),
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
        const SnackBar(content: Text('Staff advance saved successfully.')),
      );
    }
  }

  Future<void> _openPayrollRun(StaffMember staff) async {
    final now = DateTime.now();
    var periodStart = DateTime(now.year, now.month, 1);
    var periodEnd = DateTime(now.year, now.month + 1, 0);
    var payDate = now;
    final noteController = TextEditingController();

    final run = await showModalBottomSheet<StaffPayrollRun>(
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
                    'Run payroll - ${staff.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This will calculate salary using attendance, overtime, and unsettled advances for the selected period.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 1),
                        initialDateRange: DateTimeRange(
                          start: periodStart,
                          end: periodEnd,
                        ),
                      );
                      if (picked == null) {
                        return;
                      }
                      setModalState(() {
                        periodStart = picked.start;
                        periodEnd = picked.end;
                      });
                    },
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                      'Pay period: ${widget.controller.formatDate(periodStart)} - ${widget.controller.formatDate(periodEnd)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: payDate,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 1),
                      );
                      if (picked == null) {
                        return;
                      }
                      setModalState(() {
                        payDate = picked;
                      });
                    },
                    icon: const Icon(Icons.payments_rounded),
                    label: Text(
                      'Pay date: ${widget.controller.formatDate(payDate)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Payroll note',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      final payroll = await widget.controller.runStaffPayroll(
                        staffId: staff.id,
                        periodStart: periodStart,
                        periodEnd: periodEnd,
                        payDate: payDate,
                        note: noteController.text.trim(),
                      );
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop(payroll);
                    },
                    child: const Text('Run payroll'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    noteController.dispose();

    if (run == null || !mounted) {
      return;
    }
    await _openSlipPreview(run);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final staffMembers = widget.controller.allStaffMembers;
          final payrollRuns = widget.controller.staffPayrollRuns
              .take(8)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: <Widget>[
              Text(
                'Staff and Payroll',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Manage staff profiles, attendance, salary advances, payroll runs, and salary slip exports.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              SummaryCard(
                title: 'Active staff',
                value: '${widget.controller.staffMembers.length}',
                subtitle:
                    '${widget.controller.presentStaffTodayCount} marked for today',
                accentColor: kKhataGreen,
                icon: Icons.badge_rounded,
                prominent: true,
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Monthly payroll',
                      value: widget.controller.displayCurrency(
                        widget.controller.monthlyPayrollNet,
                      ),
                      subtitle: 'Net salary this month',
                      accentColor: kKhataSuccess,
                      icon: Icons.payments_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Staff advances',
                      value: widget.controller.displayCurrency(
                        widget.controller.totalOutstandingStaffAdvances,
                      ),
                      subtitle: 'Outstanding deductions',
                      accentColor: kKhataAmber,
                      icon: Icons.request_quote_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Overtime hours',
                      value: widget.controller.monthlyStaffOvertimeHours
                          .toStringAsFixed(1),
                      subtitle: 'Tracked this month',
                      accentColor: kKhataDanger,
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Payroll slips',
                      value: '${widget.controller.staffPayrollRuns.length}',
                      subtitle: 'Saved salary runs',
                      accentColor: kKhataGreen,
                      icon: Icons.description_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.controller.canWriteData
                          ? () => _openStaffEditor()
                          : null,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Add Staff'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Staff Directory',
                subtitle:
                    'Each profile stores the pay model, default hours, overtime handling, attendance, and advance history.',
              ),
              const SizedBox(height: 12),
              if (staffMembers.isEmpty)
                const EmptyStateCard(
                  title: 'No staff added yet',
                  message:
                      'Add a staff profile first, then record attendance, advances, and payroll slips.',
                )
              else
                ...staffMembers.map((staff) {
                  final latestAttendanceEntries = widget.controller
                      .attendanceForStaff(staff.id);
                  final latestAttendance = latestAttendanceEntries.isEmpty
                      ? null
                      : latestAttendanceEntries.first;
                  final latestPayrollRuns = widget.controller
                      .payrollRunsForStaff(staff.id);
                  final latestPayroll = latestPayrollRuns.isEmpty
                      ? null
                      : latestPayrollRuns.first;
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
                                    staff.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                InsightChip(
                                  label: widget.controller.staffPayTypeLabel(
                                    staff.payType,
                                  ),
                                  color: kKhataGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${staff.role} • ${widget.controller.displayCurrency(staff.baseRate)}'
                              '${staff.payType == StaffPayType.daily
                                  ? ' per day'
                                  : staff.payType == StaffPayType.monthly
                                  ? ' per month'
                                  : ' per hour'}',
                            ),
                            if (staff.phone.trim().isNotEmpty) ...<Widget>[
                              const SizedBox(height: 4),
                              Text(staff.phone),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                InsightChip(
                                  label: widget.controller.displayCurrency(
                                    widget.controller
                                        .staffOutstandingAdvanceTotal(staff.id),
                                  ),
                                  color: kKhataAmber,
                                ),
                                InsightChip(
                                  label:
                                      '${staff.defaultHoursPerDay.toStringAsFixed(staff.defaultHoursPerDay % 1 == 0 ? 0 : 1)} hrs/day',
                                  color: kKhataSuccess,
                                ),
                                if (latestAttendance != null)
                                  InsightChip(
                                    label:
                                        '${widget.controller.staffAttendanceStatusLabel(latestAttendance.status)} ${widget.controller.formatDate(latestAttendance.date)}',
                                    color: kKhataDanger,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: <Widget>[
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _openStaffEditor(staff)
                                      : null,
                                  icon: const Icon(Icons.edit_rounded),
                                  label: const Text('Edit'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _openAttendanceEntry(staff)
                                      : null,
                                  icon: const Icon(Icons.fact_check_rounded),
                                  label: const Text('Attendance'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _openAdvanceEntry(staff)
                                      : null,
                                  icon: const Icon(Icons.request_quote_rounded),
                                  label: const Text('Advance'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: widget.controller.canWriteData
                                      ? () => _openPayrollRun(staff)
                                      : null,
                                  icon: const Icon(Icons.receipt_long_rounded),
                                  label: const Text('Run Payroll'),
                                ),
                                if (latestPayroll != null)
                                  OutlinedButton.icon(
                                    onPressed: () =>
                                        _openSlipPreview(latestPayroll),
                                    icon: const Icon(Icons.visibility_outlined),
                                    label: const Text('Latest Slip'),
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
                title: 'Payroll History',
                subtitle:
                    'Saved salary runs include attendance, overtime, advance deduction, and printable salary slips.',
              ),
              const SizedBox(height: 12),
              if (payrollRuns.isEmpty)
                const EmptyStateCard(
                  title: 'No payroll runs yet',
                  message:
                      'Run payroll for a staff member to generate the first salary slip.',
                )
              else
                ...payrollRuns.map((run) {
                  final staff = widget.controller.staffMemberById(run.staffId);
                  final slipText = widget.controller.buildSalarySlipDocument(
                    run,
                  );
                  final fileBase = _safeFileName(
                    '${staff?.name ?? 'staff'}_${widget.controller.salarySlipNumberForRun(run)}',
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        title: Text(staff?.name ?? 'Staff member'),
                        subtitle: Text(
                          '${widget.controller.staffPayTypeLabel(run.payType)}'
                          ' • ${widget.controller.formatDate(run.periodStart)} - ${widget.controller.formatDate(run.periodEnd)}'
                          '\nNet ${widget.controller.displayCurrency(run.netPay)} • Overtime ${run.overtimeHours.toStringAsFixed(1)} hrs',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'preview':
                                _openSlipPreview(run);
                                return;
                              case 'share':
                                _shareSlip(run);
                                return;
                              case 'save_txt':
                                _saveTextExport(
                                  fileLabel: '$fileBase.txt',
                                  content: slipText,
                                );
                                return;
                              case 'save_pdf':
                                _savePdfExport(
                                  title: 'Salary Slip',
                                  fileLabel: '$fileBase.pdf',
                                  documentText: slipText,
                                );
                                return;
                              case 'print':
                                _printPdfDocument(
                                  title: 'Salary Slip',
                                  fileLabel: '$fileBase.pdf',
                                  documentText: slipText,
                                );
                                return;
                            }
                          },
                          itemBuilder: (context) =>
                              const <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'preview',
                                  child: Text('Preview'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'share',
                                  child: Text('Share'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'save_txt',
                                  child: Text('Save TXT'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'save_pdf',
                                  child: Text('Save PDF'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'print',
                                  child: Text('Print'),
                                ),
                              ],
                          icon: const Icon(Icons.more_vert_rounded),
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
