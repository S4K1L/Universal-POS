import 'money.dart';

/// The one pricing algorithm — a line-for-line twin of backend `app/services/pricing.py`.
///
///   gross = unit price × qty                   (per line, to the paisa)
///   net   = max(gross − line discount, 0)
///   the bill discount is spread over lines pro rata to `net` (the last line takes the remainder)
///   tax   = inclusive: taxable × r ÷ (100 + r)  |  exclusive: taxable × r ÷ 100
///   total = Σ taxable (+ Σ tax when exclusive), then optional cash rounding to the nearest taka
///
/// `docs/pricing_vectors.json` holds golden cases generated from the Python implementation; the tests
/// replay all of them here, which is what keeps the till and the server agreeing to the last paisa.
class LineInput {
  const LineInput({required this.unitPrice, required this.qtyMilli, this.discount = 0, this.taxRateBp = 0});

  final int unitPrice; // paisa per selling unit
  final int qtyMilli;
  final int discount; // paisa
  final int taxRateBp; // hundredths of a percent
}

class PricedLine {
  const PricedLine({required this.gross, required this.net, required this.share, required this.taxable, required this.tax, required this.total});

  final int gross, net, share, taxable, tax, total;
}

class PricedCart {
  const PricedCart({
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.taxTotal,
    required this.preRoundTotal,
    required this.rounding,
    required this.total,
  });

  final List<PricedLine> lines;
  final int subtotal, discount, taxTotal, preRoundTotal, rounding, total;

  static const empty = PricedCart(lines: [], subtotal: 0, discount: 0, taxTotal: 0, preRoundTotal: 0, rounding: 0, total: 0);
}

enum TaxMode { inclusive, exclusive }

PricedCart priceCart(
  List<LineInput> lines, {
  int billDiscount = 0,
  TaxMode taxMode = TaxMode.inclusive,
  bool cashRounding = false,
}) {
  if (lines.isEmpty) return PricedCart.empty;
  final grosses = [for (final l in lines) roundDiv(l.unitPrice * l.qtyMilli, 1000)];
  final nets = <int>[
    for (var i = 0; i < lines.length; i++) _max(grosses[i] - _min(lines[i].discount, grosses[i]), 0),
  ];
  final subtotal = nets.fold<int>(0, (a, b) => a + b);
  final discount = _min(_max(billDiscount, 0), subtotal);

  final shares = <int>[];
  var allocated = 0;
  for (var i = 0; i < nets.length; i++) {
    int share;
    if (i == nets.length - 1) {
      share = _min(_max(discount - allocated, 0), nets[i]);
    } else if (subtotal > 0) {
      share = roundDiv(discount * nets[i], subtotal);
    } else {
      share = 0;
    }
    shares.add(share);
    allocated += share;
  }

  final priced = <PricedLine>[];
  for (var i = 0; i < lines.length; i++) {
    final taxable = nets[i] - shares[i];
    final r = lines[i].taxRateBp;
    int tax;
    if (r <= 0) {
      tax = 0;
    } else if (taxMode == TaxMode.inclusive) {
      tax = roundDiv(taxable * r, 10000 + r);
    } else {
      tax = roundDiv(taxable * r, 10000);
    }
    final total = taxMode == TaxMode.inclusive ? taxable : taxable + tax;
    priced.add(PricedLine(gross: grosses[i], net: nets[i], share: shares[i], taxable: taxable, tax: tax, total: total));
  }

  final preRound = priced.fold<int>(0, (a, p) => a + p.total);
  var total = preRound;
  var rounding = 0;
  if (cashRounding) {
    total = roundDiv(preRound, 100) * 100;
    rounding = total - preRound;
  }
  return PricedCart(
    lines: priced,
    subtotal: subtotal,
    discount: discount,
    taxTotal: priced.fold<int>(0, (a, p) => a + p.tax),
    preRoundTotal: preRound,
    rounding: rounding,
    total: total,
  );
}

int _min(int a, int b) => a < b ? a : b;
int _max(int a, int b) => a > b ? a : b;
