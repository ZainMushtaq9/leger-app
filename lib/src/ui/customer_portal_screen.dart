import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller.dart';
import '../models.dart';
import '../services/document_export_service.dart';
import '../theme.dart';
import 'common_widgets.dart';

class CustomerPortalScreen extends StatelessWidget {
  const CustomerPortalScreen({
    super.key,
    required this.controller,
    required this.customer,
  });

  final HisabRakhoController controller;
  final Customer customer;

  static const DocumentExportService _documentExportService =
      DocumentExportService();

  Future<void> _copyLink(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Portal link copied.')));
  }

  Future<void> _copySummary(BuildContext context, String summary) async {
    await Clipboard.setData(ClipboardData(text: summary));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Portal summary copied.')));
  }

  Future<void> _copyShareCode(BuildContext context, String shareCode) async {
    await Clipboard.setData(ClipboardData(text: shareCode));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share code copied.')));
  }

  Future<void> _sharePortal(
    BuildContext context,
    Customer liveCustomer,
    String link,
  ) async {
    await SharePlus.instance.share(
      ShareParams(
        title: '${liveCustomer.name} portal',
        text:
            '${controller.buildCustomerPortalSummary(liveCustomer)}\n\nStatement preview\n${controller.buildStatementShareText(liveCustomer)}\n\n$link',
      ),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Portal summary shared.')));
  }

  Future<void> _openPortal(BuildContext context, String link) async {
    final launched = await launchUrl(
      Uri.parse(link),
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          launched
              ? 'Portal opened in the browser.'
              : 'The portal could not be opened.',
        ),
      ),
    );
  }

  Future<Uint8List> _buildQrPdf(
    Customer liveCustomer,
    String link,
    double balance,
  ) {
    return _documentExportService.buildPortalQrPdf(
      title: '${liveCustomer.name} portal QR',
      qrData: link,
      detailLines: <String>[
        'Shop: ${(controller.shopById(liveCustomer.shopId) ?? controller.activeShop).name}',
        'Customer: ${liveCustomer.name}',
        'Share code: ${liveCustomer.shareCode}',
        'Balance: ${controller.formatCurrency(balance)}',
        'Portal link: $link',
      ],
    );
  }

  Future<void> _shareQrPdf(
    BuildContext context,
    Customer liveCustomer,
    String link,
    double balance,
  ) async {
    final bytes = await _buildQrPdf(liveCustomer, link, balance);
    await SharePlus.instance.share(
      ShareParams(
        title: '${liveCustomer.name} portal QR',
        files: <XFile>[
          XFile.fromData(
            bytes,
            mimeType: 'application/pdf',
            name: '${liveCustomer.name}_portal_qr.pdf',
          ),
        ],
      ),
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Portal QR PDF shared.')));
  }

  Future<void> _saveQrPdf(
    BuildContext context,
    Customer liveCustomer,
    String link,
    double balance,
  ) async {
    final bytes = await _buildQrPdf(liveCustomer, link, balance);
    final savedPath = await _documentExportService.saveBinaryFile(
      fileLabel: '${liveCustomer.name}_portal_qr.pdf',
      bytes: bytes,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedPath == null
              ? 'Portal QR PDF download started.'
              : 'Portal QR PDF saved.',
        ),
      ),
    );
  }

  Future<void> _printQrPdf(
    BuildContext context,
    Customer liveCustomer,
    String link,
    double balance,
  ) async {
    final bytes = await _buildQrPdf(liveCustomer, link, balance);
    await _documentExportService.printPdf(
      jobName: '${liveCustomer.name} portal QR',
      bytes: bytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final liveCustomer = controller.customerById(customer.id) ?? customer;
        final insight = controller.insightFor(liveCustomer.id);
        final link = controller.buildCustomerStatementLink(liveCustomer);
        final portalSummary = controller.buildCustomerPortalSummary(
          liveCustomer,
        );

        return Scaffold(
          appBar: AppBar(title: Text('${liveCustomer.name} Portal')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Customer Portal Access',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'The customer can scan this QR code or open the link to view their statement and current balance.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: kKhataGreen.withValues(alpha: 0.16),
                          ),
                        ),
                        child: QrImageView(
                          data: link,
                          version: QrVersions.auto,
                          size: 220,
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
                              'QR code for ${liveCustomer.name} portal link',
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          InsightChip(
                            label: 'Code ${liveCustomer.shareCode}',
                            color: kKhataGreen,
                          ),
                          InsightChip(
                            label:
                                'Balance ${controller.displayCurrency(insight.balance)}',
                            color: insight.balance > 0
                                ? kKhataAmber
                                : kKhataSuccess,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _copyLink(context, link),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text('Copy Link'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPortal(context, link),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open Portal'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => _sharePortal(context, liveCustomer, link),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Portal Summary'),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copySummary(context, portalSummary),
                      icon: const Icon(Icons.notes_rounded),
                      label: const Text('Copy Summary'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _copyShareCode(context, liveCustomer.shareCode),
                      icon: const Icon(Icons.pin_outlined),
                      label: const Text('Copy Share Code'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () => _shareQrPdf(
                      context,
                      liveCustomer,
                      link,
                      insight.balance,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded),
                    label: const Text('Share QR PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _saveQrPdf(
                      context,
                      liveCustomer,
                      link,
                      insight.balance,
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Save QR PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _printQrPdf(
                      context,
                      liveCustomer,
                      link,
                      insight.balance,
                    ),
                    icon: const Icon(Icons.print_rounded),
                    label: const Text('Print QR'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Portal Summary',
                subtitle:
                    'Share or copy this access summary before sending it to the customer.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SelectableText(portalSummary),
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Statement Preview',
                subtitle:
                    'This is the statement context that will be shared with the portal link.',
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: SelectableText(
                    controller.buildStatementShareText(liveCustomer),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
