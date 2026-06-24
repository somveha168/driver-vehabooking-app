import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';
import 'dart:math' as math;

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
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Vehicle: booked class + the real assigned vehicle ──
        if (b.hasVehicle) ...[
          _vehicleCard(theme),
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
    final activeTarget = navigateToDropoff ? dropoff : pickup;
    final canNavigate = isCurrentLeg && !_isTerminalStage;

    return _SectionCard(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _routeMapPreview(
            theme,
            pickup: pickup,
            dropoff: dropoff,
            activeTarget: activeTarget,
            activeLabel: navigateToDropoff
                ? 'route_to_dropoff'.tr
                : 'route_to_pickup'.tr,
            distanceLabel: _routeDistanceLabel(pickup, dropoff),
          ),
          const SizedBox(height: AppSpacing.md),
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
          if (canNavigate) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: controller.navigateToActiveDestination,
                icon: const Icon(IconsaxPlusLinear.routing, size: 18),
                label: Text(
                  navigateToDropoff
                      ? 'navigate_to_dropoff'.tr
                      : 'navigate_to_pickup'.tr,
                ),
              ),
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

  bool get _isTerminalStage =>
      b.stage == 'completed' ||
      b.stage == 'pickup_issue' ||
      b.stage == 'cancelled';

  String? _routeDistanceLabel(Place pickup, Place dropoff) {
    if (!pickup.hasCoordinates || !dropoff.hasCoordinates) return null;

    final km = _distanceKm(
      pickup.latitude!,
      pickup.longitude!,
      dropoff.latitude!,
      dropoff.longitude!,
    );

    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  double _distanceKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(endLat - startLat);
    final dLng = _degreesToRadians(endLng - startLng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(startLat)) *
            math.cos(_degreesToRadians(endLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  String _shortPlaceLabel(Place place) {
    final label = place.locationName ?? place.address ?? place.label;
    return label.length <= 24 ? label : '${label.substring(0, 24)}...';
  }

  Widget _locationSummaryPill(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Place place,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _shortPlaceLabel(place),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeMapPreview(
    ThemeData theme, {
    required Place pickup,
    required Place dropoff,
    required Place activeTarget,
    required String activeLabel,
    String? distanceLabel,
  }) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            const Color(0xFFEAF7F3),
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RoutePreviewPainter(
                color: AppColors.primary,
                secondaryColor: AppColors.secondary,
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.md,
            right: AppSpacing.md,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            IconsaxPlusBold.routing,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                activeTarget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (distanceLabel != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      distanceLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Row(
              children: [
                Expanded(
                  child: _locationSummaryPill(
                    theme,
                    icon: IconsaxPlusLinear.location,
                    label: 'pickup'.tr.toUpperCase(),
                    place: pickup,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _locationSummaryPill(
                    theme,
                    icon: IconsaxPlusLinear.flag,
                    label: 'dropoff'.tr.toUpperCase(),
                    place: dropoff,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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

  /// Extra info rows (passengers / nationality / flight / notes), divider-separated.
  List<Widget> _detailRows(ThemeData theme) {
    final rows = <Widget>[];
    void add(IconData icon, String label, String value) {
      if (rows.isNotEmpty) rows.add(const Divider(height: 1));
      rows.add(InfoRow(icon: icon, label: label, value: value));
    }

    add(
      IconsaxPlusLinear.profile_2user,
      'passengers'.tr,
      '${b.passengerCount ?? 1}',
    );
    if (b.nationality != null && b.nationality!.isNotEmpty) {
      add(IconsaxPlusLinear.global, 'nationality'.tr, b.nationality!);
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
class _RoutePreviewPainter extends CustomPainter {
  const _RoutePreviewPainter({
    required this.color,
    required this.secondaryColor,
  });

  final Color color;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..strokeWidth = 1;

    for (var x = -size.width; x < size.width * 2; x += 34) {
      canvas.drawLine(
        Offset(x.toDouble(), 0),
        Offset(x + size.height * 0.55, size.height),
        gridPaint,
      );
    }

    for (var y = 18.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.20, size.height * 0.70)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.36,
        size.width * 0.55,
        size.height * 0.84,
        size.width * 0.70,
        size.height * 0.47,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.28,
        size.width * 0.90,
        size.height * 0.32,
        size.width * 0.86,
        size.height * 0.18,
      );

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 11;
    canvas.drawPath(route.shift(const Offset(0, 5)), shadowPaint);

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;
    canvas.drawPath(route, basePaint);

    final routePaint = Paint()
      ..shader = LinearGradient(
        colors: [color, secondaryColor, color],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    canvas.drawPath(route, routePaint);

    _drawPin(canvas, Offset(size.width * 0.20, size.height * 0.70), color, 'A');
    _drawPin(
      canvas,
      Offset(size.width * 0.86, size.height * 0.18),
      secondaryColor,
      'B',
    );
  }

  void _drawPin(Canvas canvas, Offset center, Color color, String label) {
    final outerPaint = Paint()..color = Colors.white;
    final innerPaint = Paint()..color = color;
    canvas.drawCircle(center, 16, outerPaint);
    canvas.drawCircle(center, 11, innerPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePreviewPainter oldDelegate) {
    return color != oldDelegate.color ||
        secondaryColor != oldDelegate.secondaryColor;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title});

  final Widget child;
  final String? title;

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
            const SizedBox(height: AppSpacing.md),
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
        'start' => ('start_now'.tr, IconsaxPlusLinear.play),
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
