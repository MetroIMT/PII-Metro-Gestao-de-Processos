import 'dart:io';

import 'package:dotenv/dotenv.dart';

class AppConfig {
  static late final DotEnv _env;

  static Future<void> load() async {
    final env = DotEnv(includePlatformEnvironment: true);
    final envFile = File('.env');
    if (envFile.existsSync()) {
      env.load(['.env']);
    } else {
      env.load([]);
    }
    _env = env;

    if (mongoUri.isEmpty || jwtSecret.isEmpty) {
      throw StateError('Defina MONGODB_URI e JWT_SECRET no arquivo .env');
    }
  }

  static int get port => int.parse(_env['PORT'] ?? '8081');

  static String get mongoUri => _env['MONGODB_URI'] ?? '';

  static String get dbName =>
      _env['MONGODB_DB'] ?? 'gestao-de-processos-metro';

  static String get jwtSecret => _env['JWT_SECRET'] ?? '';

  static int get bcryptRounds => int.parse(_env['BCRYPT_ROUNDS'] ?? '10');
}