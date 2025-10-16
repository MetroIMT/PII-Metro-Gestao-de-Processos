Feature: Gestão de Instrumentos
  Como um usuário do sistema
  Eu quero gerenciar instrumentos
  Para controlar o inventário de instrumentos de medição

  Scenario: Cadastrar novo instrumento
    Given que estou na página de cadastro de instrumento
    When eu preencho o código com "INS-001"
    And eu preencho o nome com "Multímetro Digital"
    And eu preencho a data de calibração com "2025-01-15"
    And eu clico no botão Salvar
    Then o instrumento deve ser cadastrado com sucesso