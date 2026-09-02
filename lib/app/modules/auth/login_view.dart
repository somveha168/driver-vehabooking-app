import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/i18n/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../data/services/settings_service.dart';
import 'login_controller.dart';

/// A quiet, focused driver sign-in screen.
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? scheme.surface : AppColors.canvas;
    final settings = Get.find<SettingsService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.applyRouteArguments();
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: canvas,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final topGap = (constraints.maxHeight * 0.075).clamp(32.0, 58.0);

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 400,
                      minHeight: constraints.maxHeight - 36,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _langToggle(
                              context,
                              settings,
                            ).animate().fadeIn(duration: 350.ms),
                          ),
                          SizedBox(height: topGap),
                          _brand(scheme),
                          const SizedBox(height: 20),
                          _headline(theme, scheme),
                          const SizedBox(height: 30),
                          _form(theme),
                          const SizedBox(height: 20),
                          _help(theme, scheme),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---- Sections ----------------------------------------------------------

  /// The symbol is enough here; the driver already knows which app is open.
  Widget _brand(ColorScheme scheme) =>
      Center(
            child: Container(
              width: 76,
              height: 66,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/branding/app_icon.png',
                fit: BoxFit.contain,
                semanticLabel: 'Veha',
              ),
            ),
          )
          .animate()
          .fadeIn(duration: 450.ms)
          .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutCubic);

  /// One clear message, without competing brand typography.
  Widget _headline(ThemeData theme, ColorScheme scheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        'login_title'.tr,
        textAlign: TextAlign.center,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontSize: 28,
          height: 1.15,
          letterSpacing: -0.5,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.12),
      const SizedBox(height: 6),
      Text(
        'login_subtitle'.tr,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.4,
        ),
      ).animate().fadeIn(delay: 420.ms, duration: 500.ms),
    ],
  );

  /// Inputs carry the structure, so the form does not need a heavy card.
  Widget _form(ThemeData theme) => Form(
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
            autofillHints: const [
              AutofillHints.username,
              AutofillHints.email,
              AutofillHints.telephoneNumber,
            ],
            decoration: InputDecoration(
              hintText: 'login_field_hint'.tr,
              prefixIcon: const Icon(IconsaxPlusLinear.call, size: 20),
            ),
            validator: Validators.loginField,
          ),
        ),
        const SizedBox(height: 18),
        _field(
          theme,
          label: 'password'.tr,
          child: Obx(
            () => TextFormField(
              controller: controller.passwordCtrl,
              focusNode: controller.passwordFocusNode,
              obscureText: controller.obscure.value,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
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
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: controller.forgotPassword,
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
        const SizedBox(height: 16),
        Obx(() {
          final enabled =
              !controller.isLoading.value && controller.canSignIn.value;

          return FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              disabledBackgroundColor: AppColors.primary.withValues(
                alpha: 0.34,
              ),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.82),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
            onPressed: enabled ? controller.submit : null,
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('sign_in'.tr),
                      const SizedBox(width: 8),
                      const Icon(IconsaxPlusLinear.arrow_right_3, size: 18),
                    ],
                  ),
          );
        }),
      ],
    ),
  ).animate().fadeIn(delay: 360.ms, duration: 500.ms).slideY(begin: 0.06);

  /// A labeled form field — compact label above a bright, quiet input.
  Widget _field(
    ThemeData theme, {
    required String label,
    required Widget child,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    final fieldColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.white;
    final quietBorder = isDark
        ? theme.colorScheme.outlineVariant.withValues(alpha: 0.55)
        : const Color(0xFFDDE6E8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 7),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
            ),
          ),
        ),
        Theme(
          data: theme.copyWith(
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: fieldColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.66,
                ),
                letterSpacing: 0,
              ),
              prefixIconColor: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.76,
              ),
              suffixIconColor: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.76,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: quietBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: quietBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.colorScheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 1.5,
                ),
              ),
            ),
          ),
          child: child,
        ),
      ],
    );
  }

  /// Account provisioning is secondary information, but remains easy to find.
  Widget _help(ThemeData theme, ColorScheme scheme) => Center(
    child: TextButton(
      onPressed: controller.showHelp,
      style: TextButton.styleFrom(
        foregroundColor: scheme.onSurfaceVariant,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      ),
      child: Text(
        'login_help'.tr,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
        ),
      ),
    ),
  ).animate().fadeIn(delay: 500.ms, duration: 450.ms);

  // ---- Bits --------------------------------------------------------------

  /// Segmented EN / ខ្មែរ toggle (matches the Welcome screen).
  Widget _langToggle(BuildContext context, SettingsService settings) {
    final theme = Theme.of(context);
    return Obx(() {
      final isKm = settings.isKhmer;
      Widget seg(String label, bool active, VoidCallback onTap) =>
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: active
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            seg(
              'EN',
              !isKm,
              () => settings.setLocale(AppTranslations.englishLocale),
            ),
            seg(
              'ខ្មែរ',
              isKm,
              () => settings.setLocale(AppTranslations.khmerLocale),
            ),
          ],
        ),
      );
    });
  }
}
