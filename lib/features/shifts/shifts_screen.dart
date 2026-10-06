import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';

final _shiftProvider = FutureProvider.autoDispose<({Map<String, dynamic>? shift, int expected, int cashIn, int cashOut, int sales, int invoices})>((ref) async {
  ref.watch(syncProvider.select((s) => s.pending));
  final repo = ref.watch(salesRepoProvider);
  final shift = await repo.currentShift();
  final totals = await repo.shiftTotals();
  return (shift: shift, expected: totals.expected, cashIn: totals.cashIn, cashOut: totals.cashOut, sales: totals.sales, invoices: totals.invoices);
});

final _shiftHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(syncProvider.select((s) => s.revision));
  return (await ref.watch(apiProvider).getList('/shifts')).cast<Map<String, dynamic>>();
});

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final cur = ref.watch(_shiftProvider);
    final hist = ref.watch(_shiftHistoryProvider);
    return PageBody(
      maxWidth: 820,
      child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
        cur.when(
          loading: () => const SkeletonList(rows: 2, height: 100),
          error: (e, _) => ErrorView(error: e),
          data: (s) {
            final open = s.shift != null;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Surface(
                color: open ? t.tint(t.success, 0.08) : t.surface,
                border: !open,
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    IconSquare(open ? Icons.lock_open_rounded : Icons.lock_rounded, color: open ? t.success : t.muted, size: 46),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(open ? context.tr('Shift is open') : context.tr('No shift open'), style: tt.headlineSmall), Text(open ? '${context.tr('Since')} ${f.dateTime(DateTime.parse(s.shift!['opened_at'] as String))} · ${s.shift!['opened_by']}' : context.tr('Open a shift to count the cash drawer at the start and end of your day.'), style: tt.bodyMedium!.copyWith(color: t.muted))])),
                  ]),
                  const SizedBox(height: 16),
                  if (open) ...[
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      for (final (label, v, c) in [('Opening float', s.shift!['opening_float'] as int, t.muted), ('Cash taken', s.cashIn, t.success), ('Paid out', s.cashOut, t.warning), ('Should be in the drawer', s.expected, t.accentDeep)])
                        Container(width: 170, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.outline)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr(label), style: tt.labelSmall), const SizedBox(height: 4), NumText(f.money(v, decimals: true), size: 19, weight: 800, color: c)])),
                    ]),
                    const SizedBox(height: 10),
                    Text('${f.intN(s.invoices)} ${context.tr('invoices')} · ${f.money(s.sales)} ${context.tr('sold this shift')}', style: tt.bodyMedium),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: () => showPanel<void>(context, maxWidth: 440, builder: (_) => _CloseShift(expected: s.expected)), icon: const Icon(Icons.lock_rounded, size: 19), label: Text(context.tr('Close shift & count cash'))),
                  ] else
                    FilledButton.icon(onPressed: ctx.can('manage_shifts') ? () => showPanel<void>(context, maxWidth: 420, builder: (_) => const _OpenShift()) : null, icon: const Icon(Icons.lock_open_rounded, size: 19), label: Text(context.tr('Open shift'))),
                ]),
              ),
            ]);
          },
        ),
        const SizedBox(height: 22),
        Section(
          title: context.tr('Previous shifts'),
          child: hist.when(
            loading: () => const SkeletonList(rows: 3, height: 60),
            error: (e, _) => Text(context.tr('History loads when you are online.'), style: tt.bodySmall),
            data: (rows) => rows.where((r) => r['status'] == 'closed').isEmpty
                ? Text(context.tr('No closed shifts yet.'), style: tt.bodyMedium!.copyWith(color: t.muted))
                : Column(children: [
                    for (final r in rows.where((r) => r['status'] == 'closed'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Surface(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${f.dateTime(DateTime.parse(r['opened_at'] as String))} → ${f.time(DateTime.parse(r['closed_at'] as String))}', style: tt.titleSmall), Text(r['opened_by'] as String, style: tt.bodySmall)])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              NumText(f.money(parsePaisa(r['counted_cash']), decimals: true), size: 15, weight: 800),
                              Pill(parsePaisa(r['variance']) == 0 ? context.tr('Balanced') : '${parsePaisa(r['variance']) > 0 ? context.tr('Over') : context.tr('Short')} ${f.money(parsePaisa(r['variance']).abs())}', color: parsePaisa(r['variance']) == 0 ? t.success : (parsePaisa(r['variance']) > 0 ? t.info : t.danger), dense: true),
                            ]),
                          ]),
                        ),
                      ),
                  ]),
          ),
        ),
      ]),
    );
  }
}

class _OpenShift extends ConsumerStatefulWidget {
  const _OpenShift();

  @override
  ConsumerState<_OpenShift> createState() => _OpenShiftState();
}

class _OpenShiftState extends ConsumerState<_OpenShift> {
  final _float = TextEditingController();

  @override
  Widget build(BuildContext context) => PanelScaffold(
        title: context.tr('Open shift'),
        subtitle: context.tr('How much cash is in the drawer right now?'),
        footer: FilledButton(
          onPressed: () async {
            await ref.read(salesRepoProvider).openShift(paisaOf(_float));
            ref.invalidate(_shiftProvider);
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(context.tr('Open shift')),
        ),
        child: MoneyField(controller: _float, label: context.tr('Opening float'), symbol: ref.watch(ctxProvider).currencySymbol, autofocus: true),
      );
}

class _CloseShift extends ConsumerStatefulWidget {
  const _CloseShift({required this.expected});
  final int expected;

  @override
  ConsumerState<_CloseShift> createState() => _CloseShiftState();
}

class _CloseShiftState extends ConsumerState<_CloseShift> {
  final _counted = TextEditingController();
  final _note = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final f = context.fmt;
    final counted = paisaOf(_counted);
    final diff = counted - widget.expected;
    return PanelScaffold(
      title: context.tr('Close shift'),
      subtitle: context.tr('Count the drawer, then type what you counted.'),
      footer: FilledButton(
        onPressed: _counted.text.trim().isEmpty
            ? null
            : () async {
                final v = await ref.read(salesRepoProvider).closeShift(counted, note: _note.text.trim());
                ref.invalidate(_shiftProvider);
                if (context.mounted) {
                  Navigator.pop(context);
                  toast(context, v == 0 ? context.tr('Shift closed — the drawer balances') : '${context.tr('Shift closed')} · ${v > 0 ? context.tr('over') : context.tr('short')} ${f.money(v.abs())}', good: v == 0);
                }
              },
        child: Text(context.tr('Close shift')),
      ),
      child: Column(children: [
        MoneyField(controller: _counted, label: context.tr('Cash counted'), symbol: ref.watch(ctxProvider).currencySymbol, autofocus: true, onChanged: (_) => setState(() {})),
        if (_counted.text.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Surface(color: t.tint(diff == 0 ? t.success : t.warning, 0.1), border: false, child: Row(children: [Icon(diff == 0 ? Icons.check_circle_rounded : Icons.balance_rounded, color: diff == 0 ? t.success : t.warning), const SizedBox(width: 10), Expanded(child: Text(diff == 0 ? context.tr('Exactly right.') : context.trf(diff > 0 ? 'Over by {amount} against what the till expects ({expected}).' : 'Short by {amount} against what the till expects ({expected}).', {'amount': f.money(diff.abs(), decimals: true), 'expected': f.money(widget.expected, decimals: true)})))]))),
        const FormGap(),
        TextField(controller: _note, decoration: InputDecoration(labelText: context.tr('Note (optional)'), prefixIcon: const Icon(Icons.notes_rounded, size: 19))),
      ]),
    );
  }
}
