import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ProfileStats extends StatelessWidget {
  final int viewsCount;
  final int connectionsCount;
  final int profileComplete;

  const ProfileStats({
    super.key,
    required this.viewsCount,
    required this.connectionsCount,
    required this.profileComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF2E2820) : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1612) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: '$viewsCount',
              label: 'Views',
              icon: Icons.visibility_outlined,
            ),
          ),
          Container(width: 0.5, height: 44, color: borderColor),
          Expanded(
            child: _StatItem(
              value: '$connectionsCount',
              label: 'Connections',
              icon: Icons.people_outline,
            ),
          ),
          Container(width: 0.5, height: 44, color: borderColor),
          Expanded(
            child: _StatItem(
              value: '$profileComplete%',
              label: 'Complete',
              icon: Icons.person_outline,
              valueColor: profileComplete >= 80 ? Colors.green.shade600 : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? valueColor;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF1A0808);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: valueColor ?? AppColors.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelMedium.copyWith(
              color: valueColor ?? textColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
