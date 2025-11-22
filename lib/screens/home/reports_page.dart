import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/pdf_service.dart';
import '../../services/excel_service.dart';
import '../../services/movimentacao_service.dart';
import '../../models/movimentacao.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage>
    with SingleTickerProviderStateMixin {
  static const LatLng _mapDefaultCenter = LatLng(-23.55, -46.63);
  static const double _mapDefaultZoom = 11.0;

  // --- Sidebar ---
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final MapController _mapController = MapController();
  late final StreamSubscription<MapEvent> _mapEventSubscription;
  LatLng _latestCenter = _mapDefaultCenter;
  double _latestZoom = _mapDefaultZoom;
  bool _isMapReady = false;

  // --- Services ---
  final MovimentacaoService _movimentacaoService = MovimentacaoService();

  // 🔹 tipo de relatório selecionado
  String _selectedReportType = 'Movimentação Geral';

  // --- Estado de carregamento ---
  bool _isLoading = true;
  List<Movimentacao> _allMovimentacoes = [];

  // --- Estado da Página ---
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedBase;
  String? _selectedUser;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  final Color backgroundColor = Colors.grey.shade100;
  final Color metroBlue = const Color(0xFF001489);

  // Lista final que será exibida na tabela (formato Map para tabela)
  List<Map<String, dynamic>> _filteredData = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _mapEventSubscription = _mapController.mapEventStream.listen((event) {
      _latestCenter = event.camera.center;
      _latestZoom = event.camera.zoom;
    });
    _loadMovimentacoes();
  }

  Future<void> _loadMovimentacoes() async {
    setState(() => _isLoading = true);
    try {
      final movimentacoes = await _movimentacaoService.getAllMovimentacoes();
      setState(() {
        _allMovimentacoes = movimentacoes;
        _filteredData = _convertMovimentacoesToMap(_allMovimentacoes);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Erro ao carregar movimentações: $e');
      }
    }
  }

  List<Map<String, dynamic>> _convertMovimentacoesToMap(
    List<Movimentacao> movimentacoes,
  ) {
    return movimentacoes.map((m) {
      // Converter tipo para quantidade com sinal
      int quantidadeComSinal =
          m.tipo.toLowerCase().contains('saida') ||
              m.tipo.toLowerCase().contains('saída')
          ? -m.quantidade.abs()
          : m.quantidade.abs();

      return {
        'codigo': m.codigoMaterial,
        'data': m.timestamp,
        'item': m.descricao.isNotEmpty
            ? m.descricao
            : 'Item ${m.codigoMaterial}',
        'categoria_id':
            'geral', // Backend não retorna categoria específica ainda
        'categoria': 'Material',
        'sub_categoria_id': null,
        'quantidade': quantidadeComSinal,
        'usuario': m.usuario,
        'base': m.local,
        'base_id': _extractBaseId(m.local),
      };
    }).toList();
  }

  String _extractBaseId(String local) {
    // Extrai o código da base (ex: "WJA - Jabaquara" -> "WJA")
    if (local.contains(' - ')) {
      return local.split(' - ').first.trim();
    }
    return local.length > 3 ? local.substring(0, 3).toUpperCase() : local;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _mapEventSubscription.cancel();
    _mapController.dispose();
    _movimentacaoService.dispose();
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

  /// Aplica filtros
  void _applyFilters() {
    List<Map<String, dynamic>> tempResults = List<Map<String, dynamic>>.from(
      _convertMovimentacoesToMap(_allMovimentacoes),
    );

    if (_selectedReportType == 'Movimentações por Usuário' &&
        _selectedUser != null) {
      tempResults = tempResults.where((row) {
        return row['usuario'] == _selectedUser;
      }).toList();
    }

    if (_selectedStartDate != null) {
      tempResults = tempResults.where((row) {
        DateTime rowDate = row['data'];
        return !rowDate.isBefore(_selectedStartDate!);
      }).toList();
    }
    if (_selectedEndDate != null) {
      tempResults = tempResults.where((row) {
        DateTime rowDate = row['data'];
        return rowDate.isBefore(_selectedEndDate!.add(const Duration(days: 1)));
      }).toList();
    }

    if (_selectedCategory != null) {
      tempResults = tempResults.where((row) {
        return row['categoria_id'] == _selectedCategory;
      }).toList();

      if (_selectedCategory == 'patrimoniado' && _selectedSubCategory != null) {
        tempResults = tempResults.where((row) {
          return row['sub_categoria_id'] == _selectedSubCategory;
        }).toList();
      }
    }

    if (_selectedBase != null) {
      tempResults = tempResults.where((row) {
        return row['base_id'] == _selectedBase;
      }).toList();
    }

    setState(() {
      _filteredData = tempResults;
    });
  }

  /// Limpa filtros
  void _clearFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedCategory = null;
      _selectedSubCategory = null;
      _selectedBase = null;
      _selectedUser = null;

      _startDateController.clear();
      _endDateController.clear();

      _filteredData = _convertMovimentacoesToMap(_allMovimentacoes);
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _canGenerateReport() {
    if (_filteredData.isEmpty) {
      _showErrorSnackBar('Não há dados para gerar o relatório');
      return false;
    }
    return true;
  }

  DateTime _getStartDate() {
    return _selectedStartDate ??
        (_filteredData.isNotEmpty
            ? _filteredData.first['data']
            : DateTime.now());
  }

  DateTime _getEndDate() {
    return _selectedEndDate ??
        (_filteredData.isNotEmpty
            ? _filteredData.last['data']
            : DateTime.now());
  }

  Future<void> _exportPdf() async {
    if (!_canGenerateReport()) return;

    final List<Map<String, String>> exportData = _filteredData.map((row) {
      return {
        'codigo': row['codigo']?.toString() ?? '—',
        'data': "${row['data'].day}/${row['data'].month}/${row['data'].year}",
        'item': row['item'].toString(),
        'categoria': row['categoria'].toString(),
        'quantidade': row['quantidade'].toString(),
        'base': row['base'].toString(),
        'usuario': row['usuario'].toString(),
      };
    }).toList();

    try {
      await PdfService.generateReport(
        title: 'Movimentação de Itens ($_selectedReportType)',
        data: exportData,
        startDate: _getStartDate(),
        endDate: _getEndDate(),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Erro ao gerar PDF: ${e.toString()}');
    }
  }

  Future<void> _exportExcel() async {
    if (!_canGenerateReport()) return;

    final List<Map<String, String>> exportData = _filteredData.map((row) {
      return {
        'data': "${row['data'].day}/${row['data'].month}/${row['data'].year}",
        'item': row['item'].toString(),
        'categoria': row['categoria'].toString(),
        'quantidade': row['quantidade'].toString(),
        'base': row['base'].toString(),
        'usuario': row['usuario'].toString(),
      };
    }).toList();

    try {
      await ExcelService.generateReport(
        title: 'Movimentação de Itens ($_selectedReportType)',
        data: exportData,
        startDate: _getStartDate(),
        endDate: _getEndDate(),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Erro ao gerar Excel: ${e.toString()}');
    }
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
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
                'Relatórios',
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
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 4))
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
              child: Sidebar(expanded: _isRailExtended, selectedIndex: 4),
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
                              'Relatórios',
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
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: isMobile
                        ? _buildMobileReportsLayout()
                        : _buildDesktopReportsLayout(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- FILTROS ----------

  Widget _buildFilterCardContents({bool closeButton = false}) {
    final ButtonStyle applyButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: metroBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
    );

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
        const SizedBox(height: 8),
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
        const SizedBox(height: 12),
        const Text('Categoria'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Selecione a categoria',
            prefixIcon: Icon(Icons.category_outlined),
          ),
          value: _selectedCategory,
          items: const [
            DropdownMenuItem(value: 'giro', child: Text('Material de Giro')),
            DropdownMenuItem(
              value: 'consumo',
              child: Text('Material de Consumo'),
            ),
            DropdownMenuItem(
              value: 'patrimoniado',
              child: Text('Material Patrimoniado'),
            ),
          ],
          onChanged: (value) async {
            setState(() {
              _selectedCategory = value;
              _selectedSubCategory = null;
            });
          },
        ),
        const SizedBox(height: 12),
        const Text('Base de manutenção'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          dropdownColor: Colors.white,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Selecione a base',
            prefixIcon: Icon(Icons.home_work_outlined),
          ),
          value: _selectedBase,
          items: const [
            DropdownMenuItem(value: 'WJA', child: Text('WJA - Jabaquara')),
            DropdownMenuItem(value: 'PSO', child: Text('PSO - Paraiso')),
            DropdownMenuItem(value: 'TRD', child: Text('TRD - Tiradentes')),
            DropdownMenuItem(value: 'TUC', child: Text('TUC - Tucuruvi')),
            DropdownMenuItem(value: 'LUM', child: Text('LUM - Luminárias')),
            DropdownMenuItem(value: 'IMG', child: Text('IMG - Imigrantes')),
            DropdownMenuItem(value: 'BFU', child: Text('BFU - Barra Funda')),
            DropdownMenuItem(value: 'BAS', child: Text('BAS - Brás')),
            DropdownMenuItem(value: 'CEC', child: Text('CEC - Cecília')),
            DropdownMenuItem(value: 'MAT', child: Text('MAT - Matheus')),
            DropdownMenuItem(value: 'VTD', child: Text('VTD - Vila Matilde')),
            DropdownMenuItem(value: 'VPT', child: Text('VPT – Vila Prudente')),
            DropdownMenuItem(value: 'PIT', child: Text('PIT – Pátio Itaquera')),
            DropdownMenuItem(value: 'POT', child: Text('POT – Pátio Oratório')),
            DropdownMenuItem(
              value: 'PAT',
              child: Text('PAT – Pátio Jabaquara'),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedBase = value);
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _clearFilters();
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
                  _applyFilters();
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

  // ---------- CARD GERAR RELATÓRIO ----------

  Widget _buildReportSection() {
    return Stack(
      children: [
        _buildReportCard(),
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              onTap: _openFilterDialog,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.filter_list, color: metroBlue),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard() {
    int totalItems = _filteredData.length;
    int totalSaidas = _filteredData
        .where((r) => r['quantidade'] < 0)
        .fold(0, (prev, r) => prev + (r['quantidade'] as int).abs());
    int totalEntradas = _filteredData
        .where((r) => r['quantidade'] > 0)
        .fold(0, (prev, r) => prev + (r['quantidade'] as int));

    totalItems;
    totalSaidas;
    totalEntradas;

    final ButtonStyle exportButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.grey.shade200,
      foregroundColor: Colors.black87,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerar Relatório',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: metroBlue,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Escolha o tipo de relatório para ser gerado:',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _reportTypeButton('Movimentações por Usuário', Icons.person),
                _reportTypeButton('Movimentação Geral', Icons.all_inclusive),
              ],
            ),

            // 🔹 Dropdown só aparece nesse tipo de relatório
            if (_selectedReportType == 'Movimentações por Usuário') ...[
              const SizedBox(height: 16),
              const Text(
                'Selecione o usuário:',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedUser,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'Escolha um usuário',
                ),
                // monta a lista de usuários únicos a partir das movimentações
                items:
                    (_allMovimentacoes
                            .map((e) => e.usuario)
                            .where((u) => u != 'N/A')
                            .toSet()
                            .toList()
                          ..sort())
                        .map(
                          (user) =>
                              DropdownMenuItem(value: user, child: Text(user)),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUser = value;
                  });
                  _applyFilters(); // reaplica filtros já considerando o usuário
                },
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  style: exportButtonStyle,
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Exportar PDF'),
                ),
                ElevatedButton.icon(
                  style: exportButtonStyle,
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Exportar Excel'),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _reportTypeButton(String label, IconData icon) {
    final bool isSelected = _selectedReportType == label;

    return ChoiceChip(
      showCheckmark: false,
      selected: isSelected,
      selectedColor: metroBlue,
      backgroundColor: Colors.grey.shade100,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : metroBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      onSelected: (_) {
        setState(() {
          _selectedReportType = label;
          _selectedUser = null;
          _filteredData = _convertMovimentacoesToMap(_allMovimentacoes);
        });
        _applyFilters();
      },
    );
  }

  // ---------- RESULTADOS (TABELA) ----------

  Widget _buildResultsCard({required bool hasBoundedHeight}) {
    List<DataRow> _buildDataRows() {
      if (_filteredData.isEmpty) return [];

      return _filteredData.map((row) {
        final DateTime data = row['data'];
        final String dataFormatada = "${data.day}/${data.month}/${data.year}";
        final bool isSaida = row['quantidade'] < 0;

        return DataRow(
          cells: [
            DataCell(Text(row['codigo'] ?? '—')),
            DataCell(Text(dataFormatada)),
            DataCell(Text(row['item'])),
            DataCell(Text(row['categoria'])),
            DataCell(
              Text(
                row['quantidade'].toString(),
                style: TextStyle(
                  color: isSaida ? Colors.red : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DataCell(Text(row['base'])),
            DataCell(Text(row['usuario'])),
          ],
        );
      }).toList();
    }

    Widget tabelaWidget = SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 500),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(
                label: Text(
                  'Código',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Data',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Item',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Categoria',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Quantidade',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Base',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Usuário',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: _buildDataRows(),
          ),
        ),
      ),
    );

    Widget loadingWidget = const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );

    Widget noResultsWidget = const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Nenhum resultado encontrado.\nAjuste os filtros e tente novamente.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );

    final Widget dataWidget = _isLoading
        ? loadingWidget
        : (_filteredData.isEmpty ? noResultsWidget : tabelaWidget);

    Widget _buildDataSection() {
      if (hasBoundedHeight) {
        return Expanded(child: dataWidget);
      }
      return SizedBox(height: 320, child: dataWidget);
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.bar_chart_rounded, color: metroBlue),
              title: const Text(
                'Resultados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            _buildDataSection(),
          ],
        ),
      ),
    );
  }

  void _zoomMap(bool zoomIn) {
    if (!_isMapReady) return;
    final double targetZoom = (zoomIn ? _latestZoom + 0.5 : _latestZoom - 0.5)
        .clamp(5.0, 18.0);
    _mapController.move(_latestCenter, targetZoom);
  }

  void _resetMapView() {
    if (!_isMapReady) return;
    _mapController.move(_mapDefaultCenter, _mapDefaultZoom);
  }

  void _fitMapToPoints(List<LatLng> points) {
    if (!_isMapReady) return;
    if (points.isEmpty) {
      _resetMapView();
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 13);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32)),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icon, color: metroBlue),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopReportsLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildReportSection(),
              const SizedBox(height: 16),
              Expanded(child: _buildResultsCard(hasBoundedHeight: true)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _buildMapCard()),
      ],
    );
  }

  Widget _buildMobileReportsLayout() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildReportSection(),
          const SizedBox(height: 16),
          _buildResultsCard(hasBoundedHeight: false),
          const SizedBox(height: 16),
          _buildMapCard(isCompact: true),
        ],
      ),
    );
  }

  // ---------- MAPA ----------

  Widget _buildMapCard({bool isCompact = false}) {
    final Map<String, LatLng> baseCoordinates = {
      'WJA': LatLng(-23.6434, -46.6415),
      'PSO': LatLng(-23.5733, -46.6401),
      'TUC': LatLng(-23.4851, -46.6126),
      'TRD': LatLng(-23.5505, -46.6333),
      'BFU': LatLng(-23.5261, -46.6672),
    };

    final usedBases = _filteredData.map((e) => e['base_id'] as String).toSet();
    final List<LatLng> basePoints = usedBases
        .map((base) => baseCoordinates[base] ?? _mapDefaultCenter)
        .toList();

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.map, color: metroBlue),
                const SizedBox(width: 8),
                Text(
                  'Mapa de Desempenho — São Paulo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: metroBlue,
                  ),
                ),
              ],
            ),
          ),
          if (isCompact)
            SizedBox(
              height: 360,
              child: _buildMapStack(baseCoordinates, usedBases, basePoints),
            )
          else
            Expanded(
              child: _buildMapStack(baseCoordinates, usedBases, basePoints),
            ),
        ],
      ),
    );
  }

  Widget _buildMapStack(
    Map<String, LatLng> baseCoordinates,
    Set<String> usedBases,
    List<LatLng> basePoints,
  ) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _mapDefaultCenter,
            initialZoom: _mapDefaultZoom,
            onMapReady: () {
              _isMapReady = true;
              _latestCenter = _mapDefaultCenter;
              _latestZoom = _mapDefaultZoom;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: usedBases.map((base) {
                final coord = baseCoordinates[base] ?? _mapDefaultCenter;
                return Marker(
                  point: coord,
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () => _showBaseDetails(base),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 36,
                          color: Colors.red,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            base,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapControlButton(
                icon: Icons.add,
                tooltip: 'Aproximar',
                onPressed: () => _zoomMap(true),
              ),
              const SizedBox(height: 8),
              _buildMapControlButton(
                icon: Icons.remove,
                tooltip: 'Afastar',
                onPressed: () => _zoomMap(false),
              ),
              const SizedBox(height: 8),
              _buildMapControlButton(
                icon: Icons.center_focus_strong,
                tooltip: 'Centralizar São Paulo',
                onPressed: _resetMapView,
              ),
              if (basePoints.length > 1) ...[
                const SizedBox(height: 8),
                _buildMapControlButton(
                  icon: Icons.zoom_out_map,
                  tooltip: 'Enquadrar bases',
                  onPressed: () => _fitMapToPoints(basePoints),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showBaseDetails(String base) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Base $base'),
        content: Text('Informações e métricas da base $base (placeholder).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
