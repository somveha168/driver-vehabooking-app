import 'package:get/get.dart';

import 'booking_detail_controller.dart';

class BookingDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => BookingDetailController());
  }
}
