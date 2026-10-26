import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_pos/core/ui/brand.dart';
import 'package:universal_pos/features/reports/report_doc.dart';
import 'package:universal_pos/features/reports/report_pdf.dart';

import 'support/harness.dart' show Fixtures;

ReportDoc sample({int invoices = 30, bool valuation = true, int topN = 10, Color accent = const Color(0xFF0E9F6E)}) => ReportDoc(
      shopName: 'Rahim General Store',
      city: 'Dhanmondi',
      address: 'Road 27, Dhaka',
      phone: '01711000001',
      scope: 'All branches',
      preparedBy: 'Shakil Ahmed',
      generatedAt: DateTime(2026, 10, 26, 11, 46),
      from: DateTime(2026, 8, 14),
      to: DateTime(2026, 10, 5),
      accent: accent,
      kpis: const [
        ReportKpi('Total sales', paisa: 123456750),
        ReportKpi('Invoices', count: 1234, tone: 'blue'),
        ReportKpi('Avg. bill', paisa: 14342, tone: 'violet'),
        ReportKpi('Total due', paisa: 100690, tone: 'amber'),
        ReportKpi('Returns', paisa: 25000, tone: 'red'),
        ReportKpi('Net sales', paisa: 123431750, tone: 'green'),
        ReportKpi('Gross profit', paisa: 31000000, tone: 'green'),
      ],
      payments: const [ReportPayment('Cash', 92166), ReportPayment('Card', 26620), ReportPayment('bKash', 16870), ReportPayment('Nagad', 1360)],
      costValueP: 987020,
      retailValueP: 1372280,
      potentialP: 385260,
      topProducts: [for (var i = 0; i < topN; i++) ReportProduct(i == 3 ? 'আটা ২ কেজি' : 'Seclo 20mg #$i', 209000 - i * 9000, 146300 - i * 9000)],
      register: [
        for (var i = 0; i < invoices; i++)
          ReportInvoice(
            id: 'id$i',
            invoiceNo: 'INV-K7Q2-${(900 + i).toString().padLeft(6, '0')}',
            soldAt: DateTime(2026, 10, 5, 5, 16).subtract(Duration(hours: i * 7)),
            customer: i == 2 ? 'সাব্বির আহমেদ' : (i.isEven ? 'Walk-in' : 'Abdul Karim'),
            payment: i % 5 == 0 ? 'Due (Credit)' : (i % 3 == 0 ? 'bKash' : 'Cash'),
            totalP: 66500 - i * 700,
            dueP: i % 5 == 0 ? 36500 : 0,
          ),
      ],
      registerTotal: 1234,
    );

/// The words a reader would see, in drawing order. The PDF writes one `[(word)]TJ` per word, so a phrase cannot be
/// searched for in the raw bytes.
String _visibleText(Uint8List bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);
  final stream = raw.substring(raw.indexOf('stream'));
  return RegExp(r'\[\((.*?)\)\]TJ').allMatches(stream).map((m) => m.group(1)!.replaceAll(r'\(', '(').replaceAll(r'\)', ')')).join(' ');
}

int _pages(Uint8List bytes) {
  final m = RegExp(r'/Type\s*/Pages[^>]*?/Count\s+(\d+)').firstMatch(latin1.decode(bytes, allowInvalid: true));
  return int.parse(m!.group(1)!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the PDF is a real, multi-page A4 document carrying the shop and the figures', () async {
    final bytes = await buildReportPdf(sample(), compress: false);
    expect(latin1.decode(bytes.sublist(0, 4)), '%PDF');
    final text = _visibleText(bytes);
    expect(text, contains('BUSINESS REPORT'));
    expect(text, contains('Rahim General Store'));
    expect(text, contains('Shakil Ahmed'));
    expect(text, contains('Generated 26 Oct 2026, 11:46 AM'));
    expect(text, contains('Tk 12,34,567.50')); // Bangladeshi digit grouping
    expect(text, contains('INVOICE REGISTER'));
    expect(text, contains('Showing the latest 30 of 1,234 invoices'));
    expect(_pages(bytes), greaterThanOrEqualTo(2));
    expect(text, contains('Page 1 of ${_pages(bytes)}'));
  });

  test('a business with no sales and no valuation still produces a report', () async {
    final empty = ReportDoc(
      shopName: 'New Shop',
      generatedAt: DateTime(2026, 10, 26),
      from: DateTime(2026, 10, 26),
      to: DateTime(2026, 10, 26),
      accent: const Color(0xFF0E9F6E),
      kpis: const [ReportKpi('Total sales', paisa: 0), ReportKpi('Invoices', count: 0, tone: 'blue'), ReportKpi('Avg. bill', paisa: 0, tone: 'violet'), ReportKpi('Total due', paisa: 0, tone: 'amber')],
      payments: const [],
    );
    final text = _visibleText(await buildReportPdf(empty, compress: false));
    expect(text, contains('No itemised sales recorded yet.'));
    expect(text, contains('No invoices recorded yet.'));
    expect(text.contains('INVENTORY VALUATION'), isFalse);
    expect(text.contains('SALES BY PAYMENT METHOD'), isFalse);
  });

  test('the report is built from the same figures the API returned', () {
    final fx = Fixtures.load();
    final summary = (fx['report_summary'] as Map).cast<String, dynamic>();
    final sales = (fx['sales_supershop'] as Map).cast<String, dynamic>();
    final doc = ReportDoc.fromData(
      {'summary': summary, 'top': fx['report_top_products'], 'valuation': fx['report_stock_valuation'], 'expenses': null},
      fx.context('supershop'),
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 26),
      register: (sales['items'] as List).cast<Map<String, dynamic>>(),
      registerTotal: sales['total'] as int,
    );
    expect(doc.kpis.first.label, 'Total sales');
    expect(doc.kpis[1].count, summary['invoices']);
    expect(doc.payments.length, (summary['by_method'] as List).length);
    expect(doc.paymentTotalP, greaterThan(0));
    expect(doc.hasValuation, isTrue);
    expect(doc.register.length, (sales['items'] as List).length);
    expect(doc.register.first.invoiceNo, (sales['items'] as List).first['invoice_no']);
    expect(doc.registerTotal, sales['total']);
  });

  test('render a sample to look at', () async {
    final out = Platform.environment['REPORT_PDF_OUT'];
    if (out == null) return;
    final logo = await brandMarkPng(Colors.white, const Color(0xFF0E9F6E));
    final hind = pw.Font.ttf(ByteData.view(File('assets/fonts/HindSiliguri-Regular.ttf').readAsBytesSync().buffer));
    File(out).writeAsBytesSync(await buildReportPdf(sample(), logo: logo, fallbackFont: hind));
  });
}
