import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../data/models/context.dart';
import '../money/money.dart';
import 'bn.dart';

enum AppLang { en, bn }

/// Provides the active language to the tree. Strings are looked up by their English text, so screens read
/// naturally (`context.t('Charge')`) and any string without a Bangla entry simply stays English.
class LangScope extends InheritedWidget {
  const LangScope({super.key, required this.lang, required super.child});

  final AppLang lang;

  static AppLang of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<LangScope>()?.lang ?? AppLang.en;

  @override
  bool updateShouldNotify(LangScope old) => old.lang != lang;
}

extension LangX on BuildContext {
  AppLang get lang => LangScope.of(this);

  String tr(String en) => lang == AppLang.bn ? (bnStrings[en] ?? en) : en;

  /// A whole sentence with `{name}` placeholders, so Bangla can reorder the pieces freely.
  String trf(String en, Map<String, Object?> args) {
    var s = tr(en);
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  /// Formatters bound to the active language.
  Fmt get fmt => Fmt(lang);
}

extension TermX on BuildContext {
  /// The business's own word, in the active language.
  String term(TenantContext ctx, String key, String fallback) => tr(ctx.term(key, fallback));

  /// A payment method's name in the active language: the business's own Bangla label if it set one, else the translation.
  String methodName(TenantContext ctx, String code) {
    final m = ctx.paymentMethods.where((x) => x.code == code).firstOrNull;
    if (m == null) return tr(code == 'return_credit' ? 'Return credit' : code);
    return lang == AppLang.bn && m.labelBn.isNotEmpty ? m.labelBn : tr(m.label);
  }

  /// English plurals just add an "s"; Bangla nouns stay as they are.
  String plural(String word) => lang == AppLang.bn ? word : '${word}s';
}

const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

class Fmt {
  const Fmt(this.lang);
  final AppLang lang;

  bool get bn => lang == AppLang.bn;

  /// Latin digits -> Bangla digits when the app is in Bangla.
  String digits(String s) {
    if (!bn) return s;
    final b = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      final d = int.tryParse(c);
      b.write(d == null ? c : _bnDigits[d]);
    }
    return b.toString();
  }

  static final _lakh = NumberFormat('#,##,##0', 'en_IN');
  static final _lakh2 = NumberFormat('#,##,##0.00', 'en_IN');

  /// Taka, grouped the Bangladeshi way (12,34,567.50). Whole amounts drop the decimals unless [decimals].
  String money(int paisa, {bool symbol = true, bool? decimals, bool sign = false}) {
    final neg = paisa < 0;
    final abs = paisa.abs();
    final whole = abs % 100 == 0;
    final showDec = decimals ?? !whole;
    final body = showDec ? _lakh2.format(abs / 100) : _lakh.format(abs ~/ 100);
    final s = '${neg ? '−' : (sign ? '+' : '')}${symbol ? '৳ ' : ''}$body';
    return digits(s);
  }

  /// Compact money for tiles: ৳ 1.2L, ৳ 3.4K. (L = lakh, Cr = crore.)
  String moneyCompact(int paisa) {
    final v = paisa.abs() / 100;
    String s;
    if (v >= 10000000) {
      s = '${(v / 10000000).toStringAsFixed(v >= 100000000 ? 0 : 1)}${bn ? ' কোটি' : 'Cr'}';
    } else if (v >= 100000) {
      s = '${(v / 100000).toStringAsFixed(v >= 1000000 ? 0 : 1)}${bn ? ' লক্ষ' : 'L'}';
    } else if (v >= 10000) {
      s = '${(v / 1000).toStringAsFixed(1)}${bn ? ' হাজার' : 'K'}';
    } else {
      return money(paisa);
    }
    s = s.replaceAll('.0', '');
    return digits('${paisa < 0 ? '−' : ''}৳ $s');
  }

  /// 1250 milli -> "1.25"; trailing zeros trimmed.
  String qty(int milli) {
    final neg = milli < 0;
    final a = milli.abs();
    var s = '${a ~/ 1000}';
    final frac = (a % 1000).toString().padLeft(3, '0').replaceAll(RegExp(r'0+$'), '');
    if (frac.isNotEmpty) s += '.$frac';
    return digits(neg ? '−$s' : s);
  }

  String intN(int n) => digits(NumberFormat.decimalPattern('en_IN').format(n));

  String date(DateTime d) => digits(DateFormat('d MMM yyyy').format(d.toLocal()));
  String dateShort(DateTime d) => digits(DateFormat('d MMM').format(d.toLocal()));
  String time(DateTime d) => digits(DateFormat('h:mm a').format(d.toLocal()));
  String dateTime(DateTime d) => digits(DateFormat('d MMM, h:mm a').format(d.toLocal()));
  String weekday(DateTime d) => DateFormat('EEE').format(d.toLocal());

  String ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inSeconds < 45) return bn ? 'এইমাত্র' : 'just now';
    if (diff.inMinutes < 60) return digits(bn ? '${diff.inMinutes} মিনিট আগে' : '${diff.inMinutes} min ago');
    if (diff.inHours < 24) return digits(bn ? '${diff.inHours} ঘণ্টা আগে' : '${diff.inHours} h ago');
    return digits(bn ? '${diff.inDays} দিন আগে' : '${diff.inDays} d ago');
  }

  String percentBp(int bp) {
    final v = bp / 100;
    return digits('${v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString()}%');
  }
}

/// Money straight from a server decimal string.
extension WireMoney on String? {
  int get paisa => parsePaisa(this);
  int get milli => parseMilli(this);
}
