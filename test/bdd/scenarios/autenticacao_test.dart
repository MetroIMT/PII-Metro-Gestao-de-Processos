import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pi_metro_2025_2/screens/login/login_screen.dart';
import 'package:pi_metro_2025_2/screens/login/login_controller.dart';
import '../mocks/mock_auth_service.dart';

void main() {
  group('Feature: Autenticação de Usuários', () {
    testWidgets(
      'Scenario: Login bem-sucedido com credenciais válidas',
      (tester) async {
        // Configurar tamanho da tela
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // Criar controller com mock
        final mockAuthService = MockAuthService();
        final controller = LoginController(authService: mockAuthService);

        // Given: que estou na página de login
        await tester.pumpWidget(
          MaterialApp(home: LoginPage(controller: controller)),
        );
        await tester.pumpAndSettle();

        // When: eu preencho o campo email com "admin@metrosp.com.br"
        final emailField = find.byType(TextField).first;
        await tester.enterText(emailField, 'admin@metrosp.com.br');
        await tester.pump();

        // And: eu preencho o campo senha com "Admin@123"
        final senhaField = find.byType(TextField).last;
        await tester.enterText(senhaField, 'Admin@123');
        await tester.pump();

        // And: eu clico no botão Entrar
        final botaoEntrar = find.text('Entrar');
        await tester.tap(botaoEntrar);
        await tester.pump(); // Inicia a requisição
        await tester.pump(const Duration(milliseconds: 200)); // Espera o mock
        await tester.pumpAndSettle(); // Espera animações

        // Then: eu devo ver a mensagem "Login realizado com sucesso!"
        expect(
          find.text('Login realizado com sucesso!'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Scenario: Login falha com credenciais inválidas',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockAuthService = MockAuthService();
        final controller = LoginController(authService: mockAuthService);

        await tester.pumpWidget(
          MaterialApp(home: LoginPage(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'admin@metrosp.com.br',
        );
        await tester.pump();

        await tester.enterText(
          find.byType(TextField).last,
          'senhaerrada',
        );
        await tester.pump();

        await tester.tap(find.text('Entrar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(
          find.text('Credenciais inválidas.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Scenario: Login falha com campos vazios',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockAuthService = MockAuthService();
        final controller = LoginController(authService: mockAuthService);

        await tester.pumpWidget(
          MaterialApp(home: LoginPage(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Entrar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(
          find.text('Preencha email e senha.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Scenario: Login falha com email de domínio inválido',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockAuthService = MockAuthService();
        final controller = LoginController(authService: mockAuthService);

        await tester.pumpWidget(
          MaterialApp(home: LoginPage(controller: controller)),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byType(TextField).first,
          'usuario@gmail.com',
        );
        await tester.pump();

        await tester.enterText(
          find.byType(TextField).last,
          'senha123',
        );
        await tester.pump();

        await tester.tap(find.text('Entrar'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('@metrosp.com.br'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Scenario: Alternar visibilidade da senha',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final mockAuthService = MockAuthService();
        final controller = LoginController(authService: mockAuthService);

        await tester.pumpWidget(
          MaterialApp(home: LoginPage(controller: controller)),
        );
        await tester.pumpAndSettle();

        final senhaField = find.byType(TextField).last;
        await tester.enterText(senhaField, 'minhasenha');
        await tester.pump();

        // Verificar que a senha está oculta
        TextField textField = tester.widget(senhaField);
        expect(textField.obscureText, isTrue);

        // Clicar no ícone de visibilidade
        final iconButton = find.byIcon(Icons.visibility);
        await tester.tap(iconButton);
        await tester.pump();

        // Verificar que a senha está visível
        textField = tester.widget(senhaField);
        expect(textField.obscureText, isFalse);
      },
    );
  });
}