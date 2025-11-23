import 'package:flutter/material.dart';
import 'estoque_page.dart'; // Reutiliza a estrutura da página de estoque
import '../../models/material.dart'; // MUDANÇA: Importa o modelo EstoqueMaterial centralizado
import '../../services/material_service.dart';

class MaterialConsumoPage extends StatefulWidget {
  const MaterialConsumoPage({super.key});

  @override
  State<MaterialConsumoPage> createState() => _MaterialConsumoPageState();
}

class _MaterialConsumoPageState extends State<MaterialConsumoPage> {
  final MaterialService _service = MaterialService();
  // Agora EstoqueMaterial está corretamente tipado pelo import acima.
  List<EstoqueMaterial>? _materiais;
  String? _error;
  
  // Define o tipo para evitar erros de digitação
  static const String _materialType = 'consumo';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Usa o tipo 'consumo'
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
      title: 'Material de Consumo',
      materiais: _materiais!,
      tipo: _materialType, // Passa o tipo para a EstoquePage
      withSidebar: true,
      sidebarSelectedIndex: 2,
      showBackButton: true,
    );
  }
}