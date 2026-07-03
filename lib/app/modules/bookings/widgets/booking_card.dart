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
  int get _reached {
    if (booking.stage == 'completed') {
      return 4;
    }

    return switch (booking.driverTripStatus ?? booking.stage) {
      'start' => 1,
      'arrived_location' => 2,
      'meet_passenger' => 3,
      'drop_passenger' || 'completed' => 4,
      _ => 0,
    };
  }

  bool get _showSteps =>
      booking.stage != 'completed' &&
      booking.stage != 'cancelled' &&
      booking.stage != 'pickup_issue';

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
                const SizedBox(height: AppSpacing.sm),
                _routeSummary(theme),
                const SizedBox(height: AppSpacing.sm),
                _bookingFacts(theme),
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
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                _customerLine(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        StatusChip(stage: booking.stage),
      ],
    );
  }

  String _customerLine() {
    final parts = <String>[
      if (booking.customerName != null && booking.customerName!.isNotEmpty)
        booking.customerName!,
      if (booking.hasPhone) booking.customerPhone!,
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }

  Widget _routeSummary(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.routing_2,
              size: 13,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _routePointText(
                    theme,
                    label: 'origin'.tr,
                    value: booking.routeOriginLabel,
                    alignEnd: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    IconsaxPlusLinear.arrow_right_3,
                    size: 14,
                    color: theme.colorScheme.outline.withValues(alpha: 0.62),
                  ),
                ),
                Expanded(
                  child: _routePointText(
                    theme,
                    label: 'destination'.tr,
                    value: booking.routeDestinationLabel,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routePointText(
    ThemeData theme, {
    required String label,
    required String value,
    required bool alignEnd,
  }) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.outline,
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.secondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    ],
  );

  Widget _bookingFacts(ThemeData theme) {
    final vehicleTitle = booking.vehicleBooked?.isNotEmpty == true
        ? booking.vehicleBooked!
        : '—';
    final assigned = booking.assignedVehicleLabel;
    final vehicleDetail = [
      if (assigned != null && assigned.isNotEmpty) assigned,
      if (booking.vehicleColor != null && booking.vehicleColor!.isNotEmpty)
        booking.vehicleColor!,
      if (booking.vehicleSeats != null)
        '${booking.vehicleSeats} ${'seats'.tr.toLowerCase()}',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _factPill(
              theme,
              icon: IconsaxPlusLinear.routing_2,
              value: booking.isRoundTrip ? 'round_trip_badge'.tr : 'one_way'.tr,
            ),
            if (booking.passengerCount != null)
              _factPill(
                theme,
                icon: IconsaxPlusLinear.profile_2user,
                value: '${booking.passengerCount} ${'pax_label'.tr}',
              ),
            if (booking.serviceType != null && booking.serviceType!.isNotEmpty)
              _factPill(
                theme,
                icon: IconsaxPlusLinear.car,
                value:
                    booking.serviceType!.capitalizeFirst ??
                    booking.serviceType!,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm + 1),
        _compactRow(
          theme,
          icon: IconsaxPlusLinear.calendar,
          label: 'trip_leg_outbound'.tr,
          value: Formatters.dateTime(_outboundWhen()),
        ),
        if (booking.isRoundTrip) ...[
          const SizedBox(height: 4),
          _compactRow(
            theme,
            icon: IconsaxPlusLinear.refresh,
            label: 'trip_leg_return'.tr,
            value: Formatters.dateTime(_returnWhen()),
          ),
        ],
        const SizedBox(height: 4),
        _compactRow(
          theme,
          icon: IconsaxPlusLinear.car,
          label: 'vehicle_booked'.tr,
          value: vehicleTitle,
        ),
        if (vehicleDetail.isNotEmpty) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                vehicleDetail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _factPill(
    ThemeData theme, {
    required IconData icon,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) => Row(
    children: [
      Icon(icon, size: 14, color: AppColors.primary.withValues(alpha: 0.82)),
      const SizedBox(width: 7),
      Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.outline,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontSize: 12.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

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
                        fontWeight: FontWeight.w500,
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
}
