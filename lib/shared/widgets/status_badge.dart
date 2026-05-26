import 'package:flutter/material.dart';
import 'package:mechmate_app/core/theme/theme.dart';

/// Status badge chip for displaying booking/service statuses.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'active' => (AppColors.info, AppColors.info.withValues(alpha: 0.12)),
      'confirmed' => (AppColors.success, AppColors.success.withValues(alpha: 0.12)),
      'pending' => (AppColors.warning, AppColors.warning.withValues(alpha: 0.12)),
      'completed' =>
        (AppColors.textDarkMuted, AppColors.textDarkMuted.withValues(alpha: 0.12)),
      'cancelled' => (AppColors.error, AppColors.error.withValues(alpha: 0.12)),
      _ => (AppColors.info, AppColors.info.withValues(alpha: 0.12)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
