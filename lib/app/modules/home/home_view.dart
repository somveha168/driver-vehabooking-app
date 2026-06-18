import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/widgets/app_bottom_nav.dart';
import '../bookings/bookings_view.dart';
import '../dashboard/dashboard_view.dart';
import '../guide/guide_view.dart';
import '../profile/profile_view.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: controller.navIndex.value,
          children: const [
            DashboardView(),
            BookingsView(),
            GuideView(),
            ProfileView(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: controller.navIndex.value,
          onTap: controller.changeTab,
          items: [
            AppNavItem(
              icon: IconsaxPlusLinear.home_2,
              selectedIcon: IconsaxPlusBold.home_2,
              label: 'nav_home'.tr,
            ),
            AppNavItem(
              icon: IconsaxPlusLinear.calendar,
              selectedIcon: IconsaxPlusBold.calendar,
              label: 'nav_bookings'.tr,
            ),
            AppNavItem(
              icon: IconsaxPlusLinear.book_1,
              selectedIcon: IconsaxPlusBold.book_1,
              label: 'nav_guide'.tr,
            ),
            AppNavItem(
              icon: IconsaxPlusLinear.profile_circle,
              selectedIcon: IconsaxPlusBold.profile_circle,
              label: 'nav_profile'.tr,
            ),
          ],
        ),
      ),
    );
  }
}
