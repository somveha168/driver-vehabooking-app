import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/driver_notification.dart';
import 'notifications_controller.dart';

class NotificationsView extends GetView<NotificationsController> {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canvas = isDark ? theme.colorScheme.surface : AppColors.canvas;

    return Scaffold(
      backgroundColor: canvas,
      body: RefreshIndicator(
        onRefresh: controller.refreshList,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.extentAfter < 220) {
              controller.loadMore();
            }
            return false;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.navClearance,
            ),
            children: const [
              _Header(),
              SizedBox(height: AppSpacing.lg),
              _FilterTabs(),
              SizedBox(height: AppSpacing.xl),
              _NotificationsBody(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends GetView<NotificationsController> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconButton(
                icon: IconsaxPlusLinear.arrow_left_2,
                onTap: Get.back,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'notifications_title'.tr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              Obx(
                () => _MarkAllReadButton(
                  enabled:
                      controller.unreadCount > 0 &&
                      !controller.isMarkingAll.value,
                  loading: controller.isMarkingAll.value,
                  onTap: controller.markAllAsRead,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.76),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.06),
          ),
        ),
        child: Icon(icon, color: AppColors.secondary, size: 19),
      ),
    );
  }
}

class _MarkAllReadButton extends StatelessWidget {
  const _MarkAllReadButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled
        ? AppColors.primary
        : AppColors.secondary.withValues(alpha: 0.28);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(IconsaxPlusLinear.tick_circle, size: 15, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'mark_all_read'.tr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends GetView<NotificationsController> {
  const _FilterTabs();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withValues(alpha: 0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            _FilterTab(
              label: 'all_notifications'.tr,
              selected: controller.filter.value == null,
              onTap: () => controller.setFilter(null),
            ),
            _FilterTab(
              label: 'unread'.tr,
              selected: controller.filter.value == 'unread',
              onTap: () => controller.setFilter('unread'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? AppColors.secondary
                  : AppColors.secondary.withValues(alpha: 0.62),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationsBody extends GetView<NotificationsController> {
  const _NotificationsBody();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.error.value != null) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.48,
          child: ErrorView(
            message: controller.error.value!,
            onRetry: controller.load,
          ),
        );
      }

      if (controller.isLoading.value) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.42,
          child: const Center(child: CircularProgressIndicator()),
        );
      }

      if (controller.notifications.isEmpty) {
        return SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.48,
          child: const _EmptyNotifications(),
        );
      }

      return Column(
        children: [
          ...controller.notifications.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _NotificationTile(item: item),
            ),
          ),
          if (controller.isLoadingMore.value) ...[
            const SizedBox(height: AppSpacing.md),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      );
    });
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxxl,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                IconsaxPlusLinear.notification_bing,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'notifications_empty_title'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'notifications_empty_message'.tr,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.secondary.withValues(alpha: 0.54),
                height: 1.42,
                letterSpacing: 0,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends GetView<NotificationsController> {
  const _NotificationTile({required this.item});

  final DriverNotification item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !item.isRead;

    return InkWell(
      onTap: () => controller.open(item),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg + 2),
      child: Container(
        decoration: softCardDecoration(context).copyWith(
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.26)
                : AppColors.secondary.withValues(alpha: 0.05),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Icon(
                _iconForType(item.type),
                color: isUnread ? AppColors.primary : theme.colorScheme.outline,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.message.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                        height: 1.32,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (item.bookingCode != null)
                        _MetaPill(
                          icon: IconsaxPlusLinear.ticket,
                          label: item.bookingCode!,
                        ),
                      if (item.createdAtHuman != null)
                        _MetaPill(
                          icon: IconsaxPlusLinear.clock,
                          label: item.createdAtHuman!,
                        ),
                      if (item.canOpenTrip)
                        _MetaPill(
                          icon: IconsaxPlusLinear.arrow_right_3,
                          label: 'open_trip'.tr,
                          highlighted: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    if (type.contains('assigned')) return IconsaxPlusLinear.routing_2;
    if (type.contains('removed')) return IconsaxPlusLinear.close_circle;
    if (type.contains('updated')) return IconsaxPlusLinear.refresh;
    return IconsaxPlusLinear.notification;
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlighted ? AppColors.primary : theme.colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: highlighted ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
