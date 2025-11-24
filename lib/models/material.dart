// lib/models/material.dart

import 'package:flutter/material.dart';

class EstoqueMaterial {
  final String codigo;
  final String nome;
  final int quantidade;
  final String local;
  final String? tipo; // 'consumo', 'giro', 'instrumento'
  
  // Requisitos Comuns/Estoque (Consumo/Giro)
  final DateTime? vencimento; // Data de validade (para Consumo/Giro)
  final String? patrimonio; // Código de patrimônio (para rastreabilidade/Instrumentos)
  final int? estoqueMinimo; // Alerta de estoque mínimo
  
  // Requisitos de Instrumento Técnico
  final DateTime? dataCalibracao; // Validade da Calibração
  final String? status; // 'disponível', 'em uso', 'em campo'
  
  EstoqueMaterial({
    required this.codigo,
    required this.nome,
    required this.quantidade,
    required this.local,
    this.tipo,
    this.vencimento,
    this.patrimonio,
    this.estoqueMinimo,
    this.dataCalibracao,
    this.status,
  });

  bool get isVencidoOuCalibracaoExpirada {
    final now = DateTime.now();
    
    final vencido = vencimento != null && vencimento!.isBefore(now);
    final calibracaoExpirada = (tipo == 'instrumento' || dataCalibracao != null) &&
        dataCalibracao != null &&
        dataCalibracao!.isBefore(now);

    return vencido || calibracaoExpirada;
  }
  
  factory EstoqueMaterial.fromJson(Map<String, dynamic> json) {
    DateTime? venc;
    if (json.containsKey('vencimento') && json['vencimento'] != null) {
        venc = DateTime.tryParse(json['vencimento'].toString());
    }
    
    DateTime? calib;
    if (json.containsKey('dataCalibracao') && json['dataCalibracao'] != null) {
        calib = DateTime.tryParse(json['dataCalibracao'].toString());
    }
    
    // Converte quantidade para int de forma segura
    final rawQuantidade = json['quantidade'];
    final quantidade = (rawQuantidade is int)
        ? rawQuantidade as int
        : int.tryParse(rawQuantidade?.toString() ?? '0') ?? 0;

    // Converte estoqueMinimo para int de forma segura
    final rawEstoqueMinimo = json['estoqueMinimo'];
    final estoqueMinimo = (rawEstoqueMinimo is int)
        ? rawEstoqueMinimo as int
        : int.tryParse(rawEstoqueMinimo?.toString() ?? '0');

    return EstoqueMaterial(
      codigo: json['codigo']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      quantidade: quantidade,
      local: json['local']?.toString() ?? '',
      vencimento: venc,
      tipo: json['tipo']?.toString(),
      patrimonio: json['patrimonio']?.toString(),
      estoqueMinimo: estoqueMinimo,
      dataCalibracao: calib,
      status: json['status']?.toString(),
    );
  }
}