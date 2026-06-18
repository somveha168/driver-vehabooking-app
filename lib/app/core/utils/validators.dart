import 'package:get/get.dart';

/// Simple, localized form validators used by the login form.
class Validators {
  const Validators._();

  static String? loginField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'login_field_required'.tr;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required'.tr;
    }
    return null;
  }
}
