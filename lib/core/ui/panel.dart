import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../util/responsive.dart';
import '../i18n/lang.dart';

/// A modal that is a centred card on big screens and a bottom sheet on phones.
Future<T?> showPanel<T>(BuildContext context, {required WidgetBuilder builder, double maxWidth = 540, bool dismissible = true}) {
  if (context.width >= 720) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.sizeOf(ctx).height - 48), child: builder(ctx)),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: builder(ctx),
    ),
  );
}

/// Standard layout for panel content: title bar, scrollable body, pinned footer.
class PanelScaffold extends StatelessWidget {
  const PanelScaffold({super.key, required this.title, this.subtitle, required this.child, this.footer, this.leading, this.actions = const [], this.padBody = true});
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final Widget? leading;
  final List<Widget> actions;
  final bool padBody;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (context.width < 720)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(width: 42, height: 4.5, decoration: BoxDecoration(color: t.outline, borderRadius: BorderRadius.circular(4))),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.l, Sp.m, Sp.s),
        child: Row(children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr(title), style: tt.headlineSmall),
              if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(context.tr(subtitle!), style: tt.bodySmall)),
            ]),
          ),
          ...actions,
          IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).maybePop()),
        ]),
      ),
      Flexible(
        child: SingleChildScrollView(
          padding: padBody ? const EdgeInsets.fromLTRB(Sp.xl, Sp.s, Sp.xl, Sp.l) : EdgeInsets.zero,
          child: child,
        ),
      ),
      if (footer != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(Sp.xl, Sp.m, Sp.xl, Sp.l),
          decoration: BoxDecoration(color: t.surface, border: Border(top: BorderSide(color: t.outline))),
          child: SafeArea(top: false, child: footer!),
        ),
    ]);
  }
}
