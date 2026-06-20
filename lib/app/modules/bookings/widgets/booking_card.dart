import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/booking_list_item.dart';

/// Tappable summary card for one assigned booking. Shows a stage progress bar
/// and a glanceable "next action" hint so the driver knows what to do at a tap.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, required this.onTap});

  final BookingListItem booking;
  final VoidCallback onTap;

  /// Completed-step count: assigned=0, start=1, arrived=2, meet=3, done=4.
  int get _reached => switch (booking.stage) {
        'start' => 1,
        'arrived_location' => 2,
        'meet_passenger' => 3,
        'drop_passenger' || 'completed' => 4,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _nextHint(theme);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.customerName ?? '—',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(stage: booking.stage),
                ],
              ),
              if (booking.stage != 'cancelled' && booking.stage != 'not_met_passenger') ...[
                const SizedBox(height: AppSpacing.md),
                _progressBar(theme),
              ],
              const SizedBox(height: AppSpacing.md),
              _line(theme, IconsaxPlusLinear.clock,
                  Formatters.dateTime(booking.departureDatetime)),
              const SizedBox(height: AppSpacing.xs),
              _line(theme, IconsaxPlusLinear.location, booking.pickupLabel),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (booking.serviceType != null)
                    _tag(theme, booking.serviceType!.toUpperCase()),
                  const Spacer(),
                  if (booking.passengerCount != null)
                    Row(
                      children: [
                        Icon(IconsaxPlusLinear.profile,
                            size: 16, color: theme.colorScheme.outline),
                        const SizedBox(width: 4),
                        Text('${booking.passengerCount}',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                ],
              ),
              if (hint != null) ...[
                const SizedBox(height: AppSpacing.md),
                hint,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressBar(ThemeData theme) {
    final reached = _reached;
    return Row(
      children: List.generate(4, (i) {
        final done = i < reached;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
            decoration: BoxDecoration(
              color: done ? AppColors.primary : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  /// Glanceable "what's next" pill, derived from the first allowed action.
  Widget? _nextHint(ThemeData theme) {
    if (booking.allowedActions.isEmpty) return null;
    final action = booking.allowedActions.first;
    final (String? label, IconData? icon) = switch (action) {
      'start' => ('start_now'.tr, IconsaxPlusLinear.play),
      'arrived' => ('mark_arrived'.tr, IconsaxPlusLinear.location_tick),
      'meet_passenger' => ('meet_passenger'.tr, IconsaxPlusLinear.profile_tick),
      'complete' => ('drop_passenger'.tr, IconsaxPlusLinear.arrow_right_3),
      _ => (null, null),
    };
    if (label == null || icon == null) return null;

    final color = AppColors.forStage(booking.stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _line(ThemeData theme, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
          ),
        ],
      );

  Widget _tag(ThemeData theme, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          text,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
        ),
      );
}
