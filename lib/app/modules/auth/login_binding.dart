import 'package:get/get.dart';

import 'login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LoginController>()) {
      Get.put(LoginController(), permanent: true);
    }
  }
}
