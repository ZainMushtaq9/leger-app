import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../controller.dart';
import '../models.dart';
import '../services/document_export_service.dart';
import '../theme.dart';
import 'common_widgets.dart';
import 'document_preview_screen.dart';
import 'quotation_builder_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.controller,
    required this.adsEnabled,
    required this.onOpenCustomer,
  });

  final HisabRakhoController controller;
  final bool adsEnabled;
  final Future<void> Function(Customer customer) onOpenCustomer;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DocumentExportService _documentExportService =
      const DocumentExportService();
  ReportRangePreset _selectedPreset = ReportRangePreset.thisMonth;
  DateTimeRange? _customRange;
  String? _selectedCashFlowBucketLabel;

  ReportRange get _activeRange {
    final now = DateTime.now();
    switch (_selectedPreset) {
      case ReportRangePreset.last7Days:
        return ReportRange(
          label: 'Last 7 days',
          start: now.subtract(const Duration(days: 6)),
          end: now,
        );
      case ReportRangePreset.thisMonth:
        return ReportRange(
          label: 'This month',
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      case ReportRangePreset.thisQuarter:
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return ReportRange(
          label: 'This quarter',
          start: DateTime(now.year, quarterStartMonth, 1),
          end: now,
        );
      case ReportRangePreset.thisYear:
        return ReportRange(
          label: 'This year',
          start: DateTime(now.year, 1, 1),
          end: now,
        );
      case ReportRangePreset.allTime:
        return const ReportRange(label: 'All time');
      case ReportRangePreset.custom:
        final customRange = _customRange;
        if (customRange == null) {
          return ReportRange(
            label: 'This month',
            start: DateTime(now.year, now.month, 1),
            end: now,
          );
        }
        return ReportRange(
          label:
              '${widget.controller.formatDate(customRange.start)} - ${widget.controller.formatDate(customRange.end)}',
          start: customRange.start,
          end: customRange.end,
        );
    }
  }

  String _presetLabel(ReportRangePreset preset) {
    switch (preset) {
      case ReportRangePreset.last7Days:
        return '7 days';
      case ReportRangePreset.thisMonth:
        return 'Month';
      case ReportRangePreset.thisQuarter:
        return 'Quarter';
      case ReportRangePreset.thisYear:
        return 'Year';
      case ReportRangePreset.allTime:
        return 'All';
      case ReportRangePreset.custom:
        return 'Custom';
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange:
          _customRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _customRange = selected;
      _selectedPreset = ReportRangePreset.custom;
    });
  }

  Future<void> _copySummary(ReportRange range) async {
    await Clipboard.setData(
      ClipboardData(text: widget.controller.buildReportSummaryText(range)),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Report summary copied.')));
  }

  Future<void> _shareSummary(ReportRange range) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Hisab Rakho Report',
        text: widget.controller.buildReportSummaryText(range),
      ),
    );
  }

  Future<void> _openReportPreview(ReportRange range) async {
    final reportText = widget.controller.buildReportDocumentText(range);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DocumentPreviewScreen(
          title: 'Report Preview',
          documentText: reportText,
          onShare: () => _shareSummary(range),
          onDownload: () => _saveTextExport(
            fileLabel: 'report_${_selectedPreset.name}.txt',
            content: reportText,
          ),
          onPrint: () => _printPdfDocument(
            title: 'Hisab Rakho Report',
            fileLabel: 'report_${_selectedPreset.name}.pdf',
            documentText: reportText,
          ),
        ),
      ),
    );
  }

  Future<void> _shareCsv(ReportRange range) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Hisab Rakho CSV Report',
        text: widget.controller.exportReportCsv(range),
      ),
    );
  }

  Future<void> _openStatementPreview(
    Customer customer,
    ReportRange range,
  ) async {
    final statementText = widget.controller.buildCustomerStatementDocument(
      customer,
      range: range,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DocumentPreviewScreen(
          title: '${customer.name} Statement',
          documentText: statementText,
          onShare: () => _shareStatement(customer, range),
          onDownload: () => _saveTextExport(
            fileLabel: '${_safeFileName(customer.name)}_statement.txt',
            content: statementText,
          ),
          onPrint: () => _printPdfDocument(
            title: '${customer.name} Statement',
            fileLabel: '${_safeFileName(customer.name)}_statement.pdf',
            documentText: statementText,
          ),
        ),
      ),
    );
  }

  Future<void> _shareStatement(Customer customer, ReportRange range) async {
    await SharePlus.instance.share(
      ShareParams(
        title: '${customer.name} statement',
        text: widget.controller.buildStatementShareText(customer, range: range),
      ),
    );
  }

  Future<void> _openQuotationBuilder() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            QuotationBuilderScreen(controller: widget.controller),
      ),
    );
  }

  Future<void> _openInvoicePreview(SaleRecord sale) async {
    final customer = sale.customerId == null
        ? null
        : widget.controller.customerById(sale.customerId!);
    final invoiceText = widget.controller.buildSaleInvoiceDocument(sale);
    final baseLabel = _safeFileName(
      customer?.name ?? widget.controller.invoiceNumberForSale(sale),
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DocumentPreviewScreen(
          title: 'Invoice Preview',
          documentText: invoiceText,
          onShare: () => _shareInvoice(sale),
          onDownload: () => _saveTextExport(
            fileLabel: '${baseLabel}_invoice.txt',
            content: invoiceText,
          ),
          onPrint: () => _printPdfDocument(
            title: 'Invoice',
            fileLabel: '${baseLabel}_invoice.pdf',
            documentText: invoiceText,
          ),
        ),
      ),
    );
  }

  Future<void> _shareInvoice(SaleRecord sale) async {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Hisab Rakho Invoice',
        text: widget.controller.buildSaleInvoiceDocument(sale),
      ),
    );
  }

  String _safeFileName(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return normalized.isEmpty ? 'hisab_rakho_export' : normalized;
  }

  Future<void> _showSavedFileMessage(String fileLabel, String? path) async {
    if (!mounted) {
      return;
    }
    if (path != null && path.trim().isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: path));
      if (!mounted) {
        return;
      }
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final range = _activeRange;
          final creditsIssued = widget.controller.creditsIssuedForRange(range);
          final paymentsReceived = widget.controller.paymentsReceivedForRange(
            range,
          );
          final netCashFlow = widget.controller.netCashFlowForRange(range);
          final openingBalance = widget.controller.openingBalanceForRange(
            range,
          );
          final closingBalance = widget.controller.closingBalanceForRange(
            range,
          );
          final remindersSent = widget.controller.remindersSentForRange(range);
          final zakatEstimate = widget.controller.zakatEstimateForRange(range);
          final cashFlowBuckets = widget.controller.cashFlowBucketsForRange(
            range,
          );
          final profitLoss = widget.controller.profitLossSummaryForRange(range);
          final taxSummary = widget.controller.taxSummaryForRange(range);
          final totalSales = profitLoss.totalSales;
          final balanceDiscrepancy = widget.controller
              .balanceSheetDiscrepancyForRange(range);
          final weeklyPulse = widget.controller.weeklyBusinessSummaries(
            count: 4,
          );
          final monthlyPulse = widget.controller.monthlyBusinessSummaries(
            count: 4,
          );
          final topSellingItems = widget.controller.topSellingItemsForRange(
            range,
          );
          final categoryBreakdown = widget.controller
              .creditIssuedCategoryBreakdownForRange(range)
              .entries
              .toList();
          final canWriteData = widget.controller.canWriteData;
          final visibleCashBuckets = cashFlowBuckets.take(6).toList();
          CashFlowBucket? selectedCashBucket;
          if (visibleCashBuckets.isNotEmpty) {
            for (final bucket in visibleCashBuckets) {
              if (bucket.label == _selectedCashFlowBucketLabel) {
                selectedCashBucket = bucket;
                break;
              }
            }
            selectedCashBucket ??= visibleCashBuckets.first;
          }
          final activeCustomers =
              widget.controller.customersTouchedInRange(range)..sort(
                (left, right) => widget.controller
                    .closingBalanceForCustomerInRange(right.id, range)
                    .compareTo(
                      widget.controller.closingBalanceForCustomerInRange(
                        left.id,
                        range,
                      ),
                    ),
              );
          final recentSales = widget.controller.saleRecords.take(8).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Reports',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Date-filtered recovery, cash flow, statements, and export tools.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: canWriteData ? () => _copySummary(range) : null,
                    icon: const Icon(Icons.copy_all_rounded),
                    tooltip: 'Copy summary',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ReportRangePreset.values.map((preset) {
                  final selected = _selectedPreset == preset;
                  return ChoiceChip(
                    label: Text(_presetLabel(preset)),
                    selected: selected,
                    onSelected: (_) {
                      if (preset == ReportRangePreset.custom) {
                        _pickCustomRange();
                        return;
                      }
                      setState(() {
                        _selectedPreset = preset;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Selected period',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        range.label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: kKhataGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.icon(
                            onPressed: canWriteData
                                ? () => _shareSummary(range)
                                : null,
                            icon: const Icon(Icons.ios_share_rounded),
                            label: const Text('Share Summary'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canWriteData
                                ? () => _openReportPreview(range)
                                : null,
                            icon: const Icon(Icons.description_outlined),
                            label: const Text('Preview'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canWriteData
                                ? () => _saveTextExport(
                                    fileLabel:
                                        'report_summary_${_selectedPreset.name}.txt',
                                    content: widget.controller
                                        .buildReportDocumentText(range),
                                  )
                                : null,
                            icon: const Icon(Icons.download_rounded),
                            label: const Text('Save TXT'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canWriteData
                                ? () => _savePdfExport(
                                    title: 'Hisab Rakho Report',
                                    fileLabel:
                                        'report_${_selectedPreset.name}.pdf',
                                    documentText: widget.controller
                                        .buildReportDocumentText(range),
                                  )
                                : null,
                            icon: const Icon(Icons.picture_as_pdf_rounded),
                            label: const Text('Save PDF'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canWriteData
                                ? () => _shareCsv(range)
                                : null,
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share CSV'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canWriteData
                                ? () => _saveTextExport(
                                    fileLabel:
                                        'report_${_selectedPreset.name}.csv',
                                    content: widget.controller.exportReportCsv(
                                      range,
                                    ),
                                  )
                                : null,
                            icon: const Icon(Icons.table_chart_rounded),
                            label: const Text('Save CSV'),
                          ),
                          OutlinedButton.icon(
                            onPressed: canWriteData
                                ? () => _printPdfDocument(
                                    title: 'Hisab Rakho Report',
                                    fileLabel:
                                        'report_${_selectedPreset.name}.pdf',
                                    documentText: widget.controller
                                        .buildReportDocumentText(range),
                                  )
                                : null,
                            icon: const Icon(Icons.print_rounded),
                            label: const Text('Print'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const SectionHeader(
                title: 'Analytics Snapshot',
                subtitle:
                    'A quick visual summary of recovery momentum and customer risk distribution.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Recovery trend',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      if (visibleCashBuckets.isEmpty)
                        const Text(
                          'No chart data is available for the selected period yet.',
                        )
                      else
                        _RecoveryTrendChart(
                          buckets: visibleCashBuckets,
                          controller: widget.controller,
                          selectedLabel: selectedCashBucket?.label,
                          onSelect: (bucket) {
                            setState(() {
                              _selectedCashFlowBucketLabel = bucket.label;
                            });
                          },
                        ),
                      if (selectedCashBucket != null) ...<Widget>[
                        const SizedBox(height: 16),
                        _SelectedCashFlowDrilldown(
                          bucket: selectedCashBucket,
                          controller: widget.controller,
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Score distribution',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 14),
                      _ScoreDistributionStrip(
                        customers: activeCustomers,
                        controller: widget.controller,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SummaryCard(
                title: 'Payments',
                value: widget.controller.displayCurrency(paymentsReceived),
                subtitle: 'Recovered in ${range.label.toLowerCase()}',
                accentColor: kKhataSuccess,
                icon: Icons.payments_rounded,
                prominent: true,
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Credit Issued',
                      value: widget.controller.displayCurrency(creditsIssued),
                      subtitle: '${activeCustomers.length} active profiles',
                      accentColor: kKhataDanger,
                      icon: Icons.add_card_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Net Cash Flow',
                      value: widget.controller.displayCurrency(netCashFlow),
                      subtitle: 'Payments minus credit',
                      accentColor: netCashFlow >= 0
                          ? kKhataSuccess
                          : kKhataAmber,
                      icon: Icons.swap_vert_circle_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Closing Balance',
                      value: widget.controller.displayCurrency(closingBalance),
                      subtitle: 'Receivables by end of period',
                      accentColor: kKhataGreen,
                      icon: Icons.account_balance_wallet_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Reminders',
                      value: '$remindersSent',
                      subtitle: 'Sent in selected period',
                      accentColor: kKhataAmber,
                      icon: Icons.campaign_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SummaryCard(
                      title: 'Sales Booked',
                      value: widget.controller.displayCurrency(totalSales),
                      subtitle: '${recentSales.length} recent sale records',
                      accentColor: kKhataGreen,
                      icon: Icons.point_of_sale_rounded,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SummaryCard(
                      title: 'Operating Result',
                      value: widget.controller.displayCurrency(
                        profitLoss.operatingProfit,
                      ),
                      subtitle: 'Gross profit minus payroll',
                      accentColor: profitLoss.operatingProfit >= 0
                          ? kKhataSuccess
                          : kKhataDanger,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AdBannerStrip(
                enabled:
                    widget.adsEnabled &&
                    widget.controller.settings.adsEnabled &&
                    !widget.controller.settings.isPaidUser,
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Business Performance',
                subtitle:
                    'Sales mix, supplier movement, and operating health for the selected period.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _MetricRow(
                        label: 'Total sales',
                        value: widget.controller.displayCurrency(
                          profitLoss.totalSales,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Cash sales',
                        value: widget.controller.displayCurrency(
                          profitLoss.cashSales,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Udhaar sales',
                        value: widget.controller.displayCurrency(
                          profitLoss.udhaarSales,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Supplier purchases',
                        value: widget.controller.displayCurrency(
                          widget.controller.supplierPurchasesForRange(range),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Supplier payments',
                        value: widget.controller.displayCurrency(
                          widget.controller.supplierPaymentsForRange(range),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Profit and Loss',
                subtitle:
                    'Sales, cost, gross profit, payroll, and operating result from real business activity.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _MetricRow(
                        label: 'Sales booked',
                        value: widget.controller.displayCurrency(
                          profitLoss.totalSales,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Cost of goods sold',
                        value: widget.controller.displayCurrency(
                          profitLoss.costOfGoodsSold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Gross profit',
                        value: widget.controller.displayCurrency(
                          profitLoss.grossProfit,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Payroll expense',
                        value: widget.controller.displayCurrency(
                          profitLoss.payrollExpense,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Operating result',
                        value: widget.controller.displayCurrency(
                          profitLoss.operatingProfit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Weekly and Monthly Pulse',
                subtitle:
                    'Compact weekly and monthly summaries for ongoing business review.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Weekly pulse',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: weeklyPulse
                            .map(
                              (summary) => _PeriodPulseCard(
                                summary: summary,
                                controller: widget.controller,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Monthly pulse',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: monthlyPulse
                            .map(
                              (summary) => _PeriodPulseCard(
                                summary: summary,
                                controller: widget.controller,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Balance Sheet',
                subtitle:
                    'Opening balance, issued credit, recovered cash, and the closing receivable snapshot.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _MetricRow(
                        label: 'Opening balance',
                        value: widget.controller.displayCurrency(
                          openingBalance,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Credit issued',
                        value: widget.controller.displayCurrency(creditsIssued),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Payments received',
                        value: widget.controller.displayCurrency(
                          paymentsReceived,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Closing balance',
                        value: widget.controller.displayCurrency(
                          closingBalance,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Balance discrepancy',
                        value: widget.controller.displayCurrency(
                          balanceDiscrepancy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MetricRow(
                        label: 'Current overdue snapshot',
                        value: widget.controller.displayCurrency(
                          widget.controller.overdueAmount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Compliance View',
                subtitle:
                    'Internal FBR-style summary and zakat estimate. Review final filing numbers separately.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: InfoPill(
                              icon: Icons.receipt_long_rounded,
                              color: kKhataAmber,
                              title: widget.controller.displayCurrency(
                                taxSummary.taxableSales,
                              ),
                              subtitle: 'Taxable sales summary',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InfoPill(
                              icon: Icons.volunteer_activism_rounded,
                              color: kKhataSuccess,
                              title: widget.controller.displayCurrency(
                                zakatEstimate,
                              ),
                              subtitle: 'Estimated zakat on receivables',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: InfoPill(
                              icon: Icons.percent_rounded,
                              color: kKhataGreen,
                              title:
                                  '${taxSummary.salesTaxRate % 1 == 0 ? taxSummary.salesTaxRate.toStringAsFixed(0) : taxSummary.salesTaxRate.toStringAsFixed(1)}%',
                              subtitle: 'Configured sales tax rate',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InfoPill(
                              icon: Icons.account_balance_rounded,
                              color: kKhataAmber,
                              title: widget.controller.displayCurrency(
                                taxSummary.salesTaxAmount,
                              ),
                              subtitle: 'Estimated sales tax portion',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Use this section as a management summary for documentation and planning. Tax submission numbers should still be reviewed separately.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Cash Flow',
                subtitle:
                    'Compare credit outflow and payment inflow across the selected period.',
              ),
              const SizedBox(height: 12),
              if (cashFlowBuckets.isEmpty)
                const EmptyStateCard(
                  title: 'No cashflow activity',
                  message:
                      'Credit and payment entries from the selected period will appear here automatically.',
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: cashFlowBuckets.take(8).map((bucket) {
                        final maxValue = bucket.credits > bucket.payments
                            ? bucket.credits
                            : bucket.payments;
                        final paymentRatio = maxValue == 0
                            ? 0.0
                            : bucket.payments / maxValue;
                        final creditRatio = maxValue == 0
                            ? 0.0
                            : bucket.credits / maxValue;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _CashFlowBucketCard(
                            bucket: bucket,
                            paymentRatio: paymentRatio,
                            creditRatio: creditRatio,
                            controller: widget.controller,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Category Breakdown',
                subtitle:
                    'See how issued credit is split across customer categories.',
              ),
              const SizedBox(height: 12),
              if (categoryBreakdown.isEmpty)
                const EmptyStateCard(
                  title: 'No category activity',
                  message:
                      'When credit is issued in the selected period, the category mix will appear here.',
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: categoryBreakdown.map((entry) {
                        final ratio = creditsIssued <= 0
                            ? 0.0
                            : entry.value / creditsIssued;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CategoryBar(
                            label: entry.key,
                            amount: widget.controller.displayCurrency(
                              entry.value,
                            ),
                            ratio: ratio,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Sales Drilldown',
                subtitle:
                    'Top products sold in the selected period with quantity, sales value, and margin.',
              ),
              const SizedBox(height: 12),
              if (topSellingItems.isEmpty)
                const EmptyStateCard(
                  title: 'No sales items yet',
                  message:
                      'Sold products will appear here automatically with their quantities, sales value, and margin.',
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: topSellingItems
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _SalesItemRow(
                                item: item,
                                controller: widget.controller,
                                maxSales: topSellingItems.first.salesAmount,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Invoices and Quotations',
                subtitle:
                    'Generate branded invoices from recent sales and build fresh quotations for customers.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Business documents use the active shop branding, invoice prefixes, tax split, and compliance identifiers from settings.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: canWriteData ? _openQuotationBuilder : null,
                        icon: const Icon(Icons.note_add_rounded),
                        label: const Text('New Quotation'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (recentSales.isEmpty)
                const EmptyStateCard(
                  title: 'No invoice activity',
                  message:
                      'Recent cash sales and udhaar sales will appear here with invoice actions after you record them in the business hub.',
                )
              else
                ...recentSales.map((sale) {
                  final customer = sale.customerId == null
                      ? null
                      : widget.controller.customerById(sale.customerId!);
                  final invoiceText = widget.controller
                      .buildSaleInvoiceDocument(sale);
                  final fileBase = _safeFileName(
                    customer?.name ??
                        widget.controller.invoiceNumberForSale(sale),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        onTap: customer == null
                            ? null
                            : () => widget.onOpenCustomer(customer),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        title: Text(
                          customer?.name ??
                              widget.controller.invoiceNumberForSale(sale),
                        ),
                        subtitle: Text(
                          '${sale.type == SaleRecordType.cash ? 'Cash sale' : 'Udhaar sale'}'
                          ' | ${widget.controller.formatDateTime(sale.date)}'
                          ' | ${widget.controller.displayCurrency(sale.totalAmount)}',
                        ),
                        trailing: canWriteData
                            ? PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'preview':
                                      _openInvoicePreview(sale);
                                      return;
                                    case 'share':
                                      _shareInvoice(sale);
                                      return;
                                    case 'save_txt':
                                      _saveTextExport(
                                        fileLabel: '${fileBase}_invoice.txt',
                                        content: invoiceText,
                                      );
                                      return;
                                    case 'save_pdf':
                                      _savePdfExport(
                                        title: 'Invoice',
                                        fileLabel: '${fileBase}_invoice.pdf',
                                        documentText: invoiceText,
                                      );
                                      return;
                                    case 'print':
                                      _printPdfDocument(
                                        title: 'Invoice',
                                        fileLabel: '${fileBase}_invoice.pdf',
                                        documentText: invoiceText,
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
                                icon: const Icon(Icons.receipt_long_rounded),
                                tooltip: 'Invoice actions',
                              )
                            : null,
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Statements',
                subtitle:
                    'Active customers in the selected period and their statement actions.',
              ),
              const SizedBox(height: 12),
              if (activeCustomers.isEmpty)
                const EmptyStateCard(
                  title: 'No statement activity',
                  message:
                      'Customers with activity in the selected period will appear here for preview, export, and sharing.',
                )
              else
                ...activeCustomers
                    .take(8)
                    .map(
                      (customer) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          child: ListTile(
                            onTap: () => widget.onOpenCustomer(customer),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            title: Text(customer.name),
                            subtitle: Text(
                              'Open ${widget.controller.displayCurrency(widget.controller.openingBalanceForCustomerInRange(customer.id, range))}'
                              ' | Credit ${widget.controller.displayCurrency(widget.controller.creditsIssuedForCustomerInRange(customer.id, range))}'
                              ' | Payment ${widget.controller.displayCurrency(widget.controller.paymentsReceivedForCustomerInRange(customer.id, range))}',
                            ),
                            trailing: canWriteData
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'preview':
                                          _openStatementPreview(
                                            customer,
                                            range,
                                          );
                                          return;
                                        case 'share':
                                          _shareStatement(customer, range);
                                          return;
                                        case 'save_txt':
                                          _saveTextExport(
                                            fileLabel:
                                                '${_safeFileName(customer.name)}_statement.txt',
                                            content: widget.controller
                                                .buildCustomerStatementDocument(
                                                  customer,
                                                  range: range,
                                                ),
                                          );
                                          return;
                                        case 'save_csv':
                                          _saveTextExport(
                                            fileLabel:
                                                '${_safeFileName(customer.name)}_statement.csv',
                                            content: widget.controller
                                                .exportCustomerStatementCsv(
                                                  customer,
                                                  range: range,
                                                ),
                                          );
                                          return;
                                        case 'save_pdf':
                                          _savePdfExport(
                                            title: '${customer.name} Statement',
                                            fileLabel:
                                                '${_safeFileName(customer.name)}_statement.pdf',
                                            documentText: widget.controller
                                                .buildCustomerStatementDocument(
                                                  customer,
                                                  range: range,
                                                ),
                                          );
                                          return;
                                        case 'print':
                                          _printPdfDocument(
                                            title: '${customer.name} Statement',
                                            fileLabel:
                                                '${_safeFileName(customer.name)}_statement.pdf',
                                            documentText: widget.controller
                                                .buildCustomerStatementDocument(
                                                  customer,
                                                  range: range,
                                                ),
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
                                            value: 'save_csv',
                                            child: Text('Save CSV'),
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
                                    tooltip: 'Statement actions',
                                  )
                                : null,
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

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(label)),
        const SizedBox(width: 12),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _RecoveryTrendChart extends StatelessWidget {
  const _RecoveryTrendChart({
    required this.buckets,
    required this.controller,
    required this.selectedLabel,
    required this.onSelect,
  });

  final List<CashFlowBucket> buckets;
  final HisabRakhoController controller;
  final String? selectedLabel;
  final ValueChanged<CashFlowBucket> onSelect;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.fold<double>(
      0,
      (current, bucket) => [
        current,
        bucket.payments,
        bucket.credits,
      ].reduce((left, right) => left > right ? left : right),
    );

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: buckets.map((bucket) {
          final paymentRatio = maxValue <= 0 ? 0.0 : bucket.payments / maxValue;
          final creditRatio = maxValue <= 0 ? 0.0 : bucket.credits / maxValue;
          final selected = bucket.label == selectedLabel;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelect(bucket),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? kKhataGreen.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: selected
                        ? Border.all(color: kKhataGreen.withValues(alpha: 0.35))
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kKhataSuccess.withValues(alpha: 0.82),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: (paymentRatio.clamp(0, 1) * 120) + 8,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kKhataDanger.withValues(alpha: 0.76),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: (creditRatio.clamp(0, 1) * 120) + 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bucket.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: selected ? FontWeight.w700 : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.displayCurrency(bucket.net),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: bucket.net >= 0 ? kKhataSuccess : kKhataDanger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SelectedCashFlowDrilldown extends StatelessWidget {
  const _SelectedCashFlowDrilldown({
    required this.bucket,
    required this.controller,
  });

  final CashFlowBucket bucket;
  final HisabRakhoController controller;

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      bucket.credits,
      bucket.payments,
      1.0,
    ].reduce((left, right) => left > right ? left : right);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kKhataGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Selected bucket: ${bucket.label}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          _MiniFlowBar(
            label: 'Payments',
            amount: controller.displayCurrency(bucket.payments),
            ratio: bucket.payments / maxValue,
            color: kKhataSuccess,
          ),
          const SizedBox(height: 8),
          _MiniFlowBar(
            label: 'Credit',
            amount: controller.displayCurrency(bucket.credits),
            ratio: bucket.credits / maxValue,
            color: kKhataDanger,
          ),
          const SizedBox(height: 8),
          _MetricRow(
            label: 'Net result',
            value: controller.displayCurrency(bucket.net),
          ),
        ],
      ),
    );
  }
}

class _PeriodPulseCard extends StatelessWidget {
  const _PeriodPulseCard({required this.summary, required this.controller});

  final PeriodBusinessSummary summary;
  final HisabRakhoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kKhataGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(summary.label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Sales ${controller.displayCurrency(summary.sales)}'),
          const SizedBox(height: 4),
          Text('Payments ${controller.displayCurrency(summary.payments)}'),
          const SizedBox(height: 4),
          Text(
            'Operating ${controller.displayCurrency(summary.operatingProfit)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: summary.operatingProfit >= 0
                  ? kKhataSuccess
                  : kKhataDanger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesItemRow extends StatelessWidget {
  const _SalesItemRow({
    required this.item,
    required this.controller,
    required this.maxSales,
  });

  final SalesItemSummary item;
  final HisabRakhoController controller;
  final double maxSales;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                item.itemName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(controller.displayCurrency(item.salesAmount)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Qty ${item.quantity} | Margin ${controller.displayCurrency(item.margin)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: maxSales <= 0 ? 0 : item.salesAmount / maxSales,
            backgroundColor: kKhataGreen.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(kKhataGreen),
          ),
        ),
      ],
    );
  }
}

class _ScoreDistributionStrip extends StatelessWidget {
  const _ScoreDistributionStrip({
    required this.customers,
    required this.controller,
  });

  final List<Customer> customers;
  final HisabRakhoController controller;

  @override
  Widget build(BuildContext context) {
    final total = customers.length;
    final high = customers
        .where(
          (customer) =>
              controller.insightFor(customer.id).recoveryScore >= 75 ||
              controller.insightFor(customer.id).overdueDays <= 3,
        )
        .length;
    final low = customers
        .where(
          (customer) =>
              controller.insightFor(customer.id).recoveryScore < 45 ||
              controller.insightFor(customer.id).overdueDays >= 30,
        )
        .length;
    final medium = total - high - low;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 18,
            child: Row(
              children: <Widget>[
                if (high > 0)
                  Expanded(
                    flex: high,
                    child: Container(color: kKhataSuccess),
                  ),
                if (medium > 0)
                  Expanded(
                    flex: medium,
                    child: Container(color: kKhataAmber),
                  ),
                if (low > 0)
                  Expanded(
                    flex: low,
                    child: Container(color: kKhataDanger),
                  ),
                if (total == 0)
                  Expanded(
                    child: Container(
                      color: kKhataGreen.withValues(alpha: 0.12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            InsightChip(
              label: total == 0
                  ? 'High 0%'
                  : 'High ${(high / total * 100).round()}%',
              color: kKhataSuccess,
            ),
            InsightChip(
              label: total == 0
                  ? 'Medium 0%'
                  : 'Medium ${(medium / total * 100).round()}%',
              color: kKhataAmber,
            ),
            InsightChip(
              label: total == 0
                  ? 'Low 0%'
                  : 'Low ${(low / total * 100).round()}%',
              color: kKhataDanger,
            ),
          ],
        ),
      ],
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.label,
    required this.amount,
    required this.ratio,
  });

  final String label;
  final String amount;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(amount),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 12,
            value: ratio.clamp(0, 1),
            backgroundColor: kKhataGreen.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(kKhataGreen),
          ),
        ),
      ],
    );
  }
}

class _CashFlowBucketCard extends StatelessWidget {
  const _CashFlowBucketCard({
    required this.bucket,
    required this.paymentRatio,
    required this.creditRatio,
    required this.controller,
  });

  final CashFlowBucket bucket;
  final double paymentRatio;
  final double creditRatio;
  final HisabRakhoController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                bucket.label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              controller.displayCurrency(bucket.net),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: bucket.net >= 0 ? kKhataSuccess : kKhataDanger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MiniFlowBar(
          label: 'Payments',
          amount: controller.displayCurrency(bucket.payments),
          ratio: paymentRatio,
          color: kKhataSuccess,
        ),
        const SizedBox(height: 8),
        _MiniFlowBar(
          label: 'Credit',
          amount: controller.displayCurrency(bucket.credits),
          ratio: creditRatio,
          color: kKhataDanger,
        ),
      ],
    );
  }
}

class _MiniFlowBar extends StatelessWidget {
  const _MiniFlowBar({
    required this.label,
    required this.amount,
    required this.ratio,
    required this.color,
  });

  final String label;
  final String amount;
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        SizedBox(width: 72, child: Text(label)),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio.clamp(0, 1),
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(width: 88, child: Text(amount, textAlign: TextAlign.end)),
      ],
    );
  }
}
