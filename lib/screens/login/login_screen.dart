import 'dart:ui';
import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import 'login_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Metro',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final _loginController = LoginController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  void _showSnack(String message, {required bool isError}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (_, animation, __) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              const begin = 0.0;
              const end = 1.0;
              const curve = Curves.easeInOut;
              final tween = Tween(begin: begin, end: end)
                  .chain(CurveTween(curve: curve));
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
    } catch (e) {
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
    final metroLightBlue = const Color(0xFF3B62FF);

    return Scaffold(
      backgroundColor: isDesktop ? Colors.white : null,
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: isDesktop
              ? _buildDesktopLayout(metroBlue, metroLightBlue, size)
              : _buildMobileTabletLayout(
                  metroBlue,
                  metroLightBlue,
                  isTablet,
                  keyboardVisible,
                  size,
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(Color metroBlue, Color metroLightBlue, Size size) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: const AssetImage('assets/LogoMetro.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.05),
              BlendMode.darken,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [metroBlue, metroLightBlue],
                  ),
                ),
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Image.asset(
                        'assets/LogoMetro.png',
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                    Text(
                      'Acesse o sistema de gerenciamento do Metrô e administre os recursos, monitore a manutenção e tenha acesso a todos os relatórios.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: _buildInfoCarousel(metroBlue, metroLightBlue),
                      ),
                    ),
                    const Text(
                      '© 2025 Metrô | Todos os direitos reservados',
                      style: TextStyle(fontSize: 12, color: Colors.white70),
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
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                    _buildAnimatedTextField(
                      controller: emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isTablet: true,
                    ),
                    const SizedBox(height: 24),
                    _buildAnimatedTextField(
                      controller: passwordController,
                      label: 'Senha',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      isTablet: true,
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
                            // Ação "Esqueceu a senha"
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              color: metroLightBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [metroBlue, metroLightBlue],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                          strokeWidth: 2.2,
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
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () {
                              // Ação "Cadastrar"
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: metroBlue,
                              side: BorderSide(color: metroBlue),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cadastrar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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
                                color: metroLightBlue,
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
    Color metroLightBlue,
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
                      height: isTablet ? 140 : (keyboardVisible ? 80 : 100),
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
                    child: const Text('Bem vindo'),
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
                        color: metroLightBlue,
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
                  SizedBox(height: isTablet ? 40 : (keyboardVisible ? 20 : 32)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    margin:
                        EdgeInsets.symmetric(horizontal: isTablet ? 16 : 0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
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
                          keyboardType: TextInputType.emailAddress,
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
                                  // Ação "Esqueceu a senha"
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
                                    color: metroLightBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: isTablet ? 52 : 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [metroBlue, metroLightBlue],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                alignment: Alignment.center,
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
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: isTablet ? 52 : 48,
                          child: OutlinedButton(
                            onPressed: () {
                              // Ação "Cadastrar"
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: metroBlue),
                              foregroundColor: metroBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cadastrar',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Contate o suporte',
                            style: TextStyle(
                              color: metroLightBlue,
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
                const BorderSide(color: Color(0xFF3B62FF), width: 2),
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

  Widget _buildInfoCarousel(Color metroBlue, Color metroLightBlue) {
    return _InfoCarouselWidget(
      metroBlue: metroBlue,
      metroLightBlue: metroLightBlue,
    );
  }
}

class _InfoCarouselWidget extends StatefulWidget {
  const _InfoCarouselWidget({
    required this.metroBlue,
    required this.metroLightBlue,
  });

  final Color metroBlue;
  final Color metroLightBlue;

  @override
  State<_InfoCarouselWidget> createState() => _InfoCarouselWidgetState();
}

class _InfoCarouselWidgetState extends State<_InfoCarouselWidget> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.85);
    _pageController.addListener(() {
      final next = _pageController.page?.round() ?? 0;
      if (_currentPage != next) {
        setState(() => _currentPage = next);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardsData = [
      {
        'icon': Icons.security_rounded,
        'title': 'Segurança Avançada',
        'description':
            'Sistema com alta segurança e encriptação de dados para proteger todas as informações sensíveis da operação.',
        'color': const Color(0xFF2979FF),
        'stats': '99.9% de proteção',
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Análise em Tempo Real',
        'description':
            'Monitore a operação com dados atualizados instantaneamente e tome decisões baseadas em informações precisas.',
        'color': const Color(0xFF26A69A),
        'stats': '+30% de eficiência',
      },
      {
        'icon': Icons.compare_arrows_rounded,
        'title': 'Integração Total',
        'description':
            'Conecte-se com todos os sistemas do Metrô, desde manutenção até gerenciamento de passageiros e recursos humanos.',
        'color': const Color(0xFFFF6D00),
        'stats': '12 sistemas integrados',
      },
    ];

    return SizedBox(
      height: 250,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: cardsData.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) {
                final card = cardsData[index];
                final color = card['color'] as Color;
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  opacity: 1,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.15),
                          color.withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -40,
                                top: -40,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: color.withOpacity(0.1),
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          card['icon'] as IconData,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          card['title'] as String,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    card['description'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: color.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      card['stats'] as String,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                cardsData.length,
                (i) => GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: i == _currentPage
                          ? cardsData[i]['color'] as Color
                          : Colors.white.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}