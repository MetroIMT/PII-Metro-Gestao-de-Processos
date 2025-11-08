import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/movimentacao.dart';
import '../../repositories/movimentacao_repository.dart';
import '../../widgets/sidebar.dart';

class MovimentacoesPage extends StatefulWidget {
  const MovimentacoesPage({super.key});

  @override
  State<MovimentacoesPage> createState() => _MovimentacoesPageState();
}

class _MovimentacoesPageState extends State<MovimentacoesPage>
    with SingleTickerProviderStateMixin {
  // --- Sidebar ---
  String? _filterTipo;
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late List<Movimentacao> _movimentacoes;
  List<Movimentacao> _filteredMovimentacoes = [];
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();

  final Color backgroundColor = const Color.fromARGB(255, 255, 255, 255);
  final Color metroBlue = const Color(0xFF001489);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _movimentacoes = MovimentacaoRepository.instance.getMovimentacoes();
    _filteredMovimentacoes = _movimentacoes;

    MovimentacaoRepository.instance.movimentacoesNotifier.addListener(
      _updateMovimentacoes,
    );

    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
        _filterMovimentacoes();
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    MovimentacaoRepository.instance.movimentacoesNotifier.removeListener(
      _updateMovimentacoes,
    );
    _searchController.dispose();
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
    if (mounted) {
      setState(() {
        _movimentacoes = MovimentacaoRepository.instance.getMovimentacoes();
        _filterMovimentacoes();
      });
    }
  }

  void _filterMovimentacoes() {
    _filteredMovimentacoes = _movimentacoes.where((mov) {
      final term = _searchTerm.toLowerCase();

      final matchesSearch =
          term.isEmpty ||
          mov.descricao.toLowerCase().contains(term) ||
          mov.codigoMaterial.toLowerCase().contains(term) ||
          mov.tipo.toLowerCase().contains(term) ||
          mov.usuario.toLowerCase().contains(term) ||
          mov.local.toLowerCase().contains(term);

      final matchesTipo = _filterTipo == null || mov.tipo == _filterTipo;

      return matchesSearch && matchesTipo;
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
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 2))
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
              child: Sidebar(expanded: _isRailExtended, selectedIndex: 2),
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
                        Image.asset('assets/LogoMetro.png', height: 40),
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
                        if (isMobile)
                          Text(
                            'Histórico de Movimentações',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: metroBlue,
                                ),
                          ),
                        if (isMobile) const SizedBox(height: 8),
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
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar movimentação...',
                hintText: 'Digite o nome, código, tipo, usuário ou local',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (v) => setState(() {
                _searchTerm = v;
                _filterMovimentacoes();
              }),
            ),

            const SizedBox(height: 12),

            // 🔹 FILTRO DE ENTRADA / SAÍDA / TODOS
            // 🔹 FILTRO DE ENTRADA / SAÍDA / TODOS (estilo refinado)
            Row(
              mainAxisAlignment: MainAxisAlignment.start, // alinha à esquerda
              children: [
                ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filterTipo == null,
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  labelStyle: TextStyle(
                    color: _filterTipo == null ? Colors.blue : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _filterTipo = null;
                      _filterMovimentacoes();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Entradas'),
                  selected: _filterTipo == 'Entrada',
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  labelStyle: TextStyle(
                    color: _filterTipo == 'Entrada'
                        ? Colors.green
                        : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _filterTipo = 'Entrada';
                      _filterMovimentacoes();
                    });
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Saídas'),
                  selected: _filterTipo == 'Saída',
                  selectedColor: Colors.white,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.grey),
                  labelStyle: TextStyle(
                    color: _filterTipo == 'Saída' ? Colors.red : Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _filterTipo = 'Saída';
                      _filterMovimentacoes();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(child: _buildMovimentacoesTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildMovimentacoesTable() {
    if (_filteredMovimentacoes.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma movimentação encontrada para o termo buscado.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth:
                MediaQuery.of(context).size.width -
                (_isRailExtended ? 180 : 70) -
                48 -
                32,
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
              final color = mov.tipo == 'Entrada' ? Colors.green : Colors.red;
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
                    Text(DateFormat('dd/MM/yy HH:mm').format(mov.timestamp)),
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
  }
}
