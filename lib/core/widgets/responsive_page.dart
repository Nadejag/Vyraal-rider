import 'package:flutter/material.dart';

import '../responsive/app_breakpoints.dart';
import '../responsive/responsive_padding.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.child,
    this.maxWidth = AppBreakpoints.medium,
    this.centerContent = false,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final padding = ResponsivePadding.page(context);
        final minHeight = (constraints.maxHeight - padding.vertical).clamp(
          0.0,
          double.infinity,
        );

        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: padding.copyWith(
            bottom: padding.bottom + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minHeight,
                maxWidth: maxWidth,
              ),
              child: Align(
                alignment: centerContent
                    ? Alignment.center
                    : Alignment.topCenter,
                child: SizedBox(width: double.infinity, child: child),
              ),
            ),
          ),
        );
      },
    );

    return SafeArea(
      child: Align(alignment: Alignment.topCenter, child: content),
    );
  }
}
