import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbin/core/ui/image_pick.dart';
import 'package:orbin/core/ui/kit.dart' show Monogram;
import 'package:orbin/core/ui/product_thumb.dart';
import 'package:orbin/features/products/product_form.dart';

import 'support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  final fx = Fixtures.load();

  Widget opener() => Consumer(builder: (context, ref, _) => Scaffold(body: Center(child: ElevatedButton(onPressed: () => showProductForm(context, ref), child: const Text('open')))));

  Future<List<dynamic>> openForm(WidgetTester tester, {PickedImage? pick, List<dynamic>? uploads}) async {
    final saved = <dynamic>[];
    await pumpScreen(tester, opener(), type: 'supershop', routes: {
      ...retailRoutes(fx),
      'POST /uploads/images': (o) {
        uploads?.add(o.data);
        return {'url': '/uploads/tenant/0123456789abcdef0123456789abcdef.png', 'bytes': 10};
      },
      'POST /products': (o) {
        saved.add(o.data);
        return {'id': 'p1'};
      },
    }, extra: [imagePickerProvider.overrideWithValue((context) async => pick)]);
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester, frames: 6);
    return saved;
  }

  Future<void> fillAndSave(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextField, 'Item name').first, 'Rose Soap');
    await tester.enterText(find.widgetWithText(TextField, 'Selling price').first, '45');
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await settle(tester, frames: 6);
  }

  testWidgets('the picture is optional: a product saves with none', (tester) async {
    final saved = await openForm(tester);
    expect(find.text('Picture (optional)'), findsOneWidget);
    expect(find.text('Add picture'), findsOneWidget);
    expect(find.text('Remove picture'), findsNothing);
    await fillAndSave(tester);
    expect(saved, hasLength(1));
    expect((saved.single as Map)['image_url'], '');
    expectNoError(tester);
  });

  testWidgets('a picked picture is uploaded, previewed, sent with the product, and can be removed', (tester) async {
    final uploads = <dynamic>[];
    final saved = await openForm(tester, pick: PickedImage(Uint8List.fromList([0x89, 0x50, 0x4e, 0x47]), 'soap.png'), uploads: uploads);
    await tester.tap(find.text('Add picture'));
    await settle(tester, frames: 6);
    expect(uploads, hasLength(1));
    expect(find.text('Change picture'), findsOneWidget);
    expect(find.text('Remove picture'), findsOneWidget);
    expect(find.byType(ProductThumb), findsWidgets);
    await fillAndSave(tester);
    expect((saved.single as Map)['image_url'], '/uploads/tenant/0123456789abcdef0123456789abcdef.png');
  });

  testWidgets('removing the picture sends an empty image', (tester) async {
    final saved = await openForm(tester, pick: PickedImage(Uint8List.fromList([1, 2, 3]), 'x.jpg'));
    await tester.tap(find.text('Add picture'));
    await settle(tester, frames: 6);
    await tester.tap(find.text('Remove picture'));
    await settle(tester, frames: 3);
    expect(find.text('Add picture'), findsOneWidget);
    await fillAndSave(tester);
    expect((saved.single as Map)['image_url'], '');
  });

  testWidgets('cancelling the picker changes nothing', (tester) async {
    final uploads = <dynamic>[];
    await openForm(tester, pick: null, uploads: uploads);
    await tester.tap(find.text('Add picture'));
    await settle(tester, frames: 4);
    expect(uploads, isEmpty);
    expect(find.text('Add picture'), findsOneWidget);
  });

  testWidgets('ProductThumb falls back to the monogram when there is no picture or it cannot load', (tester) async {
    await pumpScreen(tester, const Column(children: [
      ProductThumb(name: 'Rose Soap', size: 48),
      ProductThumb(name: 'Broken Link', imageUrl: '/uploads/x/missing.png', size: 48),
    ]));
    await settle(tester, frames: 4);
    expect(find.byType(Monogram), findsNWidgets(2));
    expectNoError(tester);
  });
}
