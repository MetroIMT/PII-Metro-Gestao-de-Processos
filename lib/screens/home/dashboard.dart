import 'package:flutter/material.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart' as flc; // Prefixado como 'flc'
import '../../services/material_service.dart';
import '../../services/movimentacao_service.dart';
import '../../models/material.dart'; // Assume EstoqueMaterial ou similar
import '../../models/movimentacao.dart'; // Assume Movimentacao
import '../../widgets/sidebar.dart'; // Importa a Sidebar
import '../../services/auth_service.dart'; // Adiciona o serviço de autenticação

// Modelo de dados para Pie Chart
class StockTypeData {
  final String title;
  final int totalQuantity; // Quantidade total em estoque
  final Color color;

  StockTypeData(this.title, this.totalQuantity, this.color);
}

class InsightsDashboardPage extends StatefulWidget {
  const InsightsDashboardPage({super.key});

  @override
  State<InsightsDashboardPage> createState() => _InsightsDashboardPageState();
}

class _InsightsDashboardPageState extends State<InsightsDashboardPage>
    with SingleTickerProviderStateMixin {
  // Cores corporativas e de alerta (Nova Paleta)
  static const Color metroBlue = Color(0xFF001489); 
  static const Color alertRed = Color.fromARGB(255, 199, 11, 30);      
  static const Color successGreen = Color.fromARGB(255, 2, 183, 44);  
  static const Color accentOrange = Color(0xFFFD7E14); 
  static const Color blueChart = Color.fromARGB(255, 36, 18, 236); 
  
  static final Color chartBlueAccent = metroBlue.withOpacity(0.85); 

  // Lógica da Sidebar
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final MaterialService _materialService = MaterialService();
  final MovimentacaoService _movimentacaoService = MovimentacaoService();

  // NOVO: Estado para controle de acesso
  String? _currentRole;
  bool _isAuthorized = false; 

  // Estados para dados dos gráficos e KPIs
  int _totalItensCadastrados = 0;
  int _totalMovimentacoesMes = 0;
  int _itensEmEstoqueSeguranca = 0;
  double _percentualMovSaida = 0.0;
  List<Movimentacao> _movimentacoesMes = [];
  Map<String, double> _movimentacaoPorLocal = {};
  Map<String, int> _movimentacaoPorTipo = {};
  List<StockTypeData> _stockDistribution = [];
  List<dynamic> _criticalMaterials = []; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkAdminAndLoad(); // Inicia a checagem de permissão
  }

  // NOVO: Função para checar permissão e carregar dados (similar a gerenciar_usuarios)
  Future<void> _checkAdminAndLoad() async {
    try {
      final role = await AuthService().role;
      if (mounted) {
        setState(() {
          _currentRole = role;
          _isAuthorized = role == 'admin';
        });

        if (_isAuthorized) {
          await _loadData();
        } else {
          // Se não for admin, para o loading state
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentRole = null;
          _isAuthorized = false;
          _isLoading = false;
        });
        print('Erro ao carregar permissão: $e');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _materialService.dispose();
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

  // Função centralizada de carregamento de dados e cálculo de KPIs
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Dados de Materiais
      final materialsGiro = await _materialService.getByTipo('giro');
      final materialsConsumo = await _materialService.getByTipo('consumo');
      final materialsPatrimoniado = await _materialService.getByTipo(
        'patrimoniado',
      );

      final allMaterials = [
        ...materialsGiro,
        ...materialsConsumo,
        ...materialsPatrimoniado,
      ];

      // KPI 1: Total de Itens Cadastrados
      final totalItems = allMaterials.length;

      // KPI 3 & Novo Chart: Itens em Estoque de Segurança (< 10)
      final criticalMaterials = allMaterials
          .where((m) => m.quantidade < 10 && m.quantidade > 0)
          .toList();
      final emEstoqueSeguranca = criticalMaterials.length;

      // Cálculo de Totais de Estoque por Tipo
      final giroTotal = materialsGiro.fold<int>(
        0,
        (sum, m) => sum + m.quantidade,
      );
      final consumoTotal = materialsConsumo.fold<int>(
        0,
        (sum, m) => sum + m.quantidade,
      );
      final patrimoniadoTotal = materialsPatrimoniado.fold<int>(
        0,
        (sum, m) => sum + m.quantidade,
      );

      // Distribuição de Estoque por Tipo (para Pie Chart)
      final List<StockTypeData> distribution = [
        // Usando cores consistentes com o tema
        StockTypeData('Giro', giroTotal, blueChart),  // MUDADO de chartBlueAccent
        StockTypeData('Consumo', consumoTotal, alertRed),
        StockTypeData('Patrimoniado', patrimoniadoTotal, successGreen),
      ].where((d) => d.totalQuantity > 0).toList(); // Filtra zero

      // 2. Dados de Movimentação (Últimos 30 dias)
      final now = DateTime.now();
      final lastMonth = now.subtract(const Duration(days: 30));
      final allMovimentacoes = await _movimentacaoService.getAllMovimentacoes();
      final recentMovimentacoes = allMovimentacoes
          .where((m) => m.timestamp.isAfter(lastMonth))
          .toList();

      // KPI 2: Total de Movimentações (Últimos 30 dias)
      final totalMovs = recentMovimentacoes.length;

      // Agrupamento de Movimentação por Local, Tipo e Cálculo de % Saída
      final Map<String, double> localCounts = {};
      final Map<String, int> tipoCounts = {'giro': 0, 'consumo': 0, 'patrimoniado': 0,};
      int totalSaidas = 0;
      int totalEntradas = 0;

      for (var mov in recentMovimentacoes) {
        // Movimentação por Local
        localCounts.update(mov.local, (value) => value + 1, ifAbsent: () => 1);

        // Contagem de Entradas/Saídas
        if (mov.tipo == 'Saída') {
          totalSaidas++;
        } else if (mov.tipo == 'Entrada') {
          totalEntradas++;
        }

        // Movimentação por Tipo
        final materialCode = mov.codigoMaterial;

        String tipo;
        if (materialsGiro.any((m) => m.codigo == materialCode)) {
          tipo = 'giro';
        } else if (materialsConsumo.any((m) => m.codigo == materialCode)) {
          tipo = 'consumo';
        } else if (materialsPatrimoniado.any((m) => m.codigo == materialCode)) {
          tipo = 'patrimoniado';
        } else {
          tipo = 'giro'; // Default
        }

        tipoCounts.update(tipo, (value) => value + 1);
      }
      
      // KPI 4: Percentual de Movimentação de Saída
      final totalMovsInOut = totalSaidas + totalEntradas;
      final percentualSaida = totalMovsInOut > 0 ? (totalSaidas / totalMovsInOut) * 100 : 0.0;

      if (mounted) {
        setState(() {
          _totalItensCadastrados = totalItems;
          _itensEmEstoqueSeguranca = emEstoqueSeguranca;
          _totalMovimentacoesMes = totalMovs;
          _movimentacoesMes = recentMovimentacoes;
          _movimentacaoPorLocal = localCounts;
          _movimentacaoPorTipo = tipoCounts;
          _stockDistribution = distribution;
          _criticalMaterials = criticalMaterials;
          _percentualMovSaida = percentualSaida;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _totalItensCadastrados = -1; // Sinaliza falha
          print('Erro ao carregar dados do dashboard: $e');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // NOVO: Bloco de conteúdo centralizado com tratamento de estados
    Widget centralContent;

    if (!_isAuthorized) {
      centralContent = _buildUnauthorizedContainer(context);
    } else if (_isLoading) {
      centralContent = const Center(child: CircularProgressIndicator());
    } else if (_totalItensCadastrados == -1) {
      centralContent = _buildErrorContent();
    } else {
      centralContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8), // Pequeno espaçamento após o header
          const Text(
            'Análise detalhada de estoque e tendências de movimentação (Últimos 30 dias)',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 24),
          _buildInsightsGrid(),
          const SizedBox(height: 24),
        ],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade100,
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
              title: const Text(
                'Dashboard',
                style: TextStyle(color: metroBlue, fontWeight: FontWeight.bold),
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
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 1))
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
              child: Sidebar(expanded: _isRailExtended, selectedIndex: 1),
            ),
          Positioned.fill(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.only(
                left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile) _buildDesktopHeader(isAuthorized: _isAuthorized),
                      if (isMobile && !_isAuthorized) const SizedBox(height: 24), // Espaçamento para mobile
                      
                      // Conteúdo principal (Autorizado/Não Autorizado)
                      centralContent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets de Estrutura ---

  Widget _buildDesktopHeader({required bool isAuthorized}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
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
                tooltip: _isRailExtended ? 'Recolher Menu' : 'Expandir Menu',
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: metroBlue,
                    ),
                  ),
                  if (!isAuthorized)
                    Text(
                      'Visão geral da gestão de estoque e movimentações.',
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NOVO: Widget para tela de acesso restrito (Consistência de UI)
  Widget _buildUnauthorizedContainer(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 64, color: alertRed),
            const SizedBox(height: 16),
            const Text(
              'Acesso Restrito',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'O Dashboard de Insights é exclusivo para administradores. Seu cargo atual é ${_currentRole == null ? 'Desconhecido' : _currentRole!.toUpperCase()}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Redireciona para a home (index 0)
                Navigator.pushReplacementNamed(context, '/'); // Redireciona para a rota principal
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: metroBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Voltar para a Home'),
            ),
          ],
        ),
      ),
    );
  }

  // NOVO: Widget para conteúdo de Erro
  Widget _buildErrorContent() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: alertRed,
          ),
          const SizedBox(height: 16),
          const Text(
            '❌ Falha ao carregar dados do servidor.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: metroBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsGrid() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    // Proporção ajustada para cards mais compactos
    final chartAspectRatio = isMobile ? 0.85 : 1.15;

    return Column(
      children: [
        // LINHA 1: Indicadores Chave (4 KPI Cards com melhor estética e espaçamento)
        _buildKeyIndicatorsRow(),
        const SizedBox(height: 24),

        // LINHA 2 (2 Gráficos): Distribuição (Pie) e Movimentação por Tipo (Stacked Bar)
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 900 ? 1 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16.0, 
          mainAxisSpacing: 16.0,
          childAspectRatio: chartAspectRatio,
              children: [
                // GRÁFICO 1: Distribuição de Estoque (Pie Chart)
                _buildChartCard(
                  'Distribuição de Estoque por Categoria (Qtd. Itens)',
                  Icons.donut_large_outlined,
                  _buildPieChart(),
                ),
                // GRÁFICO 2: Movimentações por Tipo de Material (Stacked Bar)
                _buildChartCard(
                  'Movimentações por Tipo de Material (Últimos 30 dias)',
                  Icons.bar_chart_sharp,
                  _buildStackedBarChart(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // LINHA 3 (2 Gráficos): Tendência (Line) e Top Locais (Bar)
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 900 ? 1 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: isMobile ? 0.85 : chartAspectRatio,
              children: [
                // GRÁFICO 3: Tendência de Movimentação (Line Chart)
                _buildChartCard(
                  'Tendência Diária de Movimentação (Entradas vs. Saídas)',
                  Icons.show_chart,
                  _buildLineChart(),
                ),
                // GRÁFICO 4: Top 5 Locais de Maior Movimentação (Bar Chart)
                _buildChartCard(
                  'Top 5 Locais de Maior Movimentação',
                  Icons.location_on_outlined,
                  _buildBarChart(),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // LINHA 4 (2 Gráficos): Estoque Crítico (Novo layout com 2 charts)
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 900 ? 1 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: isMobile ? 0.85 : chartAspectRatio,
              children: [
                // GRÁFICO 5: Top 5 Materiais Críticos (Vertical Bar Chart - Estilizado)
                _buildChartCard(
                  'Top 5 Itens Mais Críticos (Qtd. <10)',
                  Icons.warning_amber_outlined,
                  _buildCriticalStockChart(),
                ),
                // GRÁFICO 6: Resumo de Estoque Crítico vs. Seguro (Novo Insight)
                _buildChartCard(
                  'Resumo: Estoque Crítico vs. Seguro',
                  Icons.pie_chart,
                  _buildCriticalStockSummaryPie(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildChartCard(
    String title,
    IconData icon,
    Widget chart, {
    bool isFullWidth = false,
    double? height,
  }) {
    return Card(
      elevation: 3, 
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: metroBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: metroBlue, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: chart,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets de KPI (4 cards com visual limpo e otimizado para overflow) ---

  Widget _buildKeyIndicatorsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final bool isMobile = width < 600;
        
        // CORREÇÃO: Aumenta o limite para 450px para 1 coluna
        final int count = width < 900 
            ? (width < 450 ? 1 : 2)
            : 4; 

        // CORREÇÃO: Diminui o Aspect Ratio para dar mais ALTURA ao card.
        final double childRatio = count == 1
            ? 3.0 // Reduzido de 4.0 para 3.0 para dar mais altura ao card em 1 coluna (CRÍTICO)
            : count == 2
                ? 2.5 // Reduzido de 3.0 para 2.5 para mais altura em 2 colunas
                : 2.8; // Desktop (4 colunas)

        List<Widget> indicators = [
          _buildIndicator(
            'Itens Cadastrados (Total)',
            _totalItensCadastrados.toString(),
            Icons.inventory_2_outlined,
            metroBlue,
            isMobile,
          ),
          _buildIndicator(
            'Movimentações (Últimos 30 dias)',
            _totalMovimentacoesMes.toString(),
            Icons.swap_vert,
            successGreen,
            isMobile,
          ),
          _buildIndicator(
            'Itens em Estoque Crítico (<10)',
            _itensEmEstoqueSeguranca.toString(),
            Icons.error_outline,
            _itensEmEstoqueSeguranca > 0 ? alertRed : Colors.grey.shade600,
            isMobile,
            subtitle: _itensEmEstoqueSeguranca > 0 ? 'Exige atenção imediata' : 'Estoque em níveis seguros',
          ),
          _buildIndicator(
            'Taxa de Saída (Últimos 30 dias)',
            '${_percentualMovSaida.toStringAsFixed(1)}%',
            Icons.call_made,
            accentOrange,
            isMobile,
            subtitle: 'Mov. Saída vs. Total (Entrada+Saída)',
          ),
        ];

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: count,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: childRatio,
          children: indicators,
        );
      },
    );
  }

  // Widget de Indicador (compactado)
  Widget _buildIndicator(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isMobile, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Aumentado para 8.0 para margem de segurança
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28, 
                  height: 28, 
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6), 
                  ),
                  child: Icon(icon, color: color, size: 14), // Revertido para 14
                ),
                const SizedBox(width: 8), // Revertido para 8
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 10 : 11, // Fonte 10px em mobile
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1, // Essencial: Limita a 1 linha
                    overflow: TextOverflow.ellipsis, // Essencial para evitar overflow
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4), 
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24, 
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Subtítulo reintroduzido e garantido que caiba
            if (subtitle != null) ...[ 
              const SizedBox(height: 2), // Reduzido para 2
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11, // Fonte 10px em mobile (CRÍTICO)
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis, // CRÍTICO: Não vai estourar
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- GRÁFICOS (6 Insights) ---

  // GRÁFICO 1: Distribuição de Estoque (PIE CHART)
  Widget _buildPieChart() {
    final total = _stockDistribution.fold<int>(0, (sum, d) => sum + d.totalQuantity);

    if (total == 0 || _stockDistribution.isEmpty)
      return const Center(
        child: Text("Sem dados de quantidade em estoque para exibição."),
      );

    // CORREÇÃO: Substituir chartBlueAccent por blueChart na lista de cores
    final List<StockTypeData> correctedDistribution = _stockDistribution.map((data) {
      Color correctedColor = data.color;
      if (data.color == chartBlueAccent) {
        correctedColor = blueChart;
      }
      return StockTypeData(data.title, data.totalQuantity, correctedColor);
    }).toList();

    return flc.PieChart(
      flc.PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 50,
        startDegreeOffset: 270,
        sections: correctedDistribution.map((data) {
          final percentage = (data.totalQuantity / total) * 100;

          return flc.PieChartSectionData(
            color: data.color.withOpacity(0.9),
            value: data.totalQuantity.toDouble(),
            title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
            radius: 70,
            titleStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }

  // GRÁFICO 2: STACKED BAR CHART (Movimentação por Tipo)
  Widget _buildStackedBarChart() {
    final List<flc.BarChartGroupData> barGroups = [];
    final List<String> types = ['giro', 'consumo', 'patrimoniado'];
    int xIndex = 0;

    final maxY = _movimentacaoPorTipo.values.fold<int>(0, max).toDouble() * 1.2;
    final double interval = maxY / 5 > 1 ? (maxY / 5).ceilToDouble() : 1.0;

    for (var type in types) {
      final totalMov = (_movimentacaoPorTipo[type] ?? 0).toDouble();

      barGroups.add(
        flc.BarChartGroupData(
          x: xIndex++,
          barRods: [
            flc.BarChartRodData(
              toY: totalMov,
              // CORREÇÃO: Trocar chartBlueAccent para blueChart
              color: type == 'giro'
                  ? blueChart.withOpacity(0.9)  // MUDADO
                  : type == 'consumo'
                      ? alertRed.withOpacity(0.9)
                      : successGreen.withOpacity(0.9),
              width: 40,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ],
        ),
      );
    }

    if (barGroups.isEmpty || maxY == 0)
      return const Center(child: Text("Sem dados de movimentação por tipo."));
    
    return Column(
      children: [
        Expanded(
          child: flc.BarChart(
            flc.BarChartData(
              maxY: maxY,
              alignment: flc.BarChartAlignment.spaceAround,
              barTouchData: flc.BarTouchData(enabled: true),
              titlesData: flc.FlTitlesData(
                show: true,
                bottomTitles: flc.AxisTitles(
                  sideTitles: flc.SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= types.length) return const SizedBox();
                      final type = types[idx];
                      final label = type.substring(0, 1).toUpperCase() + type.substring(1);
                      return flc.SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: flc.AxisTitles(
                  sideTitles: flc.SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: interval,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                topTitles: const flc.AxisTitles(sideTitles: flc.SideTitles(showTitles: false)),
                rightTitles: const flc.AxisTitles(sideTitles: flc.SideTitles(showTitles: false)),
              ),
              gridData: flc.FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return const flc.FlLine(color: Color(0xFFE0E0E0), strokeWidth: 1);
                },
              ),
              borderData: flc.FlBorderData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ],
    );
  }

  // GRÁFICO 3: Tendência de Movimentação (LINE CHART)
  Widget _buildLineChart() {
    final Map<int, Map<String, int>> dailyMovement = {};
    for (var mov in _movimentacoesMes) {
      final day = mov.timestamp.day;
      final type = mov.tipo;
      dailyMovement.putIfAbsent(day, () => {'Entrada': 0, 'Saída': 0});
      dailyMovement[day]![type] = dailyMovement[day]![type]! + 1;
    }

    final sortedDays = dailyMovement.keys.toList()..sort();
    if (sortedDays.isEmpty)
      return const Center(child: Text("Sem dados de movimentação para o mês."));

    final List<flc.FlSpot> spotsEntrada = [];
    final List<flc.FlSpot> spotsSaida = [];
    double maxMov = 0;

    for (int day in sortedDays) {
      final entrada = dailyMovement[day]!['Entrada']!.toDouble();
      final saida = dailyMovement[day]!['Saída']!.toDouble();

      spotsEntrada.add(flc.FlSpot(day.toDouble(), entrada));
      spotsSaida.add(flc.FlSpot(day.toDouble(), saida));

      maxMov = max(maxMov, max(entrada, saida));
    }

    final double maxY = maxMov * 1.2;
    final double intervalY = maxY / 5 > 1 ? (maxY / 5).ceilToDouble() : 1;
    final int minX = sortedDays.first;
    final int maxX = sortedDays.last;
    final double intervalX = ((maxX - minX) / 5) < 1 ? 1 : ((maxX - minX) / 5).ceilToDouble();

    return Column(
      children: [
        Expanded(
          child: flc.LineChart(
            flc.LineChartData(
              maxY: maxY,
              minY: 0,
              minX: minX.toDouble(),
              maxX: maxX.toDouble(),
              lineTouchData: const flc.LineTouchData(enabled: true),
              titlesData: flc.FlTitlesData(
                show: true,
                bottomTitles: flc.AxisTitles(
                  axisNameWidget: const Text('Dia do Mês'),
                  sideTitles: flc.SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: intervalX,
                    getTitlesWidget: (value, meta) {
                      return flc.SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: flc.AxisTitles(
                  axisNameWidget: const Text('Qtd. Movimentações'),
                  sideTitles: flc.SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: intervalY,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.left,
                      );
                    },
                  ),
                ),
                topTitles: const flc.AxisTitles(sideTitles: flc.SideTitles(showTitles: false)),
                rightTitles: const flc.AxisTitles(sideTitles: flc.SideTitles(showTitles: false)),
              ),
              gridData: flc.FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    const flc.FlLine(color: Color(0xFFE0E0E0), strokeWidth: 1),
              ),
              borderData: flc.FlBorderData(show: false),
              lineBarsData: [
                flc.LineChartBarData(
                  spots: spotsEntrada,
                  isCurved: true,
                  color: successGreen, // Entradas (Verde)
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const flc.FlDotData(show: true, getDotPainter: _getCustomDotPainter),
                  belowBarData: flc.BarAreaData(show: false),
                ),
                flc.LineChartBarData(
                  spots: spotsSaida,
                  isCurved: true,
                  color: alertRed, // Saídas (Vermelho)
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const flc.FlDotData(show: true, getDotPainter: _getCustomDotPainter),
                  belowBarData: flc.BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
        // Legenda do gráfico de linha
        _buildLegend([
          LegendItem(color: successGreen, title: 'Entrada'),
          LegendItem(color: alertRed, title: 'Saída'),
        ]),
      ],
    );
  }

  // Função auxiliar para DotPainter
  static flc.FlDotPainter _getCustomDotPainter(
      flc.FlSpot spot, double percent, flc.LineChartBarData bar, int index) {
    return flc.FlDotCirclePainter(
      radius: 3,
      color: bar.color!,
      strokeWidth: 0,
    );
  }

  // GRÁFICO 4: Movimentações por Local (BAR CHART)
  Widget _buildBarChart() {
    final sortedLocals = _movimentacaoPorLocal.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedLocals.take(5).toList();
    final double maxY = top5.isNotEmpty
        ? top5.map((e) => e.value).reduce(max) * 1.2
        : 10;
    final double interval = maxY / 5 > 1 ? (maxY / 5).ceilToDouble() : 1;

    if (top5.isEmpty)
      return const Center(child: Text("Sem dados de movimentação por local."));

    return flc.BarChart(
      flc.BarChartData(
        alignment: flc.BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: flc.BarTouchData(enabled: false),
        titlesData: flc.FlTitlesData(
          show: true,
          bottomTitles: flc.AxisTitles(
            sideTitles: flc.SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value >= 0 && value < top5.length) {
                  return flc.SideTitleWidget(
                    axisSide: meta.axisSide,
                    angle: -0.78,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        top5[value.toInt()].key.split(' ').first,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: flc.AxisTitles(
            sideTitles: flc.SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.left,
                );
              },
            ),
          ),
          topTitles: const flc.AxisTitles(sideTitles: flc.SideTitles(showTitles: false)),
          rightTitles: const flc.AxisTitles(sideTitles: flc.SideTitles(showTitles: false)),
        ),
        gridData: flc.FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return const flc.FlLine(color: Color(0xFFE0E0E0), strokeWidth: 1);
          },
        ),
        borderData: flc.FlBorderData(show: false),
        barGroups: List.generate(top5.length, (index) {
          return flc.BarChartGroupData(
            x: index,
            barRods: [
              flc.BarChartRodData(
                toY: top5[index].value,
                color: blueChart.withOpacity(0.9),  // MUDADO
                width: 40,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // GRÁFICO 5: Estoque Crítico (Vertical Bar Chart - Estilizado e Pareado)
  Widget _buildCriticalStockChart() {
    _criticalMaterials.sort((a, b) => a.quantidade.compareTo(b.quantidade));
    final top5Critical = _criticalMaterials.take(5).toList();

    if (top5Critical.isEmpty) {
      return const Center(child: Text("Nenhum item está no estoque crítico (<10)."));
    }

    final List<flc.BarChartGroupData> barGroups = [];
    for (int i = 0; i < top5Critical.length; i++) {
      final material = top5Critical[i];
      barGroups.add(
        flc.BarChartGroupData(
          x: i,
          barRods: [
            flc.BarChartRodData(
              toY: (material.quantidade as int).toDouble(),
              // A barra mais escura para os itens mais críticos
              color: alertRed.withOpacity(0.9), // Cor consistente
              width: 40, // Aumentado
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ],
        ),
      );
    }
    
    // Y max fixo em 10, que é o limite crítico
    final double maxY = 10.0; 
    const double interval = 2.0;

    return flc.BarChart(
      flc.BarChartData(
        maxY: maxY,
        minY: 0,
        alignment: flc.BarChartAlignment.spaceAround,
        barTouchData: flc.BarTouchData(enabled: true),
        // Linha de alerta em Y=10
        extraLinesData: flc.ExtraLinesData(
          horizontalLines: [
            flc.HorizontalLine(
              y: 10,
              color: metroBlue.withOpacity(0.5),
              strokeWidth: 2,
              dashArray: const [5, 5],
              // CORREÇÃO: usar HorizontalLineLabel
              label: flc.HorizontalLineLabel(
                show: true,
                labelResolver: (line) => 'Limite de Segurança (10)',
                alignment: Alignment.topRight,
                style: const TextStyle(color: metroBlue, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
        titlesData: flc.FlTitlesData(
          show: true,
          bottomTitles: flc.AxisTitles(
            sideTitles: flc.SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= top5Critical.length) return const SizedBox();
                // Mostra o nome e quantidade no eixo
                final name = top5Critical[index].nome.split(' ').first; 
                final qty = top5Critical[index].quantidade.toString();
                return flc.SideTitleWidget(
                  axisSide: meta.axisSide,
                  angle: -0.78, 
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: alertRed)),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: flc.AxisTitles(
            sideTitles: flc.SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: interval,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
          topTitles: const flc.AxisTitles(sideTitles: flc.SideTitles(showTitles: false)),
          rightTitles: const flc.AxisTitles(sideTitles: flc.SideTitles(showTitles: false)),
        ),
        gridData: flc.FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const flc.FlLine(color: Color(0xFFE0E0E0), strokeWidth: 1),
        ),
        borderData: flc.FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }

  // GRÁFICO 6 (NOVO): Resumo Estoque Crítico vs. Seguro
  Widget _buildCriticalStockSummaryPie() {
    final int safeStock = _totalItensCadastrados - _itensEmEstoqueSeguranca;
    final int criticalStock = _itensEmEstoqueSeguranca;

    if (_totalItensCadastrados == 0)
      return const Center(child: Text("Sem itens cadastrados para análise."));

    final data = [
      {'title': 'Estoque Seguro', 'value': safeStock, 'color': successGreen.withOpacity(0.9)},
      {'title': 'Estoque Crítico', 'value': criticalStock, 'color': alertRed.withOpacity(0.9)},
    ].where((d) => (d['value'] as int) > 0).toList();
    
    final total = _totalItensCadastrados.toDouble();

    return Column(
      children: [
        Expanded(
          child: flc.PieChart(
            flc.PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 50,
              startDegreeOffset: 270,
              sections: data.map((d) {
                final percentage = (d['value'] as int) / total * 100;

                return flc.PieChartSectionData(
                  color: d['color'] as Color,
                  value: (d['value'] as int).toDouble(),
                  title: percentage < 5 ? '' : '${percentage.toStringAsFixed(1)}%',
                  radius: 70,
                  titleStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        _buildLegend(data.map((d) => LegendItem(color: d['color'] as Color, title: '${d['title']} (${d['value']})')).toList()),
      ],
    );
  }

  // Widget auxiliar para construir a legenda
  Widget _buildLegend(List<LegendItem> items) {
    return Container(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: items.map((item) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color,
              ),
            ),
            const SizedBox(width: 4),
            Text(item.title, style: const TextStyle(fontSize: 12)),
          ],
        )).toList(),
      ),
    );
  }
}

// Classe auxiliar para a legenda
class LegendItem {
  final Color color;
  final String title;
  LegendItem({required this.color, required this.title});
}