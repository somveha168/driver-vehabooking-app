import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

/// Vertical trip timeline: Start → Arrived → Pickup → Drop-off.
///
/// Completed nodes are ticked and show their timestamp; the current node
/// pulses to draw the eye (3-foot / 1-second glanceability); future nodes are
/// muted. Driven entirely by [stage] + the four milestone timestamps.
class TripTimeline extends StatefulWidget {
  const TripTimeline({
    super.key,
    required this.stage,
    this.startedAt,
    this.arrivedAt,
    this.metPassengerAt,
    this.droppedAt,
  });

  final String stage;
  final String? startedAt;
  final String? arrivedAt;
  final String? metPassengerAt;
  final String? droppedAt;

  @override
  State<TripTimeline> createState() => _TripTimelineState();
}

class _TripTimelineState extends State<TripTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  static const _labels = [
    'step_start',
    'step_arrived',
    'step_pickup',
    'step_dropoff',
  ];

  /// Completed-step count: assigned=0, start=1, arrived=2, meet=3, done=4.
  int get _reached => switch (widget.stage) {
    'start' => 1,
    'arrived_location' => 2,
    'meet_passenger' => 3,
    'drop_passenger' || 'completed' => 4,
    _ => 0,
  };

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reached = _reached;
    final cancelled = widget.stage == 'cancelled';
    final stamps = [
      widget.startedAt,
      widget.arrivedAt,
      widget.metPassengerAt,
      widget.droppedAt,
    ];

    return Column(
      children: List.generate(4, (i) {
        final done = i < reached;
        final current = i == reached && !cancelled && reached < 4;
        final isLast = i == 3;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _node(theme, done: done, current: current),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: done
                            ? AppColors.primary
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _labels[i].tr,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: (done || current)
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: (done || current)
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        done && stamps[i] != null
                            ? Formatters.time(stamps[i])
                            : current
                            ? 'in_progress'.tr
                            : '—',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: current
                              ? AppColors.primary
                              : theme.colorScheme.outline,
                          fontWeight: current
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _node(ThemeData theme, {required bool done, required bool current}) {
    if (done) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 15, color: Colors.white),
      );
    }
    if (current) {
      return AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: 0.10 + 0.14 * _pulse.value,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Center(
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
      ),
    );
  }
}
