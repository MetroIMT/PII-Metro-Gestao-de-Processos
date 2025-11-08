# Guia do Projeto

Este documento complementa o README principal com:

- Estrutura do projeto (árvore completa fornecida)
- Linguagens e tecnologias utilizadas
- Principais partes do código e responsabilidades
- Como rodar o back-end (API Node.js)
- Como rodar o front-end (Flutter/Dart)

---

## Estrutura do projeto

```
PII-Metro-Gestao-de-Processos/
├─ .dart_tool/
│  ├─ dartpad/
│  │  └─ web_plugin_registrant.dart
│  ├─ extension_discovery/
│  │  ├─ README.md
│  │  └─ vs_code.json
│  ├─ flutter_build/
│  │  └─ dart_plugin_registrant.dart
│  ├─ package_config.json
│  ├─ package_graph.json
│  └─ version
├─ android/
│  ├─ .gradle/
│  │  ├─ 8.12/
│  │  │  ├─ checksums/
│  │  │  │  └─ checksums.lock
│  │  │  ├─ executionHistory/
│  │  │  │  └─ executionHistory.lock
│  │  │  ├─ expanded/
│  │  │  ├─ fileChanges/
│  │  │  │  └─ last-build.bin
│  │  │  ├─ fileHashes/
│  │  │  │  ├─ fileHashes.lock
│  │  │  │  └─ resourceHashesCache.bin
│  │  │  ├─ vcsMetadata/
│  │  │  └─ gc.properties
│  │  ├─ buildOutputCleanup/
│  │  │  ├─ buildOutputCleanup.lock
│  │  │  └─ cache.properties
│  │  ├─ nb-cache/
│  │  │  └─ trust/
│  │  │     └─ 671DF32796AC1FE911171536A59B6E7DD0C06220998D0555763712B3A44182CC
│  │  ├─ noVersion/
│  │  │  └─ buildLogic.lock
│  │  └─ vcs-1/
│  │     └─ gc.properties
│  ├─ app/
│  │  ├─ src/
│  │  │  ├─ debug/
│  │  │  │  └─ AndroidManifest.xml
│  │  │  ├─ main/
│  │  │  │  ├─ java/
│  │  │  │  │  └─ io/
│  │  │  │  │     └─ flutter/
│  │  │  │  │        └─ plugins/
│  │  │  │  │           └─ GeneratedPluginRegistrant.java
│  │  │  │  ├─ kotlin/
│  │  │  │  │  └─ com/
│  │  │  │  │     └─ example/
│  │  │  │  │        └─ pi_metro_2025_2/
│  │  │  │  │           └─ MainActivity.kt
│  │  │  │  ├─ res/
│  │  │  │  │  ├─ drawable/
│  │  │  │  │  │  └─ launch_background.xml
│  │  │  │  │  ├─ drawable-v21/
│  │  │  │  │  │  └─ launch_background.xml
│  │  │  │  │  ├─ mipmap-hdpi/
│  │  │  │  │  │  └─ ic_launcher.png
│  │  │  │  │  ├─ mipmap-mdpi/
│  │  │  │  │  │  └─ ic_launcher.png
│  │  │  │  │  ├─ mipmap-xhdpi/
│  │  │  │  │  │  └─ ic_launcher.png
│  │  │  │  │  ├─ mipmap-xxhdpi/
│  │  │  │  │  │  └─ ic_launcher.png
│  │  │  │  │  ├─ mipmap-xxxhdpi/
│  │  │  │  │  │  └─ ic_launcher.png
│  │  │  │  │  ├─ values/
│  │  │  │  │  │  └─ styles.xml
│  │  │  │  │  └─ values-night/
│  │  │  │  │     └─ styles.xml
│  │  │  │  └─ AndroidManifest.xml
│  │  │  └─ profile/
│  │  │     └─ AndroidManifest.xml
│  │  └─ build.gradle.kts
│  ├─ gradle/
│  │  └─ wrapper/
│  │     └─ gradle-wrapper.properties
│  ├─ .gitignore
│  ├─ build.gradle.kts
│  ├─ gradle.properties
│  ├─ local.properties
│  └─ settings.gradle.kts
├─ api/
│  ├─ scripts/
│  │  ├─ add_cpf_telefone.js
│  │  └─ hash.js
│  ├─ src/
│  │  ├─ middlewares/
│  │  │  └─ auth.js
│  │  ├─ routes/
│  │  │  ├─ auth.routes.js
│  │  │  ├─ itens.routes.js
│  │  │  ├─ materiais.routes.js
│  │  │  ├─ movimentos.routes.js
│  │  │  └─ usuarios.routes.js
│  │  ├─ config.js
│  │  ├─ db.js
│  │  ├─ index.js
│  │  └─ indexes.js
│  ├─ uploads/
│  │  └─ (avatars de usuários)
│  ├─ .env
│  ├─ package-lock.json
│  └─ package.json
├─ assets/
│  └─ LogoMetro.png
├─ build/
│  ├─ native_assets/
│  │  └─ macos/
│  │     └─ native_assets.json
│  ├─ reports/
│  │  └─ problems/
│  │     └─ problems-report.html
│  ├─ test_cache/
│  │  └─ build/
│  │     ├─ 210bad4901163cba762d02a4a1c86c00.cache.dill.track.dill
│  │     └─ f61019181a390ebae04f980d79c3991a.cache.dill.track.dill
│  └─ unit_test_assets/
│     ├─ assets/
│     │  └─ LogoMetro.png
│     ├─ fonts/
│     │  └─ MaterialIcons-Regular.otf
│     ├─ packages/
│     │  └─ cupertino_icons/
│     │     └─ assets/
│     │        └─ CupertinoIcons.ttf
│     ├─ shaders/
│     │  └─ ink_sparkle.frag
│     ├─ AssetManifest.bin
│     ├─ AssetManifest.json
│     ├─ FontManifest.json
│     ├─ NativeAssetsManifest.json
│     └─ NOTICES.Z
├─ docs/
│  ├─ BDD_GUIDE.md
│  ├─ PROJECT_GUIDE.md
│  └─ TDD_GUIDE.md
├─ ios/
│  ├─ Flutter/
│  │  ├─ ephemeral/
│  │  │  ├─ flutter_lldb_helper.py
│  │  │  └─ flutter_lldbinit
│  │  ├─ AppFrameworkInfo.plist
│  │  ├─ Debug.xcconfig
│  │  ├─ flutter_export_environment.sh
│  │  ├─ Generated.xcconfig
│  │  └─ Release.xcconfig
│  ├─ Runner/
│  │  ├─ Assets.xcassets/
│  │  │  ├─ AppIcon.appiconset/
│  │  │  │  ├─ Contents.json
│  │  │  │  ├─ Icon-App-1024x1024@1x.png
│  │  │  │  ├─ Icon-App-20x20@1x.png
│  │  │  │  ├─ Icon-App-20x20@2x.png
│  │  │  │  ├─ Icon-App-20x20@3x.png
│  │  │  │  ├─ Icon-App-29x29@1x.png
│  │  │  │  ├─ Icon-App-29x29@2x.png
│  │  │  │  ├─ Icon-App-29x29@3x.png
│  │  │  │  ├─ Icon-App-40x40@1x.png
│  │  │  │  ├─ Icon-App-40x40@2x.png
│  │  │  │  ├─ Icon-App-40x40@3x.png
│  │  │  │  ├─ Icon-App-60x60@2x.png
│  │  │  │  ├─ Icon-App-60x60@3x.png
│  │  │  │  ├─ Icon-App-76x76@1x.png
│  │  │  │  ├─ Icon-App-76x76@2x.png
│  │  │  │  └─ Icon-App-83.5x83.5@2x.png
│  │  │  └─ LaunchImage.imageset/
│  │  │     ├─ Contents.json
│  │  │     ├─ LaunchImage.png
│  │  │     ├─ LaunchImage@2x.png
│  │  │     ├─ LaunchImage@3x.png
│  │  │     └─ README.md
│  │  ├─ Base.lproj/
│  │  │  ├─ LaunchScreen.storyboard
│  │  │  └─ Main.storyboard
│  │  ├─ AppDelegate.swift
│  │  ├─ GeneratedPluginRegistrant.h
│  │  ├─ GeneratedPluginRegistrant.m
│  │  ├─ Info.plist
│  │  └─ Runner-Bridging-Header.h
│  ├─ Runner.xcodeproj/
│  │  ├─ project.xcworkspace/
│  │  │  ├─ xcshareddata/
│  │  │  │  ├─ IDEWorkspaceChecks.plist
│  │  │  │  └─ WorkspaceSettings.xcsettings
│  │  │  └─ contents.xcworkspacedata
│  │  ├─ xcshareddata/
│  │  │  └─ xcschemes/
│  │  │     └─ Runner.xcscheme
│  │  └─ project.pbxproj
│  ├─ Runner.xcworkspace/
│  │  ├─ xcshareddata/
│  │  │  ├─ IDEWorkspaceChecks.plist
│  │  │  └─ WorkspaceSettings.xcsettings
│  │  └─ contents.xcworkspacedata
│  ├─ RunnerTests/
│  │  └─ RunnerTests.swift
│  └─ .gitignore
├─ lib/
│  ├─ screens/
│  │  ├─ home/
│  │  │  ├─ home_screen.dart
│  │  │  └─ widgets/
│  │  │     ├─ carousel.dart
│  │  │     ├─ estoque_item.dart
│  │  │     ├─ movimentacao_card.dart
│  │  │     └─ movimentacao_modal.dart
│  │  └─ login/
│  │     └─ login_screen.dart
│  ├─ services/
│  │  ├─ auth_service.dart
│  │  ├─ excel_service.dart
│  │  ├─ pdf_service.dart
│  │  └─ user_service.dart
│  ├─ models/
│  │  ├─ movimentacao.dart
│  │  └─ user.dart
│  ├─ repositories/
│  │  ├─ alert_repository.dart
│  │  └─ movimentacao_repository.dart
│  ├─ widgets/
│  │  └─ sidebar.dart
│  └─ main.dart
├─ linux/
│  ├─ flutter/
│  │  ├─ ephemeral/
│  │  │  └─ .plugin_symlinks/
│  │  │     ├─ flutter_secure_storage_linux
│  │  │     └─ path_provider_linux
│  │  ├─ CMakeLists.txt
│  │  ├─ generated_plugin_registrant.cc
│  │  ├─ generated_plugin_registrant.h
│  │  └─ generated_plugins.cmake
│  ├─ runner/
│  │  ├─ CMakeLists.txt
│  │  ├─ main.cc
│  │  ├─ my_application.cc
│  │  └─ my_application.h
│  ├─ .gitignore
│  ├─ CMakeLists.txt
│  └─ pubspec.lock
├─ macos/
│  ├─ Flutter/
│  │  ├─ ephemeral/
│  │  │  ├─ flutter_export_environment.sh
│  │  │  └─ Flutter-Generated.xcconfig
│  │  ├─ Flutter-Debug.xcconfig
│  │  ├─ Flutter-Release.xcconfig
│  │  └─ GeneratedPluginRegistrant.swift
│  ├─ Runner/
│  │  ├─ Assets.xcassets/
│  │  │  └─ AppIcon.appiconset/
│  │  │     ├─ app_icon_1024.png
│  │  │     ├─ app_icon_128.png
│  │  │     ├─ app_icon_16.png
│  │  │     ├─ app_icon_256.png
│  │  │     ├─ app_icon_32.png
│  │  │     ├─ app_icon_512.png
│  │  │     ├─ app_icon_64.png
│  │  │     └─ Contents.json
│  │  ├─ Base.lproj/
│  │  │  └─ MainMenu.xib
│  │  ├─ Configs/
│  │  │  ├─ AppInfo.xcconfig
│  │  │  ├─ Debug.xcconfig
│  │  │  ├─ Release.xcconfig
│  │  │  └─ Warnings.xcconfig
│  │  ├─ AppDelegate.swift
│  │  ├─ DebugProfile.entitlements
│  │  ├─ Info.plist
│  │  ├─ MainFlutterWindow.swift
│  │  └─ Release.entitlements
│  ├─ Runner.xcodeproj/
│  │  ├─ project.xcworkspace/
│  │  │  └─ xcshareddata/
│  │  │     └─ IDEWorkspaceChecks.plist
│  │  ├─ xcshareddata/
│  │  │  └─ xcschemes/
│  │  │     └─ Runner.xcscheme
│  │  └─ project.pbxproj
│  ├─ Runner.xcworkspace/
│  │  ├─ xcshareddata/
│  │  │  └─ IDEWorkspaceChecks.plist
│  │  └─ contents.xcworkspacedata
│  ├─ RunnerTests/
│  │  └─ RunnerTests.swift
│  └─ .gitignore
├─ test/
│  ├─ bdd/
│  │  ├─ features/
│  │  │  ├─ autenticacao.feature
│  │  │  ├─ gestao_ferramentas
│  │  │  ├─ gestao_instrumentos.feature
│  │  │  ├─ gestao_usuarios.feature
│  │  │  └─ movimentacoes.feature
│  │  ├─ mocks/
│  │  │  └─ mock_auth_service.dart
│  │  ├─ scenarios/
│  │  │  ├─ autenticacao_test.dart
│  │  │  ├─ gestao_ferramentas_test.dart
│  │  │  ├─ gestao_instrumentos_test.dart
│  │  │  ├─ gestao_usuarios_test.dart
│  │  │  └─ movimentacoes_test.dart
│  │  └─ bdd_suite.dart
│  ├─ controllers/
│  │  └─ login_controller_test.dart
│  ├─ services/
│  │  └─ auth_service_test.dart
│  ├─ widgets/
│  │  └─ login_screen_test.dart
│  └─ widget_test.dart
├─ web/
│  ├─ icons/
│  │  ├─ Icon-192.png
│  │  ├─ Icon-512.png
│  │  ├─ Icon-maskable-192.png
│  │  └─ Icon-maskable-512.png
│  ├─ favicon.png
│  ├─ index.html
│  └─ manifest.json
├─ windows/
│  ├─ flutter/
│  │  ├─ ephemeral/
│  │  │  └─ .plugin_symlinks/
│  │  │     ├─ flutter_secure_storage_windows
│  │  │     └─ path_provider_windows
│  │  ├─ CMakeLists.txt
│  │  ├─ generated_plugin_registrant.cc
│  │  ├─ generated_plugin_registrant.h
│  │  └─ generated_plugins.cmake
│  ├─ runner/
│  │  ├─ resources/
│  │  │  └─ app_icon.ico
│  │  ├─ CMakeLists.txt
│  │  ├─ flutter_window.cpp
│  │  ├─ flutter_window.h
│  │  ├─ main.cpp
│  │  ├─ resource.h
│  │  ├─ runner.exe.manifest
│  │  ├─ Runner.rc
│  │  ├─ utils.cpp
│  │  ├─ utils.h
│  │  ├─ win32_window.cpp
│  │  └─ win32_window.h
│  ├─ .gitignore
│  └─ CMakeLists.txt
├─ .flutter-plugins-dependencies
├─ .gitignore
├─ .metadata
├─ analysis_options.yaml
├─ pubspec.lock
├─ pubspec.yaml
└─ README.md

```

---

## Linguagens e tecnologias

### Front-end

- **Flutter (Dart)**: Framework multiplataforma para UI responsiva
- **Material Design 3**: Design system moderno com tema personalizado Metro SP
- **Flutter Secure Storage**: Armazenamento criptografado de tokens e credenciais
- **HTTP Client**: Comunicação REST com o backend
- **Provider/State Management**: Gerenciamento de estado reativo
- **Navigator 2.0**: Navegação declarativa entre telas

### Back-end

- **Node.js (ES Modules) + Express 5**: Servidor HTTP e API REST
- **MongoDB**: Banco de dados NoSQL com suporte a índices e agregações
- **bcryptjs**: Hash seguro de senhas com salt
- **jsonwebtoken (JWT)**: Autenticação stateless baseada em tokens
- **Multer**: Middleware para upload de arquivos (avatars)
- **dotenv**: Gerenciamento de variáveis de ambiente
- **cors**: Controle de acesso cross-origin

### Infraestrutura

- **MongoDB Atlas ou Local**: Banco de dados em nuvem ou on-premise
- **Plataformas suportadas**: macOS, Linux, Windows, iOS, Android, Web
- **DevTools**: Dart & Flutter DevTools para debugging e análise de performance

---

## Principais partes do código (back-end)

- api/src/index.js: inicialização do servidor Express, conexão com DB, montagem das rotas e health check, configuração de upload de arquivos
- api/src/config.js: leitura das variáveis de ambiente (MONGODB_URI, MONGODB_DB, JWT_SECRET, BCRYPT_ROUNDS)
- api/src/db.js: conexão com MongoDB e helpers (getDB, getClient)
- api/src/indexes.js: criação de índices (usuarios/email único, instrumentos/codigoInterno, etc.) na inicialização
- api/src/middlewares/auth.js: autenticação via JWT, guardas de role (requireRole), e atualização automática de sessões (lastSeen)
- api/src/routes/
  - auth.routes.js: POST /auth/login (gera JWT com expiração, compara senha com bcrypt, cria sessão no banco)
  - itens.routes.js: CRUD básico de itens, buscar por código, alertas de calibração
  - materiais.routes.js: CRUD completo de materiais (GET, POST, PUT, DELETE) por tipo (giro, patrimoniado, consumo)
  - movimentos.routes.js: registro de retirada/devolução por itemId ou por código; evita saldo negativo
  - usuarios.routes.js: CRUD de usuários com regras por perfil (admin, gestor, tecnico), upload de avatar, gerenciamento de sessões, revogação de sessões
- api/scripts/hash.js: gera hash bcrypt para popular senhaHash na base
- api/uploads/: diretório para armazenamento de avatars de usuários

## Principais partes do código (front-end)

- lib/main.dart: setup da aplicação (tema, rotas iniciais)
- lib/services/
  - auth_service.dart: login/logout, armazenamento seguro de token, sessionId e dados do usuário
  - user_service.dart: gerenciamento de usuários, upload/remoção de avatar, listagem e revogação de sessões
  - material_service.dart: CRUD de materiais com comunicação HTTP ao backend
  - pdf_service.dart: geração de relatórios em PDF com formatação personalizada
- lib/models/
  - user.dart: modelo de usuário com suporte a avatar e role
  - material.dart: modelo de material para estoque
  - movimentacao.dart: modelo de movimentação de materiais
- lib/screens/login/
  - login_screen.dart: tela de login com validações
  - login_controller.dart: lógica de controle do login
- lib/screens/home/
  - home_screen.dart: shell principal com menu lateral, dashboard com cards interativos, integração com backend
  - admin_page.dart: página de administração com gerenciamento de perfil, avatar, sessões ativas e troca de senha
  - estoque_page.dart: página de estoque com sidebar responsiva, suporte a desktop/mobile
  - material_giro_page.dart: gerenciamento de materiais de giro conectado ao backend
  - material_consumo_page.dart: gerenciamento de materiais de consumo conectado ao backend
  - material_patrimoniado_page.dart: gerenciamento de materiais patrimoniados conectado ao backend
  - movimentacoes_page.dart: histórico e controle de movimentações
  - reports_page.dart: geração de relatórios com filtros avançados e mapa de desempenho
  - alerts_page.dart: gerenciamento de alertas e notificações
- lib/widgets/
  - sidebar.dart: componente de navegação lateral responsivo (rail para desktop, drawer para mobile)
- lib/repositories/
  - movimentacao_repository.dart: gerenciamento local de movimentações

---

## Como rodar o back-end (API Node.js)

1. Instalar e subir a API:

```
   cd api
   npm install
   npm run dev
```

2. Health check (opcional):

```
   curl http://localhost:8080/health
```

---

## Como rodar o front-end (Flutter)

1. Instalação de dependências (raiz do projeto):

```
   flutter pub get
```

2. Executar com hot reload (escolha um device):

```
   flutter run -d chrome # Web
   flutter run -d ios # iOS Simulator
   flutter run -d android # Android Emulator/Device
   flutter run -d macos # Desktop macOS
```

Dicas: r = hot reload, R = hot restart.

---

## Endpoints da API

### Autenticação e Sessões

```
POST /auth/login
  Body: { email, senha }
  Retorna: { token, sessionId, usuario }
  Cria sessão no MongoDB com informações de dispositivo e IP
```

### Usuários

```
GET /usuarios/:id
  Headers: Authorization Bearer <token>
  Retorna dados do usuário (sem senhaHash)

PATCH /usuarios/:id
  Body: { nome, cpf, telefone, role, avatarUrl, senha, current }
  Atualiza perfil (admin ou próprio usuário)

POST /usuarios/:id/avatar
  Content-Type: multipart/form-data
  Field: avatar (arquivo de imagem)
  Faz upload e atualiza avatarUrl, deletando avatar anterior

DELETE /usuarios/:id/avatar
  Remove avatar e deleta arquivo do sistema

GET /usuarios/:id/sessions
  Lista todas as sessões ativas do usuário

POST /usuarios/:id/sessions/:sessionId/revoke
  Revoga uma sessão específica
```

### Materiais

```
GET /materiais?tipo=giro|consumo|patrimoniado
  Lista materiais por tipo

POST /materiais
  Body: { nome, codigo, tipo, quantidade, local, vencimento }
  Cria novo material

PUT /materiais/:id
  Atualiza material existente

DELETE /materiais/:id
  Remove material do estoque
```

### Itens e Movimentos

```
GET /itens
  Lista todos os itens/instrumentos

POST /movimentos
  Body: { itemId, tipo, responsavel, destino }
  Registra movimentação (retirada/devolução)
```

## Observações e dicas

### Configuração Inicial

- Se o script de hash falhar quando executado da raiz, rode dentro de api/
- Certifique-se que JWT_SECRET está definido no .env
- Verifique se os usuários no MongoDB possuem senhaHash válido

### Autenticação

- Todos os endpoints (exceto /auth/login e /health) exigem Bearer Token (JWT)
- Token retornado em /auth/login tem expiração de 24h
- sessionId é opcional no header X-Session-Id, mas permite rastreamento de atividade

### Upload de Arquivos

- Certifique-se que a pasta api/uploads/ existe e tem permissões adequadas
- Avatars são servidos estaticamente via /uploads/
- Formato suportado: JPEG, PNG (validação no frontend)
- Tamanho máximo recomendado: 5MB

### Banco de Dados

- Índices recomendados no MongoDB:
  - `{ itemId: 1, dataHora: -1 }` para movimentos
  - `{ codigoInterno: 1, dataHora: -1 }` para consultas por código
  - `{ userId: 1, criadoEm: -1 }` para sessões
- Coleções principais: usuarios, materiais, itens, movimentos, sessions

### Interface Responsiva

- Sidebar é habilitada com `withSidebar: true` nas páginas de materiais
- Layout adaptativo detecta largura < 600px para mobile
- NavigationRail (desktop) e Drawer (mobile) compartilham mesma lógica
