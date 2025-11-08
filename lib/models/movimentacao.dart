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
}
