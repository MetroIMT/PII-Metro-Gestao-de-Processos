import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_metro_2025_2/screens/login/login_controller.dart';
import 'package:pi_metro_2025_2/services/auth_service.dart';

@GenerateMocks([AuthService])
import 'login_controller_test.mocks.dart';

void main() {
  group('LoginController - Testes', () {
    late MockAuthService mockAuthService;
    late LoginController loginController;

    setUp(() {
      mockAuthService = MockAuthService();
      loginController = LoginController(authService: mockAuthService);
    });

    test('Login bem-sucedido deve retornar true', () async {
      when(
        mockAuthService.login(
          email: anyNamed('email'),
          senha: anyNamed('senha'),
        ),
      ).thenAnswer((_) async => true);

      final result = await loginController.login(
        email: 'teste@metro.com',
        password: 'senha123',
      );

      expect(result, true);
      verify(
        mockAuthService.login(email: 'teste@metro.com', senha: 'senha123'),
      ).called(1);
    });

    test('Login com credenciais inválidas deve retornar false', () async {
      when(
        mockAuthService.login(
          email: anyNamed('email'),
          senha: anyNamed('senha'),
        ),
      ).thenAnswer((_) async => false);

      final result = await loginController.login(
        email: 'errado@metro.com',
        password: 'senhaerrada',
      );

      expect(result, false);
      verify(
        mockAuthService.login(email: 'errado@metro.com', senha: 'senhaerrada'),
      ).called(1);
    });

    test(
      'Login deve chamar AuthService.login com os parâmetros corretos',
      () async {
        when(
          mockAuthService.login(
            email: anyNamed('email'),
            senha: anyNamed('senha'),
          ),
        ).thenAnswer((_) async => true);

        const testEmail = 'user@metro.com';
        const testPassword = 'password123';

        await loginController.login(email: testEmail, password: testPassword);

        verify(
          mockAuthService.login(email: testEmail, senha: testPassword),
        ).called(1);
      },
    );

    test('Login com erro de conexão deve propagar exceção', () async {
      when(
        mockAuthService.login(
          email: anyNamed('email'),
          senha: anyNamed('senha'),
        ),
      ).thenThrow(Exception('Erro de conexão'));

      expect(
        () async => await loginController.login(
          email: 'teste@metro.com',
          password: 'senha123',
        ),
        throwsException,
      );
    });
  });
}
