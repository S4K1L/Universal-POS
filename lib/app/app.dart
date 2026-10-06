import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/lang.dart';
import '../core/theme/theme.dart';
import '../data/providers.dart';
import '../data/session.dart';
import 'router.dart';

class UniversalPosApp extends ConsumerWidget {
  const UniversalPosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final mode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);
    // Each business type has its own accent; the rest of the system stays constant.
    final accent = ref.watch(sessionProvider.select((s) => s.ctx?.accent));
    return LangScope(
      lang: lang,
      child: MaterialApp.router(
        title: 'Universal POS',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        themeMode: mode,
        theme: buildTheme(Brightness.light, accent: accent ?? const Color(0xFF0E9F6E)),
        darkTheme: buildTheme(Brightness.dark, accent: accent ?? const Color(0xFF0E9F6E)),
        themeAnimationDuration: const Duration(milliseconds: 250),
        locale: Locale(lang.name),
        supportedLocales: const [Locale('en'), Locale('bn')],
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      ),
    );
  }
}
