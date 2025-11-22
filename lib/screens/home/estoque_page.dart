// lib/pages/estoque/estoque_page.dart (ou onde o seu estiver)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import para formatadores
// NOVO: Importar o repositório que acabamos de criar
// import '../../repositories/movimentacao_repository.dart';
import '../../services/material_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/sidebar.dart';
import 'package:intl/intl.dart'; // Import para formatar data

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
  // Se true, mostra o botão de voltar ao lado do menu
  final bool showBackButton;

  const EstoquePage({
    super.key,
    this.title = 'Estoque',
    required this.materiais,
    this.tipo,
    this.withSidebar = false,
    this.sidebarSelectedIndex = 1,
    this.showBackButton = false,
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
  final AuthService _authService = AuthService();

  // --- NOVAS VARIÁVEIS DE ESTADO E HELPERS ---
  final Color metroBlue = const Color(0xFF001489);
  final Set<String> _processingIds = <String>{};

  // --- MUDANÇA: LISTA DE BASES COMPARTILHADA ---
  final List<Map<String, String>> _listaDeBases = [
    {'value': 'WJA', 'label': 'WJA - Jabaquara'},
    {'value': 'PSO', 'label': 'PSO - Paraiso'},
    {'value': 'TRD', 'label': 'TRD - Tiradentes'},
    {'value': 'TUC', 'label': 'TUC - Tucuruvi'},
    {'value': 'LUM', 'label': 'LUM - Luminárias'},
    {'value': 'IMG', 'label': 'IMG - Imigrantes'},
    {'value': 'BFU', 'label': 'BFU - Barra Funda'},
    {'value': 'BAS', 'label': 'BAS - Brás'},
    {'value': 'CEC', 'label': 'CEC - Cecília'},
    {'value': 'MAT', 'label': 'MAT - Matheus'},
    {'value': 'VTD', 'label': 'VTD - Vila Matilde'},
    {'value': 'VPT', 'label': 'VPT - Vila Prudente'},
    {'value': 'PIT', 'label': 'PIT - Pátio Itaquera'},
    {'value': 'POT', 'label': 'POT - Pátio Oratório'},
    {'value': 'PAT', 'label': 'PAT - Pátio Jabaquara'},
  ];

  // Helper para o Input Style (copiado de gerenciar_usuarios)
  InputDecoration _buildDialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54), // Texto "preto"
      filled: true,
      fillColor: Colors.grey.shade100, // Fundo "cinza"
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: metroBlue, width: 2), // Borda "metroBlue"
      ),
    );
  }

  // --- MUDANÇA: HELPER PARA CAMPO NÃO-EDITÁVEL ---
  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- FIM DOS NOVOS HELPERS ---

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
    if (d == null) return '-';
    // Usando DateFormat para garantir o formato
    return DateFormat('dd/MM/yyyy').format(d);
  }

  // --- DIÁLOGO DE ADICIONAR (COM DROPDOWN DE LOCAL) ---
  void _showAddMaterialDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController();
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    // final localController = TextEditingController(); // REMOVIDO
    String? selectedLocal; // NOVO
    DateTime? selectedVencimento;
    final vencimentoController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;
        final double dialogWidth = MediaQuery.of(dialogContext).size.width > 550
            ? 500.0 // Largura fixa
            : MediaQuery.of(dialogContext).size.width * 0.95; // 95% para mobile

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            title: Row(
              children: [
                Icon(Icons.add_box_rounded, color: metroBlue, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Adicionar Material',
                  style: TextStyle(
                    color: metroBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            content: SizedBox(
              width: dialogWidth,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codigoController,
                        decoration: _buildDialogInputDecoration('Código *'),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Informe o código'
                            : null,
                      ),
                      const SizedBox(height: 16), // AUMENTADO
                      TextFormField(
                        controller: nomeController,
                        decoration: _buildDialogInputDecoration('Nome *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16), // AUMENTADO
                      TextFormField(
                        controller: quantidadeController,
                        decoration: _buildDialogInputDecoration(
                          'Quantidade Inicial *',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Informe a quantidade'
                            : null,
                      ),
                      const SizedBox(height: 16), // AUMENTADO
                      // --- MUDANÇA: CAMPO DE LOCAL (DROPDOWN) ---
                      DropdownButtonFormField<String>(
                        value: selectedLocal,
                        items: _listaDeBases.map((base) {
                          return DropdownMenuItem(
                            value: base['value'],
                            child: Text(base['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedLocal = value;
                          });
                        },
                        decoration: _buildDialogInputDecoration('Local *'),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Selecione um local'
                            : null,
                        dropdownColor: Colors.white,
                      ),

                      // --- FIM DA MUDANÇA ---
                      const SizedBox(height: 16), // AUMENTADO
                      TextFormField(
                        controller: vencimentoController,
                        readOnly: true,
                        decoration: _buildDialogInputDecoration(
                          'Vencimento (opcional)',
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
                            setDialogState(() {
                              selectedVencimento = picked;
                              vencimentoController.text = _formatDate(picked);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancelar', style: TextStyle(color: metroBlue)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: metroBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setDialogState(() => isSubmitting = true);

                        int quantidade;
                        try {
                          quantidade = int.parse(quantidadeController.text);
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quantidade deve ser um número'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final created = await _materialService.create(
                            codigo: codigoController.text,
                            nome: nomeController.text,
                            quantidade: quantidade,
                            local: selectedLocal!, // MUDANÇA
                            vencimento: selectedVencimento,
                            tipo: widget.tipo,
                          );

                          setState(() {
                            _materiais.add(created);
                          });

                          if (!mounted) return;
                          Navigator.of(dialogContext).pop(); // fecha o diálogo
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Material ${created.nome} adicionado com sucesso',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao criar material: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setDialogState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Adicionar'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- MUDANÇA: DIÁLOGO DE EDITAR (COM CAMPOS BONITOS E DROPDOWN) ---
  void _showEditMaterialDialog(EstoqueMaterial material) {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: material.nome);
    // final localController = TextEditingController(text: material.local); // REMOVIDO
    String? selectedLocal = material.local; // NOVO
    DateTime? selectedVencimento = material.vencimento;
    final vencimentoController = TextEditingController(
      text: _formatDate(material.vencimento),
    );

    // Valida se o local atual existe na lista, se não, reseta
    if (selectedLocal != null &&
        !_listaDeBases.any((base) => base['value'] == selectedLocal)) {
      selectedLocal = null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;
        final double dialogWidth = MediaQuery.of(dialogContext).size.width > 550
            ? 500.0 // Largura fixa
            : MediaQuery.of(dialogContext).size.width * 0.95; // 95% para mobile

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: metroBlue, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Editar Material',
                  style: TextStyle(
                    color: metroBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            content: SizedBox(
              width: dialogWidth,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // --- MUDANÇA: CAMPO NÃO-EDITÁVEL BONITO ---
                      _buildReadOnlyField(
                        'Código',
                        material.codigo,
                        Icons.qr_code_2_rounded,
                      ),
                      const SizedBox(height: 16), // AUMENTADO
                      TextFormField(
                        controller: nomeController,
                        decoration: _buildDialogInputDecoration('Nome *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16), // AUMENTADO
                      // --- MUDANÇA: CAMPO NÃO-EDITÁVEL BONITO ---
                      _buildReadOnlyField(
                        'Quantidade Atual',
                        "${material.quantidade} (use 'Movimentar' para alterar)",
                        Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 16), // AUMENTADO
                      // --- MUDANÇA: CAMPO DE LOCAL (DROPDOWN) ---
                      DropdownButtonFormField<String>(
                        value: selectedLocal,
                        items: _listaDeBases.map((base) {
                          return DropdownMenuItem(
                            value: base['value'],
                            child: Text(base['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedLocal = value;
                          });
                        },
                        decoration: _buildDialogInputDecoration('Local *'),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Selecione um local'
                            : null,
                        dropdownColor: Colors.white,
                      ),

                      // --- FIM DA MUDANÇA ---
                      const SizedBox(height: 16), // AUMENTADO
                      TextFormField(
                        controller: vencimentoController,
                        readOnly: true,
                        decoration: _buildDialogInputDecoration(
                          'Vencimento (opcional)',
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
                            setDialogState(() {
                              selectedVencimento = picked;
                              vencimentoController.text = _formatDate(picked);
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancelar', style: TextStyle(color: metroBlue)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: metroBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;

                        setDialogState(() => isSubmitting = true);
                        setState(() => _processingIds.add(material.codigo));

                        try {
                          // --- MUDANÇA: Chamada de update corrigida ---
                          final updatedMaterial = await _materialService.update(
                            material.codigo,
                            // tipo não é mais necessário
                            nome: nomeController.text,
                            local: selectedLocal!,
                            vencimento: selectedVencimento,
                          );

                          // Atualiza a lista local
                          setState(() {
                            final index = _materiais.indexWhere(
                              (m) => m.codigo == material.codigo,
                            );
                            if (index != -1) {
                              _materiais[index] = updatedMaterial;
                            }
                          });

                          if (!mounted) return;
                          Navigator.of(dialogContext).pop(); // fecha o diálogo
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Material ${updatedMaterial.nome} salvo com sucesso',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erro ao salvar material: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setDialogState(() => isSubmitting = false);
                          setState(
                            () => _processingIds.remove(material.codigo),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- NOVOS: MÉTODOS DE EXCLUIR ---
  Future<void> _deleteMaterial(String codigo) async {
    setState(() => _processingIds.add(codigo));
    try {
      // --- MUDANÇA: Chamada de delete corrigida ---
      await _materialService.delete(codigo); // tipo não é mais necessário

      setState(() {
        _materiais.removeWhere((m) => m.codigo == codigo);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material excluído com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir material: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _processingIds.remove(codigo));
    }
  }

  Future<void> _showDeleteConfirmDialog(EstoqueMaterial material) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja realmente excluir o material "${material.nome}" (${material.codigo})? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteMaterial(material.codigo);
    }
  }
  // --- FIM DOS MÉTODOS DE EXCLUIR ---

  // Método para mostrar o diálogo de movimentação de material
  void _showMovimentarDialog(BuildContext context, EstoqueMaterial material) {
    final quantidadeController = TextEditingController();
    String tipoMovimento = 'saida'; // 'saida' ou 'entrada'

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Movimentar ${material.nome}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Estoque atual: ${material.quantidade}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Saída'),
                        selected: tipoMovimento == 'saida',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => tipoMovimento = 'saida');
                          }
                        },
                        selectedColor: Colors.red.shade100,
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Entrada'),
                        selected: tipoMovimento == 'entrada',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() => tipoMovimento = 'entrada');
                          }
                        },
                        selectedColor: Colors.green.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantidadeController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Quantidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final quantidade = int.tryParse(quantidadeController.text);
                    if (quantidade == null || quantidade <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, insira uma quantidade válida.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    // Mostrar indicador de progresso
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      // Buscar o nome do usuário logado
                      final nomeUsuario = await _authService.nome ?? 'Sistema';

                      await _materialService.movimentar(
                        codigo: material.codigo,
                        tipo: tipoMovimento,
                        quantidade: quantidade,
                        usuario: nomeUsuario,
                        local: material.local,
                      );

                      // Atualizar o estado local
                      setState(() {
                        final index = _materiais.indexWhere(
                          (m) => m.codigo == material.codigo,
                        );
                        if (index != -1) {
                          final oldMaterial = _materiais[index];
                          final novaQuantidade = tipoMovimento == 'saida'
                              ? oldMaterial.quantidade - quantidade
                              : oldMaterial.quantidade + quantidade;

                          _materiais[index] = EstoqueMaterial(
                            codigo: oldMaterial.codigo,
                            nome: oldMaterial.nome,
                            quantidade: novaQuantidade,
                            local: oldMaterial.local,
                            vencimento: oldMaterial.vencimento,
                          );
                        }
                      });

                      Navigator.of(context).pop(); // Fecha o progresso
                      Navigator.of(context).pop(); // Fecha o diálogo

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Movimentação de ${material.nome} realizada com sucesso!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context).pop(); // Fecha o progresso
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metroBlue = const Color(0xFF001489);
    final bool isMobileScreen = MediaQuery.of(context).size.width < 600;

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
                  icon: Icon(Icons.filter_list, color: metroBlue),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isCompact = constraints.maxWidth < 500;

                Widget availabilityChip({
                  required MaterialColor baseColor,
                  required IconData icon,
                  required String label,
                }) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: baseColor.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: baseColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: baseColor, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: baseColor.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final availableChip = availabilityChip(
                  baseColor: Colors.green,
                  icon: Icons.check_circle,
                  label:
                      'Disponíveis: ${_materiais.where((m) => m.quantidade > 0).length}',
                );
                final missingChip = availabilityChip(
                  baseColor: Colors.red,
                  icon: Icons.warning,
                  label:
                      'Em falta: ${_materiais.where((m) => m.quantidade <= 0).length}',
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Itens no estoque: ${_filteredMateriais.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          availableChip,
                          missingChip,
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Itens no estoque: ${_filteredMateriais.length}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        availableChip,
                        const SizedBox(width: 12),
                        missingChip,
                      ],
                    ),
                  ],
                );
              },
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
                      // Encontra o label da base para exibição
                      final localLabel = _listaDeBases.firstWhere(
                        (base) => base['value'] == material.local,
                        orElse: () => {'label': material.local},
                      )['label']!;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 2,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            collapsedShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            collapsedBackgroundColor: Colors.white,
                            backgroundColor: Colors.white,
                            iconColor: metroBlue,
                            collapsedIconColor: metroBlue,
                            textColor: Colors.black87,
                            collapsedTextColor: Colors.black87,
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
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
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      'Quantidade:',
                                      material.quantidade.toString(),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      'Local:',
                                      localLabel,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      'Vencimento:',
                                      _formatDate(material.vencimento),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                          ),
                                          label: const Text('Excluir'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _showDeleteConfirmDialog(
                                                material,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        TextButton.icon(
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                          label: const Text('Editar'),
                                          onPressed: () =>
                                              _showEditMaterialDialog(material),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.swap_vert,
                                            size: 18,
                                          ),
                                          label: const Text('Movimentar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: metroBlue,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            _showMovimentarDialog(
                                              context,
                                              material,
                                            );
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
                                // Encontra o label da base para exibição
                                final localLabel = _listaDeBases.firstWhere(
                                  (base) => base['value'] == material.local,
                                  orElse: () => {'label': material.local},
                                )['label']!;

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
                                    DataCell(Text(localLabel)), // MUDANÇA
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
                                    // --- MUDANÇA: ADICIONADO BOTÃO DE EXCLUIR, EDITAR E LOADING (DESKTOP) ---
                                    DataCell(
                                      _processingIds.contains(material.codigo)
                                          ? const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit,
                                                    size: 20,
                                                  ),
                                                  color: metroBlue,
                                                  tooltip: "Editar",
                                                  onPressed: () {
                                                    _showEditMaterialDialog(
                                                      material,
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.swap_vert,
                                                    size: 20,
                                                  ),
                                                  color: metroBlue,
                                                  tooltip: "Movimentar",
                                                  onPressed: () {
                                                    _showMovimentarDialog(
                                                      context,
                                                      material,
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 20,
                                                  ),
                                                  color: Colors.red,
                                                  tooltip: "Excluir",
                                                  onPressed: () {
                                                    _showDeleteConfirmDialog(
                                                      material,
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                    ),
                                    // --- FIM DA MUDANÇA ---
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
    final isMobile = isMobileScreen;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade50,
      appBar: isMobile
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              scrolledUnderElevation: 0,
              leading: widget.showBackButton
                  ? IconButton(
                      icon: Icon(Icons.arrow_back, color: metroBlue),
                      onPressed: () => Navigator.pop(context),
                    )
                  : IconButton(
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: _animationController,
                        color: metroBlue,
                      ),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
              title: Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: metroBlue,
                ),
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
                            if (widget.showBackButton)
                              IconButton(
                                icon: Icon(Icons.arrow_back, color: metroBlue),
                                onPressed: () => Navigator.pop(context),
                                tooltip: 'Voltar',
                              ),
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
