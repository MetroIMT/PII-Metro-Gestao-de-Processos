import 'package:flutter_test/flutter_test.dart';

import '../tdd/scenarios/autenticacao_test.dart' as autenticacao;
import '../tdd/scenarios/gestao_usuarios_test.dart' as gestao_usuarios;
import '../tdd/scenarios/gestao_ferramentas_test.dart' as gestao_ferramentas;
import '../tdd/scenarios/gestao_instrumentos_test.dart' as gestao_instrumentos;
import '../tdd/scenarios/movimentacoes_test.dart' as movimentacoes;

void main() {
  group('🧪 BDD Test Suite - Sistema de Gestão Metrô', () {
    autenticacao.main();
    gestao_usuarios.main();
    gestao_ferramentas.main();
    gestao_instrumentos.main();
    movimentacoes.main();
  });
}
