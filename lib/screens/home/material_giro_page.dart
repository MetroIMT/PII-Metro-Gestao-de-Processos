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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getByTipo('giro');
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
      title: 'Material de Giro',
      materiais: _materiais!,
      tipo: 'giro',
    );
  }
}
