import 'package:flutter/material.dart';
import 'tool_page.dart';
import 'dashboard_page.dart';

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
          
          // Aqui você pode navegar para a página correspondente
          switch(index) {
            case 0:
              // Navegar para perfil do usuário
              break;
            case 1:
              // Navegar para estoque
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
            _buildDashboardCard(
              'Estoque atual',
              Icons.inventory_2,
              Colors.blue.shade800,
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
