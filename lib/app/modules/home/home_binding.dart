import 'package:get/get.dart';

import '../bookings/bookings_controller.dart';
import '../dashboard/dashboard_controller.dart';
import '../guide/guide_controller.dart';
import '../profile/profile_controller.dart';
import 'home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => DashboardController());
    Get.lazyPut(() => BookingsController());
    Get.lazyPut(() => GuideController());
    Get.lazyPut(() => ProfileController());
  }
}
