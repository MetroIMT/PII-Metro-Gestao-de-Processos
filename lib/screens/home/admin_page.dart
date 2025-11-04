import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

// Adiciona o 'TickerProvider' para a animação da sidebar
class _AdminPageState extends State<AdminPage>
    with SingleTickerProviderStateMixin {
  static const Color metroBlue = Color(0xFF001489);
  static const Color pageBackground = Color(0xFFF9F7FC);

  final TextEditingController _nameController = TextEditingController(
    text: 'Breno Augusto Gandolf',
  );

  bool _isEditingName = false;
  
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
    _nameController.dispose();
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
    // Pega o tamanho da tela para saber se é mobile
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: pageBackground,
      // AppBar só aparece no mobile
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
                'Perfil do Administrador',
                style: TextStyle(
                  color: metroBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
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
      // Drawer (menu) só existe no mobile
      drawer: isMobile
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 0))
          : null,
      body: Stack(
        children: [
          // Sidebar animada (só aparece no desktop)
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
          
          // Conteúdo principal da página
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            // Ajusta o padding da esquerda com base na sidebar (desktop) ou 0 (mobile)
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (só aparece no desktop)
                if (!isMobile)
                  _buildDesktopHeader(),
                
                // Card principal com o conteúdo
                Expanded(
                  child: Padding(
                    // Padding diferente para mobile e desktop
                    padding: EdgeInsets.all(isMobile ? 16 : 32),
                    child: SingleChildScrollView(
                      child: _buildProfileCard(),
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

  /// O header que só aparece no layout desktop
  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isRailExtended ? Icons.menu_open : Icons.menu,
              color: metroBlue,
            ),
            onPressed: _toggleRail,
          ),
          const SizedBox(width: 8),
          const Text(
            'Perfil do Administrador',
            style: TextStyle(
              color: metroBlue,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// O Card principal com as informações do perfil 
  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do Card
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Informações Pessoais',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: metroBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Nome ---
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: metroBlue),
              title: const Text(
                'Nome',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              subtitle: _isEditingName
                  ? TextField( // Aparece quando está editando
                      controller: _nameController,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: metroBlue),
                        ),
                      ),
                    )
                  : Text( // Aparece quando não está editando
                      _nameController.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
              trailing: IconButton(
                icon: Icon(
                  _isEditingName ? Icons.check_rounded : Icons.edit_outlined,
                  color: metroBlue,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _isEditingName = !_isEditingName);
                  // Aqui você salvaria o nome no banco de dados
                },
              ),
            ),

            const Divider(height: 24),

            // --- Senha ---
            ListTile(
              leading: const Icon(Icons.lock_outline, color: metroBlue),
              title: const Text(
                'Senha',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              subtitle: const Text(
                '********',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              trailing: TextButton(
                onPressed: () {
                  _showChangePasswordDialog();
                },
                child: const Text('Alterar', style: TextStyle(color: metroBlue)),
              ),
            ),

            const Divider(height: 24),

            // --- Função ---
            const ListTile(
              leading: Icon(Icons.work_outline, color: metroBlue),
              title: Text(
                'Função',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              subtitle: Text(
                'Manutenção do trilho',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              // Sem 'trailing' porque é só informativo
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog para alterar a senha (placeholder)
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar senha'),
        content: const Text(
          'Implementar alteração de senha aqui.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}