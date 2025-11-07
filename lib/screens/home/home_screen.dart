import 'package:flutter/material.dart';
import 'dart:math';
import 'estoque_page.dart';
import 'alerts_page.dart';
import 'reports_page.dart';
import 'estoque_categorias_page.dart';
import 'movimentacoes_page.dart'; // Importar a nova página
import '../../repositories/alert_repository.dart'; // Importa AlertRepository, AlertItem e AlertType
import '../../repositories/movimentacao_repository.dart';
import '../../models/movimentacao.dart';
import 'package:intl/intl.dart';
import 'gerenciar_usuarios.dart';
import '../../widgets/sidebar.dart';

// Classe PieChartPainter (Sem alterações)
// ... (seu código do PieChartPainter)
// Classe PieChartPainter (Sem alterações)
class PieChartPainter extends CustomPainter {
  final double disponivel;
  final double emFalta;
  final Color corDisponivel;
  final Color corEmFalta;

  PieChartPainter({
    required this.disponivel,
    required this.emFalta,
    this.corDisponivel = Colors.green,
    this.corEmFalta = Colors.red,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final corDisponivelClara = corDisponivel.withAlpha((0.8 * 255).round());
    final corEmFaltaClara = corEmFalta.withAlpha((0.8 * 255).round());
    final paintDisponivel = Paint()
      ..style = PaintingStyle.fill
      ..color = corDisponivelClara;
    canvas.drawArc(rect, -pi / 2, 2 * pi * disponivel, true, paintDisponivel);
    final paintEmFalta = Paint()
      ..style = PaintingStyle.fill
      ..color = corEmFaltaClara;
    canvas.drawArc(
      rect,
      -pi / 2 + 2 * pi * disponivel,
      2 * pi * emFalta,
      true,
      paintEmFalta,
    );
    final paintBorda = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, paintBorda);
    final paintCentro = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    canvas.drawCircle(center, radius * 0.5, paintCentro);
    final textSpan = TextSpan(
      text: '${(disponivel * 100).toStringAsFixed(0)}%',
      style: TextStyle(
        color: Colors.black87,
        fontSize: radius * 0.4,
        fontWeight: FontWeight.bold,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  
  static const Color metroBlue = Color(0xFF001489);

  // --- Lógica da Sidebar ---
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
    AlertRepository.instance.countNotifier.addListener(_onAlertsCountChanged);
    
    // Adicionar listener para o novo repositório
    MovimentacaoRepository.instance.movimentacoesNotifier.addListener(_onAlertsCountChanged);
  }

  void _onAlertsCountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AlertRepository.instance.countNotifier.removeListener(
      _onAlertsCountChanged,
    );
    // Remover o listener
    MovimentacaoRepository.instance.movimentacoesNotifier.removeListener(
      _onAlertsCountChanged,
    );
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
  // --- Fim da Lógica da Sidebar ---

  // Dados de exemplo (Sem alterações)
  final List<EstoqueMaterial> materiaisGiro = [
    EstoqueMaterial(
      codigo: 'G001',
      nome: 'Rolamento 6203',
      quantidade: 50,
      local: 'Almoxarifado A',
      vencimento: DateTime(2025, 12, 31),
    ),
    EstoqueMaterial(
      codigo: 'G002',
      nome: 'Correia em V AX-45',
      quantidade: 20,
      local: 'Almoxarifado B',
    ),
    EstoqueMaterial(
      codigo: 'G003',
      nome: 'Filtro de Ar Motor X',
      quantidade: 0,
      local: 'Almoxarifado A',
    ),
    EstoqueMaterial(
      codigo: 'G004',
      nome: 'Selo Mecânico 1.5"',
      quantidade: 5,
      local: 'Oficina Mecânica',
    ),
    EstoqueMaterial(
      codigo: 'G005',
      nome: 'Óleo Hidráulico',
      quantidade: 10,
      local: 'Oficina Mecânica',
      vencimento: DateTime.now().add(const Duration(days: 15)), // Vence em 15 dias
    ),
  ];
  final List<EstoqueMaterial> materiaisConsumo = [
    EstoqueMaterial(
      codigo: 'C001',
      nome: 'Óleo Lubrificante XPTO',
      quantidade: 15,
      local: 'Oficina 1',
    ),
    EstoqueMaterial(
      codigo: 'C002',
      nome: 'Graxa de Lítio',
      quantidade: 5,
      local: 'Oficina 2',
      vencimento: DateTime(2024, 8, 1), // Já venceu
    ),
    EstoqueMaterial(
      codigo: 'C003',
      nome: 'Estopa (pacote)',
      quantidade: 100,
      local: 'Oficina 1',
    ),
    EstoqueMaterial(
      codigo: 'C004',
      nome: 'Lixa para Ferro',
      quantidade: 0,
      local: 'Almoxarifado C',
    ),
  ];
  final List<EstoqueMaterial> materiaisPatrimoniado = [
    EstoqueMaterial(
      codigo: 'P001',
      nome: 'Furadeira de Impacto Bosch',
      quantidade: 1,
      local: 'Ferramentaria',
    ),
    EstoqueMaterial(
      codigo: 'P002',
      nome: 'Multímetro Digital Fluke',
      quantidade: 1,
      local: 'Laboratório de Eletrônica',
    ),
    EstoqueMaterial(
      codigo: 'P003',
      nome: 'Notebook Dell Vostro',
      quantidade: 0,
      local: 'Sala da Supervisão',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final EdgeInsets contentPadding =
        isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(40);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF4F5FA),
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
              title: const Text(
                'Home',
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
          ? Drawer(
              child: Sidebar(
                expanded: true, 
                selectedIndex: 0, 
              ),
            )
          : null,
      body: Stack(
        children: [
          // Sidebar (Desktop)
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
                selectedIndex: 0,
              ),
            ),

          // Conteúdo principal
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: SingleChildScrollView(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMobile)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
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
                                'Home',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: metroBlue,
                                ),
                              ),
                            ],
                          ),
                          Hero(
                            tag: 'logo',
                            child: Image.asset(
                              'assets/LogoMetro.png',
                              height: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildWelcomeHeader(isMobile),
                  _buildQuickActions(isMobile),
                  _buildHomeGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cabeçalho de Boas Vindas
  Widget _buildWelcomeHeader(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bem-vindo de volta, Usuário!', // TODO: Trocar por nome real
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Aqui está um resumo da sua operação hoje.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Seção de Ações Rápidas
  Widget _buildQuickActions(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Wrap(
        spacing: 12.0, 
        runSpacing: 12.0, 
        children: [
          _buildActionButton(
            context,
            icon: Icons.search,
            label: 'Buscar Material',
            onPressed: () {
              // TODO: Implementar navegação para busca
            },
          ),
          _buildActionButton(
            context,
            icon: Icons.add_shopping_cart,
            label: 'Registrar Entrada',
            onPressed: () {
              // TODO: Implementar navegação
            },
          ),
          _buildActionButton(
            context,
            icon: Icons.shopping_cart_checkout,
            label: 'Registrar Saída',
            onPressed: () {
              // TODO: Implementar navegação
            },
          ),
        ],
      ),
    );
  }

  /// Helper para os botões de ação
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: metroBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      icon: Icon(icon, size: 18, color: metroBlue),
      label: Text(
        label,
        style: const TextStyle(color: metroBlue),
      ),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: metroBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }


  /// O Grid de cards, agora mais responsivo e preenchido
  Widget _buildHomeGrid() {

    return LayoutBuilder(
      builder: (context, constraints) {
        final int crossAxisCount;
        if (constraints.maxWidth < 650) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1100) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 3;
        }

        final double childAspectRatio;
        if (crossAxisCount == 1) {
          const double desiredCardHeight = 430; // Altura fixa para evitar overflow em telas estreitas
          childAspectRatio = constraints.maxWidth / desiredCardHeight;
        } else if (crossAxisCount == 2) {
          childAspectRatio = 1.4;
        } else {
          childAspectRatio = 1.2;
        }

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(right: 24.0, bottom: 8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          children: [
            // Card de Estoque Atual (Funcional)
            _buildEstoqueCard(
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EstoqueCategoriasPage(),
                ),
              ),
            ),

            // Card de Alertas (prioridade alta)
            _buildDashboardCard(
              'Alertas (estoque baixo / vencimento)',
              Icons.warning_amber,
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AlertsPage()),
                );
              },
              hasAlert: AlertRepository.instance.countNotifier.value > 0,
              alertCount: AlertRepository.instance.countNotifier.value,
              // *** INÍCIO DA MODIFICAÇÃO ***
              content: _buildAlertsCardContent(),
              // *** FIM DA MODIFICAÇÃO ***
            ),

            // Card de Instrumentos
            _buildDashboardCard(
              'Instrumentos próximos da calibração',
              Icons.timer,
              Colors.orange,
              () {},
              content: _buildStatContent(
                "3", 
                "Precisam de atenção",
                Colors.orange.shade800
              ),
            ),

            // AJUSTE: Card de Movimentações Recentes
            _buildDashboardCard(
              'Movimentações recentes',
              Icons.swap_horiz,
              Colors.green,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MovimentacoesPage()),
                );
              },
              
              // AQUI É A MÁGICA:
              // Trocamos o _buildStatContent por um widget que ouve o repositório
              content: ValueListenableBuilder<List<Movimentacao>>(
                valueListenable: MovimentacaoRepository.instance.movimentacoesNotifier,
                builder: (context, _, child) { // O _ indica que não vamos usar a lista diretamente aqui
                  final listaMovimentacoes = MovimentacaoRepository.instance.getMovimentacoesParaDashboard();

                  if (listaMovimentacoes.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma movimentação registrada ainda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }
                  
                  // Se tiver itens, constrói a lista
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0),
                    itemCount: listaMovimentacoes.length,
                    itemBuilder: (context, index) {
                      return _buildMovimentacaoRow(listaMovimentacoes[index]);
                    },
                  );
                },
              ),
            ),

            // Card Gerenciar Usuários
            _buildDashboardCard(
              'Gerenciar Usuários',
              Icons.people,
              Colors.blue,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GerenciarUsuarios()),
                );
              },
              color2: Colors.blue.shade200,
              content: _buildStatContent(
                "8", 
                "Usuários ativos",
                Colors.blue.shade800
              ),
            ),

            // Card Relatórios
            _buildDashboardCard(
              'Relatórios',
              Icons.article,
              const Color.fromARGB(255, 231, 126, 6),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RelatoriosPage()),
                );
              },
              color2: const Color.fromARGB(255, 219, 193, 153),
              content: _buildStatContent(
                "5", 
                "Relatórios salvos",
                const Color.fromARGB(255, 184, 99, 0)
              ),
            ),
          ],
        );
      },
    );
  }

  /// Helper para criar o conteúdo de estatística dos cards
  Widget _buildStatContent(String value, String label, Color color) {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            TextSpan(
              text: '\n$label',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NOVO: Helper para mostrar uma linha da movimentação
  Widget _buildMovimentacaoRow(Movimentacao mov) {
    // Formata a hora, ex: "14:32"
    final String horaFormatada = DateFormat('HH:mm').format(mov.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Row(
        children: [
          Icon(mov.icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mov.descricao,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              overflow: TextOverflow.ellipsis, // Evita quebra de linha
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            horaFormatada,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }


  // Card de Estoque com gráfico e estatísticas (FUNCIONAL)
  Widget _buildEstoqueCard(VoidCallback onTap) {
    
    final List<EstoqueMaterial> todosMateriais = [
      ...materiaisGiro,
      ...materiaisConsumo,
      ...materiaisPatrimoniado,
    ];

    final int totalMateriais = todosMateriais.length;
    final int materiaisDisponiveis = todosMateriais
        .where((m) => m.quantidade > 0)
        .length;
    final int materiaisEmFalta = todosMateriais
        .where((m) => m.quantidade <= 0)
        .length;
    
    final double porcentagemDisponivel = totalMateriais > 0
        ? (materiaisDisponiveis / totalMateriais) * 100
        : 0.0;

    final metroLightBlue = const Color.fromARGB(255, 5, 59, 158);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            // Gradiente removido -> cor sólida
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: metroBlue.withAlpha((0.1 * 255).round()),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título e ícone
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        // Gradiente removido -> cor sólida
                        color: metroBlue,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: metroBlue.withAlpha((0.3 * 255).round()),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estoque Total', // Título alterado
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Indicador de porcentagem
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: porcentagemDisponivel > 85
                            ? Colors.green
                            : porcentagemDisponivel > 70
                            ? Colors.orange
                            : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${porcentagemDisponivel.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Conteúdo do card
                Expanded(
                  child: Row(
                    children: [
                      // Estatísticas
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildEstoqueStat(
                              'Total de materiais',
                              '$totalMateriais',
                              Icons.category,
                              metroBlue,
                            ),
                            const SizedBox(height: 12),
                            _buildEstoqueStat(
                              'Disponíveis',
                              '$materiaisDisponiveis',
                              Icons.check_circle_outline,
                              Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _buildEstoqueStat(
                              'Em falta',
                              '$materiaisEmFalta',
                              Icons.error_outline,
                              Colors.red,
                            ),
                          ],
                        ),
                      ),

                      // Gráfico de pizza
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          child: CustomPaint(
                            painter: PieChartPainter(
                              // Prevenção de divisão por zero
                              disponivel: totalMateriais > 0 
                                  ? materiaisDisponiveis / totalMateriais
                                  : 0,
                              emFalta: totalMateriais > 0
                                  ? materiaisEmFalta / totalMateriais
                                  : 0,
                              corDisponivel: Colors.green,
                            ),
                            size: const Size(100, 100),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão de ação
                Align(
                  alignment: Alignment.bottomRight,
                  child: CardActionButton(
                    borderColor: metroBlue,
                    onPressed: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }

  // Widget para mostrar uma estatística no card de estoque
  Widget _buildEstoqueStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Card individual do Dashboard
  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool hasAlert = false,
    Color? color2,
    int? alertCount, 
    Widget? content,
  }) {
    final gradientColor = color2 ?? color.withAlpha((0.6 * 255).round());

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            // Gradiente removido -> cor sólida
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha((0.1 * 255).round()),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
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
                        // Gradiente removido -> cor sólida
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha((0.3 * 255).round()),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (hasAlert)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withAlpha((0.3 * 255).round()),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${alertCount ?? AlertRepository.instance.countNotifier.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  // O 'content' agora é dinâmico
                  child: content ?? const Center(
                    child: Text(
                      'Dados do card vão aqui',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                
                Align(
                  alignment: Alignment.bottomRight,
                  child: CardActionButton(
                    borderColor: color,
                    onPressed: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ));
    }


  // *** INÍCIO DOS NOVOS HELPERS ***

  // --- Helpers copiados da AlertsPage ---

  Color _severityColor(int s) {
    switch (s) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.yellow.shade700;
    }
  }

  String _typeLabel(AlertType t) =>
      t == AlertType.lowStock ? 'Estoque baixo' : 'Vencimento próximo';

  Widget _smallStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.12 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // --- Fim dos Helpers ---

  // NOVO: Helper para uma linha de alerta (versão simplificada para o dashboard)
  Widget _buildAlertRow(AlertItem a, BuildContext context) {
    final color = _severityColor(a.severity);
    final icon = a.type == AlertType.lowStock ? Icons.inventory_2 : Icons.event;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.nome,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis, // Evita quebra de linha
                  maxLines: 1,
                ),
                Text(
                  _typeLabel(a.type),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha((0.15 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'P: ${a.severity}', // P: Prioridade
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // NOVO: Conteúdo dinâmico para o Card de Alertas
  Widget _buildAlertsCardContent() {
    // Usar ValueListenableBuilder para ouvir mudanças nos alertas
    return ValueListenableBuilder<int>(
      valueListenable: AlertRepository.instance.countNotifier,
      builder: (context, count, _) {
        final allAlerts = AlertRepository.instance.items;

        // 1. Calcular Estatísticas
        final lowStock = allAlerts
            .where((a) => a.type == AlertType.lowStock)
            .length;
        final nearExpiry = allAlerts
            .where((a) => a.type == AlertType.nearExpiry)
            .length;

        // 2. Obter os 3 mais urgentes (ordenados por severidade)
        final sortedAlerts = List<AlertItem>.from(allAlerts);
        sortedAlerts.sort((a, b) => b.severity.compareTo(a.severity));
        // Limitar a 3 ou 4 itens para não sobrecarregar o card
        final topAlerts = sortedAlerts.take(3).toList(); 

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3. Linha de Estatísticas
            Row(
              children: [
                Expanded(
                  child: _smallStat(
                    'Total de alertas',
                    count.toString(),
                    metroBlue,
                    Icons.stacked_line_chart,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallStat(
                    'Estoques baixos',
                    lowStock.toString(),
                    Colors.red,
                    Icons.inventory_2_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _smallStat(
                    'Vencimentos próximos',
                    nearExpiry.toString(),
                    Colors.green,
                    Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 16), // Linha divisória

            // 4. Lista de Alertas Urgentes
            if (topAlerts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
                    SizedBox(height: 6),
                    Text(
                      'Nenhum alerta ativo.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < topAlerts.length; i++) ...[
                    _buildAlertRow(topAlerts[i], context),
                    if (i < topAlerts.length - 1) const SizedBox(height: 6),
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}



// Botão de ação com apenas o ícone de seta
class CardActionButton extends StatefulWidget {
  final String? label; // Mantém compatibilidade com chamadas antigas
  final Color borderColor;
  final VoidCallback onPressed;

  const CardActionButton({
    this.label,
    required this.borderColor,
    required this.onPressed,
    super.key,
  });

  @override
  State<CardActionButton> createState() => _CardActionButtonState();
}

class _CardActionButtonState extends State<CardActionButton> {
  bool _isHover = false;
  bool _isPressed = false;
  final Duration _duration = const Duration(milliseconds: 300);

  void _handleTap() {
    if (!_isPressed) {
      widget.onPressed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isHover ? widget.borderColor : Colors.transparent;
    final iconColor = _isHover ? Colors.white : widget.borderColor;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHover = true),
        onExit: (_) => setState(() => _isHover = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            _handleTap();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: _duration,
            curve: Curves.easeOut,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: widget.borderColor, width: 2),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: _duration,
                  transform: Matrix4.translationValues(
                    _isHover ? 5.0 : 0.0,
                    0.0,
                    0.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
