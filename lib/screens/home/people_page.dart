import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final UserService _userService = UserService();
  List<User> _members = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
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
          SnackBar(content: Text('Erro ao carregar pessoas: $e')),
        );
      }
    }
  }

  Future<void> _addMember({
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
          const SnackBar(content: Text('Pessoa adicionada com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao adicionar pessoa: $e')),
        );
      }
    }
  }

  Future<void> _updateMember(String id, {
    String? nome,
    String? email,
    String? cpf,
    String? telefone,
    String? role,
  }) async {
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
          const SnackBar(content: Text('Pessoa atualizada com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar pessoa: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String id) async {
    try {
      await _userService.delete(id);
      await _loadMembers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pessoa removida com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover pessoa: $e')),
        );
      }
    }
  }

  void _showAddDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final senhaCtrl = TextEditingController();
    final cpfCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String selectedRole = 'tecnico';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Adicionar membro'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o email' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: senhaCtrl,
                    decoration: const InputDecoration(labelText: 'Senha *'),
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cpfCtrl,
                    decoration: const InputDecoration(labelText: 'CPF *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o CPF' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Telefone *'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o telefone' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,  // ✅ initialValue (não value)
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'gestor', child: Text('Gestor')),
                      DropdownMenuItem(value: 'tecnico', child: Text('Técnico')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          selectedRole = v;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Cargo *'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _addMember(
                    nome: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    senha: senhaCtrl.text.trim(),
                    cpf: cpfCtrl.text.trim(),
                    telefone: phoneCtrl.text.trim(),
                    role: selectedRole,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    ).then((_) {  // ✅ Dispose DEPOIS do diálogo fechar
      nameCtrl.dispose();
      emailCtrl.dispose();
      senhaCtrl.dispose();
      cpfCtrl.dispose();
      phoneCtrl.dispose();
    });
  }

  void _showEditDialog(User user) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: user.nome);
    final emailCtrl = TextEditingController(text: user.email);
    final cpfCtrl = TextEditingController(text: user.cpf ?? '');
    final phoneCtrl = TextEditingController(text: user.telefone ?? '');
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar membro'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email *'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o email' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: cpfCtrl,
                    decoration: const InputDecoration(labelText: 'CPF *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o CPF' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Telefone *'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => (v == null || v.isEmpty) ? 'Informe o telefone' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,  // ✅ initialValue (não value)
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'gestor', child: Text('Gestor')),
                      DropdownMenuItem(value: 'tecnico', child: Text('Técnico')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() {
                          selectedRole = v;
                        });
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Cargo *'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _updateMember(
                    user.id!,
                    nome: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    cpf: cpfCtrl.text.trim(),
                    telefone: phoneCtrl.text.trim(),
                    role: selectedRole,
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    ).then((_) {  // ✅ Dispose DEPOIS do diálogo fechar
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
    return Scaffold(
      appBar: AppBar(title: const Text('Pessoas')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Membros da equipe',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Adicionar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMembers,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_members.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Nenhuma pessoa cadastrada'),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('CPF')),        // ✅ NOVO
                        DataColumn(label: Text('Telefone')),   // ✅ NOVO
                        DataColumn(label: Text('Cargo')),
                        DataColumn(label: Text('Ações')),
                      ],
                      rows: _members.map((user) {
                        return DataRow(cells: [
                          DataCell(Text(user.nome)),
                          DataCell(Text(user.email)),
                          DataCell(Text(user.cpf ?? '-')),        // ✅ NOVO
                          DataCell(Text(user.telefone ?? '-')),   // ✅ NOVO
                          DataCell(Text(_getRoleDisplay(user.role))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDialog(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Remover membro'),
                                      content: const Text('Confirma remoção deste membro?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Não'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Sim'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && user.id != null) {
                                    _removeMember(user.id!);
                                  }
                                },
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}