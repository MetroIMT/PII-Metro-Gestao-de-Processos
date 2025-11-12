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
        if (m['vencimento'] != null) {
          venc = DateTime.tryParse(m['vencimento'].toString());
        }
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
    // Rota de CREATE (POST) mantém a lógica especial /giro
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
      if (m['vencimento'] != null) {
        venc = DateTime.tryParse(m['vencimento'].toString());
      }
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

  Future<void> movimentar({
    required String codigo,
    required String tipo, // 'entrada' ou 'saida'
    required int quantidade,
    required String usuario,
    required String local,
  }) async {
    final uri = Uri.parse('$_baseUrl/materiais/movimentar');
    final body = {
      'codigo': codigo,
      'tipo': tipo,
      'quantidade': quantidade,
      'usuario': usuario,
      'local': local,
    };

    final resp = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      // Tenta decodificar o erro do corpo da resposta
      String errorMessage = 'Falha ao movimentar material: ${resp.statusCode}';
      try {
        final errorBody = json.decode(resp.body);
        if (errorBody['error'] != null) {
          errorMessage = errorBody['error'];
        }
      } catch (_) {
        // se o corpo não for um json válido, usa a mensagem padrão
        errorMessage += ' ${resp.body}';
      }
      throw Exception(errorMessage);
    }
  }

  // --- MÉTODO UPDATE (AGORA USANDO PATCH e ROTA SIMPLES) ---
  Future<EstoqueMaterial> update(
    String codigo, {
    String? nome,
    String? local,
    DateTime? vencimento,
  }) async {
    // --- MUDANÇA: Rota simplificada. /materiais/:codigo para TODOS os tipos ---
    final uri = Uri.parse(
      '$_baseUrl/materiais/$codigo',
    );

    final body = {
      if (nome != null) 'nome': nome,
      if (local != null) 'local': local,
      'vencimento':
          vencimento?.toIso8601String(), // Envia null se for nulo
    };

    final resp = await _client
        .patch( // Usando PATCH
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    )
        .timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception(
        'Falha ao atualizar material: ${resp.statusCode} ${resp.body}',
      );
    }

    final m = json.decode(resp.body);
    DateTime? venc;
    try {
      if (m['vencimento'] != null) {
        venc = DateTime.tryParse(m['vencimento'].toString());
      }
    } catch (_) {
      venc = null;
    }

    // Retorna o material atualizado (importante: `quantidade` vem do servidor)
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

  // --- MÉTODO DELETE (ROTA SIMPLES) ---
  Future<void> delete(String codigo) async {
    // --- MUDANÇA: Rota simplificada. /materiais/:codigo para TODOS os tipos ---
    final uri = Uri.parse(
      '$_baseUrl/materiais/$codigo',
    );

    final resp =
        await _client.delete(uri).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception(
        'Falha ao excluir material: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  void dispose() => _client.close();
}