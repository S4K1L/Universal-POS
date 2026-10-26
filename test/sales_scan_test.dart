import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/features/pos/receipt.dart';
import 'package:universal_pos/features/sales/sales_screen.dart';

import 'support/harness.dart';

void main() {
  setUpAll(loadFonts);

  final fx = Fixtures.load();
  final routes = <String, Handler>{
    'GET /sales': (_) => fx['sales_supershop'],
    'GET /sales/${fx['sale_detail']['id']}': (_) => fx['sale_detail'],
  };
  final invoice = fx['sale_detail']['invoice_no'] as String;

  Future<void> scanByTyping(WidgetTester tester, String code) async {
    await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Scan a receipt'), findsOneWidget);
    await tester.tap(find.text('Type the code')); // no camera in a headless run: the manual path
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, code);
    await tester.tap(find.text('Use this code'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('scanning a receipt opens that sale', (tester) async {
    await pumpScreen(tester, const SalesScreen(), size: phone, routes: routes);
    await tester.pump(const Duration(milliseconds: 500));
    await scanByTyping(tester, invoice);
    expect(find.byType(ReceiptView), findsOneWidget);
  });

  testWidgets('a code that matches no sale says so instead of opening anything', (tester) async {
    await pumpScreen(tester, const SalesScreen(), size: phone, routes: routes);
    await tester.pump(const Duration(milliseconds: 500));
    await scanByTyping(tester, 'INV-NOPE-000000');
    expect(find.byType(ReceiptView), findsNothing);
    expect(find.textContaining('No sale matches'), findsOneWidget);
  });

  testWidgets('the receipt carries a QR and a barcode of its invoice number', (tester) async {
    await pumpScreen(tester, const SalesScreen(), size: phone, routes: routes);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.textContaining(invoice).first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(ReceiptView), findsOneWidget);
    expect(find.textContaining(invoice), findsWidgets);
    expect(find.byWidgetPredicate((w) => w.runtimeType.toString() == 'BarcodeWidget'), findsNWidgets(2));
  });
}
