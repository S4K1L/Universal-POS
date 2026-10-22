import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/kit.dart';
import '../../data/local/database.dart';
import '../../data/repos/catalogue_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';
import 'product_form.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _q = TextEditingController();
  String? _cat;
  bool _inactive = false;
  final List<Map<String, dynamic>> _items = [];
  int _total = 0;
  bool _loading = true;
  Object? _error;
  Timer? _debounce;
  int _seenRev = -1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _q.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _items.clear();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(apiProvider).getMap('/products', query: {
        'limit': 40,
        'offset': _items.length,
        'active': !_inactive,
        if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(),
        if (_cat != null) 'category_id': _cat,
      });
      _items.addAll((res['items'] as List).cast<Map<String, dynamic>>());
      _total = (res['total'] as num).toInt();
    } on ApiError catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final rev = ref.watch(syncProvider.select((s) => s.revision));
    if (rev != _seenRev) {
      if (_seenRev != -1) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _load(reset: true) : null);
      _seenRev = rev;
    }
    final cats = ref.watch(_categoriesProvider).value ?? const <LCategory>[];
    final word = context.term(ctx, 'product', 'Product');
    final limit = ctx.limits['products'] ?? -1;

    return PageBody(
      maxWidth: 1100,
      child: Column(children: [
        Row(children: [
          Expanded(child: AppSearchField(controller: _q, hint: context.trf('Search {word}, SKU or barcode', {'word': context.plural(word.toLowerCase())}), onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 350), () => _load(reset: true));
          })),
          if (ctx.can('manage_products')) ...[
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () async {
                  final saved = await showProductForm(context, ref);
                  if (saved == true) {
                    ref.read(syncProvider.notifier).kick();
                    _load(reset: true);
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 21),
                label: Text('${context.tr('Add')} $word'),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            _Chip(label: context.tr('All'), selected: _cat == null, onTap: () {
              setState(() => _cat = null);
              _load(reset: true);
            }),
            for (final c in cats)
              _Chip(label: c.name, selected: _cat == c.id, onTap: () {
                setState(() => _cat = c.id);
                _load(reset: true);
              }),
            _Chip(label: context.tr('Hidden'), selected: _inactive, icon: Icons.visibility_off_rounded, onTap: () {
              setState(() => _inactive = !_inactive);
              _load(reset: true);
            }),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Text('${f.intN(_total)} ${context.plural(word.toLowerCase())}', style: tt.labelMedium!.copyWith(color: t.muted)),
          if (limit >= 0) ...[const SizedBox(width: 8), Pill('${f.intN(ctx.usage['products'] ?? 0)} / ${f.intN(limit)} ${context.tr('plan limit')}', color: (ctx.usage['products'] ?? 0) >= limit ? t.danger : t.muted, dense: true)],
        ]),
        const SizedBox(height: 8),
        Expanded(
          child: _error != null
              ? ErrorView(error: _error!, onRetry: () => _load(reset: true))
              : _items.isEmpty && _loading
                  ? const SkeletonList(rows: 7, height: 68)
                  : _items.isEmpty
                      ? EmptyState(icon: Icons.category_rounded, title: context.tr('Nothing here yet'), message: ctx.can('manage_products') ? context.trf('Add your first {word} and it appears on every till.', {'word': word.toLowerCase()}) : null)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _items.length + (_items.length < _total ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _items.length) return Padding(padding: const EdgeInsets.all(12), child: Center(child: OutlinedButton(onPressed: _loading ? null : () => _load(), child: Text(context.tr('Load more')))));
                            return Padding(padding: const EdgeInsets.only(bottom: 8), child: _ProductRow(p: _items[i], onEdited: () {
                              ref.read(syncProvider.notifier).kick();
                              _load(reset: true);
                            }));
                          },
                        ),
        ),
      ]),
    );
  }
}

final _categoriesProvider = StreamProvider.autoDispose<List<LCategory>>((ref) {
  ref.cacheForSession();
  return ref.watch(catalogueRepoProvider).watchCategories();
});

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? t.ink : t.surface, borderRadius: BorderRadius.circular(R.chip), border: Border.all(color: selected ? t.ink : t.outline)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 15, color: selected ? t.onInk : t.muted), const SizedBox(width: 6)],
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? t.onInk : t.text)),
          ]),
        ),
      ),
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.p, required this.onEdited});
  final Map<String, dynamic> p;
  final VoidCallback onEdited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final variants = (p['variants'] as List).cast<Map<String, dynamic>>().where((v) => v['active'] != false).toList();
    final prices = variants.map((v) => parsePaisa(v['price'])).toList()..sort();
    final price = prices.isEmpty ? '—' : (prices.first == prices.last ? f.money(prices.first) : '${f.money(prices.first, symbol: false)}–${f.money(prices.last)}');
    final attrs = (p['attributes'] as Map).cast<String, dynamic>();
    final sub = [
      if (attrs['brand'] != null) attrs['brand'].toString(),
      if (attrs['material'] != null) attrs['material'].toString(),
      if (attrs['generic_name'] != null) attrs['generic_name'].toString(),
      variants.first['sku'] as String,
    ].where((e) => e.isNotEmpty).take(2).join(' · ');
    final inactive = p['active'] == false;
    return Opacity(
      opacity: inactive ? 0.6 : 1,
      child: Surface(
        onTap: () async {
          if (!ctx.can('manage_products')) return;
          final saved = await showProductForm(context, ref, existing: p);
          if (saved == true) onEdited();
        },
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Monogram(p['name'] as String, size: 46, seed: p['category_id'] as String? ?? p['id'] as String),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] as String, style: tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(sub, style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          if (variants.length > 1) Padding(padding: const EdgeInsets.only(right: 8), child: Pill('${f.intN(variants.length)} ${context.tr('options')}', dense: true)),
          if (p['tracking'] == 'lot' && ctx.cap('expiry_tracking') && p['track_expiry'] == true) Padding(padding: const EdgeInsets.only(right: 8), child: Pill(context.tr('Expiry'), color: t.info, dense: true, icon: Icons.event_busy_rounded)),
          if (inactive) Padding(padding: const EdgeInsets.only(right: 8), child: Pill(context.tr('Hidden'), color: t.faint, dense: true)),
          NumText(price, size: 15, weight: 800),
        ]),
      ),
    );
  }
}
