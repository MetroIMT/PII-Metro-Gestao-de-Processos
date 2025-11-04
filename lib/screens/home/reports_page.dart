import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../services/pdf_service.dart';
import '../../services/excel_service.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({super.key});

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage>
    with SingleTickerProviderStateMixin {
      
  // --- Lógica da Sidebar (sem alterações) ---
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
    _filteredData = _allData; // Carrega todos os dados ao iniciar
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
  // --- Fim da Lógica da Sidebar ---

  // --- Estado da Página de Relatórios ---
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCategory; 
  String? _selectedSubCategory; 
  String? _selectedBase;

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  final Color backgroundColor = const Color(0xFFF4F5FA);
  final Color metroBlue = const Color(0xFF001489);

  // --- LÓGICA DE FILTRO ---
  
  // ATUALIZADO: Mock data com novas categorias, sub-categorias e bases
  final List<Map<String, dynamic>> _allData = [
    {
      'data': DateTime(2025, 10, 21),
      'item': 'Cabo Elétrico',
      'categoria_id': 'consumo',
      'categoria': 'Material de Consumo',
      'sub_categoria_id': null,
      'quantidade': -5,
      'usuario': 'João Pereira',
      'base_id': 'WJA' // WJA - Jabaquara
    },
    {
      'data': DateTime(2025, 10, 22),
      'item': 'Multímetro XYZ',
      'categoria_id': 'patrimoniado',
      'categoria': 'Material Patrimoniado',
      'sub_categoria_id': 'instrumento',
      'quantidade': 1,
      'usuario': 'Ana Silva',
      'base_id': 'PSO' // PSO - Paraiso
    },
    {
      'data': DateTime(2025, 10, 23),
      'item': 'Rolamento 6203',
      'categoria_id': 'giro',
      'categoria': 'Material de Giro',
      'sub_categoria_id': null,
      'quantidade': -20,
      'usuario': 'Carlos Souza',
      'base_id': 'WJA' // WJA - Jabaquara
    },
    {
      'data': DateTime(2025, 10, 24),
      'item': 'Furadeira 220V',
      'categoria_id': 'patrimoniado',
      'categoria': 'Material Patrimoniado',
      'sub_categoria_id': 'ferramenta',
      'quantidade': 1,
      'usuario': 'Ana Silva',
      'base_id': 'TUC' // TUC - Tucuruvi
    },
  ];

  // Lista que será exibida na tela
  List<Map<String, dynamic>> _filteredData = [];

  /// ATUALIZADO: Aplica todos os filtros
  void _applyFilters() {
    List<Map<String, dynamic>> tempResults = _allData;

    // 1. Filtro de Data (CORRIGIDO)
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

    // 2. Filtro de Categoria
    if (_selectedCategory != null) {
      tempResults = tempResults.where((row) {
        return row['categoria_id'] == _selectedCategory;
      }).toList();

      // 3. Filtro de Sub-categoria (CONDICIONAL)
      if (_selectedCategory == 'patrimoniado' && _selectedSubCategory != null) {
        tempResults = tempResults.where((row) {
          return row['sub_categoria_id'] == _selectedSubCategory;
        }).toList();
      }
    }
    
    // 4. Filtro de Base
    if (_selectedBase != null) {
      tempResults = tempResults.where((row) {
        return row['base_id'] == _selectedBase;
      }).toList();
    }

    setState(() {
      _filteredData = tempResults;
    });
  }

  /// ATUALIZADO: Limpa todos os filtros
  void _clearFilters() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedCategory = null;
      _selectedSubCategory = null; 
      _selectedBase = null;
      _startDateController.clear();
      _endDateController.clear();
      
      _filteredData = _allData; // Reseta a lista
    });
  }

  /// Helper para mostrar snackbar de erro
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Valida se a lista de dados filtrada não está vazia
  bool _canGenerateReport() {
    if (_filteredData.isEmpty) {
      _showErrorSnackBar('Não há dados para gerar o relatório');
      return false;
    }
    return true;
  }
  
  // CORREÇÃO: Funções de Data seguras (à prova de lista vazia)
  DateTime _getStartDate() {
    return _selectedStartDate ?? (_filteredData.isNotEmpty ? _filteredData.first['data'] : DateTime.now());
  }
  DateTime _getEndDate() {
    return _selectedEndDate ?? (_filteredData.isNotEmpty ? _filteredData.last['data'] : DateTime.now());
  }


  /// Ação de exportar PDF (corrigida)
  Future<void> _exportPdf() async {
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

  /// Ação de exportar Excel (corrigida)
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                                _isRailExtended
                                    ? Icons.menu_open
                                    : Icons.menu,
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
                Padding(
                  padding: EdgeInsets.fromLTRB(16, isMobile ? 16 : 0, 16, 16),
                  child: const Text(
                    'Gere e exporte relatórios personalizados sobre materiais, instrumentos e históricos de movimentação.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isNarrow = constraints.maxWidth < 700;

                        if (isNarrow) {
                          // MOBILE: Um SingleChildScrollView para a página inteira
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildFilterCard(),
                                const SizedBox(height: 16),
                                _buildResultsCard(hasBoundedHeight: false), // Mobile
                              ],
                            ),
                          );
                        } else {
                          // DESKTOP: Uma Row com Filtros (rolável) e Resultados (fixo)
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1, 
                                // Permite que os filtros rolem se a tela for muito baixa
                                child: SingleChildScrollView( 
                                  child: _buildFilterCard()
                                )
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2, 
                                child: _buildResultsCard(hasBoundedHeight: true) // Desktop
                              ),
                            ],
                          );
                        }
                      },
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

  /// Card de Filtros (ATUALIZADO E CORRIGIDO)
  Widget _buildFilterCard() {
    return Card(
      elevation: 2,
      color: Colors.white, // Fundo branco
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Removido o SingleChildScrollView daqui
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Importante para o scroll do desktop
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.filter_list_rounded, color: metroBlue),
                title: const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // Data Inicial
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
                    // CORREÇÃO 1.1: Limita a data inicial pela data final
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
              const SizedBox(height: 16),

              // Data Final
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
                  // CORREÇÃO 1.2: Garante que o seletor não abra em data inválida
                  final DateTime firstDate = _selectedStartDate ?? DateTime(2000);
                  DateTime initialDate = _selectedEndDate ?? DateTime.now();
                  
                  // Se a data inicial do picker for anterior à data mínima, ajusta ela
                  if (initialDate.isBefore(firstDate)) {
                    initialDate = firstDate;
                  }

                  final date = await showDatePicker(
                    context: context,
                    initialDate: initialDate, // <-- CORRIGIDO
                    firstDate: firstDate,     // <-- CORRIGIDO
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
              
              const SizedBox(height: 16),

              // ATUALIZADO: Filtro de Categoria
              const Text('Categoria'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white, // <-- CORREÇÃO 2: Fundo branco
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
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubCategory = null; 
                  });
                },
              ),
              
              // NOVO: Filtro Condicional de Sub-Categoria
              if (_selectedCategory == 'patrimoniado') ...[
                const SizedBox(height: 16),
                const Text('Sub-categoria (Patrimoniado)'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white, // <-- CORREÇÃO 2: Fundo branco
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
              
              const SizedBox(height: 16),

              // ATUALIZADO: Filtro de Base
              const Text('Base de manutenção'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                dropdownColor: Colors.white, // <-- CORREÇÃO 2: Fundo branco
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
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.filter_alt_rounded, size: 18),
                      label: const Text('Aplicar Filtros'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: metroBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }

  /// Card de Resultados (FUNCIONAL e CORRIGIDO)
  Widget _buildResultsCard({required bool hasBoundedHeight}) {
    
    // Helper para construir as linhas da tabela dinamicamente
    List<DataRow> _buildDataRows() {
      if (_filteredData.isEmpty) return [];
      
      return _filteredData.map((row) {
        final DateTime data = row['data'];
        final String dataFormatada = "${data.day}/${data.month}/${data.year}";
        final bool isSaida = row['quantidade'] < 0;

        return DataRow(
          cells: [
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

    // O widget da tabela
    Widget tabelaWidget = SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 500), 
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
            columns: const [
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Item')),
              DataColumn(label: Text('Categoria')),
              DataColumn(label: Text('Qntd')),
              DataColumn(label: Text('Usuário')),
            ],
            rows: _buildDataRows(), 
          ),
        ),
      ),
    );
    
    // Widget de "Nenhum resultado"
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

    return Card(
      elevation: 2,
      color: Colors.white, // Fundo branco
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
              trailing: Wrap(
                spacing: 8,
                runSpacing: 8, 
                children: [
                  OutlinedButton.icon(
                    onPressed: _exportPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300), 
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportExcel,
                    icon: const Icon(Icons.table_chart_outlined, size: 18),
                    label: const Text('Excel'),
                     style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green.shade800,
                      side: BorderSide(color: Colors.green.shade300),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // CORREÇÃO: Esta é a lógica de layout que corrige o erro
            if (hasBoundedHeight)
              // Desktop: A tabela deve expandir para preencher o card
              Expanded(
                child: _filteredData.isEmpty ? noResultsWidget : tabelaWidget,
              )
            else
              // Mobile: A tabela não expande (deixa o SingleChildScrollView da página rolar)
              _filteredData.isEmpty ? noResultsWidget : tabelaWidget,

          ],
        ),
      ),
    );
  }
}