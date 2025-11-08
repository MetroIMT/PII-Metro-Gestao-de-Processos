// lib/pages/estoque/estoque_page.dart (ou onde o seu estiver)

import 'package:flutter/material.dart';
// NOVO: Importar o repositório que acabamos de criar
import '../../repositories/movimentacao_repository.dart';
import '../../services/material_service.dart';
import '../../widgets/sidebar.dart';

class EstoqueMaterial {
  final String codigo;
  // ... (resto da sua classe EstoqueMaterial sem alterações)
  final String nome;
  final int quantidade;
  final String local;
  final DateTime? vencimento;

  EstoqueMaterial({
    required this.codigo,
    required this.nome,
    required this.quantidade,
    required this.local,
    this.vencimento,
  });

  String get status => quantidade > 0 ? 'Disponível' : 'Em Falta';
}

class EstoquePage extends StatefulWidget {
  // ... (resto do seu EstoquePage e _EstoquePageState sem alterações)
  final String title;
  final List<EstoqueMaterial> materiais;
  // opcional: tipo que será usado ao criar um material (ex: 'giro','consumo','patrimoniado')
  final String? tipo;
  // Se true, a página renderiza a Sidebar (desktop rail + drawer on mobile)
  final bool withSidebar;
  // índice selecionado no sidebar (por padrão 1 = Estoque)
  final int sidebarSelectedIndex;

  const EstoquePage({
    super.key,
    this.title = 'Estoque',
    required this.materiais,
    this.tipo,
    this.withSidebar = false,
    this.sidebarSelectedIndex = 1,
  });

  @override
  State<EstoquePage> createState() => _EstoquePageState();
}

class _EstoquePageState extends State<EstoquePage>
    with SingleTickerProviderStateMixin {
  // --- Sidebar / layout state (used only when widget.withSidebar == true)
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<EstoqueMaterial> _materiais;
  final MaterialService _materialService = MaterialService();

  @override
  void initState() {
    super.initState();
    _materiais = List.from(widget.materiais);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  List<EstoqueMaterial> get _filteredMateriais {
    // ... (sem alterações)
    if (_searchQuery.isEmpty) {
      return _materiais;
    }

    return _materiais.where((material) {
      return material.codigo.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          material.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          material.local.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleRail() {
    setState(() {
      _isRailExtended = !_isRailExtended;
      if (_isRailExtended) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Widget _buildInfoRow(String label, String value) {
    // ... (sem alterações)
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(DateTime? d) {
    // ... (sem alterações)
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  // Método para mostrar o diálogo de adicionar material
  void _showAddMaterialDialog(BuildContext context) {
    // ... (controllers e decorações sem alterações)
    final codigoController = TextEditingController();
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    final localController = TextEditingController();
    DateTime? selectedVencimento;
    final vencimentoController = TextEditingController();

    final primaryColor = const Color(0xFF253250);
    final secondaryColor = Colors.blue.shade700;

    InputDecoration inputDecoration(String label, String hint, IconData icon) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: primaryColor),
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        // ... (layout do diálogo sem alterações)
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                // ... (sem alterações)
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_box_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Material',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Preencha os dados do novo material',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Form fields
              TextField(
                // ... (sem alterações)
                controller: codigoController,
                decoration: inputDecoration(
                  'Código',
                  'Ex: M001',
                  Icons.qr_code,
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              TextField(
                // ... (sem alterações)
                controller: nomeController,
                decoration: inputDecoration(
                  'Nome',
                  'Ex: Cabo Elétrico',
                  Icons.inventory,
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              TextField(
                // ... (sem alterações)
                controller: quantidadeController,
                decoration: inputDecoration(
                  'Quantidade',
                  'Ex: 150',
                  Icons.production_quantity_limits,
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              TextField(
                // ... (sem alterações)
                controller: localController,
                decoration: inputDecoration(
                  'Local',
                  'Ex: Base A',
                  Icons.location_on,
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              // Campo opcional de vencimento (abre date picker)
              TextField(
                // ... (sem alterações)
                controller: vencimentoController,
                readOnly: true,
                decoration: inputDecoration(
                  'Vencimento (opcional)',
                  'Selecione uma data',
                  Icons.calendar_today,
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedVencimento ?? now,
                    firstDate: DateTime(now.year - 5),
                    lastDate: DateTime(now.year + 10),
                  );
                  if (picked != null) {
                    selectedVencimento = picked;
                    vencimentoController.text = _formatDate(picked);
                    setState(() {}); // para atualizar se necessário
                  }
                },
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    // ... (botão cancelar sem alterações)
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      // Validar entradas
                      if (codigoController.text.isEmpty ||
                          nomeController.text.isEmpty ||
                          quantidadeController.text.isEmpty ||
                          localController.text.isEmpty) {
                        // ... (lógica de erro sem alterações)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preencha todos os campos'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Tentar converter quantidade para número
                      int quantidade;
                      try {
                        quantidade = int.parse(quantidadeController.text);
                      } catch (e) {
                        // ... (lógica de erro sem alterações)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quantidade deve ser um número'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      // Chamar a API para criar o material (usa widget.tipo se fornecido)
                      // Mostra indicador de progresso modal enquanto aguarda
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      try {
                        final created = await _materialService.create(
                          codigo: codigoController.text,
                          nome: nomeController.text,
                          quantidade: quantidade,
                          local: localController.text,
                          vencimento: selectedVencimento,
                          tipo: widget.tipo,
                        );

                        setState(() {
                          _materiais.add(created);
                        });

                        MovimentacaoRepository.instance.addMovimentacao(
                          codigoMaterial: created.codigo,
                          descricao: "Adicionado: ${created.nome}",
                          quantidade: created.quantidade,
                          tipo: 'adicao',
                          usuario: 'Sistema',
                          local: created.local,
                        );

                        // Fechar indicador de progresso e diálogo de formulário
                        Navigator.of(
                          context,
                        ).pop(); // fecha o CircularProgressIndicator
                        Navigator.of(
                          context,
                        ).pop(); // fecha o diálogo de adicionar

                        // Mostrar confirmação
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Material ${created.nome} adicionado com sucesso',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      } catch (e) {
                        // Fechar indicador de progresso se aberto
                        try {
                          Navigator.of(context).pop();
                        } catch (_) {}

                        // Mostrar erro
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao criar material: $e'),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    },
                    child: Row(
                      // ... (botão adicionar sem alterações)
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text(
                          'Adicionar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... (O resto do seu método build continua aqui, sem alterações)
    // Eu adicionei a lógica no `onPressed` do botão "Adicionar"
    // dentro do diálogo `_showAddMaterialDialog`.

    // Você deve fazer o mesmo para "Editar" e "Movimentar":
    // 1. Encontre o onPressed do botão "Editar" (na linha 600 ou 759)
    //    e adicione:
    //    MovimentacaoRepository.instance.addMovimentacao("Editado: ${material.nome}", Icons.edit);
    //
    // 2. Encontre o onPressed do botão "Movimentar" (na linha 616 ou 776)
    //    e adicione:
    //    MovimentacaoRepository.instance.addMovimentacao("Retirado: ${material.nome}", Icons.remove_circle);
    //    (ou adicione um diálogo que pergunta a quantidade e decide o ícone)

    final metroBlue = const Color(0xFF001489);

    // Original body (extracted so we can reuse it with or without sidebar)
    Widget bodyContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar material...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // Implementar filtragem avançada
                  },
                ),
              ],
            ),
          ),

          // Informações de contagem e estatísticas
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Itens no estoque: ${_filteredMateriais.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Disponíveis: ${_materiais.where((m) => m.quantidade > 0).length}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Em falta: ${_materiais.where((m) => m.quantidade <= 0).length}',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabela de materiais - Versão responsiva
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Decidir qual layout usar baseado no tamanho da tela
                final isMobile = constraints.maxWidth < 600;

                if (isMobile) {
                  // Layout de cards para mobile
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredMateriais.length,
                    itemBuilder: (context, index) {
                      final material = _filteredMateriais[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            title: Row(
                              children: [
                                // Ícone baseado na quantidade
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: material.quantidade > 0
                                        ? Colors.green.withAlpha(
                                            (0.1 * 255).round(),
                                          )
                                        : Colors.red.withAlpha(
                                            (0.1 * 255).round(),
                                          ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    material.quantidade > 0
                                        ? Icons.inventory_2
                                        : Icons.warning_amber,
                                    color: material.quantidade > 0
                                        ? Colors.green
                                        : Colors.red,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Informações principais
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        material.nome,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Código: ${material.codigo}',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: material.quantidade > 0
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    material.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Detalhes quando expandido
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                child: Column(
                                  children: [
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      'Quantidade:',
                                      material.quantidade.toString(),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow('Local:', material.local),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      'Vencimento:',
                                      _formatDate(material.vencimento),
                                    ),
                                    const SizedBox(height: 12),
                                    // Botões de ação
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                          label: const Text('Editar'),
                                          onPressed: () {
                                            // Implementar edição de material
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.swap_vert,
                                            size: 18,
                                          ),
                                          label: const Text('Movimentar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF253250,
                                            ),
                                          ),
                                          onPressed: () {
                                            // Implementar movimentação de material
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  // Layout de tabela para desktop - Responsivo
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withAlpha((0.1 * 255).round()),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    width: double.infinity,
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.grey.shade200),
                      // Horizontal scroll externo (mantido) + scroll vertical interno (adicionado)
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: SingleChildScrollView(
                            // Adiciona rolagem vertical para permitir "rodar para baixo"
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              headingRowColor:
                                  MaterialStateProperty.resolveWith<Color?>(
                                    (Set<MaterialState> states) =>
                                        const Color(0xFFF5F7FA),
                                  ),
                              dataRowColor:
                                  MaterialStateProperty.resolveWith<Color?>((
                                    Set<MaterialState> states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return Colors.blue.withAlpha(
                                        (0.1 * 255).round(),
                                      );
                                    }
                                    return Colors.white;
                                  }),
                              columnSpacing: 24,
                              horizontalMargin: 24,
                              dataRowMinHeight: 64,
                              dataRowMaxHeight: 64,
                              headingRowHeight: 60,
                              showCheckboxColumn: false,
                              dividerThickness: 1,
                              columns: [
                                const DataColumn(
                                  label: Expanded(
                                    child: Text(
                                      'Código',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Nome',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Cabeçalho centralizado para a coluna Quantidade
                                DataColumn(
                                  label: SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        'Quantidade',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  numeric: true,
                                ),
                                const DataColumn(
                                  label: Expanded(
                                    child: Text(
                                      'Local',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                // Nova coluna de Vencimento (opcional)
                                DataColumn(
                                  label: SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        'Vencimento',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const DataColumn(
                                  label: Expanded(
                                    child: Text(
                                      'Status',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const DataColumn(
                                  label: Expanded(
                                    child: Text(
                                      'Ações',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              rows: _filteredMateriais.map((material) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        material.codigo,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        material.nome,
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ),
                                    // Célula centralizada para a quantidade
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Center(
                                          child: Text(
                                            material.quantidade.toString(),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: material.quantidade > 0
                                                  ? Colors.black
                                                  : Colors.red,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(material.local)),
                                    // Célula de vencimento (formatação ou '-')
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Center(
                                          child: Text(
                                            _formatDate(material.vencimento),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: material.vencimento == null
                                                  ? Colors.grey
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: material.quantidade > 0
                                              ? Colors.green
                                              : Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          material.status,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 20,
                                            ),
                                            color: Colors.blue,
                                            tooltip: "Editar",
                                            onPressed: () {
                                              // Implementar edição
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.swap_vert,
                                              size: 20,
                                            ),
                                            color: const Color(0xFF253250),
                                            tooltip: "Movimentar",
                                            onPressed: () {
                                              // Implementar movimentação
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelectChanged: (selected) {
                                    if (selected == true) {
                                      // Implementar ação ao selecionar linha
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
          ),

          // Botão para adicionar material
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Adicionar material'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: metroBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  _showAddMaterialDialog(context);
                },
              ),
            ),
          ),
        ],
      ),
    );

    // If the caller doesn't want the sidebar, return the original scaffold
    if (!widget.withSidebar) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2D3748),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Image.asset('assets/LogoMetro.png', height: 32),
            ),
          ],
        ),
        body: bodyContent,
      );
    }

    // Otherwise, build a layout that includes the Sidebar (responsive)
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: isMobile
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _animationController,
                  color: metroBlue,
                ),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                widget.title,
                style: TextStyle(fontWeight: FontWeight.bold, color: metroBlue),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Image.asset('assets/LogoMetro.png', height: 32),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                expanded: true,
                selectedIndex: widget.sidebarSelectedIndex,
              ),
            )
          : null,
      body: Stack(
        children: [
          if (!isMobile)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              top: 0,
              bottom: 0,
              width: _isRailExtended ? 180 : 70,
              child: Sidebar(
                expanded: _isRailExtended,
                selectedIndex: widget.sidebarSelectedIndex,
              ),
            ),

          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isRailExtended ? Icons.menu_open : Icons.menu,
                                color: metroBlue,
                              ),
                              onPressed: _toggleRail,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001489),
                              ),
                            ),
                          ],
                        ),
                        Image.asset('assets/LogoMetro.png', height: 40),
                      ],
                    ),
                  ),

                // Conteúdo principal (o body original)
                Expanded(child: bodyContent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
