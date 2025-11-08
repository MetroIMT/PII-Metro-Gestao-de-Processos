import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pi_metro_2025_2/screens/login/login_controller.dart';
import 'package:pi_metro_2025_2/screens/login/login_screen.dart';

class _MockLoginController extends Mock implements LoginController {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildLoginPage({LoginController? controller}) {
    return MaterialApp(home: LoginPage(controller: controller));
  }

  group('LoginScreen - Testes de Widget', () {
    testWidgets('Renderiza os elementos principais', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Lembrar credenciais'), findsOneWidget);
      expect(find.text('Esqueceu a senha?'), findsOneWidget);
      expect(find.text('Contate o suporte'), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('Não chama o controller quando os campos estão vazios', (
      tester,
    ) async {
      final controller = _MockLoginController();
      await tester.pumpWidget(buildLoginPage(controller: controller));
      await tester.pumpAndSettle();

      // Tenta fazer login com campos vazios
      await tester.tap(find.text('Entrar'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verifica que o controller nunca foi chamado
      verifyZeroInteractions(controller);
    });

    testWidgets('Permite digitar email corporativo e senha', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField).first;
      final passwordField = find.byType(TextField).last;

      await tester.enterText(emailField, 'teste@metrosp.com.br');
      await tester.enterText(passwordField, 'senha123');
      await tester.pump();

      expect(find.text('teste@metrosp.com.br'), findsOneWidget);
      expect(find.text('senha123'), findsOneWidget);
    });

    testWidgets('Alterna visibilidade da senha', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      final showIcon = find.byIcon(Icons.visibility);
      expect(showIcon, findsOneWidget);

      await tester.tap(showIcon);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets(
      'Checkbox "Lembrar credenciais" pode ser marcado e desmarcado',
      (tester) async {
        await tester.pumpWidget(buildLoginPage());
        await tester.pumpAndSettle();

        final checkboxFinder = find.byType(Checkbox);
        expect(checkboxFinder, findsOneWidget);

        Checkbox checkbox = tester.widget(checkboxFinder);
        expect(checkbox.value, false);

        await tester.tap(checkboxFinder);
        await tester.pump();

        checkbox = tester.widget(checkboxFinder);
        expect(checkbox.value, true);

        await tester.tap(checkboxFinder);
        await tester.pump();

        checkbox = tester.widget(checkboxFinder);
        expect(checkbox.value, false);
      },
    );

    testWidgets('Exibe textos de boas-vindas', (tester) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      expect(find.text('Bem-vindo'), findsOneWidget);
      expect(find.text('de volta!'), findsOneWidget);
    });

    testWidgets('Botão "Contate o suporte" está presente e clicável', (
      tester,
    ) async {
      await tester.pumpWidget(buildLoginPage());
      await tester.pumpAndSettle();

      final suporteButton = find.text('Contate o suporte');
      expect(suporteButton, findsOneWidget);

      await tester.tap(suporteButton, warnIfMissed: false);
      await tester.pump();
    });
  });
}
