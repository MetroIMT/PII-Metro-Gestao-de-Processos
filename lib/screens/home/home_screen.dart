import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/material.dart'; // MUDANÇA: Importa o modelo centralizado
import 'estoque_page.dart';
import 'alerts_page.dart';
import 'reports_page.dart';
import 'movimentacoes_page.dart';
import 'tool_page.dart';
import '../../repositories/alert_repository.dart' show AlertItem, AlertType;
import '../../repositories/movimentacao_repository.dart';
import '../../models/movimentacao.dart';
import 'package:intl/intl.dart';
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

  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final MaterialService _materialService = MaterialService();
  final MovimentacaoService _movimentacaoService = MovimentacaoService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  String _nomeUsuario = 'Usuário';
  bool _isLoadingNome = true;

  int _usuariosAtivos = 0;
  bool _isLoadingUsuarios = true;

  List<Movimentacao> _recentMovimentacoes = [];
  bool _isLoadingRecent = true;
  String? _recentError;

  List<EstoqueMaterial>? _materiaisGiro;
  List<EstoqueMaterial>? _materiaisConsumo;
  List<EstoqueMaterial>? _materiaisInstrumento;
  String? _materiaisError;

  List<AlertItem> _dashboardAlerts = [];
  bool _isLoadingAlerts = true;
  String? _alertsError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    MovimentacaoRepository.instance.movimentacoesNotifier.addListener(
      _onAlertsCountChanged,
    );
    _loadNomeUsuario();
    _loadMateriais();
    _loadRecentMovimentacoes();
    _loadUsuariosAtivos();

    _loadDashboardAlerts();
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
        _materialService.getByTipo('instrumento'),
      ]);

      if (mounted) {
        setState(() {
          _materiaisGiro = results[0];
          _materiaisConsumo = results[1];
          _materiaisInstrumento = results[2];
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
        ];

        setState(() {
          _recentMovimentacoes = mockMovimentacoes;
          _isLoadingRecent = false;
          // _recentError = e.toString(); // Don't show error, show mocks
        });
      }
    }
  }

  Future<void> _loadDashboardAlerts() async {
    setState(() {
      _isLoadingAlerts = true;
      _alertsError = null;
    });

    try {
      final results = await Future.wait([
        _materialService.getByTipo('giro'),
        _materialService.getByTipo('instrumento'),
        _materialService.getByTipo('consumo'),
      ]);

      final allMaterials = results.expand((list) => list).toList();
      final generatedAlerts = <AlertItem>[];
      final now = DateTime.now();
      final expiryLimit = now.add(const Duration(days: 90));
      final criticalExpiryLimit = now.add(const Duration(days: 30));

      for (final m in allMaterials) {
        bool isLowStock = false;
        int lowStockSeverity = 0;
        bool isNearExpiry = false;
        int nearExpirySeverity = 0;

        final minStock = m.estoqueMinimo ?? 10;
        if (m.tipo != 'instrumento' && m.quantidade < minStock) {
          isLowStock = true;
          lowStockSeverity = m.quantidade == 0 ? 3 : 2;
        }

        DateTime? expirationDate;
        if (m.tipo == 'instrumento') {
          expirationDate = m.dataCalibracao;
        } else {
          expirationDate = m.vencimento;
        }

        if (expirationDate != null) {
          if (expirationDate.isBefore(now)) {
            isNearExpiry = true;
            nearExpirySeverity = 3;
          } else if (expirationDate.isBefore(expiryLimit)) {
            isNearExpiry = true;
            nearExpirySeverity = expirationDate.isBefore(criticalExpiryLimit)
                ? 3
                : 2;
          }
        }

        if (isLowStock || isNearExpiry) {
          final maxSeverity = max(lowStockSeverity, nearExpirySeverity);
          AlertType type;

          if (maxSeverity == lowStockSeverity && isLowStock) {
            type = AlertType.lowStock;
          } else {
            type = AlertType.nearExpiry;
          }

          generatedAlerts.add(
            AlertItem(
              codigo: m.codigo,
              nome: m.nome,
              quantidade: m.quantidade,
              local: m.local,
              vencimento: m.vencimento,
              dataCalibracao: m.dataCalibracao,
              type: type,
              severity: maxSeverity,
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
        // Dados mockados para fallback em caso de erro
        final mockAlerts = [
          AlertItem(
            codigo: 'MOCK-001',
            nome: 'Rolamento SKF 6205 (Mock)',
            quantidade: 2,
            local: 'Almoxarifado Central',
            type: AlertType.lowStock,
            severity: 3,
          ),
          AlertItem(
            codigo: 'MOCK-002',
            nome: 'Cola Industrial (Mock)',
            quantidade: 15,
            local: 'Almoxarifado B',
            vencimento: DateTime.now().add(const Duration(days: 5)),
            type: AlertType.nearExpiry,
            severity: 3,
          ),
          AlertItem(
            codigo: 'MOCK-003',
            nome: 'Luvas de Proteção (Mock)',
            quantidade: 5,
            local: 'EPIs',
            type: AlertType.lowStock,
            severity: 2,
          ),
        ];

        setState(() {
          _dashboardAlerts = mockAlerts;
          _isLoadingAlerts = false;
          // _alertsError = e.toString(); // Não exibe erro, usa mocks
        });
      }
    }
  }

  @override
  void dispose() {
    MovimentacaoRepository.instance.movimentacoesNotifier.removeListener(
      _onAlertsCountChanged,
    );
    _animationController.dispose();
    _movimentacaoService.dispose();
    _materialService.dispose();
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

  // Dados de exemplo (MANTIDOS e corrigidos para o novo modelo)
  final List<EstoqueMaterial> materiaisGiro = [
    EstoqueMaterial(
      codigo: 'G001',
      nome: 'Rolamento 6203',
      quantidade: 50,
      local: 'Almoxarifado A',
      tipo: 'giro',
      estoqueMinimo: 10,
      vencimento: DateTime(2025, 12, 31),
    ),
    EstoqueMaterial(
      codigo: 'G002',
      nome: 'Correia em V AX-45',
      quantidade: 20,
      local: 'Almoxarifado B',
      tipo: 'giro',
      estoqueMinimo: 5,
    ),
    EstoqueMaterial(
      codigo: 'G003',
      nome: 'Filtro de Ar Motor X',
      quantidade: 0,
      local: 'Almoxarifado A',
      tipo: 'giro',
      estoqueMinimo: 1,
    ),
    EstoqueMaterial(
      codigo: 'G004',
      nome: 'Selo Mecânico 1.5"',
      quantidade: 5,
      local: 'Oficina Mecânica',
      tipo: 'giro',
      estoqueMinimo: 10,
    ),
    EstoqueMaterial(
      codigo: 'G005',
      nome: 'Óleo Hidráulico',
      quantidade: 10,
      local: 'Oficina Mecânica',
      tipo: 'giro',
      estoqueMinimo: 5,
      vencimento: DateTime.now().add(const Duration(days: 15)),
    ),
  ];
  final List<EstoqueMaterial> materiaisConsumo = [
    EstoqueMaterial(
      codigo: 'C001',
      nome: 'Óleo Lubrificante XPTO',
      quantidade: 15,
      local: 'Oficina 1',
      tipo: 'consumo',
    ),
    EstoqueMaterial(
      codigo: 'C002',
      nome: 'Graxa de Lítio',
      quantidade: 5,
      local: 'Oficina 2',
      tipo: 'consumo',
      vencimento: DateTime(2024, 8, 1),
    ),
    EstoqueMaterial(
      codigo: 'C003',
      nome: 'Estopa (pacote)',
      quantidade: 100,
      local: 'Oficina 1',
      tipo: 'consumo',
    ),
    EstoqueMaterial(
      codigo: 'C004',
      nome: 'Lixa para Ferro',
      quantidade: 0,
      local: 'Almoxarifado C',
      tipo: 'consumo',
    ),
  ];
  final List<EstoqueMaterial> materiaisPatrimoniado = [
    EstoqueMaterial(
      codigo: 'P001',
      nome: 'Furadeira de Impacto Bosch',
      quantidade: 1,
      local: 'Ferramentaria',
      tipo: 'instrumento',
      patrimonio: 'PAT-1234',
      status: 'disponível',
      dataCalibracao: DateTime.now().add(const Duration(days: 90)),
    ),
    EstoqueMaterial(
      codigo: 'P002',
      nome: 'Multímetro Digital Fluke',
      quantidade: 1,
      local: 'Laboratório de Eletrônica',
      tipo: 'instrumento',
      patrimonio: 'PAT-5678',
      status: 'em uso',
      dataCalibracao: DateTime.now().subtract(const Duration(days: 10)),
    ),
    EstoqueMaterial(
      codigo: 'P003',
      nome: 'Notebook Dell Vostro',
      quantidade: 0,
      local: 'Sala da Supervisão',
      tipo: 'instrumento',
      patrimonio: 'PAT-9012',
      status: 'em campo',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final EdgeInsets contentPadding = EdgeInsets.all(isMobile ? 16 : 20);

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

          Positioned.fill(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.only(
                left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
              ),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
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

        final int crossAxisCount = maxWidth < 650 ? 1 : 2;

        // 🔹 1 coluna em celular, 2 colunas no resto (tablet/desktop)
        final int crossAxisCount = maxWidth < 750 ? 1 : 2;

        // mesmos paddings/spacings que você já usa (desktop levemente mais próximo do rail)
        final double gridHorizontalPadding = maxWidth < 750 ? 0.0 : 16.0;
        const double crossAxisSpacing = 16.0;

        final double cardWidth =
            (maxWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
            crossAxisCount;

        double desiredHeight;
        if (crossAxisCount == 1) {
          desiredHeight = 430;
          // celular: cards mais altinhos
          desiredHeight = 420;
        } else {
          desiredHeight = maxWidth > 1000 ? 320 : 360;
        }

        final double childAspectRatio = cardWidth / desiredHeight;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            right: gridHorizontalPadding,
            left: gridHorizontalPadding,
            bottom: 8.0,
          ),
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
                // CORREÇÃO: Remove const
                MaterialPageRoute(builder: (_) => ToolPage()),
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
                  // CORREÇÃO: Remove const
                  MaterialPageRoute(builder: (_) => AlertsPage()),
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
                  // CORREÇÃO: Remove const
                  MaterialPageRoute(builder: (_) => MovimentacoesPage()),
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
                  // CORREÇÃO: Remove const
                  MaterialPageRoute(builder: (_) => RelatoriosPage()),
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

  Widget _buildMovimentacaoRow(Movimentacao mov) {
    final String dataFormatada = DateFormat('dd/MM').format(mov.timestamp);
    final String horaFormatada = DateFormat('HH:mm').format(mov.timestamp);

    final bool isEntrada = mov.tipo == 'Entrada';
    final IconData iconData = isEntrada
        ? Icons.arrow_downward
        : Icons.arrow_upward;
    final Color iconColor = isEntrada ? Colors.green : Colors.red;

    final String local = mov.local;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mov.descricao,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),

          Text(
            local,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(width: 15),

          Text(
            dataFormatada,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 4),

          Text(
            horaFormatada,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

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
      ...(_materiaisInstrumento ?? materiaisPatrimoniado),
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

    if (_materiaisGiro == null ||
        _materiaisConsumo == null ||
        _materiaisInstrumento == null) {
      return _buildDashboardCard(
        'Estoque Total',
        Icons.inventory_2,
        metroBlue,
        onTap,
        content: const Center(child: CircularProgressIndicator()),
      );
    }

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
                // --- FIM DA MUDANÇA ---
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
                          '${alertCount ?? 0}',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child:
                            content ??
                            const Center(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

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
                  overflow: TextOverflow.ellipsis,
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
              'P: ${a.severity}',
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

  Widget _buildAlertsCardContent() {
    if (_isLoadingAlerts) {
      return const Center(child: CircularProgressIndicator());
    }

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

    final allAlerts = _dashboardAlerts;

    final count = allAlerts.length;
    final lowStock = allAlerts
        .where((a) => a.type == AlertType.lowStock)
        .length;
    final nearExpiry = allAlerts
        .where((a) => a.type == AlertType.nearExpiry)
        .length;

    final sortedAlerts = List<AlertItem>.from(allAlerts);
    sortedAlerts.sort((a, b) => b.severity.compareTo(a.severity));
    final top3Alerts = sortedAlerts.take(3).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 400;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                Colors.orange,
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
            // 3. Linha de Estatísticas (Responsiva)
            if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _smallStat(
                    'Total de alertas',
                    count.toString(),
                    metroBlue,
                    Icons.stacked_line_chart,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
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
                          'Vencimentos',
                          nearExpiry.toString(),
                          Colors.orange,
                          Icons.calendar_today_outlined,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
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
                      Colors.orange,
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
                      behavior: ScrollConfiguration.of(
                        context,
                      ).copyWith(scrollbars: false),
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
      },
    );
  }

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
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Iniciando geração PDF para $title'),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.table_chart, color: Colors.green),
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Iniciando geração Excel para $title'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportsCardContent() {
    final Color reportColor = Colors.deepPurple;

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

    final int reportsGeneratedCount = 12;
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
                reportTypesCount.toString(),
                reportColor,
                Icons.description_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _smallStat(
                'Relatórios Gerados',
                reportsGeneratedCount.toString(),
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
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
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
}

class CardActionButton extends StatefulWidget {
  final String? label;
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
