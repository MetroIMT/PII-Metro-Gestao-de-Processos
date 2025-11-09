import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movimentacao.dart';

class MovimentacaoService {
  static const String _baseUrl = 'http://localhost:8080';
  final http.Client _client = http.Client();

  Future<List<Movimentacao>> getAllMovimentacoes() async {
  final uri = Uri.parse('$_baseUrl/movimentos');
    try {
      final resp = await _client.get(uri).timeout(const Duration(seconds: 30));

      if (resp.statusCode != 200) {
        throw Exception('Falha ao buscar movimentações: ${resp.statusCode}');
      }

      final decoded = json.decode(resp.body);
      if (decoded is! List) return [];

      return decoded.map<Movimentacao>((m) {
        return Movimentacao.fromJson(m);
      }).toList();
    } catch (e) {
      print('Erro ao buscar movimentações: $e');
      rethrow;
    }
  }

  void dispose() => _client.close();
}
