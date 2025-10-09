import 'dart:convert';

import 'package:mongo_dart/mongo_dart.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/itens_service.dart';
import '../utils/http.dart';

class ItensRouter {
  ItensRouter(this._service);

  final ItensService _service;

  Router get router {
    final router = Router();

    router.get('/', (Request request) async {
      final tipo = request.requestedUri.queryParameters['tipo'];
      final status = request.requestedUri.queryParameters['status'];

      try {
        final itens = await _service.listar(tipo: tipo, status: status);
        return jsonResponse(200, itens);
      } on ArgumentError catch (err) {
        return jsonResponse(400, {'error': err.message});
      }
    });

    router.post('/', (Request request) async {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final tipo = data['tipo'] as String?;
      if (tipo == null) {
        return jsonResponse(400, {'error': 'Campo tipo é obrigatório'});
      }
      final payload = Map<String, dynamic>.from(data)..remove('tipo');

      try {
        final result = await _service.criar(tipo: tipo, payload: payload);
        return jsonResponse(201, result);
      } on MongoDartError catch (err) {
        return jsonResponse(400, {'error': err.message});
      }
    });

    router.patch('/<id>', (Request request, String id) async {
      final data = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final tipo = data['tipo'] as String?;
      if (tipo == null) {
        return jsonResponse(400, {'error': 'Campo tipo é obrigatório'});
      }
      final payload = Map<String, dynamic>.from(data)..remove('tipo');

      final ok = await _service.atualizar(tipo: tipo, id: id, payload: payload);
      if (!ok) return jsonResponse(404, {'error': 'Item não encontrado'});
      return jsonResponse(200, {'ok': true});
    });

    return router;
  }
}