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
  String? _error;
  // MUDANÇA: Define o tipo como 'instrumento'
  static const String _materialType = 'instrumento';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // MUDANÇA: Chama getByTipo com o novo tipo 'instrumento'
      final list = await _service.getByTipo(_materialType);
      setState(() => _materiais = list);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Erro: $_error'));
    }

    if (_materiais == null) {
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