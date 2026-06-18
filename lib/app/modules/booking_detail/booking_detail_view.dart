import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/info_row.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/swipe_to_confirm.dart';
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
          child: _ActionBar(b: b, controller: controller),
        );
      }),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.b, required this.controller});

  final BookingDetail b;
  final BookingDetailController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: [
            Text(b.code ?? '—', style: theme.textTheme.titleLarge),
            const Spacer(),
            StatusChip(stage: b.stage),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // In-app pickup reminder (v1 substitute for push).
        if (b.stage == 'accepted')
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(IconsaxPlusLinear.notification_bing,
                    color: theme.colorScheme.onTertiaryContainer),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('pickup_soon'.tr,
                      style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
                ),
              ],
            ),
          ),

        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              children: [
                InfoRow(
                  icon: IconsaxPlusLinear.profile,
                  label: 'customer'.tr,
                  value: b.customerName ?? '—',
                  trailing: (b.customerPhone != null &&
                          b.customerPhone!.isNotEmpty &&
                          b.customerPhone != 'N/A')
                      ? IconButton.filledTonal(
                          onPressed: controller.callCustomer,
                          icon: const Icon(IconsaxPlusLinear.call),
                          tooltip: 'call_customer'.tr,
                        )
                      : null,
                ),
                const Divider(height: 1),
                InfoRow(
                  icon: IconsaxPlusLinear.clock,
                  label: 'departure'.tr,
                  value: Formatters.dateTime(b.departureDatetime),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Column(
              children: [
                InfoRow(
                  icon: IconsaxPlusLinear.gps,
                  label: 'pickup'.tr,
                  value: b.pickup.label,
                  trailing: FilledButton.tonalIcon(
                    onPressed: controller.navigateToPickup,
                    icon: const Icon(IconsaxPlusLinear.routing, size: 18),
                    label: Text('navigate'.tr),
                  ),
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
        ),
        const SizedBox(height: AppSpacing.md),

        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
        ),
        const SizedBox(height: AppSpacing.xxxl),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.b, required this.controller});

  final BookingDetail b;
  final BookingDetailController controller;

  @override
  Widget build(BuildContext context) {
    if (b.allows('complete')) {
      return SwipeToConfirm(
        label: 'swipe_to_complete'.tr,
        loading: controller.isActing.value,
        onConfirmed: controller.complete,
      );
    }

    final bool isAccept = b.allows('accept');
    final String label = isAccept ? 'accept_booking'.tr : 'confirm_pickup'.tr;
    final VoidCallback onPressed =
        isAccept ? controller.accept : controller.confirmPickup;

    return FilledButton(
      onPressed: controller.isActing.value ? null : onPressed,
      child: controller.isActing.value
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }
}
