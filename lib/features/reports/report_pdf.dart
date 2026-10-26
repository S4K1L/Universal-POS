import 'dart:typed_data';

import 'package:flutter/painting.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/i18n/lang.dart';
import '../../core/ui/brand.dart';
import 'report_doc.dart';

/// Who the report is from. One place, so a rename touches one line.
class ReportBrand {
  ReportBrand._();
  static const product = 'Universal POS';
  static const tagline = 'Point of sale for every shop';
}

// ---------------------------------------------------------------------
//  Look
// ---------------------------------------------------------------------

PdfColor _c(Color c) => PdfColor.fromInt(c.toARGB32());

const _ink = PdfColor.fromInt(0xFF171E2E);
const _muted = PdfColor.fromInt(0xFF6E7788);
const _line = PdfColor.fromInt(0xFFE3E6EC);
const _zebra = PdfColor.fromInt(0xFFF7F8FB);
const _white = PdfColors.white;

/// The sheet is always English with Latin digits and "Tk": the PDF library cannot shape Bangla conjuncts, so a
/// Bangla heading would print broken. Shop, customer and product names in Bangla still print (via the fallback font).
const _en = Fmt(AppLang.en);

final _stamp = DateFormat('dd MMM yyyy, hh:mm a');
final _day = DateFormat('dd MMM yyyy');
final _rowStamp = DateFormat('dd MMM yy, hh:mm a');

class _Look {
  _Look(ReportDoc doc)
      : p = doc.palette,
        accent = _c(doc.accent),
        lite = _c(doc.palette.lite),
        deep = _c(doc.palette.deep),
        soft = _c(doc.palette.soft),
        currency = doc.currency;

  final ReportPalette p;
  final PdfColor accent, lite, deep, soft;
  final String currency;

  PdfColor tone(String name) => _c(p.tone(name));
  String money(int paisa) => '$currency ${_en.money(paisa, symbol: false, decimals: true)}';
}

pw.TextStyle _t(double size, {bool bold = false, PdfColor? color, double? letterSpacing}) => pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? _ink,
      letterSpacing: letterSpacing,
    );

// ---------------------------------------------------------------------
//  Document
// ---------------------------------------------------------------------

/// Renders the A4 business report. [logo] is the PNG of the brand mark; without it the banner is text only.
/// [fallbackFont] is a Unicode font used for any character Helvetica lacks (Bangla names). [compress] is for tests.
Future<Uint8List> buildReportPdf(ReportDoc doc, {Uint8List? logo, pw.Font? fallbackFont, bool compress = true}) async {
  final look = _Look(doc);
  final pdf = pw.Document(
    title: '${ReportBrand.product} Business Report - ${doc.shopName}',
    author: doc.preparedBy.isEmpty ? ReportBrand.product : doc.preparedBy,
    creator: ReportBrand.product,
    subject: 'Business report',
    compress: compress,
    theme: pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
      fontFallback: [if (fallbackFont != null) fallbackFont],
    ),
  );
  final mark = logo == null ? null : pw.MemoryImage(logo);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 36),
      header: (ctx) => ctx.pageNumber == 1 ? pw.SizedBox() : _runningHeader(doc, look, mark),
      footer: (ctx) => _footer(doc, look, ctx),
      build: (ctx) => [
        _banner(doc, look, mark),
        pw.SizedBox(height: 16),
        _identity(doc),
        pw.SizedBox(height: 18),
        _heading('Summary', look),
        ..._kpiRows(doc, look),
        if (doc.payments.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          _heading('Sales by payment method', look),
          _paymentBreakdown(doc, look),
        ],
        if (doc.hasValuation) ...[
          pw.SizedBox(height: 18),
          _heading('Inventory valuation', look),
          _valuation(doc, look),
        ],
        pw.SizedBox(height: 18),
        _heading('Top selling products', look),
        _topProducts(doc, look),
        pw.SizedBox(height: 18),
        _heading('Invoice register', look),
        ..._register(doc, look),
      ],
    ),
  );
  return pdf.save();
}

/// `UniversalPOS-Report-2026-10-26.pdf`
String reportFileName(DateTime when) => 'UniversalPOS-Report-${DateFormat('yyyy-MM-dd').format(when)}.pdf';

/// Builds the report and hands it to the platform: a browser download on the web, the share sheet on a phone.
Future<void> downloadReportPdf(ReportDoc doc) async {
  Uint8List? logo;
  pw.Font? fallback;
  try {
    logo = await brandMarkPng(const Color(0xFFFFFFFF), doc.accent);
  } catch (_) {
    // A missing mark must not stop the owner getting their numbers.
  }
  try {
    fallback = pw.Font.ttf(await rootBundle.load('assets/fonts/HindSiliguri-Regular.ttf'));
  } catch (_) {}
  await Printing.sharePdf(bytes: await buildReportPdf(doc, logo: logo, fallbackFont: fallback), filename: reportFileName(doc.generatedAt));
}

// ---------------------------------------------------------------------
//  Pieces
// ---------------------------------------------------------------------

String _period(ReportDoc d) {
  final a = _day.format(d.from), b = _day.format(d.to);
  return a == b ? a : '$a - $b';
}

pw.Widget _banner(ReportDoc d, _Look l, pw.ImageProvider? mark) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        gradient: pw.LinearGradient(colors: [l.lite, l.deep], begin: pw.Alignment.topLeft, end: pw.Alignment.bottomRight),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (mark != null) ...[pw.SizedBox(width: 40, height: 40, child: pw.Image(mark)), pw.SizedBox(width: 12)],
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(ReportBrand.product, style: _t(21, bold: true, color: _white)),
              pw.SizedBox(height: 1),
              pw.Text(ReportBrand.tagline, style: _t(8.5, color: l.soft)),
            ],
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('BUSINESS REPORT', style: _t(13, bold: true, color: _white, letterSpacing: 1.4)),
              pw.SizedBox(height: 3),
              pw.Text('Generated ${_stamp.format(d.generatedAt)}', style: _t(8.5, color: l.soft)),
            ],
          ),
        ],
      ),
    );

/// Slim banner for pages 2+, so a loose sheet is still identifiable.
pw.Widget _runningHeader(ReportDoc d, _Look l, pw.ImageProvider? mark) => pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 7),
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.8))),
      child: pw.Row(
        children: [
          if (mark != null) ...[
            pw.Container(
              width: 16,
              height: 16,
              decoration: pw.BoxDecoration(color: l.accent, borderRadius: pw.BorderRadius.circular(4)),
              padding: const pw.EdgeInsets.all(1),
              child: pw.Image(mark),
            ),
            pw.SizedBox(width: 6),
          ],
          pw.Text(ReportBrand.product, style: _t(10, bold: true, color: l.accent)),
          pw.Spacer(),
          pw.Text('${d.shopName}  |  Business Report', style: _t(8.5, color: _muted)),
        ],
      ),
    );

pw.Widget _identity(ReportDoc d) {
  final contact = [
    if (d.city.isNotEmpty) d.city,
    if (d.address.isNotEmpty) d.address,
    if (d.phone.isNotEmpty) 'Tel: ${d.phone}',
  ];

  pw.Widget meta(String k, String v) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(width: 62, child: pw.Text(k, style: _t(8.5, color: _muted))),
            pw.Expanded(child: pw.Text(v, textAlign: pw.TextAlign.right, style: _t(8.5, bold: true))),
          ],
        ),
      );

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('PREPARED FOR', style: _t(7.5, bold: true, color: _muted, letterSpacing: 1)),
            pw.SizedBox(height: 3),
            pw.Text(d.shopName, style: _t(17, bold: true)),
            if (contact.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Wrap(spacing: 16, runSpacing: 2, children: [for (final c in contact) pw.Text(c, style: _t(9, color: _muted))]),
            ],
          ],
        ),
      ),
      pw.SizedBox(width: 24),
      pw.Container(
        width: 232,
        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: pw.BoxDecoration(color: _zebra, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: _line, width: 0.6)),
        child: pw.Column(children: [
          if (d.scope.isNotEmpty) meta('Scope', d.scope),
          meta('Period', _period(d)),
          if (d.preparedBy.isNotEmpty) meta('Prepared by', d.preparedBy),
        ]),
      ),
    ],
  );
}

pw.Widget _heading(String text, _Look l) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(children: [
        pw.Container(width: 3.5, height: 13, decoration: pw.BoxDecoration(color: l.accent, borderRadius: pw.BorderRadius.circular(2))),
        pw.SizedBox(width: 7),
        pw.Text(text.toUpperCase(), style: _t(10, bold: true, letterSpacing: 0.8)),
      ]),
    );

/// Four cards to a row; a second row appears when returns, profit or expenses are part of the report.
List<pw.Widget> _kpiRows(ReportDoc d, _Look l) {
  pw.Widget card(ReportKpi k) => pw.Expanded(
        child: pw.Container(
          decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: _line, width: 0.8)),
          child: pw.ClipRRect(
            horizontalRadius: 6,
            verticalRadius: 6,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(height: 3, color: l.tone(k.tone)),
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(10, 9, 10, 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(k.label.toUpperCase(), style: _t(7.5, bold: true, color: _muted, letterSpacing: 0.6)),
                      pw.SizedBox(height: 5),
                      // A seven-figure total must shrink, not spill out of its card.
                      pw.FittedBox(
                        fit: pw.BoxFit.scaleDown,
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Text(k.count != null ? _en.intN(k.count!) : l.money(k.paisa ?? 0), style: _t(15, bold: true)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  pw.Widget empty() => pw.Expanded(child: pw.SizedBox());
  final rows = <pw.Widget>[];
  for (var i = 0; i < d.kpis.length; i += 4) {
    final chunk = d.kpis.skip(i).take(4).toList();
    if (i > 0) rows.add(pw.SizedBox(height: 8));
    rows.add(pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      for (var j = 0; j < 4; j++) ...[
        if (j > 0) pw.SizedBox(width: 8),
        j < chunk.length ? card(chunk[j]) : empty(),
      ],
    ]));
  }
  return rows;
}

pw.Widget _bar(double frac, PdfColor color) {
  const scale = 1000;
  final filled = (frac.clamp(0.0, 1.0) * scale).round();
  return pw.ClipRRect(
    horizontalRadius: 3,
    verticalRadius: 3,
    child: pw.SizedBox(
      height: 6,
      child: pw.Row(children: [
        if (filled > 0) pw.Expanded(flex: filled, child: pw.Container(color: color)),
        if (filled < scale) pw.Expanded(flex: scale - filled, child: pw.Container(color: _line)),
      ]),
    ),
  );
}

pw.Widget _paymentBreakdown(ReportDoc d, _Look l) {
  final top = d.payments.fold(0, (a, b) => a > b.amountP ? a : b.amountP);
  final colors = l.p.series;
  return pw.Column(children: [
    for (final (i, m) in d.payments.indexed)
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4.5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(width: 7, height: 7, decoration: pw.BoxDecoration(color: _c(colors[i % colors.length]), borderRadius: pw.BorderRadius.circular(1.5))),
            pw.SizedBox(width: 8),
            pw.SizedBox(width: 74, child: pw.Text(m.label, style: _t(9.5, bold: true))),
            pw.SizedBox(width: 92, child: pw.Text(l.money(m.amountP), textAlign: pw.TextAlign.right, style: _t(9.5, bold: true))),
            pw.SizedBox(width: 46, child: pw.Text('${(d.shareOf(m) * 100).toStringAsFixed(1)}%', textAlign: pw.TextAlign.right, style: _t(9, color: _muted))),
            pw.SizedBox(width: 14),
            pw.Expanded(child: _bar(top <= 0 ? 0 : m.amountP / top, _c(colors[i % colors.length]))),
          ],
        ),
      ),
  ]);
}

pw.Widget _valuation(ReportDoc d, _Look l) {
  pw.Widget row(String label, int paisa, PdfColor tone, {String note = ''}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Row(children: [
          pw.Container(width: 7, height: 7, decoration: pw.BoxDecoration(color: tone, borderRadius: pw.BorderRadius.circular(1.5))),
          pw.SizedBox(width: 8),
          pw.Text(label, style: _t(9.5, bold: true)),
          if (note.isNotEmpty) pw.Text(note, style: _t(8.5, color: _muted)),
          pw.Spacer(),
          pw.Text(l.money(paisa), style: _t(11, bold: true, color: tone)),
        ]),
      );

  final margin = d.marginShare == null ? '' : '  (${(d.marginShare! * 100).toStringAsFixed(1)}% of retail)';
  final rule = pw.Divider(height: 0.6, thickness: 0.6, color: _line);
  final rows = <pw.Widget>[];
  void add(pw.Widget w) {
    if (rows.isNotEmpty) rows.add(rule);
    rows.add(w);
  }

  if (d.costValueP != null) add(row('Stock value (at cost)', d.costValueP!, l.tone('blue')));
  add(row('Stock value (at retail)', d.retailValueP!, l.accent));
  if (d.potentialP != null) add(row('Potential margin', d.potentialP!, l.tone('violet'), note: margin));

  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    decoration: pw.BoxDecoration(borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: _line, width: 0.8)),
    child: pw.Column(children: rows),
  );
}

pw.Widget _empty(String text) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 14),
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(color: _zebra, borderRadius: pw.BorderRadius.circular(6), border: pw.Border.all(color: _line, width: 0.6)),
      child: pw.Text(text, style: _t(9, color: _muted)),
    );

/// A zebra-striped table whose header row repeats on every page it runs onto. Columns in [right] are right-aligned.
pw.Widget _table({
  required _Look look,
  required List<String> head,
  required List<List<String>> rows,
  required Map<int, pw.TableColumnWidth> widths,
  Set<int> right = const {},
}) {
  pw.Widget cell(String s, int col, {bool header = false, bool bold = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: pw.Text(
          s,
          textAlign: right.contains(col) ? pw.TextAlign.right : pw.TextAlign.left,
          style: header ? _t(7.5, bold: true, color: _white, letterSpacing: 0.5) : _t(8.5, bold: bold),
        ),
      );

  return pw.Table(
    columnWidths: widths,
    border: const pw.TableBorder(bottom: pw.BorderSide(color: _line, width: 0.8), horizontalInside: pw.BorderSide(color: _line, width: 0.4)),
    children: [
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(color: look.deep),
        children: [for (var c = 0; c < head.length; c++) cell(head[c].toUpperCase(), c, header: true)],
      ),
      for (var r = 0; r < rows.length; r++)
        pw.TableRow(
          decoration: r.isOdd ? const pw.BoxDecoration(color: _zebra) : null,
          children: [for (var c = 0; c < rows[r].length; c++) cell(rows[r][c], c, bold: c == 0)],
        ),
    ],
  );
}

pw.Widget _topProducts(ReportDoc d, _Look l) {
  if (d.topProducts.isEmpty) return _empty('No itemised sales recorded yet.');
  return _table(
    look: l,
    head: const ['#', 'Product', 'Units sold', 'Revenue'],
    right: const {0, 2, 3},
    widths: const {0: pw.FixedColumnWidth(28), 1: pw.FlexColumnWidth(5), 2: pw.FlexColumnWidth(1.6), 3: pw.FlexColumnWidth(2.2)},
    rows: [
      for (final (n, p) in d.topProducts.indexed) ['${n + 1}', p.name, _en.qty(p.qtyMilli), l.money(p.revenueP)],
    ],
  );
}

List<pw.Widget> _register(ReportDoc d, _Look l) {
  if (d.register.isEmpty) return [_empty('No invoices recorded yet.')];
  return [
    _table(
      look: l,
      head: const ['Invoice', 'Date', 'Customer', 'Payment', 'Total', 'Due'],
      right: const {4, 5},
      widths: const {0: pw.FlexColumnWidth(2.1), 1: pw.FlexColumnWidth(2.6), 2: pw.FlexColumnWidth(3), 3: pw.FlexColumnWidth(1.8), 4: pw.FlexColumnWidth(2), 5: pw.FlexColumnWidth(1.7)},
      rows: [
        for (final s in d.register) [s.invoiceNo, _rowStamp.format(s.soldAt), s.customer, s.payment, l.money(s.totalP), s.dueP > 0 ? l.money(s.dueP) : '-'],
      ],
    ),
    if (d.registerTotal > d.register.length)
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Text(
          'Showing the latest ${_en.intN(d.register.length)} of ${_en.intN(d.registerTotal)} invoices. Totals above cover all of them.',
          style: _t(8, color: _muted),
        ),
      ),
  ];
}

pw.Widget _footer(ReportDoc d, _Look l, pw.Context ctx) => pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 7),
      decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: _line, width: 0.8))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${ReportBrand.product}  |  ${d.shopName}', style: _t(8, bold: true, color: l.accent)),
                pw.SizedBox(height: 2),
                pw.Text('Confidential - prepared for ${d.shopName}. Amounts in Bangladeshi Taka (${d.currency}).', style: _t(7, color: _muted)),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: _t(8, color: _muted)),
        ],
      ),
    );
