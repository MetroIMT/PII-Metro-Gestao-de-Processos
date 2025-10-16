import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import 'login_controller.dart';
import 'esqueceuasenha_popup.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Metro',
      theme: ThemeData(
        primaryColor: const Color(0xFF001489),
        fontFamily: 'Poppins',
      ),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.controller});

  final LoginController? controller;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final LoginController _loginController =
      widget.controller ?? LoginController();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();
    final senha = passwordController.text;

    if (email.isEmpty || senha.isEmpty) {
      _showSnack('Preencha email e senha.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ok = await _loginController.login(email: email, password: senha);
      if (ok) {
        _showSnack('Login realizado com sucesso!', isError: false);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, animation, __) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              final tween = Tween(begin: 0.0, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeInOut));
              return FadeTransition(
                opacity: animation.drive(tween),
                child: child,
              );
            },
          ),
        );
      } else {
        _showSnack('Credenciais inválidas.', isError: true);
      }
    } on FormatException catch (err) {
      _showSnack(err.message, isError: true);
    } catch (_) {
      _showSnack('Erro ao tentar logar. Tente novamente.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    final metroBlue = const Color(0xFF001489);

    return Scaffold(
      backgroundColor: isDesktop ? Colors.white : null,
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: isDesktop
              ? _buildDesktopLayout(metroBlue, size)
              : _buildMobileTabletLayout(
                  metroBlue,
                  isTablet,
                  keyboardVisible,
                  size,
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Color metroBlue, Size size) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                color: metroBlue,
                padding: const EdgeInsets.all(40),
                child: Stack(
                  children: [
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Image.asset(
                        'assets/LogoMetro.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bem-vindo',
                            style: TextStyle(
                              fontSize: 36,
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const Text(
                            'de volta!',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 80,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Acesse o sistema de gerenciamento do Metrô e administre os recursos, monitore a manutenção e tenha acesso a todos os relatórios.',
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            '© 2025 Metrô | Todos os direitos reservados',
                            style: TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: metroBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Entre com suas credenciais para acessar o sistema',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    _buildAnimatedTextField(
                      controller: emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedTextField(
                      controller: passwordController,
                      label: 'Senha',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: rememberMe,
                                activeColor: metroBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    rememberMe = val ?? false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Lembrar credenciais',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            showEsqueciSenhaPopup(context);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              color: metroBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: metroBlue,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Precisa de ajuda?',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Contate o suporte',
                              style: TextStyle(
                                color: metroBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTabletLayout(
    Color metroBlue,
    bool isTablet,
    bool keyboardVisible,
    Size size,
  ) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      reverse: keyboardVisible,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: size.height),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF5F7FF), Color(0xFFEDF1FF)],
              stops: [0.0, 0.5, 1.0],
            ),
            image: const DecorationImage(
              image: AssetImage('assets/LogoMetro.png'),
              fit: BoxFit.cover,
              opacity: 0.03,
              alignment: Alignment.topCenter,
            ),
          ),
          child: SafeArea(
            bottom: true,
            child: Padding(
              padding: EdgeInsets.only(
                left: isTablet ? 64.0 : 32.0,
                right: isTablet ? 64.0 : 32.0,
                top: keyboardVisible ? 10.0 : (isTablet ? 40.0 : 32.0),
                bottom: keyboardVisible
                    ? MediaQuery.of(context).viewInsets.bottom + 16.0
                    : 40.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!keyboardVisible || isTablet) ...[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      height:
                          isTablet ? 140 : (keyboardVisible ? 80 : 100),
                      child: Image.asset(
                        'assets/LogoMetro.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: isTablet ? 32 : 20),
                  ],
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isTablet ? 32 : (keyboardVisible ? 24 : 28),
                      color: metroBlue,
                      fontWeight: FontWeight.w300,
                    ),
                    child: const Text('Bem-vindo'),
                  ),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isTablet ? 32 : (keyboardVisible ? 24 : 28),
                      fontWeight: FontWeight.bold,
                      color: metroBlue,
                    ),
                    child: const Text('de volta!'),
                  ),
                  if (!keyboardVisible || isTablet) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: 60,
                      height: 3,
                      decoration: BoxDecoration(
                        color: metroBlue,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Faça login para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  SizedBox(
                    height: isTablet ? 40 : (keyboardVisible ? 20 : 32),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    margin:
                        EdgeInsets.symmetric(horizontal: isTablet ? 16 : 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.8),
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.all(keyboardVisible ? 20 : 24),
                    child: Column(
                      children: [
                        _buildAnimatedTextField(
                          controller: emailController,
                          label: 'Email',
                          prefixIcon: Icons.email_outlined,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedTextField(
                          controller: passwordController,
                          label: 'Senha',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          isTablet: isTablet,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (isTablet || !keyboardVisible)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: rememberMe,
                                      activeColor: metroBlue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          rememberMe = val ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Lembrar credenciais',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  showEsqueciSenhaPopup(context);
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(
                                    color: metroBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: metroBlue,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Entrar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isTablet || !keyboardVisible) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Precisa de ajuda?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Contate o suporte',
                            style: TextStyle(
                              color: metroBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        '© 2023 Metrô | Todos os direitos reservados',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    bool isTablet = false,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isTablet ? 60 : 56,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: isTablet ? 16 : 14,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: Colors.grey[500],
            size: isTablet ? 22 : 20,
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: Color(0xFF001489), width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : 14,
            horizontal: isTablet ? 16 : 14,
          ),
        ),
        style: TextStyle(fontSize: isTablet ? 16 : 14),
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction:
            obscureText ? TextInputAction.done : TextInputAction.next,
        onSubmitted: obscureText ? (_) => _login() : null,
      ),
    );
  }
}