import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/money/money.dart';
import 'package:universal_pos/core/money/pricing.dart';

/// Replays the golden cases generated from the Python implementation
/// (`scripts/gen_pricing_vectors.py` in the backend repo). The till and the server must agree to the last paisa.
void main() {
  final file = File('docs/pricing_vectors.json');
  final cases = (jsonDecode(file.readAsStringSync())['cases'] as List).cast<Map<String, dynamic>>();

  test('loaded the shared vectors', () => expect(cases.length, greaterThan(200)));

  for (final c in cases) {
    test(c['name'] as String, () {
      final lines = [
        for (final l in (c['lines'] as List).cast<Map<String, dynamic>>())
          LineInput(
            unitPrice: parsePaisa(l['unit_price']),
            qtyMilli: parseMilli(l['qty']),
            discount: parsePaisa(l['discount']),
            taxRateBp: parseRateBp(l['tax_rate']),
          ),
      ];
      final cart = priceCart(
        lines,
        billDiscount: parsePaisa(c['bill_discount']),
        taxMode: c['tax_mode'] == 'exclusive' ? TaxMode.exclusive : TaxMode.inclusive,
        cashRounding: c['cash_rounding'] == 'nearest_1',
      );
      final e = c['expected'] as Map<String, dynamic>;
      expect(paisaToWire(cart.subtotal), e['subtotal']);
      expect(paisaToWire(cart.discount), e['discount']);
      expect(paisaToWire(cart.taxTotal), e['tax_total']);
      expect(paisaToWire(cart.rounding), e['rounding']);
      expect(paisaToWire(cart.total), e['total']);
      final el = (e['lines'] as List).cast<Map<String, dynamic>>();
      expect(cart.lines.length, el.length);
      for (var i = 0; i < el.length; i++) {
        expect(paisaToWire(cart.lines[i].net), el[i]['net'], reason: 'line $i net');
        expect(paisaToWire(cart.lines[i].share), el[i]['share'], reason: 'line $i share');
        expect(paisaToWire(cart.lines[i].tax), el[i]['tax'], reason: 'line $i tax');
        expect(paisaToWire(cart.lines[i].total), el[i]['total'], reason: 'line $i total');
      }
    });
  }

  group('wire parsing', () {
    test('paisa', () {
      expect(parsePaisa('12.50'), 1250);
      expect(parsePaisa('12'), 1200);
      expect(parsePaisa('-3.07'), -307);
      expect(parsePaisa('0.005'), 1); // half-up
      expect(paisaToWire(-307), '-3.07');
    });
    test('milli', () {
      expect(parseMilli('1.250'), 1250);
      expect(milliToWire(50), '0.050');
    });
  });
}
