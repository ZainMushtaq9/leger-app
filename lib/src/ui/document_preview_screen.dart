import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.title,
    required this.documentText,
    this.onShare,
    this.onDownload,
    this.onPrint,
  });

  final String title;
  final String documentText;
  final Future<void> Function()? onShare;
  final Future<void> Function()? onDownload;
  final Future<void> Function()? onPrint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: <Widget>[
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: documentText));
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Document copied.')));
            },
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: 'Copy',
          ),
          if (onShare != null)
            IconButton(
              onPressed: onShare,
              icon: const Icon(Icons.ios_share_rounded),
              tooltip: 'Share',
            ),
          if (onPrint != null)
            IconButton(
              onPressed: onPrint,
              icon: const Icon(Icons.print_rounded),
              tooltip: 'Print',
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: <Widget>[
            SelectableText(
              documentText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: onDownload == null && onPrint == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Row(
                  children: <Widget>[
                    if (onDownload != null)
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onDownload,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Save File'),
                        ),
                      ),
                    if (onDownload != null && onPrint != null)
                      const SizedBox(width: 12),
                    if (onPrint != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPrint,
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('Print'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
