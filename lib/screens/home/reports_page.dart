import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart'; 
import '../../services/pdf_service.dart';  
import '../../services/excel_service.dart';



class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({Key? key}) : super(key: key);

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}


class _RelatoriosPageState extends State<RelatoriosPage>
    with SingleTickerProviderStateMixin {

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
  }

  @override
  void dispose() {
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


  // Variáveis de estado originais da página de Relatórios
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedItemType;
  String? _selectedBase;
  final Color backgroundColor = const Color(0xFFF4F5FA); 

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
                  color: const Color(0xFF001489),
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              title: const Text(
                'Relatórios', 
                style: TextStyle(
                  color: Color(0xFF001489),
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
          ? Drawer(
              child: Sidebar(
                expanded: true,
                selectedIndex: 3, 
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
                selectedIndex: 3, 
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
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isRailExtended ? Icons.menu_open : Icons.menu,
                                color: const Color(0xFF001489),
                              ),
                              onPressed: _toggleRail,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Relatórios',
                              style: TextStyle(
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
                          
                          return SingleChildScrollView(
                            child: Column(
                              children: [
                                _buildFilterCard(),
                                const SizedBox(height: 16),
                                _buildResultsCard(),
                              ],
                            ),
                          );
                        } else {
                          
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 1, child: _buildFilterCard()),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildResultsCard()),
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


  Widget _buildFilterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Para não esticar verticalmente
            children: [
              const Text(
                'Filtros',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Período'),

              TextFormField(
                
                controller: TextEditingController(
                  text: _selectedStartDate == null
                      ? ''
                      : "${_selectedStartDate!.day}/${_selectedStartDate!.month}/${_selectedStartDate!.year}",
                ),
                readOnly: true,
                decoration: const InputDecoration(
                  hintText: 'Data inicial',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _selectedStartDate = date);
                  }
                },
              ),

              const SizedBox(height: 16),
            TextFormField(

              controller: TextEditingController(
              text: _selectedEndDate == null
                  ? ''
                  : "${_selectedEndDate!.day}/${_selectedEndDate!.month}/${_selectedEndDate!.year}",
            ),
              readOnly: true,
              decoration: const InputDecoration(
              hintText: 'Data final',
              suffixIcon: Icon(Icons.calendar_today),
            ),
              onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                setState(() => _selectedEndDate = date);
              }
            },
          ),
              
              const SizedBox(height: 16),
              const Text('Tipos de Item'),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione o tipo'),
                value: _selectedItemType,
                items: const [
                  DropdownMenuItem(value: 'material', child: Text('Material')),
                  DropdownMenuItem(
                    value: 'instrumento',
                    child: Text('Instrumento'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedItemType = value);
                },
              ),
              const SizedBox(height: 16),
              const Text('Base de manutenção'),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                hint: const Text('Selecione a base'),
                value: _selectedBase,
                items: const [
                  DropdownMenuItem(value: 'base1', child: Text('Base 1')),
                  DropdownMenuItem(value: 'base2', child: Text('Base 2')),
                ],
                onChanged: (value) {
                  setState(() => _selectedBase = value);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    
                  },
                  child: const Text('Aplicar filtro'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildResultsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botões de Ação
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_selectedStartDate == null || _selectedEndDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione um período para gerar o relatório'),
                        ),
                      );
                      return;
                    }

                    // Exemplo de dados - substitua pelos dados reais da sua tabela
                    final dados = [
                      {
                        'data': '27/10/2025',
                        'item': 'Cabo Elétrico',
                        'categoria': 'Material',
                        'quantidade': '-5',
                        'usuario': 'João Pereira',
                      },
                      {
                        'data': '26/10/2025',
                        'item': 'Multímetro XYZ',
                        'categoria': 'Instrumento',
                        'quantidade': '1',
                        'usuario': 'Ana Silva',
                      },
                      {
                        'data': '25/10/2025',
                        'item': 'Parafuso ABC',
                        'categoria': 'Material',
                        'quantidade': '-20',
                        'usuario': 'Carlos Souza',
                      },
                      {
                        'data': '24/10/2025',
                        'item': 'Chave de Fenda',
                        'categoria': 'Instrumento',
                        'quantidade': '2',
                        'usuario': 'Mariana Lima',
                      },
                      {
                        'data': '23/10/2025',
                        'item': 'Fita Isolante',
                        'categoria': 'Material',
                        'quantidade': '-10',
                        'usuario': 'Pedro Alves',
                      },
                    ];

                    try {
                      await PdfService.generateReport(
                        title: 'Movimentação de Itens',
                        data: dados,
                        startDate: _selectedStartDate!,
                        endDate: _selectedEndDate!,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao gerar PDF: ${e.toString()}')),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Exportar PDF'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (_selectedStartDate == null || _selectedEndDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecione um período para gerar o relatório'),
                          ),
                        );
                        return;
                      }

                      final dados = [
                        {
                          'data': '27/10/2025',
                          'item': 'Cabo Elétrico',
                          'categoria': 'Material',
                          'quantidade': '-5',
                          'usuario': 'João Pereira',
                        },
                        {
                          'data': '26/10/2025',
                          'item': 'Multímetro XYZ',
                          'categoria': 'Instrumento',
                          'quantidade': '1',
                          'usuario': 'Ana Silva',
                        },
                        {
                          'data': '25/10/2025',
                          'item': 'Parafuso ABC',
                          'categoria': 'Material',
                          'quantidade': '-20',
                          'usuario': 'Carlos Souza',
                        },
                        {
                          'data': '24/10/2025',
                          'item': 'Chave de Fenda',
                          'categoria': 'Instrumento',
                          'quantidade': '2',
                          'usuario': 'Mariana Lima',
                        },
                        {
                          'data': '23/10/2025',
                          'item': 'Fita Isolante',
                          'categoria': 'Material',
                          'quantidade': '-10',
                          'usuario': 'Pedro Alves',
                        },
                      ];

                      try {
                        await ExcelService.generateReport(
                          title: 'Movimentação de Itens',
                          data: dados,
                          startDate: _selectedStartDate!,
                          endDate: _selectedEndDate!,
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecione um período para gerar o relatório'),
                          ),
                        );
                      }
                  },
                  icon: const Icon(Icons.table_chart, size: 18),
                  label: const Text('Exportar EXCEL'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Imprimir
                  },
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Imprimir'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Tabela de Dados
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Data')),
                      DataColumn(label: Text('Item')),
                      DataColumn(label: Text('Categoria')),
                      DataColumn(label: Text('Qntd')),
                      DataColumn(label: Text('Usuário')),
                    ],
                    rows: const [
                      // Exemplo de linha, substitua por seus dados
                      DataRow(
                        cells: [
                          DataCell(Text('21/10/2025')),
                          DataCell(Text('Cabo Elétrico')),
                          DataCell(Text('Material')),
                          DataCell(Text('-5')),
                          DataCell(Text('João Pereira')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('22/10/2025')),
                          DataCell(Text('Multímetro XYZ')),
                          DataCell(Text('Instrumento')),
                          DataCell(Text('1')),
                          DataCell(Text('Ana Silva')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('22/10/2025')),
                          DataCell(Text('Parafuso ABC')),
                          DataCell(Text('Material')),
                          DataCell(Text('-20')),
                          DataCell(Text('Carlos Souza')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('24/10/2025')),
                          DataCell(Text('Chave de Fenda')),
                          DataCell(Text('Instrumento')),
                          DataCell(Text('2')),
                          DataCell(Text('Mariana Lima')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('25/10/2025')),
                          DataCell(Text('Fita Isolante')),
                          DataCell(Text('Material')),
                          DataCell(Text('-10')),
                          DataCell(Text('Pedro Alves')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
