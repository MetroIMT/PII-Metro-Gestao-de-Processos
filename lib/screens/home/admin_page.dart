import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/user_service.dart';
import '../../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Controllers e estados para alterar senha
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // name editing removed from UI

  // Toggle de visibilidade das senhas no diálogo
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Simulação de senha "armazenada" — no seu app real substitua por verificação no backend
  String _storedPassword = 'password123';

  // Avatar (suporta arquivo local + URL remota)
  final ImagePicker _picker = ImagePicker();
  File? _avatarFile;
  String? _avatarUrl;

  // Sessões ativas (vão ser carregadas do backend quando disponível)
  List<Map<String, dynamic>> _sessions = [];

  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Estado do profile carregado do servidor
  final UserService _userService = UserService();
  User? _user;
  bool _isLoadingProfile = false;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Carrega profile do servidor ao iniciar
    _fetchProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  // ----------------- Helpers novos -----------------

  /// Calcula força de senha simples (0..4)
  int _passwordStrength(String pass) {
    var score = 0;
    if (pass.length >= 6) score++;
    if (pass.contains(RegExp(r'[0-9]'))) score++;
    if (pass.contains(RegExp(r'[A-Z]'))) score++;
    if (pass.contains(RegExp(r'[!@#\\$%\^&\*(),.?":{}|<>]'))) score++;
    return score;
  }

  String _passwordStrengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Muito fraca';
      case 2:
        return 'Fraca';
      case 3:
        return 'Boa';
      case 4:
        return 'Forte';
      default:
        return '';
    }
  }

  Color _passwordStrengthColor(int score) {
    switch (score) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.lightGreen;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _setAvatarFromUrl() async {
    final controller = TextEditingController(text: _avatarUrl ?? '');
    final ok = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Usar URL da imagem'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Cole a URL aqui'),
            keyboardType: TextInputType.url,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      setState(() {
        _avatarUrl = controller.text.trim().isEmpty
            ? null
            : controller.text.trim();
        _avatarFile = null; // prioriza URL quando definida
      });
    }
  }

  void _removeAvatar() {
    // Persist a remoção no backend (PATCH { avatarUrl: null })
    final Future<String?> userIdFuture = _user?.id != null
        ? Future.value(_user!.id)
        : _getStoredUserId();
    userIdFuture.then((userId) async {
      if (userId == null) {
        setState(() {
          _avatarUrl = null;
          _avatarFile = null;
        });
        if (!mounted) return;
        _showSnackbar('Avatar removido localmente');
        return;
      }

      try {
        final updated = await _userService.removeAvatar(userId);
        if (!mounted) return;
        setState(() {
          _user = updated;
          _avatarUrl = updated.avatarUrl;
          _avatarFile = null;
        });
        _showSnackbar('Avatar removido com sucesso');
      } catch (e) {
        if (!mounted) return;
        _showSnackbar('Erro ao remover avatar: $e');
      }
    });
  }

  Future<void> _fetchSessions() async {
    final id = _user?.id ?? await _getStoredUserId();
    if (id == null) return;

    try {
      final list = await _userService.getSessions(id);
      final parsed = list.map((s) {
        DateTime? last;
        final raw = s['lastSeen'];
        if (raw is String) {
          try {
            last = DateTime.parse(raw);
          } catch (_) {
            last = null;
          }
        } else if (raw is DateTime) {
          last = raw;
        }
        return {
          'id': s['id']?.toString(),
          'device': s['device'] ?? 'Desconhecido',
          'ip': s['ip'],
          'lastSeen': last ?? DateTime.now(),
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _sessions = parsed;
      });
    } catch (e) {
      // se falhar, mantemos sessões locais e silenciosamente falhamos
      // (a lista de sessões não é crítica)
    }
  }

  // Helper seguro para exibir SnackBars sem usar diretamente `context` após awaits
  void _showSnackbar(
    String message, {
    Color? backgroundColor,
    SnackBarBehavior? behavior,
  }) {
    final ctx = _scaffoldKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: behavior,
      ),
    );
  }

  Future<void> _uploadAvatar() async {
    if (_avatarFile == null) return;
    final id = _user?.id ?? await _getStoredUserId();
    if (id == null) {
      if (!mounted) return;
      _showSnackbar('Usuário não autenticado');
      return;
    }

    try {
      final updated = await _userService.uploadAvatar(id, _avatarFile!);
      if (!mounted) return;
      setState(() {
        _user = updated;
        _avatarUrl = updated.avatarUrl;
        _avatarFile = null;
      });
      if (!mounted) return;
      _showSnackbar('Avatar enviado com sucesso');
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Erro ao enviar avatar: $e');
    }
  }

  Future<String?> _getStoredUserId() async {
    final secure = const FlutterSecureStorage();
    try {
      final id = await secure.read(key: 'userId');
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('userId');
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}

    return null;
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    final id = await _getStoredUserId();
    if (id == null) {
      setState(() {
        _profileError = 'Usuário não autenticado';
        _isLoadingProfile = false;
      });
      return;
    }

    try {
      final user = await _userService.getById(id);
      setState(() {
        _user = user;
        _nameController.text = user.nome;
        if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
          _avatarUrl = user.avatarUrl;
        }
        _isLoadingProfile = false;
      });
      // carrega sessões do backend (se disponível)
      await _fetchSessions();
    } catch (e) {
      setState(() {
        _profileError = e.toString();
        _isLoadingProfile = false;
      });
    }
  }

  // name editing removed; no local save function

  void _revokeSession(String id) {
    // Tenta revogar no backend, se possível
    final Future<String?> userIdFuture = _user?.id != null
        ? Future.value(_user!.id)
        : _getStoredUserId();
    userIdFuture.then((userId) async {
      if (userId == null) {
        setState(() {
          _sessions.removeWhere((s) => s['id'] == id);
        });
        if (!mounted) return;
        _showSnackbar(
          'Sessão local encerrada',
          behavior: SnackBarBehavior.floating,
        );
        return;
      }

      try {
        await _userService.revokeSession(userId, id);
        if (!mounted) return;
        setState(() {
          _sessions.removeWhere((s) => s['id'] == id);
        });
        _showSnackbar('Sessão encerrada', behavior: SnackBarBehavior.floating);
      } catch (e) {
        if (!mounted) return;
        _showSnackbar('Erro ao encerrar sessão: $e');
      }
    });
  }

  // PICKERS
  Future<void> _pickFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _avatarFile = File(picked.path);
          _avatarUrl = null;
        });
        // Após selecionar, envie para o backend
        _uploadAvatar();
      }
    } catch (e) {
      _showSnackbar('Erro ao selecionar imagem: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _avatarFile = File(picked.path);
          _avatarUrl = null;
        });
        // Após tirar foto, envie para o backend
        _uploadAvatar();
      }
    } catch (e) {
      _showSnackbar('Erro ao tirar foto: $e');
    }
  }

  // --------------------------------------------------

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
                style: TextStyle(color: metroBlue, fontWeight: FontWeight.bold),
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
      // Drawer (menu) só existe no mobile
      drawer: isMobile
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: -1))
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
              child: Sidebar(expanded: _isRailExtended, selectedIndex: -1),
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
                if (!isMobile) _buildDesktopHeader(),

                // Card principal com o conteúdo
                Expanded(
                  child: Padding(
                    // Padding diferente para mobile e desktop
                    padding: EdgeInsets.all(isMobile ? 16 : 32),
                    child: SingleChildScrollView(child: _buildProfileCard()),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
              const Text(
                'Perfil do Administrador',
                style: TextStyle(
                  color: metroBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          Image.asset('assets/LogoMetro.png', height: 40),
        ],
      ),
    );
  }

  /// O Card principal com as informações do perfil
  Widget _buildProfileCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withAlpha(20),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + título
            Row(children: [_avatarSection(), const SizedBox(width: 16)]),

            const SizedBox(height: 16),

            if (_profileError != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _profileError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // --- Nome ---
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: metroBlue),
              title: const Text(
                'Nome',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              subtitle: Text(
                _nameController.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              // removed edit button per request
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
                child: const Text(
                  'Alterar',
                  style: TextStyle(color: metroBlue),
                ),
              ),
            ),

            const Divider(height: 24),
            // --- CPF ---
            ListTile(
              leading: const Icon(Icons.credit_card, color: metroBlue),
              title: const Text(
                'CPF',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              subtitle: Text(
                _user?.cpf ?? '—',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              trailing: TextButton(
                onPressed: _editCpf,
                child: const Text('Editar'),
              ),
            ),

            const SizedBox(height: 8),

            // --- Telefone ---
            ListTile(
              leading: const Icon(Icons.phone, color: metroBlue),
              title: const Text(
                'Telefone',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              subtitle: Text(
                _user?.telefone ?? '—',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              trailing: TextButton(
                onPressed: _editTelefone,
                child: const Text('Editar'),
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

            const SizedBox(height: 24),

            // Sessões ativas (simples)
            _buildSessionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _avatarSection() {
    if (_isLoadingProfile) {
      return Row(
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(width: 200, child: Text('Carregando...')),
            ],
          ),
        ],
      );
    }
    ImageProvider? image;
    if (_avatarFile != null) {
      image = FileImage(_avatarFile!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      image = NetworkImage(_avatarUrl!);
    }

    return Row(
      children: [
        GestureDetector(
          onTap: _showAvatarOptions,
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade100,
            backgroundImage: image,
            child: image == null
                ? const Icon(Icons.person, size: 40, color: metroBlue)
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _nameController.text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: _showAvatarOptions,
                  child: const Text('Alterar foto'),
                ),
                if (_avatarFile != null ||
                    (_avatarUrl != null && _avatarUrl!.isNotEmpty))
                  TextButton(
                    onPressed: _removeAvatar,
                    child: const Text('Remover'),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Usar URL da imagem'),
                onTap: () {
                  Navigator.pop(context);
                  _setAvatarFromUrl();
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sessões ativas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.grey.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: _sessions.isEmpty
                  ? [
                      const SizedBox(height: 8),
                      const Text('Nenhuma sessão ativa.'),
                    ]
                  : _sessions.map((s) {
                      final last = s['lastSeen'] as DateTime;
                      return ListTile(
                        leading: const Icon(Icons.devices),
                        title: Text(s['device']),
                        subtitle: Text(
                          '${s['ip']} • Último: ${_formatRelative(last)}',
                        ),
                        trailing: TextButton(
                          onPressed: () => _revokeSession(s['id'] as String),
                          child: const Text('Encerrar'),
                        ),
                      );
                    }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }

  /// Dialog para alterar a senha (implementado) — com indicador de força
  void _showChangePasswordDialog() {
    // Limpa campos ao abrir
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _obscureCurrent = true;
    _obscureNew = true;
    _obscureConfirm = true;

    // Controla estado interno do diálogo
    bool isProcessing = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: !isProcessing,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setStateDialog) {
            Future<void> attemptChange() async {
              // Validações
              final current = _currentPasswordController.text;
              final next = _newPasswordController.text;
              final confirm = _confirmPasswordController.text;

              setStateDialog(() => errorText = null);

              if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
                setStateDialog(() => errorText = 'Preencha todos os campos.');
                return;
              }

              if (current != _storedPassword) {
                setStateDialog(() => errorText = 'Senha atual incorreta.');
                return;
              }

              if (next.length < 6) {
                setStateDialog(
                  () => errorText =
                      'A nova senha deve ter ao menos 6 caracteres.',
                );
                return;
              }

              if (next != confirm) {
                setStateDialog(() => errorText = 'As senhas não coincidem.');
                return;
              }

              // Simula processamento (substitua por chamada ao backend)
              setStateDialog(() => isProcessing = true);
              try {
                final navigator = Navigator.of(dialogContext);
                await Future.delayed(const Duration(milliseconds: 800));
                // Atualiza "senha" localmente
                setState(() => _storedPassword = next);

                // Fecha diálogo
                if (mounted) {
                  navigator.pop();
                  _showSnackbar(
                    'Senha alterada com sucesso.',
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  );
                }
              } catch (e) {
                setStateDialog(() => errorText = 'Erro ao alterar senha.');
              } finally {
                setStateDialog(() => isProcessing = false);
              }
            }

            final strength = _passwordStrength(_newPasswordController.text);

            return AlertDialog(
              title: const Text('Alterar senha'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Campo senha atual
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Senha atual',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setStateDialog(
                          () => _obscureCurrent = !_obscureCurrent,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => attemptChange(),
                  ),
                  const SizedBox(height: 12),

                  // Nova senha
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nova senha',
                      hintText: 'Mínimo 6 caracteres',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setStateDialog(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    onChanged: (_) => setStateDialog(() {}), // atualiza força
                    onSubmitted: (_) => attemptChange(),
                  ),

                  const SizedBox(height: 8),
                  // Indicador de força
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value:
                              (_passwordStrength(_newPasswordController.text)) /
                              4.0,
                          minHeight: 6,
                          color: _passwordStrengthColor(strength),
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _passwordStrengthLabel(strength),
                        style: TextStyle(
                          color: _passwordStrengthColor(strength),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Confirmar nova senha
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar nova senha',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setStateDialog(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => attemptChange(),
                  ),

                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorText!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isProcessing ? null : attemptChange,
                  style: ElevatedButton.styleFrom(backgroundColor: metroBlue),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showEditDialog(String title, String initial) async {
    final controller = TextEditingController(text: initial);
    final ok = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Editar $title'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: title),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    if (ok == true) return controller.text.trim();
    return null;
  }

  Future<void> _editCpf() async {
    final current = _user?.cpf ?? '';
    final value = await _showEditDialog('CPF', current);
    if (value == null) return;
    final id = _user?.id ?? await _getStoredUserId();
    if (id == null) return;
    try {
      final updated = await _userService.update(id, cpf: value);
      if (!mounted) return;
      setState(() => _user = updated);
      if (!mounted) return;
      _showSnackbar('CPF atualizado');
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Erro ao atualizar CPF: $e');
    }
  }

  Future<void> _editTelefone() async {
    final current = _user?.telefone ?? '';
    final value = await _showEditDialog('Telefone', current);
    if (value == null) return;
    final id = _user?.id ?? await _getStoredUserId();
    if (id == null) return;
    try {
      final updated = await _userService.update(id, telefone: value);
      if (!mounted) return;
      setState(() => _user = updated);
      if (!mounted) return;
      _showSnackbar('Telefone atualizado');
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Erro ao atualizar telefone: $e');
    }
  }
}
