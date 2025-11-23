// lib/screens/home/estoque_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import para formatadores
import '../../models/material.dart'; // MUDANÇA: Importa a classe EstoqueMaterial centralizada
import '../../services/material_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/sidebar.dart';
import 'package:intl/intl.dart'; // Import para formatar data

// A CLASSE EstoqueMaterial LOCAL FOI REMOVIDA DESTE ARQUIVO

class EstoquePage extends StatefulWidget {
  final String title;
  final List<EstoqueMaterial> materiais;
  final String? tipo; 
  final bool withSidebar;
  final int sidebarSelectedIndex;
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
  // --- Sidebar / layout state ---
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<EstoqueMaterial> _materiais;
  final MaterialService _materialService = MaterialService();
  final AuthService _authService = AuthService();

  final Color metroBlue = const Color(0xFF001489);
  final Set<String> _processingIds = <String>{};

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

  InputDecoration _buildDialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: metroBlue, width: 2),
      ),
    );
  }

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
    return DateFormat('dd/MM/yyyy').format(d);
  }

  // --- DIÁLOGO DE ADICIONAR (ATUALIZADO) ---
  void _showAddMaterialDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final codigoController = TextEditingController();
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    String? selectedLocal;
    DateTime? selectedVencimento;
    final vencimentoController = TextEditingController();
    final estoqueMinimoController = TextEditingController(); 
    final patrimonioController = TextEditingController(); 
    DateTime? selectedCalibracao;
    final calibracaoController = TextEditingController(); 
    String? selectedStatus = 'disponível'; 

    final isInstrumento = widget.tipo == 'instrumento';

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;
        final double dialogWidth = MediaQuery.of(dialogContext).size.width > 550
            ? 500.0
            : MediaQuery.of(dialogContext).size.width * 0.95;

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
                  'Adicionar ${isInstrumento ? 'Instrumento' : 'Material'}',
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
                      const SizedBox(height: 16),
                      // Campo Patrimônio para Instrumentos
                      if (isInstrumento)
                        Column(
                          children: [
                            TextFormField(
                              controller: patrimonioController,
                              decoration:
                                  _buildDialogInputDecoration('Patrimônio *'),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Informe o patrimônio'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      TextFormField(
                        controller: nomeController,
                        decoration: _buildDialogInputDecoration('Nome *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),

                      // Campos específicos de Consumo/Giro
                      if (!isInstrumento)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
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
                        ),
                      if (!isInstrumento)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            controller: estoqueMinimoController,
                            decoration: _buildDialogInputDecoration(
                              'Estoque Mínimo (opcional)',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),

                      // Campos específicos de Instrumento
                      if (isInstrumento)
                        Column(
                          children: [
                            TextFormField(
                              controller: calibracaoController,
                              readOnly: true,
                              decoration: _buildDialogInputDecoration(
                                'Vencimento Calibração *',
                              ),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Informe a data de calibração'
                                  : null,
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedCalibracao ?? now,
                                  firstDate: DateTime(now.year - 5),
                                  lastDate: DateTime(now.year + 10),
                                );
                                if (picked != null) {
                                  setDialogState(() {
                                    selectedCalibracao = picked;
                                    calibracaoController.text =
                                        _formatDate(picked);
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedStatus,
                              items: ['disponível', 'em uso', 'em campo', 'manutenção']
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.toUpperCase()),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedStatus = value;
                                });
                              },
                              decoration:
                                  _buildDialogInputDecoration('Status *'),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                      ? 'Selecione o status'
                                      : null,
                              dropdownColor: Colors.white,
                            ),
                          ],
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
                        int? estoqueMinimo;
                        try {
                          quantidade = int.parse(quantidadeController.text);
                          if (!isInstrumento && estoqueMinimoController.text.isNotEmpty) {
                            estoqueMinimo = int.parse(estoqueMinimoController.text);
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quantidade/Estoque Mínimo deve ser um número'),
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
                            local: selectedLocal!,
                            vencimento: selectedVencimento,
                            tipo: widget.tipo,
                            // Campos de Instrumento (ENVIADOS PARA O SERVIÇO)
                            patrimonio: isInstrumento ? patrimonioController.text : null,
                            dataCalibracao: selectedCalibracao,
                            status: isInstrumento ? selectedStatus : null,
                            // Campos de Estoque
                            estoqueMinimo: estoqueMinimo,
                          );

                          setState(() {
                            _materiais.add(created);
                          });

                          if (!mounted) return;
                          Navigator.of(dialogContext).pop(); 
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

  // --- DIÁLOGO DE EDITAR (ATUALIZADO) ---
  void _showEditMaterialDialog(EstoqueMaterial material) {
    final formKey = GlobalKey<FormState>();
    final nomeController = TextEditingController(text: material.nome);
    String? selectedLocal = material.local;
    DateTime? selectedVencimento = material.vencimento;
    final vencimentoController = TextEditingController(
      text: _formatDate(material.vencimento),
    );
    final estoqueMinimoController = TextEditingController(
      text: material.estoqueMinimo?.toString() ?? '',
    );
    
    final isInstrumento = material.tipo == 'instrumento';
    final dataCalibracao = material.dataCalibracao;

    if (selectedLocal != null &&
        !_listaDeBases.any((base) => base['value'] == selectedLocal)) {
      selectedLocal = null;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;
        final double dialogWidth = MediaQuery.of(dialogContext).size.width > 550
            ? 500.0
            : MediaQuery.of(dialogContext).size.width * 0.95;

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
                  'Editar ${isInstrumento ? 'Instrumento' : 'Material'}',
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
                      _buildReadOnlyField(
                        'Código',
                        material.codigo,
                        Icons.qr_code_2_rounded,
                      ),
                      const SizedBox(height: 16),
                      if (material.patrimonio != null && material.patrimonio!.isNotEmpty)
                        Column(
                          children: [
                            _buildReadOnlyField(
                              'Patrimônio (Instrumento)',
                              material.patrimonio!,
                              Icons.apartment_rounded,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      TextFormField(
                        controller: nomeController,
                        decoration: _buildDialogInputDecoration('Nome *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildReadOnlyField(
                        'Quantidade Atual',
                        "${material.quantidade} (use 'Movimentar' para alterar)",
                        Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      
                      // Vencimento (Consumo/Giro)
                      if (!isInstrumento)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
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
                        ),
                      // Calibração (Instrumento) - Apenas leitura, pois é atualizada na Movimentação/Criação
                      if (isInstrumento)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: _buildReadOnlyField(
                            'Vencimento Calibração',
                            _formatDate(dataCalibracao),
                            Icons.calendar_today,
                          ),
                        ),
                      
                      // Estoque Mínimo (Consumo/Giro)
                      if (!isInstrumento)
                        TextFormField(
                          controller: estoqueMinimoController,
                          decoration: _buildDialogInputDecoration(
                            'Estoque Mínimo (opcional)',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                        
                        int? estoqueMinimo;
                        try {
                          if (!isInstrumento && estoqueMinimoController.text.isNotEmpty) {
                            estoqueMinimo = int.parse(estoqueMinimoController.text);
                          }
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          setState(() => _processingIds.remove(material.codigo));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Estoque Mínimo deve ser um número'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        try {
                          final updatedMaterial = await _materialService.update(
                            material.codigo,
                            nome: nomeController.text,
                            local: selectedLocal!,
                            vencimento: selectedVencimento,
                            estoqueMinimo: estoqueMinimo,
                          );

                          final index = _materiais.indexWhere(
                            (m) => m.codigo == material.codigo,
                          );
                          if (index != -1) {
                            // MUDANÇA: Recria o objeto manualmente para simular o copyWith,
                            // usando os dados atualizados (nome, local, vencimento, estoqueMinimo)
                            // e preservando os dados originais do Instrumento (patrimonio, dataCalibracao, status).
                            _materiais[index] = EstoqueMaterial(
                              codigo: updatedMaterial.codigo,
                              nome: updatedMaterial.nome, // Atualizado
                              quantidade: updatedMaterial.quantidade, // Atualizado (deveria ser o mesmo)
                              local: updatedMaterial.local, // Atualizado
                              vencimento: updatedMaterial.vencimento, // Atualizado
                              estoqueMinimo: updatedMaterial.estoqueMinimo, // Atualizado
                              tipo: updatedMaterial.tipo,
                              
                              // Preserve os campos originais do instrumento:
                              patrimonio: material.patrimonio,
                              dataCalibracao: material.dataCalibracao,
                              status: material.status,
                            ); 
                          }
                          setState(() {});

                          if (!mounted) return;
                          Navigator.of(dialogContext).pop();
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

  Future<void> _deleteMaterial(String codigo) async {
    setState(() => _processingIds.add(codigo));
    try {
      await _materialService.delete(codigo); 

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

  // --- MÉTODO DE MOVIMENTAÇÃO (ATUALIZADO) ---
  void _showMovimentarDialog(BuildContext context, EstoqueMaterial material) {
    final quantidadeController = TextEditingController(); 
    String tipoMovimento = 'saida'; 

    if (material.isVencidoOuCalibracaoExpirada) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            material.tipo == 'instrumento' 
              ? 'ATENÇÃO: Este instrumento está com a calibração vencida. Movimentação não permitida.'
              : 'ATENÇÃO: Este material está vencido. Movimentação não permitida.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isInstrumento = material.tipo == 'instrumento';
    if (isInstrumento) {
      quantidadeController.text = '1';
    }

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
                  if (!isInstrumento) 
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
                    )
                  else 
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Retirada'),
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
                          label: const Text('Devolução'),
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
                    readOnly: isInstrumento, 
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: isInstrumento ? 'Quantidade (Deve ser 1)' : 'Quantidade',
                      border: const OutlineInputBorder(),
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
                    final quantidade = isInstrumento ? 1 : int.tryParse(quantidadeController.text);
                    if (quantidade == null || quantidade <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, insira uma quantidade válida.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );

                    try {
                      final nomeUsuario = await _authService.nome ?? 'Sistema';

                      if (isInstrumento) {
                        final tipoInst = tipoMovimento == 'saida' ? 'retirada' : 'devolucao';
                        await _materialService.movimentarInstrumento(
                          codigo: material.codigo,
                          tipoMovimento: tipoInst,
                          usuario: nomeUsuario,
                          local: material.local,
                        );
                      } else {
                        await _materialService.movimentar(
                          codigo: material.codigo,
                          tipo: tipoMovimento,
                          quantidade: quantidade,
                          usuario: nomeUsuario,
                          local: material.local,
                        );
                      }

                      // Atualizar o estado local (Mantendo todos os campos do modelo)
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
                            tipo: oldMaterial.tipo,
                            patrimonio: oldMaterial.patrimonio,
                            estoqueMinimo: oldMaterial.estoqueMinimo,
                            dataCalibracao: oldMaterial.dataCalibracao,
                            status: oldMaterial.status,
                          );
                        }
                      });

                      Navigator.of(context).pop(); 
                      Navigator.of(context).pop(); 

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Movimentação de ${material.nome} realizada com sucesso!',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context).pop(); 
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

    // MUDANÇA: Lógica corrigida. Se o tipo da página for 'instrumento', mostra a coluna.
    final bool showPatrimonioColumn = widget.tipo == 'instrumento' || 
      _materiais.any((m) => m.tipo == 'instrumento');

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
                final expiredChip = availabilityChip(
                  baseColor: Colors.orange,
                  icon: Icons.calendar_today,
                  label:
                      'Vencidos/Expirados: ${_materiais.where((m) => m.isVencidoOuCalibracaoExpirada).length}',
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
                          expiredChip,
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
                        const SizedBox(width: 12),
                        expiredChip,
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
                final isMobile = constraints.maxWidth < 600;

                if (isMobile) {
                  // Layout de cards para mobile
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredMateriais.length,
                    itemBuilder: (context, index) {
                      final material = _filteredMateriais[index];
                      final localLabel = _listaDeBases.firstWhere(
                        (base) => base['value'] == material.local,
                        orElse: () => {'label': material.local},
                      )['label']!;

                      final statusColor = material.isVencidoOuCalibracaoExpirada
                          ? Colors.orange
                          : material.quantidade > 0
                              ? Colors.green
                              : Colors.red;

                      final statusText = material.isVencidoOuCalibracaoExpirada
                          ? (material.tipo == 'instrumento' ? 'Calibração Vencida' : 'Vencido')
                          : material.status ?? (material.quantidade > 0 ? 'Disponível' : 'Em Falta');


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
                                // Ícone baseado na quantidade/status
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha((0.1 * 255).round()),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    material.isVencidoOuCalibracaoExpirada
                                        ? Icons.calendar_month_outlined
                                        : material.quantidade > 0
                                            ? Icons.inventory_2
                                            : Icons.warning_amber,
                                    color: statusColor,
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
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText, 
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
                                    if (material.tipo == 'instrumento' && material.patrimonio != null)
                                      _buildInfoRow(
                                        'Patrimônio:',
                                        material.patrimonio!,
                                      ),
                                    if (material.tipo != 'instrumento' && material.estoqueMinimo != null)
                                      _buildInfoRow(
                                        'Estoque Mínimo:',
                                        material.estoqueMinimo.toString(),
                                      ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      'Local:',
                                      localLabel,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      material.tipo == 'instrumento' ? 'Calibração:' : 'Vencimento:',
                                      _formatDate(material.tipo == 'instrumento' ? material.dataCalibracao : material.vencimento),
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: SingleChildScrollView(
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
                                const DataColumn(
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
                                // MUDANÇA: Adiciona coluna de Patrimônio, CONDICIONAL
                                if (showPatrimonioColumn)
                                  const DataColumn(
                                    label: Expanded(
                                      child: Text(
                                        'Patrimônio',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
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
                                DataColumn(
                                  label: SizedBox(
                                    width: 120,
                                    child: Center(
                                      child: Text(
                                        // MUDANÇA: Cabeçalho condicional
                                        showPatrimonioColumn 
                                            ? 'Venc. Calib.' 
                                            : 'Vencimento',
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
                                final localLabel = _listaDeBases.firstWhere(
                                  (base) => base['value'] == material.local,
                                  orElse: () => {'label': material.local},
                                )['label']!;
                                
                                final statusColor = material.isVencidoOuCalibracaoExpirada
                                    ? Colors.orange
                                    : material.quantidade > 0
                                        ? Colors.green
                                        : Colors.red;

                                final statusText = material.isVencidoOuCalibracaoExpirada
                                    ? (material.tipo == 'instrumento' ? 'Calibração Vencida' : 'Vencido')
                                    : material.status ?? (material.quantidade > 0 ? 'Disponível' : 'Em Falta');
                                    
                                final isInstrumento = material.tipo == 'instrumento';

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
                                    // MUDANÇA: Célula de Patrimônio, CONDICIONAL
                                    if (showPatrimonioColumn)
                                      DataCell(
                                        Text(isInstrumento ? (material.patrimonio ?? '-') : '-'),
                                      ),
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
                                    DataCell(Text(localLabel)), 
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Center(
                                          child: Text(
                                            // MUDANÇA: Usa dataCalibracao se for instrumento, senão usa vencimento
                                            _formatDate(isInstrumento ? material.dataCalibracao : material.vencimento),
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: statusColor,
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
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
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