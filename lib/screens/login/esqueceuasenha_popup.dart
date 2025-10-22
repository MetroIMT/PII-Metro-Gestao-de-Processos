import 'dart:ui';
import 'package:flutter/material.dart';

Future<void> showEsqueciSenhaPopup(BuildContext context) {
  final metroBlue = const Color(0xFF001489);
  final metroLightBlue = const Color(0xFF3B62FF);

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Esqueci a Senha',
    barrierColor: Colors.black.withOpacity(0.36),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, anim1, anim2) {
      return BackdropFilter(
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
                    color: Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _EsqueciSenhaContent(
                    metroBlue: metroBlue,
                    metroLightBlue: metroLightBlue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = Curves.easeOut.transform(animation.value);
      return Opacity(
        opacity: animation.value,
        child: Transform.scale(
          scale: 0.98 + (0.02 * curved),
          child: child,
        ),
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
    Key? key,
  }) : super(key: key);

  @override
  State<_EsqueciSenhaContent> createState() => _EsqueciSenhaContentState();
}

class _EsqueciSenhaContentState extends State<_EsqueciSenhaContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  bool _sending = false;

  // Adicionado: estados para hover/press (para web/desktop e toque)
  bool _isHover = false;
  bool _isPressed = false;

  // Adicionado: estado de hover para o botão Cancelar
  bool _isHoverCancel = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

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
    );
  }

  void _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);

    // Simula requisição de recuperação
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Instruções enviadas para o email')),
      );
    }
  }

  // Novo método: botão estilizado inspirado no exemplo HTML/CSS
  Widget _buildSendButton() {
    final borderColor = const Color(0xFF3654FF);
    final borderRadius = BorderRadius.circular(11);
    final duration = const Duration(milliseconds: 300);

    final backgroundColor = _isHover ? borderColor : Colors.transparent;
    final textColor = _isHover ? Colors.white : borderColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: _sending ? null : _send,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          height: 46, // aproximadamente 2.9em
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: borderRadius,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Texto ou loading
              AnimatedOpacity(
                duration: duration,
                opacity: _sending ? 0.0 : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícone com animação de deslocamento (translate X)
                    AnimatedContainer(
                      duration: duration,
                      transform: Matrix4.translationValues(_isHover ? 5.0 : 0.0, 0.0, 0.0),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Enviar',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Loading quando enviando (sobrepõe o texto)
              if (_sending)
                const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Novo método: botão Cancelar estilizado para combinar tamanho e fornecer feedback
  Widget _buildCancelButton() {
    final borderColor = widget.metroBlue;
    final borderRadius = BorderRadius.circular(11);
    final duration = const Duration(milliseconds: 220);

    final backgroundColor = _isHoverCancel ? widget.metroBlue.withOpacity(0.08) : Colors.transparent;
    final textColor = _isHoverCancel ? widget.metroBlue : widget.metroBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHoverCancel = true),
      onExit: (_) => setState(() => _isHoverCancel = false),
      child: GestureDetector(
        onTapDown: (_) => {}, // opcional: adicionar efeito de pressionado
        onTapUp: (_) => {}, // opcional
        onTapCancel: () {}, // opcional
        onTap: _sending ? null : () => Navigator.of(context).pop(),
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOut,
          height: 46, // igual ao botão Enviar
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: borderRadius,
          ),
          alignment: Alignment.center,
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: widget.metroBlue,
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
        // Título centralizado
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
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Email inválido';
                  return null;
                },
                onFieldSubmitted: (_) => _send(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              // Substituído: OutlinedButton -> botão customizado para ficar do mesmo tamanho e com hover sutil
              child: _buildCancelButton(),
            ),
            const SizedBox(width: 12),
            Expanded(
              // Substituído: ElevatedButton -> botão customizado inspirado no HTML/CSS fornecido
              child: _buildSendButton(),
            ),
          ],
        ),
      ],
    );
  }
}