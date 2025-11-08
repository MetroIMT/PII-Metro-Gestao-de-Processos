# 📋 Guia de Testes BDD - Projeto Metro

## 🎯 O que é BDD?

BDD (Behavior-Driven Development) é uma metodologia de desenvolvimento que foca no comportamento da aplicação do ponto de vista do usuário.
Vantagens:

- ✅ Comunicação clara entre desenvolvedores, QA e stakeholders

- ✅ Documentação viva - os testes descrevem o que o sistema faz

- ✅ Testes legíveis - qualquer pessoa pode entender

- ✅ Cobertura de cenários reais de uso

### Sintaxe Gherkin:

Feature: Funcionalidade que será testada

```
Scenario: Cenário específico de uso
  Given [contexto inicial]
  When [ação do usuário]
  And [ação adicional]
  Then [resultado esperado]
```

## 📁 Estrutura do Projeto

```
test/
├── bdd/
│   ├── features/              # Arquivos .feature (Gherkin)
│   │   ├── autenticacao.feature
│   │   ├── gestao_ferramentas.feature
│   │   ├── gestao_instrumentos.feature
│   │   ├── gestao_usuarios.feature
│   │   └── movimentacoes.feature
│   ├── mocks/                 # Mocks para testes
│   │   └── mock_auth_service.dart
│   └── bdd_suite.dart         # Suite completa de testes
├── tdd/
│   └── scenarios/             # Implementação dos testes TDD
│       ├── autenticacao_test.dart
│       ├── gestao_ferramentas_test.dart
│       ├── gestao_instrumentos_test.dart
│       ├── gestao_usuarios_test.dart
│       └── movimentacoes_test.dart
├── controllers/               # Testes de controllers
│   └── login_controller_test.dart
├── services/                  # Testes de services
│   └── auth_service_test.dart
└── widgets/                   # Testes de widgets
    └── login_screen_test.dart
```

**Nota**: A partir do commit `40bf4f7`, os testes de cenários foram reorganizados:

- Testes BDD (comportamento) mantidos em `test/bdd/`
- Testes TDD (implementação) movidos para `test/tdd/scenarios/`
- Separação clara entre features (Gherkin) e implementação de testes

## ⚙️ Configuração Inicial

1. Dependências

Adicione no pubspec.yaml:

```
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0
  http: ^1.0.0
```

2. Instalar dependências
   `flutter pub get`

📝 Escrevendo Features
Exemplo: test/bdd/features/autenticacao.feature

```
Feature: Autenticação de Usuários
  Como um usuário do sistema
  Eu quero fazer login com minhas credenciais
  Para acessar as funcionalidades do sistema

  Scenario: Login bem-sucedido com credenciais válidas
    Given que estou na página de login
    When eu preencho o campo email com "admin@metrosp.com.br"
    And eu preencho o campo senha com "Admin@123"
    And eu clico no botão Entrar
    Then eu devo ver a mensagem "Login realizado com sucesso!"
    And eu devo ser redirecionado para a tela inicial

  Scenario: Login falha com credenciais inválidas
    Given que estou na página de login
    When eu preencho o campo email com "admin@metrosp.com.br"
    And eu preencho o campo senha com "senhaerrada"
    And eu clico no botão Entrar
    Then eu devo ver a mensagem "Credenciais inválidas."

  Scenario: Login falha com campos vazios
    Given que estou na página de login
    When eu clico no botão Entrar
    Then eu devo ver a mensagem "Preencha email e senha."

  Scenario: Login falha com email de domínio inválido
    Given que estou na página de login
    When eu preencho o campo email com "usuario@gmail.com"
    And eu preencho o campo senha com "senha123"
    And eu clico no botão Entrar
    Then eu devo ver a mensagem contendo "@metrosp.com.br"

```

🎭 Criando Mocks
Exemplo: test/bdd/mocks/mock_auth_service.dart

```import 'package:pi_metro_2025_2/services/auth_service.dart';

class MockAuthService extends AuthService {
  MockAuthService() : super();

  @override
  Future<bool> login({required String email, required String senha}) async {
    // Simular delay de rede
    await Future.delayed(const Duration(milliseconds: 100));

    final normalizedEmail = email.trim().toLowerCase();

    // Validar campos vazios
    if (normalizedEmail.isEmpty || senha.isEmpty) {
      return false;
    }

    // Validar domínio do email
    if (!normalizedEmail.endsWith('@metrosp.com.br')) {
      return false;
    }

    // Simular credenciais válidas
    if (normalizedEmail == 'admin@metrosp.com.br' && senha == 'Admin@123') {
      return true;
    }

    // Credenciais inválidas
    return false;
  }
}
```

### Por que usar Mocks?

- ✅ Isolamento - Testa apenas a lógica da UI

- ✅ Velocidade - Não depende de rede ou banco de dados

- ✅ Confiabilidade - Resultados previsíveis

- ✅ Controle - Simula cenários específicos (erro, sucesso, timeout)

## 🧪 Escrevendo Testes

Exemplo: test/bdd/scenarios/autenticacao_test.dart

```
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
        tester.view.physicalSize = const Size(1200, 1920);
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
        tester.view.physicalSize = const Size(1200, 1920);
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
  });
}
```

## Estrutura de um Teste BDD:

- Setup - Configurar tela, mocks e controller

- Given - Estado inicial (renderizar a página)

- When - Ações do usuário (preencher campos, clicar botões)

- Then - Verificar resultado esperado (mensagens, navegação)

## 🚀 Executando os Testes

### Executar testes TDD (implementação)

```bash
# Um arquivo específico
flutter test test/tdd/scenarios/autenticacao_test.dart

# Todos os testes TDD
flutter test test/tdd/

# Com verbose (mais detalhes)
flutter test test/tdd/scenarios/autenticacao_test.dart --verbose

# Um cenário específico
flutter test test/tdd/scenarios/autenticacao_test.dart --plain-name "Login bem-sucedido"
```

### Executar todos os testes BDD (suite completa)

```bash
flutter test test/bdd/bdd_suite.dart
```

### Executar todos os testes do projeto

```bash
# Todos os testes (TDD + BDD + unitários + widgets)
flutter test

# Testes de serviços
flutter test test/services/

# Testes de controllers
flutter test test/controllers/

# Testes de widgets
flutter test test/widgets/
```

### Gerar relatório de cobertura

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## 🐛 Troubleshooting

### Problema: RenderFlex overflowed

#### Causa: Layout não cabe na tela do teste.

##### Solução:

```
// Aumentar o tamanho da tela
tester.view.physicalSize = const Size(1200, 1920);
```

### Ou ajustar o layout com Flexible ou Expanded.

### Problema: Widget not found

#### Causa: Widget ainda não foi renderizado ou animação não terminou.

##### Solução:

```
await tester.pumpAndSettle(); // Espera todas as animações
await tester.pump(const Duration(milliseconds: 500)); // Espera tempo específico
```

### Problema: Looking up a deactivated widget's ancestor

#### Causa: Tentando acessar widget após ele ser destruído.

##### Solução:

```
if (mounted) {
  // Só executa se o widget ainda existe
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

### Problema: HttpClient returns 400

#### Causa: Teste está tentando fazer requisição HTTP real.

##### Solução:

```
// Usar mock ao invés de serviço real
final mockService = MockAuthService();
final controller = LoginController(authService: mockService);
```

### Problema: Teste passa localmente mas falha no CI/CD

#### Causa: Diferenças de ambiente (tamanho de tela, fontes, etc).

##### Solução:

```
// Configurar ambiente consistente
tester.view.physicalSize = const Size(1200, 1920);
tester.view.devicePixelRatio = 1.0;
addTearDown(() => tester.view.resetPhysicalSize());
```

## 📊 Exemplo de Relatório de Testes

```
00:02 +5: All tests passed!

Feature: Autenticação de Usuários
  ✅ Scenario: Login bem-sucedido com credenciais válidas
  ✅ Scenario: Login falha com credenciais inválidas
  ✅ Scenario: Login falha com campos vazios
  ✅ Scenario: Login falha com email de domínio inválido
  ✅ Scenario: Alternar visibilidade da senha

5 tests passed, 0 failed
```

## � Atualizações Recentes no Projeto

### Reorganização da Estrutura de Testes (PR #23)

A partir do commit `40bf4f7`, a estrutura de testes foi reorganizada:

**Antes:**

```
test/bdd/scenarios/  # Continha tanto features quanto testes
```

**Depois:**

```
test/bdd/features/   # Apenas arquivos .feature (Gherkin)
test/bdd/mocks/      # Mocks compartilhados
test/tdd/scenarios/  # Implementação dos testes
```

**Motivação:**

- ✅ Separação clara entre especificação (BDD) e implementação (TDD)
- ✅ Melhor organização do código de testes
- ✅ Facilita manutenção e localização de testes específicos

### Novas Features Implementadas

```gherkin
Feature: Gestão de Usuários
  - Cadastro de usuários com diferentes perfis
  - Upload e remoção de avatar
  - Gerenciamento de sessões ativas

Feature: Gestão de Materiais
  - CRUD de materiais por tipo (giro, consumo, patrimoniado)
  - Integração com backend MongoDB
  - Validações de estoque

Feature: Movimentações
  - Registro de entrada/saída de materiais
  - Histórico de movimentações
  - Filtros por data e usuário
```

### Cobertura de Testes Atual

```
✅ Autenticação: 18 cenários
✅ Gestão de Usuários: 12 cenários
✅ Gestão de Ferramentas: 8 cenários
✅ Gestão de Materiais: 15 cenários
✅ Movimentações: 10 cenários

Total: 63+ cenários cobertos
```

## �🎓 Recursos Adicionais

- Documentação Oficial:

- Flutter Testing

- Widget Testing

- Mockito

## Artigos Recomendados:

- BDD with Flutter

- Testing Best Practices

## 📝 Checklist para Novos Testes

Ao criar um novo teste BDD, verifique:

1. Feature file criado em `test/bdd/features/`

2. Mock criado em `test/bdd/mocks/` (se necessário)

3. Teste implementado em `test/tdd/scenarios/` (não mais em bdd/scenarios)

4. Todos os cenários da feature cobertos

5. Testes passando localmente

6. Nomenclatura clara e descritiva

7. Comentários explicando Given/When/Then

8. Tamanho de tela configurado

9. Mocks injetados corretamente

10. Aguarda animações e requisições

11. Verificar se o teste está na pasta correta (TDD vs BDD)
