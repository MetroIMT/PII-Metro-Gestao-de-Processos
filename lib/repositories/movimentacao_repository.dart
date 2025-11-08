import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/movimentacao.dart';

class MovimentacaoRepository {
  // Singleton pattern
  MovimentacaoRepository._privateConstructor() {
    _addInitialData();
  }
  static final MovimentacaoRepository instance =
      MovimentacaoRepository._privateConstructor();

  final ValueNotifier<List<Movimentacao>> movimentacoesNotifier =
      ValueNotifier<List<Movimentacao>>([]);

  final int _limiteMovimentacoesDashboard = 5;
  final Uuid _uuid = const Uuid();

  void _addInitialData() {
    final now = DateTime.now();
    final initialData = [
      Movimentacao(
        id: _uuid.v4(),
        codigoMaterial: 'G001',
        descricao: 'Rolamento 6203',
        quantidade: 10,
        tipo: 'Saída',
        timestamp: now.subtract(const Duration(minutes: 15)),
        usuario: 'João Silva',
        local: 'Oficina A',
      ),
      Movimentacao(
        id: _uuid.v4(),
        codigoMaterial: 'C002',
        descricao: 'Graxa de Lítio',
        quantidade: 5,
        tipo: 'Entrada',
        timestamp: now.subtract(const Duration(hours: 1)),
        usuario: 'Maria Souza',
        local: 'Almoxarifado B',
      ),
      Movimentacao(
        id: _uuid.v4(),
        codigoMaterial: 'P001',
        descricao: 'Furadeira de Impacto Bosch',
        quantidade: 1,
        tipo: 'Saída',
        timestamp: now.subtract(const Duration(hours: 3)),
        usuario: 'Carlos Lima',
        local: 'Ferramentaria',
      ),
      Movimentacao(
        id: _uuid.v4(),
        codigoMaterial: 'G004',
        descricao: 'Selo Mecânico 1.5"',
        quantidade: 2,
        tipo: 'Saída',
        timestamp: now.subtract(const Duration(days: 1)),
        usuario: 'João Silva',
        local: 'Oficina Mecânica',
      ),
      Movimentacao(
        id: _uuid.v4(),
        codigoMaterial: 'C001',
        descricao: 'Óleo Lubrificante XPTO',
        quantidade: 20,
        tipo: 'Entrada',
        timestamp: now.subtract(const Duration(days: 2)),
        usuario: 'Ana Pereira',
        local: 'Oficina 1',
      ),
      Movimentacao(
        id: _uuid.v4(),
        codigoMaterial: 'G002',
        descricao: 'Correia em V AX-45',
        quantidade: 5,
        tipo: 'Saída',
        timestamp: now.subtract(const Duration(days: 3)),
        usuario: 'Maria Souza',
        local: 'Almoxarifado B',
      ),
    ];
    movimentacoesNotifier.value = initialData;
  }

  void addMovimentacao({
    required String codigoMaterial,
    required String descricao,
    required int quantidade,
    required String tipo,
    required String usuario,
    required String local,
  }) {
    final novaMovimentacao = Movimentacao(
      id: _uuid.v4(),
      codigoMaterial: codigoMaterial,
      descricao: descricao,
      quantidade: quantidade,
      tipo: tipo,
      timestamp: DateTime.now(),
      usuario: usuario,
      local: local,
    );

    final listaAtual = List<Movimentacao>.from(movimentacoesNotifier.value);
    listaAtual.insert(0, novaMovimentacao);
    movimentacoesNotifier.value = listaAtual;
  }

  List<Movimentacao> getMovimentacoes() {
    return List<Movimentacao>.from(movimentacoesNotifier.value);
  }

  List<Movimentacao> getMovimentacoesParaDashboard() {
    final all = getMovimentacoes();
    return all.take(_limiteMovimentacoesDashboard).toList();
  }

  void clear() {
    movimentacoesNotifier.value = [];
  }

  int get count => movimentacoesNotifier.value.length;

  bool get isEmpty => movimentacoesNotifier.value.isEmpty;
}
