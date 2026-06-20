import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/i18n/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'welcome_controller.dart';

/// First-run welcome — clean, brand-only: soft teal/navy aurora glows on the
/// canvas, the logo, a gradient headline, and an animated Start Now → Login.
class WelcomeView extends GetView<WelcomeController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? scheme.surface : AppColors.canvas;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: canvas,
        body: Stack(
          children: [
            // Brand aurora — two soft glows for depth, no image.
            Positioned(
              top: -110,
              right: -90,
              child: _glow(AppColors.primary, 360, isDark ? 0.22 : 0.30),
            ),
            Positioned(
              bottom: -140,
              left: -110,
              child: _glow(AppColors.secondary, 320, isDark ? 0.20 : 0.16),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _langToggle(context).animate().fadeIn(duration: 400.ms),
                    ),
                    const Spacer(flex: 3),

                    // Logo mark.
                    Image.asset('assets/branding/app_icon.png', height: 132)
                        .animate()
                        .fadeIn(duration: 550.ms)
                        .scale(begin: const Offset(0.88, 0.88), curve: Curves.easeOutBack),
                    const SizedBox(height: AppSpacing.xxxl),

                    // Eyebrow.
                    Text(
                      'welcome_eyebrow'.tr.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: AppColors.primary,
                      ),
                    ).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                    const SizedBox(height: AppSpacing.sm),

                    // Gradient title (teal → navy).
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: isDark
                            ? const [Color(0xFF4FC3A1), AppColors.primary]
                            : const [AppColors.primary, AppColors.secondary],
                      ).createShader(bounds),
                      child: Text(
                        'app_name'.tr,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fraunces(
                          fontSize: 46,
                          height: 1.0,
                          letterSpacing: -0.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().fadeIn(delay: 420.ms, duration: 550.ms).slideY(begin: 0.14),
                    const SizedBox(height: AppSpacing.md),

                    // Subtitle.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Text(
                        'welcome_subtitle'.tr,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 560.ms, duration: 550.ms),

                    const Spacer(flex: 3),

                    // CTA → Login. Forward arrow nudges + a periodic shimmer.
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: controller.start,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('welcome_cta'.tr),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(IconsaxPlusLinear.arrow_right_3, size: 20)
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .moveX(begin: -2, end: 5, duration: 650.ms, curve: Curves.easeInOut),
                          ],
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(period: 3600.ms))
                        .shimmer(
                          delay: 1800.ms,
                          duration: 1100.ms,
                          color: Colors.white.withValues(alpha: 0.35),
                        )
                        .animate()
                        .fadeIn(delay: 700.ms, duration: 500.ms)
                        .slideY(begin: 0.3),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A soft radial brand glow (an "aurora" blob).
  Widget _glow(Color color, double size, double opacity) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0.0)],
            ),
          ),
        ),
      );

  Widget _langToggle(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final isKm = controller.settings.isKhmer;
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
            seg('EN', !isKm, () => controller.setLanguage(AppTranslations.englishLocale)),
            seg('ខ្មែរ', isKm, () => controller.setLanguage(AppTranslations.khmerLocale)),
          ],
        ),
      );
    });
  }
}
