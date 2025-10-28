import 'package:flutter/material.dart';
import '../../widgets/sidebar.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  static const Color metroBlue = Color(0xFF001489);

  final TextEditingController _nameController =
      TextEditingController(text: 'Breno Augusto Gandolf');

  bool _isEditingName = false;
  bool _isSidebarExpanded = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      body: Row(
        children: [
          Sidebar(expanded: _isSidebarExpanded, selectedIndex: 0),

          Expanded(
            child: Column(
              children: [
                AppBar(
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.menu, color: metroBlue),
                    onPressed: () {
                      setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                    },
                  ),
                  title: const Text(
                    'Perfil',
                    style: TextStyle(
                      color: metroBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // 🔹 Corpo da página
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // --- Nome ---
                        const Text('Nome', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        _isEditingName
                            ? Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _nameController,
                                      autofocus: true,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 4),
                                        border: UnderlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: metroBlue),
                                    onPressed: () {
                                      setState(() => _isEditingName = false);
                                    },
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Text(
                                    _nameController.text,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        size: 20, color: metroBlue),
                                    onPressed: () {
                                      setState(() => _isEditingName = true);
                                    },
                                  ),
                                ],
                              ),
                        const SizedBox(height: 28),

                        // --- Senha ---
                        const Text('Senha', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              '********',
                              style:
                                  TextStyle(fontSize: 20, letterSpacing: 4),
                            ),
                            const SizedBox(width: 20),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Alterar senha'),
                                    content: const Text(
                                        'Implementar alteração de senha aqui.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Fechar'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text(
                                'Alterar a senha',
                                style: TextStyle(
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // --- Função ---
                        const Text('Função', style: TextStyle(fontSize: 14)),
                        const SizedBox(height: 8),
                        const Text(
                          'Manutenção do trilho',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
                        ),
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
