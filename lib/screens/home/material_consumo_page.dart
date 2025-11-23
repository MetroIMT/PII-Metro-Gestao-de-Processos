import 'package:flutter/material.dart';
import 'estoque_page.dart'; // Reutiliza a estrutura da página de estoque e o modelo de dados
import '../../services/material_service.dart';

class MaterialConsumoPage extends StatefulWidget {
  const MaterialConsumoPage({super.key});

  @override
  State<MaterialConsumoPage> createState() => _MaterialConsumoPageState();
}

class _MaterialConsumoPageState extends State<MaterialConsumoPage> {
  final MaterialService _service = MaterialService();
  List<EstoqueMaterial>? _materiais;
  bool _isLoading = true;

  // Dados mockados para fallback
  final List<EstoqueMaterial> _mockMateriais = [
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getByTipo('consumo');
      if (mounted) {
        setState(() {
          _materiais = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Em caso de erro, usa dados mockados
          _materiais = _mockMateriais;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return EstoquePage(
      title: 'Material de Consumo',
      materiais: _materiais!,
      tipo: 'consumo',
      withSidebar: true,
      sidebarSelectedIndex: 2,
      showBackButton: true,
    );
  }
}
