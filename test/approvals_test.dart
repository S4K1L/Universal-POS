import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbin/core/i18n/lang.dart';
import 'package:orbin/features/admin/admin_approvals_screen.dart';

import 'support/harness.dart';

Map<String, dynamic> _request(String id, String name, {String status = 'pending', String type = 'Cosmetic Shop', String reason = '', String plan = ''}) => {
      'id': id, 'phone': '01712345678', 'business_name': name, 'business_type_key': 'cosmetic', 'business_type_label': type, 'language': 'bn',
      'status': status, 'reject_reason': reason, 'plan_key': plan, 'reviewed_by_name': status == 'pending' ? '' : 'Platform Admin',
      'reviewed_at': null, 'created_at': '2026-11-08T09:30:00+00:00', 'tenant_id': null,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();

  Map<String, Handler> routes(List<dynamic> posts, {List<Map<String, dynamic>>? pending}) => {
        'GET /admin/signups': (o) {
          final status = o.queryParameters['status'];
          final waiting = pending ?? [_request('r1', 'Rina Cosmetics'), _request('r2', 'Karim Traders', type: 'Local Shop')];
          return {
            'items': status == 'pending' ? waiting : (status == 'rejected' ? [_request('r9', 'Old Request', status: 'rejected', reason: 'Details are incomplete')] : []),
            'counts': {'pending': waiting.length, 'approved': 0, 'rejected': 1},
          };
        },
        'GET /admin/plans': (_) => fx['admin_plans'],
        'POST /admin/signups/r1/approve': (o) {
          posts.add(('approve', o.data));
          return _request('r1', 'Rina Cosmetics', status: 'approved', plan: 'business');
        },
        'POST /admin/signups/r1/reject': (o) {
          posts.add(('reject', o.data));
          return _request('r1', 'Rina Cosmetics', status: 'rejected');
        },
      };

  for (final (name, size) in [('phone', phone), ('tablet', tablet), ('desktop', desktop)]) {
    testWidgets('approvals lists the waiting requests with their details ($name)', (tester) async {
      await pumpScreen(tester, const AdminApprovalsScreen(), size: size, admin: true, routes: routes([]));
      await settle(tester);
      expect(find.text('Rina Cosmetics'), findsOneWidget);
      expect(find.text('Karim Traders'), findsOneWidget);
      expect(find.text('Cosmetic Shop'), findsOneWidget);
      expect(find.text('Approve and assign package'), findsNWidgets(2));
      expectNoError(tester);
    });
  }

  testWidgets('approving assigns the chosen package, cycle and trial', (tester) async {
    final posts = <dynamic>[];
    await pumpScreen(tester, const AdminApprovalsScreen(), admin: true, routes: routes(posts));
    await settle(tester);
    await tester.tap(find.text('Approve and assign package').first);
    await settle(tester, frames: 6);

    // no package chosen yet → refuses
    await tester.tap(find.text('Approve and open business'));
    await settle(tester, frames: 3);
    expect(find.text('Choose the package to assign.'), findsOneWidget);
    expect(posts, isEmpty);

    await tester.tap(find.text('Business').first);
    await settle(tester, frames: 3);
    await tester.tap(find.text('Yearly'));
    await tester.enterText(find.widgetWithText(TextField, 'Free trial (days)'), '30');
    await tester.tap(find.text('Approve and open business'));
    await settle(tester, frames: 6);

    expect(posts, hasLength(1));
    final body = (posts.single as (String, dynamic)).$2 as Map;
    expect(body['plan_key'], 'business');
    expect(body['billing_cycle'], 'yearly');
    expect(body['trial_days'], 30);
    expect(body['sample_data'], false);
    expect(find.text('Approved — the business is open'), findsOneWidget);
    expectNoError(tester);
  });

  testWidgets('declining sends the reason the applicant will read', (tester) async {
    final posts = <dynamic>[];
    await pumpScreen(tester, const AdminApprovalsScreen(), admin: true, routes: routes(posts));
    await settle(tester);
    await tester.tap(find.text('Decline').first);
    await settle(tester, frames: 6);
    await tester.tap(find.widgetWithText(ActionChip, 'Details are incomplete')); // a quick reason
    await tester.pump();
    await tester.tap(find.text('Decline').last);
    await settle(tester, frames: 6);
    expect(((posts.single as (String, dynamic)).$2 as Map)['reason'], 'Details are incomplete');
    expectNoError(tester);
  });

  testWidgets('the declined tab shows the reason that was given', (tester) async {
    await pumpScreen(tester, const AdminApprovalsScreen(), admin: true, routes: routes([]));
    await settle(tester);
    await tester.tap(find.text('Declined'));
    await settle(tester);
    expect(find.text('Old Request'), findsOneWidget);
    expect(find.text('Details are incomplete'), findsOneWidget);
    expect(find.text('Approve and assign package'), findsNothing);
  });

  testWidgets('an empty queue says so', (tester) async {
    await pumpScreen(tester, const AdminApprovalsScreen(), admin: true, routes: routes([], pending: []));
    await settle(tester);
    expect(find.text('No requests waiting'), findsOneWidget);
  });

  testWidgets('the console badge counts what is waiting', (tester) async {
    final rig = await pumpScreen(tester, const SizedBox(), admin: true, routes: routes([]));
    expect(rig.container.read(pendingApprovalsProvider), 0);
    await settle(tester, frames: 4);
    expect(rig.container.read(pendingApprovalsProvider), 2);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('approvals and the approve panel fit a phone in Bangla', (tester) async {
    await pumpScreen(tester, const AdminApprovalsScreen(), size: phone, admin: true, lang: AppLang.bn, routes: routes([]));
    await settle(tester);
    expectNoError(tester);
    await tester.tap(find.text('অনুমোদন করে প্যাকেজ দিন').first);
    await settle(tester, frames: 6);
    expect(find.text('অনুমোদন করে ব্যবসা চালু করুন'), findsOneWidget);
    expectNoError(tester);
  });
}
