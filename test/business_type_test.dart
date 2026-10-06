import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/features/shell/shell.dart';

import 'support/harness.dart';

/// The business type is a data template: the till's navigation and terminology follow it, with no branching on names.
void main() {
  final fx = Fixtures.load();
  List<String> nav(String type) => navFor(fx.context(type)).where((e) => e.lockedReason == null).map((e) => e.id).toList();

  test('a local shop never sees quotations or shifts; a furniture showroom does', () {
    final local = nav('local_shop');
    expect(local, containsAll(['pos', 'products', 'customers']));
    expect(local, isNot(contains('orders')));
    expect(local, isNot(contains('shifts')));

    final furniture = nav('furniture');
    expect(furniture, contains('orders'));
  });

  test('the same screen speaks each business’s own words', () {
    expect(fx.context('pharmacy').term('customer', 'Customer'), 'Patient');
    expect(fx.context('pharmacy').term('product', 'Product'), 'Medicine');
    expect(fx.context('furniture').term('customer', 'Customer'), 'Client');
    expect(fx.context('supershop').term('customer', 'Customer'), 'Member');
    expect(fx.context('local_shop').term('due', 'Due'), 'Baki');
  });

  test('capabilities differ by type', () {
    bool has(String type, String cap) => fx.context(type).capabilities.contains(cap);
    expect(has('pharmacy', 'expiry_tracking') || has('pharmacy', 'batch_tracking'), isTrue);
    expect(has('furniture', 'document_flow'), isTrue);
    expect(has('local_shop', 'document_flow'), isFalse);
    expect(has('local_shop', 'customer_credit'), isTrue);
  });
}
