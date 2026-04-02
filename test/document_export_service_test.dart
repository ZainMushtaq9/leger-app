import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/services/document_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentExportService', () {
    test('builds non-empty PDF bytes from plain text', () async {
      const service = DocumentExportService();
      final bytes = await service.buildTextPdf(
        title: 'Report',
        documentText: 'Line 1\nLine 2\nLine 3',
      );

      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });
  });
}
