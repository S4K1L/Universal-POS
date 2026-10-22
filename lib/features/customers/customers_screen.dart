import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../core/util/responsive.dart';
import '../../data/local/database.dart';
import '../../data/models/context.dart';
import '../../data/providers.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';
import '../../data/sync/sync_engine.dart';

class _CustomerRow {
  _CustomerRow(this.c, this.pendingP);
  final LCustomer c;
  final int pendingP;
  int get balanceP => c.balanceP + pendingP;
}

final _customersProvider = StreamProvider.autoDispose<List<_CustomerRow>>((ref) async* {
  ref.cacheForSession();
  final db = ref.watch(dbProvider);
  final repo = ref.watch(salesRepoProvider);
  final trigger = db.customSelect('SELECT 1', readsFrom: {db.lCustomers, db.outbox}).watch();
  await for (final _ in trigger) {
    final rows = await (db.select(db.lCustomers)
          ..where((c) => c.active.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .get();
    final pending = await repo.pendingCustomerDeltas();
    yield [for (final c in rows) _CustomerRow(c, pending[c.id] ?? 0)];
  }
});

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final _q = TextEditingController();
  bool _owing = false;

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
    final all = ref.watch(_customersProvider);
    final word = context.term(ctx, 'customer', 'Customer');
    final canEdit = ctx.can('manage_customers');
    final credit = ctx.cap('customer_credit');

    return PageBody(
      maxWidth: 1000,
      child: FadeSwitcher(child: all.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Deferred(child: SkeletonList(rows: 6)),
        error: (e, _) => ErrorView(error: e),
        data: (rows) {
          final q = _q.text.trim().toLowerCase();
          final list = rows.where((r) => (q.isEmpty || r.c.name.toLowerCase().contains(q) || r.c.phone.contains(q)) && (!_owing || r.balanceP > 0)).toList();
          final owed = rows.fold<int>(0, (a, r) => a + (r.balanceP > 0 ? r.balanceP : 0));
          final owing = rows.where((r) => r.balanceP > 0).length;
          return Column(children: [
            if (credit)
              CardGrid(minWidth: 150, gap: 12, children: [
                StatTile(label: context.term(ctx, 'due', 'Due'), value: f.money(owed), icon: Icons.menu_book_rounded, color: t.warning, hint: context.trf('{n} owe you money', {'n': f.intN(owing)})),
                StatTile(label: '${word}s', value: f.intN(rows.length), icon: Icons.groups_rounded, hint: ctx.loyaltyOn ? '${f.intN(rows.fold(0, (a, r) => a + r.c.points))} ${context.tr('points issued')}' : null),
              ]),
            if (credit) const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AppSearchField(controller: _q, hint: context.tr('Search by name or phone'), onChanged: (_) => setState(() {}))),
              if (canEdit) ...[
                const SizedBox(width: 10),
                SizedBox(height: 50, child: FilledButton.icon(onPressed: () => showCustomerForm(context, ref), icon: const Icon(Icons.person_add_rounded, size: 20), label: Text(context.isCompact ? '' : '${context.tr('New')} $word'))),
              ],
            ]),
            if (credit) ...[
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerLeft, child: IntrinsicWidth(child: SegTabs<bool>(items: [(false, context.tr('Everyone')), (true, context.tr('Owing'))], value: _owing, onChanged: (v) => setState(() => _owing = v)))),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: Icons.groups_rounded, title: context.tr('No one here yet'), message: context.trf('Add a {word} to track what they buy and owe.', {'word': word.toLowerCase()}))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _CustomerTile(row: list[i], ctx: ctx, onTap: () => showCustomerDetail(context, ref, list[i].c.id)),
                    ),
            ),
          ]);
        },
      )),
    );
  }
}

/// One customer in the list. Name and phone take the room that is left and truncate; the points and balance sit in
/// fixed columns on wide screens (so their edges line up down the list) and stack on the right on narrow ones.
class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.row, required this.ctx, required this.onTap});
  final _CustomerRow row;
  final TenantContext ctx;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final compact = context.isCompact;
    final c = row.c;
    final pts = ctx.loyaltyOn && c.points > 0 ? Pill('${f.intN(c.points)} ${context.tr('pts')}', color: t.info, dense: true, icon: Icons.stars_rounded) : null;
    final bal = row.balanceP > 0
        ? Pill('${context.tr('owes')} ${f.money(row.balanceP)}', color: t.warning)
        : row.balanceP < 0
            ? Pill('${context.tr('credit')} ${f.money(-row.balanceP)}', color: t.success)
            : null;
    final pending = row.pendingP != 0 ? Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.schedule_rounded, size: 16, color: t.info)) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Surface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Monogram(c.name, size: 44, round: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: tt.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (c.phone.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(f.digits(c.phone), style: tt.bodySmall, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis)),
            ]),
          ),
          const SizedBox(width: 10),
          if (compact)
            Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              if (bal != null) Row(mainAxisSize: MainAxisSize.min, children: [if (pending != null) pending, bal]) else if (pending != null) pending,
              if (pts != null) Padding(padding: EdgeInsets.only(top: bal == null ? 0 : 6), child: pts),
            ])
          else ...[
            if (ctx.loyaltyOn) SizedBox(width: 96, child: Align(alignment: Alignment.centerRight, child: pts)),
            SizedBox(width: 190, child: Align(alignment: Alignment.centerRight, child: Row(mainAxisSize: MainAxisSize.min, children: [if (pending != null) pending, if (bal != null) bal]))),
          ],
        ]),
      ),
    );
  }
}

// ------------------------------------------------------------------------------------------- form

Future<void> showCustomerForm(BuildContext context, WidgetRef ref, {LCustomer? existing}) =>
    showPanel<void>(context, maxWidth: 480, builder: (_) => _CustomerForm(existing: existing));

class _CustomerForm extends ConsumerStatefulWidget {
  const _CustomerForm({this.existing});
  final LCustomer? existing;

  @override
  ConsumerState<_CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends ConsumerState<_CustomerForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _address = TextEditingController(text: widget.existing?.address);
  late final _limit = TextEditingController(text: (widget.existing?.creditLimitP ?? 0) == 0 ? '' : paisaToWire(widget.existing!.creditLimitP).replaceAll(RegExp(r'\.00$'), ''));
  late final _notes = TextEditingController(text: widget.existing?.notes);

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(ctxProvider);
    final word = context.term(ctx, 'customer', 'Customer');
    return PanelScaffold(
      title: widget.existing == null ? '${context.tr('New')} $word' : '${context.tr('Edit')} $word',
      footer: FilledButton(
        onPressed: () async {
          if (_name.text.trim().isEmpty) return;
          await ref.read(salesRepoProvider).saveCustomer(id: widget.existing?.id, name: _name.text.trim(), phone: _phone.text.trim(), address: _address.text.trim(), creditLimitP: paisaOf(_limit), notes: _notes.text.trim());
          if (context.mounted) Navigator.pop(context);
        },
        child: Text(context.tr('Save')),
      ),
      child: Column(children: [
        TextField(controller: _name, autofocus: widget.existing == null, decoration: InputDecoration(labelText: context.tr('Name'), prefixIcon: const Icon(Icons.person_rounded, size: 19))),
        const FormGap(),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: context.tr('Phone'), prefixIcon: const Icon(Icons.phone_rounded, size: 19))),
        const FormGap(),
        TextField(controller: _address, decoration: InputDecoration(labelText: context.tr('Address'), prefixIcon: const Icon(Icons.home_rounded, size: 19))),
        if (ctx.cap('customer_credit')) ...[const FormGap(), MoneyField(controller: _limit, label: context.tr('Credit limit (optional)'), symbol: ctx.currencySymbol, helper: context.tr('Leave empty for no limit'))],
        const FormGap(),
        TextField(controller: _notes, maxLines: 2, decoration: InputDecoration(labelText: context.tr('Notes'), prefixIcon: const Icon(Icons.notes_rounded, size: 19))),
      ]),
    );
  }
}

// ----------------------------------------------------------------------------------------- detail

Future<void> showCustomerDetail(BuildContext context, WidgetRef ref, String id) => showPanel<void>(context, maxWidth: 520, builder: (_) => _CustomerDetail(id: id));

final _ledgerProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, id) async {
  ref.cacheForSession(revalidate: true);
  ref.watch(syncProvider.select((s) => s.revision));
  return (await ref.watch(apiProvider).getList('/customers/$id/ledger')).cast<Map<String, dynamic>>();
});

class _CustomerDetail extends ConsumerWidget {
  const _CustomerDetail({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final row = ref.watch(_customersProvider).value?.where((r) => r.c.id == id).firstOrNull;
    if (row == null) return PanelScaffold(title: context.term(ctx, 'customer', 'Customer'), child: const SkeletonList(rows: 3));
    final c = row.c;
    final ledger = ref.watch(_ledgerProvider(id));
    return PanelScaffold(
      title: c.name,
      subtitle: c.phone.isEmpty ? null : f.digits(c.phone),
      leading: Monogram(c.name, size: 46, round: true),
      actions: [if (ctx.can('manage_customers')) IconButton(icon: const Icon(Icons.edit_rounded, size: 20), onPressed: () => showCustomerForm(context, ref, existing: c))],
      footer: ctx.can('collect_dues') && row.balanceP > 0
          ? FilledButton.icon(onPressed: () => showPanel<void>(context, maxWidth: 420, builder: (_) => _CollectFromCustomer(customerId: c.id, balanceP: row.balanceP)), icon: const Icon(Icons.payments_rounded), label: Text('${context.tr('Collect payment')} · ${f.money(row.balanceP)}'))
          : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Surface(
          color: row.balanceP > 0 ? t.tint(t.warning, 0.1) : t.surface2,
          border: false,
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(row.balanceP > 0 ? context.tr('Owes') : context.tr('Balance'), style: tt.labelMedium!.copyWith(color: t.muted)), NumText(f.money(row.balanceP.abs(), decimals: true), size: 30, weight: 800, color: row.balanceP > 0 ? t.warning : t.text)])),
            if (c.creditLimitP > 0) Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(context.tr('Credit limit'), style: tt.labelMedium!.copyWith(color: t.muted)), NumText(f.money(c.creditLimitP), size: 16)]),
          ]),
        ),
        if (row.pendingP != 0) Padding(padding: const EdgeInsets.only(top: 10), child: Row(children: [Icon(Icons.schedule_rounded, size: 16, color: t.info), const SizedBox(width: 8), Expanded(child: Text(context.tr('Includes changes from this till that have not synced yet.'), style: tt.bodySmall))])),
        if (c.address.isNotEmpty || ctx.loyaltyOn) ...[
          const SizedBox(height: 12),
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(children: [
              if (c.address.isNotEmpty) _InfoRow(icon: Icons.home_rounded, label: context.tr('Address'), value: c.address),
              if (c.address.isNotEmpty && ctx.loyaltyOn) Divider(color: t.outline.withValues(alpha: 0.6)),
              if (ctx.loyaltyOn) _InfoRow(icon: Icons.stars_rounded, label: context.tr('Loyalty points'), value: f.intN(c.points), color: t.info),
            ]),
          ),
        ],
        const FormHeading('Account history'),
        ledger.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const Deferred(child: SkeletonList(rows: 3, height: 48)),
          error: (e, _) => Text(context.tr('History loads when you are online.'), style: tt.bodySmall),
          data: (rows) => rows.isEmpty
              ? Text(context.tr('Nothing yet.'), style: tt.bodyMedium!.copyWith(color: t.muted))
              : Column(children: [
                  for (final r in rows.take(30))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        IconSquare(parsePaisa(r['amount']) > 0 ? Icons.north_east_rounded : Icons.south_west_rounded, color: parsePaisa(r['amount']) > 0 ? t.warning : t.success, size: 34),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text((r['note'] as String?)?.isNotEmpty == true ? r['note'] as String : context.tr(_kinds[r['kind']] ?? 'Entry'), style: tt.titleSmall), Text(f.dateTime(DateTime.parse(r['at'] as String)), style: tt.bodySmall)])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [NumText(f.money(parsePaisa(r['amount']), sign: true, decimals: true), size: 14, color: parsePaisa(r['amount']) > 0 ? t.warning : t.success), Text(f.money(parsePaisa(r['balance_after'])), style: tt.bodySmall)]),
                      ]),
                    ),
                ]),
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value, this.color});
  final IconData icon;
  final String label, value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        IconSquare(icon, size: 34, color: color),
        const SizedBox(width: 12),
        Text(label, style: tt.bodyMedium!.copyWith(color: context.t.muted)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: tt.titleSmall, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

const _kinds = {'sale_due': 'Sold on credit', 'payment': 'Payment received', 'return': 'Return', 'adjust': 'Adjustment', 'opening': 'Opening balance'};

class _CollectFromCustomer extends ConsumerStatefulWidget {
  const _CollectFromCustomer({required this.customerId, required this.balanceP});
  final String customerId;
  final int balanceP;

  @override
  ConsumerState<_CollectFromCustomer> createState() => _CollectFromCustomerState();
}

class _CollectFromCustomerState extends ConsumerState<_CollectFromCustomer> {
  late final _amount = TextEditingController(text: paisaToWire(widget.balanceP).replaceAll(RegExp(r'\.00$'), ''));
  final _ref = TextEditingController();
  String _method = 'cash';

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(ctxProvider);
    final amount = paisaOf(_amount);
    return PanelScaffold(
      title: context.tr('Collect payment'),
      subtitle: context.tr('Applied to the oldest unpaid invoices first.'),
      footer: FilledButton(
        onPressed: amount <= 0
            ? null
            : () async {
                await ref.read(salesRepoProvider).collectDue(customerId: widget.customerId, amountP: amount, method: _method, reference: _ref.text.trim());
                if (context.mounted) {
                  toast(context, context.tr('Payment saved'), good: true);
                  Navigator.pop(context);
                }
              },
        child: Text('${context.tr('Receive')} ${context.fmt.money(amount, decimals: true)}'),
      ),
      child: Column(children: [
        MoneyField(controller: _amount, label: context.tr('Amount'), symbol: ctx.currencySymbol, autofocus: true, onChanged: (_) => setState(() {})),
        const FormGap(),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final m in ctx.enabledPaymentMethods) ChoiceChip(avatar: Icon(m.icon, size: 17, color: m.color), label: Text(m.label), selected: _method == m.code, onSelected: (_) => setState(() => _method = m.code))]),
        if (ctx.enabledPaymentMethods.where((m) => m.code == _method).firstOrNull?.needsReference ?? false) ...[const FormGap(), TextField(controller: _ref, decoration: InputDecoration(labelText: context.tr('Transaction ID / reference'), prefixIcon: const Icon(Icons.tag_rounded, size: 19)))],
      ]),
    );
  }
}
