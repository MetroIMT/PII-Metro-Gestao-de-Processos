import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/home/estoque_page.dart';

class MaterialService {
  static const String _baseUrl = 'http://localhost:8080';
  final http.Client _client = http.Client();

  Future<List<EstoqueMaterial>> getByTipo(String tipo) async {
    final uri = Uri.parse('$_baseUrl/materiais?tipo=$tipo');
    final resp = await _client.get(uri).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception('Falha ao buscar materiais: ${resp.statusCode}');
    }

    final decoded = json.decode(resp.body);
    if (decoded is! List) return [];

    return decoded.map<EstoqueMaterial>((m) {
      DateTime? venc;
      try {
        if (m['vencimento'] != null)
          venc = DateTime.tryParse(m['vencimento'].toString());
      } catch (_) {
        venc = null;
      }

      return EstoqueMaterial(
        codigo: m['codigo']?.toString() ?? '',
        nome: m['nome']?.toString() ?? '',
        quantidade: (m['quantidade'] is int)
            ? m['quantidade'] as int
            : int.tryParse(m['quantidade']?.toString() ?? '0') ?? 0,
        local: m['local']?.toString() ?? '',
        vencimento: venc,
      );
    }).toList();
  }

  Future<EstoqueMaterial> create({
    required String codigo,
    required String nome,
    required int quantidade,
    required String local,
    DateTime? vencimento,
    String? tipo,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/materiais${tipo == 'giro' ? '/giro' : ''}',
    );
    final body = {
      'codigo': codigo,
      'nome': nome,
      'quantidade': quantidade,
      'local': local,
      if (vencimento != null) 'vencimento': vencimento.toIso8601String(),
      if (tipo != null && tipo != 'giro') 'tipo': tipo,
    };

    final resp = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(
        'Falha ao criar material: ${resp.statusCode} ${resp.body}',
      );
    }

    final m = json.decode(resp.body);
    DateTime? venc;
    try {
      if (m['vencimento'] != null)
        venc = DateTime.tryParse(m['vencimento'].toString());
    } catch (_) {
      venc = null;
    }

    return EstoqueMaterial(
      codigo: m['codigo']?.toString() ?? '',
      nome: m['nome']?.toString() ?? '',
      quantidade: (m['quantidade'] is int)
          ? m['quantidade'] as int
          : int.tryParse(m['quantidade']?.toString() ?? '0') ?? 0,
      local: m['local']?.toString() ?? '',
      vencimento: venc,
    );
  }

  void dispose() => _client.close();
}
