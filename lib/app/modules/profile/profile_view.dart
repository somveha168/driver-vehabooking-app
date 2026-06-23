import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_label.dart';
import 'profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? theme.colorScheme.surface : AppColors.canvas;

    return Scaffold(
      backgroundColor: canvas,
      body: Container(
        // Brand wash: soft primary radial glow from the top-right over the
        // canvas — identical to the home/dashboard page, for consistency.
        decoration: BoxDecoration(
          color: canvas,
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.55,
            colors: [
              AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.26),
              AppColors.primary.withValues(alpha: isDark ? 0.06 : 0.10),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 0.82],
          ),
        ),
        child: Form(
          key: controller.formKey,
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
            children: [
              _CoverHeader(controller: controller),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Collapsible identity / edit block (card-less, centered).
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Obx(() {
                          final editing = controller.isEditing.value;
                          return AnimatedSize(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOut,
                              switchOutCurve: Curves.easeIn,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.04),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: editing
                                  ? _EditForm(
                                      key: const ValueKey('edit'),
                                      controller: controller,
                                    )
                                  : _Identity(
                                      key: const ValueKey('identity'),
                                      controller: controller,
                                    ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    SectionLabel('documents'.tr),
                    const SizedBox(height: AppSpacing.md),
                    _NavRow(
                      icon: IconsaxPlusLinear.personalcard,
                      title: 'my_documents'.tr,
                      subtitle: 'documents_subtitle'.tr,
                      onTap: controller.openDocuments,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    SectionLabel('support'.tr),
                    const SizedBox(height: AppSpacing.md),
                    _NavRow(
                      icon: IconsaxPlusLinear.book_1,
                      title: 'help_and_guide'.tr,
                      onTap: controller.openGuide,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    _CompactPrefs(controller: controller),
                    const SizedBox(height: AppSpacing.xl),

                    OutlinedButton.icon(
                      onPressed: controller.logout,
                      icon: const Icon(IconsaxPlusLinear.logout, size: 18),
                      label: Text('sign_out'.tr),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: theme.colorScheme.error.withValues(alpha: 0.4),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        '${AppConfig.appName} · 1.0.0',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft teal cover (gradient from top-right) + centered avatar + name.
class _CoverHeader extends StatelessWidget {
  const _CoverHeader({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final coverHeight = topInset + 88;
    const avatarRadius = 52.0;

    return Column(
      children: [
        SizedBox(
          height: coverHeight + avatarRadius,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // No band — the page's radial brand wash shows through, so the
              // header matches the home page. This just reserves the space
              // the avatar overlaps into.
              SizedBox(height: coverHeight, width: double.infinity),
              Positioned(
                top: coverHeight - avatarRadius,
                left: 0,
                right: 0,
                child: Center(
                  child: _AvatarCircle(
                    controller: controller,
                    radius: avatarRadius,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Save / cancel for a freshly picked photo — directly under the
        // avatar so submitting just the avatar is obvious. When no photo is
        // picked it simply holds the normal gap before the name.
        Obx(() {
          if (controller.pickedPhotoPath.value == null) {
            return const SizedBox(height: AppSpacing.md);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: controller.isUploadingPhoto.value
                      ? null
                      : controller.savePhoto,
                  icon: controller.isUploadingPhoto.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(IconsaxPlusLinear.tick_circle, size: 18),
                  label: Text('save_photo'.tr),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: controller.isUploadingPhoto.value
                      ? null
                      : controller.discardPhoto,
                  child: Text('cancel'.tr),
                ),
              ],
            ),
          );
        }),
        Obx(
          () => Text(
            controller.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Collapsed view: phone, email + an Edit button.
class _Identity extends StatelessWidget {
  const _Identity({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              if (user?.phone != null && user!.phone!.isNotEmpty)
                _chip(context, user.phone!),
              if (user?.email != null && user!.email!.isNotEmpty)
                _chip(context, user.email!),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: controller.startEdit,
            icon: const Icon(IconsaxPlusLinear.edit_2, size: 14),
            label: Text('edit_profile'.tr),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 6,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _chip(BuildContext context, String value) {
    final theme = Theme.of(context);
    return Text(
      value,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.outline,
      ),
    );
  }
}

/// Expanded inline edit form.
class _EditForm extends StatelessWidget {
  const _EditForm({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // First + last name share a row.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(
                context,
                label: 'first_name'.tr,
                ctrl: controller.firstNameCtrl,
                icon: IconsaxPlusLinear.profile,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'first_name_required'.tr
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _field(
                context,
                label: 'last_name'.tr,
                ctrl: controller.lastNameCtrl,
                icon: IconsaxPlusLinear.profile,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'last_name_required'.tr
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _dateField(context),
        const SizedBox(height: AppSpacing.sm),
        _genderField(context),
        const SizedBox(height: AppSpacing.sm),
        _field(
          context,
          label: 'phone'.tr,
          ctrl: controller.phoneCtrl,
          icon: IconsaxPlusLinear.call,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.sm),
        _field(
          context,
          label: 'email'.tr,
          ctrl: controller.emailCtrl,
          icon: IconsaxPlusLinear.sms,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            return GetUtils.isEmail(v.trim()) ? null : 'email_invalid'.tr;
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        _field(
          context,
          label: 'current_address'.tr,
          ctrl: controller.currentAddressCtrl,
          icon: IconsaxPlusLinear.location,
          hint: 'current_address_hint'.tr,
          keyboardType: TextInputType.streetAddress,
          textInputAction: TextInputAction.newline,
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),

        // Compact action row.
        Row(
          children: [
            Expanded(
              child: Obx(
                () => FilledButton(
                  onPressed: controller.isSaving.value ? null : controller.save,
                  style: _btnStyle,
                  child: controller.isSaving.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('save_changes'.tr),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: controller.cancelEdit,
              style: _cancelStyle,
              child: Text('cancel'.tr),
            ),
          ],
        ),
      ],
    );
  }

  static final ButtonStyle _btnStyle = FilledButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    ),
  );

  static final ButtonStyle _cancelStyle = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: const Size(0, 44),
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.72)),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
    ),
  );

  /// Compact labeled field: a small caption label above a dense filled input.
  Widget _field(
    BuildContext context, {
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction textInputAction = TextInputAction.next,
    bool autocorrect = true,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final fieldFill = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
        : Colors.white;

    return _labeled(
      context,
      label: label,
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autocorrect: autocorrect,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: fieldFill,
          hintText: hint,
          alignLabelWithHint: maxLines > 1,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          prefixIcon: Padding(
            // Top-align the icon when the field grows to multiple lines.
            padding: EdgeInsets.only(
              bottom: maxLines > 1 ? (maxLines - 1) * 19.0 : 0,
            ),
            child: Icon(icon, size: 19),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 0,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.72),
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  /// A modern tappable date-of-birth tile: a tinted calendar badge, the chosen
  /// date (or placeholder), and a chevron — opens the native picker.
  Widget _dateField(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
        : Colors.white;

    return _labeled(
      context,
      label: 'date_of_birth'.tr,
      child: Obx(() {
        final dob = controller.dateOfBirth.value;
        final hasValue = dob != null;
        final text = hasValue
            ? DateFormat('dd MMM yyyy').format(dob)
            : 'select_date'.tr;
        return Material(
          color: tileColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: InkWell(
            onTap: () => controller.pickDateOfBirth(context),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      IconsaxPlusLinear.calendar_1,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasValue
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: hasValue
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(
                    IconsaxPlusLinear.arrow_down_1,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  /// A compact Male / Female tab control with icons and a sliding active pill.
  Widget _genderField(BuildContext context) {
    final theme = Theme.of(context);
    final trackColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
        : Colors.white.withValues(alpha: 0.76);

    return _labeled(
      context,
      label: 'gender'.tr,
      child: Obx(() {
        final selected = controller.gender.value;
        Widget tab(String value, String label, IconData icon) {
          final active = selected == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => controller.setGender(value),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: 36,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: active
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: active
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              tab('male', 'male'.tr, Icons.male_rounded),
              const SizedBox(width: 4),
              tab('female', 'female'.tr, Icons.female_rounded),
            ],
          ),
        );
      }),
    );
  }

  /// Small caption label above an arbitrary input control.
  Widget _labeled(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.controller, required this.radius});

  final ProfileController controller;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = controller.user;
      final picked = controller.pickedPhotoPath.value;
      final url = user?.imageUrl;

      ImageProvider? image;
      if (picked != null) {
        image = FileImage(File(picked));
      } else if (url != null && url.isNotEmpty) {
        image = NetworkImage(url);
      }

      return Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: radius - 4,
              // Solid soft tint = primary blended into white (clean, opaque,
              // independent of whatever sits behind the avatar).
              backgroundColor: Color.alphaBlend(
                AppColors.primary.withValues(alpha: 0.12),
                Colors.white,
              ),
              backgroundImage: image,
              child: image == null
                  ? Text(
                      _initials(user?.name),
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _pickSheet(context),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  IconsaxPlusLinear.camera,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  void _pickSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(IconsaxPlusLinear.camera),
              title: Text('take_photo'.tr),
              onTap: () {
                Navigator.of(context).pop();
                controller.pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(IconsaxPlusLinear.gallery),
              title: Text('choose_gallery'.tr),
              onTap: () {
                Navigator.of(context).pop();
                controller.pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// Tappable settings row card.
class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: softCardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
        trailing: Icon(
          IconsaxPlusLinear.arrow_right_3,
          size: 18,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

/// Small, low-emphasis language + theme controls.
class _CompactPrefs extends StatelessWidget {
  const _CompactPrefs({required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final small = SegmentedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 12),
    );

    Widget row(IconData icon, String label, Widget control) => Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.outline),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const Spacer(),
        control,
      ],
    );

    return Container(
      decoration: softCardDecoration(context),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          row(
            IconsaxPlusLinear.global,
            'language'.tr,
            Obx(
              () => SegmentedButton<String>(
                style: small,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'en', label: Text('EN')),
                  ButtonSegment(value: 'km', label: Text('ខ្មែរ')),
                ],
                selected: {controller.settings.isKhmer ? 'km' : 'en'},
                onSelectionChanged: (_) => controller.settings.toggleLanguage(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1),
          ),
          row(
            IconsaxPlusLinear.moon,
            'theme'.tr,
            Obx(
              () => SegmentedButton<ThemeMode>(
                style: small,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(IconsaxPlusLinear.setting_2, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(IconsaxPlusLinear.sun_1, size: 16),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(IconsaxPlusLinear.moon, size: 16),
                  ),
                ],
                selected: {controller.settings.themeMode.value},
                onSelectionChanged: (s) =>
                    controller.settings.setThemeMode(s.first),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
