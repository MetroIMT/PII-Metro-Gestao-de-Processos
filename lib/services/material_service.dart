import 'dart:convert';
import 'package:http/http.dart' as http;
// MUDANÇA: Usar o modelo correto. Você pode precisar ajustar o caminho dependendo da sua estrutura
import '../models/material.dart'; 
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
      // MUDANÇA: Usa o construtor de fábrica EstoqueMaterial.fromJson
      return EstoqueMaterial.fromJson(m);
    }).toList();
  }

  Future<EstoqueMaterial> create({
    required String codigo,
    required String nome,
    required int quantidade,
    required String local,
    DateTime? vencimento,
    String? tipo,
    // NOVOS CAMPOS ADICIONADOS AQUI
    String? patrimonio,
    int? estoqueMinimo,
    DateTime? dataCalibracao,
    String? status,
    // FIM NOVOS CAMPOS
  }) async {
    // Rota de CREATE (POST) mantém a lógica especial /giro
    final uri = Uri.parse(
      // Mantendo a lógica de rota original, mas usando o tipo de instrumento
      '$_baseUrl/materiais${tipo == 'giro' ? '/giro' : ''}',
    );
    
    // MUDANÇA ESSENCIAL: Adicionando todos os novos campos ao body
    final body = {
      'codigo': codigo,
      'nome': nome,
      'quantidade': quantidade,
      'local': local,
      if (vencimento != null) 'vencimento': vencimento.toIso8601String(),
      if (tipo != null && tipo != 'giro') 'tipo': tipo,
      // NOVOS CAMPOS ENVIADOS PARA O BACKEND
      if (patrimonio != null) 'patrimonio': patrimonio,
      if (estoqueMinimo != null) 'estoqueMinimo': estoqueMinimo,
      if (dataCalibracao != null) 'dataCalibracao': dataCalibracao.toIso8601String(),
      if (status != null) 'status': status,
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
    // MUDANÇA: Usa o construtor de fábrica EstoqueMaterial.fromJson
    return EstoqueMaterial.fromJson(m);
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

  // NOVO MÉTODO: Movimentação de Instrumentos (Retirada/Devolução)
  Future<void> movimentarInstrumento({
    required String codigo,
    required String tipoMovimento, // 'retirada' ou 'devolucao'
    required String usuario,
    required String local, // Local de retirada/destino
  }) async {
    // Rota dedicada para Instrumentos (patrimoniados)
    final uri = Uri.parse('$_baseUrl/instrumentos/movimentar'); 
    final body = {
      'codigo': codigo,
      'tipoMovimento': tipoMovimento,
      'quantidade': 1, // Instrumentos são sempre unitários
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
      String errorMessage = 'Falha ao movimentar instrumento: ${resp.statusCode}';
      try {
        final errorBody = json.decode(resp.body);
        if (errorBody['error'] != null) {
          errorMessage = errorBody['error']; 
        }
      } catch (_) {
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
    // NOVOS CAMPOS ADICIONADOS AQUI
    int? estoqueMinimo,
    // FIM NOVOS CAMPOS
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/materiais/$codigo',
    );

    final body = {
      if (nome != null) 'nome': nome,
      if (local != null) 'local': local,
      'vencimento':
          vencimento?.toIso8601String(), // Envia null se for nulo
      // NOVOS CAMPOS ENVIADOS PARA O BACKEND
      if (estoqueMinimo != null) 'estoqueMinimo': estoqueMinimo,
      // O backend precisa lidar com a atualização de dataCalibracao separadamente
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
    // MUDANÇA: Usa o construtor de fábrica EstoqueMaterial.fromJson
    return EstoqueMaterial.fromJson(m);
  }

  // --- MÉTODO DELETE (ROTA SIMPLES) ---
  Future<void> delete(String codigo) async {
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