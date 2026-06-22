import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/i18n/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../data/services/settings_service.dart';
import 'login_controller.dart';

/// Driver sign-in. Brand-consistent with the Welcome screen: soft teal/navy
/// aurora glows on the canvas, the logo + wordmark, and the form lifted into a
/// glass card for a focused, professional feel.
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? scheme.surface : AppColors.canvas;
    final settings = Get.find<SettingsService>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: canvas,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Brand aurora — two soft glows for depth, no image.
            Positioned(
              top: -120,
              right: -90,
              child: _glow(AppColors.primary, 360, isDark ? 0.22 : 0.30),
            ),
            Positioned(
              bottom: -150,
              left: -110,
              child: _glow(AppColors.secondary, 320, isDark ? 0.20 : 0.14),
            ),

            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xxl,
                    AppSpacing.md,
                    AppSpacing.xxl,
                    AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _langToggle(context, settings)
                                .animate()
                                .fadeIn(duration: 400.ms),
                          ),
                          const Spacer(flex: 2),

                          _brand(theme),
                          const Spacer(flex: 2),

                          _headline(theme, scheme),
                          const SizedBox(height: AppSpacing.xl),

                          _card(context, theme, scheme, isDark),
                          const SizedBox(height: AppSpacing.xl),

                          // Dispatcher help footer — drivers don't self-register.
                          Center(
                            child: TextButton(
                              onPressed: controller.showHelp,
                              child: Text(
                                'login_help'.tr,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 560.ms, duration: 500.ms),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Sections ----------------------------------------------------------

  /// Logo mark + "VEHA BOOKING" wordmark.
  Widget _brand(ThemeData theme) => Column(
        children: [
          Image.asset('assets/branding/app_icon.png', height: 88)
              .animate()
              .fadeIn(duration: 550.ms)
              .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'VEHA BOOKING',
            style: GoogleFonts.kantumruyPro(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 3.0,
              color: AppColors.secondary,
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
        ],
      );

  /// "Welcome back" display title + subtitle.
  Widget _headline(ThemeData theme, ColorScheme scheme) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'login_title'.tr,
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 34,
              height: 1.05,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.12),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'login_subtitle'.tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ).animate().fadeIn(delay: 420.ms, duration: 500.ms),
        ],
      );

  /// The form, lifted into a soft glass card.
  Widget _card(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
    bool isDark,
  ) =>
      Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainerHigh.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isDark
                ? scheme.outlineVariant.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: isDark ? 0.0 : 0.06),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(
                theme,
                label: 'login_field'.tr,
                child: TextFormField(
                  controller: controller.loginCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'login_field_hint'.tr,
                    prefixIcon: const Icon(IconsaxPlusLinear.call, size: 20),
                  ),
                  validator: Validators.loginField,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _field(
                theme,
                label: 'password'.tr,
                child: Obx(
                  () => TextFormField(
                    controller: controller.passwordCtrl,
                    obscureText: controller.obscure.value,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => controller.submit(),
                    decoration: InputDecoration(
                      hintText: 'password_hint'.tr,
                      prefixIcon: const Icon(IconsaxPlusLinear.lock, size: 20),
                      suffixIcon: IconButton(
                        onPressed: controller.toggleObscure,
                        icon: Icon(
                          controller.obscure.value
                              ? IconsaxPlusLinear.eye_slash
                              : IconsaxPlusLinear.eye,
                          size: 20,
                        ),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: controller.showHelp,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'forgot_password'.tr,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => FilledButton(
                  onPressed:
                      controller.isLoading.value ? null : controller.submit,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('sign_in'.tr),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(IconsaxPlusLinear.arrow_right_3, size: 20),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 480.ms, duration: 550.ms).slideY(begin: 0.08);

  /// A labeled form field — small bold label above its input.
  Widget _field(ThemeData theme, {required String label, required Widget child}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          child,
        ],
      );

  // ---- Bits --------------------------------------------------------------

  /// A soft radial brand glow (an "aurora" blob).
  Widget _glow(Color color, double size, double opacity) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      );

  /// Segmented EN / ខ្មែរ toggle (matches the Welcome screen).
  Widget _langToggle(BuildContext context, SettingsService settings) {
    final theme = Theme.of(context);
    return Obx(() {
      final isKm = settings.isKhmer;
      Widget seg(String label, bool active, VoidCallback onTap) => GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: active ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg('EN', !isKm, () => settings.setLocale(AppTranslations.englishLocale)),
            seg('ខ្មែរ', isKm, () => settings.setLocale(AppTranslations.khmerLocale)),
          ],
        ),
      );
    });
  }
}
