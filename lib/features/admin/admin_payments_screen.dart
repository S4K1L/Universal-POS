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

final _requestsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, status) async => ref.watch(apiProvider).getMap('/admin/payment-requests', query: {'limit': 100, if (status != 'all') 'status': status}));
final _channelsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async => (await ref.watch(apiProvider).getList('/admin/payment-channels')).cast<Map<String, dynamic>>());
final _invoicesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async => ref.watch(apiProvider).getMap('/admin/invoices', query: {'limit': 100}));

class AdminPaymentsScreen extends ConsumerStatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  ConsumerState<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends ConsumerState<AdminPaymentsScreen> {
  String _tab = 'queue';
  String _status = 'pending';

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 980,
      child: Column(children: [
        Row(children: [
          SegTabs<String>(items: [('queue', context.tr('Review')), ('channels', context.tr('Where businesses pay')), ('invoices', context.tr('Invoices'))], value: _tab, onChanged: (v) => setState(() => _tab = v)),
          const Spacer(),
          if (_tab == 'channels') FilledButton.icon(onPressed: () => _editChannel(null), icon: const Icon(Icons.add_rounded, size: 20), label: Text(context.tr('Add account'))),
        ]),
        const SizedBox(height: 12),
        Expanded(child: switch (_tab) { 'channels' => _channels(context), 'invoices' => _invoices(context), _ => _queue(context) }),
      ]),
    );
  }

  Future<void> _editChannel(Map<String, dynamic>? c) async {
    final r = await showPanel<bool>(context, maxWidth: 520, builder: (_) => _ChannelForm(existing: c));
    if (r == true) ref.invalidate(_channelsProvider);
  }

  Widget _queue(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final data = ref.watch(_requestsProvider(_status));
    return Column(children: [
      Align(alignment: Alignment.centerLeft, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: SegTabs<String>(items: [('pending', context.tr('Waiting')), ('approved', context.tr('Approved')), ('rejected', context.tr('Rejected')), ('all', context.tr('All'))], value: _status, onChanged: (v) => setState(() => _status = v)))),
      const SizedBox(height: 10),
      Expanded(
        child: AsyncBody<Map<String, dynamic>>(
          value: data,
          onRetry: () => ref.invalidate(_requestsProvider(_status)),
          data: (d) {
            final items = (d['items'] as List).cast<Map<String, dynamic>>();
            if (items.isEmpty) return EmptyState(icon: Icons.inbox_rounded, title: context.tr('Nothing here'), message: _status == 'pending' ? context.tr('When a business pays and files its transaction ID, it shows up here for you to check against your statement.') : null);
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final r = items[i];
                final s = r['status'] as String;
                final c = switch (s) { 'approved' => t.success, 'rejected' => t.danger, 'pending' => t.warning, _ => t.faint };
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Surface(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Monogram(r['tenant_name'] as String, size: 44),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r['tenant_name'] as String, style: tt.titleMedium), Text('${r['reference']} · ${f.digits((r['tenant_phone'] as String?) ?? '')} · ${f.ago(DateTime.parse(r['created_at'] as String))}', style: tt.bodySmall)])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [NumText(f.money(parsePaisa(r['amount']), decimals: true), size: 22, weight: 800), Pill(context.tr(s[0].toUpperCase() + s.substring(1)), color: c, dense: true)]),
                      ]),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.outline)),
                        child: Column(children: [
                          KV(context.tr('Plan'), '${r['plan_name']} · ${context.tr(r['billing_cycle'] as String)}', mono: false),
                          KV(context.tr('Paid via'), r['channel_label'] as String, mono: false),
                          Row(children: [
                            Expanded(child: KV(context.tr('Transaction ID'), r['transaction_id'] as String)),
                            IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.copy_rounded, size: 17), onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: r['transaction_id'] as String));
                              if (context.mounted) toast(context, context.tr('Copied'), good: true);
                            }),
                          ]),
                          if ((r['sender_account'] as String).isNotEmpty) KV(context.tr('Sent from'), f.digits(r['sender_account'] as String)),
                          if (s == 'pending' && r['period_end_after'] != null) KV(context.tr('Access until, if approved'), f.date(DateTime.parse(r['period_end_after'] as String)), mono: false, color: t.accentDeep),
                          if ((r['note'] as String).isNotEmpty) KV(context.tr('Note'), r['note'] as String, mono: false),
                          if (s == 'rejected') KV(context.tr('Reason'), r['review_note'] as String, mono: false, color: t.danger),
                          if (s != 'pending' && (r['reviewed_by'] as String).isNotEmpty) KV(context.tr('Reviewed by'), r['reviewed_by'] as String, mono: false),
                        ]),
                      ),
                      if (s == 'pending') ...[
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(onPressed: () => _reject(r), icon: Icon(Icons.close_rounded, size: 19, color: t.danger), label: Text(context.tr('Reject'), style: TextStyle(color: t.danger)))),
                          const SizedBox(width: 10),
                          Expanded(flex: 2, child: FilledButton.icon(onPressed: () => _approve(r), icon: const Icon(Icons.check_rounded, size: 20), label: Text('${context.tr('Approve')} · ${f.money(parsePaisa(r['amount']))}'))),
                        ]),
                      ],
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  Future<void> _approve(Map<String, dynamic> r) async {
    final ok = await confirmDialog(context, title: context.tr('Approve this payment?'), message: context.trf('Check that {amount} with transaction {trx} is on your {channel} statement. The business gets its plan immediately.', {'amount': context.fmt.money(parsePaisa(r['amount']), decimals: true), 'trx': r['transaction_id'], 'channel': r['channel_label']}), confirm: context.tr('Approve'));
    if (!ok) return;
    try {
      await ref.read(apiProvider).post('/admin/payment-requests/${r['id']}/approve', body: {});
      ref.invalidate(_requestsProvider);
      if (mounted) toast(context, context.tr('Approved — subscription activated'), good: true);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    final reason = TextEditingController();
    final ok = await showPanel<bool>(
      context,
      maxWidth: 440,
      builder: (c) => PanelScaffold(
        title: context.tr('Reject this payment'),
        subtitle: context.tr('The business sees your reason and can correct and resubmit.'),
        footer: Row(children: [TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.tr('Cancel'))), const Spacer(), FilledButton(onPressed: () => Navigator.pop(c, true), style: FilledButton.styleFrom(backgroundColor: context.t.danger, foregroundColor: Colors.white), child: Text(context.tr('Reject')))]),
        child: TextField(controller: reason, autofocus: true, decoration: InputDecoration(labelText: context.tr('Reason'), hintText: context.tr('e.g. Amount does not match the statement'))),
      ),
    );
    if (ok != true) return;
    if (reason.text.trim().length < 3) return;
    try {
      await ref.read(apiProvider).post('/admin/payment-requests/${r['id']}/reject', body: {'reason': reason.text.trim()});
      ref.invalidate(_requestsProvider);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Widget _channels(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final data = ref.watch(_channelsProvider);
    return AsyncBody<List<Map<String, dynamic>>>(
      value: data,
      onRetry: () => ref.invalidate(_channelsProvider),
      data: (list) => list.isEmpty
          ? EmptyState(icon: Icons.account_balance_wallet_outlined, title: context.tr('No payment accounts'), message: context.tr('Add the bKash, Nagad or bank accounts businesses should pay into.'))
          : ListView(children: [
              for (final c in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Surface(
                    onTap: () => _editChannel(c),
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      IconSquare(c['kind'] == 'bank' ? Icons.account_balance_rounded : Icons.phone_android_rounded, color: _kindColor(c['kind'] as String), size: 44),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c['label'] as String, style: tt.titleSmall), Text('${c['account_name']} · ${context.fmt.digits(c['account_number'] as String)}', style: tt.bodySmall)])),
                      Pill(c['active'] == true ? context.tr('Live') : context.tr('Off'), color: c['active'] == true ? t.success : t.faint, dense: true),
                    ]),
                  ),
                ),
            ]),
    );
  }

  Color _kindColor(String k) => switch (k) { 'bkash' => const Color(0xFFE2136E), 'nagad' => const Color(0xFFF26A21), 'rocket' => const Color(0xFF8C3494), 'upay' => const Color(0xFF1B8C47), 'bank' => const Color(0xFF3B82F6), _ => const Color(0xFF64748B) };

  Widget _invoices(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final data = ref.watch(_invoicesProvider);
    return AsyncBody<Map<String, dynamic>>(
      value: data,
      onRetry: () => ref.invalidate(_invoicesProvider),
      data: (d) {
        final items = (d['items'] as List).cast<Map<String, dynamic>>();
        if (items.isEmpty) return EmptyState(icon: Icons.receipt_long_outlined, title: context.tr('No invoices yet'));
        return ListView(children: [
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Surface(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const IconSquare(Icons.receipt_long_rounded, size: 42),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${i['number']} · ${i['tenant_name']}', style: tt.titleSmall), Text('${i['plan_name']} · ${i['method']} · ${f.date(DateTime.parse(i['created_at'] as String))}', style: tt.bodySmall)])),
                  NumText(f.money(parsePaisa(i['amount']), decimals: true), size: 15, weight: 800),
                ]),
              ),
            ),
        ]);
      },
    );
  }
}

class _ChannelForm extends ConsumerStatefulWidget {
  const _ChannelForm({this.existing});
  final Map<String, dynamic>? existing;

  @override
  ConsumerState<_ChannelForm> createState() => _ChannelFormState();
}

class _ChannelFormState extends ConsumerState<_ChannelForm> {
  late String _kind = (widget.existing?['kind'] as String?) ?? 'bkash';
  late final _label = TextEditingController(text: widget.existing?['label'] as String?);
  late final _name = TextEditingController(text: widget.existing?['account_name'] as String?);
  late final _number = TextEditingController(text: widget.existing?['account_number'] as String?);
  late final _bank = TextEditingController(text: widget.existing?['bank_name'] as String?);
  late final _branch = TextEditingController(text: widget.existing?['branch_name'] as String?);
  late final _routing = TextEditingController(text: widget.existing?['routing_number'] as String?);
  late final _instr = TextEditingController(text: widget.existing?['instructions'] as String?);
  late String _wallet = (widget.existing?['wallet_type'] as String?) ?? '';
  late bool _active = widget.existing?['active'] != false;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return PanelScaffold(
      title: widget.existing == null ? context.tr('Add payment account') : (widget.existing!['label'] as String),
      footer: Row(children: [
        if (widget.existing != null)
          TextButton(
            onPressed: () async {
              if (!await confirmDialog(context, title: context.tr('Delete this account?'), message: context.tr('Past payments keep their record.'), confirm: context.tr('Delete'), danger: true)) return;
              await ref.read(apiProvider).delete('/admin/payment-channels/${widget.existing!['id']}');
              if (context.mounted) Navigator.pop(context, true);
            },
            child: Text(context.tr('Delete'), style: TextStyle(color: t.danger)),
          ),
        const Spacer(),
        FilledButton(
          onPressed: () async {
            final body = {'kind': _kind, 'label': _label.text.trim().isEmpty ? _kind : _label.text.trim(), 'account_name': _name.text.trim(), 'account_number': _number.text.trim(), 'wallet_type': _kind == 'bank' || _kind == 'bangla_qr' ? '' : _wallet, 'bank_name': _bank.text.trim(), 'branch_name': _branch.text.trim(), 'routing_number': _routing.text.trim(), 'instructions': _instr.text.trim(), 'active': _active, 'sort_order': widget.existing?['sort_order'] ?? 10};
            try {
              if (widget.existing == null) {
                await ref.read(apiProvider).post('/admin/payment-channels', body: body);
              } else {
                await ref.read(apiProvider).put('/admin/payment-channels/${widget.existing!['id']}', body: body);
              }
              if (context.mounted) Navigator.pop(context, true);
            } on ApiError catch (e) {
              if (context.mounted) toast(context, e.message, error: true);
            }
          },
          child: Text(context.tr('Save')),
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [for (final k in ['bkash', 'nagad', 'rocket', 'upay', 'bank', 'bangla_qr']) ChoiceChip(label: Text({'bkash': 'bKash', 'nagad': 'Nagad', 'rocket': 'Rocket', 'upay': 'Upay', 'bank': 'Bank', 'bangla_qr': 'Bangla QR'}[k]!), selected: _kind == k, onSelected: (_) => setState(() => _kind = k))]),
        const FormGap(),
        TextField(controller: _label, decoration: InputDecoration(labelText: context.tr('Shown to businesses as'), hintText: 'bKash Merchant')),
        const FormGap(),
        TextField(controller: _name, decoration: InputDecoration(labelText: context.tr('Account name'))),
        const FormGap(),
        TextField(controller: _number, decoration: InputDecoration(labelText: _kind == 'bank' ? context.tr('Account number') : context.tr('Wallet number'))),
        if (_kind != 'bank' && _kind != 'bangla_qr') ...[
          const FormGap(),
          Wrap(spacing: 8, children: [for (final w in ['personal', 'agent', 'merchant']) ChoiceChip(label: Text(context.tr(w[0].toUpperCase() + w.substring(1))), selected: _wallet == w, onSelected: (_) => setState(() => _wallet = w))]),
        ],
        if (_kind == 'bank') ...[const FormGap(), TextField(controller: _bank, decoration: InputDecoration(labelText: context.tr('Bank'))), const FormGap(), Row(children: [Expanded(child: TextField(controller: _branch, decoration: InputDecoration(labelText: context.tr('Branch')))), const SizedBox(width: 10), Expanded(child: TextField(controller: _routing, decoration: InputDecoration(labelText: context.tr('Routing no.'))))])],
        const FormGap(),
        TextField(controller: _instr, maxLines: 2, decoration: InputDecoration(labelText: context.tr('Instructions shown at checkout'))),
        const FormGap(),
        SwitchRow(title: context.tr('Live'), subtitle: context.tr('Only live accounts are offered to businesses'), value: _active, onChanged: (v) => setState(() => _active = v)),
      ]),
    );
  }
}
