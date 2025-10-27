import 'package:flutter/material.dart';
import '../../repositories/alert_repository.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String _query = '';
  AlertType? _filterType;
  int _minSeverity = 1;

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _severityColor(int s) {
    switch (s) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.yellow.shade700;
    }
  }

  String _typeLabel(AlertType t) => t == AlertType.lowStock ? 'Estoque baixo' : 'Vencimento próximo';

  List<AlertItem> get _visibleAlerts {
    // Protege contra _query ou campos inesperadamente nulos/indefinidos em tempo de execução.
    String q;
    try {
      q = _query.trim().toLowerCase();
    } catch (_) {
      q = '';
    }

    final items = AlertRepository.instance.items;
    return items.where((a) {
      try {
        if (_filterType != null && a.type != _filterType) return false;
        if (a.severity < _minSeverity) return false;
        if (q.isEmpty) return true;
        final nome = a.nome.toLowerCase();
        final codigo = a.codigo.toLowerCase();
        final local = a.local.toLowerCase();
        return nome.contains(q) || codigo.contains(q) || local.contains(q);
      } catch (_) {
        // Se algum campo estiver ausente/inválido, ignorar este item no filtro
        return false;
      }
    }).toList();
  }

  void _markResolved(AlertItem a) {
    setState(() {
      AlertRepository.instance.remove(a);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta marcado como resolvido')));
  }

  // Remove o alerta pela posição na lista visível (usado pelo Dismissible)
  void _resolveAlertAt(int index) {
    final visible = _visibleAlerts;
    if (index < 0 || index >= visible.length) return;
    final removed = visible[index];
    setState(() {
      AlertRepository.instance.remove(removed);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Alerta de ${removed.nome} resolvido')));
  }

  // Nova função: mostra diálogo de confirmação e, se confirmado, remove o alerta
  Future<void> _confirmAndMark(AlertItem a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar ação'),
        content: Text('Deseja marcar o alerta de "${a.nome}" como resolvido? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _markResolved(a);
    }
  }

  void _showDetail(AlertItem a) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _severityColor(a.severity).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(a.type == AlertType.lowStock ? Icons.inventory_2 : Icons.event, color: _severityColor(a.severity)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${a.codigo} • ${a.local}', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  Chip(
                    backgroundColor: _severityColor(a.severity).withOpacity(0.12),
                    avatar: CircleAvatar(backgroundColor: _severityColor(a.severity), radius: 10),
                    label: Text('Prioridade ${a.severity}', style: TextStyle(color: _severityColor(a.severity))),
                  )
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoTile('Quantidade', a.quantidade.toString()),
                  const SizedBox(width: 8),
                  _infoTile('Vencimento', _formatDate(a.vencimento)),
                  const SizedBox(width: 8),
                  _infoTile('Tipo', _typeLabel(a.type)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                a.type == AlertType.lowStock
                    ? 'Estoque baixo — considere reposição ou realocação.'
                    : 'Vencimento próximo — priorize uso ou inspeção.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Marcar resolvido'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _confirmAndMark(a);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _smallStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.9))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildTopBar() {
    final total = AlertRepository.instance.items.length;
    final lowStock = AlertRepository.instance.items.where((a) => a.type == AlertType.lowStock).length;
    final nearExpiry = AlertRepository.instance.items.where((a) => a.type == AlertType.nearExpiry).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('Alertas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        _smallStat('Total', total.toString(), Colors.blue),
        const SizedBox(width: 8),
        _smallStat('Estoque baixo', lowStock.toString(), Colors.red),
        const SizedBox(width: 8),
        _smallStat('Vencimento', nearExpiry.toString(), Colors.orange),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar por nome, código ou local...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<int>(
          value: _minSeverity,
          items: const [
            DropdownMenuItem(value: 1, child: Text('Prioridade >=1')),
            DropdownMenuItem(value: 2, child: Text('Prioridade >=2')),
            DropdownMenuItem(value: 3, child: Text('Prioridade >=3')),
          ],
          onChanged: (v) => setState(() => _minSeverity = v ?? 1),
        ),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 6, children: [
        ChoiceChip(selected: _filterType == null, label: const Text('Todos'), onSelected: (_) => setState(() => _filterType = null)),
        ChoiceChip(selected: _filterType == AlertType.lowStock, label: const Text('Estoque baixo'), onSelected: (_) => setState(() => _filterType = AlertType.lowStock)),
        ChoiceChip(selected: _filterType == AlertType.nearExpiry, label: const Text('Vencimento próximo'), onSelected: (_) => setState(() => _filterType = AlertType.nearExpiry)),
      ]),
      const SizedBox(height: 12),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF001489),
        elevation: 0,
        actions: [Padding(padding: const EdgeInsets.only(right: 16.0), child: Image.asset('assets/LogoMetro.png', height: 32))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildTopBar(),
          Expanded(
            child: _visibleAlerts.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade400), const SizedBox(height: 12), Text('Nenhum alerta encontrado', style: TextStyle(color: Colors.grey.shade600))]))
                : isMobile
                    ? ListView.separated(
                        itemCount: _visibleAlerts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final a = _visibleAlerts[i];
                          return Dismissible(
                            key: ValueKey(a.codigo + a.nome),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar remoção'),
                                      content: Text('Deseja marcar o alerta de "${a.nome}" como resolvido?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          child: const Text('Confirmar'),
                                        ),
                                      ],
                                    ),
                                  ) ??
                                  false;
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                            onDismissed: (_) => _resolveAlertAt(i),
                            child: _buildAlertCardMobile(a, i), // use responsive mobile card
                          );
                        },
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F7FA)),
                            columnSpacing: 24,
                            columns: const [
                              DataColumn(label: Text('Código', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Nome', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Tipo', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Quantidade', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                              DataColumn(label: Text('Local', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Vencimento', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Prioridade', style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Ações', style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: _visibleAlerts.map((a) {
                              return DataRow(cells: [
                                DataCell(Text(a.codigo)),
                                DataCell(Text(a.nome)),
                                DataCell(Text(_typeLabel(a.type))),
                                DataCell(Center(child: Text(a.quantidade.toString()))),
                                DataCell(Text(a.local)),
                                DataCell(Center(child: Text(_formatDate(a.vencimento)))),
                                DataCell(Chip(backgroundColor: _severityColor(a.severity).withOpacity(0.12), label: Text('${a.severity}', style: TextStyle(color: _severityColor(a.severity))))),
                                DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                  IconButton(icon: const Icon(Icons.visibility), tooltip: 'Detalhes', onPressed: () => _showDetail(a)),
                                  IconButton(icon: const Icon(Icons.check), tooltip: 'Marcar resolvido', onPressed: () => _confirmAndMark(a)),
                                ])),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  // Novo helper: card otimizado para mobile (empilhado, textos quebram)
  Widget _buildAlertCardMobile(AlertItem a, int index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showDetail(a),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha superior: nome e prioridade chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _severityColor(a.severity),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome (permite quebra em múltiplas linhas)
                        Text(
                          a.nome,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          softWrap: true,
                        ),
                        const SizedBox(height: 4),
                        // Código e local (permitem quebra)
                        Text(
                          '${a.codigo} • ${a.local}',
                          style: TextStyle(color: Colors.grey.shade600),
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Ações compactas no topo (visão rápida)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.visibility), onPressed: () => _showDetail(a)),
                      IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green), onPressed: () => _confirmAndMark(a)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Linha de chips / detalhes (usa wrap para quebrar)
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: Icon(
                      a.type == AlertType.lowStock ? Icons.inventory_2 : Icons.event,
                      size: 16,
                      color: _severityColor(a.severity),
                    ),
                    label: Text(_typeLabel(a.type)),
                    backgroundColor: _severityColor(a.severity).withOpacity(0.08),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Qtd: ${a.quantidade}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Venc: ${_formatDate(a.vencimento)}', style: TextStyle(color: Colors.grey.shade700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Descrição curta ou instrução (se houver) — permite múltiplas linhas
              if (a.type == AlertType.lowStock)
                Text(
                  'Estoque baixo — considere reposição ou realocação.',
                  style: TextStyle(color: Colors.grey.shade700),
                  softWrap: true,
                )
              else
                Text(
                  'Vencimento próximo — priorize uso ou inspeção.',
                  style: TextStyle(color: Colors.grey.shade700),
                  softWrap: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
