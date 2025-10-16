Feature: Autenticação de Usuários
  Como um funcionário do Metrô
  Eu quero fazer login no sistema
  Para acessar as funcionalidades de gestão

  Scenario: Login bem-sucedido com credenciais válidas
    Given que estou na página de login
    When eu preencho o campo email com "admin@metrosp.com.br"
    And eu preencho o campo senha com "Admin@123"
    And eu clico no botão Entrar
    Then eu devo ver a mensagem "Login realizado com sucesso!"

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

  Scenario: Alternar visibilidade da senha
    Given que estou na página de login
    When eu preencho o campo senha com "minhasenha"
    Then a senha deve estar oculta
    When eu clico no ícone de visibilidade
    Then a senha deve estar visível