import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

import '../config.dart';
import '../utils/http.dart';

Middleware authMiddleware({bool required = true}) {
  return (innerHandler) {
    return (Request request) async {
      final header = request.headers['authorization'];
      if (header == null || !header.startsWith('Bearer ')) {
        if (!required) return innerHandler(request);
        return jsonResponse(401, {'error': 'Token ausente'});
      }

      final token = header.substring(7).trim();
      try {
        final jwt = JWT.verify(token, SecretKey(AppConfig.jwtSecret));
        final userContext = <String, dynamic>{
          'sub': jwt.payload['sub'],
          'role': jwt.payload['role'],
          'token': token,
        };

        final updatedRequest = request.change(context: {'user': userContext});
        return innerHandler(updatedRequest);
      } on JWTExpiredException {
        return jsonResponse(401, {'error': 'Token expirado'});
      } catch (_) {
        return jsonResponse(401, {'error': 'Token inválido'});
      }
    };
  };
}

Middleware requireRole(List<String> roles) {
  return (innerHandler) {
    return (Request request) async {
      final user = request.context['user'] as Map<String, dynamic>?;
      if (user == null) {
        return jsonResponse(401, {'error': 'Não autorizado'});
      }
      if (!roles.contains(user['role'])) {
        return jsonResponse(403, {'error': 'Acesso negado'});
      }
      return innerHandler(request);
    };
  };
}
