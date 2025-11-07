import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class GerenciarUsuarios extends StatefulWidget {
  const GerenciarUsuarios({super.key});

  @override
  State<GerenciarUsuarios> createState() => _GerenciarUsuariosState();
}

class _GerenciarUsuariosState extends State<GerenciarUsuarios>
    with SingleTickerProviderStateMixin {
  // Layout
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Dados
  final UserService _userService = UserService();
  List<User> _members = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentRole;
  final Set<String> _processingIds = <String>{};

  final Color metroBlue = const Color(0xFF001489);
  final Color backgroundColor = const Color.fromARGB(255, 255, 255, 255);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCurrentUserId();
    _checkAdminAndLoad();
  }

  Future<void> _checkAdminAndLoad() async {
    try {
      final role = await AuthService().role;
      setState(() => _currentRole = role); // salva o cargo atual

      // se não for admin, ainda permite ver a lista, mas sem adicionar
      await _loadMembers();
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/');
      });
    }
  }


  Future<void> _loadCurrentUserId() async {
    try {
      const secure = FlutterSecureStorage();
      final id = await secure.read(key: 'userId');
      if (id != null && id.isNotEmpty) {
        setState(() => _currentUserId = id);
        return;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('userId');
      if (id != null && id.isNotEmpty) setState(() => _currentUserId = id);
    } catch (_) {}
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

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await _userService.getAll();
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar usuários: $e')),
        );
      }
    }
  }

  Future<bool> _addMember({
    required String nome,
    required String email,
    required String senha,
    required String cpf,
    required String telefone,
    required String role,
  }) async {
    try {
      await _userService.create(
        nome: nome,
        email: email,
        senha: senha,
        cpf: cpf,
        telefone: telefone,
        role: role,
      );
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário adicionado com sucesso')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar usuário: $e')),
        );
      }
      return false;
    }
  }

  Future<bool> _updateMember(
    String id, {
    String? nome,
    String? email,
    String? cpf,
    String? telefone,
    String? role,
  }) async {
    setState(() => _processingIds.add(id));
    try {
      await _userService.update(
        id,
        nome: nome,
        email: email,
        cpf: cpf,
        telefone: telefone,
        role: role,
      );
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário atualizado com sucesso')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar usuário: $e')),
        );
      }
      return false;
    } finally {
      setState(() => _processingIds.remove(id));
    }
  }

  Future<bool> _removeMember(String id) async {
    setState(() => _processingIds.add(id));
    try {
      await _userService.delete(id);
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário removido com sucesso')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao remover usuário: $e')));
      }
      return false;
    } finally {
      setState(() => _processingIds.remove(id));
    }
  }

  // Helper para o Input Style (cinza, borda arredondada)
  InputDecoration _buildDialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54), // Texto "preto"
      filled: true,
      fillColor: Colors.grey.shade100, // Fundo "cinza"
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: metroBlue, width: 2), // Borda "metroBlue"
      ),
    );
  }

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    final cpfCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'tecnico';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;

        // --- MUDANÇA 1 (LARGURA DO DIÁLOGO) ---
        final double dialogWidth = MediaQuery.of(dialogContext).size.width > 550
            ? 500.0 // Largura fixa (500px) para desktop/telas largas
            : MediaQuery.of(dialogContext).size.width * 0.95; // 95% para mobile

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Adicionar membro'),
            content: SizedBox( // --- MUDANÇA 1 (LARGURA DO DIÁLOGO) ---
              width: dialogWidth,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: _buildDialogInputDecoration('Nome *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: _buildDialogInputDecoration('Email *'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: senhaCtrl,
                        decoration: _buildDialogInputDecoration('Senha *'),
                        obscureText: true,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe a senha' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cpfCtrl,
                        decoration: _buildDialogInputDecoration('CPF *'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 11,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o CPF';
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length != 11) {
                            return 'CPF deve conter 11 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: _buildDialogInputDecoration('Telefone *'),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 11,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o telefone';
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 10 || digits.length > 11) {
                            return 'Telefone deve conter DDD + número (10 ou 11 dígitos)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(
                            value: 'gestor',
                            child: Text('Gestor'),
                          ),
                          DropdownMenuItem(
                            value: 'tecnico',
                            child: Text('Técnico'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedRole = v);
                        },
                        decoration: _buildDialogInputDecoration('Cargo *'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancelar', style: TextStyle(color: metroBlue)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: metroBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);
                        final navigator = Navigator.of(dialogContext);
                        final ok = await _addMember(
                          nome: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          senha: senhaCtrl.text.trim(),
                          cpf: cpfCtrl.text.trim(),
                          telefone: phoneCtrl.text.trim(),
                          role: selectedRole,
                        );
                        setDialogState(() => isSubmitting = false);
                        if (ok) navigator.pop();
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Adicionar'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      senhaCtrl.dispose();
      cpfCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  Future<void> _showEditDialog(User user) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.nome);
    final emailCtrl = TextEditingController(text: user.email);
    final cpfCtrl = TextEditingController(text: user.cpf ?? '');
    final phoneCtrl = TextEditingController(text: user.telefone ?? '');
    String selectedRole = user.role;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;

        // --- MUDANÇA 1 (LARGURA DO DIÁLOGO) ---
        final double dialogWidth = MediaQuery.of(dialogContext).size.width > 550
            ? 500.0 // Largura fixa (500px) para desktop/telas largas
            : MediaQuery.of(dialogContext).size.width * 0.95; // 95% para mobile

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Editar membro'),
            content: SizedBox( // --- MUDANÇA 1 (LARGURA DO DIÁLOGO) ---
              width: dialogWidth,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: _buildDialogInputDecoration('Nome *'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o nome' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: _buildDialogInputDecoration('Email *'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Informe o email' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cpfCtrl,
                        decoration: _buildDialogInputDecoration('CPF *'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 11,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o CPF';
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length != 11) {
                            return 'CPF deve conter 11 dígitos';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: _buildDialogInputDecoration('Telefone *'),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        maxLength: 11,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o telefone';
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 10 || digits.length > 11) {
                            return 'Telefone deve conter DDD + número (10 ou 11 dígitos)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(
                            value: 'gestor',
                            child: Text('Gestor'),
                          ),
                          DropdownMenuItem(
                            value: 'tecnico',
                            child: Text('Técnico'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => selectedRole = v);
                        },
                        decoration: _buildDialogInputDecoration('Cargo *'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text('Cancelar', style: TextStyle(color: metroBlue)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: metroBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);
                        final navigator = Navigator.of(dialogContext);
                        final ok = await _updateMember(
                          user.id!,
                          nome: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          cpf: cpfCtrl.text.trim(),
                          telefone: phoneCtrl.text.trim(),
                          role: selectedRole,
                        );
                        setDialogState(() => isSubmitting = false);
                        if (ok) navigator.pop();
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      nameCtrl.dispose();
      emailCtrl.dispose();
      cpfCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  String _getRoleDisplay(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'gestor':
        return 'Gestor';
      case 'tecnico':
        return 'Técnico';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor, // "Branco"
      appBar: isMobile
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white, // "Branco"
              leading: IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _animationController,
                  color: metroBlue, // "Metro Blue"
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              title: const Text(
                'Gerenciar Usuários',
                style: TextStyle(
                  color: Color(0xFF001489), // "Metro Blue"
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
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 5))
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
              child: Sidebar(expanded: _isRailExtended, selectedIndex: 5),
            ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                                color: metroBlue, // "Metro Blue"
                              ),
                              onPressed: _toggleRail,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Gerenciar Usuários',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001489), // "Metro Blue"
                              ),
                            ),
                          ],
                        ),
                        Image.asset('assets/LogoMetro.png', height: 40),
                      ],
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, isMobile ? 16 : 0, 16, 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white, // "Branco"
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Membros da equipe',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800, // "Preto/Cinza"
                        ),
                      ),
                      if (_currentRole == 'admin')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: metroBlue, // "Metro Blue"
                            foregroundColor: Colors.white, // "Branco"
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _showAddDialog,
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Adicionar'),
                        ),
                    ],
                  ),

                    ),
                  ),
                ),
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: metroBlue, // "Metro Blue"
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red, // Cor semântica mantida
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black87), // "Preto"
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMembers,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: metroBlue, // "Metro Blue"
                              foregroundColor: Colors.white, // "Branco"
                            ),
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_members.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Nenhum usuário cadastrado',
                        style: TextStyle(color: Colors.black54), // "Preto/Cinza"
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: DataTable(
                                    // --- MUDANÇA 2 (COR DO HEADER) ---
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.grey.shade100, // "Cinza"
                                    ),
                                    dividerThickness: 1,
                                    columns: [
                                      DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold, color: metroBlue))),
                                      DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, color: metroBlue))),
                                      DataColumn(label: Text('CPF', style: TextStyle(fontWeight: FontWeight.bold, color: metroBlue))),
                                      DataColumn(label: Text('Telefone', style: TextStyle(fontWeight: FontWeight.bold, color: metroBlue))),
                                      DataColumn(label: Text('Cargo', style: TextStyle(fontWeight: FontWeight.bold, color: metroBlue))),
                                      DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold, color: metroBlue))),
                                    ],


                                    rows: _members.map((user) {
                                      return DataRow(
                                        color: WidgetStateProperty.all(Colors.white), // "Branco"
                                        cells: [
                                          DataCell(Text(user.nome, style: const TextStyle(color: Colors.black87))),
                                          DataCell(Text(user.email, style: const TextStyle(color: Colors.black87))),
                                          DataCell(Text(user.cpf ?? '-', style: const TextStyle(color: Colors.black87))),
                                          DataCell(Text(user.telefone ?? '-', style: const TextStyle(color: Colors.black87))),
                                          DataCell(
                                            Text(_getRoleDisplay(user.role), style: const TextStyle(color: Colors.black87)),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.edit,
                                                    color: metroBlue, // "Metro Blue"
                                                  ),
                                                  onPressed: () =>
                                                      _showEditDialog(user),
                                                ),
                                                if (user.id != null &&
                                                    _processingIds.contains(
                                                      user.id,
                                                    ))
                                                  SizedBox(
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(
                                                      child: SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: metroBlue, // "Metro Blue"
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red, // Semântico
                                                    ),
                                                    onPressed:
                                                        (user.id != null &&
                                                            user.id !=
                                                                _currentUserId)
                                                        ? () async {
                                                            final confirm = await showDialog<bool>(
                                                              context: context,
                                                              builder: (_) => AlertDialog(
                                                                title: const Text(
                                                                  'Remover membro',
                                                                ),
                                                                content: Text(
                                                                  'Confirma remoção de ${user.nome}?',
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop(
                                                                          false,
                                                                        ),
                                                                    child:
                                                                        const Text(
                                                                          'Não',
                                                                        ),
                                                                  ),
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.of(
                                                                          context,
                                                                        ).pop(
                                                                          true,
                                                                        ),
                                                                    child:
                                                                        const Text(
                                                                          'Sim',
                                                                        ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                            if (confirm ==
                                                                    true &&
                                                                user.id !=
                                                                    null) {
                                                              _removeMember(
                                                                user.id!,
                                                              );

                                                            }
                                                          }
                                                        : null,
                                                    tooltip:
                                                        (user.id != null &&
                                                            user.id ==
                                                                _currentUserId)
                                                        ? 'Não é possível remover o usuário atual'
                                                        : 'Remover',
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}