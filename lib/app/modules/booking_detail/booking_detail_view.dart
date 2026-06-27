import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/info_row.dart';
import '../../core/widgets/pickup_issue_sheet.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/step_action_button.dart';
import '../../core/widgets/swipe_to_confirm.dart';
import '../../core/widgets/trip_steps.dart';
import '../../data/models/booking_detail.dart';
import '../../data/models/place.dart';
import 'booking_detail_controller.dart';

class BookingDetailView extends GetView<BookingDetailController> {
  const BookingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        leadingWidth: 60,
        scrolledUnderElevation: 0,
        leading: const _CircleBack(),
        title: Text(
          'booking_detail'.tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        if (controller.error.value != null) {
          return ErrorView(
            message: controller.error.value!,
            onRetry: controller.load,
          );
        }
        final b = controller.booking.value;
        if (b == null) return const SizedBox.shrink();
        return _Detail(b: b, controller: controller);
      }),
      bottomNavigationBar: Obx(() {
        final b = controller.booking.value;
        // Show the footer when there's an action, or to explain why Start is locked.
        if (b == null || (!b.can && !b.startLocked)) {
          return const SizedBox.shrink();
        }
        return _StickyFooter(b: b, controller: controller);
      }),
    );
  }
}

/// Sticky footer: a glanceable horizontal step tracker over the action control.
class _StickyFooter extends StatelessWidget {
  const _StickyFooter({required this.b, required this.controller});

  final BookingDetail b;
  final BookingDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TripSteps(stage: b.stage),
            const SizedBox(height: AppSpacing.lg),
            if (b.can) ...[
              if (b.isStartOverdue) ...[
                _StartOverdueNotice(b: b),
                const SizedBox(height: AppSpacing.md),
              ],
              _ActionBar(b: b, controller: controller),
              if (b.canReportPickupIssue) ...[
                const SizedBox(height: 2),
                Obx(
                  () => TextButton(
                    onPressed: controller.isActing.value
                        ? null
                        : () => showPickupIssueSheet(
                            context: context,
                            onSubmit: controller.reportPickupIssue,
                            reasonOptions: b.pickupIssueReasonOptions,
                            noteMaxLength: b.pickupIssueNoteMaxLength,
                          ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('pickup_issue_link'.tr),
                  ),
                ),
              ],
            ] else if (b.startLocked)
              // Start is hidden until the driver finishes their current trip.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconsaxPlusLinear.lock_1,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      'finish_current_trip'.tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Modern circular back button for the detail app bar.
class _CircleBack extends StatelessWidget {
  const _CircleBack();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.10),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.back<void>(),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              IconsaxPlusLinear.arrow_left_2,
              size: 20,
              color: AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.b, required this.controller});

  final BookingDetail b;
  final BookingDetailController controller;

  bool get _hasPhone =>
      b.customerPhone != null &&
      b.customerPhone!.isNotEmpty &&
      b.customerPhone != 'N/A';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _detailRows(theme);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Who + contact ──
        _SectionCard(
          title: 'passenger_info'.tr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '#${b.code ?? '—'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  StatusChip(stage: b.stage),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.customerName ?? '—',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _subtitle(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_hasPhone) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _callButton(),
                  ],
                ],
              ),
              if (_hasPhone) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                _phoneRow(theme),
              ],
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              ..._passengerRows(theme),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Vehicle: booked class + the real assigned vehicle ──
        if (b.hasVehicle) ...[
          _vehicleCard(theme),
          const SizedBox(height: AppSpacing.md),
        ],

        if (b.hasOperatorContact) ...[
          _operatorCard(theme),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Pickup issue summary (terminal) ──
        if (b.stage == 'pickup_issue') ...[
          _PickupIssueSummary(reason: b.pickupIssueReason),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Route: one-way shows a single route; 2-way always reads
        // Outbound first, Return second, regardless of the selected active leg.
        if (b.hasReturn)
          ..._roundTripCards(theme)
        else ...[
          _tripRouteCard(
            theme,
            title: 'route'.tr,
            legLabel: 'departure'.tr,
            when: b.displayDepartureDatetime,
            pickup: b.pickup,
            dropoff: b.dropoff,
            isCurrentLeg: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Extra details (only when present) ──
        if (details.isNotEmpty)
          _SectionCard(
            title: 'trip_details'.tr,
            child: Column(children: details),
          ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  String _subtitle() {
    final svc = b.serviceType?.capitalizeFirst ?? '';
    final leg = b.isReturnLeg ? 'trip_leg_return'.tr : 'trip_leg_outbound'.tr;
    final trip = b.hasReturn ? '${'round_trip_badge'.tr} · $leg' : leg;
    return [svc, trip].where((e) => e.isNotEmpty).join(' · ');
  }

  List<Widget> _roundTripCards(ThemeData theme) {
    final outboundPickup = b.isReturnLeg ? b.dropoff : b.pickup;
    final outboundDropoff = b.isReturnLeg ? b.pickup : b.dropoff;
    final returnPickup = b.isReturnLeg ? b.pickup : b.dropoff;
    final returnDropoff = b.isReturnLeg ? b.dropoff : b.pickup;

    return [
      _tripRouteCard(
        theme,
        title: 'outbound_trip'.tr,
        legLabel: 'trip_leg_outbound'.tr,
        when: _outboundWhen(),
        pickup: outboundPickup,
        dropoff: outboundDropoff,
        isCurrentLeg: b.isOutboundLeg,
      ),
      const SizedBox(height: AppSpacing.md),
      _tripRouteCard(
        theme,
        title: 'return_trip'.tr,
        legLabel: 'trip_leg_return'.tr,
        when: _returnWhen(),
        pickup: returnPickup,
        dropoff: returnDropoff,
        isCurrentLeg: b.isReturnLeg,
        footer: 'return_note'.tr,
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  String _outboundWhen() {
    final outbound = b.linkedOutboundDatetime;
    if (outbound != null && outbound.isNotEmpty) return outbound;
    return b.isOutboundLeg
        ? b.displayDepartureDatetime
        : b.departureDatetime ?? '';
  }

  String _returnWhen() {
    final returnLeg = b.linkedReturnDatetime;
    if (returnLeg != null && returnLeg.isNotEmpty) return returnLeg;
    if (b.isReturnLeg) return b.displayDepartureDatetime;

    final date = Formatters.shortDate(b.returnDate);
    final time = b.returnTime;
    return [date, if (time != null && time.isNotEmpty) time].join(' · ');
  }

  /// Round call button — dials the passenger.
  Widget _callButton() => Material(
    color: AppColors.primary.withValues(alpha: 0.12),
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: controller.callCustomer,
      child: const Padding(
        padding: EdgeInsets.all(11),
        child: Icon(IconsaxPlusBold.call, size: 20, color: AppColors.primary),
      ),
    ),
  );

  Widget _phoneRow(ThemeData theme) => Row(
    children: [
      Icon(IconsaxPlusLinear.call, size: 16, color: theme.colorScheme.outline),
      const SizedBox(width: AppSpacing.sm),
      Text(
        b.customerPhone!,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  List<Widget> _passengerRows(ThemeData theme) {
    final rows = <Widget>[
      InfoRow(
        icon: IconsaxPlusLinear.profile_2user,
        label: 'passengers'.tr,
        value: '${b.passengerCount ?? 1}',
      ),
    ];

    if (b.nationality != null && b.nationality!.isNotEmpty) {
      rows
        ..add(const Divider(height: 1))
        ..add(
          InfoRow(
            icon: IconsaxPlusLinear.global,
            label: 'nationality'.tr,
            value: b.nationality!,
          ),
        );
    }

    return rows;
  }

  Widget _tripRouteCard(
    ThemeData theme, {
    required String title,
    required String legLabel,
    required String when,
    required Place pickup,
    required Place dropoff,
    required bool isCurrentLeg,
    String? footer,
  }) {
    final navigateToDropoff = _navigatesToDropoff;
    final canViewRoute =
        isCurrentLeg && pickup.hasCoordinates && dropoff.hasCoordinates;

    return _SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _departureRow(
            theme,
            legLabel: legLabel,
            when: when,
            showEstDrop: isCurrentLeg,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          _routeStop(theme, isOrigin: true, place: pickup),
          _routeStop(theme, isOrigin: false, place: dropoff),
          if (canViewRoute) ...[
            const SizedBox(height: AppSpacing.md),
            _routeMapButton(
              label: navigateToDropoff
                  ? 'view_dropoff_route'.tr
                  : 'view_pickup_route'.tr,
              onTap: controller.openMap,
            ),
          ],
          if (footer != null && footer.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              footer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool get _navigatesToDropoff =>
      b.stage == 'meet_passenger' || b.stage == 'drop_passenger';

  Widget _routeMapButton({required String label, required VoidCallback onTap}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Material(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      IconsaxPlusLinear.map,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    IconsaxPlusLinear.arrow_right_3,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _departureRow(
    ThemeData theme, {
    required String legLabel,
    required String when,
    required bool showEstDrop,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Icon(IconsaxPlusBold.calendar, size: 18, color: AppColors.primary),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              legLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              Formatters.dateTime(when),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      // Estimated drop-off time (departure + route duration).
      if (showEstDrop &&
          b.arrivalDatetime != null &&
          b.arrivalDatetime!.isNotEmpty) ...[
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'est_drop'.tr,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              Formatters.time(b.arrivalDatetime),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    ],
  );

  /// A pickup/drop-off stop in the route mini-timeline: marker + name + address.
  Widget _routeStop(
    ThemeData theme, {
    required bool isOrigin,
    required Place place,
  }) {
    final showConnector = isOrigin;
    final address =
        (place.address != null &&
            place.address!.isNotEmpty &&
            place.address != place.locationName)
        ? place.address
        : null;
    final nearby =
        (place.nearbyLocation != null && place.nearbyLocation!.isNotEmpty)
        ? place.nearbyLocation
        : null;
    final marker = Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOrigin ? AppColors.primary : Colors.white,
        border: Border.all(
          color: isOrigin
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.secondary,
          width: 3,
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Padding(padding: const EdgeInsets.only(top: 3), child: marker),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: showConnector ? AppSpacing.lg : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (isOrigin ? 'pickup'.tr : 'dropoff'.tr).toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    place.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (address != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                  if (nearby != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            IconsaxPlusLinear.location,
                            size: 13,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${'nearby'.tr}: $nearby',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Vehicle card — the booked class + the real vehicle the vendor assigned.
  Widget _vehicleCard(ThemeData theme) {
    final assigned = b.assignedVehicleLabel;
    final specsParts = <String>[
      if (b.vehicleColor != null && b.vehicleColor!.isNotEmpty) b.vehicleColor!,
      if (b.vehicleSeats != null)
        '${b.vehicleSeats} ${'seats'.tr.toLowerCase()}',
    ];
    final specs = specsParts.isEmpty ? null : specsParts.join(' · ');
    return _SectionCard(
      title: 'vehicle'.tr,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              IconsaxPlusBold.car,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (b.vehicleBooked != null && b.vehicleBooked!.isNotEmpty) ...[
                  Text(
                    'vehicle_booked'.tr.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 9.5,
                    ),
                  ),
                  Text(
                    b.vehicleBooked!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (assigned != null) ...[
                  if (b.vehicleBooked != null && b.vehicleBooked!.isNotEmpty)
                    const SizedBox(height: AppSpacing.sm),
                  Text(
                    'vehicle_assigned'.tr.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      fontSize: 9.5,
                    ),
                  ),
                  Text(
                    assigned,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (specs != null)
                    Text(
                      specs,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _operatorCard(ThemeData theme) {
    final operator = b.operator!;

    return _SectionCard(
      title: 'operator_info'.tr,
      titleGap: AppSpacing.sm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(
                  IconsaxPlusLinear.building,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operator.name ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'operator'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (operator.hasPhone) ...[
                const SizedBox(width: AppSpacing.sm),
                Material(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: controller.callOperator,
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        IconsaxPlusBold.call,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (operator.phone != null || operator.email != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (operator.phone != null)
                  _contactPill(
                    theme,
                    icon: IconsaxPlusLinear.call,
                    value: operator.phone!,
                    onTap: operator.hasPhone ? controller.callOperator : null,
                  ),
                if (operator.email != null)
                  _contactPill(
                    theme,
                    icon: IconsaxPlusLinear.sms,
                    value: operator.email!,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactPill(
    ThemeData theme, {
    required IconData icon,
    required String value,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Extra trip rows (flight / notes), divider-separated.
  List<Widget> _detailRows(ThemeData theme) {
    final rows = <Widget>[];
    void add(IconData icon, String label, String value) {
      if (rows.isNotEmpty) rows.add(const Divider(height: 1));
      rows.add(InfoRow(icon: icon, label: label, value: value));
    }

    if (b.isAirport && b.flightNumber != null) {
      add(
        IconsaxPlusLinear.airplane,
        'flight'.tr,
        [
          b.flightNumber,
          b.airline,
          b.terminal,
        ].where((e) => e != null && e.isNotEmpty).join(' · '),
      );
    }
    if (b.notes != null && b.notes!.isNotEmpty) {
      add(IconsaxPlusLinear.document_text, 'notes'.tr, b.notes!);
    }
    return rows;
  }
}

/// Soft card wrapper with an optional section title.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.title,
    this.titleGap = AppSpacing.md,
  });

  final Widget child;
  final String? title;
  final double titleGap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 2),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
              : AppColors.secondary.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: titleGap),
          ],
          child,
        ],
      ),
    );
  }
}

/// Bottom action dock: one glanceable stage CTA. Tap for routine steps;
/// swipe for the final, irreversible drop.
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.b, required this.controller});

  final BookingDetail b;
  final BookingDetailController controller;

  @override
  Widget build(BuildContext context) {
    if (b.allows('start') && b.isStartTooOld) {
      return _staleStartAction(context);
    }

    return Obx(() {
      // Final step is a deliberate swipe.
      if (b.allows('complete')) {
        return SwipeToConfirm(
          label: 'swipe_to_drop'.tr,
          loading: controller.isActing.value,
          onConfirmed: controller.complete,
        );
      }

      final action = b.allowedActions.isNotEmpty
          ? b.allowedActions.first
          : null;
      if (action == null) return const SizedBox.shrink();

      final (String label, IconData icon) = switch (action) {
        'start' => (
          b.isStartOverdue ? 'start_trip_now'.tr : 'start_now'.tr,
          IconsaxPlusLinear.play,
        ),
        'arrived' => ('mark_arrived'.tr, IconsaxPlusLinear.location_tick),
        'meet_passenger' => (
          'meet_passenger'.tr,
          IconsaxPlusLinear.profile_tick,
        ),
        _ => ('start_now'.tr, IconsaxPlusLinear.play),
      };

      return StepActionButton(
        label: label,
        icon: icon,
        loading: controller.isActing.value,
        onPressed: () => controller.runAction(action),
      );
    });
  }

  Widget _staleStartAction(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(IconsaxPlusLinear.headphone, size: 18),
        label: Text('contact_dispatch_to_start'.tr),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          disabledForegroundColor: AppColors.cancelled.withValues(alpha: 0.78),
          side: BorderSide(color: AppColors.cancelled.withValues(alpha: 0.22)),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _StartOverdueNotice extends StatelessWidget {
  const _StartOverdueNotice({required this.b});

  final BookingDetail b;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTooOld = b.isStartTooOld;
    final isVeryOverdue = b.isStartVeryOverdue;
    final color = isTooOld
        ? AppColors.cancelled
        : isVeryOverdue
        ? AppColors.assigned
        : AppColors.assigned;
    final key = isTooOld
        ? 'start_too_old_detail'
        : isVeryOverdue
        ? 'start_very_overdue_detail'
        : 'start_overdue_detail';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            isTooOld
                ? IconsaxPlusLinear.info_circle
                : IconsaxPlusLinear.timer_1,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              key.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Terminal summary on the detail screen once the driver reported they couldn't
/// meet the passenger.
class _PickupIssueSummary extends StatelessWidget {
  const _PickupIssueSummary({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.pickupIssue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(
            IconsaxPlusLinear.info_circle,
            color: AppColors.pickupIssue,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'report_pickup_issue_title'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (reason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    pickupIssueReasonLabel(reason),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
