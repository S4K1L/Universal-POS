import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../../core/money/pricing.dart';
import '../../data/local/database.dart';
import '../../data/models/cart.dart';
import '../../data/providers.dart';
import '../../data/repos/catalogue_repo.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';

/// Why an add/increase was refused (so the screen can say something useful).
class CartRefusal {
  const CartRefusal(this.message, {this.availableMilli});
  final String message;
  final int? availableMilli;
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Add a product (one variant of it). Returns a refusal if the shelf can't cover it and the business doesn't
  /// allow selling below zero.
  Future<CartRefusal?> add(ProductView pv, LVariant v, {int qtyMilli = 1000, String? unit}) async {
    final ctx = ref.read(sessionProvider).ctx!;
    final rates = await ref.read(catalogueRepoProvider).taxRates();
    final alt = pv.altUnits;
    final u = unit ?? pv.product.baseUnit;
    final factor = u == pv.product.baseUnit ? 1000 : (alt.where((a) => a.unit == u).firstOrNull?.factorMilli ?? 1000);
    final avail = pv.availableOf(v);
    final rate = ctx.cap('item_tax') && pv.product.taxClassId != null ? (rates[pv.product.taxClassId] ?? 0) : 0;
    final idx = state.lines.indexWhere((l) => l.variantId == v.id && l.unit == u && !l.overridden && l.note.isEmpty);

    final currentBase = state.lines.where((l) => l.variantId == v.id).fold<int>(0, (a, l) => a + l.baseQtyMilli);
    final addBase = qtyMilli * factor ~/ 1000;
    if (pv.stocked && !ctx.allowNegativeStock && currentBase + addBase > avail) {
      return CartRefusal(avail <= 0 ? 'Out of stock' : 'Only ${milliToWire(avail).replaceAll(RegExp(r'\.?0+$'), '')} left', availableMilli: avail);
    }

    if (idx >= 0) {
      final l = state.lines[idx];
      final lines = [...state.lines];
      lines[idx] = l.copyWith(qtyMilli: l.qtyMilli + qtyMilli, availableBaseMilli: avail);
      state = state.copyWith(lines: lines);
    } else {
      final line = CartLine(
        key: newId(),
        variantId: v.id,
        productId: pv.product.id,
        name: pv.product.name,
        nameLocal: pv.product.nameLocal,
        variantLabel: v.label,
        sku: v.sku,
        baseUnit: pv.product.baseUnit,
        allowFraction: pv.product.allowFraction,
        unit: u,
        unitFactorMilli: factor,
        qtyMilli: qtyMilli,
        baseListPriceP: v.priceP,
        taxRateBp: rate,
        altUnits: alt,
        warrantyMonths: pv.product.warrantyMonths,
        stocked: pv.stocked,
        availableBaseMilli: avail,
      );
      state = state.copyWith(lines: [...state.lines, line]);
    }
    return null;
  }

  CartRefusal? setQty(String key, int qtyMilli) {
    final ctx = ref.read(sessionProvider).ctx!;
    final i = state.lines.indexWhere((l) => l.key == key);
    if (i < 0) return null;
    if (qtyMilli <= 0) {
      remove(key);
      return null;
    }
    final l = state.lines[i];
    if (l.stocked && !ctx.allowNegativeStock) {
      final others = state.lines.where((x) => x.variantId == l.variantId && x.key != key).fold<int>(0, (a, x) => a + x.baseQtyMilli);
      if (others + qtyMilli * l.unitFactorMilli ~/ 1000 > l.availableBaseMilli) {
        final max = (l.availableBaseMilli - others) * 1000 ~/ l.unitFactorMilli;
        return CartRefusal(max <= 0 ? 'Out of stock' : 'Only ${milliToWire(max).replaceAll(RegExp(r'\.?0+$'), '')} left', availableMilli: max);
      }
    }
    final lines = [...state.lines];
    lines[i] = l.copyWith(qtyMilli: qtyMilli);
    state = state.copyWith(lines: lines);
    return null;
  }

  CartRefusal? step(String key, int deltaMilli) {
    final l = state.lines.firstWhere((x) => x.key == key);
    return setQty(key, l.qtyMilli + deltaMilli);
  }

  void remove(String key) => state = state.copyWith(lines: state.lines.where((l) => l.key != key).toList());

  void setUnit(String key, String unit, int factorMilli) {
    final i = state.lines.indexWhere((l) => l.key == key);
    if (i < 0) return;
    final lines = [...state.lines];
    lines[i] = lines[i].copyWith(unit: unit, unitFactorMilli: factorMilli, clearOverride: true);
    state = state.copyWith(lines: lines);
  }

  void setPrice(String key, int? paisa) {
    final i = state.lines.indexWhere((l) => l.key == key);
    if (i < 0) return;
    final lines = [...state.lines];
    lines[i] = paisa == null ? lines[i].copyWith(clearOverride: true) : lines[i].copyWith(priceOverrideP: paisa);
    state = state.copyWith(lines: lines);
  }

  void setLineDiscount(String key, int paisa) {
    final i = state.lines.indexWhere((l) => l.key == key);
    if (i < 0) return;
    final lines = [...state.lines];
    lines[i] = lines[i].copyWith(discountP: paisa < 0 ? 0 : paisa);
    state = state.copyWith(lines: lines);
  }

  void setLineNote(String key, String note) {
    final i = state.lines.indexWhere((l) => l.key == key);
    if (i < 0) return;
    final lines = [...state.lines];
    lines[i] = lines[i].copyWith(note: note);
    state = state.copyWith(lines: lines);
  }

  void setBillDiscount(int paisa) => state = state.copyWith(billDiscountP: paisa < 0 ? 0 : paisa);
  void setCustomer(CartCustomer? c) => state = c == null ? state.copyWith(clearCustomer: true) : state.copyWith(customer: c);
  void setNote(String note) => state = state.copyWith(note: note);
  void clear() => state = const CartState();

  // --------------------------------------------------------------------------------- held carts

  Future<void> hold({String? name}) async {
    if (state.isEmpty) return;
    final db = ref.read(dbProvider);
    final id = state.heldId ?? newId();
    final label = name ?? (state.customer?.name ?? '${state.lines.length} item${state.lines.length == 1 ? '' : 's'}');
    await db.into(db.heldCarts).insertOnConflictUpdate(HeldCartsCompanion.insert(id: id, name: label, json: jsonEncode(state.toJson()), createdAt: DateTime.now()));
    clear();
  }

  Future<void> resume(String id) async {
    final db = ref.read(dbProvider);
    final row = await (db.select(db.heldCarts)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    if (!state.isEmpty) await hold();
    final loaded = CartState.fromJson(jsonDecode(row.json) as Map<String, dynamic>);
    state = loaded.copyWith(heldId: id);
    await (db.delete(db.heldCarts)..where((t) => t.id.equals(id))).go();
  }

  Future<void> discardHeld(String id) async {
    final db = ref.read(dbProvider);
    await (db.delete(db.heldCarts)..where((t) => t.id.equals(id))).go();
  }
}

final cartProvider = NotifierProvider<CartController, CartState>(CartController.new);

final pricedCartProvider = Provider<PricedCart>((ref) {
  final cart = ref.watch(cartProvider);
  final ctx = ref.watch(sessionProvider.select((s) => s.ctx));
  if (ctx == null) return PricedCart.empty;
  return priceCart([for (final l in cart.lines) l.input], billDiscount: cart.billDiscountP, taxMode: ctx.taxMode, cashRounding: ctx.cashRounding);
});

final heldCartsProvider = StreamProvider<List<HeldCart>>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.heldCarts)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
});
