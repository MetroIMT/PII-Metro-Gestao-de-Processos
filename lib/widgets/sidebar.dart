import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/tool_page.dart';
import '../screens/home/gerenciar_usuarios.dart';
import '../screens/home/movimentacoes_page.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/reports_page.dart';
import '../screens/home/admin_page.dart';
import '../screens/home/alerts_page.dart';
import '../screens/home/dashboard.dart';

class Sidebar extends StatefulWidget {
  final bool expanded;
  final int selectedIndex;

  const Sidebar({
    super.key,
    required this.expanded,
    required this.selectedIndex,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  // Armazena a permissão do usuário para controlar a visibilidade de itens (ex: 'admin')
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  /// Carrega o nível de permissão (role) do usuário logado.
  Future<void> _loadRole() async {
    try {
      final r = await AuthService().role;
      if (mounted) setState(() => _role = r);
    } catch (_) {
      // Falha ao carregar a role é ignorada; a role permanece null
    }
  }

  @override
  Widget build(BuildContext context) {
    final metroBlue = const Color(0xFF001489);
    final metroLightBlue = const Color(0xFF001489);
    final expanded = widget.expanded;
    final selectedIndex = widget.selectedIndex;

    return Container(
      width: expanded ? 180 : 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [metroBlue, metroLightBlue.withAlpha((0.9 * 255).round())],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withAlpha((0.2 * 255).round()),
                  width: 1,
                ),
              ),
            ),
            height: 80,
            child: Image.asset('assets/LogoMetro.png'),
          ),
          const SizedBox(height: 20),

          _sidebarItem(
            context,
            Icons.person,
            'Perfil',
            -1,
            expanded,
            selectedIndex,
          ),

          _sidebarItem(
            context,
            Icons.grid_view_outlined,
            'Home',
            0,
            expanded,
            selectedIndex,
          ),
          _sidebarItem(
            context,
            Icons.data_thresholding_outlined,
            'Dashboard',
            1,
            expanded,
            selectedIndex,
          ),
          _sidebarItem(
            context,
            Icons.inventory_2,
            'Estoque',
            2,
            expanded,
            selectedIndex,
          ),
          _sidebarItem(
            context,
            Icons.swap_horiz,
            'Movimentações',
            3,
            expanded,
            selectedIndex,
          ),
          _sidebarItem(
            context,
            Icons.warning_amber_rounded,
            'Alertas',
            4,
            expanded,
            selectedIndex,
          ),
          _sidebarItem(
            context,
            Icons.article,
            'Relatórios',
            5,
            expanded,
            selectedIndex,
          ),
          // Item visível apenas para usuários 'admin'
          if ((_role ?? '') == 'admin')
            _sidebarItem(
              context,
              Icons.person_add,
              'Gerenciar usuários',
              6,
              expanded,
              selectedIndex,
            ),

          const Spacer(),
          _sidebarItem(
            context,
            Icons.logout,
            'Sair',
            7,
            expanded,
            selectedIndex,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Constrói um item de menu lateral com lógica de navegação.
  Widget _sidebarItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool expanded,
    int selectedIndex,
  ) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () async {
        // Se o item já estiver selecionado, apenas retorna (ou fecha o drawer no mobile)
        if (isSelected) {
          if (MediaQuery.of(context).size.width < 600) {
            Navigator.pop(context);
          }
          return;
        }

        // Lógica de navegação para cada índice
        switch (index) {
          case -1: // Perfil
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminPage()),
            );
            break;
          case 0: // Home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
            break;
          case 1: // Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const InsightsDashboardPage()),
            );
            break;
          case 2: // Estoque
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ToolPage()),
            );
            break;
          case 3: // Movimentações
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MovimentacoesPage()),
            );
            break;
          case 4: // Alertas
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AlertsPage()),
            );
            break;
          case 5: // Relatórios
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RelatoriosPage()),
            );
            break;
          case 6: // Gerenciar usuários (Admin)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GerenciarUsuarios()),
            );
            break;
          case 7: // Sair (Logout)
            // Mostra um diálogo de confirmação
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: const Text('Confirmar saída'),
                  content: const Text('Você realmente deseja sair da conta?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sair'),
                    ),
                  ],
                );
              },
            );

            if (shouldLogout == true) {
              try {
                await AuthService().logout();
              } catch (_) {}
              // Redireciona para a tela de login, removendo todas as rotas anteriores
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            }
            break;
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: expanded ? 16 : 0,
        ),
        decoration: BoxDecoration(
          // Aplica o destaque visual se o item for o selecionado
          color: isSelected
              ? Colors.white.withAlpha((0.2 * 255).round())
              : Colors.transparent,
          // Adiciona a barra lateral branca de seleção
          border: isSelected
              ? const Border(left: BorderSide(color: Colors.white, width: 3))
              : null,
        ),
        child: expanded
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            // Layout contraído (apenas ícone com Tooltip)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: label,
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                ],
              ),
      ),
    );
  }
}