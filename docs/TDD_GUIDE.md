# 🧪 Guia de Testes TDD - Sistema de Login

## 📊 Status Atual

```
✅ 18 testes passando
⏱️ Tempo de execução: ~1 segundo
📊 Cobertura: ~93%
```

## 🚀 Comandos Rápidos

```bash
# Executar todos os testes
flutter test

# Executar testes específicos
flutter test test/services/auth_service_test.dart
flutter test test/controllers/login_controller_test.dart
flutter test test/widgets/login_screen_test.dart

# Ver cobertura
flutter test --coverage

# Ver resultados detalhados
flutter test --reporter=expanded

# Gerar mocks (após alterações nos testes)
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📁 Estrutura de Testes

```
test/
├── services/
│   ├── auth_service_test.dart       # 6 testes - Autenticação
│   └── auth_service_test.mocks.dart # Gerado automaticamente
├── controllers/
│   ├── login_controller_test.dart   # 4 testes - Controller
│   └── login_controller_test.mocks.dart
├── widgets/
│   └── login_screen_test.dart       # 7 testes - Interface
└── widget_test.dart                 # 1 teste - Placeholder
```

## 🎯 O que é TDD?

**Test Driven Development (TDD)** é uma metodologia onde os testes são escritos **antes** do código:

1. **🔴 Red**: Escrever um teste que falha
2. **🟢 Green**: Escrever código mínimo para passar
3. **🔵 Refactor**: Melhorar o código mantendo testes passando

### Benefícios

- ✅ Código mais confiável e com menos bugs
- ✅ Refatoração segura
- ✅ Documentação viva (os testes documentam o comportamento)
- ✅ Design de código melhor

## 📋 Testes Implementados

### 1. AuthService (6 testes)

**Cenários testados:**

- ✅ Login com credenciais inválidas (401)
- ✅ Resposta sem token válido
- ✅ Erro de conexão com servidor
- ✅ Erro interno do servidor (500)
- ✅ Email vazio
- ✅ Senha vazia

**Exemplo:**

```dart
test('Login com credenciais inválidas deve retornar false', () async {
  // Arrange - Preparação
  when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
    .thenAnswer((_) async => http.Response('Unauthorized', 401));

  // Act - Ação
  final result = await authService.login(
    email: 'errado@metro.com',
    senha: 'senhaerrada',
  );

  // Assert - Verificação
  expect(result, false);
});
```

### 2. LoginController (4 testes)

**Cenários testados:**

- ✅ Login bem-sucedido
- ✅ Login com credenciais inválidas
- ✅ Parâmetros passados corretamente ao service
- ✅ Propagação de exceções

**Exemplo:**

```dart
test('Login bem-sucedido deve retornar true', () async {
  // Arrange
  when(mockAuthService.login(
    email: anyNamed('email'),
    senha: anyNamed('senha'),
  )).thenAnswer((_) async => true);

  // Act
  final result = await loginController.login(
    email: 'teste@metro.com',
    password: 'senha123',
  );

  // Assert
  expect(result, true);
});
```

### 3. LoginScreen (7 testes)

**Cenários testados:**

- ✅ Renderização de todos elementos (campos, botões, logo)
- ✅ Validação de campos vazios
- ✅ Entrada de texto (email e senha)
- ✅ Toggle de visibilidade da senha
- ✅ Checkbox "Lembrar credenciais"
- ✅ Exibição de textos de boas-vindas
- ✅ Botão de cadastro presente e clicável

**Exemplo:**

```dart
testWidgets('Deve mostrar mensagem de erro quando campos estão vazios',
    (WidgetTester tester) async {
  // Arrange
  await tester.pumpWidget(const MaterialApp(home: LoginPage()));

  // Act
  await tester.ensureVisible(find.text('Entrar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Entrar'), warnIfMissed: false);
  await tester.pumpAndSettle();

  // Assert
  expect(find.text('Preencha email e senha.'), findsOneWidget);
});
```

## 📊 Cobertura por Componente

| Componente      | Testes | Cobertura | Status |
| --------------- | ------ | --------- | ------ |
| AuthService     | 6      | ~95%      | ✅     |
| LoginController | 4      | 100%      | ✅     |
| LoginScreen     | 7      | ~90%      | ✅     |
| **TOTAL**       | **18** | **~93%**  | ✅     |

## 🔧 Dependências

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4 # Framework para criar mocks
  build_runner: ^2.9.0 # Gerador de código
```

## 📝 Padrão AAA (Arrange-Act-Assert)

Todos os testes seguem este padrão:

```dart
test('descrição do teste', () async {
  // Arrange - Preparar o cenário
  // Configurar mocks, criar objetos, definir dados

  // Act - Executar a ação
  // Chamar o método/função que está sendo testada

  // Assert - Verificar o resultado
  // Validar se o comportamento está correto
});
```

## 🎓 Boas Práticas Aplicadas

1. ✅ **Isolamento**: Cada teste é independente
2. ✅ **Clareza**: Nomes descritivos e estrutura AAA
3. ✅ **Rapidez**: Testes executam em ~1 segundo
4. ✅ **Determinísticos**: Sem comportamento aleatório
5. ✅ **Mocks**: Dependências externas mockadas (HTTP, Storage)

## ✅ Checklist Antes do Commit

- [ ] Todos os testes passando (`flutter test`)
- [ ] Código formatado (`flutter format .`)
- [ ] Sem warnings (`flutter analyze`)
- [ ] Cobertura acima de 85%

## 🐛 Troubleshooting

### Problema: "Target of URI doesn't exist: '...mocks.dart'"

**Solução:**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Problema: Testes falhando com "MissingPluginException"

**Solução:** Adicione no início do teste:

```dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // ... seus testes
}
```

### Problema: Elementos fora da tela em testes de widget

**Solução:** Use `ensureVisible`:

```dart
await tester.ensureVisible(find.text('Botão'));
await tester.pumpAndSettle();
```

## 📚 Referências

- [Documentação Flutter Testing](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [TDD - Martin Fowler](https://martinfowler.com/bliki/TestDrivenDevelopment.html)

---

**Última atualização**: 16 de outubro de 2025  
**Versão**: 1.0.0
