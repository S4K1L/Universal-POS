import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/forms.dart';
import '../../core/ui/kit.dart';
import '../../core/ui/panel.dart';
import '../../data/local/database.dart';
import '../../data/providers.dart';
import '../../data/repos/sales_repo.dart';
import '../../data/session.dart';

final _expensesProvider = StreamProvider.autoDispose<List<LExpense>>((ref) {
  ref.cacheForSession();
  final db = ref.watch(dbProvider);
  return (db.select(db.lExpenses)
        ..orderBy([(e) => OrderingTerm.desc(e.spentAt)])
        ..limit(200))
      .watch();
});

const _categories = [('Tea & snacks', Icons.local_cafe_rounded), ('Transport', Icons.directions_bike_rounded), ('Electricity', Icons.bolt_rounded), ('Rent', Icons.home_work_rounded), ('Salary', Icons.badge_rounded), ('Repairs', Icons.build_rounded), ('Packaging', Icons.inventory_rounded), ('Other', Icons.more_horiz_rounded)];

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final ctx = ref.watch(ctxProvider);
    final rows = ref.watch(_expensesProvider);
    return PageBody(
      maxWidth: 820,
      child: FadeSwitcher(child: rows.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => const Deferred(child: SkeletonList()),
        error: (e, _) => ErrorView(error: e),
        data: (list) {
          final now = DateTime.now();
          final today = list.where((e) => e.spentAt.year == now.year && e.spentAt.month == now.month && e.spentAt.day == now.day).fold<int>(0, (a, e) => a + e.amountP);
          final month = list.where((e) => e.spentAt.year == now.year && e.spentAt.month == now.month).fold<int>(0, (a, e) => a + e.amountP);
          return Column(children: [
            Row(children: [
              Expanded(child: StatTile(label: context.tr('Spent today'), value: f.money(today), icon: Icons.account_balance_wallet_rounded, color: t.warning)),
              const SizedBox(width: 12),
              Expanded(child: StatTile(label: context.tr('This month'), value: f.money(month), icon: Icons.calendar_month_rounded)),
            ]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(onPressed: ctx.can('manage_expenses') ? () => showPanel<void>(context, maxWidth: 440, builder: (_) => const _AddExpense()) : null, icon: const Icon(Icons.add_rounded, size: 20), label: Text(context.tr('Add expense'))),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(icon: Icons.account_balance_wallet_outlined, title: context.tr('No expenses yet'), message: context.tr('Tea, transport, electricity — note what you spend so the day book adds up.'))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final e = list[i];
                        final icon = _categories.where((c) => c.$1 == e.category).firstOrNull?.$2 ?? Icons.receipt_rounded;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Surface(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(children: [
                              IconSquare(icon, color: t.warning, size: 40),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(context.tr(e.category), style: tt.titleSmall), Text('${f.dateTime(e.spentAt)}${e.note.isEmpty ? '' : ' · ${e.note}'}', style: tt.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)])),
                              if (e.syncState != 'synced') Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.schedule_rounded, size: 16, color: t.info)),
                              NumText('−${f.money(e.amountP, decimals: true)}', size: 15, weight: 800),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
          ]);
        },
      )),
    );
  }
}

class _AddExpense extends ConsumerStatefulWidget {
  const _AddExpense();

  @override
  ConsumerState<_AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends ConsumerState<_AddExpense> {
  String _cat = 'Tea & snacks';
  String _method = 'cash';
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(ctxProvider);
    final amount = paisaOf(_amount);
    return PanelScaffold(
      title: context.tr('Add expense'),
      footer: FilledButton(
        onPressed: amount <= 0
            ? null
            : () async {
                await ref.read(salesRepoProvider).addExpense(category: _cat, amountP: amount, method: _method, note: _note.text.trim());
                if (context.mounted) Navigator.pop(context);
              },
        child: Text('${context.tr('Save')} ${context.fmt.money(amount)}'),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [for (final (c, icon) in _categories) ChoiceChip(avatar: Icon(icon, size: 17), label: Text(context.tr(c)), selected: _cat == c, onSelected: (_) => setState(() => _cat = c))]),
        const FormGap(),
        MoneyField(controller: _amount, label: context.tr('Amount'), symbol: ctx.currencySymbol, autofocus: true, onChanged: (_) => setState(() {})),
        const FormGap(),
        Wrap(spacing: 8, children: [for (final m in ctx.enabledPaymentMethods.take(4)) ChoiceChip(avatar: Icon(m.icon, size: 17, color: m.color), label: Text(m.label), selected: _method == m.code, onSelected: (_) => setState(() => _method = m.code))]),
        const FormGap(),
        TextField(controller: _note, decoration: InputDecoration(labelText: context.tr('Note (optional)'), prefixIcon: const Icon(Icons.notes_rounded, size: 19))),
      ]),
    );
  }
}
