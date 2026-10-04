import 'package:flutter/material.dart';
import '../motion/motion_tokens.dart';

class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  const PremiumCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(18)});

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: MotionTokens.fast,
      curve: MotionTokens.curve,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    );
  }
}
