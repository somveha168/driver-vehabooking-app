import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_spacing.dart';
import 'guide_controller.dart';

class GuideView extends GetView<GuideController> {
  const GuideView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('guide_title'.tr)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.navClearance),
        children: [
          Text('guide_how_it_works'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _Step(
            number: 1,
            color: theme.colorScheme.primary,
            title: 'guide_step_accept_title'.tr,
            desc: 'guide_step_accept_desc'.tr,
          ),
          _Step(
            number: 2,
            color: theme.colorScheme.primary,
            title: 'guide_step_pickup_title'.tr,
            desc: 'guide_step_pickup_desc'.tr,
          ),
          _Step(
            number: 3,
            color: theme.colorScheme.primary,
            title: 'guide_step_complete_title'.tr,
            desc: 'guide_step_complete_desc'.tr,
            isLast: true,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('guide_support'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(IconsaxPlusLinear.call),
                  title: Text('guide_call_dispatch'.tr),
                  subtitle: Text(AppConfig.supportPhone),
                  trailing: const Icon(IconsaxPlusLinear.arrow_right_3),
                  onTap: controller.callDispatch,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(IconsaxPlusLinear.send_2),
                  title: Text('guide_telegram_support'.tr),
                  trailing: const Icon(IconsaxPlusLinear.arrow_right_3),
                  onTap: controller.openTelegram,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: Text(
              '${'guide_app_version'.tr} ${AppConfig.appName} 1.0.0',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.color,
    required this.title,
    required this.desc,
    this.isLast = false,
  });

  final int number;
  final Color color;
  final String title;
  final String desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color,
                child: Text('$number',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: color.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
