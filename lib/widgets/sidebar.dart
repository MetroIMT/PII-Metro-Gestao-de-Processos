import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../screens/login/login_screen.dart';
import '../screens/home/estoque_categorias_page.dart';
import '../screens/home/tool_page.dart';
import '../screens/home/gerenciar_usuarios.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/reports_page.dart';
import '../screens/home/admin_page.dart';


class Sidebar extends StatelessWidget {
  final bool expanded;
  final int selectedIndex;

  const Sidebar({
    super.key,
    required this.expanded,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final metroBlue = const Color(0xFF001489);
    final metroLightBlue = const Color(0xFF001489);

    return Container(
      width: expanded ? 180 : 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [metroBlue, metroLightBlue.withOpacity(0.9)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Image.asset('assets/LogoMetro.png'),
            height: 80,
          ),
          const SizedBox(height: 20),

          // ÍCONE DE PERFIL
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => AdminPage()),
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white.withOpacity(0),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Perfil',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ),


          // Itens do menu
          _sidebarItem(context, Icons.bar_chart, 'Dashboard', 0),
          _sidebarItem(context, Icons.assignment, 'Estoque', 1),
          _sidebarItem(context, Icons.build, 'Ferramentas', 2),
          _sidebarItem(context, Icons.article, 'Relatórios', 3),
          _sidebarItem(context, Icons.person_add, 'Gerenciar usuários', 4),

          const Spacer(),
          _sidebarItem(context, Icons.logout, 'Sair', 5),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = selectedIndex == index;

    return InkWell(
      onTap: () async {
        if (isSelected) {
          if (MediaQuery.of(context).size.width < 600) {
            Navigator.pop(context);
          }
          return;
        }

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EstoqueCategoriasPage()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ToolPage()),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RelatoriosPage()),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GerenciarUsuarios()),
            );
            break;
          case 5:
            try {
              await AuthService().logout();
            } catch (_) {}
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
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
          color:
              isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
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
