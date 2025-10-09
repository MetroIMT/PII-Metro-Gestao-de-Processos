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
              child: OutlinedButton(
                onPressed: _sending ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: widget.metroBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: widget.metroBlue,
                ),
                child: Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [widget.metroBlue, widget.metroLightBlue]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: _sending
                        ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Enviar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}