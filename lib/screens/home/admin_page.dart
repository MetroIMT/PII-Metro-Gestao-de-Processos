import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


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

  bool _isEditingName = false;

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

  // Sessões ativas (simulação)
  List<Map<String, dynamic>> _sessions = [
    {
      'id': 's1',
      'device': 'Chrome · Windows 11',
      'ip': '192.168.0.12',
      'lastSeen': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 's2',
      'device': 'Safari · iPhone',
      'ip': '192.168.1.7',
      'lastSeen': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    },
  ];

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
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('OK')),
          ],
        );
      },
    );

    if (ok == true) {
      setState(() {
        _avatarUrl = controller.text.trim().isEmpty ? null : controller.text.trim();
        _avatarFile = null; // prioriza URL quando definida
      });
    }
  }

  void _removeAvatar() {
    setState(() {
      _avatarUrl = null;
      _avatarFile = null;
    });
  }

  void _revokeSession(String id) {
    setState(() {
      _sessions.removeWhere((s) => s['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sessão encerrada'), behavior: SnackBarBehavior.floating),
    );
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao tirar foto: $e')),
      );
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
            // Avatar + título
            Row(
              children: [
                _avatarSection(),
                const SizedBox(width: 16),
              ],
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
                  ? TextField(
                      // Aparece quando está editando
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
                  : Text(
                      // Aparece quando não está editando
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

            const SizedBox(height: 24),

            // Sessões ativas (simples)
            _buildSessionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _avatarSection() {
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
                TextButton(onPressed: _showAvatarOptions, child: const Text('Alterar foto')),
                if (_avatarFile != null || (_avatarUrl != null && _avatarUrl!.isNotEmpty))
                  TextButton(onPressed: _removeAvatar, child: const Text('Remover')),
              ],
            )
          ],
        )
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
        const Text('Sessões ativas', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        subtitle: Text('${s['ip']} • Último: ${_formatRelative(last)}'),
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
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          Future<void> _attemptChange() async {
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
              setStateDialog(() => errorText = 'A nova senha deve ter ao menos 6 caracteres.');
              return;
            }

            if (next != confirm) {
              setStateDialog(() => errorText = 'As senhas não coincidem.');
              return;
            }

            // Simula processamento (substitua por chamada ao backend)
            setStateDialog(() => isProcessing = true);
            try {
              await Future.delayed(const Duration(milliseconds: 800));
              // Atualiza "senha" localmente
              setState(() => _storedPassword = next);

              // Fecha diálogo
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Senha alterada com sucesso.'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
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
                        _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setStateDialog(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  onSubmitted: (_) => _attemptChange(),
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
                      icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setStateDialog(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  onChanged: (_) => setStateDialog(() {}), // atualiza força
                  onSubmitted: (_) => _attemptChange(),
                ),

                const SizedBox(height: 8),
                // Indicador de força
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (_passwordStrength(_newPasswordController.text)) / 4.0,
                        minHeight: 6,
                        color: _passwordStrengthColor(strength),
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _passwordStrengthLabel(strength),
                      style: TextStyle(color: _passwordStrengthColor(strength)),
                    )
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
                      icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setStateDialog(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  onSubmitted: (_) => _attemptChange(),
                ),

                if (errorText != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
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
                onPressed: isProcessing ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isProcessing ? null : _attemptChange,
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
        });
      },
    );
  }
}
