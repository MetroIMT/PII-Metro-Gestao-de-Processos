import 'package:flutter/material.dart';
import '../home/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Metro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    final metroBlue = Color(0xFF001489);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: isDesktop
            ? Container(
                width: 1400,
                height: 800,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Lado esquerdo azul metrô
                    Expanded(
                      flex: 1,
                      child: Container(
                        color: metroBlue,
                        padding: EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Logo
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Image.asset(
                                'assets/LogoMetro.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: 32),
                            Text(
                              'Bem-vindo',
                              style: TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'de volta!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Lorem Ipsum is simply dummy text of the printing and typesetting. Lorem Ipsum has been the industry\'s standard.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Lado direito branco
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextField(
                              controller: emailController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Email',
                              ),
                            ),
                            SizedBox(height: 16),
                            TextField(
                              controller: passwordController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Senha',
                              ),
                              obscureText: true,
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      activeColor: metroBlue,
                                      onChanged: (val) {
                                        setState(() {
                                          rememberMe = val ?? false;
                                        });
                                      },
                                    ),
                                    Text(
                                      'Lembre-se de mim',
                                      style: TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Esqueceu a senha ação
                                  },
                                  child: Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(
                                      color: metroBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Navegar para home_screen.dart
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                HomeScreen()),
                                      );
                                    },
                                    child: Text('Entrar'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: metroBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                OutlinedButton(
                                  onPressed: () {
                                    // Ação cadastrar
                                  },
                                  child: Text('Cadastrar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: metroBlue,
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 32.0, vertical: 80.0),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Logo
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Image.asset(
                          'assets/LogoMetro.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: 32),
                      Text(
                        'Bem vindo',
                        style: TextStyle(
                          fontSize: 28,
                          color: metroBlue,
                        ),
                      ),
                      Text(
                        'de volta!',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: metroBlue),
                      ),
                      SizedBox(height: 24),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Email',
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Senha',
                        ),
                        obscureText: true,
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                activeColor: metroBlue,
                                onChanged: (val) {
                                  setState(() {
                                    rememberMe = val ?? false;
                                  });
                                },
                              ),
                              Text(
                                'Lembre-se de mim',
                                style: TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              // Esqueceu a senha ação
                            },
                            child: Text(
                              'Esqueceu a senha?',
                              style: TextStyle(
                                color: metroBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Navegar para home_screen.dart
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => HomeScreen()),
                          );
                        },
                        child: Text('Entrar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: metroBlue,
                          minimumSize: Size(double.infinity, 40),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () {
                          // Ação Cadastrar
                        },
                        child: Text('Cadastrar'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 40),
                          foregroundColor: metroBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}