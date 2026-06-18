import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

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
      appBar: AppBar(
        backgroundColor: canvas,
        title: Text('profile_title'.tr),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.navClearance),
        children: [
          _header(context),
          const SizedBox(height: AppSpacing.xl),

          SectionLabel('account'.tr),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: softCardDecoration(context),
            clipBehavior: Clip.antiAlias,
            child: _NavRow(
              icon: IconsaxPlusLinear.user_edit,
              label: 'edit_profile'.tr,
              onTap: controller.editProfile,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionLabel('preferences'.tr),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: softCardDecoration(context),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _prefHeader(theme, IconsaxPlusLinear.global, 'language'.tr),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'km', label: Text('ខ្មែរ')),
                    ],
                    selected: {controller.settings.isKhmer ? 'km' : 'en'},
                    onSelectionChanged: (_) => controller.settings.toggleLanguage(),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Divider(height: 1),
                ),
                _prefHeader(theme, IconsaxPlusLinear.moon, 'theme'.tr),
                const SizedBox(height: AppSpacing.md),
                Obx(
                  () => SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system, icon: Icon(IconsaxPlusLinear.setting_2)),
                      ButtonSegment(
                          value: ThemeMode.light, icon: Icon(IconsaxPlusLinear.sun_1)),
                      ButtonSegment(
                          value: ThemeMode.dark, icon: Icon(IconsaxPlusLinear.moon)),
                    ],
                    selected: {controller.settings.themeMode.value},
                    onSelectionChanged: (s) =>
                        controller.settings.setThemeMode(s.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionLabel('support'.tr),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: softCardDecoration(context),
            clipBehavior: Clip.antiAlias,
            child: _NavRow(
              icon: IconsaxPlusLinear.book_1,
              label: 'help_and_guide'.tr,
              onTap: controller.openGuide,
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          OutlinedButton.icon(
            onPressed: controller.logout,
            icon: const Icon(IconsaxPlusLinear.logout),
            label: Text('sign_out'.tr),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.4)),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              '${AppConfig.appName} · 1.0.0',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final user = controller.user;
    return Container(
      decoration: softCardDecoration(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              _initials(user?.name),
              style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? '—',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                if (user?.phone != null)
                  Text(user!.phone!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                if (user?.email != null && user!.email!.isNotEmpty)
                  Text(user.email!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          IconButton(
            onPressed: controller.editProfile,
            icon: const Icon(IconsaxPlusLinear.edit_2),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _prefHeader(ThemeData theme, IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      );

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// A tappable settings row (icon · label · chevron).
class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: theme.textTheme.titleSmall),
      trailing: Icon(IconsaxPlusLinear.arrow_right_3,
          size: 18, color: theme.colorScheme.outline),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }
}
