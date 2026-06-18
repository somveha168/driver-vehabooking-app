import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/state_views.dart';
import 'bookings_controller.dart';
import 'widgets/booking_card.dart';

class BookingsView extends GetView<BookingsController> {
  const BookingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('bookings_title'.tr),
        bottom: TabBar(
          controller: controller.tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'tab_assigned'.tr),
            Tab(text: 'tab_accepted'.tr),
            Tab(text: 'tab_on_trip'.tr),
            Tab(text: 'tab_completed'.tr),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();

        if (controller.error.value != null) {
          return ErrorView(
            message: controller.error.value!,
            onRetry: controller.fetch,
          );
        }

        if (controller.items.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetch,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
                EmptyView(
                  title: 'no_bookings'.tr,
                  hint: 'no_bookings_hint'.tr,
                  icon: IconsaxPlusLinear.calendar_remove,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.navClearance),
            itemCount: controller.items.length,
            itemBuilder: (context, index) {
              final booking = controller.items[index];
              return BookingCard(
                booking: booking,
                onTap: () => Get.toNamed(
                  Routes.bookingDetail,
                  arguments: booking.uuid,
                )?.then((_) => controller.fetch(silent: true)),
              );
            },
          ),
        );
      }),
    );
  }
}
