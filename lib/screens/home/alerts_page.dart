import 'package:flutter/material.dart';
// Importe o serviço e os modelos necessários
import '../../services/material_service.dart';
import '../../services/auth_service.dart';
import '../home/estoque_page.dart'; // Assumindo que EstoqueMaterial está aqui, como em MaterialService
import '../../repositories/alert_repository.dart'; // Usaremos para os modelos AlertItem e AlertType
import '../../widgets/sidebar.dart';
import 'dart:async'; // Para tratamento de erros
import 'dart:math'; // Para usar o max() na severidade

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage>
    with SingleTickerProviderStateMixin {
  static const Color metroBlue = Color(0xFF001489);
  String _query = '';
  AlertType? _filterType;
  int _minSeverity = 1;
  bool _isRailExtended = false;
  late AnimationController _animationController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- Novas variáveis de estado ---
  late final MaterialService _materialService;
  List<AlertItem> _allAlerts = []; // Armazena os alertas reais
  bool _isLoading = true; // Controla o estado de carregamento
  String? _errorMessage; // Armazena mensagens de erro
  bool _isSeverityMenuOpen = false;

  // VARIAVEIS DE ESTADO PARA ADMIN
  late final AuthService _authService;
  String? _userRole;

  bool get _isAdmin => _userRole == 'admin'; // NOVO GETTER

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // Instancia o serviço e carrega os dados
    _materialService = MaterialService();
    _authService = AuthService();
    _loadUserRole(); // CARREGA ROLE
    _loadAlerts();
  }

  // NOVO MÉTODO: Carrega a role do usuário logado
  Future<void> _loadUserRole() async {
    final role = await _authService.role;
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  // --- ATUALIZADO: Método para carregar e processar alertas (com Vencido) ---
  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Busca os três tipos de material em paralelo
      final results = await Future.wait([
        _materialService.getByTipo('giro'),
        _materialService.getByTipo('patrimoniado'),
        _materialService.getByTipo('consumo'),
      ]);

      // 2. Achata a lista de listas em uma única lista
      final allMaterials = results.expand((list) => list).toList();

      // 3. Processa os materiais para gerar alertas
      final generatedAlerts = <AlertItem>[];
      final now = DateTime.now();
      
      // Limites para 'Vencimento Próximo'
      final expiryLimit = now.add(const Duration(days: 30));
      final criticalExpiryLimit = now.add(const Duration(days: 15));

      for (final m in allMaterials) {
        // --- LÓGICA DE ALERTA ATUALIZADA ---

        // 1. Calcular condições e severidades
        bool isLowStock = m.quantidade < 10;
        int lowStockSeverity = isLowStock ? (m.quantidade == 0 ? 3 : 2) : 0;
        
        // NOVO: Verifica se está VENCIDO (data é antes de agora)
        bool isExpired = m.vencimento != null && m.vencimento!.isBefore(now);
        int expiredSeverity = isExpired ? 3 : 0; // Severity 3 para vencido

        // ATUALIZADO: Verifica se está PRÓXIMO DO VENCIMENTO (e não vencido)
        bool isNearExpiry = m.vencimento != null && 
                            !isExpired && 
                            m.vencimento!.isBefore(expiryLimit);
                            
        int nearExpirySeverity = isNearExpiry
            ? (m.vencimento!.isBefore(criticalExpiryLimit) ? 3 : 2)
            : 0;

        // 2. Determinar qual alerta criar (APENAS UM por item)

        if (isExpired) {
          // Caso 1: Item Vencido (Prioridade máxima, ignora estoque)
          generatedAlerts.add(AlertItem(
            codigo: m.codigo,
            nome: m.nome,
            quantidade: m.quantidade,
            local: m.local,
            vencimento: m.vencimento,
            type: AlertType.expired, // NOVO TIPO
            severity: expiredSeverity,
          ));
        } else if (isLowStock && isNearExpiry) {
          // Caso 2: AMBOS problemas (Não está vencido). Prioriza o mais grave.
          if (lowStockSeverity >= nearExpirySeverity) {
            // Prioriza estoque baixo (ou se a gravidade for igual)
            generatedAlerts.add(AlertItem(
              codigo: m.codigo,
              nome: m.nome,
              quantidade: m.quantidade,
              local: m.local,
              vencimento: m.vencimento,
              type: AlertType.lowStock,
              severity: lowStockSeverity,
            ));
          } else {
            // Vencimento é mais grave
            generatedAlerts.add(AlertItem(
              codigo: m.codigo,
              nome: m.nome,
              quantidade: m.quantidade,
              local: m.local,
              vencimento: m.vencimento,
              type: AlertType.nearExpiry,
              severity: nearExpirySeverity,
            ));
          }
        } else if (isLowStock) {
          // Caso 3: Apenas estoque baixo
          generatedAlerts.add(AlertItem(
            codigo: m.codigo,
            nome: m.nome,
            quantidade: m.quantidade,
            local: m.local,
            vencimento: m.vencimento,
            type: AlertType.lowStock,
            severity: lowStockSeverity,
          ));
        } else if (isNearExpiry) {
          // Caso 4: Apenas vencimento próximo (e não vencido)
          generatedAlerts.add(AlertItem(
            codigo: m.codigo,
            nome: m.nome,
            quantidade: m.quantidade,
            local: m.local,
            vencimento: m.vencimento,
            type: AlertType.nearExpiry,
            severity: nearExpirySeverity,
          ));
        }
        // Se nenhum for verdadeiro, nada é adicionado.
        // --- FIM DA LÓGICA DE ALERTA ATUALIZADA ---
      }

      setState(() {
        _allAlerts = generatedAlerts;
        _isLoading = false;
      });
    } catch (e) {
      // Trata exceções da API com dados mockados
      final mockAlerts = [
        AlertItem(
          codigo: 'MOCK-001',
          nome: 'Rolamento SKF 6205 (Mock)',
          quantidade: 2,
          local: 'Almoxarifado Central',
          type: AlertType.lowStock,
          severity: 3,
        ),
        AlertItem(
          codigo: 'MOCK-002',
          nome: 'Cola Industrial (Mock)',
          quantidade: 15,
          local: 'Almoxarifado B',
          vencimento: DateTime.now().add(const Duration(days: 5)),
          type: AlertType.nearExpiry,
          severity: 3,
        ),
        AlertItem(
          codigo: 'MOCK-003',
          nome: 'Luvas de Proteção (Mock)',
          quantidade: 5,
          local: 'EPIs',
          type: AlertType.lowStock,
          severity: 2,
        ),
        AlertItem(
          codigo: 'MOCK-004',
          nome: 'Reagente Químico (Mock)',
          quantidade: 10,
          local: 'Laboratório',
          vencimento: DateTime.now().subtract(const Duration(days: 2)),
          type: AlertType.expired,
          severity: 3,
        ),
      ];

      setState(() {
        _allAlerts = mockAlerts;
        _isLoading = false;
        // _errorMessage = e.toString(); // Não exibe erro, usa mocks
      });
    }
  }

  Widget _buildAlertsPanel({
    required BuildContext context,
    required bool useListLayout,
  }) {
    // --- Variáveis restauradas ---
    final size = MediaQuery.of(context).size;
    final bool isMobileView = size.width < 600;
    final double computedMinWidth = size.width -
        (isMobileView ? 0 : (_isRailExtended ? 180 : 70)) -
        48 -
        32;
    final double tableMinWidth =
        computedMinWidth > 0 ? computedMinWidth : size.width;
    // --- Fim das variáveis restauradas ---

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTopBar(context, showTitle: useListLayout),
            const SizedBox(height: 16),
            Expanded(
              // --- Lógica de exibição atualizada ---
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 64),
                                const SizedBox(height: 12),
                                const Text(
                                  'Falha ao carregar alertas',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style:
                                      TextStyle(color: Colors.grey.shade700),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : _visibleAlerts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 64,
                                    color: Colors.green.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Nenhum alerta encontrado',
                                    style: TextStyle(
                                        color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            )
                          : useListLayout
                              ? ListView.separated(
                                  itemCount: _visibleAlerts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (context, i) {
                                    final a = _visibleAlerts[i];
                                    return Dismissible(
                                      key: ValueKey(a.codigo + a.nome),
                                      // ATUALIZADO: Restringe Dismissible ao Admin
                                      direction: _isAdmin
                                          ? DismissDirection.endToStart
                                          : DismissDirection.none,
                                      confirmDismiss: (direction) async {
                                        if (!_isAdmin) return false; // GARANTE que só Admin pode confirmar
                                        return await showDialog<bool>(
                                              context: context,
                                              builder: (context) =>
                                                  AlertDialog(
                                                title: const Text(
                                                    'Confirmar remoção'),
                                                content: Text(
                                                  'Deseja marcar o alerta de \"${a.nome}\" como resolvido?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(false),
                                                    child:
                                                        const Text('Cancelar'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                    ),
                                                    child: const Text(
                                                        'Confirmar'),
                                                  ),
                                                ],
                                              ),
                                            ) ??
                                            false;
                                      },
                                      background: Container(
                                        alignment: Alignment.centerRight,
                                        padding:
                                            const EdgeInsets.only(right: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.check,
                                            color: Colors.white),
                                      ),
                                      onDismissed: (_) => _resolveAlertAt(i),
                                      child: _buildAlertCardMobile(a, i),
                                    );
                                  },
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minWidth: tableMinWidth),
                                      child: DataTable(
                                        dataRowHeight: 60,
                                        headingRowColor:
                                            MaterialStateProperty.all(
                                          const Color.fromARGB(
                                              255, 255, 255, 255),
                                        ),
                                        headingTextStyle: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                        columnSpacing: 24,
                                        columns: const [
                                          DataColumn(label: Text('Código')),
                                          DataColumn(label: Text('Nome')),
                                          DataColumn(label: Text('Tipo')),
                                          DataColumn(
                                              label: Text('Quantidade')),
                                          DataColumn(label: Text('Local')),
                                          DataColumn(
                                              label: Text('Vencimento')),
                                          DataColumn(
                                              label: Text('Prioridade')),
                                          DataColumn(label: Text('Ações')),
                                        ],
                                        rows: _visibleAlerts.map((a) {
                                          return DataRow(
                                            cells: [
                                              DataCell(Text(a.codigo)),
                                              DataCell(Text(a.nome)),
                                              DataCell(
                                                  Text(_typeLabel(a.type))),
                                              DataCell(Text(
                                                  a.quantidade.toString())),
                                              DataCell(Text(a.local)),
                                              DataCell(Text(
                                                  _formatDate(a.vencimento))),
                                              DataCell(
                                                Chip(
                                                  backgroundColor:
                                                      _severityColor(
                                                    a.severity,
                                                  ).withAlpha(
                                                          (0.12 * 255).round()),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    side: const BorderSide(
                                                      color:
                                                          Colors.transparent,
                                                    ),
                                                  ),
                                                  label: Text(
                                                    '${a.severity}',
                                                    style: TextStyle(
                                                      color: _severityColor(
                                                          a.severity),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                          Icons.visibility),
                                                      tooltip: 'Detalhes',
                                                      onPressed: () =>
                                                          _showDetail(a),
                                                    ),
                                                    // ATUALIZADO: Restringe o botão 'Marcar resolvido' ao Admin
                                                    if (_isAdmin)
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.check),
                                                        tooltip:
                                                            'Marcar resolvido',
                                                        onPressed: () =>
                                                            _confirmAndMark(a),
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
                                ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _materialService.dispose(); // Limpa o cliente HTTP
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

  // ATUALIZADO: Inclui 'Vencido'
  String _typeLabel(AlertType t) {
    switch (t) {
      case AlertType.lowStock:
        return 'Estoque baixo';
      case AlertType.nearExpiry:
        return 'Vencimento próximo';
      case AlertType.expired:
        return 'Vencido';
      case AlertType.calibration:
        return 'Calibração';
    }
  }

  Future<void> _showSeverityMenu(BuildContext anchorContext) async {
    final renderBox = anchorContext.findRenderObject() as RenderBox?;
    final overlayState = Overlay.of(anchorContext);
    final overlayBox = overlayState?.context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlayBox == null) return;

    setState(() => _isSeverityMenuOpen = true);

    final target = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    const double gap = 6;
    final double left = target.dx;
    final double top = target.dy + size.height + gap;
    final double right = overlayBox.size.width - left - size.width;
    final double bottom = overlayBox.size.height - top;

    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(left, top, right, bottom),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      constraints: BoxConstraints.tightFor(width: size.width),
      items: _severityMenuItems(),
    );

    if (!mounted) return;
    setState(() {
      _isSeverityMenuOpen = false;
      if (selected != null) {
        _minSeverity = selected;
      }
    });
  }

  List<PopupMenuEntry<int>> _severityMenuItems() {
    return List.generate(3, (index) {
      final value = index + 1;
      final bool isSelected = _minSeverity == value;
      return PopupMenuItem<int>(
        value: value,
        height: 44,
        child: Row(
          children: [
            Text(
              '≥ $value',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? metroBlue : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check, color: metroBlue, size: 18),
            ],
          ],
        ),
      );
    });
  }

  List<AlertItem> get _visibleAlerts {
    String q;
    try {
      q = _query.trim().toLowerCase();
    } catch (_) {
      q = '';
    }

    // --- Alteração principal: usa _allAlerts em vez do repositório ---
    final items = _allAlerts;
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
        return false;
      }
    }).toList();
  }

  void _markResolved(AlertItem a) {
    setState(() {
      // --- Alteração: remove da lista de estado local ---
      _allAlerts.remove(a);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alerta marcado como resolvido')),
    );
  }

  // Remove o alerta pela posição na lista visível (usado pelo Dismissible)
  void _resolveAlertAt(int index) {
    if (!_isAdmin) return; // NOVO: Impede ação se não for Admin
    final visible = _visibleAlerts;
    if (index < 0 || index >= visible.length) return;
    final removed = visible[index];
    setState(() {
      // --- Alteração: remove da lista de estado local ---
      _allAlerts.remove(removed);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Alerta de ${removed.nome} resolvido')),
    );
  }

  // Nova função: mostra diálogo de confirmação e, se confirmado, remove o alerta
  Future<void> _confirmAndMark(AlertItem a) async {
    // NOVO: Adiciona a restrição de Admin
    if (!_isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas administradores podem marcar alertas como resolvidos.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha((0.12 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Confirmar resolução',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Deseja marcar o alerta de "${a.nome}" como resolvido? Esta ação não pode ser desfeita.',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Marcar resolvido'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      _markResolved(a);
    }
  }

  void _showDetail(AlertItem a) {
    final Color severityColor = _severityColor(a.severity);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: severityColor.withAlpha((0.18 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        a.type == AlertType.lowStock
                            ? Icons.inventory_2
                            : a.type == AlertType.expired
                                ? Icons.warning_amber_rounded
                                : Icons.event,
                        color: severityColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.nome,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${a.codigo} • ${a.local}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      backgroundColor: severityColor.withAlpha(
                        (0.15 * 255).round(),
                      ),
                      shape: const StadiumBorder(),
                      label: Text(
                        'Prioridade ${a.severity}',
                        style: TextStyle(
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _infoTile('Quantidade', a.quantidade.toString()),
                    const SizedBox(width: 12),
                    _infoTile('Vencimento', _formatDate(a.vencimento)),
                    const SizedBox(width: 12),
                    _infoTile('Tipo', _typeLabel(a.type)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  a.type == AlertType.lowStock
                      ? 'Estoque baixo — considere reposição ou realocação para este item.'
                      : a.type == AlertType.expired
                          ? 'ALERTA: Material VENCIDO — descarte ou reavalie imediatamente.'
                          : 'Vencimento próximo — priorize o uso ou inspeção do material.',
                  style: a.type == AlertType.expired
                      ? TextStyle(color: Colors.red.shade900, fontSize: 15, fontWeight: FontWeight.bold)
                      : const TextStyle(color: Colors.black54, fontSize: 15),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Fechar',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ATUALIZADO: Restringe o botão 'Marcar resolvido' ao Admin
                    if (_isAdmin)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Marcar resolvido'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _confirmAndMark(a);
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _smallStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withAlpha((0.9 * 255).round()),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // NOVO MÉTODO: Constrói a linha de botões de filtro no estilo MovimentacoesPage
  Widget _buildAlertFilterRow() {
    final ButtonStyle baseStyle = OutlinedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Colors.grey, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
    );

    final ButtonStyle selectedStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );

    Widget buildButton(String label, AlertType? filterValue, Color primaryColor, IconData icon) {
      final isSelected = _filterType == filterValue;

      return SizedBox(
        height: 40, // Altura uniforme
        child: isSelected
            ? ElevatedButton.icon(
                onPressed: () {
                  setState(() => _filterType = filterValue);
                },
                icon: Icon(icon, size: 18),
                label: Text(label),
                style: selectedStyle.copyWith(
                  backgroundColor: MaterialStateProperty.all(primaryColor),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
              )
            : OutlinedButton.icon(
                onPressed: () {
                  setState(() => _filterType = filterValue);
                },
                icon: Icon(icon, size: 18, color: primaryColor),
                label: Text(label, style: const TextStyle(color: Colors.black87)),
                style: baseStyle,
              ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        buildButton('Todos', null, metroBlue, Icons.view_list),
        buildButton(
            'Estoque baixo', AlertType.lowStock, Colors.red.shade700, Icons.inventory_2),
        buildButton(
            'Vencimento próximo', AlertType.nearExpiry, Colors.orange.shade700, Icons.event_available),
        buildButton(
            'Vencido', AlertType.expired, Colors.red.shade900, Icons.warning_amber_rounded), // NOVO BOTÃO
        buildButton(
            'Calibração', AlertType.calibration, Colors.blueAccent.shade700, Icons.build),
      ],
    );
  }

  // --- ATUALIZADO: Método _buildTopBar com nova ordem de elementos ---
  Widget _buildTopBar(BuildContext context, {bool showTitle = true}) {
    // --- Alteração: calcula totais com base em _allAlerts ---
    final total = _allAlerts.length;
    final lowStock =
        _allAlerts.where((a) => a.type == AlertType.lowStock).length;
    // Soma NearExpiry e Expired para o estatística
    final nearExpiry =
        _allAlerts.where((a) => a.type == AlertType.nearExpiry || a.type == AlertType.expired).length; 

    final size = MediaQuery.of(context).size;
    final bool isMobileView = size.width < 600;

    // ATUALIZADO: Removido padding superior
    final Widget searchField = Padding(
      padding: const EdgeInsets.only(top: 0), 
      child: TextField(
        style: const TextStyle(fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: 'Buscar alerta...',
          hintText: 'Digite nome, código ou local',
          floatingLabelBehavior: FloatingLabelBehavior.never,
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );

    Widget severitySelector(double width) {
      return SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prioridade mínima',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (fieldContext) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showSeverityMenu(fieldContext),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isSeverityMenuOpen
                              ? metroBlue
                              : Colors.grey.shade300,
                          width: 1.2,
                        ),
                        boxShadow: _isSeverityMenuOpen
                            ? [
                                BoxShadow(
                                  color: metroBlue.withOpacity(0.15),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '≥ $_minSeverity',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            _isSeverityMenuOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    final Widget filterControls = isMobileView
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              searchField,
              const SizedBox(height: 12),
              severitySelector(double.infinity),
            ],
          )
        : Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              severitySelector(190),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          Row(
            children: [
              _smallStat('Total', total.toString(), metroBlue),
              const SizedBox(width: 8),
              _smallStat('Estoque baixo', lowStock.toString(), Colors.red),
              const SizedBox(width: 8),
              _smallStat('Vencimento', nearExpiry.toString(), Colors.orange),
            ],
          ),
        if (showTitle) const SizedBox(height: 12),
        // MODIFICADO: Search field and Severity selector (filterControls) agora estão no topo
        filterControls, 
        const SizedBox(height: 12),
        // MODIFICADO: Filter buttons no novo estilo (_buildAlertFilterRow)
        _buildAlertFilterRow(),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;
    final bool useListLayout = size.width < 700;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey.shade100,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              scrolledUnderElevation: 0,
              elevation: 0,
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
                'Alertas',
                style: TextStyle(
                  color: Color(0xFF001489),
                  fontWeight: FontWeight.bold,
                ),
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
      drawer: isMobile
          ? Drawer(child: Sidebar(expanded: true, selectedIndex: 4))
          : null,
      body: Stack(
        children: [
          if (!isMobile)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: 0,
              top: 0,
              bottom: 0,
              width: _isRailExtended ? 180 : 70,
              child: Sidebar(expanded: _isRailExtended, selectedIndex: 4),
            ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(
              left: !isMobile ? (_isRailExtended ? 180 : 70) : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile)
                  Padding(
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
                            Text(
                              'Alertas',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: metroBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMobile) const SizedBox(height: 8),
                        const Text(
                          'Verifique todos os alertas emitidos',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _buildAlertsPanel(
                            context: context,
                            useListLayout: useListLayout,
                          ),
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

  // Novo helper: card otimizado para mobile (empilhado, textos quebram)
  Widget _buildAlertCardMobile(AlertItem a, int index) {
    return Card(
      color: Colors.white,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                      IconButton(
                        icon: Icon(
                          Icons.visibility,
                          color: metroBlue,
                        ),
                        onPressed: () => _showDetail(a),
                      ),
                      // ATUALIZADO: Restringe o botão 'Marcar resolvido' ao Admin
                      if (_isAdmin)
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () => _confirmAndMark(a),
                        ),
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
                      a.type == AlertType.lowStock
                          ? Icons.inventory_2
                          : a.type == AlertType.expired
                              ? Icons.warning_amber_rounded
                              : Icons.event,
                      size: 16,
                      color: _severityColor(a.severity),
                    ),
                    label: Text(_typeLabel(a.type)),
                    backgroundColor: _severityColor(
                      a.severity,
                    ).withAlpha((0.08 * 255).round()),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Qtd: ${a.quantidade}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Venc: ${_formatDate(a.vencimento)}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
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
              else if (a.type == AlertType.expired)
                Text(
                  'ALERTA: Material VENCIDO — descarte ou reavalie imediatamente.',
                  style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold),
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