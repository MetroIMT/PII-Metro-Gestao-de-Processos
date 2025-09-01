import 'package:flutter/material.dart';
import 'dart:math';
import 'tool_page.dart';
import 'estoque_page.dart';

// Classe para desenhar o gráfico de pizza do estoque
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
    
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * disponivel,
      true,
      paintDisponivel,
    );
    
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
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

  @override
  Widget build(BuildContext context) {
    // Detectar se está em modo mobile
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      // AppBar apenas no mobile (para o menu hamburguer)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        // No mobile: botão abre drawer, no desktop: botão expande/contrai a sidebar
        leading: IconButton(
          icon: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animationController,
            color: const Color(0xFF2D3748),
          ),
          onPressed: isMobile
              ? () {
                  // Usar o _scaffoldKey para abrir o drawer
                  _scaffoldKey.currentState?.openDrawer();
                }
              : _toggleRail,
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/LogoMetro.png', height: 32),
          ),
        ],
      ),
      drawer: isMobile 
          ? Drawer(child: _buildSidebar(expanded: true)) 
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
              child: _buildSidebar(expanded: _isRailExtended),
            ),

          // Conteúdo principal (com padding à esquerda apenas em desktop)
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0
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
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Hero(
                          tag: 'logo',
                          child: Image.asset('assets/LogoMetro.png', height: 40),
                        ),
                      ],
                    ),
                  ),
                
                // Dashboard Cards
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDashboardContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Barra lateral com menu de navegação
  Widget _buildSidebar({bool expanded = false}) {
    return Container(
      width: expanded ? 180 : 70,
      color: const Color(0xFF253250), // Cor azul escuro do Metrô
      child: Column(
        children: [
          // Aumentando o espaçamento no topo
          const SizedBox(height: 60),
          // Logo do Metrô no topo da sidebar
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Icon(
              Icons.subway,
              color: Colors.white,
              size: 32,
            ),
          ),
          _sidebarItem(Icons.person, 'Usuário', 0, expanded),
          _sidebarItem(Icons.assignment, 'Estoque', 1, expanded),
          _sidebarItem(Icons.build, 'Ferramentas', 2, expanded),
          _sidebarItem(Icons.article, 'Relatórios', 3, expanded),
          const Spacer(),
        ],
      ),
    );
  }
  
  // Item individual da barra lateral
  Widget _sidebarItem(IconData icon, String label, int index, bool expanded) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
          
          // Navegação para as diferentes páginas
          switch(index) {
            case 0:
              // Navegar para perfil do usuário
              break;
            case 1:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolPage()));
              break;
            case 3:
              // Navegar para relatórios
              break;
          }
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: expanded ? 16 : 0),
        color: isSelected ? Colors.black26 : Colors.transparent,
        child: expanded 
          // Layout expandido: ícone e texto lado a lado
          ? Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            )
          // Layout recolhido: ícone e texto em coluna
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
      ),
    );
  }
  
  // Conteúdo do Dashboard baseado na imagem de referência
  Widget _buildDashboardContent() {
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
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPage())),
            ),
            
            // Card de Instrumentos Próximos da Calibração
            _buildDashboardCard(
              'Instrumentos próximos da calibração',
              Icons.timer,
              Colors.orange,
              () {}, 
            ),
            
            // Card de Movimentações Recentes
            _buildDashboardCard(
              'Movimentações recentes',
              Icons.swap_horiz,
              Colors.green,
              () {},
            ),
            
            // Card de Alertas (estoque baixo / vencimento)
            _buildDashboardCard(
              'Alertas (estoque baixo / vencimento)',
              Icons.warning_amber,
              Colors.red,
              () {},
              hasAlert: true,
            ),
          ],
        );
      }
    );
  }
  
  // Card de Estoque com gráfico e estatísticas
  Widget _buildEstoqueCard(VoidCallback onTap) {
    // Dados do estoque (no futuro, buscar da API)
    final int totalMateriais = 150;
    final int materiaisDisponiveis = 120;
    final int materiaisEmFalta = totalMateriais - materiaisDisponiveis;
    final double porcentagemDisponivel = (materiaisDisponiveis / totalMateriais) * 100;
    
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título e ícone
              Row(
                children: [
                  Icon(Icons.inventory_2, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            Colors.blue.shade800,
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
                          ),
                          size: const Size(100, 100),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Widget para mostrar uma estatística no card de estoque
  Widget _buildEstoqueStat(String label, String value, IconData icon, Color color) {
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
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
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

  // Card individual do Dashboard
  Widget _buildDashboardCard(String title, IconData icon, Color color, VoidCallback onTap, {bool hasAlert = false}) {
    return Material(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  if (hasAlert)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Dados do card vão aqui',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
