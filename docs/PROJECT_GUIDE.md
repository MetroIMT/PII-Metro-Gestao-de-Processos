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
│ ├─ chrome-device/
│ │ └─ Default/
│ │ ├─ AutofillStrikeDatabase/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ blob_storage/
│ │ │ ├─ 464a0f5f-6c3d-4ac1-9a2e-20c040c92b41/
│ │ │ ├─ cb84f77b-0bf1-4f35-9aa4-9a9a402bcfdc/
│ │ │ ├─ d6568fbd-263c-495d-907e-7d44a7180b43/
│ │ │ └─ f0a4b446-3e24-4517-bdac-3a0093801995/
│ │ ├─ BudgetDatabase/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ chrome_cart_db/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ ClientCertificates/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ commerce_subscription_db/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ discount_infos_db/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ discounts_db/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ Download Service/
│ │ │ ├─ EntryDB/
│ │ │ │ ├─ LOCK
│ │ │ │ ├─ LOG
│ │ │ │ └─ LOG.old
│ │ │ └─ Files/
│ │ ├─ Extension Rules/
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ MANIFEST-000001
│ │ ├─ Extension Scripts/
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ MANIFEST-000001
│ │ ├─ Extension State/
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ ├─ LOG.old
│ │ │ └─ MANIFEST-000001
│ │ ├─ Feature Engagement Tracker/
│ │ │ ├─ AvailabilityDB/
│ │ │ │ ├─ LOCK
│ │ │ │ ├─ LOG
│ │ │ │ └─ LOG.old
│ │ │ └─ EventDB/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ GCM Store/
│ │ │ ├─ Encryption/
│ │ │ │ ├─ CURRENT
│ │ │ │ ├─ LOCK
│ │ │ │ ├─ LOG
│ │ │ │ ├─ LOG.old
│ │ │ │ └─ MANIFEST-000001
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ ├─ LOG.old
│ │ │ └─ MANIFEST-000001
│ │ ├─ Local Storage/
│ │ │ └─ leveldb/
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ ├─ LOG.old
│ │ │ └─ MANIFEST-000001
│ │ ├─ optimization_guide_hint_cache_store/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ parcel_tracking_db/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ PersistentOriginTrials/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ Segmentation Platform/
│ │ │ ├─ SegmentInfoDB/
│ │ │ │ ├─ LOCK
│ │ │ │ ├─ LOG
│ │ │ │ └─ LOG.old
│ │ │ ├─ SignalDB/
│ │ │ │ ├─ LOCK
│ │ │ │ ├─ LOG
│ │ │ │ └─ LOG.old
│ │ │ └─ SignalStorageConfigDB/
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ └─ LOG.old
│ │ ├─ Service Worker/
│ │ │ ├─ Database/
│ │ │ │ ├─ CURRENT
│ │ │ │ ├─ LOCK
│ │ │ │ ├─ LOG
│ │ │ │ ├─ LOG.old
│ │ │ │ └─ MANIFEST-000001
│ │ │ └─ ScriptCache/
│ │ │ ├─ index-dir/
│ │ │ │ └─ the-real-index
│ │ │ ├─ 2cc80dabc69f58b6_0
│ │ │ ├─ 4cb013792b196a35_0
│ │ │ ├─ 4cb013792b196a35_1
│ │ │ └─ index
│ │ ├─ Session Storage/
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ ├─ LOG.old
│ │ │ └─ MANIFEST-000001
│ │ ├─ Sessions/
│ │ │ ├─ Session_13404449864547832
│ │ │ ├─ Session_13404481887052175
│ │ │ ├─ Session_13404494494204898
│ │ │ ├─ Session_13404577218230806
│ │ │ ├─ Session_13404626908621404
│ │ │ ├─ Tabs_13404450483850181
│ │ │ ├─ Tabs_13404481887421277
│ │ │ ├─ Tabs_13404494494577296
│ │ │ ├─ Tabs_13404577218656258
│ │ │ └─ Tabs_13404626909022959
│ │ ├─ Shared Dictionary/
│ │ │ ├─ cache/
│ │ │ │ ├─ index-dir/
│ │ │ │ │ └─ the-real-index
│ │ │ │ └─ index
│ │ │ ├─ db
│ │ │ └─ db-journal
│ │ ├─ shared_proto_db/
│ │ │ ├─ metadata/
│ │ │ │ ├─ CURRENT
│ │ │ │ ├─ LOCK
│ │ │ │ ├─ LOG
│ │ │ │ ├─ LOG.old
│ │ │ │ └─ MANIFEST-000001
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ ├─ LOG.old
│ │ │ └─ MANIFEST-000001
│ │ ├─ Site Characteristics Database/
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ ├─ LOG.old
│ │ │ └─ MANIFEST-000001
│ │ ├─ Sync Data/
│ │ │ └─ LevelDB/
│ │ │ ├─ CURRENT
│ │ │ ├─ LOCK
│ │ │ ├─ LOG
│ │ │ ├─ LOG.old
│ │ │ └─ MANIFEST-000001
│ │ ├─ WebStorage/
│ │ │ ├─ QuotaManager
│ │ │ └─ QuotaManager-journal
│ │ ├─ Account Web Data
│ │ ├─ Account Web Data-journal
│ │ ├─ Affiliation Database
│ │ ├─ Affiliation Database-journal
│ │ ├─ BookmarkMergedSurfaceOrdering
│ │ ├─ BrowsingTopicsSiteData
│ │ ├─ BrowsingTopicsSiteData-journal
│ │ ├─ BrowsingTopicsState
│ │ ├─ Cookies
│ │ ├─ Cookies-journal
│ │ ├─ DIPS
│ │ ├─ Favicons
│ │ ├─ Favicons-journal
│ │ ├─ heavy_ad_intervention_opt_out.db
│ │ ├─ heavy_ad_intervention_opt_out.db-journal
│ │ ├─ History
│ │ ├─ History-journal
│ │ ├─ LOCK
│ │ ├─ LOG
│ │ ├─ LOG.old
│ │ ├─ Login Data
│ │ ├─ Login Data For Account
│ │ ├─ Login Data For Account-journal
│ │ ├─ Login Data-journal
│ │ ├─ Network Action Predictor
│ │ ├─ Network Action Predictor-journal
│ │ ├─ Network Persistent State
│ │ ├─ passkey_enclave_state
│ │ ├─ Preferences
│ │ ├─ PreferredApps
│ │ ├─ README
│ │ ├─ Reporting and NEL
│ │ ├─ Reporting and NEL-journal
│ │ ├─ Safe Browsing Cookies
│ │ ├─ Safe Browsing Cookies-journal
│ │ ├─ Secure Preferences
│ │ ├─ ServerCertificate
│ │ ├─ ServerCertificate-journal
│ │ ├─ SharedStorage
│ │ ├─ Shortcuts
│ │ ├─ Shortcuts-journal
│ │ ├─ Top Sites
│ │ ├─ Top Sites-journal
│ │ ├─ TransportSecurity
│ │ ├─ Trust Tokens
│ │ ├─ Trust Tokens-journal
│ │ ├─ trusted_vault.pb
│ │ ├─ Web Data
│ │ └─ Web Data-journal
│ ├─ dartpad/
│ │ └─ web_plugin_registrant.dart
│ ├─ extension_discovery/
│ │ ├─ README.md
│ │ └─ vs_code.json
│ ├─ package_config.json
│ ├─ package_graph.json
│ └─ version
├─ android/
│ ├─ .gradle/
│ │ ├─ 8.12/
│ │ │ ├─ checksums/
│ │ │ │ ├─ checksums.lock
│ │ │ │ ├─ md5-checksums.bin
│ │ │ │ └─ sha1-checksums.bin
│ │ │ ├─ executionHistory/
│ │ │ │ └─ executionHistory.lock
│ │ │ ├─ expanded/
│ │ │ ├─ fileChanges/
│ │ │ │ └─ last-build.bin
│ │ │ ├─ fileHashes/
│ │ │ │ ├─ fileHashes.bin
│ │ │ │ ├─ fileHashes.lock
│ │ │ │ └─ resourceHashesCache.bin
│ │ │ ├─ vcsMetadata/
│ │ │ └─ gc.properties
│ │ ├─ buildOutputCleanup/
│ │ │ ├─ buildOutputCleanup.lock
│ │ │ └─ cache.properties
│ │ ├─ nb-cache/
│ │ │ └─ trust/
│ │ │ ├─ 5F175AF1D2CB7E95CC67781243C44A723BA33E1864437389375AC53AF65F697D
│ │ │ ├─ 9A5E9C158109811CEED45F5301C5FF74694C075280791A00B8EBD15B3850B16C
│ │ │ ├─ BD9F29329EEEE8053788D759FBF1FE5EDA66B6F42892DEA7EAC5CE9B5BF48234
│ │ │ └─ CC6CB41D54A0D49E0283C04F6E50543B536DED3D906EC2C90294245637986037
│ │ ├─ noVersion/
│ │ │ └─ buildLogic.lock
│ │ └─ vcs-1/
│ │ └─ gc.properties
│ ├─ app/
│ │ ├─ src/
│ │ │ ├─ debug/
│ │ │ │ └─ AndroidManifest.xml
│ │ │ ├─ main/
│ │ │ │ ├─ java/
│ │ │ │ │ └─ io/
│ │ │ │ │ └─ flutter/
│ │ │ │ │ └─ plugins/
│ │ │ │ │ └─ GeneratedPluginRegistrant.java
│ │ │ │ ├─ kotlin/
│ │ │ │ │ └─ com/
│ │ │ │ │ └─ example/
│ │ │ │ │ └─ pi_metro_2025_2/
│ │ │ │ │ └─ MainActivity.kt
│ │ │ │ ├─ res/
│ │ │ │ │ ├─ drawable/
│ │ │ │ │ │ └─ launch_background.xml
│ │ │ │ │ ├─ drawable-v21/
│ │ │ │ │ │ └─ launch_background.xml
│ │ │ │ │ ├─ mipmap-hdpi/
│ │ │ │ │ │ └─ ic_launcher.png
│ │ │ │ │ ├─ mipmap-mdpi/
│ │ │ │ │ │ └─ ic_launcher.png
│ │ │ │ │ ├─ mipmap-xhdpi/
│ │ │ │ │ │ └─ ic_launcher.png
│ │ │ │ │ ├─ mipmap-xxhdpi/
│ │ │ │ │ │ └─ ic_launcher.png
│ │ │ │ │ ├─ mipmap-xxxhdpi/
│ │ │ │ │ │ └─ ic_launcher.png
│ │ │ │ │ ├─ values/
│ │ │ │ │ │ └─ styles.xml
│ │ │ │ │ └─ values-night/
│ │ │ │ │ └─ styles.xml
│ │ │ │ └─ AndroidManifest.xml
│ │ │ └─ profile/
│ │ │ └─ AndroidManifest.xml
│ │ └─ build.gradle.kts
│ ├─ gradle/
│ │ └─ wrapper/
│ │ └─ gradle-wrapper.properties
│ ├─ .gitignore
│ ├─ build.gradle.kts
│ ├─ gradle.properties
│ ├─ local.properties
│ └─ settings.gradle.kts
├─ api/
│ ├─ scripts/
│ │ └─ hash.js
│ ├─ src/
│ │ ├─ middlewares/
│ │ │ └─ auth.js
│ │ ├─ routes/
│ │ │ ├─ auth.routes.js
│ │ │ ├─ itens.routes.js
│ │ │ ├─ movimentos.routes.js
│ │ │ └─ usuarios.routes.js
│ │ ├─ config.js
│ │ ├─ db.js
│ │ ├─ index.js
│ │ └─ indexes.js
│ ├─ .env
│ ├─ package-lock.json
│ └─ package.json
├─ assets/
│ └─ LogoMetro.png
├─ build/
│ ├─ 8dc760c27b6e2935e50454102b6fa53d/
│ │ ├─ \_composite.stamp
│ │ ├─ gen_dart_plugin_registrant.stamp
│ │ └─ gen_localizations.stamp
│ ├─ flutter_assets/
│ │ ├─ assets/
│ │ │ └─ LogoMetro.png
│ │ ├─ fonts/
│ │ │ └─ MaterialIcons-Regular.otf
│ │ ├─ packages/
│ │ │ └─ cupertino_icons/
│ │ │ └─ assets/
│ │ │ └─ CupertinoIcons.ttf
│ │ ├─ shaders/
│ │ │ └─ ink_sparkle.frag
│ │ ├─ AssetManifest.bin
│ │ ├─ AssetManifest.bin.json
│ │ ├─ AssetManifest.json
│ │ ├─ FontManifest.json
│ │ └─ NOTICES
│ ├─ reports/
│ │ └─ problems/
│ │ └─ problems-report.html
│ └─ 210bad4901163cba762d02a4a1c86c00.cache.dill.track.dill
├─ ios/
│ ├─ Flutter/
│ │ ├─ ephemeral/
│ │ │ ├─ flutter_lldb_helper.py
│ │ │ └─ flutter_lldbinit
│ │ ├─ AppFrameworkInfo.plist
│ │ ├─ Debug.xcconfig
│ │ ├─ flutter_export_environment.sh
│ │ ├─ Generated.xcconfig
│ │ └─ Release.xcconfig
│ ├─ Runner/
│ │ ├─ Assets.xcassets/
│ │ │ ├─ AppIcon.appiconset/
│ │ │ │ ├─ Contents.json
│ │ │ │ ├─ Icon-App-1024x1024@1x.png
│ │ │ │ ├─ Icon-App-20x20@1x.png
│ │ │ │ ├─ Icon-App-20x20@2x.png
│ │ │ │ ├─ Icon-App-20x20@3x.png
│ │ │ │ ├─ Icon-App-29x29@1x.png
│ │ │ │ ├─ Icon-App-29x29@2x.png
│ │ │ │ ├─ Icon-App-29x29@3x.png
│ │ │ │ ├─ Icon-App-40x40@1x.png
│ │ │ │ ├─ Icon-App-40x40@2x.png
│ │ │ │ ├─ Icon-App-40x40@3x.png
│ │ │ │ ├─ Icon-App-60x60@2x.png
│ │ │ │ ├─ Icon-App-60x60@3x.png
│ │ │ │ ├─ Icon-App-76x76@1x.png
│ │ │ │ ├─ Icon-App-76x76@2x.png
│ │ │ │ └─ Icon-App-83.5x83.5@2x.png
│ │ │ └─ LaunchImage.imageset/
│ │ │ ├─ Contents.json
│ │ │ ├─ LaunchImage.png
│ │ │ ├─ LaunchImage@2x.png
│ │ │ ├─ LaunchImage@3x.png
│ │ │ └─ README.md
│ │ ├─ Base.lproj/
│ │ │ ├─ LaunchScreen.storyboard
│ │ │ └─ Main.storyboard
│ │ ├─ AppDelegate.swift
│ │ ├─ GeneratedPluginRegistrant.h
│ │ ├─ GeneratedPluginRegistrant.m
│ │ ├─ Info.plist
│ │ └─ Runner-Bridging-Header.h
│ ├─ Runner.xcodeproj/
│ │ ├─ project.xcworkspace/
│ │ │ ├─ xcshareddata/
│ │ │ │ ├─ IDEWorkspaceChecks.plist
│ │ │ │ └─ WorkspaceSettings.xcsettings
│ │ │ └─ contents.xcworkspacedata
│ │ ├─ xcshareddata/
│ │ │ └─ xcschemes/
│ │ │ └─ Runner.xcscheme
│ │ └─ project.pbxproj
│ ├─ Runner.xcworkspace/
│ │ ├─ xcshareddata/
│ │ │ ├─ IDEWorkspaceChecks.plist
│ │ │ └─ WorkspaceSettings.xcsettings
│ │ └─ contents.xcworkspacedata
│ ├─ RunnerTests/
│ │ └─ RunnerTests.swift
│ └─ .gitignore
├─ lib/
│ ├─ screens/
│ │ ├─ home/
│ │ │ ├─ calendar_page.dart
│ │ │ ├─ estoque_page.dart
│ │ │ ├─ home_screen.dart
│ │ │ ├─ info_page.dart
│ │ │ ├─ people_page.dart
│ │ │ ├─ settings_page.dart
│ │ │ └─ tool_page.dart
│ │ └─ login/
│ │ ├─ cadastro_popup.dart
│ │ ├─ esqueceuasenha_popup.dart
│ │ ├─ login_controller.dart
│ │ └─ login_screen.dart
│ ├─ services/
│ │ └─ auth_service.dart
│ └─ main.dart
├─ linux/
│ ├─ .dart_tool/
│ │ ├─ package_config.json
│ │ ├─ package_graph.json
│ │ └─ version
│ ├─ flutter/
│ │ ├─ ephemeral/
│ │ │ └─ .plugin_symlinks/
│ │ │ ├─ flutter_secure_storage_linux
│ │ │ └─ path_provider_linux
│ │ ├─ CMakeLists.txt
│ │ ├─ generated_plugin_registrant.cc
│ │ ├─ generated_plugin_registrant.h
│ │ └─ generated_plugins.cmake
│ ├─ runner/
│ │ ├─ CMakeLists.txt
│ │ ├─ main.cc
│ │ ├─ my_application.cc
│ │ └─ my_application.h
│ ├─ .gitignore
│ ├─ CMakeLists.txt
│ └─ pubspec.lock
├─ macos/
│ ├─ Flutter/
│ │ ├─ ephemeral/
│ │ │ ├─ flutter_export_environment.sh
│ │ │ └─ Flutter-Generated.xcconfig
│ │ ├─ Flutter-Debug.xcconfig
│ │ ├─ Flutter-Release.xcconfig
│ │ └─ GeneratedPluginRegistrant.swift
│ ├─ Runner/
│ │ ├─ Assets.xcassets/
│ │ │ └─ AppIcon.appiconset/
│ │ │ ├─ app_icon_1024.png
│ │ │ ├─ app_icon_128.png
│ │ │ ├─ app_icon_16.png
│ │ │ ├─ app_icon_256.png
│ │ │ ├─ app_icon_32.png
│ │ │ ├─ app_icon_512.png
│ │ │ ├─ app_icon_64.png
│ │ │ └─ Contents.json
│ │ ├─ Base.lproj/
│ │ │ └─ MainMenu.xib
│ │ ├─ Configs/
│ │ │ ├─ AppInfo.xcconfig
│ │ │ ├─ Debug.xcconfig
│ │ │ ├─ Release.xcconfig
│ │ │ └─ Warnings.xcconfig
│ │ ├─ AppDelegate.swift
│ │ ├─ DebugProfile.entitlements
│ │ ├─ Info.plist
│ │ ├─ MainFlutterWindow.swift
│ │ └─ Release.entitlements
│ ├─ Runner.xcodeproj/
│ │ ├─ project.xcworkspace/
│ │ │ └─ xcshareddata/
│ │ │ └─ IDEWorkspaceChecks.plist
│ │ ├─ xcshareddata/
│ │ │ └─ xcschemes/
│ │ │ └─ Runner.xcscheme
│ │ └─ project.pbxproj
│ ├─ Runner.xcworkspace/
│ │ ├─ xcshareddata/
│ │ │ └─ IDEWorkspaceChecks.plist
│ │ └─ contents.xcworkspacedata
│ ├─ RunnerTests/
│ │ └─ RunnerTests.swift
│ └─ .gitignore
├─ test/
│ └─ widget_test.dart
├─ web/
│ ├─ icons/
│ │ ├─ Icon-192.png
│ │ ├─ Icon-512.png
│ │ ├─ Icon-maskable-192.png
│ │ └─ Icon-maskable-512.png
│ ├─ favicon.png
│ ├─ index.html
│ └─ manifest.json
├─ windows/
│ ├─ flutter/
│ │ ├─ ephemeral/
│ │ │ └─ .plugin_symlinks/
│ │ │ ├─ flutter_secure_storage_windows
│ │ │ └─ path_provider_windows
│ │ ├─ CMakeLists.txt
│ │ ├─ generated_plugin_registrant.cc
│ │ ├─ generated_plugin_registrant.h
│ │ └─ generated_plugins.cmake
│ ├─ runner/
│ │ ├─ resources/
│ │ │ └─ app_icon.ico
│ │ ├─ CMakeLists.txt
│ │ ├─ flutter_window.cpp
│ │ ├─ flutter_window.h
│ │ ├─ main.cpp
│ │ ├─ resource.h
│ │ ├─ runner.exe.manifest
│ │ ├─ Runner.rc
│ │ ├─ utils.cpp
│ │ ├─ utils.h
│ │ ├─ win32_window.cpp
│ │ └─ win32_window.h
│ ├─ .gitignore
│ └─ CMakeLists.txt
├─ .flutter-plugins-dependencies
├─ .gitignore
├─ .metadata
├─ analysis_options.yaml
├─ package-lock.json
├─ pubspec.lock
├─ pubspec.yaml
└─ README.md
```
---

## Linguagens e tecnologias

- Front-end: Flutter (Dart)
  - Flutter Secure Storage, Material 3, navegação com Navigator
- Back-end: Node.js (ES Modules) + Express 5
  - mongodb (driver oficial), bcryptjs, jsonwebtoken, dotenv, cors
- Banco de dados: MongoDB (Atlas ou local)
- Plataforma: macOS/Linux/Windows, iOS/Android/Web/Desktop

---

## Principais partes do código (back-end)

- api/src/index.js: inicialização do servidor Express, conexão com DB, montagem das rotas e health check
- api/src/config.js: leitura das variáveis de ambiente (MONGODB_URI, MONGODB_DB, JWT_SECRET, BCRYPT_ROUNDS)
- api/src/db.js: conexão com MongoDB e helpers (getDB, getClient)
- api/src/indexes.js: criação de índices (usuarios/email único, instrumentos/codigoInterno, etc.) na inicialização
- api/src/middlewares/auth.js: autenticação via JWT e guardas de role (requireRole)
- api/src/routes/
  - auth.routes.js: POST /auth/login (gera JWT com expiração, compara senha com bcrypt)
  - itens.routes.js: CRUD básico de itens, buscar por código, alertas de calibração
  - movimentos.routes.js: registro de retirada/devolução por itemId ou por código; evita saldo negativo
  - usuarios.routes.js: CRUD de usuários com regras por perfil (admin, gestor, tecnico)
- api/scripts/hash.js: gera hash bcrypt para popular senhaHash na base

## Principais partes do código (front-end)

- lib/main.dart: setup da aplicação (tema, rotas iniciais)
- lib/services/auth_service.dart: login/logout, armazenamento seguro de token e dados do usuário
- lib/screens/login/login_screen.dart: tela de login
- lib/screens/home/home_screen.dart: shell principal com menu lateral, botão Sair com limpeza de sessão e navegação para Login
- lib/screens/home/\*: páginas dummy (estoque, pessoas, ferramentas, etc.)

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

## Observações e dicas

- Se o script de hash falhar quando executado da raiz, rode dentro de api/.
- Se o login falhar, verifique JWT_SECRET no .env e os usuários no MongoDB.
- Movimentos e itens exigem autenticação via Bearer Token (JWT) retornado em /auth/login.
- Indíces de movimentos recomendados (no MongoDB): { itemId: 1, dataHora: -1 } e { codigoInterno: 1, dataHora: -1 }.
