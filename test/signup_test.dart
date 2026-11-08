import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:orbin/core/api/api_client.dart';
import 'package:orbin/core/i18n/lang.dart';
import 'package:orbin/features/auth/login_screen.dart';
import 'package:orbin/features/auth/signup_pending_screen.dart';
import 'package:orbin/features/auth/signup_screen.dart';
import 'package:orbin/features/auth/signup_state.dart';

import 'support/harness.dart';

/// A session that records sign-ins instead of talking to a server.
class _Session extends FixedSession {
  _Session(super.s, {this.failWith});
  final ApiError? failWith;
  static final logins = <(String, String)>[];

  @override
  Future<void> login(String phone, String password) async {
    if (failWith != null) throw failWith!;
    logins.add((phone, password));
  }
}

class _Preset extends PendingSignupController {
  _Preset(this.value);
  final PendingSignup value;

  @override
  PendingSignup? build() => value;
}

Widget _app([String initial = '/signup']) {
  final router = GoRouter(initialLocation: initial, routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/signup/pending', builder: (_, __) => const SignupPendingScreen(pollEvery: Duration(seconds: 2))),
  ]);
  return Builder(builder: (c) => MaterialApp.router(routerConfig: router, theme: Theme.of(c), debugShowCheckedModeBanner: false));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();
  final types = fx['public_types'];

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  for (final (name, size) in [('phone', phone), ('desktop', desktop)]) {
    testWidgets('signup asks for account details, then business details, then waits for approval ($name)', (tester) async {
      final posted = <dynamic>[];
      await pumpScreen(tester, _app(), size: size, signedOut: true, routes: {
        'GET /public/business-types': (_) => types,
        'POST /auth/signup': (o) {
          posted.add(o.data);
          return {'id': 'req-1', 'status': 'pending', 'business_name': 'Rina Cosmetics', 'phone': '01712345678'};
        },
        'POST /auth/signup/status': (_) => {'id': 'req-1', 'status': 'pending', 'business_name': 'Rina Cosmetics', 'business_type_label': 'Cosmetics', 'phone': '01712345678', 'reject_reason': ''},
      });
      await settle(tester, frames: 3);

      // step 1 — nothing to continue with yet
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Business name'), findsNothing);
      await tester.tap(find.text('Continue'));
      await settle(tester, frames: 3);
      expect(find.text('Enter a Bangladesh mobile number like 01712345678'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '01712345678');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'secret1234');
      await tester.enterText(find.widgetWithText(TextField, 'Confirm password'), 'different99');
      await tester.tap(find.text('Continue'));
      await settle(tester, frames: 3);
      expect(find.text('The two passwords do not match.'), findsOneWidget);
      expect(find.text('Business name'), findsNothing);

      await tester.enterText(find.widgetWithText(TextField, 'Confirm password'), 'secret1234');
      await tester.tap(find.text('Continue'));
      await settle(tester, frames: 8);

      // step 2 — business name and type
      expect(find.text('Business name'), findsOneWidget);
      expect(find.text('What kind of business is it?'), findsOneWidget);
      await tester.ensureVisible(find.text('Send for approval'));
      await tester.tap(find.text('Send for approval'));
      await settle(tester, frames: 3);
      expect(find.text('Enter your business name.'), findsOneWidget);
      expect(posted, isEmpty, reason: 'nothing is sent until the form is complete');

      await tester.enterText(find.widgetWithText(TextField, 'Business name'), 'Rina Cosmetics');
      await tester.ensureVisible(find.text('Cosmetic Shop').first);
      await tester.tap(find.text('Cosmetic Shop').first);
      await settle(tester, frames: 4);
      await tester.ensureVisible(find.text('Send for approval'));
      await tester.tap(find.text('Send for approval'));
      await settle(tester, frames: 8);

      expect(posted, hasLength(1));
      expect((posted.single as Map)['phone'], '01712345678');
      expect((posted.single as Map)['business_name'], 'Rina Cosmetics');
      expect((posted.single as Map)['business_type_key'], 'cosmetic');

      // the waiting page
      expect(find.text('Orbin Business Management is reviewing your data'), findsOneWidget);
      expect(find.text('Under review'), findsOneWidget);
      expect(find.text('Rina Cosmetics'), findsWidgets);
      expectNoError(tester);
      await teardown(tester);
    });
  }

  testWidgets('the waiting page signs the owner in the moment the request is approved', (tester) async {
    _Session.logins.clear();
    var calls = 0;
    await pumpScreen(tester, _app('/signup/pending'), signedOut: true, routes: {
      'POST /auth/signup/status': (_) => {
            'id': 'r', 'status': ++calls < 2 ? 'pending' : 'approved', 'business_name': 'Rina Cosmetics', 'business_type_label': 'Cosmetics', 'phone': '01712345678', 'reject_reason': '',
          },
    }, session: (s) => _Session(s), extra: [
      pendingSignupProvider.overrideWith(() => _Preset(const PendingSignup(phone: '01712345678', password: 'secret1234'))),
    ]);
    await settle(tester, frames: 3);
    expect(find.text('Orbin Business Management is reviewing your data'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2)); // next poll
    await settle(tester, frames: 4);
    expect(find.text('You are approved!'), findsOneWidget);
    expect(find.text('Opening your shop…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await settle(tester, frames: 4);
    expect(_Session.logins, [('01712345678', 'secret1234')]);
    await teardown(tester);
  });

  testWidgets('a declined request shows the reason and lets the applicant correct and retry', (tester) async {
    await pumpScreen(tester, _app('/signup/pending'), signedOut: true, routes: {
      'GET /public/business-types': (_) => types,
      'POST /auth/signup/status': (_) => {
            'id': 'r', 'status': 'rejected', 'business_name': 'Rina Cosmetics', 'business_type_label': 'Cosmetics', 'phone': '01712345678', 'reject_reason': 'Please add a trade licence number',
          },
    }, extra: [pendingSignupProvider.overrideWith(() => _Preset(const PendingSignup(phone: '01712345678', password: 'secret1234', businessName: 'Rina Cosmetics')))]);
    await settle(tester, frames: 4);
    expect(find.text('We could not approve this request'), findsOneWidget);
    expect(find.text('Please add a trade licence number'), findsOneWidget);
    await tester.tap(find.text('Edit and try again'));
    await settle(tester, frames: 6);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.widgetWithText(TextField, '01712345678'), findsOneWidget, reason: 'the phone number is kept');
    await teardown(tester);
  });

  testWidgets('signing in while a request is still open lands on the waiting page', (tester) async {
    final router = GoRouter(initialLocation: '/login', routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/signup/pending', builder: (_, __) => const SignupPendingScreen(pollEvery: Duration(seconds: 30))),
    ]);
    await pumpScreen(tester, Builder(builder: (c) => MaterialApp.router(routerConfig: router, theme: Theme.of(c), debugShowCheckedModeBanner: false)), signedOut: true, routes: {
      'POST /auth/signup/status': (_) => {'id': 'r', 'status': 'pending', 'business_name': 'Rina Cosmetics', 'business_type_label': 'Cosmetics', 'phone': '01712345678', 'reject_reason': ''},
    }, session: (s) => _Session(s, failWith: ApiError(status: 403, message: 'Your request is still being reviewed', code: 'signup_pending')));
    await settle(tester, frames: 3);
    expect(find.text('Create an account'), findsOneWidget, reason: 'the login page offers signup');
    await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '01712345678');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'secret1234');
    await tester.tap(find.text('Sign in').last);
    await settle(tester, frames: 6);
    expect(find.text('Orbin Business Management is reviewing your data'), findsOneWidget);
    await teardown(tester);
  });

  testWidgets('the whole signup reads and fits in Bangla on a phone', (tester) async {
    await pumpScreen(tester, _app(), size: phone, signedOut: true, lang: AppLang.bn, routes: {'GET /public/business-types': (_) => types});
    await settle(tester, frames: 4);
    expect(find.text('আপনার অ্যাকাউন্ট খুলুন'), findsOneWidget);
    expectNoError(tester);
    await tester.enterText(find.byType(TextField).at(0), '01712345678');
    await tester.enterText(find.byType(TextField).at(1), 'secret1234');
    await tester.enterText(find.byType(TextField).at(2), 'secret1234');
    await tester.tap(find.text('চালিয়ে যান'));
    await settle(tester, frames: 8);
    expect(find.text('এটি কোন ধরনের ব্যবসা?'), findsOneWidget);
    expectNoError(tester);
    await teardown(tester);
  });

  testWidgets('the waiting page fits a phone, in English and in Bangla', (tester) async {
    for (final lang in [AppLang.en, AppLang.bn]) {
      await pumpScreen(tester, _app('/signup/pending'), size: phone, signedOut: true, lang: lang, routes: {
        'POST /auth/signup/status': (_) => {'id': 'r', 'status': 'pending', 'business_name': 'Rina Cosmetics', 'business_type_label': 'Cosmetics', 'phone': '01712345678', 'reject_reason': ''},
      }, extra: [pendingSignupProvider.overrideWith(() => _Preset(const PendingSignup(phone: '01712345678', password: 'secret1234')))]);
      await settle(tester, frames: 4);
      expectNoError(tester);
      await teardown(tester);
    }
  });
}
