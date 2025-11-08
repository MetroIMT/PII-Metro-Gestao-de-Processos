// lib/services/pdf_service.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
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
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        build: (context) => [
          _buildHeader(title, startDate, endDate),
          pw.SizedBox(height: 16),
          _buildTable(data),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    final bytes = await pdf.save();

    if (kIsWeb) {
      // Web: abre diálogo de impressão / salvar como PDF
      await Printing.layoutPdf(onLayout: (format) async => bytes);
      return;
    }

    // Android/iOS/desktop: salva em diretório temporário
    final dir = await getTemporaryDirectory();
    final filePath =
        '${dir.path}/relatorio_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
  }

  // ---------- TEMPLATE DO RELATÓRIO ----------

  static pw.Widget _buildHeader(
    String title,
    DateTime startDate,
    DateTime endDate,
  ) {
    final dataInicio = '${_dd(startDate)}/${_mm(startDate)}/${startDate.year}';
    final dataFim = '${_dd(endDate)}/${_mm(endDate)}/${endDate.year}';

    final now = DateTime.now();
    final horaExportacao =
        '${_dd(now)}/${_mm(now)}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Linha superior (data/hora atual)
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Gerado em: $horaExportacao',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 8),

        // Título principal
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),

        pw.SizedBox(height: 4),

        // Subtítulo com o período
        pw.Text(
          'Relatório de $dataInicio a $dataFim',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),

        pw.SizedBox(height: 12),
        pw.Divider(thickness: 1),
      ],
    );
  }

  static pw.Widget _buildTable(List<Map<String, String>> data) {
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 10,
      color: PdfColors.grey800,
    );

    final cellStyle = pw.TextStyle(fontSize: 9, color: PdfColors.grey800);

    return pw.Table(
      border: pw.TableBorder.symmetric(
        inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.4),
        outside: const pw.BorderSide(color: PdfColors.grey400, width: 0.6),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.0), // Código
        1: const pw.FlexColumnWidth(1.2), // Data
        2: const pw.FlexColumnWidth(2.6), // Item
        3: const pw.FlexColumnWidth(2.0), // Categoria
        4: const pw.FlexColumnWidth(1.2), // Quantidade
        7: const pw.FlexColumnWidth(1.6), // Usuário
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFEFEFEF),
          ),
          children: [
            _headerCell('Código', headerStyle),
            _headerCell('Data', headerStyle),
            _headerCell('Item', headerStyle),
            _headerCell('Categoria', headerStyle),
            _headerCell(
              'Quantidade',
              headerStyle,
              align: pw.Alignment.centerRight,
            ),
            _headerCell('Usuário', headerStyle),
          ],
        ),

        // Linhas da tabela
        for (int i = 0; i < data.length; i++)
          _buildDataRow(data[i], cellStyle, i),
      ],
    );
  }

  static pw.TableRow _buildDataRow(
    Map<String, String> row,
    pw.TextStyle baseStyle,
    int index,
  ) {
    final bgColor = index.isEven
        ? PdfColors.white
        : const PdfColor(0.97, 0.97, 0.97);

    final qtdStr = row['quantidade'] ?? '';
    final qtdNum = int.tryParse(qtdStr.replaceAll(',', '.')) ?? 0;

    final qtdColor = qtdNum < 0
        ? PdfColors.red
        : qtdNum > 0
        ? PdfColors.green
        : PdfColors.black;

    return pw.TableRow(
      decoration: pw.BoxDecoration(color: bgColor),
      children: [
        _cell(row['codigo'] ?? '', baseStyle),
        _cell(row['data'] ?? '', baseStyle),
        _cell(row['item'] ?? '', baseStyle),
        _cell(row['categoria'] ?? '', baseStyle),
        _cell(
          qtdStr,
          baseStyle.copyWith(color: qtdColor), // Quantidade
          align: pw.Alignment.centerRight,
        ),
        _cell(row['usuario'] ?? '', baseStyle),
      ],
    );
  }

  // ---------- Helpers de célula ----------

  static pw.Widget _headerCell(
    String text,
    pw.TextStyle style, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      child: pw.Text(
        text,
        style: style,
        maxLines: 2,
        overflow: pw.TextOverflow.clip,
      ),
    );
  }

  static String _dd(DateTime d) => d.day.toString().padLeft(2, '0');
  static String _mm(DateTime d) => d.month.toString().padLeft(2, '0');
}
