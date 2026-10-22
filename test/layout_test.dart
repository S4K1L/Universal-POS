import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/ui/kit.dart';

import 'support/harness.dart';

/// Shared layout pieces that every screen leans on: label/value rows and equal-height card rows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  testWidgets('KV puts the label at the left edge and the value flush against the right edge', (tester) async {
    await pumpScreen(tester, const Align(alignment: Alignment.topLeft, child: SizedBox(width: 480, child: KV('Retail value', '৳18,161'))), size: desktop);
    await tester.pump();
    final row = tester.getRect(find.byType(KV));
    final value = tester.getRect(find.text('৳18,161'));
    final label = tester.getRect(find.text('Retail value'));
    expect(value.right, closeTo(row.right, 0.5));
    expect(label.left, closeTo(row.left, 0.5));
    expect(value.left, greaterThan(row.center.dx), reason: 'the value must not start in the middle of the row');
    expectNoError(tester);
  });

  testWidgets('cards in a CardGrid row stretch to the tallest one and keep one width', (tester) async {
    await pumpScreen(
      tester,
      const SingleChildScrollView(
        child: CardGrid(children: [
          Surface(child: SizedBox(height: 40, child: Text('short'))),
          Surface(child: SizedBox(height: 160, child: Text('tall'))),
          Surface(child: SizedBox(height: 40, child: Text('alone'))),
        ]),
      ),
      size: desktop,
    );
    await tester.pump();
    final cards = tester.widgetList<Surface>(find.byType(Surface)).toList();
    expect(cards, hasLength(3));
    final rects = [for (var i = 0; i < 3; i++) tester.getRect(find.byType(Surface).at(i))];
    expect(rects[0].height, closeTo(rects[1].height, 0.5), reason: 'the short card stretches to its row-mate');
    expect(rects[2].width, closeTo(rects[0].width, 0.5), reason: 'a lone card in the last row keeps the column width');
    expect(rects[2].top, greaterThan(rects[0].bottom));
    expectNoError(tester);
  });

  testWidgets('CardGrid collapses to one column on a narrow screen', (tester) async {
    await pumpScreen(tester, const SingleChildScrollView(child: CardGrid(children: [Surface(child: Text('a')), Surface(child: Text('b'))])), size: phone);
    await tester.pump();
    expect(tester.getRect(find.byType(Surface).at(1)).top, greaterThan(tester.getRect(find.byType(Surface).at(0)).bottom));
    expectNoError(tester);
  });

  testWidgets('with fillLast a lone card in the last row takes the whole row', (tester) async {
    await pumpScreen(
      tester,
      const SingleChildScrollView(child: CardGrid(minWidth: 150, maxColumns: 3, gap: 12, fillLast: true, children: [Surface(child: Text('a')), Surface(child: Text('b')), Surface(child: Text('c'))])),
      size: phone,
    );
    await tester.pump();
    final first = tester.getRect(find.byType(Surface).at(0));
    final last = tester.getRect(find.byType(Surface).at(2));
    expect(last.top, greaterThan(first.bottom), reason: 'three tiles on a phone are two + one');
    expect(last.width, closeTo(first.width * 2 + 12, 1), reason: 'the third tile fills the row');
    expectNoError(tester);
  });
}
