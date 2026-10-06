import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';

/// Number pad for amounts and quantities. Stateless: the parent owns the text.
class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.onKey, this.allowDot = true, this.height = 64, this.dense = false});
  final void Function(String key) onKey; // '0'..'9', '.', 'back', 'clear', '00'
  final bool allowDot;
  final double height;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', allowDot ? '.' : '00', '0', 'back'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: dense ? 6 : 8,
      crossAxisSpacing: dense ? 6 : 8,
      childAspectRatio: 1.9,
      children: [for (final k in keys) _Key(k, onKey)],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key(this.k, this.onKey);
  final String k;
  final void Function(String) onKey;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final isBack = k == 'back';
    return Material(
      color: isBack ? t.tint(t.danger, 0.1) : t.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.selectionClick();
          onKey(k);
        },
        onLongPress: isBack ? () => onKey('clear') : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: t.outline)),
          child: isBack
              ? Icon(Icons.backspace_outlined, size: 22, color: t.danger)
              : Text(k, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, fontFeatures: tabular, color: t.text, fontVariations: const [FontVariation('wght', 700)])),
        ),
      ),
    );
  }
}

/// Applies a keypad key to a numeric text buffer ("12.5"), capping decimals.
String applyKey(String current, String key, {int maxDecimals = 2, int maxLen = 10}) {
  switch (key) {
    case 'back':
      return current.isEmpty ? '' : current.substring(0, current.length - 1);
    case 'clear':
      return '';
    case '.':
      if (current.contains('.')) return current;
      return current.isEmpty ? '0.' : '$current.';
    case '00':
      return current.isEmpty ? current : (current.length + 2 <= maxLen ? '${current}00' : current);
    default:
      if (current.length >= maxLen) return current;
      if (current.contains('.') && current.split('.')[1].length >= maxDecimals) return current;
      if (current == '0') return key;
      return current + key;
  }
}
