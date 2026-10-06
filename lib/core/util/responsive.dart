import 'package:flutter/widgets.dart';

class Bp {
  static const compact = 640.0;
  static const wide = 960.0;
  static const huge = 1360.0;
}

extension ResponsiveX on BuildContext {
  double get width => MediaQuery.sizeOf(this).width;
  bool get isCompact => width < Bp.compact;
  bool get isWide => width >= Bp.wide;
  bool get isHuge => width >= Bp.huge;
}
