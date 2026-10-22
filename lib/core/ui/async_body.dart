import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../i18n/lang.dart';
import 'kit.dart';

/// Loading / error / data for anything fetched from the server. A request that fails because the till is
/// offline says so plainly — the till itself keeps working.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, this.onRetry, this.loading});
  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) => FadeSwitcher(
        child: value.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          data: (v) => KeyedSubtree(key: const ValueKey('data'), child: data(v)),
          loading: () => KeyedSubtree(key: const ValueKey('loading'), child: Deferred(child: loading ?? const Padding(padding: EdgeInsets.all(20), child: SkeletonList(rows: 5, height: 70)))),
          error: (e, _) => KeyedSubtree(key: const ValueKey('error'), child: ErrorView(error: e, onRetry: onRetry)),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final offline = error is ApiError && (error as ApiError).offline;
    final lapsed = error is ApiError && (error as ApiError).lapsed;
    return EmptyState(
      icon: offline ? Icons.cloud_off_rounded : (lapsed ? Icons.lock_clock_rounded : Icons.error_outline_rounded),
      title: offline ? context.tr('This screen needs the internet') : context.tr('Something went wrong'),
      message: offline ? context.tr('Selling keeps working offline. This page will load when the connection is back.') : (error is ApiError ? (error as ApiError).message : '$error'),
      action: onRetry == null ? null : OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded, size: 19), label: Text(context.tr('Try again'))),
    );
  }
}

/// Wide pages centre their content in a readable column.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 1180, this.padding});
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final gutter = w < 640 ? 14.0 : 24.0;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: Padding(padding: padding ?? EdgeInsets.fromLTRB(gutter, 4, gutter, 0), child: child)),
    );
  }
}
