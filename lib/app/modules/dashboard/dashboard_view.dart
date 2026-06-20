import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/booking_list_item.dart';
import 'dashboard_controller.dart';

/// Soft, editorial card surface used across the home page — crisp white on the
/// tinted canvas with a soft layered shadow (no grey border).
BoxDecoration _softCard(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? theme.colorScheme.surfaceContainerHigh : Colors.white,
    borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 2),
    border: isDark
        ? Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))
        : null,
    boxShadow: [
      BoxShadow(
        color: AppColors.secondary.withValues(alpha: isDark ? 0.0 : 0.04),
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: AppColors.secondary.withValues(alpha: isDark ? 0.0 : 0.09),
        blurRadius: 26,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? scheme.surface : AppColors.canvas;

    return Scaffold(
      backgroundColor: canvas,
      body: Obx(() {
        if (controller.isLoading.value && controller.summary.value == null) {
          return const LoadingView();
        }
        if (controller.error.value != null && controller.summary.value == null) {
          return ErrorView(message: controller.error.value!, onRetry: controller.load);
        }
        final upcoming = controller.summary.value?.upcoming ?? const [];

        return Container(
          // Brand wash: a soft primary radial glow from the top-right corner
          // diffusing across the whole page over the cream canvas.
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
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.navClearance),
                children: [
                  _Hero(controller: controller),
                  const SizedBox(height: AppSpacing.xl),
                  // NOW — the one trip to act on, or its own empty template.
                  SectionLabel('section_now'.tr),
                  const SizedBox(height: AppSpacing.lg),
                  _nextPickup(context),
                  const SizedBox(height: AppSpacing.xxl),
                  // UPCOMING — the queue, or its own empty template.
                  SectionLabel('section_upcoming'.tr),
                  const SizedBox(height: AppSpacing.lg),
                  if (upcoming.isNotEmpty)
                    ...[
                      for (final b in upcoming) ...[
                        _UpcomingItem(booking: b, controller: controller),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ]
                  else
                    _emptyUpcoming(),
                  const SizedBox(height: AppSpacing.xxl),
                  SectionLabel('overview'.tr),
                  const SizedBox(height: AppSpacing.lg),
                  _stats(),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _nextPickup(BuildContext context) {
    final next = controller.summary.value?.nextPickup;
    if (next == null) {
      return _emptyNow()
          .animate()
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.04);
    }
    return _NextPickupCard(next: next, controller: controller)
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05);
  }

  /// NOW empty — status-aware (reflects why there's no active trip).
  Widget _emptyNow() {
    final (Color color, IconData icon, String title, String hint) =
        switch (controller.status.value) {
      'day_off' => (
          AppColors.notMet,
          IconsaxPlusBold.coffee,
          'empty_dayoff_title'.tr,
          'empty_dayoff_hint'.tr,
        ),
      'pending_verification' => (
          AppColors.assigned,
          IconsaxPlusBold.clock,
          'empty_pending_title'.tr,
          'empty_pending_hint'.tr,
        ),
      _ => (
          AppColors.primary,
          IconsaxPlusBold.car,
          'empty_ready_title'.tr,
          'empty_ready_hint'.tr,
        ),
    };
    return _EmptyCard(color: color, icon: icon, title: title, hint: hint);
  }

  /// UPCOMING empty — the schedule queue is clear.
  Widget _emptyUpcoming() => _EmptyCard(
        color: AppColors.primary,
        icon: IconsaxPlusBold.calendar,
        title: 'empty_upcoming_title'.tr,
        hint: 'empty_upcoming_hint'.tr,
      );

  Widget _stats() {
    final counts = controller.summary.value?.counts;
    final items = [
      ('assigned', counts?.assigned ?? 0, 'tab_assigned'),
      ('active', counts?.active ?? 0, 'tab_active'),
      ('completed', counts?.completed ?? 0, 'tab_completed'),
    ];
    return Row(
      children: items
          .map((e) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: _StatCard(
                    stage: e.$1,
                    count: e.$2,
                    label: e.$3.tr,
                    onTap: () => controller.goToBookings(e.$1),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// Editorial hero: date eyebrow, serif greeting with an accent stop, subtitle.
class _Hero extends StatelessWidget {
  const _Hero({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'good_morning'
        : (hour < 17 ? 'good_afternoon' : 'good_evening');
    final name = controller.user?.firstName ?? controller.user?.name ?? '';
    final dateLabel =
        DateFormat('EEEE, MMMM d').format(DateTime.now()).toUpperCase();

    final serif = GoogleFonts.fraunces(
      fontSize: 34,
      height: 1.02,
      letterSpacing: -0.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Date eyebrow with brand dot.
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            blurRadius: 0,
                            spreadRadius: 3),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      dateLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Compact operational-status pill.
            _StatusPill(controller: controller),
            const SizedBox(width: AppSpacing.sm),
            // Notification bell.
            InkWell(
              onTap: controller.openNotifications,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(IconsaxPlusLinear.notification,
                    size: 20, color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '${greeting.tr},',
          style: serif.copyWith(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        // Name in a teal→navy brand gradient (like the web "Veha."), with a
        // teal accent period.
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF4FC3A1), AppColors.primary]
                    : const [AppColors.primary, AppColors.secondary],
              ).createShader(bounds),
              child: Text(
                name,
                style: serif.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
            Text('.', style: serif.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.primary.withValues(alpha: 0.32),
              AppColors.primary.withValues(alpha: 0.04),
              Colors.transparent,
            ], stops: const [0.0, 0.4, 0.8]),
          ),
        ),
      ],
    );
  }
}

/// Compact operational-status pill (header): a colored dot + one short word.
/// Reflects the driver's real `status` (Available · On a trip · Day off ·
/// Pending) — not a presence toggle; the vendor pre-assigns trips.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final (Color color, String label) = switch (controller.status.value) {
        'available' => (AppColors.completed, 'status_available'.tr),
        'assign' || 'on_duty' => (AppColors.onTrip, 'status_on_trip'.tr),
        'day_off' => (theme.colorScheme.outline, 'status_day_off'.tr),
        'pending_verification' => (AppColors.assigned, 'status_pending'.tr),
        _ => (AppColors.completed, 'status_available'.tr),
      };

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    });
  }
}

/// Compact upcoming pickup row: time · name · pickup → detail.
class _UpcomingItem extends StatelessWidget {
  const _UpcomingItem({required this.booking, required this.controller});

  final BookingListItem booking;
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.openBooking(booking.uuid),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: _softCard(context),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            children: [
              Text(
                Formatters.time(booking.departureDatetime),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.customerName ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      booking.pickupLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(IconsaxPlusLinear.arrow_right_3,
                  size: 18, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextPickupCard extends StatelessWidget {
  const _NextPickupCard({required this.next, required this.controller});

  final BookingListItem next;
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final until = Formatters.timeUntil(next.departureDatetime);

    return Container(
      decoration: _softCard(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: InkWell(
        onTap: controller.openNextPickup,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(stage: next.stage),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                  child: Text(
                    until != null ? '${'departing_in'.tr} $until' : 'departing_now'.tr,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(next.customerName ?? '—',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            _line(theme, IconsaxPlusLinear.clock, Formatters.dateTime(next.departureDatetime)),
            const SizedBox(height: AppSpacing.xs),
            _line(theme, IconsaxPlusLinear.location, next.pickupLabel),
            if (next.stage != 'cancelled' && next.stage != 'not_met_passenger') ...[
              const SizedBox(height: AppSpacing.md),
              _miniProgress(theme, next.stage),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.navigateToNextPickup,
                    icon: const Icon(IconsaxPlusLinear.routing, size: 18),
                    label: Text('navigate'.tr),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Obx(() {
                    final action =
                        next.allowedActions.isNotEmpty ? next.allowedActions.first : null;
                    final label = switch (action) {
                      'start' => 'start_now'.tr,
                      'arrived' => 'mark_arrived'.tr,
                      'meet_passenger' => 'meet_passenger'.tr,
                      _ => 'booking_detail'.tr,
                    };
                    return FilledButton(
                      onPressed: controller.isActing.value
                          ? null
                          : controller.advanceNextPickup,
                      child: controller.isActing.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(label),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(ThemeData theme, IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
          Expanded(
              child: Text(text,
                  style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
        ],
      );

  /// 4-segment stage progress: Start → Arrived → Pickup → Drop-off.
  Widget _miniProgress(ThemeData theme, String stage) {
    final reached = switch (stage) {
      'start' => 1,
      'arrived_location' => 2,
      'meet_passenger' => 3,
      'drop_passenger' || 'completed' => 4,
      _ => 0,
    };
    return Row(
      children: List.generate(4, (i) {
        final done = i < reached;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
            decoration: BoxDecoration(
              color: done ? AppColors.primary : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

/// Compact, modern empty template — a brand-haloed icon + title + hint. Used by
/// both the NOW and UPCOMING sections so each has its own purposeful empty state.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      decoration: _softCard(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Concentric brand halo behind the icon.
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.stage,
    required this.count,
    required this.label,
    required this.onTap,
  });

  final String stage;
  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AppColors.forStage(stage);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: 4),
        decoration: _softCard(context),
        child: Column(
          children: [
            Text('$count',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}
