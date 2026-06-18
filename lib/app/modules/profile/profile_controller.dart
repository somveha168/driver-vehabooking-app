import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/settings_service.dart';
import '../home/home_controller.dart';

class ProfileController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();
  final SettingsService settings = Get.find<SettingsService>();

  AuthUser? get user => _auth.currentUser.value;

  void editProfile() => Get.toNamed(Routes.editProfile);

  /// Jump to the Guide tab.
  void openGuide() => Get.find<HomeController>().changeTab(2);

  Future<void> logout() async {
    await _auth.logout();
    Get.offAllNamed(Routes.login);
  }
}
