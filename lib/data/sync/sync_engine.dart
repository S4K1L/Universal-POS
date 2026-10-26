import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/money/money.dart';
import '../local/database.dart';
import '../providers.dart';
import '../session.dart';

/// What the "beacon" in the top bar shows.
@immutable
class SyncState {
  const SyncState({
    this.started = false,
    this.online = true,
    this.syncing = false,
    this.pending = 0,
    this.failed = 0,
    this.lastSync,
    this.error,
    this.bootstrapped = false,
    this.catalogueLoading = false,
    this.revision = 0,
  });

  final bool started;
  final bool online;
  final bool syncing;
  final int pending; // events waiting to reach the server
  final int failed; // events the server refused — need a person
  final DateTime? lastSync;
  final String? error;
  final bool bootstrapped; // the first full pull has completed at least once
  final bool catalogueLoading;

  /// Bumped whenever a cycle pushed or pulled anything — screens refetch on this rather than on a timer.
  final int revision;

  SyncState copyWith({bool? started, bool? online, bool? syncing, int? pending, int? failed, DateTime? lastSync, String? error, bool clearError = false, bool? bootstrapped, bool? catalogueLoading, int? revision}) =>
      SyncState(
        started: started ?? this.started,
        online: online ?? this.online,
        syncing: syncing ?? this.syncing,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        lastSync: lastSync ?? this.lastSync,
        error: clearError ? null : (error ?? this.error),
        bootstrapped: bootstrapped ?? this.bootstrapped,
        catalogueLoading: catalogueLoading ?? this.catalogueLoading,
        revision: revision ?? this.revision,
      );
}

/// Offline-first sync.
///
/// **Push** — every sale, return, payment, expense, customer and stock count the device makes is written to the
/// local database *and* to an outbox in one transaction. The engine replays the outbox to `/sync/push` in
/// order; each event carries a client-generated id, so retrying after a dropped connection is always safe.
///
/// **Pull** — it then asks `/sync/pull` for everything that changed since its cursor and applies it locally.
/// The server wins on the catalogue; devices never edit it offline.
class SyncController extends Notifier<SyncState> {
  /// Tests switch this off: there is no connectivity plugin in a headless run.
  static bool watchConnectivity = true;

  Timer? _timer;
  StreamSubscription<dynamic>? _conn;
  StreamSubscription<List<OutboxData>>? _outboxSub;
  Future<void>? _current;
  bool _again = false;

  AppDatabase get _db => ref.read(dbProvider);
  ApiClient get _api => ref.read(apiProvider);

  @override
  SyncState build() {
    ref.onDispose(_cancel);
    return const SyncState();
  }

  void start() {
    if (state.started) {
      kick();
      return;
    }
    state = state.copyWith(started: true);
    _db.kvGet('bootstrapped').then((v) {
      if (v == '1') state = state.copyWith(bootstrapped: true);
    });
    _outboxSub?.cancel();
    _outboxSub = (_db.select(_db.outbox)..where((t) => t.status.isNotValue('done'))).watch().listen((rows) {
      state = state.copyWith(pending: rows.where((r) => r.status != 'failed').length, failed: rows.where((r) => r.status == 'failed').length);
    });
    _conn?.cancel();
    if (watchConnectivity) {
      try {
        _conn = Connectivity().onConnectivityChanged.listen((_) => kick(), onError: (_) {});
      } catch (_) {}
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => kick());
    // Anything left "sending" by a crash goes back in the queue.
    (_db.update(_db.outbox)..where((t) => t.status.equals('sending'))).write(const OutboxCompanion(status: Value('pending')));
    kick();
  }

  void _cancel() {
    _timer?.cancel();
    _conn?.cancel();
    _outboxSub?.cancel();
    _timer = null;
  }

  void stop() {
    _cancel();
    state = const SyncState();
  }

  /// Run a sync cycle soon (or right after the one in progress).
  void kick() {
    if (!state.started) return;
    if (_current != null) {
      _again = true;
      return;
    }
    _current = _run().whenComplete(() {
      _current = null;
      if (_again) {
        _again = false;
        kick();
      }
    });
  }

  /// Run a full cycle and wait for it (waits for one already in progress, then runs another).
  Future<void> syncNow() async {
    if (!state.started) return;
    if (_current != null) await _current;
    _again = false;
    _current = _run().whenComplete(() => _current = null);
    await _current;
  }

  Future<void> _run() async {
    try {
      final up = await _api.ping();
      if (!up) {
        state = state.copyWith(online: false, syncing: false);
        return;
      }
      final first = !state.bootstrapped;
      state = state.copyWith(online: true, syncing: true, catalogueLoading: first, clearError: true);
      final pushed = await _push();
      final pulled = await _pull();
      state = state.copyWith(syncing: false, catalogueLoading: false, lastSync: DateTime.now(), clearError: true, revision: (pushed + pulled) > 0 ? state.revision + 1 : state.revision);
    } on ApiError catch (e) {
      if (e.offline) {
        state = state.copyWith(online: false, syncing: false, catalogueLoading: false);
      } else if (e.unauthorized) {
        state = state.copyWith(syncing: false, catalogueLoading: false, error: 'Sign in again to keep syncing');
      } else {
        state = state.copyWith(syncing: false, catalogueLoading: false, error: e.message);
      }
    } catch (e) {
      state = state.copyWith(syncing: false, catalogueLoading: false, error: e.toString());
    }
  }

  // ----------------------------------------------------------------------------------------- push

  /// Statuses that say "try again later" rather than "this event is wrong".
  static bool _transient(ApiError e) => e.offline || e.status >= 500 || e.unauthorized || e.status == 408 || e.status == 425 || e.status == 429;

  Future<int> _push() async {
    var count = 0;
    var batchSize = 50;
    while (true) {
      final rows = await (_db.select(_db.outbox)
            ..where((t) => t.status.isIn(['pending', 'sending']))
            ..orderBy([(t) => OrderingTerm.asc(t.seq)])
            ..limit(batchSize))
          .get();
      if (rows.isEmpty) return count;
      count += rows.length;
      final ids = rows.map((r) => r.id).toList();
      await (_db.update(_db.outbox)..where((t) => t.id.isIn(ids))).write(const OutboxCompanion(status: Value('sending')));
      for (final r in rows) {
        await (_db.update(_db.outbox)..where((t) => t.id.equals(r.id))).write(OutboxCompanion(attempts: Value(r.attempts + 1)));
      }

      Map<String, dynamic> res;
      try {
        res = await _api.post('/sync/push', body: {
          'events': [
            for (final r in rows)
              {
                'id': r.id,
                'type': r.type,
                'occurred_at': r.occurredAt.toUtc().toIso8601String(),
                if (r.actorId != null) 'actor_id': r.actorId,
                'payload': jsonDecode(r.payload),
              }
          ],
        });
      } on ApiError catch (e) {
        if (_transient(e)) {
          await (_db.update(_db.outbox)..where((t) => t.id.isIn(ids))).write(const OutboxCompanion(status: Value('pending')));
          rethrow;
        }
        await (_db.update(_db.outbox)..where((t) => t.id.isIn(ids))).write(const OutboxCompanion(status: Value('pending')));
        if (rows.length > 1) {
          // The server refused the batch as a whole, which says nothing about which event is wrong. Send them one at a
          // time so only the guilty event is parked and the rest still reach the books.
          batchSize = 1;
          count -= rows.length;
          continue;
        }
        // A single event the server refuses outright: park it for a human instead of looping forever.
        await (_db.update(_db.outbox)..where((t) => t.id.equals(rows.single.id))).write(OutboxCompanion(status: const Value('failed'), errorCode: Value(e.code), lastError: Value(e.message)));
        await _markSalesFailed(rows);
        continue;
      }

      final results = {for (final r in (res['results'] as List)) (r as Map<String, dynamic>)['id'] as String: r};
      for (final row in rows) {
        final r = results[row.id];
        if (r == null) {
          await (_db.update(_db.outbox)..where((t) => t.id.equals(row.id))).write(const OutboxCompanion(status: Value('pending')));
          continue;
        }
        final status = r['status'] as String;
        if (status == 'applied' || status == 'duplicate') {
          await (_db.update(_db.outbox)..where((t) => t.id.equals(row.id))).write(const OutboxCompanion(status: Value('done'), errorCode: Value(null), lastError: Value(null)));
          await _onApplied(row, r);
        } else {
          await (_db.update(_db.outbox)..where((t) => t.id.equals(row.id))).write(
              OutboxCompanion(status: const Value('failed'), errorCode: Value(r['code'] as String?), lastError: Value(r['message'] as String?)));
          await _markSalesFailed([row]);
        }
      }
    }
  }

  Future<void> _onApplied(OutboxData row, Map<String, dynamic> result) async {
    final payload = jsonDecode(row.payload) as Map<String, dynamic>;
    switch (row.type) {
      case 'sale.create':
        final flags = (result['flags'] as List?)?.cast<String>() ?? const [];
        final invoice = result['invoice_no'] as String?;
        await (_db.update(_db.lSales)..where((t) => t.id.equals(payload['id'] as String))).write(LSalesCompanion(
          syncState: const Value('synced'),
          flags: Value(jsonEncode(flags)),
          invoiceNo: invoice == null ? const Value.absent() : Value(invoice),
        ));
      case 'expense.create':
        await (_db.update(_db.lExpenses)..where((t) => t.id.equals(payload['id'] as String))).write(const LExpensesCompanion(syncState: Value('synced')));
    }
  }

  Future<void> _markSalesFailed(List<OutboxData> rows) async {
    for (final r in rows) {
      if (r.type == 'sale.create') {
        final id = (jsonDecode(r.payload) as Map<String, dynamic>)['id'] as String;
        await (_db.update(_db.lSales)..where((t) => t.id.equals(id))).write(const LSalesCompanion(syncState: Value('failed')));
      }
    }
  }

  /// Put a refused event back in the queue (after the cause was fixed).
  Future<void> retry(String id) async {
    await (_db.update(_db.outbox)..where((t) => t.id.equals(id))).write(const OutboxCompanion(status: Value('pending'), errorCode: Value(null), lastError: Value(null)));
    final row = await (_db.select(_db.outbox)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row != null && row.type == 'sale.create') {
      final sid = (jsonDecode(row.payload) as Map<String, dynamic>)['id'] as String;
      await (_db.update(_db.lSales)..where((t) => t.id.equals(sid))).write(const LSalesCompanion(syncState: Value('pending')));
    }
    kick();
  }

  /// Give up on an event. The sale stays in this device's history, marked as never synced.
  Future<void> discard(String id) => (_db.delete(_db.outbox)..where((t) => t.id.equals(id))).go();

  // ----------------------------------------------------------------------------------------- pull

  Future<int> _pull() async {
    var total = 0;
    var cursor = int.tryParse(await _db.kvGet('sync_cursor') ?? '0') ?? 0;
    var contextChanged = false;
    while (true) {
      final res = await _api.getMap('/sync/pull', query: {'cursor': cursor, 'limit': 500}, timeout: const Duration(seconds: 60));
      final changes = (res['changes'] as List).cast<Map<String, dynamic>>();
      total += changes.length;
      await _db.transaction(() async {
        for (final c in changes) {
          if (c['entity'] == 'context') {
            contextChanged = true;
          } else {
            await _apply(c);
          }
        }
      });
      cursor = (res['cursor'] as num).toInt();
      await _db.kvSet('sync_cursor', '$cursor');
      if (res['has_more'] != true) break;
    }
    if (!state.bootstrapped) {
      await _db.kvSet('bootstrapped', '1');
      state = state.copyWith(bootstrapped: true);
      contextChanged = true;
    }
    if (contextChanged) await ref.read(sessionProvider.notifier).refreshContext();
    return total;
  }

  Future<void> _apply(Map<String, dynamic> c) async {
    final entity = c['entity'] as String;
    final id = c['id'] as String;
    final isDelete = c['op'] == 'delete';
    final data = (c['data'] as Map?)?.cast<String, dynamic>();
    switch (entity) {
      case 'category':
        if (isDelete || data == null) {
          await (_db.delete(_db.lCategories)..where((t) => t.id.equals(id))).go();
        } else {
          await _db.into(_db.lCategories).insertOnConflictUpdate(LCategoriesCompanion.insert(
            id: id,
            name: data['name'] as String,
            parentId: Value(data['parent_id'] as String?),
            sortOrder: Value((data['sort_order'] as num?)?.toInt() ?? 0),
            active: Value(data['active'] != false),
          ));
        }
      case 'tax_class':
        if (isDelete || data == null) {
          await (_db.delete(_db.lTaxClasses)..where((t) => t.id.equals(id))).go();
        } else {
          await _db.into(_db.lTaxClasses).insertOnConflictUpdate(LTaxClassesCompanion.insert(
            id: id,
            name: data['name'] as String,
            rateBp: Value(parseRateBp(data['rate'])),
            isDefault: Value(data['is_default'] == true),
          ));
        }
      case 'customer':
        if (isDelete || data == null) {
          await (_db.delete(_db.lCustomers)..where((t) => t.id.equals(id))).go();
        } else {
          await _db.into(_db.lCustomers).insertOnConflictUpdate(LCustomersCompanion.insert(
            id: id,
            name: data['name'] as String,
            phone: Value((data['phone'] as String?) ?? ''),
            address: Value((data['address'] as String?) ?? ''),
            creditLimitP: Value(parsePaisa(data['credit_limit'])),
            balanceP: Value(parsePaisa(data['balance'])),
            points: Value((data['points'] as num?)?.toInt() ?? 0),
            notes: Value((data['notes'] as String?) ?? ''),
            active: Value(data['active'] != false),
          ));
        }
      case 'stock':
        if (data != null && !isDelete) {
          await _db.into(_db.lStock).insertOnConflictUpdate(LStockCompanion.insert(branchId: data['branch_id'] as String, variantId: data['variant_id'] as String, onHandMilli: parseMilli(data['on_hand'])));
        }
      case 'product':
        await _applyProduct(id, isDelete ? null : data);
    }
  }

  Future<void> _applyProduct(String id, Map<String, dynamic>? p) async {
    await (_db.delete(_db.lBarcodes)..where((t) => t.productId.equals(id))).go();
    await (_db.delete(_db.lVariants)..where((t) => t.productId.equals(id))).go();
    if (p == null) {
      await (_db.delete(_db.lProducts)..where((t) => t.id.equals(id))).go();
      return;
    }
    final variants = (p['variants'] as List).cast<Map<String, dynamic>>();
    final brand = ((p['attributes'] as Map?)?['brand'] ?? '').toString();
    final skus = variants.map((v) => v['sku']).join(' ');
    final codes = [for (final v in variants) for (final b in (v['barcodes'] as List)) (b as Map)['code']].join(' ');
    final search = '${p['name']} ${p['name_local'] ?? ''} $brand $skus $codes'.toLowerCase();
    await _db.into(_db.lProducts).insertOnConflictUpdate(LProductsCompanion.insert(
      id: id,
      name: p['name'] as String,
      nameLocal: Value((p['name_local'] as String?) ?? ''),
      categoryId: Value(p['category_id'] as String?),
      type: Value((p['type'] as String?) ?? 'stockable'),
      baseUnit: Value((p['base_unit'] as String?) ?? 'pc'),
      altUnits: Value(jsonEncode(p['alt_units'] ?? const [])),
      allowFraction: Value(p['allow_fraction'] == true),
      tracking: Value((p['tracking'] as String?) ?? 'none'),
      trackExpiry: Value(p['track_expiry'] == true),
      taxClassId: Value(p['tax_class_id'] as String?),
      attributes: Value(jsonEncode(p['attributes'] ?? const {})),
      imageUrl: Value((p['image_url'] as String?) ?? ''),
      reorderMilli: Value(parseMilli(p['reorder_level'])),
      warrantyMonths: Value((p['warranty_months'] as num?)?.toInt() ?? 0),
      active: Value(p['active'] != false),
      search: Value(search),
    ));
    for (final v in variants) {
      final vid = v['id'] as String;
      await _db.into(_db.lVariants).insertOnConflictUpdate(LVariantsCompanion.insert(
        id: vid,
        productId: id,
        priceP: parsePaisa(v['price']),
        sku: Value((v['sku'] as String?) ?? ''),
        label: Value((v['label'] as String?) ?? ''),
        optionValues: Value(jsonEncode(v['option_values'] ?? const {})),
        mrpP: Value(parsePaisa(v['mrp'])),
        costP: Value(v['cost'] == null ? null : parsePaisa(v['cost'])),
        plu: Value(v['plu'] as String?),
        active: Value(v['active'] != false),
      ));
      for (final b in (v['barcodes'] as List).cast<Map<String, dynamic>>()) {
        await _db.into(_db.lBarcodes).insertOnConflictUpdate(LBarcodesCompanion.insert(
          code: b['code'] as String,
          variantId: vid,
          productId: id,
          unit: Value(b['unit'] as String?),
          qtyPerScanMilli: Value(parseMilli(b['qty_per_scan'])),
        ));
      }
    }
  }

  /// Throw away the cursor and pull everything again (the Sync Center's "Resync" button).
  Future<void> fullResync() async {
    await _db.resetCatalogue();
    state = state.copyWith(bootstrapped: false);
    await syncNow();
  }
}

final syncProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);
