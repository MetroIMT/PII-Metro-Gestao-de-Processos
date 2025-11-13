import 'package:flutter/material.dart';

enum AlertType { lowStock, nearExpiry, calibration }

class AlertItem {
  final String codigo;
  final String nome;
  final int quantidade;
  final String local;
  final DateTime? vencimento;
  final AlertType type;
  final int severity;

  AlertItem({
    required this.codigo,
    required this.nome,
    required this.quantidade,
    required this.local,
    this.vencimento,
    required this.type,
    required this.severity,
  });
}

class AlertRepository {
  AlertRepository._internal() {
    _items = [
      AlertItem(
        codigo: 'M003',
        nome: 'Conduíte Flexível 20mm',
        quantidade: 0,
        local: 'Base A',
        vencimento: null,
        type: AlertType.lowStock,
        severity: 3,
      ),
      AlertItem(
        codigo: 'M005',
        nome: 'Fusível 10A',
        quantidade: 0,
        local: 'Base B',
        vencimento: DateTime.now().add(const Duration(days: 10)),
        type: AlertType.nearExpiry,
        severity: 3,
      ),
      AlertItem(
        codigo: 'M008',
        nome: 'Chave Seccionadora',
        quantidade: 5,
        local: 'Base C',
        vencimento: DateTime.now().add(const Duration(days: 40)),
        type: AlertType.nearExpiry,
        severity: 2,
      ),
      AlertItem(
        codigo: 'M002',
        nome: 'Disjuntor 20A',
        quantidade: 45,
        local: 'Base B',
        vencimento: null,
        type: AlertType.lowStock,
        severity: 1,
      ),
      AlertItem(
        codigo: 'M007',
        nome: 'Relé de Proteção',
        quantidade: 18,
        local: 'Base A',
        vencimento: DateTime.now().add(const Duration(days: 5)),
        type: AlertType.nearExpiry,
        severity: 3,
      ),
    ];
    countNotifier = ValueNotifier<int>(_items.length);
  }

  static final AlertRepository instance = AlertRepository._internal();

  late List<AlertItem> _items;
  late ValueNotifier<int> countNotifier;

  List<AlertItem> get items => _items;

  void remove(AlertItem a) {
    _items.remove(a);
    countNotifier.value = _items.length;
  }
}
