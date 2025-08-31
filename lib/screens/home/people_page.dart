import 'package:flutter/material.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final List<_Member> _members = [
    _Member(name: 'Ana Silva', cpf: '123.456.789-00', phone: '(11) 91234-5678', role: 'Gestor'),
    _Member(name: 'João Pereira', cpf: '987.654.321-00', phone: '(11) 99876-5432', role: 'Operador'),
  ];

  void _addMember(_Member m) {
    setState(() {
      _members.add(m);
    });
  }

  void _removeMember(int index) {
    setState(() {
      _members.removeAt(index);
    });
  }

  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final cpfCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'Operador';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adicionar membro'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: cpfCtrl,
                  decoration: const InputDecoration(labelText: 'CPF'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o CPF' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Informe o telefone' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(value: 'Gestor', child: Text('Gestor')),
                    DropdownMenuItem(value: 'Operador', child: Text('Operador')),
                  ],
                  onChanged: (v) { if (v != null) role = v; },
                  decoration: const InputDecoration(labelText: 'Cargo'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _addMember(_Member(name: nameCtrl.text.trim(), cpf: cpfCtrl.text.trim(), phone: phoneCtrl.text.trim(), role: role));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    nameCtrl.dispose();
    cpfCtrl.dispose();
    phoneCtrl.dispose();
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
                    const Text('Membros da equipe', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Nome')),
                      DataColumn(label: Text('CPF')),
                      DataColumn(label: Text('Telefone')),
                      DataColumn(label: Text('Cargo')),
                      DataColumn(label: Text('Ações')),
                    ],
                    rows: List.generate(_members.length, (index) {
                      final m = _members[index];
                      return DataRow(cells: [
                        DataCell(Text(m.name)),
                        DataCell(Text(m.cpf)),
                        DataCell(Text(m.phone)),
                        DataCell(Text(m.role)),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Remover membro'),
                                    content: const Text('Confirma remoção deste membro?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Não')),
                                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sim')),
                                    ],
                                  ),
                                );
                                if (confirm == true) _removeMember(index);
                              },
                            ),
                          ],
                        )),
                      ]);
                    }),
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

class _Member {
  final String name;
  final String cpf;
  final String phone;
  final String role;

  _Member({required this.name, required this.cpf, required this.phone, required this.role});
}
