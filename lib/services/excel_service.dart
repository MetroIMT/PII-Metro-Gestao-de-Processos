import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ExcelService {
  static Future<void> generateReport({
    required String title,
    required List<Map<String, String>> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Relatório'];

    // Cabeçalho
    sheet.appendRow([
      TextCellValue(title),
      TextCellValue('Período:'),
      TextCellValue(
        '${_dd(startDate)}/${_mm(startDate)}/${startDate.year} '
        'a ${_dd(endDate)}/${_mm(endDate)}/${endDate.year}',
      ),
    ]);

    // Linha em branco
    sheet.appendRow([TextCellValue('')]);

    // Títulos da tabela
    sheet.appendRow([
      TextCellValue('Data'),
      TextCellValue('Item'),
      TextCellValue('Categoria'),
      TextCellValue('Qntd'),
      TextCellValue('Usuário'),
    ]);

    // Linhas de dados
    for (final r in data) {
      sheet.appendRow([
        TextCellValue(r['data'] ?? ''),
        TextCellValue(r['item'] ?? ''),
        TextCellValue(r['categoria'] ?? ''),
        TextCellValue(r['quantidade'] ?? ''),
        TextCellValue(r['usuario'] ?? ''),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Falha ao gerar XLSX');

    final uint8 = Uint8List.fromList(bytes);
    final fileName = 'relatorio_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    if (kIsWeb) {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: uint8,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final f = File(path);
    await f.writeAsBytes(uint8, flush: true);

    await OpenFilex.open(path);
  }

  static String _dd(DateTime d) => d.day.toString().padLeft(2, '0');
  static String _mm(DateTime d) => d.month.toString().padLeft(2, '0');
}
