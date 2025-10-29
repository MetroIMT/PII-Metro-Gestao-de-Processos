// pdf_service.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static Future<void> generateReport({
    required String title,
    required List<Map<String, String>> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 8),
          pw.Text('Período: ${startDate.day}/${startDate.month}/${startDate.year} '
              'a ${endDate.day}/${endDate.month}/${endDate.year}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Data', 'Item', 'Categoria', 'Qntd', 'Usuário'],
            data: data.map((r) => [
              r['data'] ?? '',
              r['item'] ?? '',
              r['categoria'] ?? '',
              r['quantidade'] ?? '',
              r['usuario'] ?? '',
            ]).toList(),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      // Abre o diálogo de impressão/“salvar como PDF” no navegador
      await Printing.layoutPdf(onLayout: (format) async => bytes);
      return;
    }

    // Android/iOS/desktop
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

  }
}
