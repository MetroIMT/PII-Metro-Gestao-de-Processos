import 'package:flutter/material.dart';
import 'estoque_page.dart'; // Reutiliza a estrutura da página de estoque
import '../../models/material.dart'; // MUDANÇA: Importa o modelo centralizado
import '../../services/material_service.dart';

class MaterialPatrimoniadoPage extends StatefulWidget {
  const MaterialPatrimoniadoPage({super.key});

  @override
  State<MaterialPatrimoniadoPage> createState() =>
      _MaterialPatrimoniadoPageState();
}

class _MaterialPatrimoniadoPageState extends State<MaterialPatrimoniadoPage> {
  final MaterialService _service = MaterialService();
  List<EstoqueMaterial>? _materiais;
  // MUDANÇA: Define o tipo como 'instrumento'
  static const String _materialType = 'instrumento';
  bool _isLoading = true;

  // Dados mockados para fallback
  final List<EstoqueMaterial> _mockMateriais = [
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // MUDANÇA: Chama getByTipo com o novo tipo 'instrumento'
      final list = await _service.getByTipo(_materialType);
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
      // MUDANÇA: Atualiza o título para refletir a especialização
      title: 'Materiais patrimoniados', 
      materiais: _materiais!,
      // MUDANÇA: Passa o tipo correto para a EstoquePage
      tipo: _materialType, 
      withSidebar: true,
      sidebarSelectedIndex: 2,
      showBackButton: true,
    );
  }
}