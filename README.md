# Sistema de Gestão de Materiais e Instrumentos do Metrô de São Paulo

## Criação e Implementação de Soluções Digitais para Gestão de Processos

### Parceiro: Metrô de São Paulo

## Contexto Geral

O Departamento de Restabelecimento de Sistemas do Metrô SP é responsável por atender falhas operacionais em equipamentos fixos nas quatro linhas em operação. São 186 técnicos que atuam em regime 24/7, com escala A e B, alocados em 12 bases de manutenção com estoques de materiais e instrumentos.

Essas equipes trabalham com mais de 1.372 tipos de materiais e 686 instrumentos, muitos deles de alto valor, com necessidade de rastreabilidade, controle de validade (ex: calibração), logística eficiente e segurança patrimonial.

Atualmente, o controle desses recursos é feito de forma manual e descentralizada, gerando perda de materiais, extravios, retrabalho, atrasos e risco de não conformidade com normas técnicas.

## Objetivos do Projeto

Desenvolver soluções digitais acessíveis por desktop e mobile que:

- Automatizem o controle de estoque de materiais e sua movimentação
- Gerenciem de forma segura e rastreável a retirada, devolução e status dos instrumentos técnicos
- Forneçam visão consolidada e em tempo real do inventário, com alertas e relatórios
- Implementem controle de saldos em tempo real, com alertas para estoque mínimo
- Permitam a inclusão de códigos de patrimônio e dados para rastreabilidade
- Criem relatórios e dashboards analíticos com filtros personalizáveis
- Ofereçam interfaces responsivas para acesso via desktop e celular

## Requisitos Funcionais

### Sistema de Estoque (Materiais de Consumo, Giro e Patrimoniado)

- Registro de entrada e saída de materiais, por código único
- Controle de saldos por base, veículo, tipo de material e localização
- Cadastro com responsável, data e destino da movimentação
- Inclusão de códigos de patrimônio e rastreabilidade por item
- Emissão de alertas de estoque mínimo
- Geração de relatórios e gráficos por base, equipe e tipo de item
- **CRUD completo de materiais** integrado com banco de dados MongoDB
- **Interface responsiva** com sidebar adaptável para desktop e mobile
- **Filtros avançados** por categoria, data e usuário
- **Integração backend-frontend** via API REST

### Sistema de Instrumentos Técnicos

- Controle de retirada e devolução por funcionário
- Atualização automática de status: "em uso", "em campo", "disponível"
- Avisos de validade de calibração e pendências por instrumento
- Histórico completo de uso por instrumento e por funcionário

### Sistema de Autenticação e Sessões

- Acesso diferenciado por perfil (Administrador e Usuário)
- **Rastreamento de sessões** com informações de dispositivo, IP e última atividade
- **Controle de sessões ativas** com visualização e revogação por usuário
- **Middleware de atualização automática** do lastSeen das sessões
- **Gerenciamento de perfil** com upload e remoção de avatar
- Armazenamento seguro de tokens JWT e sessionId

### Segurança e Governança

- Rastreabilidade completa (quem retirou, quando retirou, quando devolveu, posição atual)
- Geração de alertas de vencimento da calibração
- Responsabilização automática em caso de extravio
- **Sistema de roles** com permissões diferenciadas
- **Auditoria de sessões** com histórico de acessos

## Benefícios Esperados

- Redução de perdas e extravios de materiais
- Melhor planejamento de reposição e controle de consumo
- Rastreabilidade por item, base, destino e responsável
- Eficiência na logística e suporte à manutenção
- Geração de dados confiáveis para auditorias e relatórios operacionais

## Tecnologias Utilizadas

### Frontend

- **Flutter/Dart**: Framework multiplataforma para desenvolvimento de interfaces responsivas
- **Material Design 3**: Design system seguindo padrões do Material You
- **Flutter Secure Storage**: Armazenamento seguro de tokens e credenciais
- **HTTP Client**: Comunicação com API REST
- **Provider/State Management**: Gerenciamento de estado da aplicação

### Backend

- **Node.js + Express 5**: Servidor HTTP e API REST
- **MongoDB**: Banco de dados NoSQL para persistência
- **JWT (jsonwebtoken)**: Autenticação e autorização baseada em tokens
- **bcryptjs**: Hash seguro de senhas
- **Multer**: Upload de arquivos (avatars)
- **CORS**: Controle de acesso entre origens

### DevOps e Qualidade

- **Flutter Test**: Framework de testes unitários e de integração
- **TDD/BDD**: Metodologias de desenvolvimento orientado a testes
- **Git/GitHub**: Controle de versão e colaboração
- **VS Code**: Ambiente de desenvolvimento integrado

## Sobre o Desenvolvimento

Este projeto é comum aos três cursos:

- Ciência da Computação (CIC)
- Sistemas de Informação (SIN)
- Inteligência Artificial e Ciência de Dados (ICD)

O projeto será apresentado aos técnicos e engenheiros do Metrô de São Paulo, com potencial de implementação real em suas operações.

## Testes e TDD

Este projeto implementa **Test Driven Development (TDD)** com cobertura de ~93% no sistema de login.

### Status dos Testes

```
✅ 18 testes passando
⏱️ Tempo de execução: ~1 segundo
📊 Cobertura: ~93%
```

### Executar Testes

```bash
# Todos os testes
flutter test

# Testes específicos
flutter test test/services/auth_service_test.dart
flutter test test/controllers/login_controller_test.dart
flutter test test/widgets/login_screen_test.dart

# Testes TDD
flutter test test/tdd/

# Testes BDD
flutter test test/bdd/
```

### Documentação

📖 **[Guia Completo de Testes TDD](./docs/TDD_GUIDE.md)**

📖 **[Guia Completo de Testes BDD](./docs/BDD_GUIDE.md)**

📖 **[Guia Técnico Completo sobre este projeto](./docs/PROJECT_GUIDE.md)**

---
