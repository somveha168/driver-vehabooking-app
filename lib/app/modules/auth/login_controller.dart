import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final formKey = GlobalKey<FormState>();
  final loginCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final isLoading = false.obs;
  final obscure = true.obs;

  void toggleObscure() => obscure.toggle();

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      await _auth.login(loginCtrl.text.trim(), passwordCtrl.text);
      Get.offAllNamed(Routes.home);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    loginCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
