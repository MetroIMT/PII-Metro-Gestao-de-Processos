import 'dart:async';

import 'package:shelf/shelf.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'db/mongo_client.dart';
import 'middleware/auth_middleware.dart';
import 'routes/auth_router.dart';
import 'routes/itens_router.dart';
import 'routes/movimentos_router.dart';
import 'services/auth_service.dart';
import 'services/itens_service.dart';
import 'services/movimentos_service.dart';
import 'utils/http.dart';

Future<Handler> buildHandler() async {
  await MongoClient.connect();

  final router = Router();

  router.get('/health', (Request _) => jsonResponse(200, {'ok': true}));

  final authService = AuthService();
  final itensService = ItensService();
  final movimentosService = MovimentosService();

  router.mount('/auth', AuthRouter(authService).router.call);

  router.mount(
    '/itens',
    Pipeline()
        .addMiddleware(authMiddleware(required: false))
        .addHandler(ItensRouter(itensService).router.call),
  );

  router.mount(
    '/movimentos',
    Pipeline()
        .addMiddleware(authMiddleware())
        .addHandler(MovimentosRouter(movimentosService).router.call),
  );

  return Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router.call);
}
