import 'dart:async';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf_io.dart';

import 'package:api_dart/config.dart';
import 'package:api_dart/server.dart';

Future<void> main(List<String> args) async {
  DotEnv(includePlatformEnvironment: true).load(['.env']);
  await AppConfig.load();

  _setupLogging();

  final handler = await buildHandler();
  final server = await serve(handler, InternetAddress.anyIPv4, AppConfig.port);

  print('🟢 Shelf rodando em http://${server.address.host}:${server.port}');
}

void _setupLogging() {
  Logger.root
    ..level = Level.INFO
    ..onRecord.listen((rec) {
      // ignore: avoid_print
      print('${rec.level.name}: ${rec.time}: ${rec.message}');
    });
}
