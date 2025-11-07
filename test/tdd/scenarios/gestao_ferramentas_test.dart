import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature: Gestão de Ferramentas', () {
    testWidgets(
      'Scenario: Cadastrar nova ferramenta',
      (tester) async {
        // Given: que estou na página de cadastro de ferramenta
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('Cadastrar Ferramenta')),
              body: Column(
                children: [
                  const TextField(
                    key: Key('codigo_field'),
                    decoration: InputDecoration(labelText: 'Código'),
                  ),
                  const TextField(
                    key: Key('nome_field'),
                    decoration: InputDecoration(labelText: 'Nome'),
                  ),
                  const TextField(
                    key: Key('quantidade_field'),
                    decoration: InputDecoration(labelText: 'Quantidade'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Salvar'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // When: eu preencho o código com "FER-001"
        final codigoField = find.byKey(const Key('codigo_field'));
        await tester.enterText(codigoField, 'FER-001');
        await tester.pump();

        // And: eu preencho o nome com "Chave de Fenda"
        final nomeField = find.byKey(const Key('nome_field'));
        await tester.enterText(nomeField, 'Chave de Fenda');
        await tester.pump();

        // And: eu preencho a quantidade com "50"
        final quantidadeField = find.byKey(const Key('quantidade_field'));
        await tester.enterText(quantidadeField, '50');
        await tester.pump();

        // And: eu clico no botão Salvar
        final botaoSalvar = find.text('Salvar');
        await tester.tap(botaoSalvar);
        await tester.pump();

        // Then: a ferramenta deve ser cadastrada com sucesso
        // (Verificar quando tiver integração com backend)
      },
      skip: true, // Remova quando implementar a tela
    );
  });
}