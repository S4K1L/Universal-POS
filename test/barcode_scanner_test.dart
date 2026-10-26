import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/ui/barcode_scanner.dart';
import 'package:universal_pos/core/ui/kit.dart';

import 'support/harness.dart';

void main() {
  setUpAll(loadFonts);

  testWidgets('the camera button opens the scanner and a typed code reaches the search box', (tester) async {
    final controller = TextEditingController();
    final searched = <String>[];
    await pumpScreen(tester, Padding(padding: const EdgeInsets.all(16), child: AppSearchField(controller: controller, hint: 'Search stock', scannable: true, onChanged: searched.add)), size: phone);

    expect(cameraScanSupported, isTrue);
    await tester.tap(find.byIcon(Icons.qr_code_scanner_rounded));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Scan a barcode'), findsOneWidget);

    // No camera in a headless run, so the scanner offers to take the code by hand — the same path as a blocked camera.
    await tester.tap(find.text('Type the code'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, '8901234567890');
    await tester.tap(find.text('Use this code'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.text, '8901234567890');
    expect(searched, contains('8901234567890'));
    expect(find.text('Scan a barcode'), findsNothing);
  });

  testWidgets('a search box without scanning enabled has no camera button', (tester) async {
    await pumpScreen(tester, AppSearchField(controller: TextEditingController(), hint: 'Search customers'), size: phone);
    expect(find.byIcon(Icons.qr_code_scanner_rounded), findsNothing);
  });
}
