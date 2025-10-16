import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _storage = const FlutterSecureStorage();

  static const _androidEmulatorHost = '10.0.2.2';
  static const _iosSimulatorHost = '127.0.0.1';
  static const _desktopHost = 'http://localhost:8080';

  static final RegExp _metroEmailRegex =
      RegExp(r'^[a-z0-9._%+-]+@metrosp\.com\.br$');

  static String get _baseUrl {
    if (kIsWeb) return _desktopHost;

    if (Platform.isAndroid) return 'http://$_androidEmulatorHost:8080';
    if (Platform.isIOS) return 'http://$_iosSimulatorHost:8080';

    return _desktopHost; // macOS/Windows/Linux
  }

  Future<bool> login({required String email, required String senha}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = senha.trim();

    if (!_metroEmailRegex.hasMatch(normalizedEmail)) {
      debugPrint('Email fora do domínio permitido: $email');
      return false;
    }

    if (trimmedPassword.isEmpty) {
      debugPrint('Senha não informada.');
      return false;
    }

    final uri = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': normalizedEmail, 'senha': trimmedPassword}),
      );

      if (response.statusCode != 200) {
        debugPrint('Login falhou: ${response.statusCode} ${response.body}');
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) return false;

      await Future.wait([
        _storage.write(key: 'token', value: token),
        _storage.write(key: 'role', value: data['role'] as String?),
        _storage.write(key: 'nome', value: data['nome'] as String?),
        _storage.write(key: 'userId', value: data['id'] as String?),
        _storage.write(
          key: 'tokenExpiresIn',
          value: (data['expiresIn']?.toString() ?? ''),
        ),
      ]);

      return true;
    } catch (e, stack) {
      debugPrint('Erro ao chamar /auth/login: $e');
      debugPrint(stack.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: 'token'),
      _storage.delete(key: 'role'),
      _storage.delete(key: 'nome'),
      _storage.delete(key: 'userId'),
      _storage.delete(key: 'tokenExpiresIn'),
    ]);
  }

  Future<String?> get token async => _storage.read(key: 'token');
}