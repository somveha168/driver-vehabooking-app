import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Full-width primary action that pulls focus: a soft brand glow that breathes,
/// a periodic shimmer sweep, and a nudging icon. Shows a spinner while [loading].
class StepActionButton extends StatelessWidget {
  const StepActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: 20)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: -1, end: 3, duration: 700.ms, curve: Curves.easeInOut),
        label: Text(label),
      ),
    );

    if (loading) return button;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: button,
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.012, duration: 1100.ms, curve: Curves.easeInOut)
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          delay: 1500.ms,
          duration: 1200.ms,
          color: Colors.white.withValues(alpha: 0.35),
        );
  }
}
