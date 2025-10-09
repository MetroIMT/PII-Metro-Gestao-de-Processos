import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/movimentos_service.dart';
import '../utils/http.dart';

class MovimentosRouter {
  MovimentosRouter(this._service);

  final MovimentosService _service;

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      final itemId = request.requestedUri.queryParameters['itemId'];
      final docs = await _service.listar(itemId: itemId);
      return jsonResponse(200, docs);
    });

    router.post('/', (Request request) async {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final tipo = data['tipo'] as String?;
      final itemTipo = data['itemTipo'] as String?;
      final itemId = data['itemId'] as String?;
      final quantidade = data['quantidade'] ?? 1;
      final observacao = data['observacao'] as String?;

      if (tipo == null || itemTipo == null || itemId == null) {
        return jsonResponse(400, {'error': 'Campos obrigatórios faltando'});
      }

      final user = request.context['user'] as Map<String, dynamic>;
      final usuarioId = user['sub'] as String;

      await _service.registrar(
        tipo: tipo,
        itemTipo: itemTipo,
        itemId: itemId,
        usuarioId: usuarioId,
        quantidade: num.parse(quantidade.toString()),
        observacao: observacao,
      );

      return jsonResponse(201, {'ok': true});
    });

    return router;
  }
}