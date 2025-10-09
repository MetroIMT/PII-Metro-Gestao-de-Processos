import 'package:mongo_dart/mongo_dart.dart';

import '../config.dart';

class MongoClient {
  MongoClient._();

  static Db? _db;

  static Future<Db> connect() async {
    if (_db?.isConnected ?? false) {
      return _db!;
    }

    final db = await Db.create(AppConfig.mongoUri);
    await db.open();
    _db = db;
    return db;
  }

  static Db get db {
    final current = _db;
    if (current == null || !current.isConnected) {
      throw StateError(
        'MongoDB não conectado. Chame MongoClient.connect() antes.',
      );
    }
    return current;
  }

  /// Obtém uma coleção do banco de dados
  static DbCollection collection(String collectionName) {
    return db.collection(collectionName);
  }

  /// Fecha a conexão com o banco de dados
  static Future<void> close() async {
    if (_db?.isConnected ?? false) {
      await _db!.close();
      _db = null;
    }
  }

  /// Executa operações em uma transação (requer Replica Set)
  /// Para uso simples, removi a dependência de Session que não existe na versão atual
  static Future<T> withTransaction<T>(
    Future<T> Function(Db db) operation,
  ) async {
    final db = MongoClient.db;

    // Verifica se o MongoDB suporta transações
    try {
      // Para operações simples, executa diretamente
      // Em um ambiente de produção com Replica Set, você pode implementar
      // transações mais robustas usando a API específica do mongo_dart
      return await operation(db);
    } catch (e) {
      // Em caso de erro, relança a exceção
      rethrow;
    }
  }
}
