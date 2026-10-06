import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_pos/core/i18n/bn.dart';
import 'package:universal_pos/core/i18n/lang.dart';

/// Every literal passed to `tr('…')` / `trf('…', …)` has a Bangla entry, and each entry keeps the same {placeholders}.
void main() {
  final lit = RegExp(r"""\btrf?\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")""");
  final ternary = RegExp(r"\btrf?\(([^(),]*\?[^(),]*)[,)]");
  final quoted = RegExp(r"'((?:[^'\\]|\\.)*)'");

  String unescape(String s) => s.replaceAll(r"\'", "'").replaceAll(r'\$', r'$').replaceAll(r'\n', '\n');

  Set<String> sourceKeys() {
    final keys = <String>{};
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart') || f.path.endsWith('bn.dart')) continue;
      final src = f.readAsStringSync();
      for (final m in lit.allMatches(src)) {
        keys.add(unescape(m.group(1) ?? m.group(2)!));
      }
      for (final m in ternary.allMatches(src)) {
        for (final q in quoted.allMatches(m.group(1)!.substring(m.group(1)!.indexOf('?')))) {
          keys.add(unescape(q.group(1)!));
        }
      }
    }
    return keys;
  }

  test('every translated literal in the app has a Bangla entry', () {
    final missing = sourceKeys().where((k) => !bnStrings.containsKey(k)).toList()..sort();
    expect(missing, isEmpty, reason: 'Add these to lib/core/i18n/bn.dart:\n${missing.join('\n')}');
  });

  test('Bangla entries keep the same placeholders as English', () {
    final ph = RegExp(r'\{\w+\}');
    final bad = [
      for (final e in bnStrings.entries)
        if (ph.allMatches(e.key).map((m) => m.group(0)).toSet().difference(ph.allMatches(e.value).map((m) => m.group(0)).toSet()).isNotEmpty ||
            ph.allMatches(e.value).map((m) => m.group(0)).toSet().difference(ph.allMatches(e.key).map((m) => m.group(0)).toSet()).isNotEmpty)
          e.key
    ];
    expect(bad, isEmpty);
  });

  test('Bangla digits and BD money grouping', () {
    const bn = Fmt(AppLang.bn);
    const en = Fmt(AppLang.en);
    expect(en.money(123456750, decimals: true), '৳\u200912,34,567.50');
    expect(bn.money(123456750, decimals: true), '৳\u2009১২,৩৪,৫৬৭.৫০');
    expect(bn.digits('INV-D01-000042'), 'INV-D০১-০০০০৪২');
  });
}
