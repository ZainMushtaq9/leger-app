import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../controller.dart';
import '../services/document_export_service.dart';
import '../theme.dart';
import 'common_widgets.dart';

class BusinessCardScreen extends StatelessWidget {
  const BusinessCardScreen({super.key, required this.controller});

  final HisabRakhoController controller;

  static const DocumentExportService _documentExportService =
      DocumentExportService();

  Future<Uint8List> _buildBusinessCardPdf() {
    final shop = controller.activeShop;
    return _documentExportService.buildPortalQrPdf(
      title: '${shop.name} business card',
      qrData: controller.buildBusinessCardQrData(),
      detailLines: controller.buildBusinessCardText().split('\n'),
    );
  }

  Future<void> _copyCardText(BuildContext context, String cardText) async {
    await Clipboard.setData(ClipboardData(text: cardText));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Business card copied.')));
  }

  Future<void> _shareCardText(BuildContext context, String cardText) async {
    await SharePlus.instance.share(
      ShareParams(title: 'Business Card', text: cardText),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Business card shared.')));
  }

  Future<void> _shareCardPdf(BuildContext context, String fileLabel) async {
    final bytes = await _buildBusinessCardPdf();
    await SharePlus.instance.share(
      ShareParams(
        title: 'Business Card PDF',
        files: <XFile>[
          XFile.fromData(bytes, mimeType: 'application/pdf', name: fileLabel),
        ],
      ),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Business card PDF shared.')));
  }

  Future<void> _saveCardPdf(BuildContext context, String fileLabel) async {
    final bytes = await _buildBusinessCardPdf();
    final savedPath = await _documentExportService.saveBinaryFile(
      fileLabel: fileLabel,
      bytes: bytes,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedPath == null
              ? 'Business card download started.'
              : 'Business card saved.',
        ),
      ),
    );
  }

  Future<void> _printCardPdf(String fileLabel) async {
    final bytes = await _buildBusinessCardPdf();
    await _documentExportService.printPdf(jobName: fileLabel, bytes: bytes);
  }

  String _fileLabel(String shopName) {
    final normalized = shopName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    return '${normalized.isEmpty ? 'hisab_rakho' : normalized}_business_card.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final shop = controller.activeShop;
        final cardText = controller.buildBusinessCardText();
        final qrData = controller.buildBusinessCardQrData();
        final fileLabel = _fileLabel(shop.name);

        return Scaffold(
          appBar: AppBar(title: const Text('Business Card')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: <Widget>[
              Card(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: <Color>[
                        kKhataGreen,
                        kKhataGreen.withValues(alpha: 0.88),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const BrandMark(size: 56),
                        const SizedBox(height: 18),
                        Text(
                          shop.name,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        if (shop.tagline.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            shop.tagline.trim(),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            InsightChip(
                              label: controller.terminology.userTypeLabel,
                              color: Colors.white,
                            ),
                            if (shop.phone.trim().isNotEmpty)
                              InsightChip(
                                label: shop.phone.trim(),
                                color: Colors.white,
                              ),
                            if (shop.email.trim().isNotEmpty)
                              InsightChip(
                                label: shop.email.trim(),
                                color: Colors.white,
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 190,
                              backgroundColor: Colors.white,
                              gapless: false,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: kKhataInk,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: kKhataGreen,
                              ),
                              semanticsLabel:
                                  'QR code for the active business card',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Card Text',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      SelectableText(cardText),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          FilledButton.tonalIcon(
                            onPressed: () => _copyCardText(context, cardText),
                            icon: const Icon(Icons.copy_all_rounded),
                            label: const Text('Copy'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _shareCardText(context, cardText),
                            icon: const Icon(Icons.ios_share_rounded),
                            label: const Text('Share'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => _shareCardPdf(context, fileLabel),
                            icon: const Icon(Icons.picture_as_pdf_rounded),
                            label: const Text('Share PDF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _saveCardPdf(context, fileLabel),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Save PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _printCardPdf(fileLabel),
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Print'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
