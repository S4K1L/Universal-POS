import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/i18n/lang.dart';
import 'local/database.dart';

/// What `main()` reads from secure storage before the first frame.
class Bootstrap {
  const Bootstrap({required this.serverUrl, this.access, this.refresh, this.lang = AppLang.en, this.themeMode = ThemeMode.system});
  final String serverUrl;
  final String? access, refresh;
  final AppLang lang;
  final ThemeMode themeMode;
}

final bootstrapProvider = Provider<Bootstrap>((ref) => throw UnimplementedError('override in main'));

/// The device database. Overridden in tests with an in-memory one.
final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

class ServerUrlController extends Notifier<String> {
  @override
  String build() => ref.read(bootstrapProvider).serverUrl;

  Future<void> set(String url) async {
    state = url;
    await SecureStore.instance.write('server_url', url);
  }
}

final serverUrlProvider = NotifierProvider<ServerUrlController, String>(ServerUrlController.new);

class LangController extends Notifier<AppLang> {
  @override
  AppLang build() => ref.read(bootstrapProvider).lang;

  Future<void> set(AppLang l) async {
    state = l;
    await SecureStore.instance.write('lang', l.name);
  }
}

final langProvider = NotifierProvider<LangController, AppLang>(LangController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(bootstrapProvider).themeMode;

  Future<void> set(ThemeMode m) async {
    state = m;
    await SecureStore.instance.write('theme', m.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
