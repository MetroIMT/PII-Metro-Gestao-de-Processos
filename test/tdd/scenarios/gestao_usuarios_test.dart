import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature: Gestão de Usuários', () {
    testWidgets(
      'Scenario: Criar novo usuário com sucesso',
      (tester) async {
        // Given: que estou na página de criação de usuário
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Criar Usuário')),
              body: Column(
                children: [
                  const TextField(
                    key: Key('nome_field'),
                    decoration: InputDecoration(labelText: 'Nome'),
                  ),
                  const TextField(
                    key: Key('email_field'),
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  const TextField(
                    key: Key('senha_field'),
                    decoration: InputDecoration(labelText: 'Senha'),
                    obscureText: true,
                  ),
                  DropdownButton<String>(
                    key: const Key('papel_dropdown'),
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('user')),
                      DropdownMenuItem(value: 'admin', child: Text('admin')),
                    ],
                    onChanged: (value) {},
                  ),
                  ElevatedButton(onPressed: () {}, child: const Text('Salvar')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: eu preencho o nome com "João Silva"
        final nomeField = find.byKey(const Key('nome_field'));
        await tester.enterText(nomeField, 'João Silva');
        await tester.pump();

        // And: eu preencho o email com "joao.silva@metrosp.com.br"
        final emailField = find.byKey(const Key('email_field'));
        await tester.enterText(emailField, 'joao.silva@metrosp.com.br');
        await tester.pump();

        // And: eu preencho a senha com "Senha@123"
        final senhaField = find.byKey(const Key('senha_field'));
        await tester.enterText(senhaField, 'Senha@123');
        await tester.pump();

        // And: eu seleciono o papel "user"
        // (Implementar quando tiver a tela real)

        // And: eu clico no botão Salvar
        final botaoSalvar = find.text('Salvar');
        await tester.tap(botaoSalvar);
        await tester.pump();

        // Then: o usuário deve ser criado com sucesso
        // (Verificar quando tiver integração com backend)
      },
      skip: true, // Remova quando implementar a tela
    );

    testWidgets(
      'Scenario: Falha ao criar usuário com email de domínio inválido',
      (tester) async {
        // Implementar quando tiver a tela de criação de usuário
      },
      skip: true,
    );
  });
}
