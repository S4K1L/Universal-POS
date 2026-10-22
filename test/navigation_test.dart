import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/app/router.dart';
import 'package:universal_pos/core/api/api_client.dart';
import 'package:universal_pos/core/i18n/lang.dart';
import 'package:universal_pos/core/theme/theme.dart';
import 'package:universal_pos/data/local/database.dart';
import 'package:universal_pos/data/platform_status.dart';
import 'package:universal_pos/data/providers.dart';
import 'package:universal_pos/data/session.dart';
import 'package:universal_pos/features/dashboard/dashboard_screen.dart';
import 'package:universal_pos/features/sales/sales_screen.dart';

import 'support/harness.dart';

class _QuietStatus extends PlatformStatusController {
  @override
  PlatformStatus build() => const PlatformStatus();
  @override
  Future<void> refresh() async {}
}

/// Moving between pages in the real router: every page change runs the fade-through transition without a layout error,
/// and the shell's heading follows the page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadFonts();
    PlatformStatusController.autoPoll = false;
  });
  final fx = Fixtures.load();

  testWidgets('every page change plays its transition cleanly, in both directions', (tester) async {
    tester.view.physicalSize = desktop;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final client = ApiClient(baseUrl: 'http://fake/api/v1')..adapter = FakeAdapter({...retailRoutes(fx), 'GET /reports/dashboard': (_) => fx['dashboard_supershop'], 'GET /orders': (_) => {'items': []}});
    final ctx = fx.context('supershop');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final c = ProviderContainer(overrides: [
      dbProvider.overrideWithValue(db),
      cacheWindowProvider.overrideWithValue(Duration.zero),
      bootstrapProvider.overrideWithValue(const Bootstrap(serverUrl: 'http://fake/api/v1')),
      apiProvider.overrideWithValue(client),
      sessionProvider.overrideWith(() => FixedSession(SessionState(status: AuthStatus.ready, ctx: ctx, user: (ctx.raw['user'] as Map).cast<String, dynamic>()))),
      platformStatusProvider.overrideWith(_QuietStatus.new),
    ]);
    addTearDown(c.dispose);
    final router = c.read(routerProvider);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: LangScope(
        lang: AppLang.en,
        child: MaterialApp.router(
          routerConfig: router,
          theme: buildTheme(Brightness.light),
          supportedLocales: const [Locale('en'), Locale('bn')],
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        ),
      ),
    ));
    await settle(tester, frames: 4);
    expect(find.byType(DashboardScreen), findsOneWidget);

    for (final path in ['/sales', '/dashboard', '/products', '/stock', '/customers', '/pos', '/reports', '/settings', '/dashboard']) {
      router.go(path);
      // Walk through the transition frame by frame: the outgoing page must be gone or fading, never stacked on the new one.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        expectNoError(tester);
      }
      await settle(tester, frames: 3);
      expect(router.state.matchedLocation, path);
    }
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(SalesScreen), findsNothing, reason: 'the old page is removed once the transition ends');
  });
}
