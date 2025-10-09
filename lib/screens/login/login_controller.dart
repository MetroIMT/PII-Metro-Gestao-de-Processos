import 'package:mongo_dart/mongo_dart.dart';
import 'package:pi_metro_2025_2/services/auth_service.dart';

class LoginController {
  LoginController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  Future<bool> login({required String email, required String password}) async {
    return _authService.login(email: email, senha: password);
  }
}
