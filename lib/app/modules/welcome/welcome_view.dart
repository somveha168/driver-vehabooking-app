import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:path_drawing/path_drawing.dart';

import '../../core/i18n/app_translations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'welcome_controller.dart';

/// First-run welcome — a fully vector hero: soft brand waves at the top, the
/// Veha lockup + serif headline, then a Cambodian skyline with a dashed travel
/// route between two pins, riding a flowing road into the CTA. No image assets
/// beyond the logo lockup, so it stays crisp at any size.
class WelcomeView extends GetView<WelcomeController> {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? scheme.surface : AppColors.canvas;
    final ink = isDark ? Colors.white : AppColors.secondary;
    final size = MediaQuery.sizeOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: canvas,
        body: Stack(
          children: [
            // Soft flowing brand waves sweeping from the top-left.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.34,
              child: CustomPaint(painter: _TopWavesPainter(isDark: isDark)),
            ),

            // Skyline + dashed route + flowing road filling the lower half.
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.52,
              child: CustomPaint(painter: _LandscapePainter(isDark: isDark))
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 900.ms),
            ),

            // Foreground content.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _langToggle(context).animate().fadeIn(duration: 400.ms),
                    ),
                    SizedBox(height: size.height * 0.04),

                    // Logo lockup (cloud + road over VEHA BOOKING).
                    Image.asset('assets/branding/welcome_lockup.png', height: 132)
                        .animate()
                        .fadeIn(duration: 550.ms)
                        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
                    const SizedBox(height: AppSpacing.xl),

                    // Serif headline.
                    Text(
                      'welcome_headline'.tr,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fraunces(
                        fontSize: 54,
                        height: 1.0,
                        letterSpacing: -0.5,
                        fontWeight: FontWeight.w600,
                        color: ink,
                      ),
                    ).animate().fadeIn(delay: 280.ms, duration: 550.ms).slideY(begin: 0.14),
                    const SizedBox(height: AppSpacing.md),

                    // Teal divider.
                    Container(
                      width: 54,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ).animate().fadeIn(delay: 420.ms).scaleX(begin: 0.2, curve: Curves.easeOut),
                    const SizedBox(height: AppSpacing.lg),

                    // Two-line tagline (muted ink + brand teal).
                    Text(
                      'welcome_tagline_1'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark ? scheme.onSurfaceVariant : AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 520.ms, duration: 500.ms),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'welcome_tagline_2'.tr,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

                    const Spacer(),

                    // Page dots (first active) — decorative pager hint.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final active = i == 0;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.primary
                                : AppColors.secondary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: AppSpacing.lg),

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
                        .fadeIn(delay: 760.ms, duration: 500.ms)
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

/// Soft, layered brand waves sweeping in from the top-left corner.
class _TopWavesPainter extends CustomPainter {
  _TopWavesPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const base = AppColors.primary;

    // A few parallel ribbons, each a touch fainter, fanning across the top.
    for (var i = 0; i < 5; i++) {
      final t = i / 5;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = base.withValues(alpha: (isDark ? 0.10 : 0.16) * (1 - t * 0.7));

      final dy = -h * 0.12 + i * h * 0.085;
      final path = Path()
        ..moveTo(-w * 0.1, dy + h * 0.18)
        ..quadraticBezierTo(w * 0.22, dy - h * 0.04, w * 0.6, dy + h * 0.16)
        ..quadraticBezierTo(w * 0.85, dy + h * 0.3, w * 1.1, dy + h * 0.12);
      canvas.drawPath(path, paint);
    }

    // A faint filled sweep for body behind the ribbons.
    final sweep = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          base.withValues(alpha: isDark ? 0.10 : 0.12),
          base.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final body = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.62, 0)
      ..quadraticBezierTo(w * 0.2, h * 0.22, 0, h * 0.5)
      ..close();
    canvas.drawPath(body, sweep);
  }

  @override
  bool shouldRepaint(covariant _TopWavesPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// The lower hero: a faint Khmer skyline on the horizon, a dashed travel route
/// between two map pins, all riding flowing road waves into the bottom edge.
class _LandscapePainter extends CustomPainter {
  _LandscapePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const teal = AppColors.primary;

    // Horizon where the skyline sits and the road begins to flow.
    final horizon = h * 0.52;

    _paintRoadWaves(canvas, w, h, horizon);
    _paintSkyline(canvas, w, horizon);
    _paintRoute(canvas, w, h);
    _paintRoad(canvas, w, h, horizon);

    // Subtle ground reflection wash.
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [teal.withValues(alpha: 0.0), teal.withValues(alpha: 0.05)],
      ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon));
    canvas.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), glow);
  }

  /// Layered soft teal wave fills, lightest at top, deepening toward the floor.
  void _paintRoadWaves(Canvas canvas, double w, double h, double horizon) {
    const teal = AppColors.primary;
    final layers = [
      (y: horizon + h * 0.02, alpha: 0.07, amp: h * 0.05),
      (y: horizon + h * 0.14, alpha: 0.10, amp: h * 0.06),
      (y: horizon + h * 0.28, alpha: 0.13, amp: h * 0.05),
    ];
    for (final l in layers) {
      final paint = Paint()..color = teal.withValues(alpha: l.alpha);
      final path = Path()..moveTo(0, l.y);
      path.cubicTo(
        w * 0.25, l.y - l.amp,
        w * 0.55, l.y + l.amp,
        w * 0.78, l.y - l.amp * 0.4,
      );
      path.quadraticBezierTo(w * 0.92, l.y - l.amp, w, l.y - l.amp * 0.2);
      path.lineTo(w, h);
      path.lineTo(0, h);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  /// A stylized Cambodian skyline: lotus-bud temple towers flanked by a couple
  /// of modern blocks, rendered as a faint teal silhouette on the horizon.
  void _paintSkyline(Canvas canvas, double w, double horizon) {
    const teal = AppColors.primary;
    final paint = Paint()..color = teal.withValues(alpha: isDark ? 0.16 : 0.20);

    // Flat city blocks behind, for depth.
    final blocks = Paint()..color = teal.withValues(alpha: isDark ? 0.10 : 0.13);
    void block(double cx, double bw, double bh) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - bw / 2, horizon - bh, bw, bh),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        blocks,
      );
    }

    block(w * 0.14, w * 0.06, w * 0.10);
    block(w * 0.24, w * 0.05, w * 0.07);
    block(w * 0.80, w * 0.06, w * 0.12);
    block(w * 0.90, w * 0.05, w * 0.08);

    // Temple gallery base.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.30, horizon - w * 0.05, w * 0.40, w * 0.05),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      ),
      paint,
    );

    // Five lotus-bud towers (tall center, descending to the sides).
    _tower(canvas, paint, w * 0.50, horizon, w * 0.085, w * 0.30); // center
    _tower(canvas, paint, w * 0.38, horizon, w * 0.065, w * 0.22);
    _tower(canvas, paint, w * 0.62, horizon, w * 0.065, w * 0.22);
    _tower(canvas, paint, w * 0.30, horizon, w * 0.05, w * 0.15);
    _tower(canvas, paint, w * 0.70, horizon, w * 0.05, w * 0.15);

    // A couple of palms for the tropical horizon.
    _palm(canvas, teal, w * 0.10, horizon, w * 0.05);
    _palm(canvas, teal, w * 0.88, horizon, w * 0.045);
  }

  /// One lotus-bud temple tower at [cx], rising [th] above [baseY].
  void _tower(Canvas canvas, Paint paint, double cx, double baseY, double tw, double th) {
    final path = Path()
      ..moveTo(cx - tw / 2, baseY)
      ..lineTo(cx - tw / 2, baseY - th * 0.42)
      ..lineTo(cx - tw * 0.32, baseY - th * 0.55)
      ..quadraticBezierTo(cx - tw * 0.30, baseY - th * 0.82, cx, baseY - th)
      ..quadraticBezierTo(cx + tw * 0.30, baseY - th * 0.82, cx + tw * 0.32, baseY - th * 0.55)
      ..lineTo(cx + tw / 2, baseY - th * 0.42)
      ..lineTo(cx + tw / 2, baseY)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// A simple palm: a thin trunk with a few fronds.
  void _palm(Canvas canvas, Color color, double x, double baseY, double ph) {
    final trunk = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: isDark ? 0.14 : 0.18);
    canvas.drawLine(Offset(x, baseY), Offset(x - ph * 0.1, baseY - ph), trunk);

    final frond = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: isDark ? 0.16 : 0.22);
    final top = Offset(x - ph * 0.1, baseY - ph);
    for (final a in [-2.4, -1.8, -1.2, -0.7]) {
      final dir = Offset(math.cos(a), math.sin(a));
      final end = top + dir * (ph * 0.5);
      final ctrl = top + dir * (ph * 0.3) + const Offset(0, -6);
      final p = Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
      canvas.drawPath(p, frond);
    }
  }

  /// Dashed travel route arcing from a low-left pin up to a high-right pin.
  void _paintRoute(Canvas canvas, double w, double h) {
    const teal = AppColors.primary;
    final start = Offset(w * 0.10, h * 0.46);
    final end = Offset(w * 0.84, h * 0.16);

    final route = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        w * 0.30, h * 0.58,
        w * 0.40, h * 0.18,
        w * 0.60, h * 0.26,
      )
      ..cubicTo(
        w * 0.72, h * 0.31,
        w * 0.74, h * 0.16,
        end.dx, end.dy,
      );

    final dashed = dashPath(
      route,
      dashArray: CircularIntervalList<double>(<double>[7, 6]),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = teal.withValues(alpha: 0.75);
    canvas.drawPath(dashed, paint);

    _pin(canvas, start, w * 0.05);
    _pin(canvas, end, w * 0.055);
  }

  /// A teardrop map pin whose point sits on [p].
  void _pin(Canvas canvas, Offset p, double s) {
    const teal = AppColors.primary;
    final fill = Paint()..color = teal;
    final cx = p.dx;
    final cy = p.dy - s; // circle center above the point
    final r = s * 0.62;

    final path = Path()
      ..moveTo(p.dx, p.dy)
      ..lineTo(cx - r * 0.78, cy + r * 0.5)
      ..arcToPoint(Offset(cx + r * 0.78, cy + r * 0.5),
          radius: Radius.circular(r), clockwise: true, largeArc: true)
      ..close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.3), 2, true);
    canvas.drawPath(path, fill);
    canvas.drawCircle(Offset(cx, cy), r * 0.42, Paint()..color = Colors.white);
  }

  /// A white road sweeping up from the bottom edge toward a vanishing point,
  /// with soft teal edges and a dashed center line — echoes the lockup's road.
  void _paintRoad(Canvas canvas, double w, double h, double horizon) {
    const teal = AppColors.primary;
    final vanish = Offset(w * 0.52, horizon + h * 0.06);

    final road = Path()
      ..moveTo(w * 0.18, h)
      ..quadraticBezierTo(w * 0.34, h * 0.78, vanish.dx - w * 0.05, vanish.dy)
      ..lineTo(vanish.dx + w * 0.05, vanish.dy)
      ..quadraticBezierTo(w * 0.74, h * 0.80, w * 0.88, h)
      ..close();

    canvas.drawPath(
      road,
      Paint()..color = Colors.white.withValues(alpha: isDark ? 0.10 : 0.85),
    );

    // Soft teal edge highlights.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = teal.withValues(alpha: 0.30);
    final left = Path()
      ..moveTo(w * 0.18, h)
      ..quadraticBezierTo(w * 0.34, h * 0.78, vanish.dx - w * 0.05, vanish.dy);
    final right = Path()
      ..moveTo(w * 0.88, h)
      ..quadraticBezierTo(w * 0.74, h * 0.80, vanish.dx + w * 0.05, vanish.dy);
    canvas.drawPath(left, edge);
    canvas.drawPath(right, edge);

    // Dashed center line.
    final center = Path()
      ..moveTo(w * 0.52, h)
      ..quadraticBezierTo(w * 0.53, h * 0.8, vanish.dx, vanish.dy);
    final dashed = dashPath(center, dashArray: CircularIntervalList<double>(<double>[10, 9]));
    canvas.drawPath(
      dashed,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = teal.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _LandscapePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
