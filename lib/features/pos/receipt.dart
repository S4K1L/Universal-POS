import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/i18n/lang.dart';
import '../../core/money/money.dart';
import '../../core/theme/theme.dart';
import '../../core/ui/kit.dart';
import '../../data/models/context.dart';
import '../../data/repos/sales_repo.dart';

class ReceiptLine {
  ReceiptLine({required this.name, required this.detail, required this.qtyText, required this.unitPriceP, required this.totalP, this.discountP = 0, this.warrantyMonths = 0, this.note = ''});
  final String name, detail, qtyText, note;
  final int unitPriceP, totalP, discountP, warrantyMonths;
}

class ReceiptPay {
  ReceiptPay(this.label, this.amountP, this.reference);
  final String label, reference;
  final int amountP;
}

class ReceiptData {
  ReceiptData({
    required this.shopName,
    required this.address,
    required this.phone,
    required this.vatNo,
    required this.footer,
    required this.invoiceNo,
    required this.when,
    required this.cashier,
    required this.customer,
    required this.lines,
    required this.subtotalP,
    required this.discountP,
    required this.taxP,
    required this.taxMode,
    required this.roundingP,
    required this.totalP,
    required this.paidP,
    required this.payments,
    this.changeP = 0,
    this.pointsEarned = 0,
    this.syncState = 'synced',
    this.voided = false,
  });

  final String shopName, address, phone, vatNo, footer, invoiceNo, cashier, customer, taxMode, syncState;
  final DateTime when;
  final List<ReceiptLine> lines;
  final List<ReceiptPay> payments;
  final int subtotalP, discountP, taxP, roundingP, totalP, paidP, changeP, pointsEarned;
  final bool voided;
  int get dueP => (totalP - paidP) < 0 ? 0 : totalP - paidP;

  static String _methodLabel(TenantContext ctx, String code) {
    if (code == 'return_credit') return 'Return credit';
    return ctx.paymentMethods.where((m) => m.code == code).firstOrNull?.label ?? code;
  }

  factory ReceiptData.fromBundle(SaleBundle b, TenantContext ctx, {int changeP = 0}) {
    final r = ctx.receipt;
    String qtyText(int qtyMilli, String unit) => '${const Fmt(AppLang.en).qty(qtyMilli)} $unit';
    return ReceiptData(
      shopName: (r['header'] as String?)?.isNotEmpty == true ? r['header'] as String : ctx.businessName,
      address: (r['address'] as String?) ?? ctx.businessAddress,
      phone: (r['phone'] as String?) ?? ctx.businessPhone,
      vatNo: (r['vat_reg_no'] as String?) ?? '',
      footer: (r['footer'] as String?) ?? '',
      invoiceNo: b.sale.invoiceNo,
      when: b.sale.soldAt,
      cashier: b.sale.cashierName,
      customer: b.sale.customerName,
      lines: [
        for (final l in b.lines)
          ReceiptLine(name: l.productName, detail: l.variantLabel, qtyText: qtyText(l.qtyMilli, l.unit), unitPriceP: l.unitPriceP, totalP: l.netP, discountP: l.discountP, warrantyMonths: l.warrantyMonths, note: l.note),
      ],
      subtotalP: b.sale.subtotalP,
      discountP: b.sale.discountP,
      taxP: b.sale.taxP,
      taxMode: b.sale.taxMode,
      roundingP: b.sale.roundingP,
      totalP: b.sale.totalP,
      paidP: b.sale.paidP,
      payments: [for (final p in b.payments) ReceiptPay(_methodLabel(ctx, p.method), p.amountP, p.reference)],
      changeP: changeP,
      pointsEarned: b.sale.pointsEarned,
      syncState: b.sale.syncState,
      voided: b.sale.status == 'voided',
    );
  }

  /// From a sale the server sent (`SaleOut`), e.g. one made on another till.
  factory ReceiptData.fromServer(Map<String, dynamic> s, TenantContext ctx) {
    final r = ctx.receipt;
    final f = const Fmt(AppLang.en);
    return ReceiptData(
      shopName: (r['header'] as String?)?.isNotEmpty == true ? r['header'] as String : ctx.businessName,
      address: (r['address'] as String?) ?? ctx.businessAddress,
      phone: (r['phone'] as String?) ?? ctx.businessPhone,
      vatNo: (r['vat_reg_no'] as String?) ?? '',
      footer: (r['footer'] as String?) ?? '',
      invoiceNo: s['invoice_no'] as String,
      when: DateTime.parse(s['sold_at'] as String),
      cashier: (s['cashier_name'] as String?) ?? '',
      customer: (s['customer_name'] as String?) ?? 'Walk-in',
      lines: [
        for (final l in (s['lines'] as List).cast<Map<String, dynamic>>())
          ReceiptLine(
            name: l['product_name'] as String,
            detail: (l['variant_label'] as String?) ?? '',
            qtyText: '${f.qty(parseMilli(l['qty']))} ${l['unit']}',
            unitPriceP: parsePaisa(l['unit_price']),
            totalP: parsePaisa(l['line_total']),
            discountP: parsePaisa(l['discount']),
            warrantyMonths: (l['warranty_months'] as num?)?.toInt() ?? 0,
            note: (l['note'] as String?) ?? '',
          ),
      ],
      subtotalP: parsePaisa(s['subtotal']),
      discountP: parsePaisa(s['discount']),
      taxP: parsePaisa(s['tax_total']),
      taxMode: (s['tax_mode'] as String?) ?? 'inclusive',
      roundingP: parsePaisa(s['rounding']),
      totalP: parsePaisa(s['total']),
      paidP: parsePaisa(s['paid']),
      payments: [for (final p in (s['payments'] as List).cast<Map<String, dynamic>>()) ReceiptPay(_methodLabel(ctx, p['method'] as String), parsePaisa(p['amount']), (p['reference'] as String?) ?? '')],
      pointsEarned: (s['points_earned'] as num?)?.toInt() ?? 0,
      voided: s['status'] == 'voided',
    );
  }
}

/// A paper-white receipt, whatever the app theme is: what you see is what the printer gets.
class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key, required this.data, this.boundaryKey, this.width = 340});
  final ReceiptData data;
  final GlobalKey? boundaryKey;
  final double width;

  @override
  Widget build(BuildContext context) {
    final f = context.fmt;
    const ink = Color(0xFF16201B);
    const faint = Color(0xFF6B7570);
    TextStyle s(double size, {int w = 500, Color c = ink}) => TextStyle(fontSize: size, color: c, fontWeight: FontWeight.values[(w ~/ 100) - 1], fontVariations: [FontVariation('wght', w.toDouble())], fontFeatures: tabular, height: 1.3, fontFamily: 'PJS', fontFamilyFallback: const ['Hind']);
    Widget dash() => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: LayoutBuilder(builder: (_, c) => Text('- ' * (c.maxWidth ~/ 9), maxLines: 1, overflow: TextOverflow.clip, style: s(12, c: faint))));
    Widget row(String l, String r, {bool bold = false, double size = 13, Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(l, style: s(size, w: bold ? 800 : 500, c: color ?? ink))), Text(r, style: s(size, w: bold ? 800 : 600, c: color ?? ink))]),
        );

    final content = Container(
      width: width,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(data.shopName, textAlign: TextAlign.center, style: s(19, w: 800)),
        if (data.address.isNotEmpty) Text(data.address, textAlign: TextAlign.center, style: s(11.5, c: faint)),
        if (data.phone.isNotEmpty) Text(f.digits(data.phone), textAlign: TextAlign.center, style: s(11.5, c: faint)),
        if (data.vatNo.isNotEmpty) Text('${context.tr('VAT reg')}: ${f.digits(data.vatNo)}', textAlign: TextAlign.center, style: s(11.5, c: faint)),
        dash(),
        row(context.tr('Invoice'), data.invoiceNo, bold: true),
        row(context.tr('Date'), f.dateTime(data.when), size: 12),
        if (data.cashier.isNotEmpty) row(context.tr('Cashier'), data.cashier, size: 12),
        if (data.customer.isNotEmpty && data.customer != 'Walk-in') row(context.tr('Customer'), data.customer, size: 12),
        if (data.voided) Padding(padding: const EdgeInsets.only(top: 6), child: Center(child: Text(context.tr('VOID'), style: s(20, w: 800, c: const Color(0xFFE5484D))))),
        dash(),
        for (final l in data.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.detail.isEmpty ? l.name : '${l.name} — ${l.detail}', style: s(13, w: 700)),
              Row(children: [
                Expanded(child: Text('${f.digits(l.qtyText)} × ${f.money(l.unitPriceP, symbol: false, decimals: true)}', style: s(12, c: faint))),
                Text(f.money(l.totalP, symbol: false, decimals: true), style: s(13, w: 700)),
              ]),
              if (l.discountP > 0) Text('${context.tr('Discount')} −${f.money(l.discountP, symbol: false, decimals: true)}', style: s(11.5, c: faint)),
              if (l.warrantyMonths > 0) Text('${context.tr('Warranty')}: ${f.digits('${l.warrantyMonths}')} ${context.tr('months')}', style: s(11.5, c: faint)),
              if (l.note.isNotEmpty) Text(l.note, style: s(11.5, c: faint)),
            ]),
          ),
        dash(),
        row(context.tr('Subtotal'), f.money(data.subtotalP, decimals: true)),
        if (data.discountP > 0) row(context.tr('Discount'), '−${f.money(data.discountP, decimals: true)}'),
        if (data.taxP > 0) row(data.taxMode == 'inclusive' ? context.tr('incl. VAT') : context.tr('VAT'), f.money(data.taxP, decimals: true)),
        if (data.roundingP != 0) row(context.tr('Rounding'), f.money(data.roundingP, decimals: true, sign: true)),
        const SizedBox(height: 4),
        row(context.tr('TOTAL'), f.money(data.totalP, decimals: true), bold: true, size: 18),
        dash(),
        for (final p in data.payments) row(p.reference.isEmpty ? context.tr(p.label) : '${context.tr(p.label)} · ${p.reference}', f.money(p.amountP, decimals: true), size: 12.5),
        if (data.changeP > 0) row(context.tr('Change'), f.money(data.changeP, decimals: true), bold: true, size: 13),
        if (data.dueP > 0) row(context.tr('DUE'), f.money(data.dueP, decimals: true), bold: true, size: 15, color: const Color(0xFFD13438)),
        if (data.pointsEarned > 0) Padding(padding: const EdgeInsets.only(top: 6), child: Text('${context.tr('Points earned')}: ${f.digits('${data.pointsEarned}')}', textAlign: TextAlign.center, style: s(12, c: faint))),
        dash(),
        if (data.footer.isNotEmpty) Text(data.footer, textAlign: TextAlign.center, style: s(12.5, w: 600)),
        // Scanned on the Sales screen to pull this sale up: a QR for phone cameras, Code 128 for laser scanners.
        if (data.invoiceNo.isNotEmpty) ...[
          const SizedBox(height: 12),
          Center(child: BarcodeWidget(barcode: Barcode.qrCode(), data: data.invoiceNo, width: 92, height: 92, color: ink, drawText: false)),
          const SizedBox(height: 8),
          BarcodeWidget(barcode: Barcode.code128(), data: data.invoiceNo, height: 40, color: ink, drawText: false),
          const SizedBox(height: 4),
          Text(data.invoiceNo, textAlign: TextAlign.center, style: s(10.5, c: faint)),
        ],
        if (data.syncState == 'pending')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(context.tr('Saved on this till — syncs automatically'), textAlign: TextAlign.center, style: s(10.5, c: faint)),
          ),
      ]),
    );
    final clipped = ClipPath(clipper: _Teeth(), child: content);
    return boundaryKey == null ? clipped : RepaintBoundary(key: boundaryKey, child: clipped);
  }
}

class _Teeth extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const tooth = 9.0;
    final p = Path()..moveTo(0, 0)..lineTo(s.width, 0)..lineTo(s.width, s.height - tooth);
    var x = s.width;
    var down = false;
    while (x > 0) {
      x = (x - tooth).clamp(0, s.width);
      p.lineTo(x, s.height - (down ? 0 : tooth));
      down = !down;
    }
    return p..close();
  }

  @override
  bool shouldReclip(_Teeth old) => false;
}

class ReceiptPrinter {
  /// Rasterise the on-screen receipt (so Bangla and every font renders exactly as shown) and hand it to the
  /// system print dialog as an 80 mm roll page.
  static Future<Uint8List> pdfOf(GlobalKey key) async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
    final doc = pw.Document();
    final mem = pw.MemoryImage(bytes);
    const widthPt = 80 * PdfPageFormat.mm;
    final heightPt = widthPt * image.height / image.width;
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(widthPt, heightPt, marginAll: 0),
      build: (_) => pw.Image(mem, fit: pw.BoxFit.fill),
    ));
    return doc.save();
  }

  static Future<void> print(GlobalKey key, String name) async {
    final pdf = await pdfOf(key);
    await Printing.layoutPdf(onLayout: (_) async => pdf, name: name, format: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity));
  }

  static Future<void> share(GlobalKey key, String name) async {
    final pdf = await pdfOf(key);
    await Printing.sharePdf(bytes: pdf, filename: '$name.pdf');
  }
}

/// The receipt panel shown after a sale (and when re-opening one from history).
class ReceiptPanel extends StatefulWidget {
  const ReceiptPanel({super.key, required this.data, this.onNewSale});
  final ReceiptData data;
  final VoidCallback? onNewSale;

  @override
  State<ReceiptPanel> createState() => _ReceiptPanelState();
}

class _ReceiptPanelState extends State<ReceiptPanel> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _run(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) toast(context, 'Could not prepare the receipt: $e', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.56),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: Center(child: ReceiptView(data: d, boundaryKey: _key))),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _run(() => ReceiptPrinter.print(_key, d.invoiceNo)), icon: const Icon(Icons.print_rounded, size: 19), label: Text(context.tr('Print')))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _run(() => ReceiptPrinter.share(_key, d.invoiceNo)), icon: const Icon(Icons.ios_share_rounded, size: 19), label: Text(context.tr('Share')))),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onNewSale?.call();
              },
              child: Text(context.tr(widget.onNewSale == null ? 'Done' : 'New sale')),
            ),
          ),
        ]),
      ),
    ]);
  }
}
