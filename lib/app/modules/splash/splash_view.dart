import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/veha_logo_draw.dart';
import 'splash_controller.dart';

/// First screen on every launch — the Veha logo draws itself on a clean
/// background, then [SplashController] routes onward.
class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // White matches the native splash for a seamless handoff.
    final background = isDark ? theme.colorScheme.surface : Colors.white;

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VehaLogoDraw(
              height: 118,
              duration: Duration(milliseconds: 1500),
            ),
            const SizedBox(height: 18),
            Text(
              'Veha Driver',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'For transport drivers',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
