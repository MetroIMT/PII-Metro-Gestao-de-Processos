import 'package:flutter/material.dart';
import 'estoque_page.dart'; // Reutiliza a estrutura da página de estoque e o modelo de dados

class MaterialConsumoPage extends StatelessWidget {
  const MaterialConsumoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados de exemplo para esta categoria.
    final List<EstoqueMaterial> materiaisConsumo = [
      EstoqueMaterial(
        codigo: 'C001',
        nome: 'Óleo Lubrificante XPTO',
        quantidade: 15,
        local: 'Oficina 1',
      ),
      EstoqueMaterial(
        codigo: 'C002',
        nome: 'Graxa de Lítio',
        quantidade: 5,
        local: 'Oficina 2',
        vencimento: DateTime(2024, 8, 1),
      ),
      EstoqueMaterial(
        codigo: 'C003',
        nome: 'Estopa (pacote)',
        quantidade: 100,
        local: 'Oficina 1',
      ),
      EstoqueMaterial(
        codigo: 'C004',
        nome: 'Lixa para Ferro',
        quantidade: 0,
        local: 'Almoxarifado C',
      ),
    ];

    return EstoquePage(
      title: 'Material de Consumo',
      materiais: materiaisConsumo,
    );
  }
}
