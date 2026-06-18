import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Colored pill showing a booking's driver-facing stage.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.stage});

  final String stage;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forStage(stage);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Text(
        'stage_$stage'.tr,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
