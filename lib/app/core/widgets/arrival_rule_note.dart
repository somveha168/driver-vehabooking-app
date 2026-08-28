import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The standing rule drivers are held to: be at the pickup at least 15 minutes
/// before the booked departure time.
///
/// Sits directly above the trip's action control - the moment the driver is
/// deciding whether to set off is the moment the rule is worth reading.
class ArrivalRuleNote extends StatelessWidget {
  const ArrivalRuleNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          IconsaxPlusLinear.clock,
          size: 13,
          color: AppColors.primary.withValues(alpha: 0.85),
        ),
        const SizedBox(width: AppSpacing.xs + 1),
        Flexible(
          child: Text(
            'arrive_early_rule'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 11.5,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
