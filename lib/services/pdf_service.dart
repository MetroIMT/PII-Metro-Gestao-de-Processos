import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  static Future<void> generateReport({
    required String title,
    required List<Map<String, dynamic>> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Relatório de Movimentação: $title'),
        ),
        build: (context) => [
          pw.Header(
            level: 1,
            text: 'Período: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              // Cabeçalho
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  'Data',
                  'Item',
                  'Categoria',
                  'Quantidade',
                  'Usuário',
                ].map((header) => pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    header,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                )).toList(),
              ),
              // Dados
              ...data.map((item) => pw.TableRow(
                children: [
                  item['data'].toString(),
                  item['item'].toString(),
                  item['categoria'].toString(),
                  item['quantidade'].toString(),
                  item['usuario'].toString(),
                ].map((cell) => pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(cell),
                )).toList(),
              )).toList(),
            ],
          ),
        ],
      ),
    );

    // Salvar o arquivo
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    // Abrir o arquivo
    await OpenFile.open(file.path);
  }
}