import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../core/theme/theme.dart' show tabular;
import '../../core/util/responsive.dart';
import '../../data/repos/catalogue_repo.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';

final _stockProvider = StreamProvider.autoDispose<List<ProductView>>((ref) {
  ref.cacheForSession(revalidate: true);
  return ref.watch(catalogueRepoProvider).watchProducts(limit: 600, stockedOnly: true);
});

final _expiringProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.cacheForSession(revalidate: true);
  ref.watch(syncProvider.select((s) => s.revision));
  final r = await ref.watch(apiProvider).getList('/reports/expiring', query: {'days': 180});
  return r.cast<Map<String, dynamic>>();
});

class StockScreen extends ConsumerStatefulWidget {
  const StockScreen({super.key});

  @override
  ConsumerState<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends ConsumerState<StockScreen> {
  final _q = TextEditingController();
  String _filter = 'all';
  String _tab = 'stock';

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final products = ref.watch(_stockProvider);
    final showCost = ctx.can('view_cost');
    final expiry = ctx.cap('expiry_tracking');

    return PageBody(
      maxWidth: 1000,
      child: FadeSwitcher(child: products.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Deferred(child: SkeletonList(rows: 6)),
        error: (e, _) => ErrorView(error: e),
        data: (all) {
          final rows = <(ProductView, dynamic)>[
            for (final p in all) for (final v in p.variants) (p, v),
          ];
          int availOf(ProductView p, dynamic v) => p.availableOf(v);
          final out = rows.where((r) => availOf(r.$1, r.$2) <= 0).length;
          final low = rows.where((r) => availOf(r.$1, r.$2) > 0 && availOf(r.$1, r.$2) <= r.$1.product.reorderMilli).length;
          final value = showCost ? rows.fold<int>(0, (a, r) => a + (((r.$2.costP ?? 0) as int) * availOf(r.$1, r.$2).clamp(0, 1 << 40).toInt() ~/ 1000)) : 0;
          final q = _q.text.trim().toLowerCase();
          final shown = rows.where((r) {
            final a = availOf(r.$1, r.$2);
            if (_filter == 'out' && a > 0) return false;
            if (_filter == 'low' && !(a > 0 && a <= r.$1.product.reorderMilli)) return false;
            if (q.isEmpty) return true;
            return r.$1.product.search.contains(q);
          }).toList();
          return Column(children: [
            CardGrid(minWidth: 150, maxColumns: 3, gap: 12, fillLast: true, children: [
              StatTile(label: context.tr('Items in stock'), value: f.intN(rows.length - out), icon: Icons.inventory_2_rounded, hint: '${f.intN(rows.length)} ${context.tr('tracked')}'),
              StatTile(label: context.tr('Running low'), value: f.intN(low), icon: Icons.warning_amber_rounded, color: t.warning, hint: '${f.intN(out)} ${context.tr('out of stock')}'),
              if (showCost) StatTile(label: context.tr('Stock value (cost)'), value: f.moneyCompact(value), icon: Icons.account_balance_rounded, color: t.info),
            ]),
            const SizedBox(height: 12),
            if (expiry) Align(alignment: Alignment.centerLeft, child: IntrinsicWidth(child: SegTabs<String>(items: [('stock', context.tr('Stock')), ('expiry', context.tr('Batches & expiry'))], value: _tab, onChanged: (v) => setState(() => _tab = v)))),
            if (expiry) const SizedBox(height: 12),
            if (_tab == 'expiry')
              Expanded(child: _ExpiryList(ctx: ctx))
            else ...[
              AppSearchField(controller: _q, hint: context.tr('Search stock'), onChanged: (_) => setState(() {})),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: IntrinsicWidth(child: SegTabs<String>(items: [('all', context.tr('All')), ('low', context.tr('Low')), ('out', context.tr('Out'))], value: _filter, onChanged: (v) => setState(() => _filter = v)))),
              const SizedBox(height: 12),
              if (!context.isCompact && shown.isNotEmpty) _StockHeader(showCost: showCost),
              Expanded(
                child: shown.isEmpty
                    ? EmptyState(icon: Icons.inventory_2_outlined, title: context.tr('Nothing to show'), message: _filter == 'all' ? context.tr('Stocked items you add show up here.') : null)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: shown.length,
                        itemBuilder: (_, i) {
                          final (p, v) = shown[i];
                          return _StockTile(pv: p, variant: v, available: availOf(p, v), showCost: showCost, onTap: ctx.can('adjust_stock') ? () => showPanel<void>(context, maxWidth: 460, builder: (_) => _AdjustPanel(pv: p, variantId: v.id)) : null);
                        },
                      ),
              ),
            ],
          ]);
        },
      )),
    );
  }
}

// Column widths shared by the header and every row, so the numbers line up down the page.
const double _costColW = 130, _qtyColW = 120;

class _StockHeader extends StatelessWidget {
  const _StockHeader({required this.showCost});
  final bool showCost;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.w800);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(children: [
        const SizedBox(width: 52), // the monogram and its gap
        Expanded(child: Text(context.tr('Item').toUpperCase(), style: style)),
        if (showCost) SizedBox(width: _costColW, child: Text(context.tr('Value').toUpperCase(), style: style, textAlign: TextAlign.end)),
        SizedBox(width: _qtyColW, child: Text(context.tr('On hand').toUpperCase(), style: style, textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.pv, required this.variant, required this.available, required this.showCost, required this.onTap});
  final ProductView pv;
  final dynamic variant;
  final int available;
  final bool showCost;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final compact = context.isCompact;
    final p = pv.product;
    final v = variant;
    final a = available;
    final status = a <= 0 ? (t.danger, context.tr('Out')) : (a <= p.reorderMilli ? (t.warning, context.tr('Low')) : (t.success, context.tr('OK')));
    final cost = showCost && v.costP != null ? f.money((v.costP as int) * a.clamp(0, 1 << 40) ~/ 1000) : null;
    final qty = Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
      NumText('${f.qty(a)} ${p.baseUnit}', size: 15, weight: 800, color: a <= 0 ? t.danger : t.text),
      const SizedBox(height: 3),
      Pill(status.$2, color: status.$1, dense: true),
    ]);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Surface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Monogram(p.name, size: 40, seed: p.categoryId ?? p.id),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v.label.isEmpty ? p.name : '${p.name} · ${v.label}', style: tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${v.sku} · ${context.tr('reorder at')} ${f.qty(p.reorderMilli)}', style: tt.bodySmall, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 10),
          if (!compact && showCost) SizedBox(width: _costColW, child: Text(cost ?? '—', style: tt.bodyMedium!.copyWith(color: t.muted, fontFeatures: tabular), textAlign: TextAlign.end, maxLines: 1)),
          if (compact) qty else SizedBox(width: _qtyColW, child: Align(alignment: Alignment.centerRight, child: qty)),
        ]),
      ),
    );
  }
}

class _ExpiryList extends ConsumerWidget {
  const _ExpiryList({required this.ctx});
  final dynamic ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final data = ref.watch(_expiringProvider);
    return AsyncBody<List<Map<String, dynamic>>>(
      value: data,
      onRetry: () => ref.invalidate(_expiringProvider),
      data: (rows) => rows.isEmpty
          ? EmptyState(icon: Icons.event_available_rounded, title: context.tr('Nothing expires in the next 6 months'))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                final days = (r['days_left'] as num).toInt();
                final c = days < 0 ? t.danger : (days <= 30 ? t.danger : (days <= 90 ? t.warning : t.muted));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Surface(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Row(children: [
                      IconSquare(Icons.event_busy_rounded, color: c, size: 40),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r['label'] == '' ? r['name'] as String : '${r['name']} · ${r['label']}', style: tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis), Text('${context.tr('Batch')} ${r['lot_no']} · ${f.qty(parseMilli(r['qty']))} ${context.tr('left')} · ${f.date(DateTime.parse(r['expiry'] as String))}', style: tt.bodySmall)])),
                      Pill(days < 0 ? context.tr('Expired') : '${f.intN(days)} ${context.tr('days')}', color: c),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}

class _AdjustPanel extends ConsumerStatefulWidget {
  const _AdjustPanel({required this.pv, required this.variantId});
  final ProductView pv;
  final String variantId;

  @override
  ConsumerState<_AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends ConsumerState<_AdjustPanel> {
  String _mode = 'count';
  final _qty = TextEditingController();
  final _note = TextEditingController();
  String _reason = 'adjust';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final v = widget.pv.variants.firstWhere((x) => x.id == widget.variantId);
    final have = widget.pv.availableOf(v);
    final q = _qty.text.trim().isEmpty ? null : parseMilli(_qty.text.trim());
    final delta = q == null ? null : (_mode == 'count' ? q - have : (_mode == 'add' ? q : -q));
    return PanelScaffold(
      title: widget.pv.product.name,
      subtitle: '${v.label.isEmpty ? v.sku : v.label} · ${context.tr('now')} ${f.qty(have)} ${widget.pv.product.baseUnit}',
      leading: Monogram(widget.pv.product.name, size: 44),
      footer: FilledButton(
        onPressed: _busy || delta == null || delta == 0
            ? null
            : () async {
                setState(() => _busy = true);
                final repo = ref.read(salesRepoProvider);
                if (_mode == 'count') {
                  await repo.adjustStock(variantId: v.id, countedWire: milliToWire(q!), note: _note.text.trim());
                } else {
                  await repo.adjustStock(variantId: v.id, deltaWire: milliToWire(delta), reason: _mode == 'add' ? 'adjust' : _reason, note: _note.text.trim());
                }
                if (context.mounted) {
                  toast(context, context.tr('Saved — it syncs automatically'), good: true);
                  Navigator.pop(context);
                }
              },
        child: Text(delta == null || delta == 0 ? context.tr('Save') : '${context.tr('Save')} (${delta > 0 ? '+' : ''}${f.qty(delta)})'),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SegTabs<String>(items: [('count', context.tr('Count')), ('add', context.tr('Add')), ('remove', context.tr('Remove'))], value: _mode, onChanged: (v) => setState(() => _mode = v), expand: true),
        const FormGap(),
        TextField(
          controller: _qty,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(labelText: _mode == 'count' ? context.tr('Counted on the shelf') : (_mode == 'add' ? context.tr('Quantity received') : context.tr('Quantity to remove')), suffixText: widget.pv.product.baseUnit),
        ),
        if (_mode == 'remove') ...[
          const FormGap(),
          Wrap(spacing: 8, children: [for (final (k, l) in [('damage', 'Damaged'), ('expired', 'Expired'), ('adjust', 'Lost / other')]) ChoiceChip(label: Text(context.tr(l)), selected: _reason == k, onSelected: (_) => setState(() => _reason = k))]),
        ],
        const FormGap(),
        TextField(controller: _note, decoration: InputDecoration(labelText: context.tr('Note (optional)'), prefixIcon: const Icon(Icons.notes_rounded, size: 19))),
        const FormGap(),
        Text(context.tr('Stock changes are recorded in the ledger with who made them and why.'), style: tt.bodySmall),
      ]),
    );
  }
}
