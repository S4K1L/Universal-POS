import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/ui/brand.dart';
import '../../core/util/responsive.dart';
import 'login_screen.dart' show AuthBrandPanel;

/// The page every signed-out screen sits in: the brand panel beside the content on a wide screen, a centred
/// column with the logo above it on a phone.
class AuthFrame extends StatelessWidget {
  const AuthFrame({super.key, required this.child, this.maxWidth = 460});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final wide = context.width >= 900;
    return Scaffold(
      backgroundColor: t.canvas,
      body: wide
          ? Row(children: [
              const Expanded(flex: 11, child: AuthBrandPanel()),
              Expanded(
                flex: 9,
                child: Center(
                  child: SingleChildScrollView(padding: const EdgeInsets.all(40), child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child)),
                ),
              ),
            ])
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(children: [const BrandMark(size: 52), const SizedBox(height: 12), const BrandWordmark(size: 22), const SizedBox(height: 24), child]),
                  ),
                ),
              ),
            ),
    );
  }
}
