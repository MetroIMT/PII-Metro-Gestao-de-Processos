import 'package:mongo_dart/mongo_dart.dart';

import '../db/mongo_client.dart';
import '../utils/mongo_utils.dart';

class ItensService {
  DbCollection _collectionFor(String tipo) {
    switch (tipo) {
      case 'instrumento':
        return MongoClient.db.collection('instrumentos');
      case 'ferramenta':
        return MongoClient.db.collection('ferramentas');
      default:
        throw ArgumentError('tipo deve ser "ferramenta" ou "instrumento"');
    }
  }

  Future<List<Map<String, dynamic>>> listar({
    String? tipo,
    String? status,
  }) async {
    if (tipo != null) {
      final col = _collectionFor(tipo);
      final filtro = <String, dynamic>{};
      if (status != null) filtro['status'] = status;

      final docs = await col.find(filtro).toList();
      // Limita a 200 resultados após buscar
      final limitedDocs = docs.take(200).toList();
      return limitedDocs
          .map((doc) => encodeDocument({...doc, 'tipo': tipo}))
          .toList();
    }

    final db = MongoClient.db;
    final filtro = status != null ? {'status': status} : null;

    final ferramentas = await db
        .collection('ferramentas')
        .find(filtro ?? const {})
        .toList();
    final instrumentos = await db
        .collection('instrumentos')
        .find(filtro ?? const {})
        .toList();

    return [
      ...ferramentas.map(
        (doc) => encodeDocument({...doc, 'tipo': 'ferramenta'}),
      ),
      ...instrumentos.map(
        (doc) => encodeDocument({...doc, 'tipo': 'instrumento'}),
      ),
    ];
  }

  Future<Map<String, dynamic>> criar({
    required String tipo,
    required Map<String, dynamic> payload,
  }) async {
    final col = _collectionFor(tipo);
    final doc = {...payload, 'criadoEm': DateTime.now().toUtc()};

    await col.insert(doc);
    return encodeDocument({...doc, 'tipo': tipo});
  }

  Future<bool> atualizar({
    required String tipo,
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    final col = _collectionFor(tipo);
    final objectId = ObjectId.parse(id);
    final update = {
      r'$set': {...payload, 'atualizadoEm': DateTime.now().toUtc()},
    };

    final result = await col.updateOne(where.id(objectId), update);

    return result.isSuccess;
  }
}
