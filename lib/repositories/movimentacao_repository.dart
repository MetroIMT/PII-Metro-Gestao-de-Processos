import 'package:flutter/material.dart';
import '../models/movimentacao.dart';

class MovimentacaoRepository {
  // Singleton pattern
  MovimentacaoRepository._privateConstructor();
  static final MovimentacaoRepository instance = 
      MovimentacaoRepository._privateConstructor();

  final ValueNotifier<List<Movimentacao>> movimentacoesNotifier = 
      ValueNotifier<List<Movimentacao>>([]);

  final int _limiteMovimentacoes = 5;

  // Existing add method
  void addMovimentacao(String descricao, IconData icon) {
    final novaMovimentacao = Movimentacao(
      descricao: descricao,
      icon: icon,
      timestamp: DateTime.now(),
    );

    final listaAtual = List<Movimentacao>.from(movimentacoesNotifier.value);
    listaAtual.insert(0, novaMovimentacao);

    if (listaAtual.length > _limiteMovimentacoes) {
      listaAtual.removeLast();
    }

    movimentacoesNotifier.value = listaAtual;
  }

  // New helper methods
  List<Movimentacao> get movimentacoes => movimentacoesNotifier.value;

  void clear() {
    movimentacoesNotifier.value = [];
  }

  int get count => movimentacoesNotifier.value.length;

  bool get isEmpty => movimentacoesNotifier.value.isEmpty;
}