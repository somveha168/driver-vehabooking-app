import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';

/// App-level floating feedback with compact, driver-friendly styling.
class AppSnackbar {
  const AppSnackbar._();

  static void success(String message) {
    _show(
      message,
      color: AppColors.primary,
      icon: IconsaxPlusBold.tick_circle,
      duration: const Duration(seconds: 2),
    );
  }

  static void info(String message) {
    _show(
      message,
      color: AppColors.secondary,
      icon: IconsaxPlusLinear.info_circle,
      duration: const Duration(seconds: 2),
    );
  }

  static void error(String message) {
    _show(
      message,
      color: AppColors.cancelled,
      icon: IconsaxPlusLinear.close_circle,
      duration: const Duration(seconds: 3),
    );
  }

  static void _show(
    String message, {
    required Color color,
    required IconData icon,
    required Duration duration,
  }) {
    Get.closeAllSnackbars();
    Get.showSnackbar(
      GetSnackBar(
        titleText: const SizedBox.shrink(),
        messageText: _ToastContent(message: message, color: color, icon: icon),
        snackPosition: SnackPosition.BOTTOM,
        snackStyle: SnackStyle.FLOATING,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 22),
        padding: EdgeInsets.zero,
        borderRadius: 22,
        backgroundColor: Colors.transparent,
        barBlur: 0,
        boxShadows: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
        animationDuration: const Duration(milliseconds: 280),
        forwardAnimationCurve: Curves.easeOutCubic,
        reverseAnimationCurve: Curves.easeInCubic,
        duration: duration,
      ),
    );
  }
}

class _ToastContent extends StatelessWidget {
  const _ToastContent({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF10201F) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF10201F);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.20 : 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
