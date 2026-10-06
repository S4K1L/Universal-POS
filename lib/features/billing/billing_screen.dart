import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/session.dart';

final _billingProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiProvider);
  final r = await Future.wait<Object>([api.getMap('/billing/subscription'), api.getMap('/billing/plans'), api.getList('/billing/payment-requests')]);
  return {'sub': r[0], 'plans': r[1], 'requests': r[2]};
});

String _limitText(BuildContext context, int v) => v < 0 ? context.tr('Unlimited') : context.fmt.intN(v);

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _cycle = 'monthly';

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final data = ref.watch(_billingProvider);
    return PageBody(
      maxWidth: 1000,
      child: AsyncBody<Map<String, dynamic>>(
        value: data,
        onRetry: () => ref.invalidate(_billingProvider),
        data: (d) {
          final sub = (d['sub'] as Map).cast<String, dynamic>();
          final plans = ((d['plans'] as Map)['plans'] as List).cast<Map<String, dynamic>>();
          final requests = (d['requests'] as List).cast<Map<String, dynamic>>();
          final current = ((d['plans'] as Map)['current']) as String;
          final plan = (sub['plan'] as Map).cast<String, dynamic>();
          final usage = (sub['usage'] as Map).cast<String, dynamic>();
          final limits = (plan['limits'] as Map).cast<String, dynamic>();
          final state = sub['state'] as String;
          final c = state == 'active' ? t.success : (state == 'trialing' ? t.info : t.danger);
          final pending = requests.where((r) => r['status'] == 'pending').firstOrNull;
          final invoices = (sub['invoices'] as List).cast<Map<String, dynamic>>();
          return ListView(padding: const EdgeInsets.only(bottom: 30), children: [
            Surface(
              color: t.tint(c, 0.07),
              border: false,
              padding: const EdgeInsets.all(22),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconSquare(Icons.workspace_premium_rounded, color: c, size: 52),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Text('${plan['name']} ${context.tr('plan')}', style: tt.headlineSmall), const SizedBox(width: 10), Pill(context.tr(state == 'grace' ? 'Grace period' : state[0].toUpperCase() + state.substring(1)), color: c)]),
                    const SizedBox(height: 4),
                    Text(state == 'trialing' ? '${f.intN(sub['days_left'] as int)} ${context.tr('trial days left')} · ${context.tr('ends')} ${f.date(DateTime.parse(sub['period_end'] as String))}' : '${context.tr('Paid until')} ${f.date(DateTime.parse(sub['period_end'] as String))}${(sub['days_left'] as int) > 0 ? ' · ${f.intN(sub['days_left'] as int)} ${context.tr('days left')}' : ''}', style: tt.bodyMedium!.copyWith(color: t.muted)),
                  ])),
                ]),
                const SizedBox(height: 18),
                Wrap(spacing: 14, runSpacing: 12, children: [
                  for (final k in ['products', 'staff', 'branches', 'devices'])
                    SizedBox(
                      width: 200,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [Expanded(child: Text(context.tr(k[0].toUpperCase() + k.substring(1)), style: tt.labelMedium!.copyWith(color: t.muted))), Text('${f.intN((usage[k] as num).toInt())} / ${_limitText(context, (limits[k] as num?)?.toInt() ?? -1)}', style: tt.labelMedium)]),
                        const SizedBox(height: 6),
                        ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: ((limits[k] as num?) ?? -1) < 0 ? 0.04 : ((usage[k] as num) / ((limits[k] as num) == 0 ? 1 : limits[k] as num)).clamp(0.0, 1.0).toDouble(), minHeight: 7, color: ((limits[k] as num?) ?? -1) >= 0 && (usage[k] as num) >= (limits[k] as num) ? t.danger : t.accent, backgroundColor: t.outline)),
                      ]),
                    ),
                ]),
              ]),
            ),
            if (pending != null) ...[
              const SizedBox(height: 14),
              Surface(
                color: t.tint(t.warning, 0.1),
                border: false,
                child: Row(children: [
                  Icon(Icons.hourglass_top_rounded, color: t.warning),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.trf('Payment {ref} is being checked', {'ref': pending['reference']}), style: tt.titleSmall), Text('${pending['plan_name']} · ${f.money(parsePaisa(pending['amount']))} · ${context.trf('we confirm it against the {channel} statement, usually within a few hours.', {'channel': pending['channel_label']})}', style: tt.bodySmall)])),
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref.read(apiProvider).post('/billing/payment-requests/${pending['id']}/cancel');
                        ref.invalidate(_billingProvider);
                      } on ApiError catch (e) {
                        if (context.mounted) toast(context, e.message, error: true);
                      }
                    },
                    child: Text(context.tr('Withdraw')),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 22),
            Row(children: [
              Expanded(child: Text(context.tr('Plans'), style: tt.headlineSmall)),
              SegTabs<String>(items: [('monthly', context.tr('Monthly')), ('yearly', context.tr('Yearly'))], value: _cycle, onChanged: (v) => setState(() => _cycle = v)),
            ]),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth > 860 ? plans.length.clamp(1, 3) : 1;
              final w = (box.maxWidth - 14 * (cols - 1)) / cols;
              return Wrap(spacing: 14, runSpacing: 14, children: [
                for (final p in plans)
                  SizedBox(
                    width: w,
                    child: _PlanCard(
                      plan: p,
                      cycle: _cycle,
                      current: p['key'] == current,
                      onPay: ctx.can('manage_subscription') && pending == null ? () => _pay(context, p) : null,
                    ),
                  ),
              ]);
            }),
            if (requests.isNotEmpty) ...[
              const SizedBox(height: 22),
              Section(title: context.tr('Payment history'), child: Column(children: [for (final r in requests.take(10)) _RequestRow(r)])),
            ],
            if (invoices.isNotEmpty) ...[
              const SizedBox(height: 22),
              Section(
                title: context.tr('Invoices'),
                child: Column(children: [
                  for (final i in invoices.take(12))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Surface(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          const IconSquare(Icons.receipt_long_rounded, size: 40),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${i['number']} · ${i['plan_name']}', style: tt.titleSmall), Text('${f.date(DateTime.parse(i['period_start'] as String))} → ${f.date(DateTime.parse(i['period_end'] as String))} · ${i['method']}', style: tt.bodySmall)])),
                          NumText(f.money(parsePaisa(i['amount']), decimals: true), size: 15, weight: 800),
                        ]),
                      ),
                    ),
                ]),
              ),
            ],
          ]);
        },
      ),
    );
  }

  Future<void> _pay(BuildContext context, Map<String, dynamic> plan) async {
    final ok = await showPanel<bool>(context, maxWidth: 560, builder: (_) => _PayPanel(plan: plan, cycle: _cycle));
    if (ok == true) {
      ref.invalidate(_billingProvider);
      if (context.mounted) toast(context, context.tr('Thanks — we are checking your payment'), good: true);
    }
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.cycle, required this.current, required this.onPay});
  final Map<String, dynamic> plan;
  final String cycle;
  final bool current;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final price = parsePaisa(cycle == 'yearly' ? plan['yearly_price'] : plan['monthly_price']);
    final monthlyEq = cycle == 'yearly' ? price ~/ 12 : price;
    final saving = cycle == 'yearly' ? parsePaisa(plan['monthly_price']) * 12 - price : 0;
    final limits = (plan['limits'] as Map).cast<String, dynamic>();
    final features = (plan['features'] as List).cast<String>();
    final hl = plan['highlight'] == true;
    return Surface(
      color: hl ? t.accentSoft : t.surface,
      raised: hl,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(plan['name'] as String, style: tt.headlineSmall)), if (current) Pill(context.tr('Current'), color: t.success) else if (hl) Pill(context.tr('Popular'), color: t.accent, filled: true)]),
        if ((plan['tagline'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(plan['tagline'] as String, style: tt.bodySmall)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [NumText(f.money(price), size: 34, weight: 800), const SizedBox(width: 6), Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(cycle == 'yearly' ? context.tr('/ year') : context.tr('/ month'), style: tt.bodySmall))]),
        if (cycle == 'yearly' && saving > 0) Padding(padding: const EdgeInsets.only(top: 2), child: Text('${f.money(monthlyEq)}/${context.tr('mo')} · ${context.tr('save')} ${f.money(saving)}', style: tt.bodySmall!.copyWith(color: t.success, fontWeight: FontWeight.w700))),
        const SizedBox(height: 14),
        for (final k in ['products', 'staff', 'branches', 'devices'])
          _Feat('${_limitText(context, (limits[k] as num?)?.toInt() ?? -1)} ${context.tr(k)}'),
        const Divider(height: 22),
        for (final x in features.take(8)) _Feat(context.tr(_featureLabel[x] ?? x)),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: current
              ? OutlinedButton(onPressed: onPay, child: Text(context.tr('Renew')))
              : FilledButton(onPressed: onPay, child: Text('${context.tr('Choose')} ${plan['name']}')),
        ),
      ]),
    );
  }
}

const _featureLabel = {
  'pos': 'Point of sale',
  'inventory': 'Inventory & catalogue',
  'purchases': 'Purchases & suppliers',
  'customers': 'Customers & due ledger',
  'reports': 'Standard reports',
  'reports_advanced': 'Advanced reports',
  'offline_sync': 'Offline selling with auto-sync',
  'multi_branch': 'Multiple branches',
  'staff': 'Staff accounts & roles',
  'expenses': 'Expenses & day book',
  'export': 'Data export',
  'orders': 'Orders & quotations',
};

class _Feat extends StatelessWidget {
  const _Feat(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [Icon(Icons.check_rounded, size: 18, color: context.t.accent), const SizedBox(width: 8), Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium))]),
      );
}

class _RequestRow extends StatelessWidget {
  const _RequestRow(this.r);
  final Map<String, dynamic> r;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final s = r['status'] as String;
    final c = switch (s) { 'approved' => t.success, 'rejected' => t.danger, 'pending' => t.warning, _ => t.faint };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Surface(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconSquare(Icons.payments_rounded, color: c, size: 40),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${r['reference']} · ${r['plan_name']} (${context.tr(r['billing_cycle'] as String)})', style: tt.titleSmall), Text('${r['channel_label']} · ${r['transaction_id']} · ${f.dateTime(DateTime.parse(r['created_at'] as String))}', style: tt.bodySmall)])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [NumText(f.money(parsePaisa(r['amount']), decimals: true), size: 15, weight: 800), Pill(context.tr(s[0].toUpperCase() + s.substring(1)), color: c, dense: true)]),
          ]),
          if (s == 'rejected' && (r['review_note'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${context.tr('Reason')}: ${r['review_note']}', style: tt.bodySmall!.copyWith(color: t.danger))),
        ]),
      ),
    );
  }
}

class _PayPanel extends ConsumerStatefulWidget {
  const _PayPanel({required this.plan, required this.cycle});
  final Map<String, dynamic> plan;
  final String cycle;

  @override
  ConsumerState<_PayPanel> createState() => _PayPanelState();
}

class _PayPanelState extends ConsumerState<_PayPanel> {
  List<Map<String, dynamic>> _channels = [];
  String? _channel;
  final _sender = TextEditingController();
  final _txn = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    ref.read(apiProvider).getList('/billing/payment-channels').then((l) {
      if (mounted) {
        setState(() {
          _channels = l.cast<Map<String, dynamic>>();
          _channel = _channels.isEmpty ? null : _channels.first['id'] as String;
        });
      }
    }).catchError((e) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final amount = parsePaisa(widget.cycle == 'yearly' ? widget.plan['yearly_price'] : widget.plan['monthly_price']);
    final ch = _channels.where((c) => c['id'] == _channel).firstOrNull;
    return PanelScaffold(
      title: context.trf('Pay for {plan}', {'plan': widget.plan['name']}),
      subtitle: '${f.money(amount, decimals: true)} · ${context.tr(widget.cycle)}',
      footer: FilledButton(
        onPressed: _busy || _channel == null || _txn.text.trim().length < 4
            ? null
            : () async {
                setState(() => _busy = true);
                try {
                  await ref.read(apiProvider).post('/billing/payment-requests', body: {'plan_key': widget.plan['key'], 'billing_cycle': widget.cycle, 'channel_id': _channel, 'sender_account': _sender.text.trim(), 'transaction_id': _txn.text.trim(), 'note': _note.text.trim()});
                  if (context.mounted) Navigator.pop(context, true);
                } on ApiError catch (e) {
                  if (context.mounted) toast(context, e.message, error: true);
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
        child: Text(context.tr('I have paid — submit')),
      ),
      child: _error != null
          ? ErrorView(error: _error!)
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('1. ${context.trf('Send exactly {amount} to one of these accounts', {'amount': f.money(amount, decimals: true)})}', style: tt.titleSmall),
              const SizedBox(height: 10),
              for (final c in _channels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Surface(
                    onTap: () => setState(() => _channel = c['id'] as String),
                    color: _channel == c['id'] ? t.accentSoft : t.surface,
                    padding: const EdgeInsets.all(14),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(_channel == c['id'] ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: _channel == c['id'] ? t.accent : t.faint),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['label'] as String, style: tt.titleSmall),
                        if ((c['account_name'] as String).isNotEmpty) Text(c['account_name'] as String, style: tt.bodySmall),
                        if ((c['account_number'] as String).isNotEmpty)
                          Row(children: [
                            NumText(f.digits(c['account_number'] as String), size: 18, weight: 800),
                            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.copy_rounded, size: 17), onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: c['account_number'] as String));
                              if (context.mounted) toast(context, context.tr('Copied'), good: true);
                            }),
                          ]),
                        if ((c['bank_name'] as String).isNotEmpty) Text('${c['bank_name']} · ${c['branch_name']} · ${c['routing_number']}', style: tt.bodySmall),
                        if ((c['instructions'] as String).isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(c['instructions'] as String, style: tt.bodySmall)),
                      ])),
                    ]),
                  ),
                ),
              const FormGap(6),
              Text('2. ${context.tr('Tell us what you sent')}', style: tt.titleSmall),
              const SizedBox(height: 10),
              TextField(controller: _txn, onChanged: (_) => setState(() {}), decoration: InputDecoration(labelText: context.tr('Transaction ID (TrxID)'), prefixIcon: const Icon(Icons.tag_rounded, size: 19))),
              const FormGap(),
              TextField(controller: _sender, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Number you paid from'), prefixIcon: const Icon(Icons.phone_rounded, size: 19))),
              const FormGap(),
              TextField(controller: _note, decoration: InputDecoration(labelText: context.tr('Note (optional)'))),
              if (ch != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(context.tr('Your plan changes the moment we confirm the payment — nothing before that.'), style: tt.bodySmall)),
            ]),
    );
  }
}
