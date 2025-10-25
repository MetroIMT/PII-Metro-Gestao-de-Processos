import 'package:flutter/material.dart';
import 'estoque_page.dart'; // Reutiliza a estrutura da página de estoque e o modelo de dados

class MaterialGiroPage extends StatelessWidget {
  const MaterialGiroPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dados de exemplo para esta categoria.
    // Em uma aplicação real, estes dados viriam de um serviço ou banco de dados.
    final List<EstoqueMaterial> materiaisGiro = [
      EstoqueMaterial(
        codigo: 'G001',
        nome: 'Rolamento 6203',
        quantidade: 50,
        local: 'Almoxarifado A',
        vencimento: DateTime(2025, 12, 31),
      ),
      EstoqueMaterial(
        codigo: 'G002',
        nome: 'Correia em V AX-45',
        quantidade: 20,
        local: 'Almoxarifado B',
      ),
      EstoqueMaterial(
        codigo: 'G003',
        nome: 'Filtro de Ar Motor X',
        quantidade: 0,
        local: 'Almoxarifado A',
      ),
      EstoqueMaterial(
        codigo: 'G004',
        nome: 'Selo Mecânico 1.5"',
        quantidade: 5,
        local: 'Oficina Mecânica',
      ),
    ];

    return EstoquePage(
      title: 'Material de Giro',
      materiais: materiaisGiro,
    );
  }
}
