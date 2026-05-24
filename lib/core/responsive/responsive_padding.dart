import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

abstract final class ResponsivePadding {
  static EdgeInsets page(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= AppBreakpoints.medium) {
      return const EdgeInsets.symmetric(horizontal: 48, vertical: 32);
    }

    if (width >= AppBreakpoints.compact) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }

    return const EdgeInsets.all(16);
  }
}
