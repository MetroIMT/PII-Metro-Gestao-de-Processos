import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mongo_dart/mongo_dart.dart';

import '../config.dart';
import '../db/mongo_client.dart';

class AuthService {
  DbCollection get _users => MongoClient.db.collection('usuarios');

  Future<Map<String, dynamic>?> login({
    required String email,
    required String senha,
  }) async {
    final user = await _users.findOne(
      where
        ..eq('email', email)
        ..eq('ativo', true),
    );

    if (user == null) return null;

    final senhaHash = user['senhaHash'] as String? ?? '';
    final ok = BCrypt.checkpw(senha, senhaHash);
    if (!ok) return null;

    final token = JWT(
      {'sub': (user['_id'] as ObjectId).oid, 'role': user['role']},
      subject: (user['_id'] as ObjectId).oid,
    ).sign(SecretKey(AppConfig.jwtSecret), expiresIn: const Duration(hours: 8));

    return {'token': token, 'role': user['role'], 'nome': user['nome']};
  }
}
