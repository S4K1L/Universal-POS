import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/i18n/lang.dart';
import '../../core/theme/theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/brand.dart';
import '../../core/ui/kit.dart';
import 'report_doc.dart';

/// The on-screen report, built from the same [ReportDoc] as the PDF and laid out the same way: banner, who it is
/// for, summary cards, payment mix, valuation, best sellers, invoices. The page decides how wide it is once and
/// passes flags down, so nothing here has to ask.

final _rowStamp = DateFormat('dd MMM yy, hh:mm a');

/// Small caps label, as used above values and in table headers.
TextStyle _caption(BuildContext c) => TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: c.t.muted);

BoxDecoration _card(BuildContext c) => BoxDecoration(color: c.t.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: c.t.outline));

/// A saturated tone as it should read on the current surface: fine on white, lifted toward white on dark.
Color _lift(BuildContext c, Color color) => c.t.dark ? Color.lerp(color, Colors.white, 0.42)! : color;

// ---------------------------------------------------------------------
//  Banner
// ---------------------------------------------------------------------

/// The gradient masthead: brand on the left, what this is on the right, and the page's actions underneath it.
class ReportBanner extends StatelessWidget {
  const ReportBanner({super.key, required this.doc, required this.action, required this.stacked});
  final ReportDoc doc;
  final Widget action;

  /// Brand above the title above the action, instead of side by side.
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final p = doc.palette;
    final f = context.fmt;
    final onBanner = Colors.white;
    final soft = p.soft;
    final brand = Row(children: [
      BrandMark(size: stacked ? 42 : 52, color: Colors.white.withValues(alpha: 0.95)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Universal POS', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: onBanner, fontWeight: FontWeight.w800, fontSize: stacked ? 21 : 25, letterSpacing: -0.3)),
          Text(context.tr('Point of sale for every shop'), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: soft, fontSize: 12)),
        ]),
      ),
    ]);

    final title = Column(
      crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(context.tr('BUSINESS REPORT'), maxLines: 1, style: TextStyle(color: onBanner, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1.5)),
        const SizedBox(height: 3),
        Text('${context.tr('As of')} ${f.digits(DateFormat('dd MMM yyyy, hh:mm a').format(doc.generatedAt))}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: soft, fontSize: 12)),
      ],
    );

    return Container(
      padding: EdgeInsets.all(stacked ? 16 : 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: [p.lite, p.deep], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: p.deep.withValues(alpha: 0.22), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: stacked
          ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [brand, const SizedBox(height: 16), title, const SizedBox(height: 14), action])
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: brand),
              const SizedBox(width: 20),
              Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [title, const SizedBox(height: 12), action]),
            ]),
    );
  }
}

// ---------------------------------------------------------------------
//  Who it is for
// ---------------------------------------------------------------------

class ReportIdentity extends StatelessWidget {
  const ReportIdentity({super.key, required this.doc, required this.stacked});
  final ReportDoc doc;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final tt = Theme.of(context).textTheme;
    final f = context.fmt;
    final contact = [
      if (doc.city.isNotEmpty) doc.city,
      if (doc.address.isNotEmpty) doc.address,
      if (doc.phone.isNotEmpty) '${context.tr('Tel')}: ${f.digits(doc.phone)}',
    ];
    final day = DateFormat('dd MMM yyyy');
    final a = f.digits(day.format(doc.from)), b = f.digits(day.format(doc.to));

    final who = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(context.tr('PREPARED FOR'), style: _caption(context).copyWith(letterSpacing: 1.2)),
      const SizedBox(height: 4),
      Text(doc.shopName, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.headlineSmall?.copyWith(fontSize: 23, fontWeight: FontWeight.w800)),
      if (contact.isNotEmpty) ...[
        const SizedBox(height: 5),
        // Spaced rather than joined with a separator, so a wrapped line never ends on a stray "|".
        Wrap(spacing: 16, runSpacing: 2, children: [for (final c in contact) Text(c, style: tt.bodySmall)]),
      ],
    ]);

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 84, child: Text(context.tr(k), style: tt.bodySmall)),
            Expanded(child: Text(v, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, fontFeatures: tabular))),
          ]),
        );

    final meta = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: _card(context).copyWith(color: t.surface2),
      child: Column(children: [
        if (doc.scope.isNotEmpty) row('Scope', context.tr(doc.scope)),
        row('Period', a == b ? a : '$a - $b'),
        if (doc.preparedBy.isNotEmpty) row('Prepared by', doc.preparedBy),
      ]),
    );

    if (stacked) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [who, const SizedBox(height: 14), meta]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: who), const SizedBox(width: 24), SizedBox(width: 310, child: meta)]);
  }
}

// ---------------------------------------------------------------------
//  Section heading
// ---------------------------------------------------------------------

class ReportHeading extends StatelessWidget {
  const ReportHeading(this.text, {super.key, this.accent});
  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: accent ?? context.t.accent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 9),
          Expanded(child: Text(context.tr(text).toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.9, color: context.t.text))),
        ]),
      );
}

// ---------------------------------------------------------------------
//  Summary cards
// ---------------------------------------------------------------------

class ReportKpis extends StatelessWidget {
  const ReportKpis({super.key, required this.doc, required this.fourUp});
  final ReportDoc doc;

  /// Four across; otherwise two by two.
  final bool fourUp;

  @override
  Widget build(BuildContext context) {
    final f = context.fmt;
    final cards = [
      for (final k in doc.kpis) _KpiCard(context.tr(k.label), k.count != null ? f.intN(k.count!) : f.money(k.paisa ?? 0, decimals: true), doc.palette.tone(k.tone)),
    ];
    final per = fourUp ? 4 : 2;
    return Column(children: [
      for (var i = 0; i < cards.length; i += per) ...[
        if (i > 0) const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var j = 0; j < per; j++) ...[
            if (j > 0) const SizedBox(width: 12),
            Expanded(child: i + j < cards.length ? cards[i + j] : const SizedBox()),
          ],
        ]),
      ],
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(this.label, this.value, this.tone);
  final String label, value;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
        decoration: _card(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(height: 3.5, color: tone),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: _caption(context)),
                const SizedBox(height: 8),
                // Fixed height with a shrinking value: a seven-figure total scales down inside its card instead of
                // spilling out, and the cards stay the same height.
                SizedBox(
                  height: 30,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, maxLines: 1, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: context.t.text, fontFeatures: tabular)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      );
}

// ---------------------------------------------------------------------
//  Sales by payment method
// ---------------------------------------------------------------------

class ReportPayments extends StatelessWidget {
  const ReportPayments({super.key, required this.doc, required this.compact, this.minHeight});
  final ReportDoc doc;

  /// Bar on its own line under the figures, for a narrow card.
  final bool compact;

  /// At least this tall, so it can sit level with a neighbour. A minimum, not exact: large system fonts need more room.
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final top = doc.payments.fold(0, (a, b) => a > b.amountP ? a : b.amountP);
    final colors = doc.palette.series;
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: _card(context),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (final (i, m) in doc.payments.indexed)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: _row(context, m, colors[i % colors.length], top <= 0 ? 0 : m.amountP / top)),
      ]),
    );
  }

  Widget _row(BuildContext context, ReportPayment m, Color color, double frac) {
    final f = context.fmt;
    final t = context.t;
    final amount = Text(f.money(m.amountP, decimals: true), maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFeatures: tabular));
    final share = Text(f.digits('${(doc.shareOf(m) * 100).toStringAsFixed(1)}%'), textAlign: TextAlign.end, maxLines: 1, style: TextStyle(fontSize: 12, color: t.muted, fontFeatures: tabular));
    final dot = Container(width: 9, height: 9, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.5)));
    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Stack(children: [
          Positioned.fill(child: ColoredBox(color: t.outline)),
          Align(alignment: Alignment.centerLeft, child: FractionallySizedBox(widthFactor: frac.clamp(0.0, 1.0), child: SizedBox(height: 8, child: ColoredBox(color: color)))),
        ]),
      ),
    );
    final label = Text(context.tr(m.label), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13));

    if (compact) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          dot,
          const SizedBox(width: 9),
          Expanded(child: label),
          const SizedBox(width: 8),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 150), child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: amount)),
          SizedBox(width: 48, child: share),
        ]),
        const SizedBox(height: 7),
        bar,
      ]);
    }
    return Row(children: [
      dot,
      const SizedBox(width: 10),
      SizedBox(width: 92, child: label),
      SizedBox(width: 124, child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: amount)),
      SizedBox(width: 56, child: share),
      const SizedBox(width: 14),
      Expanded(child: bar),
    ]);
  }
}

// ---------------------------------------------------------------------
//  Inventory valuation
// ---------------------------------------------------------------------

class ReportValuation extends StatelessWidget {
  const ReportValuation({super.key, required this.doc, this.minHeight});
  final ReportDoc doc;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final p = doc.palette;
    final f = context.fmt;
    final rows = <Widget>[
      if (doc.costValueP != null) _row(context, 'Stock value (at cost)', doc.costValueP!, ReportPalette.blue),
      _row(context, 'Stock value (at retail)', doc.retailValueP!, p.accent),
      if (doc.potentialP != null)
        _row(context, 'Potential margin', doc.potentialP!, ReportPalette.violet, note: doc.marginShare == null ? null : context.trf('{pct}% of retail', {'pct': f.digits((doc.marginShare! * 100).toStringAsFixed(1))})),
    ];
    final line = Divider(height: 1, color: context.t.outline);
    return Container(
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: _card(context),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) line,
          Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: rows[i]),
        ],
      ]),
    );
  }

  Widget _row(BuildContext context, String label, int paisa, Color tone, {String? note}) => Row(children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(2.5))),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(context.tr(label), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            if (note != null) Text(note, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
          ]),
        ),
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 190),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(context.fmt.money(paisa, decimals: true), maxLines: 1, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _lift(context, tone), fontFeatures: tabular)),
          ),
        ),
      ]);
}

// ---------------------------------------------------------------------
//  Tables
// ---------------------------------------------------------------------

class _Column {
  const _Column(this.label, {this.width, this.flex = 1, this.align = Alignment.centerLeft});
  final String label;

  /// Fixed width, or a share of what is left when null.
  final double? width;
  final int flex;
  final Alignment align;
}

/// A rounded, bordered table: accent header band, zebra body. Cells are single-line so row height never depends on width.
class _BandTable extends StatelessWidget {
  const _BandTable({required this.columns, required this.rows, required this.header, this.onTapRow});
  final List<_Column> columns;
  final List<List<Widget>> rows;
  final Color header;
  final void Function(int row)? onTapRow;

  Widget _cell(_Column c, Widget child) {
    final aligned = Align(alignment: c.align, child: child);
    return c.width != null ? SizedBox(width: c.width, child: aligned) : Expanded(flex: c.flex, child: aligned);
  }

  @override
  Widget build(BuildContext context) {
    final zebra = context.t.surface2;
    return Container(
      decoration: _card(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            color: header,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              for (final c in columns)
                _cell(c, Text(context.tr(c.label).toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.7))),
            ]),
          ),
          for (var r = 0; r < rows.length; r++)
            InkWell(
              onTap: onTapRow == null ? null : () => onTapRow!(r),
              child: Container(
                color: r.isOdd ? zebra : null,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(children: [for (var i = 0; i < columns.length; i++) _cell(columns[i], rows[r][i])]),
              ),
            ),
        ]),
      ),
    );
  }
}

Widget _text(String s, {bool bold = false, Color? color, bool numeric = false}) =>
    Text(s, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color, fontFeatures: numeric ? tabular : null));

/// Right-aligned figure that shrinks rather than overflowing its column.
Widget _figure(String s, {bool bold = false, Color? color}) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: _text(s, bold: bold, color: color, numeric: true));

class ReportEmpty extends StatelessWidget {
  const ReportEmpty(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
        alignment: Alignment.center,
        decoration: _card(context).copyWith(color: context.t.surface2),
        child: Text(context.tr(text), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      );
}

class ReportProducts extends StatelessWidget {
  const ReportProducts({super.key, required this.doc, required this.compact});
  final ReportDoc doc;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (doc.topProducts.isEmpty) return const ReportEmpty('No itemised sales recorded yet.');
    final f = context.fmt;
    final top = doc.topProducts;
    final head = doc.palette.deep;
    if (compact) {
      // The rank folds into the name: a separate "#" column would leave the product a few characters on a phone.
      return _BandTable(
        header: head,
        columns: const [_Column('Product', flex: 1), _Column('Units', width: 54, align: Alignment.centerRight), _Column('Revenue', width: 96, align: Alignment.centerRight)],
        rows: [
          for (final (n, p) in top.indexed) [_text('${f.digits('${n + 1}')}.  ${p.name}', bold: true), _figure(f.qty(p.qtyMilli)), _figure(f.money(p.revenueP, decimals: true))],
        ],
      );
    }
    return _BandTable(
      header: head,
      columns: const [_Column('#', width: 34, align: Alignment.center), _Column('Product', flex: 1), _Column('Units sold', width: 100, align: Alignment.centerRight), _Column('Revenue', width: 140, align: Alignment.centerRight)],
      rows: [
        for (final (n, p) in top.indexed) [_text(f.digits('${n + 1}'), bold: true), _text(p.name, bold: true), _figure(f.qty(p.qtyMilli)), _figure(f.money(p.revenueP, decimals: true))],
      ],
    );
  }
}

class ReportRegister extends StatelessWidget {
  const ReportRegister({super.key, required this.doc, required this.rows, required this.compact, this.onOpen});
  final ReportDoc doc;

  /// How many of the newest invoices to list on screen.
  final int rows;
  final bool compact;

  /// Tapping an invoice opens its receipt.
  final void Function(ReportInvoice)? onOpen;

  @override
  Widget build(BuildContext context) {
    if (doc.register.isEmpty) return const ReportEmpty('No invoices recorded yet.');
    final f = context.fmt;
    final shown = doc.register.take(rows).toList();
    final table = compact ? _compactList(context, shown) : _wideTable(context, shown);
    if (doc.registerTotal <= shown.length) return table;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      table,
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          context.trf('Showing the latest {shown} of {total} invoices. The PDF lists the latest {pdf}.', {'shown': f.intN(shown.length), 'total': f.intN(doc.registerTotal), 'pdf': f.intN(doc.register.length)}),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ]);
  }

  Color _methodColor(BuildContext context, String label) {
    final i = doc.payments.indexWhere((p) => p.label == label);
    final series = doc.palette.series;
    return i < 0 ? context.t.muted : series[i % series.length];
  }

  Widget _tap(ReportInvoice s, Widget child) => onOpen == null ? child : InkWell(onTap: () => onOpen!(s), child: child);

  Widget _wideTable(BuildContext context, List<ReportInvoice> shown) {
    final f = context.fmt;
    return _BandTable(
      header: doc.palette.deep,
      onTapRow: onOpen == null ? null : (i) => onOpen!(shown[i]),
      columns: const [
        _Column('Invoice', flex: 21),
        _Column('Date', flex: 25),
        _Column('Customer', flex: 30),
        _Column('Payment', flex: 20),
        _Column('Total', flex: 22, align: Alignment.centerRight),
        _Column('Due', flex: 18, align: Alignment.centerRight),
      ],
      rows: [
        for (final s in shown)
          [
            _text(s.invoiceNo, bold: true),
            _text(f.digits(_rowStamp.format(s.soldAt))),
            _text(s.customer == 'Walk-in' ? context.tr('Walk-in') : s.customer),
            Pill(s.payment, color: _methodColor(context, s.payment), dense: true),
            _figure(f.money(s.totalP, decimals: true), bold: true),
            s.dueP > 0 ? _figure(f.money(s.dueP, decimals: true), bold: true, color: _lift(context, ReportPalette.red)) : _text('-', color: context.t.muted),
          ],
      ],
    );
  }

  /// Phones: one small card per invoice, in the table's stripes.
  Widget _compactList(BuildContext context, List<ReportInvoice> shown) {
    final f = context.fmt;
    final zebra = context.t.surface2;
    return Container(
      decoration: _card(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Column(children: [
          for (var r = 0; r < shown.length; r++)
            _tap(
              shown[r],
              Container(
                width: double.infinity,
                color: r.isOdd ? zebra : null,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _text(shown[r].invoiceNo, bold: true)),
                    const SizedBox(width: 10),
                    ConstrainedBox(constraints: const BoxConstraints(maxWidth: 170), child: _figure(f.money(shown[r].totalP, decimals: true), bold: true)),
                  ]),
                  const SizedBox(height: 2),
                  Text('${f.digits(_rowStamp.format(shown[r].soldAt))}  -  ${shown[r].customer == 'Walk-in' ? context.tr('Walk-in') : shown[r].customer}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    Pill(shown[r].payment, color: _methodColor(context, shown[r].payment), dense: true),
                    if (shown[r].dueP > 0) Pill('${context.tr('Due')} ${f.money(shown[r].dueP, decimals: true)}', color: ReportPalette.red, dense: true),
                  ]),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------
//  Footer
// ---------------------------------------------------------------------

class ReportFooter extends StatelessWidget {
  const ReportFooter({super.key, required this.doc});
  final ReportDoc doc;

  @override
  Widget build(BuildContext context) => Column(children: [
        Divider(height: 1, color: context.t.outline),
        const SizedBox(height: 12),
        Text('Universal POS  |  ${doc.shopName}', textAlign: TextAlign.center, style: TextStyle(color: context.t.accent, fontWeight: FontWeight.w700, fontSize: 12)),
        const SizedBox(height: 3),
        Text(context.tr('Amounts in Bangladeshi Taka (৳)'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
      ]);
}
