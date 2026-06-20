import 'package:get/get.dart';

import 'splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Eager: the view doesn't read `controller`, so lazyPut would never create
    // it — and its onReady (which schedules navigation) would never fire.
    Get.put(SplashController());
  }
}
