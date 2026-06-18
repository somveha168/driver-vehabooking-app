import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/booking_list_item.dart';

/// Tappable summary card for one assigned booking.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, required this.onTap});

  final BookingListItem booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            ],
          ),
        ),
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
