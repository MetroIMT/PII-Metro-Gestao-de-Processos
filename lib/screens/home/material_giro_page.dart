import 'package:flutter/material.dart';
import 'estoque_page.dart'; // Reutiliza a estrutura da página de estoque e o modelo de dados
import '../../services/material_service.dart';

class MaterialGiroPage extends StatefulWidget {
  const MaterialGiroPage({super.key});

  @override
  State<MaterialGiroPage> createState() => _MaterialGiroPageState();
}

class _MaterialGiroPageState extends State<MaterialGiroPage> {
  final MaterialService _service = MaterialService();
  List<EstoqueMaterial>? _materiais;
  bool _isLoading = true;

  // Dados mockados para fallback
  final List<EstoqueMaterial> _mockMateriais = [
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
    EstoqueMaterial(
      codigo: 'G005',
      nome: 'Óleo Hidráulico',
      quantidade: 10,
      local: 'Oficina Mecânica',
      vencimento: DateTime.now().add(const Duration(days: 15)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getByTipo('giro');
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
      title: 'Material de Giro',
      materiais: _materiais!,
      tipo: 'giro',
      withSidebar: true,
      sidebarSelectedIndex: 2,
      showBackButton: true,
    );
  }
}
