import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../controller.dart';
import '../models.dart';
import '../services/document_export_service.dart';
import 'document_preview_screen.dart';

class QuotationBuilderScreen extends StatefulWidget {
  const QuotationBuilderScreen({
    super.key,
    required this.controller,
    this.preselectedCustomer,
  });

  final HisabRakhoController controller;
  final Customer? preselectedCustomer;

  @override
  State<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends State<QuotationBuilderScreen> {
  final DocumentExportService _documentExportService =
      const DocumentExportService();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _validDaysController = TextEditingController(
    text: '7',
  );
  late final List<_QuotationLineDraft> _lineDrafts = <_QuotationLineDraft>[
    _QuotationLineDraft(),
  ];
  String? _selectedCustomerId;

  Customer? get _selectedCustomer {
    final preset = widget.preselectedCustomer;
    if (preset != null) {
      return widget.controller.customerById(preset.id) ?? preset;
    }
    final selectedCustomerId = _selectedCustomerId;
    if (selectedCustomerId == null || selectedCustomerId.isEmpty) {
      return null;
    }
    return widget.controller.customerById(selectedCustomerId);
  }

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.preselectedCustomer?.id;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _validDaysController.dispose();
    for (final draft in _lineDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  List<SaleLineItem> _buildLineItems() {
    return _lineDrafts
        .map((draft) {
          final quantity =
              int.tryParse(draft.quantityController.text.trim()) ?? 0;
          final unitPrice =
              double.tryParse(draft.unitPriceController.text.trim()) ?? 0;
          return SaleLineItem(
            inventoryItemId: '',
            itemName: draft.nameController.text.trim(),
            quantity: quantity,
            unitPrice: unitPrice,
            costPrice: 0,
          );
        })
        .where(
          (item) =>
              item.itemName.trim().isNotEmpty &&
              item.quantity > 0 &&
              item.unitPrice >= 0,
        )
        .toList();
  }

  String _safeFileName(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return normalized.isEmpty ? 'quotation' : normalized;
  }

  String _buildDocumentText() {
    return widget.controller.buildQuotationDocument(
      customer: _selectedCustomer,
      lineItems: _buildLineItems(),
      note: _noteController.text.trim(),
      validDays: int.tryParse(_validDaysController.text.trim()) ?? 7,
    );
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

  Future<void> _openPreview() async {
    final lineItems = _buildLineItems();
    if (lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one quotation line before previewing.'),
        ),
      );
      return;
    }
    final documentText = _buildDocumentText();
    final customerLabel = _selectedCustomer?.name ?? 'quotation';
    final fileBase = _safeFileName(customerLabel);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DocumentPreviewScreen(
          title: 'Quotation Preview',
          documentText: documentText,
          onShare: () async {
            await SharePlus.instance.share(
              ShareParams(title: 'Hisab Rakho Quotation', text: documentText),
            );
          },
          onDownload: () => _saveTextExport(
            fileLabel: '${fileBase}_quotation.txt',
            content: documentText,
          ),
          onPrint: () => _printPdfDocument(
            title: 'Quotation',
            fileLabel: '${fileBase}_quotation.pdf',
            documentText: documentText,
          ),
        ),
      ),
    );
  }

  Future<void> _savePdf() async {
    final lineItems = _buildLineItems();
    if (lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one quotation line before saving a PDF.'),
        ),
      );
      return;
    }
    final customerLabel = _selectedCustomer?.name ?? 'quotation';
    await _savePdfExport(
      title: 'Quotation',
      fileLabel: '${_safeFileName(customerLabel)}_quotation.pdf',
      documentText: _buildDocumentText(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.controller.customers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation Builder'),
        actions: <Widget>[
          IconButton(
            onPressed: _openPreview,
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Preview',
          ),
          IconButton(
            onPressed: _savePdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Save PDF',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: <Widget>[
          Text(
            'Create a branded quotation or estimate using the active shop details.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String?>(
            initialValue: _selectedCustomerId,
            decoration: const InputDecoration(
              labelText: 'Customer',
              hintText: 'Optional for walk-in quotation',
            ),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Walk-in / prospective customer'),
              ),
              ...customers.map(
                (customer) => DropdownMenuItem<String?>(
                  value: customer.id,
                  child: Text('${customer.name} • ${customer.phone}'),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCustomerId = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _validDaysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Validity (days)',
              hintText: '7',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Delivery note, payment terms, or offer details',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Quotation lines',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _lineDrafts.add(_QuotationLineDraft());
                  });
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Line'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...List<Widget>.generate(_lineDrafts.length, (index) {
            final draft = _lineDrafts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Line ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (_lineDrafts.length > 1)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  final removed = _lineDrafts.removeAt(index);
                                  removed.dispose();
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              tooltip: 'Remove line',
                            ),
                        ],
                      ),
                      TextField(
                        controller: draft.nameController,
                        decoration: const InputDecoration(
                          labelText: 'Item or service',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: draft.quantityController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: draft.unitPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Unit price',
                              ),
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
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: FilledButton.icon(
            onPressed: _openPreview,
            icon: const Icon(Icons.description_outlined),
            label: const Text('Preview Quotation'),
          ),
        ),
      ),
    );
  }
}

class _QuotationLineDraft {
  _QuotationLineDraft()
    : nameController = TextEditingController(),
      quantityController = TextEditingController(text: '1'),
      unitPriceController = TextEditingController();

  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }
}
