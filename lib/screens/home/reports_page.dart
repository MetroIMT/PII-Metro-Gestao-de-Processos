import 'package:flutter/material.dart';

class RelatoriosPage extends StatefulWidget {
  const RelatoriosPage({Key? key}) : super(key: key);

  @override
  State<RelatoriosPage> createState() => _RelatoriosPageState();
}

class _RelatoriosPageState extends State<RelatoriosPage> {
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedItemType;
  String? _selectedBase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Text(
                        'Relatórios',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Image.asset('assets/LogoMetro.png', height: 40),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gere e exporte relatórios personalizados sobre materiais, instrumentos e históricos de movimentação.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter
                      Expanded(
                        flex: 1,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Filtros',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text('Período'),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                          hintText: 'Data inicial',
                                          suffixIcon: Icon(Icons.calendar_today),
                                        ),
                                        onTap: () async {
                                          final date = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime.now(),
                                            firstDate: DateTime(2000),
                                            lastDate: DateTime(2100),
                                          );
                                          if (date != null) {
                                            setState(() => _selectedStartDate = date);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text('Tipos de Item'),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('Selecione o tipo'),
                                  value: _selectedItemType,
                                  items: const [
                                    DropdownMenuItem(value: 'material', child: Text('Material')),
                                    DropdownMenuItem(value: 'instrumento', child: Text('Instrumento')),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedItemType = value);
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text('Base de manutenção'),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('Selecione a base'),
                                  value: _selectedBase,
                                  items: const [
                                    DropdownMenuItem(value: 'base1', child: Text('Base 1')),
                                    DropdownMenuItem(value: 'base2', child: Text('Base 2')),
                                  ],
                                  onChanged: (value) {
                                    setState(() => _selectedBase = value);
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Implement filter logic
                                    },
                                    child: const Text('Aplicar filtro'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Results 
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // PDF export
                                      },
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Exportar PDF'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // EXEL export
                                      },
                                      icon: const Icon(Icons.table_chart),
                                      label: const Text('Exportar EXEL'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        // Imprimir
                                      },
                                      icon: const Icon(Icons.print),
                                      label: const Text('Imprimir'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('Data')),
                                      DataColumn(label: Text('Item')),
                                      DataColumn(label: Text('Categoria')),
                                      DataColumn(label: Text('Qntd')),
                                      DataColumn(label: Text('Usuário')),
                                    ],
                                    rows: const [], 
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}