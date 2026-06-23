import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Crisp white (or dark-surface) card with a soft layered shadow and no grey
/// border — the shared editorial card surface used across the app.
BoxDecoration softCardDecoration(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 2),
    border: isDark
        ? Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          )
        : null,
    boxShadow: [
      BoxShadow(
        color: AppColors.secondary.withValues(alpha: isDark ? 0.0 : 0.04),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: AppColors.secondary.withValues(alpha: isDark ? 0.0 : 0.09),
        blurRadius: 26,
        offset: const Offset(0, 14),
      ),
    ],
  );
}
