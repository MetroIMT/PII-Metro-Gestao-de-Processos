import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/movimentacao.dart';
import '../../services/movimentacao_service.dart'; // Alterado
import '../../widgets/sidebar.dart';

class MovimentacoesPage extends StatefulWidget {
  const MovimentacoesPage({super.key});

  @override
  State<MovimentacoesPage> createState() => _MovimentacoesPageState();
}

class _MovimentacoesPageState extends State<MovimentacoesPage>
    with SingleTickerProviderStateMixin {
  // --- Service ---
  final MovimentacaoService _movimentacaoService = MovimentacaoService();

  // --- Sidebar ---
  String? _filterTipo;
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Movimentacao> _movimentacoes = [];
  List<Movimentacao> _filteredMovimentacoes = [];
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = true;
  String? _error;

  final Color backgroundColor = const Color.fromARGB(255, 255, 255, 255);
  final Color metroBlue = const Color(0xFF001489);

  // --- Advanced Filter State (New) ---
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  List<String> _selectedBases = ['ALL']; // Inicia com 'Todas'
  String? _selectedUser;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  // --- Constants for Bases (Copied from reports_page.dart) ---
  static const List<MapEntry<String, String>> _allBaseOptions = [
    MapEntry('ALL', 'Todas as Bases'),
    MapEntry('WJA', 'WJA - Jabaquara'),
    MapEntry('PSO', 'PSO - Paraiso'),
    MapEntry('TRD', 'TRD - Tiradentes'),
    MapEntry('TUC', 'TUC - Tucuruvi'),
    MapEntry('LUM', 'LUM - Luminárias'),
    MapEntry('IMG', 'IMG - Imigrantes'),
    MapEntry('BFU', 'BFU - Barra Funda'),
    MapEntry('BAS', 'BAS - Brás'),
    MapEntry('CEC', 'CEC - Cecília'),
    MapEntry('MAT', 'MAT - Matheus'),
    MapEntry('VTD', 'VTD - Vila Matilde'),
    MapEntry('VPT', 'VPT – Vila Prudente'),
    MapEntry('PIT', 'PIT – Pátio Itaquera'),
    MapEntry('POT', 'POT – Pátio Oratório'),
    MapEntry('PAT', 'PAT – Pátio Jabaquara'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadMovimentacoes();

    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
        _filterMovimentacoes();
      });
    });

    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadMovimentacoes() async {
    try {
      final movimentacoes = await _movimentacaoService.getAllMovimentacoes();
      setState(() {
        _movimentacoes = movimentacoes;
        _filteredMovimentacoes = _movimentacoes;
        _isLoading = false;
      });
    } catch (e) {
      // Mock data for fallback
      final mockMovimentacoes = [
        Movimentacao(
          id: '1',
          tipo: 'Saída',
          codigoMaterial: 'G001',
          descricao: 'Rolamento 6203 (Mock)',
          quantidade: 2,
          usuario: 'João Silva',
          local: 'Oficina Mecânica',
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
        Movimentacao(
          id: '2',
          tipo: 'Entrada',
          codigoMaterial: 'C002',
          descricao: 'Graxa de Lítio (Mock)',
          quantidade: 5,
          usuario: 'Maria Oliveira',
          local: 'Almoxarifado A',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        Movimentacao(
          id: '3',
          tipo: 'Saída',
          codigoMaterial: 'P001',
          descricao: 'Furadeira Bosch (Mock)',
          quantidade: 1,
          usuario: 'Carlos Souza',
          local: 'Obra Externa',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Movimentacao(
          id: '4',
          tipo: 'Entrada',
          codigoMaterial: 'G005',
          descricao: 'Óleo Hidráulico (Mock)',
          quantidade: 10,
          usuario: 'Ana Pereira',
          local: 'Almoxarifado B',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Movimentacao(
          id: '5',
          tipo: 'Saída',
          codigoMaterial: 'C004',
          descricao: 'Lixa para Ferro (Mock)',
          quantidade: 20,
          usuario: 'Pedro Santos',
          local: 'Oficina 2',
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

      setState(() {
        _movimentacoes = mockMovimentacoes;
        _filteredMovimentacoes = _movimentacoes;
        _isLoading = false;
        // _error = e.toString(); // Don't show error, show mocks
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _movimentacaoService.dispose();
    // Dispose new controllers
    _startDateController.dispose();
    _endDateController.dispose();
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

  void _updateMovimentacoes() {
    _loadMovimentacoes();
  }

  // Helper functions copied from reports_page.dart
  String _extractBaseId(String local) {
    if (local.contains(' - ')) {
      return local.split(' - ').first.trim();
    }
    return local.length > 3 ? local.substring(0, 3).toUpperCase() : local;
  }

  String _getBaseName(String baseId) {
    return _allBaseOptions
        .firstWhere((e) => e.key == baseId, orElse: () => MapEntry('', baseId))
        .value;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  /// Aplica filtros avançados
  void _applyAdvancedFilters() {
    setState(() {
      _filterMovimentacoes();
    });
    // Opcional: Fechar o diálogo se chamado a partir dele.
  }

  /// Limpa filtros avançados
  void _clearAdvancedFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedBases = ['ALL']; // Reseta para 'Todas'
      _selectedUser = null;

      _startDateController.clear();
      _endDateController.clear();

      _filterMovimentacoes();
    });
  }

  // Updated filter logic to include new advanced filters
  void _filterMovimentacoes() {
    final term = _searchTerm.toLowerCase();

    _filteredMovimentacoes = _movimentacoes.where((mov) {
      // 1. Existing: Search in all main fields (descricao, codigoMaterial, tipo, usuario, local)
      final matchesSearch =
          term.isEmpty ||
          mov.descricao.toLowerCase().contains(term) ||
          mov.codigoMaterial.toLowerCase().contains(term) ||
          mov.tipo.toLowerCase().contains(term) ||
          mov.usuario.toLowerCase().contains(term) ||
          mov.local.toLowerCase().contains(term);

      // 2. Existing: Filter by Tipo (Entrada/Saída/Todos)
      final matchesTipo = _filterTipo == null || mov.tipo == _filterTipo;

      // --- New Advanced Filters ---

      // 3. New: Filter by Date Range
      final DateTime movDate = mov.timestamp;
      final bool matchesStartDate =
          _selectedStartDate == null || !movDate.isBefore(_selectedStartDate!);
      final bool matchesEndDate =
          _selectedEndDate == null ||
              movDate.isBefore(_selectedEndDate!.add(const Duration(days: 1)));
      final bool matchesDate = matchesStartDate && matchesEndDate;

      // 4. New: Filter by Base
      final String baseId = _extractBaseId(mov.local);
      final bool matchesBase =
          _selectedBases.contains('ALL') || _selectedBases.contains(baseId);
          
      // 5. New: Filter by User
      final bool matchesUser =
          _selectedUser == null || mov.usuario == _selectedUser;

      // Combine all filters
      return matchesSearch && matchesTipo && matchesDate && matchesBase && matchesUser;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      key: _scaffoldKey,
      appBar: isMobile
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _animationController,
                  color: metroBlue,
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              title: Text(
                'Histórico de Movimentações',
                style: TextStyle(color: metroBlue, fontWeight: FontWeight.bold),
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
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 3))
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
              child: Sidebar(expanded: _isRailExtended, selectedIndex: 3),
            ),

          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: Column(
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
                              'Histórico de Movimentações',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: metroBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMobile) const SizedBox(height: 8),
                        const Text(
                          'Visualize todas as entradas e saídas de materiais do estoque.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        Expanded(child: _buildMovimentacoesCard()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimentacoesCard() {
    // Check if advanced filters are active
    final bool advancedFiltersActive = _selectedStartDate != null ||
        _selectedEndDate != null ||
        !_selectedBases.contains('ALL') ||
        _selectedUser != null;

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: _searchFocusNode.hasFocus
                          ? 'Busca por código, descrição, tipo, usuário ou local'
                          : 'Buscar movimentação...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      suffixIcon: advancedFiltersActive
                          ? IconButton(
                              icon: const Icon(Icons.filter_list_off, color: Colors.red),
                              tooltip: 'Limpar filtros',
                              onPressed: _clearAdvancedFilters,
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() {
                      _searchTerm = v;
                      _filterMovimentacoes();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                // Botão de Filtro Avançado (New)
                Tooltip(
                  message: 'Filtros (Data, Base, Usuário)',
                  child: Container(
                    height: 56, // Match TextField height
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.filter_list_rounded,
                          color: advancedFiltersActive
                              ? metroBlue
                              : Colors.black54),
                      onPressed: _openFilterDialog,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 FILTRO DE ENTRADA / SAÍDA / TODOS (Novo Estilo)
            _buildTypeFilterRow(),

            const SizedBox(height: 16),

            Expanded(child: _buildMovimentacoesTable()),
          ],
        ),
      ),
    );
  }

  // Novo método para construir os botões de filtro por Tipo (mais bonito)
  Widget _buildTypeFilterRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final double textSize = isCompact ? 12.0 : 14.0;
        final double horizontalPadding = isCompact ? 12.0 : 16.0;

        final ButtonStyle baseStyle = OutlinedButton.styleFrom(
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          side: const BorderSide(color: Colors.grey, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          elevation: 0,
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

        final ButtonStyle selectedStyle = ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
          minimumSize: const Size(0, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );

        Widget buildButton(String label, String? filterValue, Color primaryColor) {
          final isSelected = _filterTipo == filterValue;
          final color = isSelected ? Colors.white : primaryColor;
          final iconData = label == 'Entradas'
              ? Icons.add_circle_outline
              : (label == 'Saídas' ? Icons.remove_circle_outline : Icons.view_list);

          final TextStyle labelStyle = TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: textSize,
          );

          return SizedBox(
            height: 40, // Uniform height
            child: isSelected
                ? ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterTipo = filterValue;
                        _filterMovimentacoes();
                      });
                    },
                    icon: Icon(iconData, size: 18, color: Colors.white),
                    label: Text(
                      label,
                      style: labelStyle,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                    style: selectedStyle.copyWith(
                      backgroundColor: MaterialStateProperty.all(primaryColor),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _filterTipo = filterValue;
                        _filterMovimentacoes();
                      });
                    },
                    icon: Icon(iconData, size: 18, color: color),
                    label: Text(
                      label,
                      style: labelStyle,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                    style: baseStyle,
                  ),
          );
        }

        // Em telas menores (mobile), expande os botões para preencher a largura
        if (isCompact) {
          return Row(
            children: [
              Expanded(child: buildButton('Todos', null, metroBlue)),
              const SizedBox(width: 8),
              Expanded(
                child: buildButton(
                  'Entradas',
                  'Entrada',
                  Colors.green.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: buildButton('Saídas', 'Saída', Colors.red.shade700),
              ),
            ],
          );
        }

        // Desktop: Alinhado à esquerda
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            buildButton('Todos', null, metroBlue),
            const SizedBox(width: 8),
            buildButton('Entradas', 'Entrada', Colors.green.shade700),
            const SizedBox(width: 8),
            buildButton('Saídas', 'Saída', Colors.red.shade700),
          ],
        );
      },
    );
  }

  Future<void> _openFilterDialog() async {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildFilterCardContents(),
            ),
          ),
        ),
      );
    } else {
      await showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 120.0,
            vertical: 40.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildFilterCardContents(closeButton: true),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildFilterCardContents({bool closeButton = false}) {
    final ButtonStyle applyButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: metroBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );

    final ButtonStyle clearButtonStyle = OutlinedButton.styleFrom(
        foregroundColor: Colors.black54,
        side: const BorderSide(color: Colors.grey, width: 1.0));

    String baseFilterDisplayText;
    if (_selectedBases.contains('ALL')) {
      baseFilterDisplayText = 'Todas as Bases';
    } else if (_selectedBases.isEmpty) {
      baseFilterDisplayText = 'Todas as Bases';
    } else {
      baseFilterDisplayText = _selectedBases
          .map((id) => _getBaseName(id))
          .join(', ');
    }

    // Lista de usuários únicos para o dropdown
    final List<String> uniqueUsers = _movimentacoes
        .map((e) => e.usuario)
        .where((u) => u != 'N/A')
        .toSet()
        .toList()
        ..sort();
        
    // Adiciona uma opção para 'Todos os Usuários'
    uniqueUsers.insert(0, 'Todos os Usuários');
    
    // Mapeia o estado do usuário para o valor do dropdown
    String? dropdownUserValue = _selectedUser ?? 'Todos os Usuários';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_list_rounded, color: metroBlue),
            const SizedBox(width: 8),
            Text(
              'Filtros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: metroBlue,
              ),
            ),
            const Spacer(),
            if (closeButton)
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Data Inicial'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _startDateController,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Selecione a data inicial',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedStartDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: _selectedEndDate ?? DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: metroBlue,
                      onPrimary: Colors.white,
                      onSurface: Colors.black87,
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
            if (date != null) {
              setState(() {
                _selectedStartDate = date;
                _startDateController.text =
                    "${date.day}/${date.month}/${date.year}";
              });
            }
          },
        ),
        const SizedBox(height: 12),
        const Text('Data Final'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _endDateController,
          readOnly: true,
          decoration: const InputDecoration(
            hintText: 'Selecione a data final',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_today_outlined),
          ),
          onTap: () async {
            final DateTime firstDate = _selectedStartDate ?? DateTime(2000);
            DateTime initialDate = _selectedEndDate ?? DateTime.now();
            if (initialDate.isBefore(firstDate)) initialDate = firstDate;
            final date = await showDatePicker(
              context: context,
              initialDate: initialDate,
              firstDate: firstDate,
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: metroBlue,
                      onPrimary: Colors.white,
                      onSurface: Colors.black87,
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
            if (date != null) {
              setState(() {
                _selectedEndDate = date;
                _endDateController.text =
                    "${date.day}/${date.month}/${date.year}";
              });
            }
          },
        ),
        
        // Novo Filtro: Usuário
        const SizedBox(height: 12),
        const Text('Usuário'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Selecione o usuário',
            prefixIcon: Icon(Icons.person_outline),
          ),
          value: dropdownUserValue,
          items: uniqueUsers.map((user) {
            return DropdownMenuItem(
              value: user,
              child: Text(user),
            );
          }).toList(),
          onChanged: (value) async {
            setState(() {
              _selectedUser = (value == 'Todos os Usuários' ? null : value);
            });
          },
        ),

        // Filtro de Base
        const SizedBox(height: 12),
        const Text('Base de manutenção (Multi-seleção)'),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(text: baseFilterDisplayText),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Selecione as bases',
            prefixIcon: Icon(Icons.home_work_outlined),
          ),
          onTap: () async {
            await _openMultiSelectBaseDialog();
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: clearButtonStyle,
                onPressed: () {
                  _clearAdvancedFilters();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Limpar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: applyButtonStyle,
                onPressed: () {
                  _applyAdvancedFilters();
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Diálogo para Multi-seleção de Bases (Copied from reports_page.dart)
  Future<void> _openMultiSelectBaseDialog() async {
    Set<String> tempSelectedBases =
        _selectedBases.contains('ALL') ? {} : Set.from(_selectedBases);

    final List<MapEntry<String, String>> individualBaseOptions =
        _allBaseOptions.where((base) => base.key != 'ALL').toList();

    await showDialog(
      context: context,
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: AlertDialog(
              title: const Text('Selecionar Bases'),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(maxHeight: 300),
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setStateDialog) {
                    final bool isAllSelected = tempSelectedBases.isEmpty;

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CheckboxListTile(
                            title: Text(
                              _allBaseOptions.first.value,
                              style: TextStyle(
                                color: isAllSelected ? metroBlue : Colors.black87,
                                fontWeight: isAllSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            value: isAllSelected,
                            tileColor: Colors.white,
                            activeColor: metroBlue,
                            checkColor: Colors.white,
                            splashRadius: 0,
                            onChanged: (bool? newValue) {
                              if (newValue == true) {
                                setStateDialog(() {
                                  tempSelectedBases.clear();
                                });
                              }
                            },
                          ),
                          const Divider(height: 1, color: Colors.grey),

                          ...individualBaseOptions.map((base) {
                            bool isChecked = tempSelectedBases.contains(base.key);

                            return CheckboxListTile(
                              title: Text(base.value),
                              value: isChecked,
                              tileColor: Colors.white,
                              activeColor: metroBlue,
                              checkColor: Colors.white,
                              splashRadius: 0,
                              onChanged: (bool? newValue) {
                                if (newValue == null) return;

                                setStateDialog(() {
                                  if (newValue) {
                                    tempSelectedBases.add(base.key);
                                  } else {
                                    tempSelectedBases.remove(base.key);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: metroBlue,
                  ),
                  onPressed: () {
                    List<String> finalSelection =
                        tempSelectedBases.isEmpty ? ['ALL'] : tempSelectedBases.toList();

                    setState(() {
                      _selectedBases = finalSelection;
                    });
                    _applyAdvancedFilters();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Finalização do corpo da classe

  Widget _buildMovimentacoesTable() {
    if (_filteredMovimentacoes.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma movimentação encontrada para o termo ou filtros aplicados.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Define um ponto de quebra para mobile/tablet vertical
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          // --- VERSÃO MOBILE (LISTA DE CARDS) ---
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _filteredMovimentacoes.length,
            itemBuilder: (context, index) {
              final mov = _filteredMovimentacoes[index];
              final isEntrada = mov.tipo == 'Entrada';
              final color = isEntrada ? Colors.green : Colors.red;
              // Usa o ícone do model ou um padrão
              final icon = mov.icon; 

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withAlpha((0.1 * 255).round()),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mov.descricao,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cód: ${mov.codigoMaterial}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${mov.quantidade}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: color,
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM HH:mm').format(mov.timestamp),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    mov.usuario,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.place_outlined,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    mov.local,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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
              );
            },
          );
        }

        // --- VERSÃO DESKTOP (TABELA) ---
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: DataTable(
                dataRowHeight: 60,
                headingRowColor: MaterialStateProperty.all(
                  const Color.fromARGB(255, 255, 255, 255),
                ),
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                columns: const [
                  DataColumn(label: Text('Código')),
                  DataColumn(label: Text('Descrição')),
                  DataColumn(label: Text('Qtd.')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Data/Hora')),
                  DataColumn(label: Text('Usuário')),
                  DataColumn(label: Text('Local')),
                ],
                rows: _filteredMovimentacoes.map((mov) {
                  final color =
                      mov.tipo == 'Entrada' ? Colors.green : Colors.red;
                  return DataRow(
                    cells: [
                      DataCell(Text(mov.codigoMaterial)),
                      DataCell(
                        Text(mov.descricao, overflow: TextOverflow.ellipsis),
                      ),
                      DataCell(Text(mov.quantidade.toString())),
                      DataCell(
                        Row(
                          children: [
                            Icon(mov.icon, size: 18, color: color),
                            const SizedBox(width: 8),
                            Text(
                              mov.tipo,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          DateFormat('dd/MM/yy HH:mm').format(mov.timestamp),
                        ),
                      ),
                      DataCell(Text(mov.usuario)),
                      DataCell(Text(mov.local)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}
