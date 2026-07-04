import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Horizontal 4-step trip tracker: Start → Arrived → Meet → Drop.
/// Done steps show a check, the current step pulses (radar halo), upcoming stay
/// hollow. Used on the Home NOW card and in the trip-detail footer.
class TripSteps extends StatelessWidget {
  const TripSteps({
    super.key,
    required this.stage,
    this.showLabels = true,
    this.compact = false,
  });

  final String stage;
  final bool showLabels;
  final bool compact;

  static const _labels = [
    'step_short_start',
    'step_short_arrived',
    'step_short_meet',
    'step_short_drop',
  ];

  int get _stageIndex => switch (stage) {
    'start' => 0,
    'arrived_location' => 1,
    'meet_passenger' => 2,
    'drop_passenger' || 'completed' => 3,
    _ => -1,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.outlineVariant;
    final isCompleted = stage == 'completed';
    final stageIndex = _stageIndex;
    final size = compact ? 18.0 : 22.0;
    final dotSize = compact ? 5.5 : 7.0;
    final checkSize = compact ? 11.0 : 13.0;
    final connectorHeight = compact ? 2.0 : 3.0;
    final labelFontSize = compact ? 9.0 : 10.0;

    Widget step(int i) {
      final done = isCompleted || i < stageIndex;
      final current = !isCompleted && i == stageIndex;
      final filled = done || current;
      final circle = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? AppColors.primary : Colors.transparent,
          border: filled ? null : Border.all(color: muted, width: 2),
        ),
        child: done
            ? Icon(Icons.check_rounded, size: checkSize, color: Colors.white)
            : current
            ? Container(
                width: dotSize,
                height: dotSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              )
            : null,
      );
      final marker = !current
          ? circle
          : Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(
                      begin: 0.9,
                      end: compact ? 1.65 : 1.9,
                      duration: 1300.ms,
                      curve: Curves.easeOut,
                    )
                    .fadeOut(duration: 1300.ms),
                circle,
              ],
            );

      if (!showLabels) return marker;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          marker,
          const SizedBox(height: 5),
          Text(
            _labels[i].tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: labelFontSize,
              fontWeight: current ? FontWeight.w700 : FontWeight.w600,
              color: current
                  ? AppColors.primary
                  : done
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.outline,
            ),
          ),
        ],
      );
    }

    Widget connector(int seg) => Expanded(
      child: Padding(
        // Align to the circle centers when labels push the row taller.
        padding: EdgeInsets.only(top: showLabels ? size / 2 - 1.5 : 0),
        child: Container(
          height: connectorHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: (isCompleted || seg < stageIndex)
                ? AppColors.primary
                : muted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: showLabels
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        step(0),
        connector(0),
        step(1),
        connector(1),
        step(2),
        connector(2),
        step(3),
      ],
    );
  }
}
