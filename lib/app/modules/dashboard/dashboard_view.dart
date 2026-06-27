import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/pickup_issue_sheet.dart';
import '../../core/widgets/section_label.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/step_action_button.dart';
import '../../core/widgets/swipe_to_confirm.dart';
import '../../core/widgets/trip_steps.dart';
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
        ? Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          )
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
        if (controller.error.value != null &&
            controller.summary.value == null) {
          return ErrorView(
            message: controller.error.value!,
            onRetry: controller.load,
          );
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
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.navClearance,
                ),
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
                  if (upcoming.isNotEmpty) ...[
                    for (final b in upcoming) ...[
                      _UpcomingItem(booking: b, controller: controller),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ] else
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
      return _emptyNow().animate().fadeIn(duration: 300.ms).slideY(begin: 0.04);
    }
    return _NextPickupCard(
      next: next,
      controller: controller,
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }

  /// NOW empty — status-aware (reflects why there's no active trip).
  Widget _emptyNow() {
    final hasUpcoming =
        (controller.summary.value?.upcoming.isNotEmpty) ?? false;
    final (Color color, IconData icon, String title, String hint) = switch ((
      controller.status.value,
      controller.active.value,
      hasUpcoming,
    )) {
      ('pending', _, _) => (
        AppColors.assigned,
        IconsaxPlusBold.clock,
        'empty_pending_title'.tr,
        'empty_pending_hint'.tr,
      ),
      ('rejected', _, _) => (
        AppColors.pickupIssue,
        IconsaxPlusBold.shield_cross,
        'empty_rejected_title'.tr,
        'empty_rejected_hint'.tr,
      ),
      ('approved', false, _) => (
        themeColorInactive,
        IconsaxPlusBold.pause_circle,
        'empty_inactive_title'.tr,
        'empty_inactive_hint'.tr,
      ),
      ('approved', true, true) => (
        AppColors.assigned,
        IconsaxPlusBold.calendar_tick,
        'empty_assigned_title'.tr,
        'empty_assigned_hint'.tr,
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

  Color get themeColorInactive =>
      Get.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
          .map(
            (e) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _StatCard(
                  stage: e.$1,
                  count: e.$2,
                  label: e.$3.tr,
                  onTap: () => controller.goToBookings(e.$1),
                ),
              ),
            ),
          )
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
    final name = controller.user?.displayName ?? '';
    final dateLabel = DateFormat(
      'EEEE, MMMM d',
    ).format(DateTime.now()).toUpperCase();

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
                          spreadRadius: 3,
                        ),
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
            // Compact working-state pill.
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
                child: const Icon(
                  IconsaxPlusLinear.notification,
                  size: 20,
                  color: AppColors.primary,
                ),
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
                style: serif.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '.',
              style: serif.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.32),
                AppColors.primary.withValues(alpha: 0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 0.4, 0.8],
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact working-state pill (header): Active/Inactive for approved drivers,
/// with Pending/Rejected verification states taking priority.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final (Color color, String label) = switch (controller.status.value) {
        'pending' => (AppColors.assigned, 'status_pending'.tr),
        'rejected' => (AppColors.pickupIssue, 'status_rejected'.tr),
        'approved' when controller.active.value => (
          AppColors.completed,
          'status_active'.tr,
        ),
        'approved' => (theme.colorScheme.outline, 'status_inactive'.tr),
        _ => (AppColors.assigned, 'status_pending'.tr),
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
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
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

  /// Relative departure day: "Today" / "Tomorrow" / "21 Jun".
  String _dayLabel() {
    final diff = Formatters.daysFromToday(booking.displayDepartureDatetime);
    return switch (diff) {
      0 => 'section_today'.tr,
      1 => 'section_tomorrow'.tr,
      _ => Formatters.shortDate(booking.displayDepartureDatetime),
    };
  }

  String _legLabel() => booking.isReturnLeg
      ? '${'round_trip_badge'.tr} · ${'trip_leg_return'.tr}'
      : '${'round_trip_badge'.tr} · ${'trip_leg_outbound'.tr}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.openBooking(
          booking.uuid,
          assignmentId: booking.assignmentId,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Container(
          decoration: _softCard(context),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dayLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      Formatters.time(booking.displayDepartureDatetime),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
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
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (booking.isRoundTrip) ...[
                      const SizedBox(height: 2),
                      Text(
                        _legLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    Text(
                      booking.hasDropoff
                          ? '${booking.pickupLabel}  →  ${booking.dropoffLabel}'
                          : booking.pickupLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 18,
                color: theme.colorScheme.outline,
              ),
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
    final showProgress =
        next.stage != 'cancelled' && next.stage != 'pickup_issue';

    return Container(
      decoration: _softCard(context),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: controller.openNextPickup,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Contact header: passenger name + phone, with a call action.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next.customerName ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        _meta(theme),
                        if (next.isRoundTrip) ...[
                          const SizedBox(height: 3),
                          _legLine(theme),
                        ],
                        if (next.hasPhone) ...[
                          const SizedBox(height: 4),
                          _phone(theme),
                        ],
                      ],
                    ),
                  ),
                  if (next.hasPhone) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _callButton(),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _departure(theme),
              if (next.isStartOverdue) ...[
                const SizedBox(height: AppSpacing.sm),
                _startOverdueNotice(theme),
              ],
              const SizedBox(height: AppSpacing.sm + 2),

              // Origin → destination timeline.
              _stop(
                theme,
                isOrigin: true,
                caption: 'pickup'.tr,
                value: next.pickupLabel,
              ),
              if (next.hasDropoff)
                _stop(
                  theme,
                  isOrigin: false,
                  caption: 'dropoff'.tr,
                  value: next.dropoffLabel,
                ),
              if (next.hasDropoff) ...[
                const SizedBox(height: AppSpacing.sm),
                _mapButton(theme),
              ],

              if (showProgress) ...[
                const SizedBox(height: AppSpacing.md),
                TripSteps(stage: next.stage),
              ],
              if (next.isStartBlocked) ...[
                const SizedBox(height: AppSpacing.md),
                _blockingTripNotice(theme),
              ],
              if (next.nextAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _action(theme, next.nextAction!),
                if (_canReportPickupIssue) ...[
                  const SizedBox(height: 2),
                  _pickupIssueButton(context, theme),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _blockingTripNotice(ThemeData theme) {
    final blockedBy = next.startBlockedBy!;
    final title = 'finish_trip_first_title'.trParams({
      'code': blockedBy.code ?? 'this trip',
    });
    final subtitleParts = <String>[
      if (blockedBy.customerName != null && blockedBy.customerName!.isNotEmpty)
        blockedBy.customerName!,
      if (blockedBy.legDepartureDatetime != null &&
          blockedBy.legDepartureDatetime!.isNotEmpty)
        Formatters.dateTime(blockedBy.legDepartureDatetime!),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.assigned.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.assigned.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              IconsaxPlusLinear.lock_1,
              size: 17,
              color: AppColors.assigned,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitleParts.isNotEmpty)
                  Text(
                    subtitleParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          TextButton(
            onPressed: controller.openBlockingTrip,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.assigned,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            child: Text('open_trip'.tr),
          ),
        ],
      ),
    );
  }

  /// The advance control: an animated next-step button for start/arrived/meet,
  /// and a deliberate swipe for the irreversible final drop. Lives on the card
  /// so the driver advances the trip without leaving Home.
  Widget _action(ThemeData theme, String action) {
    if (action == 'start' && next.isStartTooOld) {
      return _staleStartAction(theme);
    }

    if (action == 'complete') {
      return Obx(
        () => SwipeToConfirm(
          label: 'swipe_to_drop'.tr,
          loading: controller.isActing.value,
          onConfirmed: () => controller.runNextAction('complete'),
        ),
      );
    }

    final (String label, IconData icon) = switch (action) {
      'start' => (
        next.isStartOverdue ? 'start_trip_now'.tr : 'start_now'.tr,
        IconsaxPlusLinear.play,
      ),
      'arrived' => ('mark_arrived'.tr, IconsaxPlusLinear.location_tick),
      'meet_passenger' => ('meet_passenger'.tr, IconsaxPlusLinear.profile_tick),
      _ => ('start_now'.tr, IconsaxPlusLinear.play),
    };

    return Obx(
      () => StepActionButton(
        label: label,
        icon: icon,
        loading: controller.isActing.value,
        onPressed: () => controller.runNextAction(action),
      ),
    );
  }

  bool get _canReportPickupIssue =>
      next.allowedActions.contains('report_pickup_issue');

  Widget _startOverdueNotice(ThemeData theme) {
    final isTooOld = next.isStartTooOld;
    final isVeryOverdue = next.isStartVeryOverdue;
    final color = isTooOld
        ? AppColors.cancelled
        : isVeryOverdue
        ? AppColors.assigned
        : AppColors.assigned;
    final key = isTooOld
        ? 'start_too_old_home'
        : isVeryOverdue
        ? 'start_very_overdue_home'
        : 'start_overdue_home';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            isTooOld
                ? IconsaxPlusLinear.info_circle
                : IconsaxPlusLinear.timer_1,
            size: 17,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              key.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _staleStartAction(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(IconsaxPlusLinear.headphone, size: 18),
        label: Text('contact_dispatch_to_start'.tr),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          disabledForegroundColor: AppColors.cancelled.withValues(alpha: 0.78),
          side: BorderSide(color: AppColors.cancelled.withValues(alpha: 0.22)),
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _pickupIssueButton(BuildContext context, ThemeData theme) {
    return Obx(
      () => TextButton.icon(
        onPressed: controller.isActing.value
            ? null
            : () => showPickupIssueSheet(
                context: context,
                onSubmit: (reason, note) =>
                    controller.reportPickupIssue(reason, note: note),
                reasonOptions: next.pickupIssueReasonOptions,
                noteMaxLength: next.pickupIssueNoteMaxLength,
              ),
        icon: const Icon(IconsaxPlusLinear.search_status, size: 17),
        label: Text('pickup_issue_link'.tr),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _mapButton(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: controller.openNextPickupMap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  IconsaxPlusLinear.map,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'view_pickup_route'.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legLine(ThemeData theme) {
    final linked = next.linkedLegDatetime;
    final linkedLabel = linked == null || linked.isEmpty
        ? null
        : (next.isReturnLeg
              ? '${'outbound_scheduled'.tr} ${Formatters.shortDate(linked)}'
              : '${'return_scheduled'.tr} ${Formatters.shortDate(linked)}');

    return Text(
      [
        'round_trip_badge'.tr,
        next.isReturnLeg ? 'trip_leg_return'.tr : 'trip_leg_outbound'.tr,
        ...?(linkedLabel == null ? null : [linkedLabel]),
      ].join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  /// Passenger phone, with a call glyph.
  Widget _phone(ThemeData theme) => Row(
    children: [
      Icon(IconsaxPlusLinear.call, size: 13, color: theme.colorScheme.outline),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          next.customerPhone!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  /// Round call button — dials the passenger straight from the card.
  Widget _callButton() => Material(
    color: AppColors.primary.withValues(alpha: 0.12),
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => controller.callCustomer(next.customerPhone!),
      child: const Padding(
        padding: EdgeInsets.all(9),
        child: Icon(IconsaxPlusBold.call, size: 18, color: AppColors.primary),
      ),
    ),
  );

  Widget _meta(ThemeData theme) {
    final outline = theme.colorScheme.outline;
    return Row(
      children: [
        if (next.serviceType != null)
          Text(
            next.serviceType!.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        if (next.serviceType != null && next.passengerCount != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(shape: BoxShape.circle, color: outline),
          ),
          const SizedBox(width: 8),
        ],
        if (next.passengerCount != null) ...[
          Icon(IconsaxPlusLinear.profile, size: 13, color: outline),
          const SizedBox(width: 4),
          Text(
            '${next.passengerCount}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: outline,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _departure(ThemeData theme) => Row(
    children: [
      Icon(
        IconsaxPlusLinear.calendar,
        size: 16,
        color: theme.colorScheme.outline,
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(
        Formatters.dateTime(next.displayDepartureDatetime),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    ],
  );

  /// One stop in the route timeline. Origin is a filled dot, destination a ring;
  /// a connector drops from the origin when there's a destination below.
  Widget _stop(
    ThemeData theme, {
    required bool isOrigin,
    required String caption,
    required String value,
  }) {
    final showConnector = isOrigin && next.hasDropoff;
    final marker = Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isOrigin ? AppColors.primary : Colors.white,
        border: Border.all(
          color: isOrigin
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.secondary,
          width: 3,
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Padding(padding: const EdgeInsets.only(top: 3), child: marker),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: AppColors.primary.withValues(alpha: 0.22),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: showConnector ? AppSpacing.sm : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      fontSize: 9.5,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    height: 1.35,
                  ),
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
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.lg,
          horizontal: 4,
        ),
        decoration: _softCard(context),
        child: Column(
          children: [
            Text(
              '$count',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
