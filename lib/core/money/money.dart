/// Exact money and quantity arithmetic on integers.
///
/// Money is whole **paisa**, quantities whole **thousandths** of a unit. Binary floats are never used
/// for anything that gets added up, so a receipt printed offline matches what the server later books to
/// the paisa. The server speaks decimal *strings* ("12.50", "1.250"); these helpers convert both ways.
library;

/// Half-up integer division for a non-negative numerator and a positive divisor.
int roundDiv(int a, int b) {
  assert(b > 0);
  if (a >= 0) return (2 * a + b) ~/ (2 * b);
  return -((2 * -a + b) ~/ (2 * b));
}

/// "12.50" -> 1250. Accepts "12", "12.5", "-3.07"; anything beyond 2 dp is rounded half-up.
int parsePaisa(Object? v) => _parseScaled(v, 2);

/// "1.250" -> 1250.
int parseMilli(Object? v) => _parseScaled(v, 3);

int _parseScaled(Object? v, int dp) {
  if (v == null) return 0;
  if (v is int) return v * _pow10(dp);
  if (v is double) return (v * _pow10(dp)).round();
  var s = v.toString().trim();
  if (s.isEmpty) return 0;
  final neg = s.startsWith('-');
  if (neg) s = s.substring(1);
  final parts = s.split('.');
  final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]) ?? 0;
  var frac = parts.length > 1 ? parts[1] : '';
  var carry = 0;
  if (frac.length > dp) {
    carry = int.parse(frac[dp]) >= 5 ? 1 : 0;
    frac = frac.substring(0, dp);
  }
  frac = frac.padRight(dp, '0');
  final value = whole * _pow10(dp) + int.parse(frac) + carry;
  return neg ? -value : value;
}

int _pow10(int n) => n == 2 ? 100 : (n == 3 ? 1000 : 1);

/// 1250 -> "12.50" (wire format).
String paisaToWire(int p) => _scaledToWire(p, 2);

/// 1250 -> "1.250" (wire format).
String milliToWire(int m) => _scaledToWire(m, 3);

String _scaledToWire(int v, int dp) {
  final neg = v < 0;
  final abs = v.abs();
  final unit = _pow10(dp);
  final s = '${abs ~/ unit}.${(abs % unit).toString().padLeft(dp, '0')}';
  return neg ? '-$s' : s;
}

/// Tax rate "7.5" -> 750 (hundredths of a percent).
int parseRateBp(Object? v) => _parseScaled(v, 2);
