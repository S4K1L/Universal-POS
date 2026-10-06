import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/kit.dart';
import '../../core/util/responsive.dart';
import '../../data/local/database.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';

final _queueProvider = StreamProvider.autoDispose<List<OutboxData>>((ref) => ref.watch(salesRepoProvider).watchOutbox());
final _doneProvider = StreamProvider.autoDispose<List<OutboxData>>((ref) => ref.watch(salesRepoProvider).watchRecentDone(limit: 25));

const _typeLabel = {
  'sale.create': ('Sale', Icons.receipt_long_rounded),
  'sale.return': ('Return', Icons.assignment_return_rounded),
  'sale.void': ('Void', Icons.block_rounded),
  'payment.receive': ('Payment received', Icons.payments_rounded),
  'customer.upsert': ('Customer', Icons.person_rounded),
  'stock.adjust': ('Stock change', Icons.inventory_2_rounded),
  'expense.create': ('Expense', Icons.account_balance_wallet_rounded),
  'shift.open': ('Shift opened', Icons.lock_open_rounded),
  'shift.close': ('Shift closed', Icons.lock_rounded),
};

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final s = ref.watch(syncProvider);
    final queue = ref.watch(_queueProvider).value ?? const [];
    final done = ref.watch(_doneProvider).value ?? const [];
    final api = ref.watch(apiProvider);
    final ctx = ref.watch(ctxProvider);
    final device = ref.watch(sessionProvider.select((s) => s.device));
    final failed = queue.where((q) => q.status == 'failed').toList();
    final waiting = queue.where((q) => q.status != 'failed').toList();
    final Color c = s.failed > 0 ? t.danger : (!s.online ? t.warning : (s.syncing ? t.info : t.success));
    final headline = s.failed > 0
        ? context.tr('Some items need your attention')
        : (!s.online ? context.tr('Working offline') : (s.syncing ? context.tr('Syncing…') : context.tr('Everything is up to date')));
    final sub = s.failed > 0
        ? context.tr('The server refused these items. Review them below — nothing has been lost.')
        : (!s.online
            ? '${f.intN(s.pending)} ${context.tr('items are saved on this till and will sync by themselves when the connection returns.')}'
            : (s.lastSync == null ? context.tr('Waiting for the first sync…') : '${context.tr('Last synced')} ${f.ago(s.lastSync!)}'));

    return ListView(
      padding: EdgeInsets.fromLTRB(context.isCompact ? 14 : 24, 4, context.isCompact ? 14 : 24, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Surface(
                color: t.tint(c, 0.08),
                border: false,
                padding: const EdgeInsets.all(22),
                child: Row(children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(color: t.tint(c, 0.16), shape: BoxShape.circle),
                    child: Icon(s.failed > 0 ? Icons.error_outline_rounded : (!s.online ? Icons.cloud_off_rounded : (s.syncing ? Icons.sync_rounded : Icons.cloud_done_rounded)), size: 30, color: c),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(headline, style: tt.headlineSmall), const SizedBox(height: 4), Text(sub, style: tt.bodyMedium!.copyWith(color: t.muted))])),
                ]),
              ),
              const SizedBox(height: 14),
              Wrap(spacing: 12, runSpacing: 12, children: [
                FilledButton.icon(onPressed: s.syncing ? null : () => ref.read(syncProvider.notifier).syncNow(), icon: const Icon(Icons.sync_rounded, size: 20), label: Text(context.tr('Sync now'))),
                OutlinedButton.icon(
                  onPressed: s.syncing
                      ? null
                      : () async {
                          final ok = await confirmDialog(context, title: context.tr('Re-download everything?'), message: context.tr('Your catalogue, customers and stock are fetched again from the server. Unsynced sales are kept.'), confirm: context.tr('Resync'));
                          if (ok) await ref.read(syncProvider.notifier).fullResync();
                        },
                  icon: const Icon(Icons.cloud_download_rounded, size: 20),
                  label: Text(context.tr('Full resync')),
                ),
              ]),
              const SizedBox(height: 18),
              Surface(
                child: Column(children: [
                  KV(context.tr('This till'), device == null ? '—' : '${device.name} · ${device.code}', mono: false),
                  KV(context.tr('Invoice numbers'), device == null ? '—' : 'INV-${device.code}-######', mono: false),
                  KV(context.tr('Server'), Uri.parse(api.baseUrl).authority),
                  KV(context.tr('Waiting to sync'), f.intN(s.pending)),
                  KV(context.tr('Subscription valid until'), f.date(ctx.validUntil)),
                ]),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: api.forceOffline,
                onChanged: (v) {
                  api.forceOffline = v;
                  ref.read(syncProvider.notifier).kick();
                  (context as Element).markNeedsBuild();
                },
                title: Text(context.tr('Work offline (test mode)')),
                subtitle: Text(context.tr('Pretend the internet is down to see how this till behaves. Turn it off to sync.')),
                contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                secondary: Icon(Icons.airplanemode_active_rounded, color: t.muted),
              ),
              if (failed.isNotEmpty) ...[
                const SizedBox(height: 18),
                Section(
                  title: context.tr('Needs attention'),
                  subtitle: context.tr('Retry after fixing the cause, or discard if it should not be sent.'),
                  child: Column(children: [for (final q in failed) _QueueRow(q, failed: true)]),
                ),
              ],
              const SizedBox(height: 18),
              Section(
                title: context.tr('Waiting to sync'),
                child: waiting.isEmpty
                    ? Surface(child: Row(children: [Icon(Icons.check_circle_rounded, color: t.success), const SizedBox(width: 10), Expanded(child: Text(context.tr('Nothing waiting — every sale has reached the server.'), style: tt.bodyMedium))]))
                    : Column(children: [for (final q in waiting) _QueueRow(q)]),
              ),
              if (done.isNotEmpty) ...[
                const SizedBox(height: 18),
                Section(title: context.tr('Recently synced'), child: Column(children: [for (final q in done.take(12)) _QueueRow(q, done: true)])),
              ],
            ]),
          ),
        ),
      ],
    );
  }
}

class _QueueRow extends ConsumerWidget {
  const _QueueRow(this.q, {this.failed = false, this.done = false});
  final OutboxData q;
  final bool failed, done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final meta = _typeLabel[q.type] ?? (q.type, Icons.sync_rounded);
    final c = failed ? t.danger : (done ? t.success : t.warning);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Surface(
        padding: const EdgeInsets.all(12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconSquare(meta.$2, color: c, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.summary.isEmpty ? context.tr(meta.$1) : q.summary, style: tt.titleSmall),
              Text('${context.tr(meta.$1)} · ${f.dateTime(q.occurredAt)}${q.attempts > 1 && !done ? ' · ${context.trf('{n} tries', {'n': f.intN(q.attempts)})}' : ''}', style: tt.bodySmall),
              if (failed && q.lastError != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(q.lastError!, style: tt.bodySmall!.copyWith(color: t.danger))),
            ]),
          ),
          if (failed) ...[
            TextButton(onPressed: () => ref.read(syncProvider.notifier).retry(q.id), child: Text(context.tr('Retry'))),
            TextButton(
              onPressed: () async {
                final ok = await confirmDialog(context, title: context.tr('Discard this item?'), message: context.tr('It will not be sent to the server. A sale stays in this till’s history but will never appear in your reports.'), confirm: context.tr('Discard'), danger: true);
                if (ok) await ref.read(syncProvider.notifier).discard(q.id);
              },
              child: Text(context.tr('Discard'), style: TextStyle(color: t.danger)),
            ),
          ] else
            Pill(done ? context.tr('Synced') : context.tr('Waiting'), color: c, dense: true),
        ]),
      ),
    );
  }
}
