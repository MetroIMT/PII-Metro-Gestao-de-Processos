# 🧪 Guia de Testes e TDD (atualizado)

Este guia reflete a estratégia de testes em vigor no projeto, alinhada às mudanças recentes no AuthService, LoginController e LoginScreen, e ao uso de mocks sem geração de código.

## 🚀 Comandos úteis

```bash
# Executar todos os testes
flutter test

# Executar um arquivo específico
flutter test test/services/auth_service_test.dart
flutter test test/controllers/login_controller_test.dart
flutter test test/widgets/login_screen_test.dart

# Ver cobertura
flutter test --coverage

# Saída mais detalhada
flutter test --reporter=expanded
```

## 📁 Estrutura atual de testes

```
test/
├── services/
│   └── auth_service_test.dart       # testes de integração de chamada HTTP (mockada)
├── controllers/
│   └── login_controller_test.dart   # validação + orquestração com AuthService
├── widgets/
│   └── login_screen_test.dart       # testes de widget/UX
└── widget_test.dart                 # padrão do Flutter (placeholder)
```

Observação: os arquivos gerados via codegen do Mockito (mocks.dart) foram removidos. Não usamos mais build_runner para testes.

## 🎯 TDD em 3 passos

1. Red: escreva um teste que falha (define o comportamento desejado)
2. Green: implemente o mínimo para o teste passar
3. Refactor: melhore o design mantendo todos os testes verdes

Benefícios: mais confiança, refatorações seguras, documentação viva, melhor design de código.

## 🧰 Estratégia de mocking (sem codegen)

- HTTP: use `package:http/testing.dart` (MockClient) para simular respostas do backend.
- Services/Controllers: use mocks manuais e leves com `mockito` (sem anotações/geração). Ex.: `class _MockAuthService extends Mock implements AuthService {}`.
- Widgets: injete dependências (ex.: `LoginController`) para isolar a UI e controlar cenários.

### Exemplo — HTTP com MockClient

```dart
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

test('Login 401 retorna false', () async {
  var called = false;
  final client = MockClient((request) async {
    called = true;
    expect(request.method, 'POST');
    return http.Response('Unauthorized', 401);
  });

  final service = AuthService(client: client);
  final ok = await service.login(
    email: 'errado@metrosp.com.br',
    senha: 'senha',
  );

  expect(called, true);
  expect(ok, false);
});
```

### Exemplo — Mock manual do AuthService

```dart
class _MockAuthService extends Mock implements AuthService {}

test('Controller normaliza e-mail e delega ao service', () async {
  final mock = _MockAuthService();
  final controller = LoginController(authService: mock);

  when(mock.login(email: 'user@metrosp.com.br', senha: '123'))
      .thenAnswer((_) async => true);

  final ok = await controller.login(
    email: '  USER@METROSP.COM.BR ',
    password: '123',
  );

  expect(ok, true);
  verify(mock.login(email: 'user@metrosp.com.br', senha: '123')).called(1);
});
```

### Exemplo — Teste de widget com injeção de controller

```dart
class _MockLoginController extends Mock implements LoginController {}

testWidgets('Mostra erro quando campos vazios', (tester) async {
  final controller = _MockLoginController();
  await tester.pumpWidget(
    MaterialApp(home: LoginPage(controller: controller)),
  );

  await tester.tap(find.text('Entrar'), warnIfMissed: false);
  await tester.pump();

  expect(find.text('Preencha email e senha.'), findsOneWidget);
  verifyZeroInteractions(controller);
});
```

## ✅ Cenários cobertos (resumo)

### AuthService

- 401/500 retornam false
- Falha de conexão retorna false
- Resposta 200 sem token retorna false
- Email fora de `@metrosp.com.br` não faz POST e retorna false
- Email ou senha vazios não fazem POST e retornam false

### LoginController

- Sucesso retorna true
- Credenciais inválidas retornam false
- Normaliza e-mail antes de delegar
- Domínio inválido lança `FormatException`
- Erros do service podem ser propagados

### LoginScreen

- Renderiza elementos principais
- Valida campos vazios (snackbar)
- Alterna visibilidade da senha
- Checkbox "Lembrar credenciais" alterna estado
- Textos de boas-vindas e botões presentes (ex.: "Contate o suporte")

## 🔧 Dependências de teste

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4

dependencies:
  http: ^1.2.0 # (MockClient está em package:http/testing.dart)
```

## 📝 Padrão AAA (Arrange–Act–Assert)

```dart
test('descrição', () async {
  // Arrange
  // Act
  // Assert
});
```

## 🎓 Boas práticas

1. Use nomes descritivos e mantenha testes independentes
2. Evite rede/IO reais (mocke HTTP, storage, etc.)
3. Em widgets, injete dependências e use `TestWidgetsFlutterBinding.ensureInitialized()` quando necessário
4. Prefira `pump()` ao invés de `pumpAndSettle()` indiscriminadamente
5. Use `ensureVisible` apenas quando realmente houver overflow/scroll
6. Assegure que validações de domínio e normalização sejam cobertas por testes

## ✅ Checklist antes do commit

- [ ] `flutter test` verde
- [ ] `flutter analyze` sem erros
- [ ] `flutter format .` aplicado
- [ ] Cenários críticos cobertos (erros de rede, HTTP 401/500, entradas inválidas)

## 🐛 Troubleshooting

- MissingPluginException em testes de widget

  - Garanta `TestWidgetsFlutterBinding.ensureInitialized()` no `main()` dos testes

- Elementos fora da tela
  - Use `await tester.ensureVisible(finder);` antes de interagir

## 📚 Referências

- https://docs.flutter.dev/testing
- https://pub.dev/packages/http (MockClient)
- https://pub.dev/packages/mockito
- https://martinfowler.com/bliki/TestDrivenDevelopment.html

