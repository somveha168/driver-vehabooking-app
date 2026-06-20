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
        final assigned = controller.summary.value?.counts.assigned ?? 0;

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
                  _OnlineCard(controller: controller),
                  if (assigned > 0) ...[
                    const SizedBox(height: AppSpacing.md),
                    _AcceptAlert(count: assigned, controller: controller),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _nextPickup(context),
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
    final theme = Theme.of(context);
    if (next == null) {
      return Container(
        decoration: _softCard(context),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(IconsaxPlusLinear.calendar_tick,
                size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.sm),
            Text('no_next_pickup'.tr, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text('no_next_pickup_hint'.tr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      );
    }
    return _NextPickupCard(next: next, controller: controller)
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05);
  }

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
            Expanded(
              child: Row(
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
            // Notification bell.
            InkWell(
              onTap: controller.openNotifications,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.06),
                        blurRadius: 8),
                  ],
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
        const SizedBox(height: AppSpacing.md),
        Text(
          'home_subtitle'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.45,
          ),
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

/// Clean white availability card with a status dot.
class _OnlineCard extends StatelessWidget {
  const _OnlineCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final online = controller.isOnline.value;
      final dot = online ? AppColors.completed : theme.colorScheme.outline;
      return Container(
        decoration: _softCard(context),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(
              color: dot, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dot.withValues(alpha: 0.4), blurRadius: 6)],
            )),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(online ? 'you_are_online'.tr : 'you_are_offline'.tr,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  Text(online ? 'ready_for_trips'.tr : 'offline_hint'.tr,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
            if (controller.isToggling.value)
              const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              Switch(value: online, onChanged: controller.toggleOnline),
          ],
        ),
      );
    });
  }
}

class _AcceptAlert extends StatelessWidget {
  const _AcceptAlert({required this.count, required this.controller});

  final int count;
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppColors.assigned.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => controller.goToBookings('assigned'),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(IconsaxPlusLinear.notification_bing, color: AppColors.assigned),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text('$count ${'awaiting_acceptance'.tr}',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              const Icon(IconsaxPlusLinear.arrow_right_3, color: AppColors.assigned),
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
                Text('next_pickup'.tr.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2)),
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
