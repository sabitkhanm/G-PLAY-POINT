import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class AnimatedCounter extends StatelessWidget {
  final num value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.duration = AppMotion.medium,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: duration,
      curve: AppMotion.curve,
      builder: (context, current, _) {
        final isInteger = value is int || value % 1 == 0;
        final text = isInteger
            ? current.round().toString()
            : current.toStringAsFixed(2);

        return Text(
          '$prefix$text$suffix',
          style: style ?? Theme.of(context).textTheme.headlineMedium,
        );
      },
    );
  }
}
