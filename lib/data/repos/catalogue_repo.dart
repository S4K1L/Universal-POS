import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money.dart';
import '../local/database.dart';
import '../providers.dart';
import '../session.dart';

class AltUnit {
  const AltUnit(this.unit, this.factorMilli);
  final String unit;
  final int factorMilli; // base units per this unit, ×1000
}

/// A product with its variants and what is actually available to sell on this till right now.
class ProductView {
  ProductView(this.product, this.variants, this.available);

  final LProduct product;
  final List<LVariant> variants;

  /// variantId -> base units available (server stock at last pull, minus sales still waiting to sync), in milli.
  final Map<String, int> available;

  bool get hasVariants => variants.length > 1;
  bool get stocked => product.type == 'stockable';
  int get totalAvailable => variants.fold(0, (a, v) => a + (available[v.id] ?? 0));
  int availableOf(LVariant v) => available[v.id] ?? 0;
  int get minPrice => variants.isEmpty ? 0 : variants.map((v) => v.priceP).reduce((a, b) => a < b ? a : b);
  int get maxPrice => variants.isEmpty ? 0 : variants.map((v) => v.priceP).reduce((a, b) => a > b ? a : b);
  bool get lowStock => stocked && totalAvailable <= product.reorderMilli;
  bool get outOfStock => stocked && totalAvailable <= 0;

  List<AltUnit> get altUnits {
    final raw = (jsonDecode(product.altUnits) as List).cast<Map<String, dynamic>>();
    return [for (final a in raw) AltUnit(a['unit'] as String, parseMilli(a['factor']))];
  }

  Map<String, dynamic> get attributes => (jsonDecode(product.attributes) as Map).cast<String, dynamic>();
  String get brand => (attributes['brand'] ?? '').toString();
}

class LookupHit {
  const LookupHit(this.variantId, this.productId, {this.unit, this.qtyMilli = 1000});
  final String variantId, productId;
  final String? unit;
  final int qtyMilli;
}

class CatalogueRepo {
  CatalogueRepo(this.db, {this.branchId});
  final AppDatabase db;

  /// The branch this till sells for. Stock is counted for that branch only; null (no branch) counts them all.
  final String? Function()? branchId;
  String? get _branch => branchId?.call();

  /// SQLite caps how many values one `IN (…)` may carry, and a big catalogue exceeds it.
  static Iterable<List<T>> _chunks<T>(List<T> all, [int size = 400]) sync* {
    for (var i = 0; i < all.length; i += size) {
      yield all.sublist(i, i + size > all.length ? all.length : i + size);
    }
  }

  /// A stream that ticks whenever anything the catalogue view depends on changes.
  Stream<void> get _changes => db
      .customSelect('SELECT 1', readsFrom: {db.lProducts, db.lVariants, db.lStock, db.lBarcodes, db.outbox, db.lTaxClasses})
      .watch()
      .transform(_debounce(const Duration(milliseconds: 60)));

  Stream<List<LCategory>> watchCategories() => (db.select(db.lCategories)
        ..where((c) => c.active.equals(true))
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder), (c) => OrderingTerm.asc(c.name)]))
      .watch();

  Stream<List<LTaxClassesData>> watchTaxClasses() => db.select(db.lTaxClasses).watch();

  Future<Map<String, int>> taxRates() async => {for (final t in await db.select(db.lTaxClasses).get()) t.id: t.rateBp};

  Stream<List<ProductView>> watchProducts({String q = '', String? categoryId, int limit = 150, bool stockedOnly = false}) async* {
    yield await products(q: q, categoryId: categoryId, limit: limit, stockedOnly: stockedOnly);
    await for (final _ in _changes) {
      yield await products(q: q, categoryId: categoryId, limit: limit, stockedOnly: stockedOnly);
    }
  }

  Future<List<ProductView>> products({String q = '', String? categoryId, int limit = 150, bool stockedOnly = false}) async {
    final query = db.select(db.lProducts)..where((p) => p.active.equals(true));
    final term = q.trim().toLowerCase().replaceAll('%', '').replaceAll('_', '');
    if (term.isNotEmpty) {
      for (final w in term.split(RegExp(r'\s+'))) {
        query.where((p) => p.search.like('%$w%'));
      }
    }
    if (categoryId != null) query.where((p) => p.categoryId.equals(categoryId));
    if (stockedOnly) query.where((p) => p.type.equals('stockable'));
    query
      ..orderBy([(p) => OrderingTerm.asc(p.name)])
      ..limit(limit);
    final rows = await query.get();
    return _hydrate(rows);
  }

  Future<ProductView?> byId(String id) async {
    final row = await (db.select(db.lProducts)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (await _hydrate([row])).first;
  }

  Future<List<ProductView>> _hydrate(List<LProduct> rows) async {
    if (rows.isEmpty) return const [];
    final ids = rows.map((r) => r.id).toList();
    final variants = <LVariant>[];
    for (final chunk in _chunks(ids)) {
      variants.addAll(await _variantsOf(chunk));
    }
    variants.sort((a, b) => a.label.compareTo(b.label));
    return _viewsOf(rows, variants);
  }

  Future<List<LVariant>> _variantsOf(List<String> ids) => (db.select(db.lVariants)
        ..where((v) => v.productId.isIn(ids) & v.active.equals(true))
        ..orderBy([(v) => OrderingTerm.asc(v.label)]))
      .get();

  Future<List<ProductView>> _viewsOf(List<LProduct> rows, List<LVariant> variants) async {
    final byProduct = <String, List<LVariant>>{};
    for (final v in variants) {
      byProduct.putIfAbsent(v.productId, () => []).add(v);
    }
    final avail = await availableFor(variants.map((v) => v.id));
    return [for (final r in rows) if (byProduct[r.id]?.isNotEmpty ?? false) ProductView(r, byProduct[r.id]!, avail)];
  }

  /// This branch's stock at the last pull, adjusted for everything this till has done since that hasn't synced yet.
  Future<Map<String, int>> availableFor(Iterable<String> variantIds) async {
    final ids = variantIds.toList();
    if (ids.isEmpty) return {};
    final branch = _branch;
    final stock = <String, int>{};
    for (final chunk in _chunks(ids)) {
      final query = db.select(db.lStock)..where((s) => s.variantId.isIn(chunk));
      if (branch != null) query.where((s) => s.branchId.equals(branch));
      for (final row in await query.get()) {
        stock[row.variantId] = (stock[row.variantId] ?? 0) + row.onHandMilli;
      }
    }
    final pending = await pendingStockDeltas();
    return {for (final id in ids) id: (stock[id] ?? 0) + (pending[id] ?? 0)};
  }

  Future<Map<String, int>> pendingStockDeltas() async {
    final branch = _branch;
    final rows = await (db.select(db.outbox)..where((o) => o.status.isNotValue('done'))).get();
    final out = <String, int>{};
    void add(String variant, int milli) => out[variant] = (out[variant] ?? 0) + milli;
    bool mine(Object? eventBranch) => branch == null || eventBranch == null || eventBranch == branch; // another branch's stock is not ours to adjust
    for (final r in rows) {
      final p = jsonDecode(r.payload) as Map<String, dynamic>;
      switch (r.type) {
        case 'sale.create':
          if (!mine(p['branch_id'])) break;
          for (final l in (p['lines'] as List).cast<Map<String, dynamic>>()) {
            add(l['variant_id'] as String, -(parseMilli(l['qty']) * parseMilli(l['unit_factor'] ?? '1') ~/ 1000));
          }
        case 'stock.adjust':
          if (p['delta'] != null && mine(p['branch_id'])) add(p['variant_id'] as String, parseMilli(p['delta']));
        case 'sale.return':
          if (p['restock'] == false) break;
          final sale = await (db.select(db.lSales)..where((x) => x.id.equals(p['sale_id'] as String))).getSingleOrNull();
          if (!mine(sale?.branchId)) break;
          for (final l in (p['lines'] as List).cast<Map<String, dynamic>>()) {
            final line = await (db.select(db.lSaleLines)..where((x) => x.id.equals(l['sale_line_id'] as String))).getSingleOrNull();
            if (line != null) add(line.variantId, parseMilli(l['qty']) * line.unitFactorMilli ~/ 1000);
          }
      }
    }
    return out;
  }

  Future<LVariant?> variant(String id) => (db.select(db.lVariants)..where((v) => v.id.equals(id))).getSingleOrNull();

  /// Resolve a scanned/typed code: barcode → SKU → scale label.
  Future<LookupHit?> lookup(String raw, {String scalePrefix = '20', String scaleMode = 'weight', bool scaleEnabled = false}) async {
    final code = raw.trim();
    if (code.isEmpty) return null;
    final bc = await (db.select(db.lBarcodes)..where((b) => b.code.equals(code))).getSingleOrNull();
    if (bc != null) return LookupHit(bc.variantId, bc.productId, unit: bc.unit, qtyMilli: bc.qtyPerScanMilli);
    final bySku = await (db.select(db.lVariants)..where((v) => v.sku.equals(code) & v.active.equals(true))).getSingleOrNull();
    if (bySku != null) return LookupHit(bySku.id, bySku.productId);
    if (scaleEnabled && code.length == 13 && RegExp(r'^\d{13}$').hasMatch(code) && code.startsWith(scalePrefix)) {
      final plu = code.substring(scalePrefix.length, 7);
      final value = int.parse(code.substring(7, 12));
      final v = await (db.select(db.lVariants)..where((v) => (v.plu.equals(plu) | v.plu.equals(plu.replaceFirst(RegExp(r'^0+'), ''))) & v.active.equals(true))).getSingleOrNull();
      if (v != null) {
        final qty = scaleMode == 'weight' ? value : (v.priceP > 0 ? (value * 1000 ~/ v.priceP) : 0);
        return LookupHit(v.id, v.productId, qtyMilli: qty);
      }
    }
    return null;
  }

  Future<bool> hasCatalogue() async => (await (db.selectOnly(db.lProducts)..addColumns([db.lProducts.id.count()])).map((r) => r.read(db.lProducts.id.count())).getSingle() ?? 0) > 0;
}

StreamTransformer<T, T> _debounce<T>(Duration d) {
  Timer? timer;
  return StreamTransformer.fromBind((s) {
    final c = StreamController<T>();
    final sub = s.listen((v) {
      timer?.cancel();
      timer = Timer(d, () => c.add(v));
    }, onError: c.addError, onDone: () {
      timer?.cancel();
      c.close();
    });
    c.onCancel = () {
      timer?.cancel();
      return sub.cancel();
    };
    return c.stream;
  });
}

final catalogueRepoProvider = Provider<CatalogueRepo>((ref) => CatalogueRepo(ref.watch(dbProvider), branchId: () => ref.read(sessionProvider).branchId));
