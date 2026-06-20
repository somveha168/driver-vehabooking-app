import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/info_row.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/swipe_to_confirm.dart';
import '../../core/widgets/trip_timeline.dart';
import '../../data/models/booking_detail.dart';
import 'booking_detail_controller.dart';

class BookingDetailView extends GetView<BookingDetailController> {
  const BookingDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('booking_detail'.tr)),
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
        return SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionBar(b: b, controller: controller),
              if (b.allows('report_not_met_passenger')) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: controller.isActing.value
                      ? null
                      : () => _openNotMetSheet(context, controller),
                  child: Text('cant_find_passenger'.tr),
                ),
              ],
            ],
          ),
        );
      }),
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
    final inProgress =
        b.stage != 'completed' && b.stage != 'cancelled' && b.stage != 'not_met_passenger';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Hero: who + status, big and glanceable ──
        Row(
          children: [
            Text(
              '#${b.code ?? '—'}',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const Spacer(),
            StatusChip(stage: b.stage),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          b.customerName ?? '—',
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _subtitle(),
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Quick actions — always in thumb reach.
        Row(
          children: [
            if (_hasPhone) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.callCustomer,
                  icon: const Icon(IconsaxPlusLinear.call, size: 18),
                  label: Text('call'.tr),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: controller.navigateToPickup,
                icon: const Icon(IconsaxPlusLinear.routing, size: 18),
                label: Text('navigate'.tr),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Trip progress timeline ──
        if (inProgress) ...[
          _SectionCard(
            title: 'trip_progress'.tr,
            child: TripTimeline(
              stage: b.stage,
              startedAt: b.startedAt,
              arrivedAt: b.arrivedAt,
              metPassengerAt: b.metPassengerAt,
              droppedAt: b.droppedAt,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Couldn't-meet-passenger summary (terminal) ──
        if (b.stage == 'not_met_passenger') ...[
          _NotMetSummary(reason: b.notMetPassengerReason),
          const SizedBox(height: AppSpacing.md),
        ],

        // ── Route ──
        _SectionCard(
          child: Column(
            children: [
              InfoRow(
                icon: IconsaxPlusLinear.clock,
                label: 'departure'.tr,
                value: Formatters.dateTime(b.departureDatetime),
              ),
              const Divider(height: 1),
              InfoRow(
                icon: IconsaxPlusLinear.gps,
                label: 'pickup'.tr,
                value: b.pickup.label,
              ),
              const Divider(height: 1),
              InfoRow(
                icon: IconsaxPlusLinear.location,
                label: 'dropoff'.tr,
                value: b.dropoff.label,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Details ──
        _SectionCard(
          child: Column(
            children: [
              InfoRow(
                icon: IconsaxPlusLinear.profile_2user,
                label: 'passengers'.tr,
                value: '${b.passengerCount ?? 1}',
              ),
              if (b.vehicleType != null || b.plateNumber != null) ...[
                const Divider(height: 1),
                InfoRow(
                  icon: IconsaxPlusLinear.car,
                  label: 'vehicle'.tr,
                  value: [b.vehicleType, b.plateNumber]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(' · '),
                ),
              ],
              if (b.isAirport && b.flightNumber != null) ...[
                const Divider(height: 1),
                InfoRow(
                  icon: IconsaxPlusLinear.airplane,
                  label: 'flight'.tr,
                  value: [b.flightNumber, b.airline, b.terminal]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(' · '),
                ),
              ],
              if (b.notes != null && b.notes!.isNotEmpty) ...[
                const Divider(height: 1),
                InfoRow(
                  icon: IconsaxPlusLinear.document_text,
                  label: 'notes'.tr,
                  value: b.notes!,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }

  String _subtitle() {
    final svc = b.serviceType?.capitalizeFirst ?? '';
    final pax = '${b.passengerCount ?? 1} ${'passengers'.tr.toLowerCase()}';
    return [svc, pax].where((e) => e.isNotEmpty).join(' · ');
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
    return Card(
      child: Padding(
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

    final acting = controller.isActing.value;
    return FilledButton.icon(
      onPressed: acting ? null : () => controller.runAction(action),
      icon: acting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(icon, size: 20),
      label: Text(label),
    );
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
