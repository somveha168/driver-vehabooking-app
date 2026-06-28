import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/booking_list_item.dart';

/// Tappable summary card for one booking. The hierarchy is built for drivers:
/// passenger, schedule, vehicle, route, then trip metadata.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, required this.onTap});

  final BookingListItem booking;
  final VoidCallback onTap;

  /// Completed-step count from the real driver-trip status:
  /// assigned=0, start=1, arrived=2, meet=3, dropped=4.
  int get _reached => switch (booking.driverTripStatus ?? booking.stage) {
    'start' => 1,
    'arrived_location' => 2,
    'meet_passenger' => 3,
    'drop_passenger' || 'completed' => 4,
    _ => 0,
  };

  bool get _showSteps =>
      booking.stage != 'cancelled' && booking.stage != 'pickup_issue';

  bool get _auditClosedSteps => booking.stage == 'completed';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = _nextHint(theme);
    final stageColor = AppColors.forStage(booking.stage);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: stageColor.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(theme),
                const SizedBox(height: AppSpacing.md),
                _tripSchedule(theme),
                if (booking.hasVehicle) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _vehicleRow(theme),
                ],
                const SizedBox(height: AppSpacing.md),
                _routeBlock(theme),
                if (hint != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  hint,
                ],
                if (_showSteps) ...[
                  const SizedBox(height: AppSpacing.md),
                  _stepRail(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (booking.code != null && booking.code!.isNotEmpty) ...[
                Text(
                  booking.code!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              _labelValueText(
                theme,
                label: 'customer'.tr,
                value: _customerLine(),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusChip(stage: booking.stage),
            if (booking.serviceType != null &&
                booking.serviceType!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                booking.serviceType!.capitalizeFirst ?? booking.serviceType!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _customerLine() {
    final parts = <String>[
      booking.customerName ?? '—',
      if (booking.hasPhone) booking.customerPhone!,
    ];
    return parts.join(' · ');
  }

  Widget _stepRail(ThemeData theme) {
    final reached = _reached;
    final audit = _auditClosedSteps;
    final labels = [
      'step_short_start'.tr,
      'step_short_arrived'.tr,
      'step_short_meet'.tr,
      'step_short_drop'.tr,
    ];

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 18,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final step = width / 4;
                final dotCenters = List.generate(4, (i) => step * i + step / 2);
                final lineStart = dotCenters.first;
                final lineEnd = dotCenters.last;
                final progressEnd = dotCenters[reached.clamp(0, 3)];
                final baseLineColor = audit
                    ? AppColors.cancelled.withValues(alpha: 0.36)
                    : theme.colorScheme.outlineVariant;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: lineStart,
                      right: width - lineEnd,
                      child: _stepLine(baseLineColor),
                    ),
                    if (reached > 0)
                      Positioned(
                        left: lineStart,
                        width: progressEnd - lineStart,
                        child: _stepLine(AppColors.primary),
                      ),
                    ...List.generate(4, (i) {
                      final done = i < reached;
                      final current = !audit && i == reached && reached < 4;
                      final missed = audit && !done;

                      return Positioned(
                        left: dotCenters[i] - 8,
                        child: _stepDot(
                          theme,
                          done: done,
                          current: current,
                          missed: missed,
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: labels
                .map(
                  (label) => Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _tripSchedule(ThemeData theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _dateLine(
        theme,
        label: 'trip_label'.tr,
        value: booking.isRoundTrip ? 'round_trip_badge'.tr : 'one_way'.tr,
      ),
      const SizedBox(height: 3),
      _dateLine(
        theme,
        label: 'trip_leg_outbound'.tr,
        value: Formatters.dateTime(_outboundWhen()),
      ),
      if (booking.isRoundTrip) ...[
        const SizedBox(height: 2),
        _dateLine(
          theme,
          label: 'trip_leg_return'.tr,
          value: Formatters.dateTime(_returnWhen()),
        ),
      ],
    ],
  );

  String _outboundWhen() {
    final outbound = booking.linkedOutboundDatetime;
    if (outbound != null && outbound.isNotEmpty) return outbound;
    return booking.isOutboundLeg
        ? booking.displayDepartureDatetime
        : booking.departureDatetime ?? booking.displayDepartureDatetime;
  }

  String _returnWhen() {
    final returnLeg = booking.linkedReturnDatetime;
    if (returnLeg != null && returnLeg.isNotEmpty) return returnLeg;
    return booking.isReturnLeg
        ? booking.displayDepartureDatetime
        : booking.linkedLegDatetime ?? '';
  }

  Widget _vehicleRow(ThemeData theme) {
    final assigned = booking.assignedVehicleLabel;
    final specs = <String>[
      if (booking.vehicleColor != null && booking.vehicleColor!.isNotEmpty)
        booking.vehicleColor!,
      if (booking.vehicleSeats != null)
        '${booking.vehicleSeats} ${'seats'.tr.toLowerCase()}',
    ].join(' · ');
    final detail = [
      assigned,
      if (specs.isNotEmpty) specs,
    ].whereType<String>().join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (booking.vehicleBooked != null && booking.vehicleBooked!.isNotEmpty)
          Text(
            booking.vehicleBooked!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            detail,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (booking.passengerCount != null) ...[
          const SizedBox(height: 3),
          _labelValueText(
            theme,
            label: 'pax_label'.tr,
            value: '${booking.passengerCount}',
            maxLines: 1,
          ),
        ],
      ],
    );
  }

  Widget _routeBlock(ThemeData theme) => Column(
    children: [
      _routeStop(
        theme,
        icon: IconsaxPlusLinear.location,
        label: 'pickup'.tr,
        value: booking.pickupLabel,
        isFirst: true,
        hasNext: booking.hasDropoff,
      ),
      if (booking.hasDropoff)
        _routeStop(
          theme,
          icon: IconsaxPlusLinear.location_tick,
          label: 'dropoff'.tr,
          value: booking.dropoffLabel,
          isFirst: false,
          hasNext: false,
        ),
    ],
  );

  Widget _routeStop(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required bool isFirst,
    required bool hasNext,
  }) {
    final color = isFirst ? AppColors.primary : AppColors.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 11, color: color),
            ),
            if (hasNext)
              Container(
                width: 1.5,
                height: 18,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: AppColors.primary.withValues(alpha: 0.22),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 0, bottom: hasNext ? 0 : 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                    fontSize: 9.5,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Glanceable "what's next" pill, derived from the first forward action.
  Widget? _nextHint(ThemeData theme) {
    final action = booking.nextAction;
    if (action == null) return null;

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
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(IconsaxPlusLinear.arrow_right_3, size: 14, color: color),
        ],
      ),
    );
  }

  Widget _labelValueText(
    ThemeData theme, {
    required String label,
    required String value,
    int maxLines = 2,
  }) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: TextStyle(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextSpan(
          text: value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
    style: theme.textTheme.bodyMedium?.copyWith(height: 1.2),
  );

  Widget _stepDot(
    ThemeData theme, {
    required bool done,
    required bool current,
    bool missed = false,
  }) {
    final active = done || current;
    final color = missed
        ? AppColors.cancelled
        : active
        ? AppColors.primary
        : theme.colorScheme.surface;
    final borderColor = missed
        ? AppColors.cancelled
        : active
        ? AppColors.primary
        : theme.colorScheme.outlineVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: borderColor, width: 1.6),
      ),
      child: done
          ? const Icon(
              IconsaxPlusLinear.tick_circle,
              size: 11,
              color: Colors.white,
            )
          : missed
          ? const Icon(Icons.close_rounded, size: 12, color: Colors.white)
          : current
          ? Center(
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _stepLine(Color color) => Container(
    height: 2,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(99),
    ),
  );

  Widget _dateLine(
    ThemeData theme, {
    required String label,
    required String value,
  }) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: TextStyle(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.w500,
          ),
        ),
        TextSpan(
          text: value,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: theme.textTheme.bodyMedium,
  );
}
