import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/auth_service.dart';
import '../utils/http.dart';

class AuthRouter {
  AuthRouter(this._service);

  final AuthService _service;

  Router get router {
    final router = Router();

    router.post('/login', (Request request) async {
      final body = await request.readAsString();
      final data = body.isEmpty ? <String, dynamic>{} : jsonDecode(body);

      final email = data['email'] as String?;
      final senha = data['senha'] as String?;
      if (email == null || senha == null) {
        return jsonResponse(400, {'error': 'email e senha são obrigatórios'});
      }

      final authResult = await _service.login(email: email, senha: senha);
      if (authResult == null) {
        return jsonResponse(401, {'error': 'Credenciais inválidas'});
      }

      return jsonResponse(200, authResult);
    });

    return router;
  }
}