import 'package:flutter/material.dart';
import 'screens/login/login_screen.dart';
import 'package:pi_metro_2025_2/database/mongodb_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await MongoService.connect();
  } catch (e) {
    print('Erro ao conectar ao MongoDB: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PI Metro 2025-02',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
