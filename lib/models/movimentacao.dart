import 'package:flutter/material.dart';

class Movimentacao {
  final String id;
  final String codigoMaterial;
  final String descricao;
  final int quantidade;
  final String tipo; // "Entrada" ou "Saída"
  final DateTime timestamp;
  final String usuario;
  final String local;

  Movimentacao({
    required this.id,
    required this.codigoMaterial,
    required this.descricao,
    required this.quantidade,
    required this.tipo,
    required this.timestamp,
    required this.usuario,
    required this.local,
  });

  // Helper para obter o ícone com base no tipo
  IconData get icon {
    return tipo == 'Entrada' ? Icons.arrow_downward : Icons.arrow_upward;
  }

  factory Movimentacao.fromJson(Map<String, dynamic> json) {
    // Tenta diversas chaves possíveis, pois a coleção 'movimentos' pode
    // usar nomes diferentes para os campos dependendo da origem.
    String id = json['_id']?.toString() ?? json['id']?.toString() ?? '';

    String codigo = '';
    if (json.containsKey('codigoMaterial')) codigo = json['codigoMaterial'] ?? '';
    if (codigo.isEmpty && json.containsKey('codigoInterno')) codigo = json['codigoInterno'] ?? '';
    if (codigo.isEmpty && json.containsKey('codigo')) codigo = json['codigo'] ?? '';
    if (codigo.isEmpty && json.containsKey('itemId')) codigo = json['itemId']?.toString() ?? '';

    String descricao = json['descricao'] ?? json['observacao'] ?? '';

    final quantidade = (json['quantidade'] is int)
        ? json['quantidade'] as int
        : int.tryParse(json['quantidade']?.toString() ?? '0') ?? 0;

    String rawTipo = (json['tipo'] ?? json['tipoMovimento'] ?? '').toString();
    String tipo;
    final lower = rawTipo.toLowerCase();
    if (lower.contains('entrada')) {
      tipo = 'Entrada';
    } else if (lower.contains('saida') || lower.contains('saída')) {
      tipo = 'Saída';
    } else if (lower.contains('emprestimo')) {
      tipo = 'Empréstimo';
    } else if (lower.contains('devolucao')) {
      tipo = 'Devolução';
    } else {
      tipo = rawTipo.isNotEmpty ? rawTipo : 'Desconhecido';
    }

    DateTime timestamp = DateTime.now();
    final dateCandidates = ['data', 'dataHora', 'data_hora', 'timestamp', 'createdAt', 'dataHoraMovimento'];
    for (final k in dateCandidates) {
      if (json[k] != null) {
        try {
          timestamp = DateTime.parse(json[k].toString());
          break;
        } catch (_) {
          // ignore parse errors
        }
      }
    }

    String usuario = '';
    if (json['usuario'] != null) usuario = json['usuario'].toString();
    if (usuario.isEmpty && json['usuarioId'] != null) usuario = json['usuarioId'].toString();

    String local = json['local'] ?? json['localizacao'] ?? '';

    return Movimentacao(
      id: id,
      codigoMaterial: codigo,
      descricao: descricao,
      quantidade: quantidade,
      tipo: tipo,
      timestamp: timestamp,
      usuario: usuario.isNotEmpty ? usuario : 'N/A',
      local: local.isNotEmpty ? local : 'N/A',
    );
  }
}
