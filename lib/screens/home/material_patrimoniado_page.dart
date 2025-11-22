import 'package:flutter/material.dart';
import 'estoque_page.dart'; // Reutiliza a estrutura da página de estoque e o modelo de dados
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getByTipo('patrimoniado');
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
      title: 'Material Patrimoniado',
      materiais: _materiais!,
      tipo: 'patrimoniado',
      withSidebar: true,
      sidebarSelectedIndex: 2,
      showBackButton: true,
    );
  }
}
