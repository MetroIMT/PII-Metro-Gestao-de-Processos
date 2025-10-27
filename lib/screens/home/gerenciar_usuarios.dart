import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart'; 

// Classe do Modelo de Dados (do seu novo código)
class _Member {
  final String name;
  final String cpf;
  final String phone;
  final String role;

  _Member({
    required this.name,
    required this.cpf,
    required this.phone,
    required this.role,
  });
}

class GerenciarUsuarios extends StatefulWidget {
  const GerenciarUsuarios({Key? key}) : super(key: key);

  @override
  State<GerenciarUsuarios> createState() => _GerenciarUsuariosState();
}

class _GerenciarUsuariosState extends State<GerenciarUsuarios>
    with SingleTickerProviderStateMixin {
      
  // --- Início da Lógica de Layout (IDÊNTICA à HomeScreen) ---
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
  // --- Fim da Lógica de Layout ---

  // --- Início da Lógica de Dados (Mesclada do PeoplePage) ---
  final Color metroBlue = const Color(0xFF001489);
  final Color backgroundColor = const Color(0xFFF4F5FA);

  // Usando o modelo _Member e os dados do seu exemplo
  final List<_Member> _members = [
    _Member(
        name: 'Ana Silva',
        cpf: '123.456.789-00',
        phone: '(11) 91234-5678',
        role: 'Gestor'),
    _Member(
        name: 'João Pereira',
        cpf: '987.654.321-00',
        phone: '(11) 99876-5432',
        role: 'Operador'),
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

  // Popup para adicionar novo membro (do seu exemplo)
  Future<void> _showAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final cpfCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String role = 'Operador';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: cpfCtrl,
                  decoration: const InputDecoration(labelText: 'CPF'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o CPF' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Telefone'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Informe o telefone' : null,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  items: const [
                    DropdownMenuItem(value: 'Gestor', child: Text('Gestor')),
                    DropdownMenuItem(
                        value: 'Operador', child: Text('Operador')),
                  ],
                  onChanged: (v) {
                    if (v != null) role = v;
                  },
                  decoration: const InputDecoration(labelText: 'Cargo'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: metroBlue, // Aplicando o estilo
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _addMember(_Member(
                    name: nameCtrl.text.trim(),
                    cpf: cpfCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    role: role));
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
  // --- Fim da Lógica de Dados ---

  @override
  Widget build(BuildContext context) {
    // Detectar se está em modo mobile (copiado da HomeScreen)
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor, // Fundo cinza claro
      
      // AppBar apenas no mobile
      appBar: isMobile
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: AnimatedIcon(
                  icon: AnimatedIcons.menu_close,
                  progress: _animationController,
                  color: const Color(0xFF001489),
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              title: const Text(
                'Gerenciar Usuários',
                style: TextStyle(
                  color: Color(0xFF001489),
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
      
      // Drawer apenas no mobile
      drawer: isMobile
          ? Drawer(
              child: Sidebar( // CHAMA A SIDEBAR DO PASSO 1
                expanded: true, 
                selectedIndex: 4, // Índice 4 = Gerenciar Usuários
              ),
            )
          : null,
      
      // Body com Stack para o layout desktop
      body: Stack(
        children: [
          // Barra lateral fixa em desktop
          if (!isMobile)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              top: 0,
              bottom: 0,
              width: _isRailExtended ? 180 : 70,
              child: Sidebar( // CHAMA A SIDEBAR DO PASSO 1
                expanded: _isRailExtended,
                selectedIndex: 4, 
              ),
            ),

          // Conteúdo principal (DataTable)
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com título (apenas em desktop)
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
                                color: const Color(0xFF001489),
                              ),
                              onPressed: _toggleRail,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Gerenciar Usuários',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001489),
                              ),
                            ),
                          ],
                        ),
                        Image.asset('assets/LogoMetro.png', height: 40),
                      ],
                    ),
                  ),

                // Card com o botão "Adicionar" (do seu exemplo)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, isMobile ? 16 : 0, 16, 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           Text('Membros da equipe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              )),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: metroBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

                // Tabela de Dados (do seu exemplo)
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
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: Card( 
                                 elevation: 2,
                                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                 clipBehavior: Clip.antiAlias, 
                                 child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade100),
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
                                            icon: Icon(Icons.edit,
                                                color: Colors.blue.shade700),
                                            onPressed: () {
                                              // TODO: Criar _showEditDialog(m)
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () async {
                                              final confirm =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      'Remover membro'),
                                                  content: Text(
                                                      'Confirma remoção de ${m.name}?'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(context)
                                                                .pop(false),
                                                        child:
                                                            const Text('Não')),
                                                    TextButton(
                                                        onPressed: () =>
                                                            Navigator.of(context)
                                                                .pop(true),
                                                        child:
                                                            const Text('Sim')),
                                                  ],
                                                ),
                                              );
                                              if (confirm == true)
                                                _removeMember(index);
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
                        );
                      }
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Espaçamento inferior
              ],
            ),
          ),
        ],
      ),
    );
  }
}