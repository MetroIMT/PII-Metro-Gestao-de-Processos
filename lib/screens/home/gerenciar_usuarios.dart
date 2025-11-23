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
  List<User> _filteredMembers = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentRole;
  final Set<String> _processingIds = <String>{};

  final Color metroBlue = const Color(0xFF001489);

  // NOVO: Estado para filtros
  String _searchTerm = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _filterRole; // null = Todos

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadCurrentUserId();
    _checkAdminAndLoad();

    // NOVO: Listener para busca
    _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
        _filterMembers();
      });
    });

    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> _checkAdminAndLoad() async {
    try {
      final role = await AuthService().role;
      if (mounted) {
        setState(() => _currentRole = role);
      }

      // se não for admin, ainda permite ver a lista, mas sem adicionar
      await _loadMembers();
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/');
        });
      }
    }
  }

  Future<void> _loadCurrentUserId() async {
    try {
      const secure = FlutterSecureStorage();
      final id = await secure.read(key: 'userId');
      if (id != null && id.isNotEmpty && mounted) {
        setState(() => _currentUserId = id);
        return;
      }
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('userId');
      if (id != null && id.isNotEmpty && mounted) {
        setState(() => _currentUserId = id);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleRail() {
    if (!mounted) return;

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
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await _userService.getAll();
      if (!mounted) return;

      setState(() {
        _members = members;
        _filterMembers(); // NOVO: Filtra a lista inicial
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

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

  // NOVO: Lógica de filtragem
  void _filterMembers() {
    final term = _searchTerm.toLowerCase();

    _filteredMembers = _members.where((user) {
      // 1. Filtro por termo de busca (Nome, Email, CPF, Telefone, Cargo)
      final matchesSearch = term.isEmpty ||
          user.nome.toLowerCase().contains(term) ||
          user.email.toLowerCase().contains(term) ||
          (user.cpf ?? '').toLowerCase().contains(term) ||
          (user.telefone ?? '').toLowerCase().contains(term) ||
          user.role.toLowerCase().contains(term);

      // 2. Filtro por Cargo
      final matchesRole = _filterRole == null || user.role == _filterRole;

      return matchesSearch && matchesRole;
    }).toList();
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
    String? senha,
  }) async {
    if (!mounted) return false;

    setState(() => _processingIds.add(id));
    try {
      await _userService.update(
        id,
        nome: nome,
        email: email,
        cpf: cpf,
        telefone: telefone,
        role: role,
        senha: senha,
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
      if (mounted) {
        setState(() => _processingIds.remove(id));
      }
    }
  }

  Future<bool> _removeMember(String id) async {
    if (!mounted) return false;

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
      if (mounted) {
        setState(() => _processingIds.remove(id));
      }
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

  // --- FUNÇÃO DE ADICIONAR (mantida) ---
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

        final double dialogWidth = MediaQuery.of(dialogContext).size.width > 550
            ? 500.0 // Largura fixa (500px) para desktop/telas largas
            : MediaQuery.of(dialogContext).size.width * 0.95; // 95% para mobile

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            title: Row(
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  color: metroBlue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Adicionar membro',
                  style: TextStyle(
                    color: metroBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),

            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),

            content: SizedBox(
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
                        decoration: _buildDialogInputDecoration(
                          'Email * (ex: nome@metrosp.com.br)',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o email';
                          final emailNorm = v.trim().toLowerCase();
                          if (!emailNorm.endsWith('@metrosp.com.br')) {
                            return 'Email deve ser @metrosp.com.br';
                          }
                          if (!RegExp(
                            r'^[a-z0-9._%+-]+@metrosp\.com\.br$',
                          ).hasMatch(emailNorm)) {
                            return 'Email inválido';
                          }
                          return null;
                        },
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 11,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Informe o telefone';
                          }
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
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
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

            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                        if (ok) {
                          navigator.pop();
                        } else {
                          setDialogState(() => isSubmitting = false);
                        }
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

  // --- FUNÇÃO DE EDITAR (mantida) ---
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

        final double dialogWidth = MediaQuery.of(dialogContext).size.width > 550
            ? 500.0 // Largura fixa (500px) para desktop/telas largas
            : MediaQuery.of(dialogContext).size.width * 0.95; // 95% para mobile

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: metroBlue, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Editar membro',
                  style: TextStyle(
                    color: metroBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),

            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),

            content: SizedBox(
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
                        decoration: _buildDialogInputDecoration(
                          'Email * (ex: nome@metrosp.com.br)',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Informe o email';
                          final emailNorm = v.trim().toLowerCase();
                          if (!emailNorm.endsWith('@metrosp.com.br')) {
                            return 'Email deve ser @metrosp.com.br';
                          }
                          if (!RegExp(
                            r'^[a-z0-9._%+-]+@metrosp\.com\.br$',
                          ).hasMatch(emailNorm)) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cpfCtrl,
                        decoration: _buildDialogInputDecoration('CPF *'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 11,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Informe o telefone';
                          }
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
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
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

            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
                        if (ok) {
                          navigator.pop();
                        } else {
                          setDialogState(() => isSubmitting = false);
                        }
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

  // NOVO: Widget para construir o card principal (Controles + Tabela)
  Widget _buildMembersCard() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    Widget content;
    if (_isLoading) {
      content = Center(
        child: CircularProgressIndicator(color: metroBlue),
      );
    } else if (_errorMessage != null) {
      content = _buildErrorWidget();
    } else if (_members.isEmpty) {
      content = const Center(
        child: Text(
          'Nenhum usuário cadastrado',
          style: TextStyle(color: Colors.black54),
        ),
      );
    } else if (_filteredMembers.isEmpty) {
      content = const Center(
        child: Text(
          'Nenhum usuário encontrado para o termo ou filtros aplicados.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    } else {
      content = Expanded(child: _buildMembersTable());
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Membros da equipe',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (_currentRole == 'admin')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: metroBlue,
                      foregroundColor: Colors.white,
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
            const SizedBox(height: 16),

            // Busca e Filtro de Cargo (Layout Corrigido para Desktop)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: _searchFocusNode.hasFocus
                          ? 'Buscar por nome, email, CPF ou telefone'
                          : 'Buscar usuário...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  SizedBox( // CORREÇÃO: Usando SizedBox para dar um tamanho fixo e razoável
                    width: 200, 
                    child: DropdownButtonFormField<String>(
                      value: _filterRole,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Cargo',
                        prefixIcon: const Icon(Icons.shield_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos Cargos'),
                        ),
                        const DropdownMenuItem(
                          value: 'admin',
                          child: Text('Admin'),
                        ),
                        const DropdownMenuItem(
                          value: 'gestor',
                          child: Text('Gestor'),
                        ),
                        const DropdownMenuItem(
                          value: 'tecnico',
                          child: Text('Técnico'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _filterRole = v;
                          _filterMembers();
                        });
                      },
                    ),
                  ),
                ],
              ],
            ),

            if (isMobile)
              // Mobile role filter (below search)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _filterRole,
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    hintText: 'Cargo',
                    prefixIcon: const Icon(Icons.shield_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Todos Cargos'),
                    ),
                    const DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                    const DropdownMenuItem(
                      value: 'gestor',
                      child: Text('Gestor'),
                    ),
                    const DropdownMenuItem(
                      value: 'tecnico',
                      child: Text('Técnico'),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _filterRole = v;
                      _filterMembers();
                    });
                  },
                ),
              ),

            const SizedBox(height: 16),

            // Conteúdo principal (tabela, loading, erro, vazio)
            Expanded(
              child: content,
            ),
          ],
        ),
      ),
    );
  }

  // NOVO: Widget para exibir erro
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadMembers,
            style: ElevatedButton.styleFrom(
              backgroundColor: metroBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // NOVO: Widget para construir a Tabela (usando _filteredMembers)
  Widget _buildMembersTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  Colors.grey.shade100,
                ),
                dividerThickness: 1,
                columns: [
                  DataColumn(
                    label: Text(
                      'Nome',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: metroBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Email',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: metroBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CPF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: metroBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Telefone',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: metroBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Cargo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: metroBlue,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Ações',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: metroBlue,
                      ),
                    ),
                  ),
                ],
                rows: _filteredMembers.map((user) {
                  return DataRow(
                    color: WidgetStateProperty.all(
                      Colors.white,
                    ),
                    cells: [
                      DataCell(
                        Text(
                          user.nome,
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          user.email,
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          user.cpf ?? '-',
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          user.telefone ?? '-',
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          _getRoleDisplay(user.role),
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: metroBlue,
                              ),
                              onPressed: () => _showEditDialog(user),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: metroBlue,
                                    ),
                                  ),
                                ),
                              )
                            else
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: (user.id != null &&
                                        user.id != _currentUserId)
                                    ? () async {
                                        final confirm =
                                            await showDialog<bool>(
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
                                                    Navigator.of(context).pop(
                                                  false,
                                                ),
                                                child: const Text('Não'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(
                                                  true,
                                                ),
                                                child: const Text('Sim'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true &&
                                            user.id != null) {
                                          _removeMember(
                                            user.id!,
                                          );
                                        }
                                      }
                                    : null,
                                tooltip: (user.id != null &&
                                        user.id == _currentUserId)
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade100, // Fundo cinza consistente
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
              title: Text(
                'Gerenciar Usuários',
                style: TextStyle(
                  color: metroBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Image.asset('assets/LogoMetro.png', height: 32),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 6))
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
              child: Sidebar(expanded: _isRailExtended, selectedIndex: 6),
            ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: Column(
              children: [
                if (!isMobile)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0), // Header padding consistente
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
                              'Gerenciar Usuários',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: metroBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0), // Conteúdo principal padding consistente
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMobile) const SizedBox(height: 8),
                        const Text(
                          'Gerencie todos os usuários do sistema, suas informações e permissões.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        Expanded(child: _buildMembersCard()),
                      ],
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
}