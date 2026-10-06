import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/kit.dart';
import '../../data/session.dart';

class AdminAuditScreen extends ConsumerStatefulWidget {
  const AdminAuditScreen({super.key});

  @override
  ConsumerState<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends ConsumerState<AdminAuditScreen> {
  final _q = TextEditingController();
  String? _action;
  final List<Map<String, dynamic>> _items = [];
  int _total = 0;
  bool _loading = true;
  Object? _error;
  Timer? _debounce;

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
      final r = await ref.read(apiProvider).getMap('/admin/audit', query: {'limit': 50, 'offset': _items.length, if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(), if (_action != null) 'action': _action});
      _items.addAll((r['items'] as List).cast<Map<String, dynamic>>());
      _total = (r['total'] as num).toInt();
    } on ApiError catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  IconData _icon(String a) => a.startsWith('plan') ? Icons.sell_rounded : a.startsWith('billing') ? Icons.payments_rounded : a.startsWith('tenant') ? Icons.storefront_rounded : a.startsWith('business_type') ? Icons.category_rounded : a.startsWith('sale') ? Icons.receipt_long_rounded : a.startsWith('staff') ? Icons.badge_rounded : Icons.history_rounded;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    return PageBody(
      maxWidth: 900,
      child: Column(children: [
        AppSearchField(controller: _q, hint: context.tr('Search the audit trail'), onChanged: (_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 350), () => _load(reset: true));
        }),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegTabs<String?>(items: [(null, context.tr('All')), ('tenant', context.tr('Businesses')), ('plan', context.tr('Plans')), ('billing', context.tr('Billing')), ('business_type', context.tr('Types')), ('sale', context.tr('Flagged sales'))], value: _action, onChanged: (v) {
              setState(() => _action = v);
              _load(reset: true);
            }),
          ),
        ),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: Text('${f.intN(_total)} ${context.tr('entries')} · ${context.tr('append-only, never edited')}', style: tt.labelMedium!.copyWith(color: t.muted))),
        const SizedBox(height: 8),
        Expanded(
          child: _error != null
              ? ErrorView(error: _error!, onRetry: () => _load(reset: true))
              : _items.isEmpty && _loading
                  ? const SkeletonList(rows: 8, height: 60)
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _items.length + (_items.length < _total ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _items.length) return Padding(padding: const EdgeInsets.all(12), child: Center(child: OutlinedButton(onPressed: _loading ? null : () => _load(), child: Text(context.tr('Load more')))));
                        final a = _items[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Surface(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              IconSquare(_icon(a['action'] as String), size: 36),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(a['summary'] as String, style: tt.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text('${a['actor']} · ${a['action']}${a['impersonated'] == true ? ' · ${context.tr('support session')}' : ''}', style: tt.bodySmall),
                              ])),
                              Text(f.dateTime(DateTime.parse(a['at'] as String)), style: tt.bodySmall),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
