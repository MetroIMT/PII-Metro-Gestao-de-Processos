import 'package:mongo_dart/mongo_dart.dart';
import 'package:pi_metro_2025_2/database/mongodb_service.dart';
import '../../database/mongodb_service.dart';

class LoginController {
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    print('Tentando logar com email: $email e senha: $password');

    try {
      final usersCollection = MongoService.getCollection('usuarios');
      final user = await usersCollection.findOne(
        where.eq('email', email).eq('password', password),
      );
      if (user != null) {
        print('Usuário encontrado: $user');
        return true;
      } else {
        print('Usuário não encontrado.');
        return false;
      }
    } catch (e) {
      print('Erro ao tentar logar: $e');
      return false;
    }    
  }
}