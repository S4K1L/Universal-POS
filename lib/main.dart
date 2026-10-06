import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/api/api_client.dart';
import 'core/i18n/lang.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SecureStore.instance;
  final server = await store.read('server_url') ?? ServerConfig.fallback;
  final langName = await store.read('lang');
  final themeName = await store.read('theme');
  runApp(ProviderScope(
    overrides: [
      bootstrapProvider.overrideWithValue(Bootstrap(
        serverUrl: server,
        access: await store.read('access'),
        refresh: await store.read('refresh'),
        lang: langName == null ? AppLang.en : AppLang.values.firstWhere((l) => l.name == langName, orElse: () => AppLang.en),
        themeMode: ThemeMode.values.firstWhere((m) => m.name == themeName, orElse: () => ThemeMode.system),
      )),
    ],
    child: const UniversalPosApp(),
  ));
}
