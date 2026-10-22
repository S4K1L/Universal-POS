import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/lang.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/kit.dart';
import '../../core/util/responsive.dart';
import '../../data/local/database.dart';
import '../../data/models/cart.dart';
import '../../data/models/context.dart';
import '../../data/repos/catalogue_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';
import 'cart_controller.dart';
import 'payment_sheet.dart';
import 'pos_widgets.dart';
import 'receipt.dart';
import '../../core/ui/panel.dart';

final _categoriesProvider = StreamProvider.autoDispose<List<LCategory>>((ref) {
  ref.cacheForSession();
  return ref.watch(catalogueRepoProvider).watchCategories();
});

final _productsProvider = StreamProvider.autoDispose.family<List<ProductView>, ({String q, String? cat})>(
  (ref, a) => ref.watch(catalogueRepoProvider).watchProducts(q: a.q, categoryId: a.cat, limit: 240),
);

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  String _q = '';
  String? _cat;
  Timer? _debounce;

  // keyboard-wedge barcode scanners "type" a code very fast and finish with Enter
  final _buf = StringBuffer();
  DateTime _last = DateTime.now();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent || !mounted) return false;
    if (ModalRoute.of(context)?.isCurrent == false) return false;
    final focus = FocusManager.instance.primaryFocus;
    final typing = focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null || focus?.context?.widget is EditableText;
    if (typing) return false; // the search box handles its own Enter (see _submit)
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds > 90) _buf.clear();
    _last = now;
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final code = _buf.toString();
      _buf.clear();
      if (code.length >= 4) {
        unawaited(_scan(code));
        return true;
      }
      return false;
    }
    final ch = e.character;
    if (ch != null && ch.length == 1 && ch.codeUnitAt(0) >= 32) _buf.write(ch);
    return false;
  }

  Future<void> _scan(String code) async {
    final ctx = ref.read(ctxProvider);
    final repo = ref.read(catalogueRepoProvider);
    final hit = await repo.lookup(code, scalePrefix: (ctx.scale['prefix'] as String?) ?? '20', scaleMode: (ctx.scale['mode'] as String?) ?? 'weight', scaleEnabled: ctx.cap('scale_barcode'));
    if (!mounted) return;
    if (hit == null) {
      toast(context, '${context.tr('No item matches')} $code', error: true);
      return;
    }
    final pv = await repo.byId(hit.productId);
    final v = pv?.variants.where((x) => x.id == hit.variantId).firstOrNull;
    if (pv == null || v == null) return;
    final r = await ref.read(cartProvider.notifier).add(pv, v, qtyMilli: hit.qtyMilli, unit: hit.unit);
    if (mounted && r != null) toast(context, '${pv.product.name}: ${context.tr(r.message)}', error: true);
    HapticFeedback.mediumImpact();
  }

  void _submit(String v) async {
    final ctx = ref.read(ctxProvider);
    final hit = await ref.read(catalogueRepoProvider).lookup(v, scalePrefix: (ctx.scale['prefix'] as String?) ?? '20', scaleMode: (ctx.scale['mode'] as String?) ?? 'weight', scaleEnabled: ctx.cap('scale_barcode'));
    if (hit != null) {
      _search.clear();
      setState(() => _q = '');
      await _scan(v);
      _searchFocus.requestFocus();
    }
  }

  Future<void> _tap(ProductView pv) async {
    final ctx = ref.read(ctxProvider);
    final cart = ref.read(cartProvider.notifier);
    if (pv.hasVariants) {
      await showVariantPicker(context, ref, pv);
      return;
    }
    final v = pv.variants.first;
    var qty = 1000;
    if (pv.product.allowFraction && ctx.cap('fractional_qty')) {
      final q = await showQtySheet(context, title: pv.product.name, unit: pv.product.baseUnit, allowFraction: true, maxMilli: pv.stocked && !ctx.allowNegativeStock ? pv.availableOf(v) : null);
      if (q == null) return;
      qty = q;
    }
    final r = await cart.add(pv, v, qtyMilli: qty);
    if (mounted && r != null) toast(context, r.message, error: true);
  }

  Future<void> _charge() async {
    final ctx = ref.read(ctxProvider);
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) return;
    if (ctx.requireCustomer && cart.customer == null) {
      final c = await showCustomerPicker(context);
      if (c == null) return;
      ref.read(cartProvider.notifier).setCustomer(c);
    }
    if (!mounted) return;
    final paid = await showPaymentSheet(context);
    if (paid == null || !mounted) return;
    ref.read(cartProvider.notifier).clear();
    final data = ReceiptData.fromBundle(paid.bundle, ctx, changeP: paid.changeP);
    await showPanel<void>(context, maxWidth: 420, builder: (c) => PanelScaffold(
          title: context.tr('Sale complete'),
          subtitle: paid.bundle.sale.invoiceNo,
          leading: IconSquare(Icons.check_circle_rounded, color: context.t.success),
          padBody: false,
          child: ReceiptPanel(data: data, onNewSale: () => _searchFocus.requestFocus()),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(ctxProvider);
    final sync = ref.watch(syncProvider);
    final t = context.t;
    if (!ctx.sellingAllowed) return _Locked(ctx: ctx);
    final catalogue = _Catalogue(
      search: _search,
      focus: _searchFocus,
      q: _q,
      cat: _cat,
      onQuery: (v) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 180), () => mounted ? setState(() => _q = v) : null);
      },
      onCat: (c) => setState(() => _cat = c),
      onSubmit: _submit,
      onTap: _tap,
      loading: !sync.bootstrapped,
    );
    if (context.width >= 1000) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 20, 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: catalogue),
          const SizedBox(width: 18),
          SizedBox(width: context.isHuge ? 430 : 390, child: _CartPane(onCharge: _charge)),
        ]),
      );
    }
    // phone / tablet: catalogue with a sticky cart bar that opens the cart
    final cart = ref.watch(cartProvider);
    final priced = ref.watch(pricedCartProvider);
    return Stack(children: [
      Padding(padding: EdgeInsets.fromLTRB(context.isCompact ? 12 : 20, 0, context.isCompact ? 12 : 20, cart.isEmpty ? 8 : 86), child: catalogue),
      if (!cart.isEmpty)
        Positioned(
          left: 14,
          right: 14,
          bottom: 12,
          child: Material(
            color: t.accent,
            borderRadius: BorderRadius.circular(20),
            elevation: 6,
            shadowColor: t.accent.withValues(alpha: 0.5),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _openCartSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: t.onAccent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)), child: Text(context.fmt.intN(cart.lines.length), style: TextStyle(color: t.onAccent, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 12),
                  Text(context.tr('View sale'), style: TextStyle(color: t.onAccent, fontWeight: FontWeight.w700, fontSize: 15)),
                  const Spacer(),
                  Text(context.fmt.money(priced.total, decimals: true), style: TextStyle(color: t.onAccent, fontWeight: FontWeight.w800, fontSize: 18, fontFeatures: tabular)),
                  const SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_up_rounded, color: t.onAccent),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }

  void _openCartSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(12),
          child: _CartPane(
            onCharge: () async {
              Navigator.pop(ctx);
              await _charge();
            },
            embedded: true,
          ),
        ),
      ),
    );
  }
}

class _Locked extends ConsumerWidget {
  const _Locked({required this.ctx});
  final TenantContext ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) => EmptyState(
        icon: Icons.lock_clock_rounded,
        title: context.tr('Selling is paused'),
        message: ctx.lapsed
            ? context.tr('This subscription has ended. Renew it to open the till again — sales you already made are safe and will sync.')
            : context.tr('This device has not confirmed the subscription for a while. Connect to the internet once to unlock the till.'),
        action: ctx.can('manage_subscription') ? FilledButton(onPressed: () => context.go('/billing'), child: Text(context.tr('Renew subscription'))) : null,
      );
}

// ------------------------------------------------------------------------------------------ catalogue

class _Catalogue extends ConsumerWidget {
  const _Catalogue({required this.search, required this.focus, required this.q, required this.cat, required this.onQuery, required this.onCat, required this.onSubmit, required this.onTap, required this.loading});
  final TextEditingController search;
  final FocusNode focus;
  final String q;
  final String? cat;
  final ValueChanged<String> onQuery, onSubmit;
  final ValueChanged<String?> onCat;
  final void Function(ProductView) onTap;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final f = context.fmt;
    final cats = ref.watch(_categoriesProvider).value ?? const [];
    final cart = ref.watch(cartProvider);
    final held = ref.watch(heldCartsProvider).value ?? const [];
    final inCart = <String, int>{};
    for (final l in cart.lines) {
      inCart[l.productId] = (inCart[l.productId] ?? 0) + l.qtyMilli;
    }
    return Column(children: [
      Row(children: [
        Expanded(child: AppSearchField(controller: search, focusNode: focus, hint: context.tr('Search items or scan a barcode'), onChanged: onQuery, onSubmitted: onSubmit, autofocus: context.width > 700)),
        const SizedBox(width: 10),
        Badge(
          isLabelVisible: held.isNotEmpty,
          label: Text(f.intN(held.length)),
          backgroundColor: t.warning,
          textColor: Colors.black,
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(onPressed: () => showHeldCarts(context, ref), icon: const Icon(Icons.pause_circle_outline_rounded, size: 20), label: Text(context.isCompact ? '' : context.tr('Parked')), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: context.isCompact ? 12 : 18))),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      SizedBox(
        height: 38,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _CatChip(label: context.tr('All'), selected: cat == null, onTap: () => onCat(null)),
          for (final c in cats) _CatChip(label: c.name, selected: cat == c.id, onTap: () => onCat(c.id)),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(child: _ProductGrid(q: q, cat: cat, loading: loading, inCart: inCart, onTap: onTap)),
    ]);
  }
}

/// The product grid. While a new search or category is being read it keeps showing the previous results instead of
/// dropping to a skeleton, so typing in the search box never makes the grid blink.
class _ProductGrid extends ConsumerStatefulWidget {
  const _ProductGrid({required this.q, required this.cat, required this.loading, required this.inCart, required this.onTap});
  final String q;
  final String? cat;
  final bool loading;
  final Map<String, int> inCart;
  final void Function(ProductView) onTap;

  @override
  ConsumerState<_ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends ConsumerState<_ProductGrid> {
  List<ProductView>? _last;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(_productsProvider((q: widget.q, cat: widget.cat)));
    final fresh = products.value;
    if (fresh != null) _last = fresh;
    final list = fresh ?? _last;
    if (products.hasError && list == null) {
      return EmptyState(icon: Icons.error_outline_rounded, title: context.tr('Could not read the catalogue'), message: '${products.error}');
    }
    final Widget body;
    if (list == null) {
      body = const Deferred(key: ValueKey('skeleton'), child: _GridSkeleton());
    } else if (list.isEmpty) {
      body = widget.loading
          ? const _GridSkeleton(key: ValueKey('syncing'), message: true)
          : EmptyState(
              key: const ValueKey('empty'),
              icon: widget.q.isEmpty ? Icons.inventory_2_outlined : Icons.search_off_rounded,
              title: widget.q.isEmpty ? context.tr('No items yet') : context.tr('Nothing matches'),
              message: widget.q.isEmpty ? context.tr('Add products under Items — they appear here, on every till, within seconds.') : '“${widget.q}”',
            );
    } else {
      body = GridView.builder(
        key: const ValueKey('grid'),
        padding: const EdgeInsets.only(bottom: 12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 184, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.0),
        itemCount: list.length,
        itemBuilder: (_, i) => ProductTile(pv: list[i], inCartMilli: widget.inCart[list[i].product.id] ?? 0, onTap: () => widget.onTap(list[i])),
      );
    }
    return FadeSwitcher(child: body);
  }
}

class _CatChip extends StatelessWidget {
  const _CatChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? t.ink : t.surface, borderRadius: BorderRadius.circular(R.chip), border: Border.all(color: selected ? t.ink : t.outline)),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? t.onInk : t.text, fontVariations: const [FontVariation('wght', 700)])),
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton({super.key, this.message = false});
  final bool message;

  @override
  Widget build(BuildContext context) => Stack(children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 184, mainAxisSpacing: 12, crossAxisSpacing: 12),
          itemCount: 12,
          itemBuilder: (_, __) => const Skeleton(radius: 18, height: 150),
        ),
        if (message)
          Center(
            child: Surface(
              raised: true,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3)),
                const SizedBox(height: 12),
                Text(context.tr('Loading your catalogue…'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(context.tr('This only happens the first time on a new till.'), style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ),
      ]);
}

// ------------------------------------------------------------------------------------------- cart pane

class _CartPane extends ConsumerWidget {
  const _CartPane({required this.onCharge, this.embedded = false});
  final VoidCallback onCharge;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final cart = ref.watch(cartProvider);
    final priced = ref.watch(pricedCartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final word = context.term(ctx, 'customer', 'Customer');

    return Surface(
      padding: EdgeInsets.zero,
      raised: !embedded,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 10, 8),
          child: Row(children: [
            Text(context.tr('Current sale'), style: tt.titleLarge),
            const SizedBox(width: 8),
            _CountBadge(count: cart.lines.length),
            const Spacer(),
            IconButton(tooltip: context.tr('Park this sale'), onPressed: cart.isEmpty ? null : () => notifier.hold(), icon: const Icon(Icons.pause_circle_outline_rounded)),
            IconButton(
              tooltip: context.tr('Clear'),
              onPressed: cart.isEmpty
                  ? null
                  : () async {
                      if (await confirmDialog(context, title: context.tr('Clear this sale?'), message: context.tr('All items will be removed.'), confirm: context.tr('Clear'), danger: true)) notifier.clear();
                    },
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
            if (embedded) IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Material(
            color: cart.customer == null ? t.surface2 : t.accentSoft,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final c = await showCustomerPicker(context);
                notifier.setCustomer(c);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  cart.customer == null ? Icon(Icons.person_add_alt_1_rounded, size: 22, color: t.muted) : Monogram(cart.customer!.name, size: 28, round: true),
                  const SizedBox(width: 10),
                  Expanded(child: Text(cart.customer?.name ?? '${context.tr('Add')} ${word.toLowerCase()} ${ctx.requireCustomer ? '' : '(${context.tr('optional')})'}', style: tt.titleSmall!.copyWith(color: cart.customer == null ? t.muted : t.text), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (cart.customer != null && cart.customer!.balanceP > 0) Pill('${context.tr('owes')} ${f.money(cart.customer!.balanceP)}', color: t.warning, dense: true),
                  if (cart.customer != null) InkWell(onTap: () => notifier.setCustomer(null), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 18))),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: FadeSwitcher(
            child: cart.isEmpty
                ? EmptyState(key: const ValueKey('empty'), icon: Icons.qr_code_scanner_rounded, title: context.tr('Ready to sell'), message: context.tr('Scan a barcode or tap an item to start.'), compact: true)
                : _CartLines(key: const ValueKey('lines'), lines: cart.lines, totals: [for (var i = 0; i < cart.lines.length; i++) priced.lines.length > i ? priced.lines[i].net - priced.lines[i].share : 0]),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: t.outline))),
          child: Column(children: [
            _TotalRow(context.tr('Subtotal'), f.money(priced.subtotal, decimals: true), amount: priced.subtotal, format: (v) => f.money(v, decimals: true)),
            InkWell(
              onTap: cart.isEmpty || !ctx.can('apply_discount') ? null : () => showDiscountSheet(context, ref),
              borderRadius: BorderRadius.circular(8),
              child: _TotalRow(context.tr('Discount'), priced.discount > 0 ? '−${f.money(priced.discount, decimals: true)}' : (ctx.can('apply_discount') && !cart.isEmpty ? context.tr('Add') : '—'), accent: priced.discount > 0 || ctx.can('apply_discount')),
            ),
            if (priced.taxTotal > 0) _TotalRow(ctx.taxMode.name == 'inclusive' ? context.tr('incl. VAT') : context.tr('VAT'), f.money(priced.taxTotal, decimals: true)),
            if (priced.rounding != 0) _TotalRow(context.tr('Rounding'), f.money(priced.rounding, decimals: true, sign: true)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: cart.isEmpty ? null : onCharge,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                child: Row(children: [
                  Text(context.tr('Charge'), style: const TextStyle(fontSize: 18)),
                  if (!cart.isEmpty) ...[
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: Motion.fast,
                      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                      child: Container(key: ValueKey(cart.lines.length), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: t.onAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: Text(f.intN(cart.lines.length), style: const TextStyle(fontSize: 13))),
                    ),
                  ],
                  const Spacer(),
                  CountUp(value: priced.total, duration: const Duration(milliseconds: 420), format: (v) => f.money(v, decimals: true), builder: (_, text) => Text(text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFeatures: tabular))),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value, {this.accent = false, this.amount, this.format});
  final String label, value;
  final bool accent;

  /// When given, the figure glides to each new amount instead of jumping.
  final int? amount;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: t.muted))),
        if (amount != null && format != null) CountUp(value: amount!, duration: const Duration(milliseconds: 380), format: format!, builder: (_, text) => NumText(text, size: 14, weight: 700, color: accent ? t.accentDeep : t.text)) else NumText(value, size: 14, weight: 700, color: accent ? t.accentDeep : t.text),
      ]),
    );
  }
}

/// How many lines are in the sale. The number swaps with a small pop so adding an item is visible at the corner too.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return AnimatedSwitcher(
      duration: Motion.fast,
      transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: FadeTransition(opacity: a, child: c)),
      child: count == 0
          ? const SizedBox.shrink(key: ValueKey(0))
          : Container(
              key: ValueKey(count),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(R.chip)),
              child: Text(context.fmt.intN(count), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: t.dark ? Color.lerp(t.accent, Colors.white, 0.3) : t.accentDeep)),
            ),
    );
  }
}

class _CartEntry {
  const _CartEntry(this.line, this.total);
  final CartLine line;
  final int total;
}

/// The lines of the sale. A line slides and grows in when it is added, shrinks away when it is removed, and a swipe to
/// the left deletes it. Rows keep their place while quantities change, so the list never jumps under the cashier's finger.
class _CartLines extends ConsumerStatefulWidget {
  const _CartLines({super.key, required this.lines, required this.totals});
  final List<CartLine> lines;
  final List<int> totals;

  @override
  ConsumerState<_CartLines> createState() => _CartLinesState();
}

class _CartLinesState extends ConsumerState<_CartLines> {
  final _list = GlobalKey<AnimatedListState>();
  late final List<_CartEntry> _items = [for (final (i, l) in widget.lines.indexed) _CartEntry(l, widget.totals[i])];
  final _swiped = <String>{}; // a swipe has already animated the row away

  @override
  void didUpdateWidget(_CartLines old) {
    super.didUpdateWidget(old);
    final next = {for (final (i, l) in widget.lines.indexed) l.key: _CartEntry(l, widget.totals[i])};
    final state = _list.currentState;
    for (var i = _items.length - 1; i >= 0; i--) {
      if (next.containsKey(_items[i].line.key)) continue;
      final gone = _items.removeAt(i);
      final instant = _swiped.remove(gone.line.key);
      state?.removeItem(i, (c, a) => instant ? const SizedBox.shrink() : _animated(gone, a), duration: instant || Motion.reduced(context) ? Duration.zero : Motion.base);
    }
    for (var i = 0; i < _items.length; i++) {
      _items[i] = next[_items[i].line.key]!;
    }
    for (var i = 0; i < widget.lines.length; i++) {
      if (i >= _items.length || _items[i].line.key != widget.lines[i].key) {
        _items.insert(i, next[widget.lines[i].key]!);
        state?.insertItem(i, duration: Motion.reduced(context) ? Duration.zero : const Duration(milliseconds: 340));
      }
    }
  }

  Widget _animated(_CartEntry e, Animation<double> a) {
    final curve = CurvedAnimation(parent: a, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return SizeTransition(
      sizeFactor: curve,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.16, 0), end: Offset.zero).animate(curve), child: _CartLineTile(line: e.line, total: e.total, onSwiped: () => _swiped.add(e.line.key))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedList(
        key: _list,
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
        initialItemCount: _items.length,
        itemBuilder: (c, i, a) => i < _items.length ? _animated(_items[i], a) : const SizedBox.shrink(),
      );
}

class _CartLineTile extends ConsumerStatefulWidget {
  const _CartLineTile({required this.line, required this.total, required this.onSwiped});
  final CartLine line;
  final int total;
  final VoidCallback onSwiped;

  @override
  ConsumerState<_CartLineTile> createState() => _CartLineTileState();
}

class _CartLineTileState extends ConsumerState<_CartLineTile> with SingleTickerProviderStateMixin {
  // A soft accent wash that fades out whenever the line changes, so the eye finds what just happened.
  late final AnimationController _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..value = 1;
  int _dir = 1; // +1 quantity went up, -1 went down: the number rolls the same way

  bool _announced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_announced) return;
    _announced = true;
    if (!Motion.reduced(context)) _flash.forward(from: 0); // a freshly added line announces itself
  }

  @override
  void didUpdateWidget(_CartLineTile old) {
    super.didUpdateWidget(old);
    final a = old.line, b = widget.line;
    if (a.qtyMilli != b.qtyMilli) _dir = b.qtyMilli >= a.qtyMilli ? 1 : -1;
    if (a.qtyMilli != b.qtyMilli || a.unitPriceP != b.unitPriceP || a.discountP != b.discountP || a.unit != b.unit) {
      if (!Motion.reduced(context)) _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final line = widget.line;
    final notifier = ref.read(cartProvider.notifier);
    final step = line.allowFraction ? 500 : 1000;
    final bn = context.lang == AppLang.bn;
    final name = line.variantLabel.isEmpty ? line.shownName(bn) : '${line.shownName(bn)} · ${line.variantLabel}';
    final qtyText = '${f.qty(line.qtyMilli)}${line.allowFraction || line.unit != 'pc' ? ' ${line.unit}' : ''}';

    Future<void> editQty() async {
      final q = await showQtySheet(context, title: line.shownName(bn), unit: line.unit, initialMilli: line.qtyMilli, allowFraction: line.allowFraction, maxMilli: line.stocked && !ref.read(ctxProvider).allowNegativeStock ? line.maxQtyMilli : null);
      if (q != null) {
        final r = notifier.setQty(line.key, q);
        if (r != null && context.mounted) toast(context, r.message, error: true);
      }
    }

    final content = AnimatedBuilder(
      animation: _flash,
      builder: (_, child) => DecoratedBox(
        decoration: BoxDecoration(color: Color.lerp(t.accent.withValues(alpha: t.dark ? 0.18 : 0.12), t.accent.withValues(alpha: 0), Curves.easeOut.transform(_flash.value)), borderRadius: BorderRadius.circular(14)),
        child: child,
      ),
      child: InkWell(
        onTap: () => showLineEditor(context, ref, line),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Monogram(line.shownName(bn), size: 42, seed: line.productId),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Text(name, style: tt.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 10),
                  CountUp(value: widget.total, duration: const Duration(milliseconds: 380), format: (v) => f.money(v, decimals: true), builder: (_, text) => NumText(text, size: 15, weight: 800)),
                ]),
                const SizedBox(height: 3),
                Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  NumText('${f.money(line.unitPriceP)} / ${line.unit}', size: 12, weight: 600, color: line.overridden ? t.warning : t.muted),
                  if (line.discountP > 0) Pill('−${f.money(line.discountP)}', color: t.success, dense: true),
                  if (line.overridden) Pill(context.tr('price changed'), color: t.warning, dense: true),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _QtyStepper(
                    text: qtyText,
                    dir: _dir,
                    onMinus: () => notifier.step(line.key, -step),
                    onPlus: () {
                      final r = notifier.step(line.key, step);
                      if (r != null) toast(context, r.message, error: true);
                    },
                    onEdit: editQty,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: context.tr('Remove'),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => notifier.remove(line.key),
                    icon: Icon(Icons.delete_outline_rounded, size: 20, color: t.muted),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Dismissible(
        key: ValueKey('line-${line.key}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          widget.onSwiped();
          notifier.remove(line.key);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(color: t.tint(t.danger, 0.14), borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.delete_rounded, color: t.danger),
        ),
        child: content,
      ),
    );
  }
}

/// − quantity + in one capsule. Tapping the number opens the keypad; the number itself rolls up or down as it changes.
class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.text, required this.dir, required this.onMinus, required this.onPlus, required this.onEdit});
  final String text;
  final int dir;
  final VoidCallback onMinus, onPlus, onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    Widget button(IconData icon, VoidCallback onTap) => InkResponse(
          radius: 22,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(width: 38, height: 36, child: Icon(icon, size: 19)),
        );
    return Container(
      height: 36,
      decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.outline)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        button(Icons.remove_rounded, onMinus),
        InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minWidth: 52),
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: Motion.fast,
                transitionBuilder: (c, a) {
                  final entering = c.key == ValueKey(text);
                  final from = Offset(0, entering ? 0.7 * dir : -0.7 * dir);
                  return FadeTransition(opacity: a, child: SlideTransition(position: Tween<Offset>(begin: from, end: Offset.zero).animate(a), child: c));
                },
                layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, if (current != null) current]),
                child: NumText(text, key: ValueKey(text), size: 15, weight: 800),
              ),
            ),
          ),
        ),
        button(Icons.add_rounded, onPlus),
      ]),
    );
  }
}
