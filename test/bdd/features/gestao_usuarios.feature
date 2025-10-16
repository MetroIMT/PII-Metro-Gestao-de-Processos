Feature: Gestão de Usuários
  Como um administrador do sistema
  Eu quero gerenciar usuários
  Para controlar o acesso ao sistema

  Scenario: Criar novo usuário com sucesso
    Given que estou na página de criação de usuário
    When eu preencho o nome com "João Silva"
    And eu preencho o email com "joao.silva@metrosp.com.br"
    And eu preencho a senha com "Senha@123"
    And eu seleciono o papel "user"
    And eu clico no botão Salvar
    Then o usuário deve ser criado com sucesso
    And eu devo ver a mensagem "Usuário criado com sucesso"

  Scenario: Falha ao criar usuário com email de domínio inválido
    Given que estou na página de criação de usuário
    When eu preencho o email com "joao.silva@gmail.com"
    And eu preencho os demais campos obrigatórios
    And eu clico no botão Salvar
    Then eu devo ver a mensagem "Email deve ser do domínio @metrosp.com.br"