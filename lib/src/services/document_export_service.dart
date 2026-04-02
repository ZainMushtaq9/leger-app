import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DocumentExportService {
  const DocumentExportService();

  Future<String?> saveTextFile({
    required String fileLabel,
    required String content,
  }) {
    return saveBinaryFile(
      fileLabel: fileLabel,
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
  }

  Future<String?> saveBinaryFile({
    required String fileLabel,
    required Uint8List bytes,
  }) {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save export file',
      fileName: fileLabel,
      bytes: bytes,
    );
  }

  Future<Uint8List> buildTextPdf({
    required String title,
    required String documentText,
  }) async {
    final pdf = pw.Document();
    final base = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Variable.ttf'),
    );
    final arabicFallback = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoNaskhArabic-Variable.ttf'),
    );
    final lines = documentText.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 32),
          theme: pw.ThemeData.withFont(
            base: base,
            bold: base,
            fontFallback: <pw.Font>[arabicFallback],
          ),
        ),
        build: (context) => <pw.Widget>[
          pw.Text(
            title,
            style: pw.TextStyle(
              font: base,
              fontSize: 20,
              color: PdfColors.green800,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Text(
                line.isEmpty ? ' ' : line,
                style: pw.TextStyle(font: base, fontSize: 10.5, lineSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> buildPortalQrPdf({
    required String title,
    required String qrData,
    required List<String> detailLines,
  }) async {
    final pdf = pw.Document();
    final base = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Variable.ttf'),
    );

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 28),
          theme: pw.ThemeData.withFont(base: base, bold: base),
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Text(
              title,
              style: pw.TextStyle(
                font: base,
                fontSize: 20,
                color: PdfColors.green800,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 18),
            pw.Center(
              child: pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: qrData,
                width: 190,
                height: 190,
              ),
            ),
            pw.SizedBox(height: 18),
            ...detailLines.map(
              (line) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  line,
                  style: pw.TextStyle(font: base, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> printPdf({required String jobName, required Uint8List bytes}) {
    return Printing.layoutPdf(
      name: jobName,
      onLayout: (PdfPageFormat format) async => bytes,
    );
  }
}
