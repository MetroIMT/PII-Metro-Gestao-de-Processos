import 'package:flutter/material.dart';

class Movimentacao {
  final String descricao;
  final IconData icon;
  final DateTime timestamp;

  Movimentacao({
    required this.descricao,
    required this.icon,
    required this.timestamp,
  });
}