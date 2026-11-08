import 'dart:async';

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

/// Signup requests by status: `{items: [...], counts: {pending, approved, rejected}}`.
final adminSignupsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, status) async {
  ref.cacheForSession(revalidate: true);
  return ref.watch(apiProvider).getMap('/admin/signups', query: {'limit': 100, 'status': status});
});

final _planChoicesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final d = await ref.watch(apiProvider).getMap('/admin/plans');
  return (d['plans'] as List).cast<Map<String, dynamic>>().where((p) => p['active'] != false).toList();
});

/// How many signup requests are waiting — the badge on the console's "Approvals" entry. Refreshes by itself.
class PendingApprovalsController extends Notifier<int> {
  /// How often to look again; null switches the timer off (tests).
  static Duration? pollEvery = const Duration(seconds: 45);
  Timer? _timer;

  @override
  int build() {
    ref.onDispose(() => _timer?.cancel());
    final every = pollEvery;
    if (every != null) _timer = Timer.periodic(every, (_) => refresh());
    Future.microtask(refresh);
    return 0;
  }

  Future<void> refresh() async {
    try {
      final d = await ref.read(apiProvider).getMap('/admin/signups', query: {'limit': 1, 'status': 'pending'});
      state = ((d['counts'] as Map)['pending'] as num?)?.toInt() ?? 0;
    } on ApiError {
      // keep the last known number
    }
  }
}

final pendingApprovalsProvider = NotifierProvider<PendingApprovalsController, int>(PendingApprovalsController.new);

class AdminApprovalsScreen extends ConsumerStatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  ConsumerState<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends ConsumerState<AdminApprovalsScreen> {
  String _status = 'pending';

  void _refresh() {
    ref.invalidate(adminSignupsProvider);
    ref.read(pendingApprovalsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final data = ref.watch(adminSignupsProvider(_status));
    final counts = ((data.value?['counts']) as Map?)?.cast<String, dynamic>() ?? const {};
    String label(String key, String text) {
      final n = (counts[key] as num?)?.toInt() ?? 0;
      return n > 0 ? '$text · ${f.intN(n)}' : text;
    }

    return PageBody(
      maxWidth: 900,
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegTabs<String>(
              items: [('pending', label('pending', context.tr('Waiting'))), ('approved', context.tr('Approved')), ('rejected', context.tr('Declined'))],
              value: _status,
              onChanged: (v) => setState(() => _status = v),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AsyncBody<Map<String, dynamic>>(
            value: data,
            onRetry: _refresh,
            data: (d) {
              final items = (d['items'] as List).cast<Map<String, dynamic>>();
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.how_to_reg_rounded,
                  title: _status == 'pending' ? context.tr('No requests waiting') : context.tr('Nothing here'),
                  message: _status == 'pending' ? context.tr('When someone signs up, their request appears here for you to approve and assign a package.') : null,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final r = items[i];
                  final s = r['status'] as String;
                  final c = switch (s) { 'approved' => t.success, 'rejected' => t.danger, _ => t.warning };
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Surface(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Monogram(r['business_name'] as String, size: 46),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r['business_name'] as String, style: tt.titleMedium),
                              Text('${f.digits(r['phone'] as String)} · ${f.dateTime(DateTime.parse(r['created_at'] as String))}', style: tt.bodySmall),
                            ]),
                          ),
                          Pill(context.tr(s == 'pending' ? 'Waiting' : (s == 'approved' ? 'Approved' : 'Declined')), color: c, dense: true),
                        ]),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(12), border: Border.all(color: t.outline)),
                          child: Column(children: [
                            KV(context.tr('Business type'), r['business_type_label'] as String, mono: false),
                            Row(children: [
                              Expanded(child: KV(context.tr('Phone number'), f.digits(r['phone'] as String))),
                              IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.copy_rounded, size: 17), onPressed: () async {
                                await Clipboard.setData(ClipboardData(text: r['phone'] as String));
                                if (context.mounted) toast(context, context.tr('Copied'), good: true);
                              }),
                            ]),
                            KV(context.tr('Language'), (r['language'] as String) == 'bn' ? 'বাংলা' : 'English', mono: false),
                            if (s == 'approved' && (r['plan_key'] as String).isNotEmpty) KV(context.tr('Package'), r['plan_key'] as String, mono: false, color: t.accentDeep),
                            if (s != 'pending' && (r['reviewed_by_name'] as String).isNotEmpty) KV(context.tr('Reviewed by'), r['reviewed_by_name'] as String, mono: false),
                            if (s == 'rejected') KV(context.tr('Reason'), (r['reject_reason'] as String).isEmpty ? '—' : r['reject_reason'] as String, mono: false, color: t.danger),
                          ]),
                        ),
                        if (s == 'pending') ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            Expanded(child: OutlinedButton.icon(onPressed: () => _reject(r), icon: Icon(Icons.close_rounded, size: 19, color: t.danger), label: Text(context.tr('Decline'), style: TextStyle(color: t.danger)))),
                            const SizedBox(width: 10),
                            Expanded(flex: 2, child: FilledButton.icon(onPressed: () => _approve(r), icon: const Icon(Icons.check_rounded, size: 20), label: Text(context.tr('Approve and assign package')))),
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
      ]),
    );
  }

  Future<void> _approve(Map<String, dynamic> r) async {
    final done = await showPanel<bool>(context, maxWidth: 560, builder: (_) => _ApprovePanel(request: r));
    if (done == true) {
      _refresh();
      if (mounted) toast(context, context.tr('Approved — the business is open'), good: true);
    }
  }

  Future<void> _reject(Map<String, dynamic> r) async {
    final done = await showPanel<bool>(context, maxWidth: 460, builder: (_) => _RejectPanel(request: r));
    if (done == true) {
      _refresh();
      if (mounted) toast(context, context.tr('Request declined'));
    }
  }
}

class _ApprovePanel extends ConsumerStatefulWidget {
  const _ApprovePanel({required this.request});
  final Map<String, dynamic> request;

  @override
  ConsumerState<_ApprovePanel> createState() => _ApprovePanelState();
}

class _ApprovePanelState extends ConsumerState<_ApprovePanel> {
  String? _plan;
  String _cycle = 'monthly';
  bool _samples = false, _busy = false;
  String? _error;
  final _trial = TextEditingController();

  @override
  void dispose() {
    _trial.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_plan == null) {
      setState(() => _error = context.tr('Choose the package to assign.'));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).post('/admin/signups/${widget.request['id']}/approve', body: {
        'plan_key': _plan,
        'billing_cycle': _cycle,
        if (_trial.text.trim().isNotEmpty) 'trial_days': int.tryParse(_trial.text.trim()) ?? 0,
        'sample_data': _samples,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final plans = ref.watch(_planChoicesProvider);
    return PanelScaffold(
      title: context.tr('Approve and assign package'),
      subtitle: '${widget.request['business_name']} · ${widget.request['business_type_label']}',
      footer: Row(children: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))),
        const Spacer(),
        FilledButton.icon(
          onPressed: _busy ? null : _submit,
          icon: _busy ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: t.onAccent)) : const Icon(Icons.check_rounded, size: 19),
          label: Text(context.tr('Approve and open business')),
        ),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FormHeading(context.tr('Package')),
        plans.when(
          loading: () => const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2.6))),
          error: (e, _) => Text(e is ApiError ? e.message : '$e', style: tt.bodyMedium!.copyWith(color: t.danger)),
          data: (list) => Column(children: [
            for (final p in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Surface(
                  onTap: () => setState(() => _plan = p['key'] as String),
                  color: _plan == p['key'] ? t.accentSoft : t.surface,
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Icon(_plan == p['key'] ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: _plan == p['key'] ? t.accent : t.faint),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name'] as String, style: tt.titleSmall),
                        if (((p['tagline'] as String?) ?? '').isNotEmpty) Text(p['tagline'] as String, style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        if (((p['trial_days'] as num?) ?? 0) > 0) Text(context.trf('{n} days free trial', {'n': f.intN((p['trial_days'] as num).toInt())}), style: tt.bodySmall!.copyWith(color: t.success)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      NumText(f.money(parsePaisa(p['monthly_price'])), size: 17, weight: 800),
                      Text(context.tr('/ month'), style: tt.bodySmall),
                    ]),
                  ]),
                ),
              ),
          ]),
        ),
        FormHeading(context.tr('Billing')),
        SegTabs<String>(items: [('monthly', context.tr('Monthly')), ('yearly', context.tr('Yearly'))], value: _cycle, onChanged: (v) => setState(() => _cycle = v)),
        const FormGap(),
        TextField(
          controller: _trial,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: context.tr('Free trial (days)'), helperText: context.tr('Leave empty to use the package default'), prefixIcon: const Icon(Icons.timer_outlined, size: 19)),
        ),
        const FormGap(),
        SwitchRow(title: context.tr('Load sample products'), subtitle: context.tr('A realistic starter catalogue for this type, so the till is not empty on day one'), value: _samples, onChanged: (v) => setState(() => _samples = v)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: tt.bodyMedium!.copyWith(color: t.danger)),
        ],
      ]),
    );
  }
}

class _RejectPanel extends ConsumerStatefulWidget {
  const _RejectPanel({required this.request});
  final Map<String, dynamic> request;

  @override
  ConsumerState<_RejectPanel> createState() => _RejectPanelState();
}

class _RejectPanelState extends ConsumerState<_RejectPanel> {
  final _reason = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(apiProvider).post('/admin/signups/${widget.request['id']}/reject', body: {'reason': _reason.text.trim()});
      if (mounted) Navigator.pop(context, true);
    } on ApiError catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final suggestions = [context.tr('Details are incomplete'), context.tr('We could not verify this business'), context.tr('Duplicate request')];
    return PanelScaffold(
      title: context.tr('Decline this request'),
      subtitle: context.tr('The applicant sees your reason and can correct their details and apply again.'),
      footer: Row(children: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false), child: Text(context.tr('Cancel'))),
        const Spacer(),
        FilledButton(onPressed: _busy ? null : _submit, style: FilledButton.styleFrom(backgroundColor: t.danger, foregroundColor: Colors.white), child: Text(context.tr('Decline'))),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _reason, autofocus: true, maxLength: 300, minLines: 2, maxLines: 4, decoration: InputDecoration(labelText: context.tr('Reason'), hintText: context.tr('Tell them what to fix, if you like'))),
        Wrap(spacing: 8, runSpacing: 6, children: [for (final s in suggestions) ActionChip(label: Text(s), onPressed: () => setState(() => _reason.text = s))]),
        if (_error != null) ...[const SizedBox(height: 10), Text(_error!, style: tt.bodyMedium!.copyWith(color: t.danger))],
      ]),
    );
  }
}
