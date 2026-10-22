import 'package:flutter/material.dart';

import '../i18n/lang.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../util/responsive.dart';
import 'kit.dart';

// Building blocks shared by the business dashboard and the platform console overview: the dark headline panel with
// its trend and metrics, the quick-action tiles, and the card shape every block sits in.

class HeroMetric {
  const HeroMetric(this.label, this.value, {this.sub, this.color});
  final String label, value;
  final String? sub;
  final Color? color;
}

class HeroLabel extends StatelessWidget {
  const HeroLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: t.success, shape: BoxShape.circle, boxShadow: [BoxShadow(color: t.success.withValues(alpha: 0.6), blurRadius: 8)])),
      const SizedBox(width: 9),
      Text(text.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: t.onInkMuted, fontFamily: 'PJS', fontFamilyFallback: const ['Hind'])),
    ]);
  }
}

class HeroValue extends StatelessWidget {
  const HeroValue(this.text, {super.key, this.size = 46});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: NumText(text, size: size, weight: 800, color: context.t.onInk));
}

class HeroHeadline extends StatelessWidget {
  const HeroHeadline({super.key, required this.value, required this.format, required this.delta, required this.versus});
  final int value;
  final String Function(int) format;
  final String versus;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final compact = context.isCompact;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HeroLabel(context.tr("Today's sales")),
      SizedBox(height: compact ? 8 : 12),
      CountUp(value: value, format: format, builder: (_, text) => HeroValue(text, size: compact ? 38 : 50)),
      const SizedBox(height: 12),
      Wrap(spacing: 10, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        if (delta != null) DeltaChip(delta!),
        Text(versus, style: TextStyle(color: t.onInkMuted, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

class DeltaChip extends StatelessWidget {
  const DeltaChip(this.v, {super.key});
  final double v;

  @override
  Widget build(BuildContext context) {
    final up = v >= 0;
    final c = up ? const Color(0xFF34D399) : const Color(0xFFFB7185);
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 3, 10, 3),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(R.chip)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded, size: 16, color: c),
        const SizedBox(width: 5),
        Text(context.fmt.digits('${(v.abs() * 100).toStringAsFixed(v.abs() >= 1 ? 0 : 1)}%'), style: TextStyle(color: c, fontWeight: FontWeight.w800, fontSize: 12.5, fontFeatures: tabular)),
      ]),
    );
  }
}

class HeroTrend extends StatelessWidget {
  const HeroTrend({super.key, required this.values, required this.caption});
  final List<int> values;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    if (values.length < 2) return const SizedBox(height: 70);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(caption, style: TextStyle(color: t.onInkMuted, fontSize: 12, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      SizedBox(height: 76, child: Sparkline(values: [for (final v in values) v.toDouble()], color: Color.lerp(t.accent, Colors.white, 0.45)!, stroke: 2.6)),
    ]);
  }
}

class HeroMetrics extends StatelessWidget {
  const HeroMetrics({super.key, required this.metrics});
  final List<HeroMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final compact = context.isCompact;
    Widget cell(HeroMetric m) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.label, style: TextStyle(color: t.onInkMuted, fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 5),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: NumText(m.value, size: compact ? 17 : 22, weight: 800, color: m.color ?? t.onInk)),
          if (m.sub != null && !compact) Padding(padding: const EdgeInsets.only(top: 3), child: Text(m.sub!, style: TextStyle(color: t.onInkMuted, fontSize: 11.5, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (i, m) in metrics.indexed) ...[
        if (i > 0) ...[SizedBox(width: compact ? 10 : 16), Container(width: 1, height: compact ? 34 : 44, color: Colors.white.withValues(alpha: 0.08)), SizedBox(width: compact ? 12 : 20)],
        Expanded(child: cell(m)),
      ],
    ]);
  }
}

// ======================================================================================================== quick actions

class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap, this.primary = false, this.badge = 0});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  /// A count shown on the tile's corner (for example payments waiting for review); nothing when zero.
  final int badge;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final fg = primary ? t.onAccent : null;
    // Narrow tiles (phones, small tablets) stack the icon over the label so the label is never cut off.
    final tile = LayoutBuilder(builder: (c, box) {
      final stacked = box.maxWidth < 170;
      return Surface(
        onTap: onTap,
        color: primary ? t.accent : null,
        border: !primary,
        padding: EdgeInsets.symmetric(horizontal: stacked ? 6 : 16, vertical: stacked ? 12 : 14),
        child: stacked
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                primary ? Icon(icon, color: fg, size: 24) : IconSquare(icon, size: 38),
                const SizedBox(height: 8),
                Text(label, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: fg), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
              ])
            : Row(children: [
                primary ? Icon(icon, color: fg, size: 22) : IconSquare(icon, size: 38),
                const SizedBox(width: 12),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall!.copyWith(color: fg), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Icon(Icons.arrow_forward_rounded, size: 16, color: primary ? fg : t.faint),
              ]),
      );
    });
    if (badge <= 0) return tile;
    return Stack(clipBehavior: Clip.none, fit: StackFit.passthrough, children: [
      tile,
      Positioned(
        top: -7,
        right: -5,
        child: Container(
          constraints: const BoxConstraints(minWidth: 20),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: t.warning, borderRadius: BorderRadius.circular(R.chip), border: Border.all(color: t.canvas, width: 2)),
          child: Text(context.fmt.intN(badge), textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black, height: 1.2)),
        ),
      ),
    ]);
  }
}

// ======================================================================================================== cards & rows

/// One card shape for every block on the dashboard: title, optional count badge and link, then content.
class DashCard extends StatelessWidget {
  const DashCard({super.key, required this.title, required this.child, this.subtitle, this.count, this.action, this.onAction, this.trailing});
  final String title;
  final String? subtitle, action;
  final int? count;
  final VoidCallback? onAction;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final link = t.dark ? Color.lerp(t.accent, Colors.white, 0.3)! : t.accentDeep;
    return Surface(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(title, style: tt.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (count != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                    decoration: BoxDecoration(color: t.surface2, borderRadius: BorderRadius.circular(R.chip), border: Border.all(color: t.outline)),
                    child: Text(context.fmt.intN(count!), style: tt.labelSmall!.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle!, style: tt.bodySmall)),
            ]),
          ),
          if (trailing != null) trailing!,
          if (action != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(action!, style: TextStyle(color: link, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: link),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}

class DashEmpty extends StatelessWidget {
  const DashEmpty(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 22), child: Center(child: Text(text, style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: context.t.muted))));
}

class DashAllGood extends StatelessWidget {
  const DashAllGood(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: t.tint(t.success, 0.1), borderRadius: BorderRadius.circular(R.control)),
      child: Row(children: [Icon(Icons.check_circle_rounded, color: t.success, size: 20), const SizedBox(width: 10), Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium))]),
    );
  }
}

class DashListRow extends StatelessWidget {
  const DashListRow({super.key, required this.title, required this.trailing, this.leading, this.meta});
  final String title;
  final String? meta;
  final Widget? leading, trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.outline.withValues(alpha: 0.6)))),
      child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Expanded(child: Text(title, style: tt.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (meta != null) Padding(padding: const EdgeInsets.only(right: 10), child: Text(meta!, style: tt.bodySmall)),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

