import 'package:flutter/material.dart';
import 'home_screen.dart'; // Para PieChartPainter e CardActionButton
import 'estoque_page.dart'; // Para EstoqueMaterial e EstoquePage
import 'material_giro_page.dart'; // Página a ser criada
import 'material_consumo_page.dart';
import 'material_patrimoniado_page.dart';

class EstoqueCategoriasPage extends StatefulWidget {
  const EstoqueCategoriasPage({super.key});

  @override
  State<EstoqueCategoriasPage> createState() => _EstoqueCategoriasPageState();
}

class _EstoqueCategoriasPageState extends State<EstoqueCategoriasPage> {
  // Dados de exemplo para as categorias
  final List<EstoqueMaterial> materiaisGiro = [
    EstoqueMaterial(codigo: 'G001', nome: 'Rolamento 6203', quantidade: 50, local: 'Almox. A'),
    EstoqueMaterial(codigo: 'G002', nome: 'Correia V', quantidade: 20, local: 'Almox. B'),
    EstoqueMaterial(codigo: 'G003', nome: 'Filtro de Ar', quantidade: 0, local: 'Almox. A'),
  ];

  final List<EstoqueMaterial> materiaisConsumo = [
    EstoqueMaterial(codigo: 'C001', nome: 'Óleo Lubrificante', quantidade: 15, local: 'Oficina 1'),
    EstoqueMaterial(codigo: 'C002', nome: 'Graxa', quantidade: 5, local: 'Oficina 2'),
    EstoqueMaterial(codigo: 'C003', nome: 'Estopa', quantidade: 100, local: 'Oficina 1'),
  ];

  final List<EstoqueMaterial> materiaisPatrimoniado = [
    EstoqueMaterial(codigo: 'P001', nome: 'Furadeira de Impacto', quantidade: 1, local: 'Ferramentaria'),
    EstoqueMaterial(codigo: 'P002', nome: 'Multímetro Digital', quantidade: 1, local: 'Eletrônica'),
  ];

  late final List<Map<String, dynamic>> categorias;

  @override
  void initState() {
    super.initState();
    categorias = [
      {
        'titulo': 'Material de Giro',
        'icone': Icons.sync_alt,
        'cor': Colors.blue.shade700,
        'materiais': materiaisGiro,
        'pagina': () => const MaterialGiroPage(),
      },
      {
        'titulo': 'Material de Consumo',
        'icone': Icons.construction,
        'cor': Colors.orange.shade700,
        'materiais': materiaisConsumo,
        'pagina': () => const MaterialConsumoPage(),
      },
      {
        'titulo': 'Material Patrimoniado',
        'icone': Icons.devices,
        'cor': Colors.purple.shade700,
        'materiais': materiaisPatrimoniado,
        'pagina': () => const MaterialPatrimoniadoPage(),
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorias de Estoque', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/LogoMetro.png', height: 32),
          ),
        ],
      ),
      backgroundColor: Colors.grey.shade50,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          
          if (isMobile) {
            // Mobile: SingleChildScrollView com Column
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: categorias.map((categoria) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _EstoqueCategoriaCard(
                      title: categoria['titulo'],
                      icon: categoria['icone'],
                      color: categoria['cor'],
                      materiais: categoria['materiais'],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => categoria['pagina']())),
                    ),
                  );
                }).toList(),
              ),
            );
          } else {
            // Tablet e Desktop: Grid
            final crossAxisCount = constraints.maxWidth < 1200 ? 2 : 3;
            return GridView.builder(
              padding: const EdgeInsets.all(24.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.5,
              ),
              itemCount: categorias.length,
              itemBuilder: (context, index) {
                final categoria = categorias[index];
                return _EstoqueCategoriaCard(
                  title: categoria['titulo'],
                  icon: categoria['icone'],
                  color: categoria['cor'],
                  materiais: categoria['materiais'],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => categoria['pagina']())),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// Card de categoria simplificado, sem efeitos de hover ou animação
class _EstoqueCategoriaCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<EstoqueMaterial> materiais;
  final VoidCallback onTap;

  const _EstoqueCategoriaCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.materiais,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int totalMateriais = materiais.length;
    final int materiaisDisponiveis = materiais.where((m) => m.quantidade > 0).length;
    final int materiaisEmFalta = materiais.where((m) => m.quantidade <= 0).length;
    final double porcentagemDisponivel = totalMateriais > 0 ? (materiaisDisponiveis / totalMateriais) * 100 : 0.0;

    final isMobile = MediaQuery.of(context).size.width < 700;
    final isVerySmall = MediaQuery.of(context).size.width < 500;
    final cardHeight = isMobile ? 280.0 : null;

    return Material(
      elevation: 2,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: cardHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do Card
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: isMobile ? 20 : 22),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: isMobile ? 15 : 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: porcentagemDisponivel > 85 ? Colors.green.shade400 : porcentagemDisponivel > 70 ? Colors.orange.shade400 : Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${porcentagemDisponivel.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 12 : 16),
                // Corpo do Card
                Expanded(
                  child: isVerySmall
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildEstoqueStat('Total', '$totalMateriais', Icons.category_outlined, color),
                            _buildEstoqueStat('Disponíveis', '$materiaisDisponiveis', Icons.check_circle_outline, Colors.green.shade600),
                            _buildEstoqueStat('Em falta', '$materiaisEmFalta', Icons.error_outline, Colors.red.shade600),
                          ],
                        )
                      : Row(
                          children: [
                            // Estatísticas
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildEstoqueStat('Total', '$totalMateriais', Icons.category_outlined, color),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  _buildEstoqueStat('Disponíveis', '$materiaisDisponiveis', Icons.check_circle_outline, Colors.green.shade600),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  _buildEstoqueStat('Em falta', '$materiaisEmFalta', Icons.error_outline, Colors.red.shade600),
                                ],
                              ),
                            ),
                            // Gráfico
                            Expanded(
                              flex: 2,
                              child: CustomPaint(
                                painter: PieChartPainter(
                                  disponivel: totalMateriais > 0 ? materiaisDisponiveis / totalMateriais : 0,
                                  emFalta: totalMateriais > 0 ? materiaisEmFalta / totalMateriais : 0,
                                  corDisponivel: Colors.green.shade400,
                                  corEmFalta: Colors.red.shade400,
                                ),
                                size: const Size(100, 100),
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                // Rodapé do Card
                Align(
                  alignment: Alignment.bottomRight,
                  child: CardActionButton(
                    label: 'Ver detalhes',
                    borderColor: color,
                    onPressed: onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstoqueStat(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }
}
