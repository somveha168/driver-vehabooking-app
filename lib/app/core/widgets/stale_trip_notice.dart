import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Banner for a trip that is still under way long after its departure time.
///
/// The backend stops such a trip claiming the dashboard's NOW card, so without
/// this the driver would find it sitting in their list with no explanation of
/// why it is still there or what to do about it.
class StaleTripNotice extends StatelessWidget {
  const StaleTripNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = AppColors.assigned;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            IconsaxPlusLinear.timer_1,
            size: 17,
            color: color.withValues(alpha: 0.92),
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'stale_trip_title'.tr,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'stale_trip_detail'.tr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
