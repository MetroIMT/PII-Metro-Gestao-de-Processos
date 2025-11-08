import 'package:pi_metro_2025_2/services/auth_service.dart';

class MockAuthService extends AuthService {
  MockAuthService() : super();

  @override
  Future<bool> login({required String email, required String senha}) async {
    // Simular delay de rede
    await Future.delayed(const Duration(milliseconds: 100));

    final normalizedEmail = email.trim().toLowerCase();

    // Validar campos vazios
    if (normalizedEmail.isEmpty || senha.isEmpty) {
      return false;
    }

    // Validar domínio do email
    if (!normalizedEmail.endsWith('@metrosp.com.br')) {
      return false;
    }

    // Simular credenciais válidas
    if (normalizedEmail == 'admin@metrosp.com.br' && senha == 'Admin@123') {
      return true;
    }

    // Credenciais inválidas
    return false;
  }
}
