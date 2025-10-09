import 'dart:io';

import 'package:bcrypt/bcrypt.dart';

void main(List<String> args) {
  final senha = args.isNotEmpty ? args.first : 'admin123';

  final hash = BCrypt.hashpw(senha, BCrypt.gensalt());
  stdout.writeln('{');
  stdout.writeln('  "senha": "$senha",');
  stdout.writeln('  "hash": "$hash"');
  stdout.writeln('}');
}
