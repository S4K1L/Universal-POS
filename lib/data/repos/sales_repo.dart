import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/money/money.dart';
import '../../core/money/pricing.dart';
import '../local/database.dart';
import '../models/cart.dart';
import '../providers.dart';
import '../session.dart';
import '../sync/sync_engine.dart';

const _uuid = Uuid();
String newId() => _uuid.v7();

class NewPayment {
  const NewPayment(this.method, this.amountP, {this.reference = ''});
  final String method;
  final int amountP;
  final String reference;
}

class SaleDraft {
  const SaleDraft({required this.cart, required this.payments});
  final CartState cart;
  final List<NewPayment> payments;
}

/// A sale together with its lines and payments, as stored on the till.
class SaleBundle {
  SaleBundle(this.sale, this.lines, this.payments);
  final LSale sale;
  final List<LSaleLine> lines;
  final List<LSalePayment> payments;
  int get dueP => (sale.totalP - sale.paidP).clamp(0, 1 << 40);
}

class OutboxItem {
  OutboxItem(this.row);
  final OutboxData row;
}

/// Everything that changes the books goes through here: the local tables and the outbox are written in one
/// transaction, so the till is never in a state where it printed a receipt the server will never hear about.
class SalesRepo {
  SalesRepo(this.ref);
  final Ref ref;

  AppDatabase get db => ref.read(dbProvider);

  /// Short code that prefixes every invoice number this install issues, so two tills selling offline can never mint
  /// the same number. It is made up on first use and kept on the device; the server is never asked to hand it out.
  Future<String> tillCode() => tillCodeOf(db);

  Future<int> _nextSeq() async {
    final cur = int.tryParse(await db.kvGet('invoice_seq') ?? '0') ?? 0;
    final next = cur + 1;
    await db.kvSet('invoice_seq', '$next');
    return next;
  }

  Future<String?> openShiftId() async {
    final s = await db.kvGet('shift');
    if (s == null) return null;
    return (jsonDecode(s) as Map<String, dynamic>)['id'] as String?;
  }

  Future<void> _enqueue(String type, Map<String, dynamic> payload, {required String summary, DateTime? at, String? actorId, String? id}) async {
    await db.into(db.outbox).insert(OutboxCompanion.insert(
          id: id ?? newId(),
          type: type,
          payload: jsonEncode(payload),
          occurredAt: at ?? DateTime.now().toUtc(),
          actorId: Value(actorId),
          summary: Value(summary),
          createdAt: DateTime.now().toUtc(),
        ));
  }

  // ------------------------------------------------------------------------------------- sales

  Future<SaleBundle> completeSale(SaleDraft draft) async {
    final session = ref.read(sessionProvider);
    final ctx = session.ctx!;
    final branchId = session.branchId!;
    final tillCode = await this.tillCode();
    final cart = draft.cart;
    final priced = priceCart(
      [for (final l in cart.lines) l.input],
      billDiscount: cart.billDiscountP,
      taxMode: ctx.taxMode,
      cashRounding: ctx.cashRounding,
    );
    final now = DateTime.now();
    final saleId = newId();
    late SaleBundle bundle;

    await db.transaction(() async {
      final seq = await _nextSeq();
      final invoiceNo = 'INV-$tillCode-${seq.toString().padLeft(6, '0')}';
      final shiftId = await openShiftId();

      // Apply payments in order, never more than the bill.
      var remaining = priced.total;
      final applied = <NewPayment>[];
      for (final p in draft.payments) {
        final take = p.amountP < remaining ? p.amountP : remaining;
        if (take <= 0) continue;
        applied.add(NewPayment(p.method, take, reference: p.reference));
        remaining -= take;
      }
      final paid = priced.total - remaining;

      await db.into(db.lSales).insert(LSalesCompanion.insert(
            id: saleId,
            invoiceNo: invoiceNo,
            soldAt: now,
            customerId: Value(cart.customer?.id),
            customerName: Value(cart.customer?.name ?? 'Walk-in'),
            subtotalP: priced.subtotal,
            discountP: Value(priced.discount),
            taxP: Value(priced.taxTotal),
            roundingP: Value(priced.rounding),
            totalP: priced.total,
            paidP: paid,
            taxMode: Value(ctx.taxMode == TaxMode.exclusive ? 'exclusive' : 'inclusive'),
            cashRounding: Value(ctx.cashRounding),
            note: Value(cart.note),
            cashierId: ctx.userId,
            cashierName: Value(ctx.userName),
            branchId: branchId,
            shiftId: Value(shiftId),
            createdAt: now,
          ));

      final lineRows = <LSaleLinesCompanion>[];
      final payloadLines = <Map<String, dynamic>>[];
      for (var i = 0; i < cart.lines.length; i++) {
        final l = cart.lines[i];
        final pl = priced.lines[i];
        final lineId = newId();
        lineRows.add(LSaleLinesCompanion.insert(
          id: lineId,
          saleId: saleId,
          position: Value(i),
          variantId: l.variantId,
          productId: l.productId,
          productName: l.name,
          variantLabel: Value(l.variantLabel),
          sku: Value(l.sku),
          unit: Value(l.unit),
          unitFactorMilli: Value(l.unitFactorMilli),
          qtyMilli: l.qtyMilli,
          unitPriceP: l.unitPriceP,
          discountP: Value(l.discountP),
          taxRateBp: Value(l.taxRateBp),
          taxAmountP: Value(pl.tax),
          netP: pl.net,
          chargedP: pl.total,
          warrantyMonths: Value(l.warrantyMonths),
          note: Value(l.note),
        ));
        payloadLines.add({
          'id': lineId,
          'variant_id': l.variantId,
          'qty': milliToWire(l.qtyMilli),
          'unit': l.unit,
          'unit_factor': milliToWire(l.unitFactorMilli),
          'unit_price': paisaToWire(l.unitPriceP),
          'discount': paisaToWire(l.discountP),
          'tax_rate': paisaToWire(l.taxRateBp),
          if (l.note.isNotEmpty) 'note': l.note,
        });
      }
      await db.batch((b) => b.insertAll(db.lSaleLines, lineRows));

      final payRows = <LSalePaymentsCompanion>[];
      final payloadPays = <Map<String, dynamic>>[];
      for (final p in applied) {
        final pid = newId();
        payRows.add(LSalePaymentsCompanion.insert(id: pid, saleId: saleId, method: p.method, amountP: p.amountP, reference: Value(p.reference), paidAt: now));
        payloadPays.add({'id': pid, 'method': p.method, 'amount': paisaToWire(p.amountP), 'reference': p.reference, 'paid_at': now.toUtc().toIso8601String()});
      }
      await db.batch((b) => b.insertAll(db.lSalePayments, payRows));

      await _enqueue(
        'sale.create',
        {
          'id': saleId,
          'invoice_no': invoiceNo,
          'sold_at': now.toUtc().toIso8601String(),
          'branch_id': branchId,
          if (shiftId != null) 'shift_id': shiftId,
          if (cart.customer != null) 'customer_id': cart.customer!.id,
          'customer_name': cart.customer?.name ?? 'Walk-in',
          'lines': payloadLines,
          'bill_discount': paisaToWire(priced.discount),
          'tax_mode': ctx.taxMode == TaxMode.exclusive ? 'exclusive' : 'inclusive',
          'cash_rounding': ctx.cashRounding ? 'nearest_1' : 'none',
          'payments': payloadPays,
          'totals': {
            'subtotal': paisaToWire(priced.subtotal),
            'discount': paisaToWire(priced.discount),
            'tax_total': paisaToWire(priced.taxTotal),
            'rounding': paisaToWire(priced.rounding),
            'total': paisaToWire(priced.total),
          },
          if (cart.note.isNotEmpty) 'note': cart.note,
        },
        summary: '$invoiceNo · ${paisaToWire(priced.total)}',
        at: now.toUtc(),
        actorId: ctx.userId,
        id: newId(),
      );

      final sale = await (db.select(db.lSales)..where((t) => t.id.equals(saleId))).getSingle();
      bundle = SaleBundle(
        sale,
        await (db.select(db.lSaleLines)..where((t) => t.saleId.equals(saleId))..orderBy([(t) => OrderingTerm.asc(t.position)])).get(),
        await (db.select(db.lSalePayments)..where((t) => t.saleId.equals(saleId))).get(),
      );
    });
    ref.read(syncProvider.notifier).kick();
    return bundle;
  }

  Future<SaleBundle?> bundleOf(String saleId) async {
    final sale = await (db.select(db.lSales)..where((t) => t.id.equals(saleId))).getSingleOrNull();
    if (sale == null) return null;
    return SaleBundle(
      sale,
      await (db.select(db.lSaleLines)..where((t) => t.saleId.equals(saleId))..orderBy([(t) => OrderingTerm.asc(t.position)])).get(),
      await (db.select(db.lSalePayments)..where((t) => t.saleId.equals(saleId))..orderBy([(t) => OrderingTerm.asc(t.paidAt)])).get(),
    );
  }

  Stream<List<LSale>> watchRecent({int limit = 100}) => (db.select(db.lSales)
        ..orderBy([(t) => OrderingTerm.desc(t.soldAt)])
        ..limit(limit))
      .watch();

  /// Sales made on this till since [from] — what the dashboard shows with no connection.
  Future<List<LSale>> salesSince(DateTime from) => (db.select(db.lSales)..where((t) => t.soldAt.isBiggerOrEqualValue(from) & t.status.equals('completed'))).get();

  // ------------------------------------------------------------------------------------ returns

  /// Return goods from a sale made on this till (works offline). `lines` maps sale-line id -> qty in selling units, milli.
  Future<void> returnItems({required String saleId, required Map<String, int> lines, required bool restock, String method = 'cash', String reason = ''}) async {
    final ctx = ref.read(sessionProvider).ctx!;
    await db.transaction(() async {
      for (final e in lines.entries) {
        final l = await (db.select(db.lSaleLines)..where((t) => t.id.equals(e.key))).getSingle();
        await (db.update(db.lSaleLines)..where((t) => t.id.equals(e.key))).write(LSaleLinesCompanion(returnedQtyMilli: Value(l.returnedQtyMilli + e.value)));
      }
      final sale = await (db.select(db.lSales)..where((t) => t.id.equals(saleId))).getSingle();
      await _enqueue(
        'sale.return',
        {
          'id': newId(),
          'sale_id': saleId,
          'lines': [for (final e in lines.entries) {'sale_line_id': e.key, 'qty': milliToWire(e.value)}],
          'restock': restock,
          'refund_method': method,
          'reason': reason,
          'returned_at': DateTime.now().toUtc().toIso8601String(),
        },
        summary: 'Return on ${sale.invoiceNo}',
        actorId: ctx.userId,
      );
    });
    ref.read(syncProvider.notifier).kick();
  }

  // -------------------------------------------------------------------------------------- dues

  /// Collect money against a customer's due (oldest invoice first on the server). Works offline.
  Future<void> collectDue({String? customerId, String? saleId, required int amountP, String method = 'cash', String reference = ''}) async {
    final ctx = ref.read(sessionProvider).ctx!;
    final id = newId();
    await db.transaction(() async {
      if (saleId != null) {
        final sale = await (db.select(db.lSales)..where((t) => t.id.equals(saleId))).getSingleOrNull();
        if (sale != null) {
          await (db.update(db.lSales)..where((t) => t.id.equals(saleId))).write(LSalesCompanion(paidP: Value(sale.paidP + amountP)));
          await db.into(db.lSalePayments).insert(LSalePaymentsCompanion.insert(id: id, saleId: saleId, method: method, amountP: amountP, reference: Value(reference), kind: const Value('due'), paidAt: DateTime.now()));
        }
      }
      await _enqueue(
        'payment.receive',
        {
          'id': id,
          if (saleId != null) 'sale_id': saleId,
          if (customerId != null && saleId == null) 'customer_id': customerId,
          'amount': paisaToWire(amountP),
          'method': method,
          'reference': reference,
          'paid_at': DateTime.now().toUtc().toIso8601String(),
        },
        summary: 'Due collected · ${paisaToWire(amountP)}',
        actorId: ctx.userId,
        id: id,
      );
    });
    ref.read(syncProvider.notifier).kick();
  }

  Future<void> voidSale(String saleId, String reason) async {
    final ctx = ref.read(sessionProvider).ctx!;
    await db.transaction(() async {
      final sale = await (db.select(db.lSales)..where((t) => t.id.equals(saleId))).getSingleOrNull();
      if (sale != null) await (db.update(db.lSales)..where((t) => t.id.equals(saleId))).write(const LSalesCompanion(status: Value('voided')));
      await _enqueue('sale.void', {'sale_id': saleId, 'reason': reason}, summary: 'Void ${sale?.invoiceNo ?? ''}', actorId: ctx.userId);
    });
    ref.read(syncProvider.notifier).kick();
  }

  // ----------------------------------------------------------------------------------- expenses

  Future<void> addExpense({required String category, required int amountP, String method = 'cash', String note = ''}) async {
    final session = ref.read(sessionProvider);
    final ctx = session.ctx!;
    final id = newId();
    final at = DateTime.now();
    await db.transaction(() async {
      await db.into(db.lExpenses).insert(LExpensesCompanion.insert(id: id, branchId: session.branchId!, category: category, amountP: amountP, method: Value(method), note: Value(note), spentAt: at));
      await _enqueue(
        'expense.create',
        {'id': id, 'branch_id': session.branchId!, 'category': category, 'amount': paisaToWire(amountP), 'method': method, 'note': note, 'spent_at': at.toUtc().toIso8601String()},
        summary: 'Expense · $category · ${paisaToWire(amountP)}',
        actorId: ctx.userId,
        id: id,
      );
    });
    ref.read(syncProvider.notifier).kick();
  }

  // ------------------------------------------------------------------------------------ stock

  Future<void> adjustStock({required String variantId, String? deltaWire, String? countedWire, String reason = 'adjust', String note = ''}) async {
    final session = ref.read(sessionProvider);
    await _enqueue(
      'stock.adjust',
      {
        'id': newId(),
        'variant_id': variantId,
        'branch_id': session.branchId!,
        if (deltaWire != null) 'delta': deltaWire,
        if (countedWire != null) 'counted': countedWire,
        'reason': countedWire != null ? 'count' : reason,
        'note': note,
      },
      summary: 'Stock ${countedWire != null ? 'count' : 'adjustment'}',
      actorId: session.ctx!.userId,
    );
    ref.read(syncProvider.notifier).kick();
  }

  // ------------------------------------------------------------------------------------- shifts

  Future<Map<String, dynamic>?> currentShift() async {
    final s = await db.kvGet('shift');
    return s == null ? null : jsonDecode(s) as Map<String, dynamic>;
  }

  Future<void> openShift(int floatP) async {
    final session = ref.read(sessionProvider);
    final id = newId();
    final at = DateTime.now().toUtc();
    await db.transaction(() async {
      await db.kvSet('shift', jsonEncode({'id': id, 'opened_at': at.toIso8601String(), 'opening_float': floatP, 'branch_id': session.branchId!, 'opened_by': session.ctx!.userName}));
      await _enqueue('shift.open', {'id': id, 'branch_id': session.branchId!, 'opened_at': at.toIso8601String(), 'opening_float': paisaToWire(floatP)},
          summary: 'Shift opened · float ${paisaToWire(floatP)}', at: at, actorId: session.ctx!.userId);
    });
    ref.read(syncProvider.notifier).kick();
  }

  /// Float + cash taken − cash paid out, on this till since the shift opened.
  Future<({int expected, int cashIn, int cashOut, int sales, int invoices})> shiftTotals() async {
    final shift = await currentShift();
    if (shift == null) return (expected: 0, cashIn: 0, cashOut: 0, sales: 0, invoices: 0);
    final opened = DateTime.parse(shift['opened_at'] as String).toLocal();
    final pays = await (db.select(db.lSalePayments)..where((p) => p.paidAt.isBiggerOrEqualValue(opened) & p.kind.isNotValue('return'))).get();
    final cashIn = pays.where((p) => p.method == 'cash').fold<int>(0, (a, p) => a + p.amountP);
    final exp = await (db.select(db.lExpenses)..where((e) => e.spentAt.isBiggerOrEqualValue(opened) & e.method.equals('cash'))).get();
    final cashOut = exp.fold<int>(0, (a, e) => a + e.amountP);
    final sales = await (db.select(db.lSales)..where((s) => s.soldAt.isBiggerOrEqualValue(opened) & s.status.equals('completed'))).get();
    return (expected: (shift['opening_float'] as int) + cashIn - cashOut, cashIn: cashIn, cashOut: cashOut, sales: sales.fold(0, (a, s) => a + s.totalP), invoices: sales.length);
  }

  Future<int> closeShift(int countedP, {String note = ''}) async {
    final shift = await currentShift();
    if (shift == null) return 0;
    final totals = await shiftTotals();
    final at = DateTime.now().toUtc();
    await db.transaction(() async {
      await _enqueue('shift.close', {'id': shift['id'], 'closed_at': at.toIso8601String(), 'counted_cash': paisaToWire(countedP), 'note': note},
          summary: 'Shift closed · counted ${paisaToWire(countedP)}', at: at, actorId: ref.read(sessionProvider).ctx!.userId);
      await db.kvDelete('shift');
    });
    ref.read(syncProvider.notifier).kick();
    return countedP - totals.expected;
  }

  // ----------------------------------------------------------------------------------- customers

  Future<LCustomer> saveCustomer({String? id, required String name, String phone = '', String address = '', int creditLimitP = 0, String notes = ''}) async {
    final ctx = ref.read(sessionProvider).ctx!;
    final cid = id ?? newId();
    await db.transaction(() async {
      final existing = await (db.select(db.lCustomers)..where((t) => t.id.equals(cid))).getSingleOrNull();
      await db.into(db.lCustomers).insertOnConflictUpdate(LCustomersCompanion.insert(
            id: cid,
            name: name,
            phone: Value(phone),
            address: Value(address),
            creditLimitP: Value(creditLimitP),
            balanceP: Value(existing?.balanceP ?? 0),
            points: Value(existing?.points ?? 0),
            notes: Value(notes),
          ));
      await _enqueue(
        'customer.upsert',
        {'id': cid, 'name': name, 'phone': phone, 'address': address, 'credit_limit': paisaToWire(creditLimitP), 'notes': notes},
        summary: 'Customer · $name',
        actorId: ctx.userId,
      );
    });
    ref.read(syncProvider.notifier).kick();
    return (db.select(db.lCustomers)..where((t) => t.id.equals(cid))).getSingle();
  }

  /// Server balance + what this till has sold on credit / collected since the last pull.
  Future<Map<String, int>> pendingCustomerDeltas() async {
    final rows = await (db.select(db.outbox)..where((o) => o.status.isNotValue('done'))).get();
    final out = <String, int>{};
    for (final r in rows) {
      final p = jsonDecode(r.payload) as Map<String, dynamic>;
      if (r.type == 'sale.create' && p['customer_id'] != null) {
        final total = parsePaisa((p['totals'] as Map)['total']);
        final paid = (p['payments'] as List).fold<int>(0, (a, x) => a + parsePaisa((x as Map)['amount']));
        out[p['customer_id'] as String] = (out[p['customer_id']] ?? 0) + (total - paid);
      } else if (r.type == 'payment.receive') {
        String? cid = p['customer_id'] as String?;
        if (cid == null && p['sale_id'] != null) {
          cid = (await (db.select(db.lSales)..where((t) => t.id.equals(p['sale_id'] as String))).getSingleOrNull())?.customerId;
        }
        if (cid != null) out[cid] = (out[cid] ?? 0) - parsePaisa(p['amount']);
      }
    }
    return out;
  }

  Stream<List<OutboxData>> watchOutbox() => (db.select(db.outbox)
        ..where((o) => o.status.isNotValue('done'))
        ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
      .watch();

  Stream<List<OutboxData>> watchRecentDone({int limit = 30}) => (db.select(db.outbox)
        ..where((o) => o.status.equals('done'))
        ..orderBy([(o) => OrderingTerm.desc(o.seq)])
        ..limit(limit))
      .watch();

  /// Housekeeping: keep a month of local history and a few days of confirmed events.
  Future<void> prune() async {
    final cutoffSales = DateTime.now().subtract(const Duration(days: 35));
    final old = await (db.select(db.lSales)..where((t) => t.soldAt.isSmallerThanValue(cutoffSales) & t.syncState.equals('synced'))).get();
    for (final s in old) {
      await (db.delete(db.lSaleLines)..where((t) => t.saleId.equals(s.id))).go();
      await (db.delete(db.lSalePayments)..where((t) => t.saleId.equals(s.id))).go();
      await (db.delete(db.lSales)..where((t) => t.id.equals(s.id))).go();
    }
    await (db.delete(db.outbox)..where((o) => o.status.equals('done') & o.createdAt.isSmallerThanValue(DateTime.now().subtract(const Duration(days: 4))))).go();
  }
}

final salesRepoProvider = Provider<SalesRepo>((ref) => SalesRepo(ref));

const _codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I to misread on a printed receipt

/// This install's invoice prefix. Installs that were already numbering invoices keep the code they had.
Future<String> tillCodeOf(AppDatabase db) async {
  final saved = await db.kvGet('till_code');
  if (saved != null) return saved;
  String? code;
  final legacy = await db.kvGet('device'); // written by earlier versions that registered the till with the server
  if (legacy != null) code = (jsonDecode(legacy) as Map<String, dynamic>)['code'] as String?;
  if (code == null) {
    final rnd = Random.secure();
    code = String.fromCharCodes([for (var i = 0; i < 4; i++) _codeAlphabet.codeUnitAt(rnd.nextInt(_codeAlphabet.length))]);
  }
  await db.kvSet('till_code', code);
  return code;
}

final tillCodeProvider = FutureProvider<String>((ref) => tillCodeOf(ref.read(dbProvider)));
