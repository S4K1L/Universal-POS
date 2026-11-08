import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbin/core/i18n/lang.dart';
import 'package:orbin/data/session.dart';
import 'package:orbin/features/admin/admin_settings_screen.dart';
import 'package:orbin/features/admin/admin_users_screen.dart';

import 'support/harness.dart';

Map<String, dynamic> _u(String id, String name, String phone, String role, {String? business, bool active = true, String? last = '2026-11-08T08:00:00+00:00'}) => {
      'id': id, 'name': name, 'phone': phone, 'email': '', 'role': role,
      'role_label': role == 'super_admin' ? 'Platform admin' : (role == 'owner' ? 'Owner' : 'Cashier'), 'active': active,
      'tenant_id': business == null ? null : 't-$id', 'tenant_name': business, 'last_login_at': last, 'created_at': '2026-11-01T08:00:00+00:00',
    };

final _everyone = [
  _u('a1', 'Platform Admin', '01700000000', 'super_admin'),
  _u('o1', 'Tanvir Ahmed', '01722000001', 'owner', business: 'Fresh Bazar Superstore'),
  _u('c1', 'Sohel Rana', '01722000003', 'cashier', business: 'Fresh Bazar Superstore'),
  _u('c2', 'Old Cashier', '01711000002', 'cashier', business: 'Rahim General Store', active: false, last: null),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  Map<String, Handler> usersRoutes(List<Map<String, dynamic>> queries) => {
        'GET /admin/users': (o) {
          queries.add(o.queryParameters);
          final group = o.queryParameters['group'];
          final q = (o.queryParameters['q'] as String?)?.toLowerCase();
          var rows = _everyone.where((u) => group == null || group == 'all' || (group == 'admin' ? u['role'] == 'super_admin' : group == 'owner' ? u['role'] == 'owner' : !['super_admin', 'owner'].contains(u['role']))).toList();
          if (q != null) rows = rows.where((u) => (u['name'] as String).toLowerCase().contains(q) || ((u['tenant_name'] as String?) ?? '').toLowerCase().contains(q)).toList();
          return {'items': rows, 'total': rows.length, 'limit': 50, 'offset': 0, 'counts': {'all': 4, 'admin': 1, 'owner': 1, 'staff': 2}};
        },
      };

  for (final (name, size) in [('phone', phone), ('tablet', tablet), ('desktop', desktop)]) {
    testWidgets('the users list shows every account with role, business and status ($name)', (tester) async {
      await pumpScreen(tester, const AdminUsersScreen(), size: size, admin: true, routes: usersRoutes([]));
      await settle(tester);
      expect(find.text('Platform Admin'), findsOneWidget);
      expect(find.text('Tanvir Ahmed'), findsOneWidget);
      expect(find.text('Sohel Rana'), findsOneWidget);
      expect(find.text('Old Cashier'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
      expect(find.text('Platform admin'), findsWidgets);
      expect(find.textContaining('Fresh Bazar Superstore'), findsWidgets);
      expect(find.textContaining('Never signed in'), findsOneWidget);
      expect(find.textContaining('4 accounts'), findsOneWidget);
      expectNoError(tester);
    });
  }

  testWidgets('filtering by group and searching ask the server', (tester) async {
    final queries = <Map<String, dynamic>>[];
    await pumpScreen(tester, const AdminUsersScreen(), admin: true, routes: usersRoutes(queries));
    await settle(tester);
    await tester.tap(find.textContaining('Business owners'));
    await settle(tester);
    expect(queries.last['group'], 'owner');
    expect(find.text('Tanvir Ahmed'), findsOneWidget);
    expect(find.text('Sohel Rana'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'rahim');
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
    expect(queries.last['q'], 'rahim');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the users list reads in Bangla on a phone', (tester) async {
    await pumpScreen(tester, const AdminUsersScreen(), size: phone, admin: true, lang: AppLang.bn, routes: usersRoutes([]));
    await settle(tester);
    expect(find.textContaining('ব্যবসার মালিক'), findsWidgets);
    expectNoError(tester);
  });

  group('platform admins in settings', () {
    final admins = [_u('a1', 'Platform Admin', '01700000000', 'super_admin'), _u('a2', 'Second Admin', '01799999999', 'super_admin'), _u('a3', 'Gone Admin', '01788888888', 'super_admin', active: false)];

    Map<String, Handler> routes(List<dynamic> calls) => {
          'GET /admin/settings': (_) => {'grace_days': {'days': 3}, 'support': {}, 'maintenance': {'enabled': false, 'message': ''}},
          'GET /admin/admins': (_) => admins,
          'POST /admin/admins': (o) {
            calls.add(('add', o.data));
            return _u('a9', 'New Admin', '01712345678', 'super_admin');
          },
          'DELETE /admin/admins/a2': (o) {
            calls.add(('remove', o.path));
            return _u('a2', 'Second Admin', '01799999999', 'super_admin', active: false);
          },
        };
    SessionController session(SessionState s) => FixedSession(const SessionState(status: AuthStatus.ready, user: {'id': 'a1', 'role': 'super_admin', 'name': 'Platform Admin'}));

    testWidgets('lists the admins, marks you, and offers removal only for others', (tester) async {
      await pumpScreen(tester, const AdminSettingsScreen(), size: desktop, admin: true, routes: routes([]), session: session);
      await settle(tester);
      expect(find.text('Platform admins'), findsOneWidget);
      expect(find.text('Second Admin'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);
      expect(find.byTooltip('Remove'), findsOneWidget, reason: 'not for yourself, not for one already removed');
      expect(find.text('Disabled'), findsOneWidget);
      expectNoError(tester);
    });

    testWidgets('adding an admin validates, then posts name, phone and password', (tester) async {
      final calls = <dynamic>[];
      await pumpScreen(tester, const AdminSettingsScreen(), size: desktop, admin: true, routes: routes(calls), session: session);
      await settle(tester);
      await tester.tap(find.text('Add admin').first);
      await settle(tester, frames: 6);
      await tester.tap(find.text('Add admin').last);
      await settle(tester, frames: 3);
      expect(find.text('Enter their name.'), findsOneWidget);
      expect(calls, isEmpty);

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'New Admin');
      await tester.enterText(find.widgetWithText(TextField, 'Phone number'), '01712345678');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'newadmin123');
      await tester.tap(find.text('Add admin').last);
      await settle(tester, frames: 6);
      final body = (calls.single as (String, dynamic)).$2 as Map;
      expect(body, {'name': 'New Admin', 'phone': '01712345678', 'password': 'newadmin123'});
      expect(find.text('Admin added — they can sign in now'), findsOneWidget);
    });

    testWidgets('removing asks first, then deletes', (tester) async {
      final calls = <dynamic>[];
      await pumpScreen(tester, const AdminSettingsScreen(), size: desktop, admin: true, routes: routes(calls), session: session);
      await settle(tester);
      await tester.tap(find.byTooltip('Remove'));
      await settle(tester, frames: 4);
      expect(find.text('Remove this admin?'), findsOneWidget);
      expect(calls, isEmpty);
      await tester.tap(find.text('Remove').last);
      await settle(tester, frames: 6);
      expect((calls.single as (String, dynamic)).$2, '/admin/admins/a2');
    });

    testWidgets('fits a phone, in Bangla too', (tester) async {
      for (final lang in [AppLang.en, AppLang.bn]) {
        await pumpScreen(tester, const AdminSettingsScreen(), size: phone, admin: true, lang: lang, routes: routes([]), session: session);
        await settle(tester);
        expectNoError(tester);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      }
    });
  });
}
