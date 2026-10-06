import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/keypad.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../core/util/responsive.dart';
import '../../data/models/context.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import 'cart_controller.dart';

typedef PaidSale = ({SaleBundle bundle, int changeP});

Future<PaidSale?> showPaymentSheet(BuildContext context) =>
    showPanel<PaidSale>(context, maxWidth: 860, dismissible: false, builder: (_) => const _PaymentSheet());

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet();

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final List<NewPayment> _payments = [];
  String _method = 'cash';
  String _entry = '';
  final _ref = TextEditingController();
  bool _credit = false;
  bool _busy = false;

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  int get _applied => _payments.fold(0, (a, p) => a + p.amountP);

  void _key(String k) => setState(() => _entry = applyKey(_entry, k));

  Future<void> _complete(TenantContext ctx, int total) async {
    final cart = ref.read(cartProvider);
    final remaining = total - _applied;
    final entered = _entry.isEmpty ? null : parsePaisa(_entry);
    final finalPayments = [..._payments];
    var change = 0;

    if (_credit) {
      if (cart.customer == null) {
        toast(context, context.tr('Choose a customer to sell on credit.'), error: true);
        return;
      }
      if (entered != null && entered > 0) {
        finalPayments.add(NewPayment(_method, entered > remaining ? remaining : entered, reference: _ref.text.trim()));
      }
      final due = total - finalPayments.fold<int>(0, (a, p) => a + p.amountP);
      final c = cart.customer!;
      if (c.creditLimitP > 0 && c.balanceP + due > c.creditLimitP) {
        final ok = await confirmDialog(context,
            title: context.tr('Over the credit limit'),
            message: context.trf('{name} would owe {amount} against a limit of {limit}.', {'name': c.name, 'amount': context.fmt.money(c.balanceP + due), 'limit': context.fmt.money(c.creditLimitP)}),
            confirm: context.tr('Sell anyway'),
            danger: true);
        if (!ok || !mounted) return;
      }
    } else {
      final pay = entered ?? remaining;
      if (pay < remaining) {
        toast(context, context.tr('The amount received is less than what is left to pay.'), error: true);
        return;
      }
      if (remaining > 0) {
        finalPayments.add(NewPayment(_method, remaining, reference: _ref.text.trim()));
        if (_method == 'cash' && pay > remaining) change = pay - remaining;
      }
    }
    if (ctx.requireCustomer && cart.customer == null) {
      toast(context, context.trf('Choose a {word} first.', {'word': context.term(ctx, 'customer', 'customer').toLowerCase()}), error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      final bundle = await ref.read(salesRepoProvider).completeSale(SaleDraft(cart: cart, payments: finalPayments));
      if (mounted) Navigator.of(context).pop((bundle: bundle, changeP: change));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } catch (e) {
      if (mounted) toast(context, '${context.tr('Could not save the sale')}: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final cart = ref.watch(cartProvider);
    final priced = ref.watch(pricedCartProvider);
    final total = priced.total;
    final remaining = total - _applied;
    final entered = _entry.isEmpty ? null : parsePaisa(_entry);
    final tendered = entered ?? remaining;
    final change = (!_credit && _method == 'cash' && tendered > remaining) ? tendered - remaining : 0;
    final shortBy = (!_credit && tendered < remaining) ? remaining - tendered : 0;
    final method = ctx.enabledPaymentMethods.where((m) => m.code == _method).firstOrNull;
    final due = _credit ? (remaining - (entered ?? 0)).clamp(0, 1 << 40) : 0;
    final wide = context.width >= 720;

    final left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: t.accentSoft, borderRadius: BorderRadius.circular(R.card)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.tr(_payments.isEmpty ? 'Total to pay' : 'Left to pay'), style: tt.labelMedium!.copyWith(color: t.accentDeep)),
          const SizedBox(height: 4),
          NumText(f.money(remaining, decimals: true), size: 38, weight: 800),
          if (_payments.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final (i, p) in _payments.indexed)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(children: [
                  Icon(ctx.paymentMethods.where((m) => m.code == p.method).firstOrNull?.icon ?? Icons.payments_rounded, size: 16, color: t.accentDeep),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.methodName(ctx, p.method), style: tt.bodyMedium)),
                  NumText(f.money(p.amountP, decimals: true), size: 14),
                  InkWell(onTap: () => setState(() => _payments.removeAt(i)), child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close_rounded, size: 16))),
                ]),
              ),
          ],
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(R.card), border: Border.all(color: t.outline)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr(_credit ? 'Paid now (optional)' : (method?.kind == 'cash' ? 'Cash received' : 'Amount')), style: tt.labelMedium!.copyWith(color: t.muted)),
              const SizedBox(height: 2),
              NumText(_entry.isEmpty ? f.money(_credit ? 0 : remaining, symbol: true, decimals: true) : '${ctx.currencySymbol} ${f.digits(_entry)}', size: 28, weight: 800, color: _entry.isEmpty ? t.faint : t.text),
            ]),
          ),
          if (change > 0)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(context.tr('Change'), style: tt.labelMedium!.copyWith(color: t.success)),
              NumText(f.money(change, decimals: true), size: 24, weight: 800, color: t.success),
            ])
          else if (shortBy > 0 && _entry.isNotEmpty)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(context.tr('Short by'), style: tt.labelMedium!.copyWith(color: t.warning)),
              NumText(f.money(shortBy, decimals: true), size: 20, weight: 800, color: t.warning),
            ])
          else if (_credit)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(context.tr('On credit'), style: tt.labelMedium!.copyWith(color: t.warning)),
              NumText(f.money(due, decimals: true), size: 22, weight: 800, color: t.warning),
            ]),
        ]),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final q in _quick(remaining))
          ActionChip(label: Text(q == remaining ? context.tr('Exact') : f.money(q, symbol: false)), onPressed: () => setState(() => _entry = paisaToWire(q).replaceAll(RegExp(r'\.00$'), ''))),
      ]),
      const SizedBox(height: 12),
      Keypad(onKey: _key, dense: true),
    ]);

    final right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(context.tr('Pay with'), style: tt.titleSmall),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final m in ctx.enabledPaymentMethods)
          _MethodTile(label: context.methodName(ctx, m.code), icon: m.icon, color: m.color, selected: !_credit && _method == m.code, onTap: () => setState(() {
                _method = m.code;
                _credit = false;
              })),
        if (ctx.cap('customer_credit'))
          _MethodTile(label: context.tr('Credit (baki)'), icon: Icons.menu_book_rounded, color: t.warning, selected: _credit, onTap: () => setState(() => _credit = !_credit)),
      ]),
      if (method != null && method.needsReference && !_credit) ...[
        const SizedBox(height: 14),
        TextField(controller: _ref, decoration: InputDecoration(labelText: method.kind == 'mobile' ? context.tr('Transaction ID (TrxID)') : context.tr('Reference / slip no.'), prefixIcon: const Icon(Icons.tag_rounded, size: 19))),
      ],
      if (_credit) ...[
        const SizedBox(height: 14),
        Surface(
          color: t.tint(t.warning, 0.1),
          border: false,
          child: cart.customer == null
              ? Row(children: [Icon(Icons.person_off_rounded, color: t.warning), const SizedBox(width: 10), Expanded(child: Text(context.tr('Choose a customer on the sale screen first — the due is recorded on their account.'), style: tt.bodyMedium))])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cart.customer!.name, style: tt.titleSmall),
                  const SizedBox(height: 4),
                  Text('${context.tr('Currently owes')} ${f.money(cart.customer!.balanceP)}${cart.customer!.creditLimitP > 0 ? ' · ${context.tr('limit')} ${f.money(cart.customer!.creditLimitP)}' : ''}', style: tt.bodySmall),
                ]),
        ),
      ],
      const SizedBox(height: 14),
      if (entered != null && entered > 0 && entered < remaining && !_credit)
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _payments.add(NewPayment(_method, entered, reference: _ref.text.trim()));
            _entry = '';
            _ref.clear();
          }),
          icon: const Icon(Icons.call_split_rounded, size: 19),
          label: Text(context.trf('Take {amount} and split the rest', {'amount': f.money(entered)})),
        ),
    ]);

    final completeButton = FilledButton(
        onPressed: _busy ? null : () => _complete(ctx, total),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60), backgroundColor: _credit ? t.warning : t.accent, foregroundColor: _credit ? Colors.black : t.onAccent),
        child: _busy
            ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: t.onAccent))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.check_circle_rounded),
                const SizedBox(width: 10),
                Text(_credit ? '${context.tr('Sell on credit')} · ${f.money(due, decimals: true)}' : '${context.tr('Complete sale')} · ${f.money(total, decimals: true)}', style: const TextStyle(fontSize: 16.5)),
              ]),
      );

    return PanelScaffold(
      title: context.tr('Take payment'),
      footer: completeButton,
      subtitle: '${f.intN(cart.lines.length)} ${context.tr(cart.lines.length == 1 ? 'line' : 'lines')}${cart.customer == null ? '' : ' · ${cart.customer!.name}'}',
      child: wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 11, child: left), const SizedBox(width: 22), Expanded(flex: 10, child: right)])
          : Column(children: [left, const SizedBox(height: 20), right]),
    );
  }

  List<int> _quick(int remaining) {
    if (remaining <= 0) return const [];
    final out = <int>{remaining};
    for (final step in const [10000, 50000, 100000, 200000]) {
      final up = ((remaining + step - 1) ~/ step) * step;
      if (up > remaining) out.add(up);
    }
    return out.take(5).toList();
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: 124,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? t.tint(color, 0.14) : t.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : t.outline, width: selected ? 1.8 : 1),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 9),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text, fontVariations: const [FontVariation('wght', 700)]), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}
