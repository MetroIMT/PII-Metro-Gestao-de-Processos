import 'package:mongo_dart/mongo_dart.dart';

import '../db/mongo_client.dart';
import '../utils/mongo_utils.dart';

class MovimentosService {
  DbCollection get _movimentos => MongoClient.db.collection('movimentos');

  DbCollection _collectionFor(String tipo) {
    switch (tipo) {
      case 'instrumento':
        return MongoClient.db.collection('instrumentos');
      case 'ferramenta':
        return MongoClient.db.collection('ferramentas');
      default:
        throw ArgumentError('itemTipo inválido');
    }
  }

  Future<List<Map<String, dynamic>>> listar({String? itemId}) async {
    final filtro = <String, dynamic>{};
    if (itemId != null) {
      filtro['itemId'] = ObjectId.parse(itemId);
    }

    final docs = await _movimentos.find(filtro).toList();

    // Ordena por dataHora em ordem decrescente após buscar
    docs.sort((a, b) {
      final dateA =
          a['dataHora'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB =
          b['dataHora'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    // Limita a 200 resultados
    final limitedDocs = docs.take(200).toList();

    return limitedDocs.map(encodeDocument).toList();
  }

  Future<void> registrar({
    required String tipo,
    required String itemTipo,
    required String itemId,
    required String usuarioId,
    required num quantidade,
    String? observacao,
  }) async {
    final itemCollection = _collectionFor(itemTipo);
    final itemObjectId = ObjectId.parse(itemId);

    await MongoClient.withTransaction<void>((db) async {
      final movimentoDoc = {
        'tipo': tipo,
        'itemTipo': itemTipo,
        'itemId': itemObjectId,
        'quantidade': quantidade,
        'usuarioId': ObjectId.parse(usuarioId),
        'observacao': observacao,
        'dataHora': DateTime.now().toUtc(),
      };

      await _movimentos.insertOne(movimentoDoc);

      final inc = (tipo == 'entrada' || tipo == 'devolucao')
          ? quantidade
          : -quantidade;
      final updateSet = <String, dynamic>{
        'atualizadoEm': DateTime.now().toUtc(),
      };

      if (tipo == 'emprestimo') {
        updateSet['status'] = 'emprestada';
      } else if (tipo == 'devolucao') {
        updateSet['status'] = 'disponivel';
      }

      final update = <String, dynamic>{
        r'$inc': {'quantidade': inc},
        r'$set': updateSet,
      };

      final result = await itemCollection.updateOne(
        where.id(itemObjectId),
        update,
      );

      if (!result.isSuccess) {
        throw StateError('Item não encontrado ou não atualizado.');
      }
    });
  }
}
