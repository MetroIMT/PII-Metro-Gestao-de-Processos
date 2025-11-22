import 'package:flutter/material.dart';
import 'dart:math';
import 'estoque_page.dart';
import 'alerts_page.dart';
import 'reports_page.dart';
import 'estoque_categorias_page.dart';
import 'movimentacoes_page.dart'; // Importar a nova página
import 'tool_page.dart';
// Importa os *modelos* AlertItem e AlertType, mas não o repositório estático
import '../../repositories/alert_repository.dart' show AlertItem, AlertType;
import '../../repositories/movimentacao_repository.dart';
import '../../models/movimentacao.dart';
import 'package:intl/intl.dart';
import 'gerenciar_usuarios.dart';
import '../../widgets/sidebar.dart';
import '../../services/material_service.dart';
import '../../services/movimentacao_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';

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

  // --- Serviços ---
  final MaterialService _materialService = MaterialService();
  final MovimentacaoService _movimentacaoService = MovimentacaoService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  // --- Estado: Nome do Usuário ---
  String _nomeUsuario = 'Usuário';
  bool _isLoadingNome = true;

  // --- Estado: Usuários Ativos ---
  int _usuariosAtivos = 0;
  bool _isLoadingUsuarios = true;

  // --- Estado: Movimentações ---
  List<Movimentacao> _recentMovimentacoes = [];
  bool _isLoadingRecent = true;
  String? _recentError;

  // --- Estado: Estoque (para o gráfico) ---
  List<EstoqueMaterial>? _materiaisGiro;
  List<EstoqueMaterial>? _materiaisConsumo;
  List<EstoqueMaterial>? _materiaisPatrimoniado;
  String? _materiaisError;

  // --- NOVO ESTADO: Alertas (para o card de Alertas) ---
  List<AlertItem> _dashboardAlerts = [];
  bool _isLoadingAlerts = true;
  String? _alertsError;
  // --- FIM DA MUDANÇA ---

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // --- MUDANÇA: Listener do AlertRepository REMOVIDO ---
    // AlertRepository.instance.countNotifier.addListener(_onAlertsCountChanged);

    // Adicionar listener para o novo repositório
    MovimentacaoRepository.instance.movimentacoesNotifier.addListener(
      _onAlertsCountChanged,
    );
    // Carregar nome do usuário
    _loadNomeUsuario();
    // carregar materiais do backend para atualizar o card de estoque
    _loadMateriais();
    // carregar últimas movimentações do backend para o card do dashboard
    _loadRecentMovimentacoes();
    // carregar usuários ativos
    _loadUsuariosAtivos();

    // --- MUDANÇA: Carregar os alertas REAIS ---
    _loadDashboardAlerts();
    // --- FIM DA MUDANÇA ---
  }

  Future<void> _loadUsuariosAtivos() async {
    setState(() => _isLoadingUsuarios = true);
    try {
      final usuarios = await _userService.getAll();
      final ativos = usuarios.where((u) => u.ativo).length;
      if (mounted) {
        setState(() {
          _usuariosAtivos = ativos;
          _isLoadingUsuarios = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _usuariosAtivos = 0;
          _isLoadingUsuarios = false;
        });
      }
    }
  }

  Future<void> _loadNomeUsuario() async {
    try {
      final nome = await _authService.nome;
      if (mounted) {
        setState(() {
          _nomeUsuario = nome ?? 'Usuário';
          _isLoadingNome = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nomeUsuario = 'Usuário';
          _isLoadingNome = false;
        });
      }
    }
  }

  Future<void> _loadMateriais() async {
    try {
      final results = await Future.wait([
        _materialService.getByTipo('giro'),
        _materialService.getByTipo('consumo'),
        _materialService.getByTipo('patrimoniado'),
      ]);

      if (mounted) {
        setState(() {
          _materiaisGiro = results[0];
          _materiaisConsumo = results[1];
          _materiaisPatrimoniado = results[2];
          _materiaisError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _materiaisError = e.toString());
    }
  }

  void _onAlertsCountChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentMovimentacoes() async {
    setState(() {
      _isLoadingRecent = true;
      _recentError = null;
    });

    try {
      final list = await _movimentacaoService.getAllMovimentacoes(limit: 5);
      if (mounted) {
        setState(() {
          _recentMovimentacoes = list;
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _recentError = e.toString();
          _isLoadingRecent = false;
        });
      }
    }
  }

  // --- NOVO MÉTODO: Lógica de Alertas (copiado da AlertsPage) ---
  Future<void> _loadDashboardAlerts() async {
    setState(() {
      _isLoadingAlerts = true;
      _alertsError = null;
    });

    try {
      final results = await Future.wait([
        _materialService.getByTipo('giro'),
        _materialService.getByTipo('patrimoniado'),
        _materialService.getByTipo('consumo'),
      ]);

      final allMaterials = results.expand((list) => list).toList();
      final generatedAlerts = <AlertItem>[];
      final now = DateTime.now();
      final expiryLimit = now.add(const Duration(days: 30));
      final criticalExpiryLimit = now.add(const Duration(days: 15));

      for (final m in allMaterials) {
        bool isLowStock = m.quantidade < 10;
        int lowStockSeverity = isLowStock ? (m.quantidade == 0 ? 3 : 2) : 0;

        bool isNearExpiry =
            m.vencimento != null && m.vencimento!.isBefore(expiryLimit);
        int nearExpirySeverity = isNearExpiry
            ? (m.vencimento!.isBefore(criticalExpiryLimit) ? 3 : 2)
            : 0;

        if (isLowStock && isNearExpiry) {
          if (lowStockSeverity >= nearExpirySeverity) {
            generatedAlerts.add(
              AlertItem(
                codigo: m.codigo,
                nome: m.nome,
                quantidade: m.quantidade,
                local: m.local,
                vencimento: m.vencimento,
                type: AlertType.lowStock,
                severity: lowStockSeverity,
              ),
            );
          } else {
            generatedAlerts.add(
              AlertItem(
                codigo: m.codigo,
                nome: m.nome,
                quantidade: m.quantidade,
                local: m.local,
                vencimento: m.vencimento,
                type: AlertType.nearExpiry,
                severity: nearExpirySeverity,
              ),
            );
          }
        } else if (isLowStock) {
          generatedAlerts.add(
            AlertItem(
              codigo: m.codigo,
              nome: m.nome,
              quantidade: m.quantidade,
              local: m.local,
              vencimento: m.vencimento,
              type: AlertType.lowStock,
              severity: lowStockSeverity,
            ),
          );
        } else if (isNearExpiry) {
          generatedAlerts.add(
            AlertItem(
              codigo: m.codigo,
              nome: m.nome,
              quantidade: m.quantidade,
              local: m.local,
              vencimento: m.vencimento,
              type: AlertType.nearExpiry,
              severity: nearExpirySeverity,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _dashboardAlerts = generatedAlerts;
          _isLoadingAlerts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _alertsError = e.toString();
          _isLoadingAlerts = false;
        });
      }
    }
  }
  // --- FIM DA MUDANÇA ---

  @override
  void dispose() {
    // --- MUDANÇA: Listener do AlertRepository REMOVIDO ---
    // AlertRepository.instance.countNotifier.removeListener(
    //   _onAlertsCountChanged,
    // );
    // --- FIM DA MUDANÇA ---

    MovimentacaoRepository.instance.movimentacoesNotifier.removeListener(
      _onAlertsCountChanged,
    );
    _animationController.dispose();
    _movimentacaoService.dispose();
    _materialService.dispose(); // Adicionado para fechar o cliente de materiais
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
      vencimento: DateTime.now().add(
        const Duration(days: 15),
      ), // Vence em 15 dias
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

    final EdgeInsets contentPadding = EdgeInsets.all(isMobile ? 16 : 24);

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
                'Home',
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
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 0))
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
              child: Sidebar(expanded: _isRailExtended, selectedIndex: 0),
            ),

          // Conteúdo principal
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
                  padding: contentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMobile)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
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
                                'Home',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: metroBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildWelcomeHeader(isMobile),
                      _buildHomeGrid(),
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

  /// Cabeçalho de Boas Vindas
  Widget _buildWelcomeHeader(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _isLoadingNome
              ? Row(
                  children: [
                    Text(
                      'Bem-vindo de volta, ',
                      style: TextStyle(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      height: isMobile ? 22 : 28,
                      child: const LinearProgressIndicator(),
                    ),
                  ],
                )
              : Text(
                  'Bem-vindo de volta, $_nomeUsuario!',
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

  /// O Grid de cards, agora mais responsivo e preenchido
  Widget _buildHomeGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;

        // 🔹 1 coluna em celular, 2 colunas no resto (tablet/desktop)
        final int crossAxisCount = maxWidth < 650 ? 1 : 2;

        // mesmos paddings/spacings que você já usa
        const double gridHorizontalPadding = 24.0;
        const double crossAxisSpacing = 16.0;

        // calcula largura aproximada de cada card
        final double totalSpacing =
            crossAxisSpacing * (crossAxisCount - 1) + gridHorizontalPadding;
        final double cardWidth = (maxWidth - totalSpacing) / crossAxisCount;

        // altura "ideal" pros cards
        double desiredHeight;
        if (crossAxisCount == 1) {
          // celular: cards mais altinhos
          desiredHeight = 430;
        } else {
          // tablet / desktop: ajusta pra não ficar gigante
          desiredHeight = maxWidth > 1000 ? 320 : 360;
        }

        final double childAspectRatio = cardWidth / desiredHeight;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(right: 24.0, bottom: 8.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          children: [
            // Card de Estoque Atual
            _buildEstoqueCard(
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ToolPage()),
              ),
            ),

            // Card de Alertas
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
              hasAlert: _dashboardAlerts.isNotEmpty,
              alertCount: _dashboardAlerts.length,
              content: _buildAlertsCardContent(),
            ),

            // Movimentações recentes
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
              content: _buildRecentMovimentacoesContent(),
            ),

            // Relatórios
            _buildDashboardCard(
              'Relatórios',
              Icons.article_outlined,
              Colors.deepPurple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RelatoriosPage()),
                );
              },
              content: _buildReportsCardContent(),
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
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // --- MUDANÇA: ÍCONES DE SETA VERDE/VERMELHA E ADICIONAR LOCAL/BASE (MANTIDA) ---
  Widget _buildMovimentacaoRow(Movimentacao mov) {
    // Formata a hora, ex: "14:32"
    final String horaFormatada = DateFormat('HH:mm').format(mov.timestamp);

    // Lógica de Ícone e Cor
    final bool isEntrada = mov.tipo == 'Entrada';
    final IconData iconData = isEntrada
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    final Color iconColor = isEntrada ? Colors.green : Colors.red;

    // Assumindo que a classe Movimentacao tem um campo 'local'
    final String local = mov.local;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 20), // Ícone ATUALIZADO
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
          // Adiciona a base/local antes da hora
          Text(
            local,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500, // Leve destaque
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
  // --- FIM DA MUDANÇA ---

  Widget _buildRecentMovimentacoesContent() {
    if (_isLoadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recentError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erro ao carregar movimentações: $_recentError',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadRecentMovimentacoes,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_recentMovimentacoes.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma movimentação registrada ainda.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    // Mantém o comportamento de scroll padrão para evitar clipping
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0),
      itemCount: _recentMovimentacoes.length,
      itemBuilder: (context, index) =>
          _buildMovimentacaoRow(_recentMovimentacoes[index]),
    );
  }

  // Card de Estoque com gráfico e estatísticas (ORIGINAL, COM BOTÃO CORRIGIDO)
  Widget _buildEstoqueCard(VoidCallback onTap) {
    final List<EstoqueMaterial> todosMateriais = [
      ...(_materiaisGiro ?? materiaisGiro),
      ...(_materiaisConsumo ?? materiaisConsumo),
      ...(_materiaisPatrimoniado ?? materiaisPatrimoniado),
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

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
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
                // ---------- CABEÇALHO ----------
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
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
                        'Estoque Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ),
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

                // ---------- CONTEÚDO ENVOLVIDO EM EXPANDED PARA CORRIGIR BOTÃO ----------
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Estatísticas
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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

                            const SizedBox(width: 8),

                            // Gráfico
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CustomPaint(
                                painter: PieChartPainter(
                                  disponivel: totalMateriais > 0
                                      ? materiaisDisponiveis / totalMateriais
                                      : 0,
                                  emFalta: totalMateriais > 0
                                      ? materiaisEmFalta / totalMateriais
                                      : 0,
                                  corDisponivel: Colors.green,
                                  corEmFalta: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botão de Ação corrigido para o canto inferior direito
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para mostrar uma estatística no card de estoque (Original)
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
    int? alertCount,
    Widget? content,
  }) {
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
                          // --- MUDANÇA: Usa o alertCount passado como parâmetro ---
                          '${alertCount ?? 0}',
                          // --- FIM DA MUDANÇA ---
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

                // --- MUDANÇA: CORREÇÃO DE OVERFLOW DO BOTÃO ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        // O 'content' agora é dinâmico
                        child:
                            content ??
                            const Center(
                              child: Text(
                                'Dados do card vão aqui',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                      ),
                      // Botão (AGORA DENTRO DO EXPANDED)
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
                // --- FIM DA MUDANÇA ---
              ],
            ),
          ),
        ),
      ),
    );
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- MUDANÇA: CONTEÚDO DO CARD DE ALERTAS ATUALIZADO (USA ESTADO REAL E FILTRO) ---
  Widget _buildAlertsCardContent() {
    // 1. Lidar com o estado de carregamento
    if (_isLoadingAlerts) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Lidar com o estado de erro
    if (_alertsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Falha ao carregar alertas: $_alertsError',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 3. Exibir os dados reais (usando _dashboardAlerts do estado)
    final allAlerts = _dashboardAlerts;

    // 1. Calcular Estatísticas
    final count = allAlerts.length;
    final lowStock = allAlerts
        .where((a) => a.type == AlertType.lowStock)
        .length;
    final nearExpiry = allAlerts
        .where((a) => a.type == AlertType.nearExpiry)
        .length;

    // 2. Obter os 3 mais críticos (ordenados por severidade decrescente)
    final sortedAlerts = List<AlertItem>.from(allAlerts);
    sortedAlerts.sort((a, b) => b.severity.compareTo(a.severity));
    final top3Alerts = sortedAlerts.take(3).toList(); // Filtra para os 3 mais críticos

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3. Linha de Estatísticas (Altura Fixa)
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
                Colors.orange, // Corrigido para Laranja
                Icons.calendar_today_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 16), // Linha divisória (Altura Fixa)
        // 4. Lista de Alertas Urgentes (AGORA EXPANDIDA E SCROLLABLE)
        Expanded(
          child: top3Alerts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 28,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Nenhum alerta ativo.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                )
              : ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    primary: false,
                    physics: const BouncingScrollPhysics(),
                    itemCount: top3Alerts.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: _buildAlertRow(top3Alerts[i], context),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
  // --- FIM DA MUDANÇA ---

  // --- NOVO HELPER: Linha de relatório com ícones de ação (para dar sensação de funcionalidade) ---
  Widget _buildActionableReportRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          // Ações Claras (Botões visíveis)
          Row(
            children: [
              // Botão de Download PDF (Funcionalidade mockada)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Ação: Iniciar geração do PDF (mock)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Iniciando geração PDF para $title')),
                  );
                },
              ),
              const SizedBox(width: 4),
              // Botão de Download Excel (Funcionalidade mockada)
              IconButton(
                icon: const Icon(Icons.table_chart, color: Colors.green),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Ação: Iniciar geração do Excel (mock)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Iniciando geração Excel para $title')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MUDANÇA: CONTEÚDO DO CARD DE RELATÓRIOS ATUALIZADO (USA NOVO HELPER E LÓGICA) ---
  Widget _buildReportsCardContent() {
    final Color reportColor = Colors.deepPurple;
    
    // Lista de relatórios disponíveis (agora usada para contagem e exibição)
    final List<Map<String, dynamic>> availableReports = [
      {
        'title': 'Movimentação Geral',
        'subtitle': 'Entradas e saídas de todos os itens.',
        'icon': Icons.swap_horiz,
      },
      {
        'title': 'Movimentações por Usuário',
        'subtitle': 'Filtrar por atividade de usuário.',
        'icon': Icons.person_search_outlined,
      },
      {
        'title': 'Inventário Atual',
        'subtitle': 'Status de todo o estoque.',
        'icon': Icons.inventory_2_outlined,
      },
      {
        'title': 'Vencimentos Próximos',
        'subtitle': 'Relatório de materiais com vencimento.',
        'icon': Icons.calendar_today_outlined,
      },
    ];

    // Simulação de relatórios gerados (mock funcional)
    final int reportsGeneratedCount = 12; // Número mock funcional
    final int reportTypesCount = availableReports.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Estatísticas (Mais funcionais)
        Row(
          children: [
            Expanded(
              child: _smallStat(
                'Tipos de Relatório',
                reportTypesCount.toString(), // Contagem dos tipos disponíveis
                reportColor,
                Icons.description_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _smallStat(
                'Relatórios Gerados',
                reportsGeneratedCount.toString(), // Mock funcional
                metroBlue,
                Icons.download_done_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 16),
        // 2. Lista de prévia (Usa ListView para rolar se necessário)
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              primary: false,
              physics: const BouncingScrollPhysics(),
              itemCount: availableReports.length,
              itemBuilder: (context, index) {
                final report = availableReports[index];
                return _buildActionableReportRow(
                  context,
                  report['title'],
                  report['subtitle'],
                  report['icon'],
                  reportColor,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  // --- FIM DA MUDANÇA ---
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
