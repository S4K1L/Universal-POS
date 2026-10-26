import 'package:flutter/material.dart';

import '../../core/money/money.dart';
import '../../data/models/context.dart';

/// Colours for the report, worked out from the business's own accent so the printed sheet matches its till.
/// The supporting tones stay fixed so a "due" or "returns" figure always reads the same.
class ReportPalette {
  ReportPalette(this.accent)
      : lite = Color.lerp(accent, Colors.white, 0.18)!,
        deep = HSLColor.fromColor(accent).withLightness((HSLColor.fromColor(accent).lightness - 0.12).clamp(0.12, 0.9)).toColor(),
        soft = Color.lerp(accent, Colors.white, 0.88)!;

  final Color accent, lite, deep, soft;

  static const blue = Color(0xFF2563EB);
  static const violet = Color(0xFF7C3AED);
  static const amber = Color(0xFFB45309);
  static const red = Color(0xFFC0362C);
  static const green = Color(0xFF15803D);

  /// Payment methods take these in order, so the biggest is always the brand colour.
  List<Color> get series => [accent, blue, violet, amber, red, green];

  Color tone(String name) => switch (name) {
        'blue' => blue,
        'violet' => violet,
        'amber' => amber,
        'red' => red,
        'green' => green,
        _ => accent,
      };
}

class ReportKpi {
  const ReportKpi(this.label, {this.paisa, this.count, this.tone = 'accent'});
  final String label;
  final int? paisa;
  final int? count;
  final String tone;
}

class ReportPayment {
  const ReportPayment(this.label, this.amountP);
  final String label;
  final int amountP;
}

class ReportProduct {
  const ReportProduct(this.name, this.qtyMilli, this.revenueP);
  final String name;
  final int qtyMilli, revenueP;
}

class ReportInvoice {
  const ReportInvoice({required this.id, required this.invoiceNo, required this.soldAt, required this.customer, required this.payment, required this.totalP, required this.dueP});
  final String id, invoiceNo, customer, payment;
  final DateTime soldAt;
  final int totalP, dueP;
}

/// Everything the report shows, already worked out, so the screen and the PDF can never disagree.
class ReportDoc {
  const ReportDoc({
    required this.shopName,
    this.address = '',
    this.city = '',
    this.phone = '',
    this.scope = '',
    this.preparedBy = '',
    required this.generatedAt,
    required this.from,
    required this.to,
    required this.accent,
    this.currency = 'Tk',
    required this.kpis,
    required this.payments,
    this.costValueP,
    this.retailValueP,
    this.potentialP,
    this.topProducts = const [],
    this.register = const [],
    this.registerTotal = 0,
  });

  /// How many invoices the register lists — a year of trading is a PDF nobody can open on a phone.
  static const registerLimit = 100;
  static const topProductLimit = 10;

  final String shopName, address, city, phone, scope, preparedBy, currency;
  final DateTime generatedAt, from, to;
  final Color accent;
  final List<ReportKpi> kpis;
  final List<ReportPayment> payments;
  final int? costValueP, retailValueP, potentialP;
  final List<ReportProduct> topProducts;
  final List<ReportInvoice> register;
  final int registerTotal;

  ReportPalette get palette => ReportPalette(accent);
  bool get hasValuation => retailValueP != null;
  int get paymentTotalP => payments.fold(0, (a, p) => a + p.amountP);
  double shareOf(ReportPayment p) => paymentTotalP <= 0 ? 0 : p.amountP / paymentTotalP;
  double? get marginShare => (potentialP == null || (retailValueP ?? 0) <= 0) ? null : potentialP! / retailValueP!;

  /// Builds the report from what the Reports screen already fetched.
  factory ReportDoc.fromData(Map<String, dynamic> d, TenantContext ctx, {required DateTime from, required DateTime to, required List<Map<String, dynamic>> register, required int registerTotal}) {
    final s = (d['summary'] as Map).cast<String, dynamic>();
    final val = (d['valuation'] as Map?)?.cast<String, dynamic>();
    final exp = (d['expenses'] as Map?)?.cast<String, dynamic>();
    final top = (d['top'] as List).cast<Map<String, dynamic>>();
    final methods = (s['by_method'] as List).cast<Map<String, dynamic>>();
    final returns = parsePaisa(s['returns_total']);

    String methodLabel(String code) => ctx.paymentMethods.where((m) => m.code == code).firstOrNull?.label ?? (code.isEmpty ? code : code[0].toUpperCase() + code.substring(1).replaceAll('_', ' '));

    String paymentOf(Map<String, dynamic> sale) {
      final used = <String>[];
      for (final p in (sale['payments'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        if (p['kind'] == 'return') continue;
        final l = methodLabel(p['method'] as String);
        if (!used.contains(l)) used.add(l);
      }
      if (used.isNotEmpty) return used.join(' + ');
      return parsePaisa(sale['due']) > 0 ? 'Due (Credit)' : '-';
    }

    return ReportDoc(
      shopName: ctx.businessName,
      address: ctx.businessAddress,
      city: ctx.businessCity,
      phone: ctx.businessPhone,
      scope: ctx.branches.length > 1 ? 'All branches' : (ctx.mainBranch?.name ?? 'All branches'),
      preparedBy: ctx.userName,
      generatedAt: DateTime.now(),
      from: from,
      to: to,
      accent: ctx.accent,
      currency: ctx.currencySymbol == '৳' ? 'Tk' : ctx.currencySymbol,
      kpis: [
        ReportKpi('Total sales', paisa: parsePaisa(s['gross_sales'])),
        ReportKpi('Invoices', count: (s['invoices'] as num).toInt(), tone: 'blue'),
        ReportKpi('Avg. bill', paisa: parsePaisa(s['avg_bill']), tone: 'violet'),
        ReportKpi('Total due', paisa: parsePaisa(s['due_created']), tone: 'amber'),
        if (returns > 0) ReportKpi('Returns', paisa: returns, tone: 'red'),
        if (returns > 0) ReportKpi('Net sales', paisa: parsePaisa(s['net_sales']), tone: 'green'),
        if (s['gross_profit'] != null) ReportKpi('Gross profit', paisa: parsePaisa(s['gross_profit']), tone: 'green'),
        if (exp != null) ReportKpi('Expenses', paisa: parsePaisa(exp['total']), tone: 'amber'),
      ],
      payments: [for (final m in methods) ReportPayment(methodLabel(m['method'] as String), parsePaisa(m['amount']))],
      costValueP: val?['cost_value'] == null ? null : parsePaisa(val!['cost_value']),
      retailValueP: val == null ? null : parsePaisa(val['retail_value']),
      potentialP: val?['potential_profit'] == null ? null : parsePaisa(val!['potential_profit']),
      topProducts: [for (final p in top.take(topProductLimit)) ReportProduct(p['name'] as String, parseMilli(p['qty']), parsePaisa(p['revenue']))],
      register: [
        for (final sale in register)
          ReportInvoice(
            id: sale['id'] as String,
            invoiceNo: sale['invoice_no'] as String,
            soldAt: DateTime.parse(sale['sold_at'] as String).toLocal(),
            customer: (sale['customer_name'] as String?) ?? 'Walk-in',
            payment: paymentOf(sale),
            totalP: parsePaisa(sale['total']),
            dueP: parsePaisa(sale['due']),
          ),
      ],
      registerTotal: registerTotal,
    );
  }
}
