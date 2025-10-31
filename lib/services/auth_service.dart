import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _storage = const FlutterSecureStorage();

  static const _androidEmulatorHost = '10.0.2.2';
  static const _iosSimulatorHost = '127.0.0.1';
  static const _desktopHost = 'http://localhost:8080';

  static final RegExp _metroEmailRegex = RegExp(
    r'^[a-z0-9._%+-]+@metrosp\.com\.br$',
  );

  static String get _baseUrl {
    if (kIsWeb) return _desktopHost;

    if (Platform.isAndroid) return 'http://$_androidEmulatorHost:8080';
    if (Platform.isIOS) return 'http://$_iosSimulatorHost:8080';

    return _desktopHost; // macOS/Windows/Linux
  }

  static const Duration _timeoutDuration = Duration(seconds: 30);

  Future<bool> login({required String email, required String senha}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedPassword = senha.trim();

    if (!_metroEmailRegex.hasMatch(normalizedEmail)) {
      debugPrint('Email fora do domínio permitido: $email');
      throw Exception('Use um e-mail @metrosp.com.br');
    }

    if (trimmedPassword.isEmpty) {
      debugPrint('Senha não informada.');
      throw Exception('Senha obrigatória');
    }

    final uri = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': normalizedEmail,
              'senha': trimmedPassword,
            }),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              throw TimeoutException(
                'Conexão com o servidor expirou. Tente novamente.',
              );
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token == null || token.isEmpty) return false;

        // Persist token and metadata in secure storage and SharedPreferences so
        // web and mobile clients can read it regardless of storage support.
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

        try {
          final prefs = await SharedPreferences.getInstance();
          await Future.wait([
            prefs.setString('token', token),
            prefs.setString('role', data['role'] as String? ?? ''),
            prefs.setString('nome', data['nome'] as String? ?? ''),
            prefs.setString('userId', data['id'] as String? ?? ''),
            prefs.setString(
              'tokenExpiresIn',
              data['expiresIn']?.toString() ?? '',
            ),
          ]);
        } catch (_) {
          // Ignore SharedPreferences errors; secure storage already has the token.
        }

        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Email ou senha incorretos');
      } else {
        throw Exception('Erro do servidor: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout: ${e.message}');
      throw Exception(
        'Conexão expirou. Verifique sua conexão com a internet e tente novamente.',
      );
    } on http.ClientException catch (e) {
      debugPrint('Erro ao chamar /auth/login: $e');
      throw Exception(
        'Erro de conexão: ${e.message}. Verifique se o servidor está rodando.',
      );
    } catch (e) {
      debugPrint('Erro desconhecido: $e');
      throw Exception('Erro ao fazer login: $e');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!_metroEmailRegex.hasMatch(normalizedEmail)) {
      throw Exception('Use um e-mail @metrosp.com.br');
    }

    final uri = Uri.parse('$_baseUrl/auth/reset-password');

    try {
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': normalizedEmail}),
          )
          .timeout(
            _timeoutDuration,
            onTimeout: () {
              throw TimeoutException(
                'Conexão com o servidor expirou. Tente novamente.',
              );
            },
          );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Nenhum usuário encontrado para este email');
      } else {
        throw Exception('Erro do servidor: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout: ${e.message}');
      throw Exception(
        'Conexão expirou. Verifique sua conexão com a internet e tente novamente.',
      );
    } on http.ClientException catch (e) {
      debugPrint('Erro ao chamar /auth/reset-password: $e');
      throw Exception(
        'Erro de conexão: ${e.message}. Verifique se o servidor está rodando.',
      );
    } catch (e) {
      debugPrint('Erro desconhecido: $e');
      throw Exception(e.toString().replaceAll("Exception: ", ""));
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

    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('token'),
        prefs.remove('role'),
        prefs.remove('nome'),
        prefs.remove('userId'),
        prefs.remove('tokenExpiresIn'),
      ]);
    } catch (_) {
      // ignore
    }
  }

  Future<String?> get token async {
    try {
      final value = await _storage.read(key: 'token');
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {
      // ignore
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString('token');
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {
      // ignore
    }

    return null;
  }

  /// Returns the role of the current user, reading secure storage first and
  /// falling back to SharedPreferences. Returns null if not present.
  Future<String?> get role async {
    try {
      final value = await _storage.read(key: 'role');
      if (value != null && value.isNotEmpty) return value;
    } catch (_) {
      // ignore
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString('role');
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {
      // ignore
    }

    return null;
  }
}
