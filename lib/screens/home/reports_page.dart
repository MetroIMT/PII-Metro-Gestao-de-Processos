import 'dart:math';

import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/pdf_service.dart';
import '../../services/excel_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


/// Página de Relatórios — versão atualizada do layout de filtro.
/// Desta vez o filtro abre como um diálogo compacto (desktop) ou bottom sheet (mobile),
/// em vez de um overlay large que cobria o conteúdo.

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage>
    with SingleTickerProviderStateMixin {
  // --- Sidebar ---
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _filteredData = List<Map<String, dynamic>>.from(_allData);
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  // --- Estado da Página ---
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCategory;
  String? _selectedSubCategory;
  String? _selectedBase;


  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  final Color backgroundColor = const Color(0xFFFFFFFF); // branco em hex
  final Color metroBlue = const Color(0xFF001489);

  // Mock data para simulação
  final List<Map<String, dynamic>> _allData = [
    {
      'codigo': 'ITM-00123',
      'data': DateTime(2025, 10, 21),
      'item': 'Cabo Elétrico',
      'categoria_id': 'consumo',
      'categoria': 'Material de Consumo',
      'sub_categoria_id': null,
      'quantidade': -5,
      'usuario': 'João Pereira',
      'base_id': 'WJA'
    },
    {
      'codigo': 'ITM-00234',
      'data': DateTime(2025, 10, 22),
      'item': 'Multímetro XYZ',
      'categoria_id': 'patrimoniado',
      'categoria': 'Material Patrimoniado',
      'sub_categoria_id': 'instrumento',
      'quantidade': 1,
      'usuario': 'Ana Silva',
      'base_id': 'PSO'
    },
    {
      'codigo': 'ITM-00345',
      'data': DateTime(2025, 10, 23),
      'item': 'Rolamento 6203',
      'categoria_id': 'giro',
      'categoria': 'Material de Giro',
      'sub_categoria_id': null,
      'quantidade': -20,
      'usuario': 'Carlos Souza',
      'base_id': 'WJA'
    },
    {
      'codigo': 'ITM-00456',
      'data': DateTime(2025, 10, 24),
      'item': 'Furadeira 220V',
      'categoria_id': 'patrimoniado',
      'categoria': 'Material Patrimoniado',
      'sub_categoria_id': 'ferramenta',
      'quantidade': 1,
      'usuario': 'Ana Silva',
      'base_id': 'TUC'
    },
  ];

  // Lista final que será exibida na tabela.
  List<Map<String, dynamic>> _filteredData = [];

  /// Aplica todos os filtros e atualiza a `_filteredData`.
  void _applyFilters() {
    List<Map<String, dynamic>> tempResults = List<Map<String, dynamic>>.from(_allData);

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

  /// Limpa todos os filtros e reseta a lista para os dados originais.
  void _clearFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedCategory = null;
      _selectedSubCategory = null;
      _selectedBase = null;
      _startDateController.clear();
      _endDateController.clear();
      _filteredData = List<Map<String, dynamic>>.from(_allData);
    });
  }

  /// Exibe uma SnackBar de erro.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Valida se a lista de dados não está vazia antes de gerar um relatório.
  bool _canGenerateReport() {
    if (_filteredData.isEmpty) {
      _showErrorSnackBar('Não há dados para gerar o relatório');
      return false;
    }
    return true;
  }

  DateTime _getStartDate() {
    return _selectedStartDate ?? (_filteredData.isNotEmpty ? _filteredData.first['data'] : DateTime.now());
  }

  DateTime _getEndDate() {
    return _selectedEndDate ?? (_filteredData.isNotEmpty ? _filteredData.last['data'] : DateTime.now());
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
        'usuario': row['usuario'].toString(),
      };
    }).toList();

    try {
      await PdfService.generateReport(
        title: 'Movimentação de Itens',
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
        'usuario': row['usuario'].toString(),
      };
    }).toList();

    try {
      await ExcelService.generateReport(
        title: 'Movimentação de Itens',
        data: exportData,
        startDate: _getStartDate(),
        endDate: _getEndDate(),
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Erro ao gerar Excel: ${e.toString()}');
    }
  }

  // Abre o diálogo de filtros: em desktop usa AlertDialog (compacto), em mobile usa bottom sheet.
  Future<void> _openFilterDialog() async {
    final isMobile = MediaQuery.of(context).size.width < 900;

    if (isMobile) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
          insetPadding: const EdgeInsets.symmetric(horizontal: 120.0, vertical: 40.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                style: TextStyle(
                  color: metroBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                    padding: const EdgeInsets.all(16.0),
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
                        Image.asset('assets/LogoMetro.png', height: 40),
                      ],
                    ),
                  ),

                // Conteúdo: duas colunas (esquerda: relatórios/resultados; direita: mapa)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Row(
                        children: [
                          // Esquerda
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Report card com botão de filtro compacto
                                Stack(
                                  children: [
                                    _buildReportCard(),

                                    // Botão de filtro compacto — abre dialog/bottom sheet
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Material(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        child: InkWell(
                                          onTap: _openFilterDialog,
                                          borderRadius: BorderRadius.circular(10),
                                          child: Container(
                                            width: 44,
                                            height: 44,
                                            padding: const EdgeInsets.all(8),
                                            child: Icon(Icons.filter_list, color: metroBlue),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                Expanded(child: _buildResultsCard(hasBoundedHeight: true)),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Direita: mapa
                          Expanded(flex: 1, child: _buildMapCard()),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card de filtros (conteúdo reutilizável). Se closeButton=true mostra X interno.
  Widget _buildFilterCardContents({bool closeButton = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.filter_list_rounded, color: metroBlue),
            const SizedBox(width: 8),
            Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: metroBlue)),
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
            );
            if (date != null) {
              setState(() {
                _selectedStartDate = date;
                _startDateController.text = "${date.day}/${date.month}/${date.year}";
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
            );
            if (date != null) {
              setState(() {
                _selectedEndDate = date;
                _endDateController.text = "${date.day}/${date.month}/${date.year}";
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
            DropdownMenuItem(value: 'consumo', child: Text('Material de Consumo')),
            DropdownMenuItem(value: 'patrimoniado', child: Text('Material Patrimoniado')),
          ],
          onChanged: (value) async {
            setState(() {
              _selectedCategory = value;
              _selectedSubCategory = null;
            });

            if (value == 'patrimoniado') {
              final isMobile = MediaQuery.of(context).size.width < 900;
              String? result;

              if (isMobile) {
                result = await showModalBottomSheet<String>(
                  context: context,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ListTile(title: Text('Sub-categoria (Patrimoniado)')),
                        ListTile(
                          title: const Text('Ferramenta'),
                          onTap: () => Navigator.pop(context, 'ferramenta'),
                        ),
                        ListTile(
                          title: const Text('Instrumento'),
                          onTap: () => Navigator.pop(context, 'instrumento'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              } else {
                result = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Sub-categoria (Patrimoniado)'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'ferramenta'),
                        child: const Text('Ferramenta'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'instrumento'),
                        child: const Text('Instrumento'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, null),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              }

              if (result != null) {
                setState(() {
                  _selectedSubCategory = result;
                });
              }
            }
          },
        ),

        if (_selectedCategory == 'patrimoniado') ...[
          const SizedBox(height: 12),
          const Text('Sub-categoria (Patrimoniado)'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            dropdownColor: Colors.white,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Selecione a sub-categoria',
              prefixIcon: Icon(Icons.build_circle_outlined),
            ),
            value: _selectedSubCategory,
            items: const [
              DropdownMenuItem(value: 'ferramenta', child: Text('Ferramenta')),
              DropdownMenuItem(value: 'instrumento', child: Text('Instrumento')),
            ],
            onChanged: (value) {
              setState(() => _selectedSubCategory = value);
            },
          ),
        ],

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
            DropdownMenuItem(value: 'PAT', child: Text('PAT – Pátio Jabaquara')),
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
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
                child: const Text('Limpar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _applyFilters();
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card que contém geração de relatório, botoes export e informações resumidas.
  Widget _buildReportCard() {
    int totalItems = _filteredData.length;
    int totalSaidas = _filteredData.where((r) => r['quantidade'] < 0).fold(0, (prev, r) => prev + (r['quantidade'] as int).abs());
    int totalEntradas = _filteredData.where((r) => r['quantidade'] > 0).fold(0, (prev, r) => prev + (r['quantidade'] as int));

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gerar Relatório', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: metroBlue)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Exportar PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: _exportExcel,
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Exportar Excel'),
                ),
                OutlinedButton(
                  onPressed: () {
                    _showErrorSnackBar('Funcionalidade de agendamento ainda não implementada.');
                  },
                  child: const Text('Agendar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _smallInfoTile('Linhas', totalItems.toString()),
                _smallInfoTile('Entradas', totalEntradas.toString()),
                _smallInfoTile('Saídas', totalSaidas.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallInfoTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  /// Card de resultados (tabela)
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
              DataColumn(label: Text('Código')),
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Item')),
              DataColumn(label: Text('Categoria')),
              DataColumn(label: Text('Quantidade')),
              DataColumn(label: Text('Usuário')),
            ],
            rows: _buildDataRows(),
          ),
        ),
      ),
    );

    Widget noResultsWidget = Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: const Text(
                                        'Nenhum resultado encontrado.\nAjuste os filtros e tente novamente.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 255, 255, 255)),
                                      ),
                                    ),
                                  );


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
              title: const Text('Resultados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(child: _filteredData.isEmpty ? noResultsWidget : tabelaWidget),
          ],
        ),
      ),
    );
  }

  /// Card do mapa com fallback para asset ausente.
  /// Card do mapa interativo (usando OpenStreetMap via flutter_map)
  Widget _buildMapCard() {
  final Map<String, LatLng> baseCoordinates = {
    'WJA': LatLng(-23.6434, -46.6415), // Jabaquara
    'PSO': LatLng(-23.5733, -46.6401), // Paraiso
    'TUC': LatLng(-23.4851, -46.6126), // Tucuruvi
    'TRD': LatLng(-23.5505, -46.6333), // Tiradentes (centro)
    'BFU': LatLng(-23.5261, -46.6672), // Barra Funda
  };

  final usedBases = _allData.map((e) => e['base_id'] as String).toSet();

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
              const Icon(Icons.map, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Mapa de Desempenho — São Paulo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  _showErrorSnackBar('Abrir mapa em tela cheia (não implementado)');
                },
                icon: const Icon(Icons.open_in_full),
                label: const Text('Tela cheia'),
              )
            ],
          ),
        ),

        // --- Mapa interativo ---
        Expanded(
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(-23.55, -46.63), // novo nome
              initialZoom: 11.0, // novo nome
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: usedBases.map((base) {
                  final coord = baseCoordinates[base] ?? const LatLng(-23.55, -46.63);
                  return Marker(
                    point: coord,
                    width: 80,
                    height: 80,
                    child: GestureDetector(
                      onTap: () => _showBaseDetails(base),
                      child: Column(
                        children: [
                          const Icon(Icons.location_on, size: 36, color: Colors.red),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: Text(base, style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList().cast<Marker>(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  void _showBaseDetails(String base) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Base $base'),
        content: Text('Informações e métricas da base $base (placeholder).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        ],
      ),
    );
  }
}
