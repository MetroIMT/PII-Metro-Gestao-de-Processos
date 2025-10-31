import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class UserService {
  static const String _baseUrl = 'http://localhost:8080';
  final http.Client _client = http.Client();

  final _secureStorage = const FlutterSecureStorage();

  Future<void> _clearToken() async {
    try {
      await _secureStorage.delete(key: 'token');
      await _secureStorage.delete(key: 'role');
      await _secureStorage.delete(key: 'nome');
      await _secureStorage.delete(key: 'userId');
      await _secureStorage.delete(key: 'tokenExpiresIn');
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('role');
      await prefs.remove('nome');
      await prefs.remove('userId');
      await prefs.remove('tokenExpiresIn');
    } catch (_) {}
  }

  dynamic _tryDecodeJson(String body) {
    if (body.isEmpty) return null;
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    // Prefer secure storage (used by AuthService). Fall back to SharedPreferences
    // for compatibility with older saved tokens.
    final secure = const FlutterSecureStorage();
    String? token;

    try {
      token = await secure.read(key: 'token');
    } catch (_) {
      // ignore secure storage errors and fallback
      token = null;
    }

    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('token');
    }

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<List<User>> getAll() async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .get(Uri.parse('$_baseUrl/usuarios'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is List) {
          return decoded.map((j) => User.fromJson(j)).toList();
        }
        // Response body wasn't valid JSON array
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Resposta inválida do servidor (esperado JSON): ${response.statusCode} — $snippet',
        );
      } else if (response.statusCode == 401) {
        // Unauthorized - clear stored token so user must re-login.
        final decoded = _tryDecodeJson(response.body);
        await _clearToken();
        if (decoded is Map && decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        throw Exception('Token ausente ou inválido');
      } else {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          throw Exception(decoded['message']);
        }
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Erro ao buscar usuários: status=${response.statusCode}, body=$snippet',
        );
      }
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  Future<User> getById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .get(Uri.parse('$_baseUrl/usuarios/$id'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is Map) {
          return User.fromJson(Map<String, dynamic>.from(decoded));
        }
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Resposta inválida do servidor (esperado JSON): ${response.statusCode} — $snippet',
        );
      } else if (response.statusCode == 401) {
        final decoded = _tryDecodeJson(response.body);
        await _clearToken();
        if (decoded is Map && decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        throw Exception('Token ausente ou inválido');
      } else {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is Map && decoded.containsKey('message')) {
          throw Exception(decoded['message']);
        }
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Erro ao buscar usuário: status=${response.statusCode}, body=$snippet',
        );
      }
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  Future<User> create({
    required String nome,
    required String email,
    required String senha,
    required String cpf,
    required String telefone,
    required String role,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/usuarios'),
            headers: headers,
            body: json.encode({
              'nome': nome,
              'email': email,
              'senha': senha,
              'cpf': cpf,
              'telefone': telefone,
              'role': role,
              'ativo': true,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is Map) {
          return User.fromJson(Map<String, dynamic>.from(decoded));
        }
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Resposta inválida do servidor (esperado JSON): ${response.statusCode} — $snippet',
        );
      } else if (response.statusCode == 401) {
        final decoded = _tryDecodeJson(response.body);
        await _clearToken();
        if (decoded is Map && decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        throw Exception('Token ausente ou inválido');
      } else {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is Map) {
          throw Exception(
            decoded['error'] ?? decoded['message'] ?? 'Erro ao criar usuário',
          );
        }
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Erro ao criar usuário: status=${response.statusCode}, body=$snippet',
        );
      }
    } catch (e) {
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  Future<User> update(
    String id, {
    String? nome,
    String? email,
    String? cpf,
    String? telefone,
    String? role,
  }) async {
    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> body = {};

      if (nome != null && nome.isNotEmpty) body['nome'] = nome;
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (cpf != null && cpf.isNotEmpty) body['cpf'] = cpf;
      if (telefone != null && telefone.isNotEmpty) body['telefone'] = telefone;
      if (role != null && role.isNotEmpty) body['role'] = role;

      final response = await _client
          .patch(
            Uri.parse('$_baseUrl/usuarios/$id'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is Map) {
          return User.fromJson(Map<String, dynamic>.from(decoded));
        }
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Resposta inválida do servidor (esperado JSON): ${response.statusCode} — $snippet',
        );
      } else if (response.statusCode == 401) {
        final decoded = _tryDecodeJson(response.body);
        await _clearToken();
        if (decoded is Map && decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        throw Exception('Token ausente ou inválido');
      } else {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is Map) {
          throw Exception(
            decoded['error'] ??
                decoded['message'] ??
                'Erro ao atualizar usuário',
          );
        }
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Erro ao atualizar usuário: status=${response.statusCode}, body=$snippet',
        );
      }
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await _client
          .delete(Uri.parse('$_baseUrl/usuarios/$id'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 401) {
        final decoded = _tryDecodeJson(response.body);
        await _clearToken();
        if (decoded is Map && decoded.containsKey('error')) {
          throw Exception(decoded['error']);
        }
        throw Exception('Token ausente ou inválido');
      }
      if (response.statusCode != 200 && response.statusCode != 204) {
        final decoded = _tryDecodeJson(response.body);
        if (decoded is Map) {
          throw Exception(
            decoded['error'] ?? decoded['message'] ?? 'Erro ao deletar usuário',
          );
        }
        final snippet = response.body.length > 200
            ? '${response.body.substring(0, 200)}...'
            : response.body;
        throw Exception(
          'Erro ao deletar usuário: status=${response.statusCode}, body=$snippet',
        );
      }
    } catch (e) {
      throw Exception('Erro ao deletar usuário: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
