import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/i18n/lang.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/async_body.dart';
import '../../core/ui/kit.dart';
import '../../data/session.dart';

/// Every account on the platform — platform admins, business owners and their staff — with search and filters.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _q = TextEditingController();
  String _group = 'all';
  final List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _counts = const {};
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
      final r = await ref.read(apiProvider).getMap('/admin/users', query: {
        'limit': 50,
        'offset': _items.length,
        if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(),
        if (_group != 'all') 'group': _group,
      });
      _items.addAll((r['items'] as List).cast<Map<String, dynamic>>());
      _total = (r['total'] as num).toInt();
      _counts = (r['counts'] as Map).cast<String, dynamic>();
    } on ApiError catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    String tab(String key, String text) {
      final n = (_counts[key] as num?)?.toInt();
      return n == null ? text : '$text · ${f.intN(n)}';
    }

    return PageBody(
      maxWidth: 1000,
      child: Column(children: [
        AppSearchField(controller: _q, hint: context.tr('Search by name, phone or business'), onChanged: (_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 350), () => _load(reset: true));
        }),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegTabs<String>(
              items: [('all', tab('all', context.tr('All'))), ('admin', tab('admin', context.tr('Platform admins'))), ('owner', tab('owner', context.tr('Business owners'))), ('staff', tab('staff', context.tr('Staff')))],
              value: _group,
              onChanged: (v) {
                setState(() => _group = v);
                _load(reset: true);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerLeft, child: Text('${f.intN(_total)} ${context.tr('accounts')}', style: tt.labelMedium!.copyWith(color: t.muted))),
        const SizedBox(height: 8),
        Expanded(
          child: _error != null
              ? ErrorView(error: _error!, onRetry: () => _load(reset: true))
              : _items.isEmpty && _loading
                  ? const SkeletonList(rows: 6, height: 72)
                  : _items.isEmpty
                      ? EmptyState(icon: Icons.people_outline_rounded, title: context.tr('No accounts match'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _items.length + (_items.length < _total ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _items.length) {
                              return Padding(padding: const EdgeInsets.all(12), child: Center(child: OutlinedButton(onPressed: _loading ? null : () => _load(), child: Text(context.tr('Load more')))));
                            }
                            return Padding(padding: const EdgeInsets.only(bottom: 8), child: UserRow(user: _items[i]));
                          },
                        ),
        ),
      ]),
    );
  }
}

/// One account: who, their role, which business, whether it is enabled, and when they last signed in.
class UserRow extends StatelessWidget {
  const UserRow({super.key, required this.user, this.trailing});
  final Map<String, dynamic> user;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final role = user['role'] as String;
    final active = user['active'] == true;
    final business = user['tenant_name'] as String?;
    final last = user['last_login_at'] as String?;
    final roleColor = switch (role) { 'super_admin' => t.accentDeep, 'owner' => t.info, _ => t.muted };
    return Opacity(
      opacity: active ? 1 : 0.6,
      child: Surface(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Monogram(user['name'] as String, size: 44, round: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(user['name'] as String, style: tt.titleSmall),
                Pill(context.tr(user['role_label'] as String), color: roleColor, dense: true),
                if (!active) Pill(context.tr('Disabled'), color: t.danger, dense: true),
              ]),
              const SizedBox(height: 2),
              Text(f.digits(user['phone'] as String), style: tt.bodySmall),
              Text(
                [
                  if (business != null) business else context.tr('Platform'),
                  last == null ? context.tr('Never signed in') : '${context.tr('Last active')} ${f.dateTime(DateTime.parse(last))}',
                ].join(' · '),
                style: tt.bodySmall!.copyWith(color: t.muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ]),
          ),
          if (trailing != null) trailing!,
        ]),
      ),
    );
  }
}
