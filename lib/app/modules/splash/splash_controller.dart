import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/storage/storage_service.dart';
import '../../data/services/auth_service.dart';

/// The loading screen: plays the logo-draw, then routes to the right place.
class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    // Let the logo finish drawing, then decide where to go. (onInit is
    // guaranteed to run on creation; the delay keeps us past the first frame.)
    Future.delayed(const Duration(milliseconds: 1800), _go);
  }

  void _go() {
    final storage = Get.find<StorageService>();
    final loggedIn = Get.find<AuthService>().isLoggedIn;
    final next = !storage.seenOnboarding
        ? Routes.welcome
        : (loggedIn ? Routes.home : Routes.login);
    Get.offAllNamed(next);
  }
}
