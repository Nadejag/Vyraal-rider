import 'package:flutter/material.dart';

class AppSection extends StatelessWidget {
  const AppSection({
    required this.title,
    required this.child,
    this.titleStyle,
    super.key,
  });

  final String title;
  final Widget child;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle ?? Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
