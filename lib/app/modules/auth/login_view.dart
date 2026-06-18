import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../data/services/settings_service.dart';
import 'login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Get.find<SettingsService>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: settings.toggleLanguage,
                  icon: const Icon(Icons.translate, size: 18),
                  label: Obx(() => Text(settings.isKhmer ? 'EN' : 'ខ្មែរ')),
                ),
              ),
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Icon(Icons.local_taxi_rounded,
                    size: 38, color: theme.colorScheme.onPrimaryContainer),
              ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: AppSpacing.xl),
              Text('login_title'.tr, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'login_subtitle'.tr,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Form(
                key: controller.formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: controller.loginCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: 'login_field'.tr,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: Validators.loginField,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Obx(
                      () => TextFormField(
                        controller: controller.passwordCtrl,
                        obscureText: controller.obscure.value,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => controller.submit(),
                        decoration: InputDecoration(
                          labelText: 'password'.tr,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: controller.toggleObscure,
                            icon: Icon(controller.obscure.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
                        validator: Validators.password,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Obx(
                () => FilledButton(
                  onPressed: controller.isLoading.value ? null : controller.submit,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('sign_in'.tr),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
