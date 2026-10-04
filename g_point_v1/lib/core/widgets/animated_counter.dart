import 'package:flutter/material.dart';
import '../motion/motion_tokens.dart';

class AnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  const AnimatedCounter({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: MotionTokens.slow,
        curve: MotionTokens.curve,
        builder: (context, v, _) => Text(v.round().toString(), style: style),
      );
}
