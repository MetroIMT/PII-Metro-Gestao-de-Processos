import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pi_metro_2025_2/services/auth_service.dart'; // Verifica se este caminho está correto para o serviço de autenticação

/// Mostra o pop-up de recuperação de senha com efeito de fundo.
Future<void> showEsqueciSenhaPopup(BuildContext context) {
  final metroBlue = const Color(0xFF001489);

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Esqueci a Senha',
    // Escurece o fundo
    barrierColor: Colors.black.withAlpha((0.36 * 255).round()),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim1, anim2) {
      return BackdropFilter(
        // Aplica o efeito blur no fundo
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.98 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.12 * 255).round()),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _EsqueciSenhaContent(
                    metroBlue: metroBlue,
                    metroLightBlue: metroBlue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    // Transição com fade e leve scale
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = Curves.easeOut.transform(animation.value);
      return Opacity(
        opacity: animation.value,
        child: Transform.scale(scale: 0.98 + (0.02 * curved), child: child),
      );
    },
  );
}

class _EsqueciSenhaContent extends StatefulWidget {
  final Color metroBlue;
  final Color metroLightBlue;

  const _EsqueciSenhaContent({
    required this.metroBlue,
    required this.metroLightBlue,
  });

  @override
  State<_EsqueciSenhaContent> createState() => _EsqueciSenhaContentState();
}

class _EsqueciSenhaContentState extends State<_EsqueciSenhaContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  
  // Flag para controlar o estado de envio e mostrar o loading
  bool _sending = false;

  // Instância do serviço de autenticação
  final AuthService _authService = AuthService();
  
  // Regex para validar o domínio @metrosp.com.br
  static final RegExp _metroEmailRegex = RegExp(
    r'^[a-z0-9._%+-]+@metrosp\.com\.br$',
  );

  // Estado para o efeito de hover do botão "Cancelar"
  bool _isHoverCancel = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  /// Decoração padrão para os campos de texto.
  InputDecoration _fieldDecoration({required String label, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.metroLightBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
    );
  }

  /// Lógica de envio do email de recuperação.
  void _send() async {
    // Valida o formulário antes de prosseguir
    if (!_formKey.currentState!.validate()) return;
    
    // Ativa o loading/desabilita o botão
    setState(() => _sending = true);

    final email = _email.text.trim().toLowerCase();

    try {
      // Chama o serviço para enviar o email de reset
      await _authService.sendPasswordResetEmail(email: email);

      if (mounted) {
        // Fecha o pop-up e mostra notificação de sucesso
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Instruções enviadas para o email.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Em caso de erro, mostra uma notificação vermelha
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // Finaliza o loading
        setState(() => _sending = false);
      }
    }
  }

  /// Constrói o botão "Enviar" (Metro Blue, sem hover, com loading)
  Widget _buildSendButton() {
    final metroBlue = widget.metroBlue;
    final borderRadius = BorderRadius.circular(11);
    final duration = const Duration(milliseconds: 300);

    final bool isDisabled = _sending;
    
    // Define cores fixas para o botão (ou cinza se estiver desabilitado)
    final Color currentBackgroundColor = isDisabled 
        ? Colors.grey.shade300
        : metroBlue; 
        
    final Color currentBorderColor = isDisabled 
        ? Colors.grey.shade400
        : metroBlue; 
        
    // Define a cor do texto/ícone
    final Color currentTextColor = isDisabled 
        ? Colors.grey.shade600
        : Colors.white; 

    // Ação de clique: chama _send se não estiver enviando
    return GestureDetector(
      onTap: isDisabled ? null : _send,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        height: 46,
        decoration: BoxDecoration(
          color: currentBackgroundColor,
          border: Border.all(color: currentBorderColor, width: 2),
          borderRadius: borderRadius,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Conteúdo do botão (Texto e Ícone)
            AnimatedOpacity(
              duration: duration,
              opacity: _sending ? 0.0 : 1.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: currentTextColor,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Enviar',
                    style: TextStyle(
                      color: currentTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Indicador de loading
            if (_sending)
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  // Cor branca para contraste
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Constrói o botão "Cancelar" (Mantém o efeito de hover sutil).
  Widget _buildCancelButton() {
    final borderColor = widget.metroBlue;
    final borderRadius = BorderRadius.circular(11);
    final duration = const Duration(milliseconds: 220);

    // Calcula a cor de fundo com base no hover
    final backgroundColor = _isHoverCancel
        ? widget.metroBlue.withAlpha((0.08 * 255).round())
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoverCancel = true),
      onExit: (_) => setState(() => _isHoverCancel = false),
      child: GestureDetector(
        // Se não estiver enviando, fecha o pop-up
        onTap: _sending ? null : () => Navigator.of(context).pop(),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          height: 46,
          decoration: BoxDecoration(
            color: _sending ? Colors.grey.shade200 : backgroundColor,
            border: Border.all(
              color: _sending ? Colors.grey.shade400 : borderColor,
              width: 2,
            ),
            borderRadius: borderRadius,
          ),
          alignment: Alignment.center,
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: _sending ? Colors.grey.shade600 : widget.metroBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Título e mensagem de instrução
        Column(
          children: [
            Text(
              'Recuperar Senha',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.metroBlue,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Informe seu email para receber instruções de redefinição',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        const SizedBox(height: 18),
        // Estrutura do formulário
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                decoration: _fieldDecoration(
                  label: 'Email',
                  prefix: Icon(Icons.email_outlined, color: Colors.grey[600]),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o email';
                  final email = v.trim().toLowerCase();
                  // Validação 1: Checa formato básico de email
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                    return 'Email inválido';
                  }
                  // Validação 2: Exige o domínio @metrosp.com.br
                  if (!_metroEmailRegex.hasMatch(email)) {
                    return 'Use um e-mail @metrosp.com.br';
                  }
                  return null;
                },
                // Permite o envio ao pressionar Enter
                onFieldSubmitted: (_) => _send(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Linha com os botões de ação
        Row(
          children: [
            Expanded(child: _buildCancelButton()),
            const SizedBox(width: 12),
            Expanded(child: _buildSendButton()),
          ],
        ),
      ],
    );
  }
}