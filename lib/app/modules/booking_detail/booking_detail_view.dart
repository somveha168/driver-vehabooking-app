import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/info_row.dart';
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
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        if (controller.error.value != null) {
          return ErrorView(message: controller.error.value!, onRetry: controller.load);
        }
        final b = controller.booking.value;
        if (b == null) return const SizedBox.shrink();
        return _Detail(b: b, controller: controller);
      }),
      bottomNavigationBar: Obx(() {
        final b = controller.booking.value;
        if (b == null || !b.can) return const SizedBox.shrink();
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
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TripSteps(stage: b.stage),
            const SizedBox(height: AppSpacing.lg),
            _ActionBar(b: b, controller: controller),
            if (b.allows('report_not_met_passenger')) ...[
              const SizedBox(height: AppSpacing.xs),
              Obx(
                () => TextButton(
                  onPressed: controller.isActing.value
                      ? null
                      : () => _openNotMetSheet(context, controller),
                  child: Text('cant_find_passenger'.tr),
                ),
              ),
            ],
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
            child: Icon(IconsaxPlusLinear.arrow_left_2,
                size: 20, color: AppColors.secondary),
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
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.outline),
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
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _subtitle(),
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.outline),
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

        // ── Couldn't-meet-passenger summary (terminal) ──
        if (b.stage == 'not_met_passenger') ...[
          _NotMetSummary(reason: b.notMetPassengerReason),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Route: where + when, with Navigate ──
        _SectionCard(
          title: 'route'.tr,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _departureRow(theme),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              _routeStop(theme, isOrigin: true, place: b.pickup),
              _routeStop(theme, isOrigin: false, place: b.dropoff),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: controller.navigateToPickup,
                  icon: const Icon(IconsaxPlusLinear.routing, size: 18),
                  label: Text('navigate'.tr),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Return trip (round-trip bookings) ──
        if (b.hasReturn) ...[
          _SectionCard(
            title: 'return_trip'.tr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sync_rounded, size: 18, color: AppColors.onTrip),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'round_trip'.tr,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: theme.colorScheme.outline),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _returnWhen(),
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                // On the way back the route reverses.
                _routeStop(theme, isOrigin: true, place: b.dropoff),
                _routeStop(theme, isOrigin: false, place: b.pickup),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'return_note'.tr,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
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
    final trip = b.hasReturn ? 'round_trip'.tr : (b.tripType?.capitalizeFirst ?? '');
    return [svc, trip].where((e) => e.isNotEmpty).join(' · ');
  }

  /// Return leg date + time, e.g. "24 Jun · 07:35".
  String _returnWhen() {
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
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      );

  Widget _departureRow(ThemeData theme) => Row(
        children: [
          const Icon(IconsaxPlusBold.calendar, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'departure'.tr,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.dateTime(b.departureDatetime),
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      );

  /// A pickup/drop-off stop in the route mini-timeline: marker + name + address.
  Widget _routeStop(ThemeData theme,
      {required bool isOrigin, required Place place}) {
    final showConnector = isOrigin;
    final address = (place.address != null &&
            place.address!.isNotEmpty &&
            place.address != place.locationName)
        ? place.address
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
              padding: EdgeInsets.only(bottom: showConnector ? AppSpacing.lg : 0),
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
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (address != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      address,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
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
      if (b.vehicleSeats != null) '${b.vehicleSeats} ${'seats'.tr.toLowerCase()}',
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
            child: const Icon(IconsaxPlusBold.car, size: 22, color: AppColors.primary),
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
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (specs != null)
                    Text(
                      specs,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
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

    add(IconsaxPlusLinear.profile_2user, 'passengers'.tr, '${b.passengerCount ?? 1}');
    if (b.nationality != null && b.nationality!.isNotEmpty) {
      add(IconsaxPlusLinear.global, 'nationality'.tr, b.nationality!);
    }
    if (b.isAirport && b.flightNumber != null) {
      add(
        IconsaxPlusLinear.airplane,
        'flight'.tr,
        [b.flightNumber, b.airline, b.terminal]
            .where((e) => e != null && e.isNotEmpty)
            .join(' · '),
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
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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

      final action = b.allowedActions.isNotEmpty ? b.allowedActions.first : null;
      if (action == null) return const SizedBox.shrink();

      final (String label, IconData icon) = switch (action) {
        'start' => ('start_now'.tr, IconsaxPlusLinear.play),
        'arrived' => ('mark_arrived'.tr, IconsaxPlusLinear.location_tick),
        'meet_passenger' => ('meet_passenger'.tr, IconsaxPlusLinear.profile_tick),
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

/// Opens the "couldn't meet passenger" report sheet.
Future<void> _openNotMetSheet(BuildContext context, BookingDetailController controller) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _NotMetSheet(controller: controller),
  );
}

String _notMetReasonLabel(String? key) => switch (key) {
      'cant_reach' => 'reason_cant_reach'.tr,
      'customer_cancelled' => 'reason_customer_cancelled'.tr,
      'didnt_show' => 'reason_didnt_show'.tr,
      _ => 'report_not_met_title'.tr,
    };

/// Terminal summary on the detail screen once the driver reported they couldn't
/// meet the passenger.
class _NotMetSummary extends StatelessWidget {
  const _NotMetSummary({this.reason});

  final String? reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.notMet.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.info_circle, color: AppColors.notMet),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'report_not_met_title'.tr,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (reason != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _notMetReasonLabel(reason),
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
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

/// Bottom sheet: pick a reason (+ optional note) for not meeting the passenger.
class _NotMetSheet extends StatefulWidget {
  const _NotMetSheet({required this.controller});

  final BookingDetailController controller;

  @override
  State<_NotMetSheet> createState() => _NotMetSheetState();
}

class _NotMetSheetState extends State<_NotMetSheet> {
  static const _reasons = ['didnt_show', 'cant_reach', 'customer_cancelled'];
  String? _reason;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;
    Navigator.of(context).pop();
    await widget.controller.reportNotMetPassenger(reason, _noteController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'report_not_met_title'.tr,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'report_not_met_hint'.tr,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final r in _reasons)
            _ReasonTile(
              label: _notMetReasonLabel(r),
              selected: _reason == r,
              onTap: () => setState(() => _reason = r),
            ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _noteController,
            maxLines: 2,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'add_note_optional'.tr,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _reason == null ? null : _submit,
              child: Text('submit_report'.tr),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable reason row with a custom radio indicator.
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              selected ? IconsaxPlusBold.tick_circle : IconsaxPlusLinear.record,
              color: selected ? AppColors.primary : theme.colorScheme.outlineVariant,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
