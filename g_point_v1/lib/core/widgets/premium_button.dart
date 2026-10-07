import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool outlined;
  final bool expanded;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.outlined = false,
    this.expanded = true,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final button = widget.outlined
        ? OutlinedButton(
            onPressed: widget.loading ? null : widget.onPressed,
            child: _content(),
          )
        : FilledButton(
            onPressed: widget.loading ? null : widget.onPressed,
            child: _content(),
          );

    return AnimatedScale(
      scale: _pressed ? .985 : 1,
      duration: AppMotion.fast,
      child: GestureDetector(
        onTapDown: widget.onPressed == null ? null : (_) => setState(() => _pressed = true),
        onTapUp: widget.onPressed == null ? null : (_) => setState(() => _pressed = false),
        onTapCancel: widget.onPressed == null ? null : () => setState(() => _pressed = false),
        child: widget.expanded
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }

  Widget _content() {
    if (widget.loading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (widget.icon == null) return Text(widget.label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, size: 19),
        const SizedBox(width: AppSpacing.sm),
        Text(widget.label),
      ],
    );
  }
}
