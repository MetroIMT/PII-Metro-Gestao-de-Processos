import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pi_metro_2025_2/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService - Testes de Login', () {
    test('Login com credenciais inválidas deve retornar false', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        expect(request.method, 'POST');
        return http.Response('Unauthorized', 401);
      });

      final authService = AuthService(client: client);

      final result = await authService.login(
        email: 'errado@metrosp.com.br',
        senha: 'senhaerrada',
      );

      expect(called, true);
      expect(result, false);
    });

    test('Login com resposta sem token deve retornar false', () async {
      var called = false;
      final responseBody = jsonEncode({'message': 'Success', 'token': ''});

      final client = MockClient((request) async {
        called = true;
        return http.Response(responseBody, 200);
      });

      final authService = AuthService(client: client);

      final result = await authService.login(
        email: 'teste@metrosp.com.br',
        senha: 'senha123',
      );

      expect(called, true);
      expect(result, false);
    });

    test('Login com erro de conexão deve retornar false', () async {
      final client = MockClient((request) async {
        throw Exception('Erro de conexão');
      });

      final authService = AuthService(client: client);

      final result = await authService.login(
        email: 'teste@metrosp.com.br',
        senha: 'senha123',
      );

      expect(result, false);
    });

    test('Login com status 500 deve retornar false', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('Server Error', 500);
      });

      final authService = AuthService(client: client);

      final result = await authService.login(
        email: 'teste@metrosp.com.br',
        senha: 'senha123',
      );

      expect(called, true);
      expect(result, false);
    });

    test(
      'Login com email fora do domínio deve retornar false sem POST',
      () async {
        var called = false;
        final client = MockClient((request) async {
          called = true;
          return http.Response('Ok', 200);
        });

        final authService = AuthService(client: client);

        final result = await authService.login(
          email: 'teste@gmail.com',
          senha: 'senha123',
        );

        expect(called, false);
        expect(result, false);
      },
    );

    test('Login com email vazio deve retornar false sem POST', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('Ok', 200);
      });

      final authService = AuthService(client: client);

      final result = await authService.login(email: '', senha: 'senha123');

      expect(called, false);
      expect(result, false);
    });

    test('Login com senha vazia deve retornar false sem POST', () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('Ok', 200);
      });

      final authService = AuthService(client: client);

      final result = await authService.login(
        email: 'teste@metrosp.com.br',
        senha: '',
      );

      expect(called, false);
      expect(result, false);
    });
  });
}
