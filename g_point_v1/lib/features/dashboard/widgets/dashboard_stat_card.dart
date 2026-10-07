import 'package:flutter/material.dart';

import '../../../core/widgets/premium_card.dart';

enum DashboardStatAccent { primary, info, success, warning }

class DashboardStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget value;
  final DashboardStatAccent accent;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _accentColor(theme);

    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const Spacer(),
          value,
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _accentColor(ThemeData theme) {
    switch (accent) {
      case DashboardStatAccent.primary:
        return theme.colorScheme.primary;
      case DashboardStatAccent.info:
        return theme.colorScheme.secondary;
      case DashboardStatAccent.success:
        return const Color(0xFF159A68);
      case DashboardStatAccent.warning:
        return const Color(0xFFD98A00);
    }
  }
}
