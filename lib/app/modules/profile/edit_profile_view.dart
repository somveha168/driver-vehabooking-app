import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import 'edit_profile_controller.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('edit_profile'.tr)),
      body: Form(
        key: controller.formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              decoration: softCardDecoration(context),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.firstNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'first_name'.tr,
                      prefixIcon: const Icon(IconsaxPlusLinear.profile),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'first_name_required'.tr
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: controller.lastNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'last_name'.tr,
                      prefixIcon: const Icon(IconsaxPlusLinear.profile),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'last_name_required'.tr
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: controller.phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'phone'.tr,
                      prefixIcon: const Icon(IconsaxPlusLinear.call),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Obx(
              () => FilledButton(
                onPressed: controller.isSaving.value ? null : controller.save,
                child: controller.isSaving.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('save_changes'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
