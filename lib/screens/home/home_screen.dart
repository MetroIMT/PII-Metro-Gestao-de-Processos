import 'package:flutter/material.dart';
import 'dart:math';
import 'tool_page.dart';
import 'estoque_page.dart';
import 'alerts_page.dart';
import 'estoque_categorias_page.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import '../../repositories/alert_repository.dart';
import 'gerenciar_usuarios.dart';
import '../../widgets/sidebar.dart'; 

// Classe para desenhar o gráfico de pizza do estoque (Sem alterações)
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

    // Definir as cores do gráfico
    final corDisponivelClara = corDisponivel.withOpacity(0.8);
    final corEmFaltaClara = corEmFalta.withOpacity(0.8);

    // Desenhar arco disponível
    final paintDisponivel = Paint()
      ..style = PaintingStyle.fill
      ..color = corDisponivelClara;

    canvas.drawArc(rect, -pi / 2, 2 * pi * disponivel, true, paintDisponivel);

    // Desenhar arco em falta
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

    // Desenhar borda branca
    final paintBorda = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paintBorda);

    // Desenhar círculo central
    final paintCentro = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    canvas.drawCircle(center, radius * 0.5, paintCentro);

    // Desenhar texto de porcentagem no centro
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
      textDirection: TextDirection.ltr,
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
  
  // A lógica de estado da sidebar (animação) permanece na página
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
    // Escutar mudanças na contagem de alertas para atualizar o dashboard
    AlertRepository.instance.countNotifier.addListener(_onAlertsCountChanged);
  }

  void _onAlertsCountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Remover listener para evitar leaks
    AlertRepository.instance.countNotifier.removeListener(_onAlertsCountChanged);
    _animationController.dispose();
    super.dispose();
  }

  // Função que controla a animação e estado da sidebar
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

  @override
  Widget build(BuildContext context) {
    // Detectar se está em modo mobile
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      // AppBar apenas no mobile (para o menu hamburguer)
      appBar: isMobile
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              // No mobile: botão abre drawer
              leading: IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _animationController,
                  color: const Color(0xFF001489),
                ),
                onPressed: () {
                  // Usar o _scaffoldKey para abrir o drawer
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              title: const Text(
                'Dashboard',
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
      
      // ATUALIZADO: Usa o novo widget Sidebar
      drawer: isMobile
          ? Drawer(
              child: Sidebar(
                expanded: true, // No drawer, está sempre expandida
                selectedIndex: 0, // 0 = Dashboard
              ),
            )
          : null,
      
      body: Stack(
        children: [
          // Barra lateral fixa em desktop (posicionada sobre o conteúdo)
          if (!isMobile)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              top: 0,
              bottom: 0,
              width: _isRailExtended ? 180 : 70,
              // ATUALIZADO: Usa o novo widget Sidebar
              child: Sidebar(
                expanded: _isRailExtended,
                selectedIndex: 0, // 0 = Dashboard
              ),
            ),

          // Conteúdo principal (com padding à esquerda apenas em desktop)
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com título e logo (apenas em desktop)
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
                              // ATUALIZADO: Chama a função de toggle
                              onPressed: _toggleRail,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001489),
                              ),
                            ),
                          ],
                        ),
                        Hero(
                          tag: 'logo',
                          child: Image.asset(
                            'assets/LogoMetro.png',
                            height: 40, // Altura ajustada
                          ),
                        ),
                      ],
                    ),
                  ),

                // Dashboard Cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDashboardContent(), // Método de conteúdo
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //
  // OS MÉTODOS _buildSidebar E _sidebarItem FORAM REMOVIDOS DESTE ARQUIVO
  //

  // Conteúdo do Dashboard baseado na imagem de referência (Sem alterações)
  Widget _buildDashboardContent() {
    final metroBlue = const Color(0xFF001489);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Decidir se é 1 ou 2 colunas com base na largura disponível
        final crossAxisCount = constraints.maxWidth < 700 ? 1 : 2;

        return GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5, // Cards mais largos que altos
          ),
          children: [
            // Card de Estoque Atual
            _buildEstoqueCard(
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EstoqueCategoriasPage()),
              ),
            ),

            // Card de Instrumentos Próximos da Calibração
            _buildDashboardCard(
              'Instrumentos próximos da calibração',
              Icons.timer,
              Colors.orange,
              () {},
              color2: Colors.orange.shade200,
            ),

            // Card de Movimentações Recentes
            _buildDashboardCard(
              'Movimentações recentes',
              Icons.swap_horiz,
              Colors.green,
              () {},
              color2: Colors.green.shade200,
            ),

            // Card de Alertas (estoque baixo / vencimento) - usa contagem do repositório
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
              color2: Colors.red.shade200,
            ),
          ],
        );
      },
    );
  }

  // Card de Estoque com gráfico e estatísticas (Sem alterações)
  Widget _buildEstoqueCard(VoidCallback onTap) {
    // Dados do estoque obtidos da mesma fonte de estoque_page
    // Estes valores deveriam idealmente vir de um serviço ou provider compartilhado
    final List<EstoqueMaterial> materiais = [
      EstoqueMaterial(
        codigo: 'M001',
        nome: 'Cabo Elétrico 2.5mm',
        quantidade: 150,
        local: 'Base A',
      ),
      EstoqueMaterial(
        codigo: 'M002',
        nome: 'Disjuntor 20A',
        quantidade: 45,
        local: 'Base B',
      ),
      EstoqueMaterial(
        codigo: 'M003',
        nome: 'Conduíte Flexível 20mm',
        quantidade: 0,
        local: 'Base A',
      ),
      EstoqueMaterial(
        codigo: 'M004',
        nome: 'Terminal Elétrico',
        quantidade: 230,
        local: 'Base C',
      ),
      EstoqueMaterial(
        codigo: 'M005',
        nome: 'Fusível 10A',
        quantidade: 0,
        local: 'Base B',
      ),
      EstoqueMaterial(
        codigo: 'M006',
        nome: 'Luva de Emenda 25mm',
        quantidade: 75,
        local: 'Base D',
      ),
      EstoqueMaterial(
        codigo: 'M007',
        nome: 'Relé de Proteção',
        quantidade: 18,
        local: 'Base A',
      ),
      EstoqueMaterial(
        codigo: 'M008',
        nome: 'Chave Seccionadora',
        quantidade: 5,
        local: 'Base C',
      ),
    ];

    // Cálculos dos valores baseados nos dados acima
    final int totalMateriais = materiais.length;
    final int materiaisDisponiveis =
        materiais.where((m) => m.quantidade > 0).length;
    final int materiaisEmFalta =
        materiais.where((m) => m.quantidade <= 0).length;
    final double porcentagemDisponivel =
        (materiaisDisponiveis / totalMateriais) * 100;

    final metroBlue = const Color(0xFF001489);
    final metroLightBlue = const Color.fromARGB(255, 5, 59, 158);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.grey.shade50],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: metroBlue.withOpacity(0.1),
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
                        gradient: LinearGradient(
                          colors: [metroBlue, metroLightBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: metroBlue.withOpacity(0.3),
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
                        'Estoque atual',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Indicador de porcentagem de disponibilidade
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
                      // Estatísticas à esquerda
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Total de materiais
                            _buildEstoqueStat(
                              'Total de materiais',
                              '$totalMateriais',
                              Icons.category,
                              metroBlue,
                            ),
                            const SizedBox(height: 12),

                            // Materiais disponíveis
                            _buildEstoqueStat(
                              'Disponíveis',
                              '$materiaisDisponiveis',
                              Icons.check_circle_outline,
                              Colors.green,
                            ),
                            const SizedBox(height: 12),

                            // Materiais em falta
                            _buildEstoqueStat(
                              'Em falta',
                              '$materiaisEmFalta',
                              Icons.error_outline,
                              Colors.red,
                            ),
                          ],
                        ),
                      ),

                      // Gráfico de pizza à direita
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.all(8.0),
                          child: CustomPaint(
                            painter: PieChartPainter(
                              disponivel: materiaisDisponiveis / totalMateriais,
                              emFalta: materiaisEmFalta / totalMateriais,
                              corDisponivel:
                                  Colors.green, // Usando verde para o gráfico
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
                    label: 'Ver estoque',
                    borderColor: metroBlue,
                    onPressed: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para mostrar uma estatística no card de estoque (Sem alterações)
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
            color: color.withOpacity(0.1),
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

  // Card individual do Dashboard (Sem alterações)
  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool hasAlert = false,
    Color? color2,
    int? alertCount, // novo parâmetro opcional
  }) {
    final gradientColor = color2 ?? color.withOpacity(0.6);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
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
                        gradient: LinearGradient(
                          colors: [color, gradientColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
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
                              color: Colors.red.withOpacity(0.3),
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
                const Expanded(
                  child: Center(
                    child: Text(
                      'Dados do card vão aqui',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
                // Botão de ação
                Align(
                  alignment: Alignment.bottomRight,
                  child: CardActionButton(
                    label: 'Ver detalhes',
                    borderColor: color,
                    onPressed: onTap,
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

// Novo widget: botão estilizado replicando comportamento do exemplo HTML/CSS (Sem alterações)
class CardActionButton extends StatefulWidget {
  final String label;
  final Color borderColor;
  final VoidCallback onPressed;

  const CardActionButton({
    required this.label,
    required this.borderColor,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

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
    final textColor = _isHover ? Colors.white : widget.borderColor;

    return MouseRegion(
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
              // Texto + ícone (icone se desloca ao hover)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: _duration,
                    transform:
                        Matrix4.translationValues(_isHover ? 5.0 : 0.0, 0.0, 0.0),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}