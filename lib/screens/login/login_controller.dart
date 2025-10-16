import 'package:pi_metro_2025_2/services/auth_service.dart';

class LoginController {
  LoginController({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  static final RegExp _metroEmailRegex =
      RegExp(r'^[a-z0-9._%+-]+@metrosp\.com\.br$');

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!_metroEmailRegex.hasMatch(normalizedEmail)) {
      throw const FormatException('Use um e-mail @metrosp.com.br');
    }

    if (password.trim().isEmpty) {
      throw const FormatException('Senha obrigatória.');
    }

    return _authService.login(
      email: normalizedEmail,
      senha: password,
    );
  }
}