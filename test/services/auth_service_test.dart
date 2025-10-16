import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_metro_2025_2/services/auth_service.dart';

@GenerateMocks([http.Client])
import 'auth_service_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService - Testes de Login', () {
    late MockClient mockClient;
    late AuthService authService;

    setUp(() {
      mockClient = MockClient();
      authService = AuthService(client: mockClient);
    });

    test('Login com credenciais inválidas deve retornar false', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Unauthorized', 401));

      final result = await authService.login(
        email: 'errado@metro.com',
        senha: 'senhaerrada',
      );

      expect(result, false);
    });

    test('Login com resposta sem token deve retornar false', () async {
      final responseBody = jsonEncode({'message': 'Success', 'token': ''});

      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response(responseBody, 200));

      final result = await authService.login(
        email: 'teste@metro.com',
        senha: 'senha123',
      );

      expect(result, false);
    });

    test('Login com erro de conexão deve retornar false', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenThrow(Exception('Erro de conexão'));

      final result = await authService.login(
        email: 'teste@metro.com',
        senha: 'senha123',
      );

      expect(result, false);
    });

    test('Login com status 500 deve retornar false', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final result = await authService.login(
        email: 'teste@metro.com',
        senha: 'senha123',
      );

      expect(result, false);
    });

    test('Login com email vazio deve tentar fazer requisição', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Bad Request', 400));

      final result = await authService.login(email: '', senha: 'senha123');

      expect(result, false);
      verify(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).called(1);
    });

    test('Login com senha vazia deve tentar fazer requisição', () async {
      when(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => http.Response('Bad Request', 400));

      final result = await authService.login(
        email: 'teste@metro.com',
        senha: '',
      );

      expect(result, false);
      verify(
        mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        ),
      ).called(1);
    });
  });
}
