Feature: Movimentações de Ferramentas e Instrumentos
  Como um usuário do sistema
  Eu quero registrar movimentações
  Para controlar empréstimos e devoluções

  Scenario: Registrar empréstimo de ferramenta
    Given que existe uma ferramenta disponível
    When eu registro um empréstimo de 5 unidades
    Then a quantidade disponível deve diminuir em 5
    And eu devo ver a mensagem "Empréstimo registrado com sucesso"