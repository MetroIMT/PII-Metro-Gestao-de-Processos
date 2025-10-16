import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_metro_2025_2/screens/login/login_screen.dart';

void main() {
  group('LoginScreen - Testes de Widget', () {
    testWidgets('Deve renderizar todos os elementos da tela de login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      expect(find.byType(TextField), findsNWidgets(2)); // Email e senha
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Cadastrar'), findsOneWidget);
      expect(find.byType(Image), findsWidgets); // Logo do Metro
    });

    testWidgets('Deve mostrar mensagem de erro quando campos estão vazios', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.ensureVisible(find.text('Entrar'));
      await tester.pumpAndSettle();

      final loginButton = find.text('Entrar');
      await tester.tap(loginButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Preencha email e senha.'), findsOneWidget);
    });

    testWidgets('Deve permitir digitar email e senha', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      await tester.enterText(emailField, 'teste@metro.com');
      await tester.enterText(passwordField, 'senha123');
      await tester.pump();

      expect(find.text('teste@metro.com'), findsOneWidget);
      expect(find.text('senha123'), findsOneWidget);
    });

    testWidgets('Deve alternar visibilidade da senha ao clicar no ícone', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      final visibilityIcon = find.byIcon(Icons.visibility);
      expect(visibilityIcon, findsOneWidget);

      await tester.tap(visibilityIcon);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Deve marcar e desmarcar checkbox "Lembrar credenciais"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      final checkbox = find.byType(Checkbox);
      expect(checkbox, findsOneWidget);

      Checkbox checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, false);

      await tester.tap(checkbox);
      await tester.pump();

      checkboxWidget = tester.widget(checkbox);
      expect(checkboxWidget.value, true);
    });

    testWidgets('Deve exibir texto "Bem vindo de volta!" na tela', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      expect(find.text('Bem vindo'), findsOneWidget);
      expect(find.text('de volta!'), findsOneWidget);
    });

    testWidgets('Botão de cadastrar deve estar presente e clicável', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));
      await tester.ensureVisible(find.text('Cadastrar'));
      await tester.pumpAndSettle();

      final cadastrarButton = find.text('Cadastrar');

      expect(cadastrarButton, findsOneWidget);

      await tester.tap(cadastrarButton, warnIfMissed: false);
      await tester.pump();
    });
  });
}
