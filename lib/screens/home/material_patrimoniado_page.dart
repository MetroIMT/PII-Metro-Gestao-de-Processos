import 'package:flutter/material.dart';
import 'estoque_page.dart'; // Reutiliza a estrutura da página de estoque e o modelo de dados

class MaterialPatrimoniadoPage extends StatelessWidget {
  const MaterialPatrimoniadoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados de exemplo para esta categoria.
    final List<EstoqueMaterial> materiaisPatrimoniado = [
      EstoqueMaterial(
        codigo: 'P001',
        nome: 'Furadeira de Impacto Bosch',
        quantidade: 1,
        local: 'Ferramentaria',
      ),
      EstoqueMaterial(
        codigo: 'P002',
        nome: 'Multímetro Digital Fluke',
        quantidade: 1,
        local: 'Laboratório de Eletrônica',
      ),
      EstoqueMaterial(
        codigo: 'P003',
        nome: 'Notebook Dell Vostro',
        quantidade: 0,
        local: 'Sala da Supervisão',
      ),
    ];

    return EstoquePage(
      title: 'Material Patrimoniado',
      materiais: materiaisPatrimoniado,
    );
  }
}
