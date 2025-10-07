// lib/database/mongodb_service.dart

import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  // Variável estática para a instância do banco de dados
  static Db? _db;
  static const String _connectionString = "mongodb+srv://srbreno7:170406Ba@cluster.hb9ue.mongodb.net/?retryWrites=true&w=majority&appName=Cluster"; // IMPORTANTE: Substitua!

  // Método para abrir a conexão
  static Future<void> connect() async {
    try {
      _db = await Db.create(_connectionString);
      await _db!.open();
      print('Conectado ao MongoDB!');
    } catch (e) {
      print('Erro ao conectar ao MongoDB: $e');
    }
  }

  // Método para fechar a conexão
  static Future<void> close() async {
    if (_db != null && _db!.isConnected) {
      await _db!.close();
      print('🔌 Conexão com MongoDB fechada.');
    }
  }

  // Método para obter uma coleção
  static DbCollection getCollection(String collectionName) {
    if (_db == null || !_db!.isConnected) {
      throw Exception('Banco de dados não conectado. Chame connect() primeiro.');
    }
    return _db!.collection(collectionName);
  }
}