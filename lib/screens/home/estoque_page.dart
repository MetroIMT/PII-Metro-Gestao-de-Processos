import 'package:flutter/material.dart';

class EstoqueMaterial {
  final String codigo;
  final String nome;
  final int quantidade;
  final String local;

  EstoqueMaterial({
    required this.codigo,
    required this.nome,
    required this.quantidade,
    required this.local,
  });

  String get status => quantidade > 0 ? 'Disponível' : 'Em Falta';
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Lista de exemplo de materiais
  final List<EstoqueMaterial> _materiais = [
    EstoqueMaterial(codigo: 'M001', nome: 'Cabo Elétrico 2.5mm', quantidade: 150, local: 'Base A'),
    EstoqueMaterial(codigo: 'M002', nome: 'Disjuntor 20A', quantidade: 45, local: 'Base B'),
    EstoqueMaterial(codigo: 'M003', nome: 'Conduíte Flexível 20mm', quantidade: 0, local: 'Base A'),
    EstoqueMaterial(codigo: 'M004', nome: 'Terminal Elétrico', quantidade: 230, local: 'Base C'),
    EstoqueMaterial(codigo: 'M005', nome: 'Fusível 10A', quantidade: 0, local: 'Base B'),
    EstoqueMaterial(codigo: 'M006', nome: 'Luva de Emenda 25mm', quantidade: 75, local: 'Base D'),
    EstoqueMaterial(codigo: 'M007', nome: 'Relé de Proteção', quantidade: 18, local: 'Base A'),
    EstoqueMaterial(codigo: 'M008', nome: 'Chave Seccionadora', quantidade: 5, local: 'Base C'),
  ];
  
  List<EstoqueMaterial> get _filteredMateriais {
    if (_searchQuery.isEmpty) {
      return _materiais;
    }
    
    return _materiais.where((material) {
      return material.codigo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             material.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             material.local.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Helper para criar linhas de informação
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // Método para mostrar o diálogo de adicionar material
  void _showAddMaterialDialog(BuildContext context) {
    final codigoController = TextEditingController();
    final nomeController = TextEditingController();
    final quantidadeController = TextEditingController();
    final localController = TextEditingController();
    
    // Definir cores e estilos para o diálogo
    final primaryColor = const Color(0xFF253250); // Cor azul escuro do Metrô
    final secondaryColor = Colors.blue.shade700;
    
    // Estilo padrão para inputs
    final inputDecoration = (String label, String hint, IconData icon) => InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: primaryColor),
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: secondaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    );
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_box_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Adicionar Material',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Preencha os dados do novo material',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Form fields
              TextField(
                controller: codigoController,
                decoration: inputDecoration(
                  'Código', 
                  'Ex: M001', 
                  Icons.qr_code
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: nomeController,
                decoration: inputDecoration(
                  'Nome', 
                  'Ex: Cabo Elétrico', 
                  Icons.inventory
                ),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: quantidadeController,
                decoration: inputDecoration(
                  'Quantidade', 
                  'Ex: 150', 
                  Icons.production_quantity_limits
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: localController,
                decoration: inputDecoration(
                  'Local', 
                  'Ex: Base A', 
                  Icons.location_on
                ),
                style: const TextStyle(fontSize: 16),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Validar entradas
                      if (codigoController.text.isEmpty || 
                          nomeController.text.isEmpty ||
                          quantidadeController.text.isEmpty ||
                          localController.text.isEmpty) {
                        // Mostrar erro
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Preencha todos os campos'),
                            backgroundColor: Colors.red,
                          )
                        );
                        return;
                      }
                      
                      // Tentar converter quantidade para número
                      int quantidade;
                      try {
                        quantidade = int.parse(quantidadeController.text);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Quantidade deve ser um número'),
                            backgroundColor: Colors.red,
                          )
                        );
                        return;
                      }
                      
                      // Adicionar o novo material à lista
                      setState(() {
                        _materiais.add(
                          EstoqueMaterial(
                            codigo: codigoController.text,
                            nome: nomeController.text,
                            quantidade: quantidade,
                            local: localController.text,
                          )
                        );
                      });
                      
                      // Fechar o diálogo
                      Navigator.pop(context);
                      
                      // Mostrar confirmação
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Material ${nomeController.text} adicionado com sucesso',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          duration: const Duration(seconds: 4),
                        )
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text(
                          'Adicionar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estoque', 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/LogoMetro.png', height: 32),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de pesquisa
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar material...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {
                      // Implementar filtragem avançada
                    },
                  ),
                ],
              ),
            ),
            
            // Tabela de materiais - Versão responsiva
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Decidir qual layout usar baseado no tamanho da tela
                  final isMobile = constraints.maxWidth < 600;
                  
                  if (isMobile) {
                    // Layout de cards para mobile
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _filteredMateriais.length,
                      itemBuilder: (context, index) {
                        final material = _filteredMateriais[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  // Ícone baseado na quantidade
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: material.quantidade > 0 
                                          ? Colors.green.withOpacity(0.1) 
                                          : Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      material.quantidade > 0 
                                          ? Icons.inventory_2 
                                          : Icons.warning_amber,
                                      color: material.quantidade > 0 
                                          ? Colors.green 
                                          : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Informações principais
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          material.nome,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Código: ${material.codigo}',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: material.quantidade > 0 ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      material.status,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Detalhes quando expandido
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    children: [
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Quantidade:', material.quantidade.toString()),
                                      const SizedBox(height: 8),
                                      _buildInfoRow('Local:', material.local),
                                      const SizedBox(height: 12),
                                      // Botões de ação
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.edit, size: 18),
                                            label: const Text('Editar'),
                                            onPressed: () {
                                              // Implementar edição de material
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            icon: const Icon(Icons.swap_vert, size: 18),
                                            label: const Text('Movimentar'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF253250),
                                            ),
                                            onPressed: () {
                                              // Implementar movimentação de material
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    // Layout de tabela para desktop
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) => Colors.grey.shade300,
                            ),
                            columnSpacing: 24,
                            horizontalMargin: 16,
                            dataRowHeight: 60,
                            headingRowHeight: 56,
                            columns: const [
                              DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Quantidade', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Local', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _filteredMateriais.map((material) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(
                                    material.codigo,
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  )),
                                  DataCell(Text(material.nome)),
                                  DataCell(Text(
                                    material.quantidade.toString(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: material.quantidade > 0 ? Colors.black : Colors.red,
                                    ),
                                  )),
                                  DataCell(Text(material.local)),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: material.quantidade > 0 ? Colors.green : Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        material.status,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 20),
                                          color: Colors.blue,
                                          onPressed: () {
                                            // Implementar edição
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.swap_vert, size: 20),
                                          color: const Color(0xFF253250),
                                          onPressed: () {
                                            // Implementar movimentação
                                          },
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
                  }
                },
              ),
            ),
            
            // Botão para adicionar material
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar material'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _showAddMaterialDialog(context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
