import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/app_snackbar.dart';
import '../../data/services/auth_service.dart';

class EditProfileController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final formKey = GlobalKey<FormState>();
  late final TextEditingController firstNameCtrl;
  late final TextEditingController lastNameCtrl;
  late final TextEditingController phoneCtrl;

  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final user = _auth.currentUser.value;
    firstNameCtrl = TextEditingController(text: user?.firstName ?? '');
    lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    isSaving.value = true;
    try {
      await _auth.updateProfile(
        firstName: firstNameCtrl.text.trim(),
        lastName: lastNameCtrl.text.trim(),
        phone: phoneCtrl.text.trim(),
      );
      AppSnackbar.success('profile_updated'.tr);
      Get.back();
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}
