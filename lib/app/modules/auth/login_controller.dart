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
  final passwordFocusNode = FocusNode();

  final isLoading = false.obs;
  final canSignIn = false.obs;
  final obscure = true.obs;

  String? _appliedRouteIdentifier;

  @override
  void onInit() {
    loginCtrl.addListener(_syncSignInState);
    passwordCtrl.addListener(_syncSignInState);
    applyRouteArguments();
    _syncSignInState();
    super.onInit();
  }

  void toggleObscure() => obscure.toggle();

  void showHelp() => AppSnackbar.info('login_help_message'.tr);

  void applyRouteArguments() {
    final args = Get.arguments;
    if (args is! Map) return;

    final identifier = args['identifier']?.toString().trim();
    if (identifier == null || identifier.isEmpty) return;
    if (_appliedRouteIdentifier == identifier) return;

    _appliedRouteIdentifier = identifier;
    if (loginCtrl.text != identifier) {
      loginCtrl.text = identifier;
    }
    passwordCtrl.clear();
    _syncSignInState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        passwordFocusNode.requestFocus();
      }
    });
  }

  void forgotPassword() {
    Get.toNamed(
      Routes.forgotPassword,
      arguments: {'identifier': loginCtrl.text.trim()},
    );
  }

  Future<void> submit() async {
    if (!canSignIn.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    isLoading.value = true;
    try {
      await _auth.login(loginCtrl.text.trim(), passwordCtrl.text);
      passwordCtrl.clear();
      Get.offAllNamed(Routes.home);
    } on ApiException catch (e) {
      AppSnackbar.error(e.message);
    } catch (_) {
      AppSnackbar.error('error_generic'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void _syncSignInState() {
    canSignIn.value =
        loginCtrl.text.trim().isNotEmpty && passwordCtrl.text.isNotEmpty;
  }

  @override
  void onClose() {
    loginCtrl.removeListener(_syncSignInState);
    passwordCtrl.removeListener(_syncSignInState);
    loginCtrl.dispose();
    passwordCtrl.dispose();
    passwordFocusNode.dispose();
    super.onClose();
  }
}
