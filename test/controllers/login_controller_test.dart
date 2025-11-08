import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:pi_metro_2025_2/screens/login/login_controller.dart';
import 'package:pi_metro_2025_2/services/auth_service.dart';

class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(client: http.Client());

  bool returnValue = true;
  bool shouldThrow = false;
  bool wasCalled = false;
  String? lastEmail;
  String? lastSenha;

  @override
  Future<bool> login({required String email, required String senha}) async {
    wasCalled = true;
    lastEmail = email;
    lastSenha = senha;

    if (shouldThrow) {
      throw Exception('Erro de conexão');
    }

    return returnValue;
  }
}

void main() {
  late _FakeAuthService fakeAuthService;
  late LoginController loginController;

  setUp(() {
    fakeAuthService = _FakeAuthService();
    loginController = LoginController(authService: fakeAuthService);
  });

  test('Login bem-sucedido deve retornar true', () async {
    fakeAuthService.returnValue = true;

    final result = await loginController.login(
      email: 'teste@metrosp.com.br',
      password: 'senha123',
    );

    expect(result, isTrue);
    expect(fakeAuthService.wasCalled, isTrue);
    expect(fakeAuthService.lastEmail, 'teste@metrosp.com.br');
    expect(fakeAuthService.lastSenha, 'senha123');
  });

  test('Login com credenciais inválidas deve retornar false', () async {
    fakeAuthService.returnValue = false;

    final result = await loginController.login(
      email: 'errado@metrosp.com.br',
      password: 'senhaerrada',
    );

    expect(result, isFalse);
    expect(fakeAuthService.wasCalled, isTrue);
    expect(fakeAuthService.lastEmail, 'errado@metrosp.com.br');
    expect(fakeAuthService.lastSenha, 'senhaerrada');
  });

  test('Login normaliza o email antes de chamar o serviço', () async {
    fakeAuthService.returnValue = true;

    await loginController.login(
      email: '  USER@METROSP.COM.BR ',
      password: 'password123',
    );

    expect(fakeAuthService.wasCalled, isTrue);
    expect(fakeAuthService.lastEmail, 'user@metrosp.com.br');
    expect(fakeAuthService.lastSenha, 'password123');
  });

  test('Login com erro de conexão deve propagar exceção', () async {
    fakeAuthService.shouldThrow = true;

    expect(
      () async => loginController.login(
        email: 'teste@metrosp.com.br',
        password: 'senha123',
      ),
      throwsException,
    );
    expect(fakeAuthService.wasCalled, isTrue);
  });

  test('Login com domínio inválido não chama o serviço', () async {
    expect(
      () async =>
          loginController.login(email: 'teste@gmail.com', password: 'senha123'),
      throwsA(isA<FormatException>()),
    );

    expect(fakeAuthService.wasCalled, isFalse);
  });
}
