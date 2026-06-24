import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:get/get.dart';

import '../../core/theme/app_spacing.dart';
import 'guide_controller.dart';

class GuideView extends GetView<GuideController> {
  const GuideView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('guide_title'.tr)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.navClearance,
        ),
        children: [
          Obx(() {
            if (controller.loadingVideos.value && controller.videos.isEmpty) {
              return const _VideoLoadingCard();
            }

            if (controller.videoError.value != null &&
                controller.videos.isEmpty) {
              return _VideoStateCard(
                icon: Icons.video_library_outlined,
                title: 'guide_videos_error'.tr,
                actionLabel: 'retry'.tr,
                onAction: controller.loadVideos,
              );
            }

            if (controller.videos.isEmpty) {
              return _VideoStateCard(
                icon: Icons.video_library_outlined,
                title: 'guide_videos_empty'.tr,
                actionLabel: 'refresh'.tr,
                onAction: controller.loadVideos,
              );
            }

            return Column(
              children: controller.videos
                  .map(
                    (video) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _VideoCard(
                        title: video.title,
                        description: _plainText(video.description),
                        canOpen: video.url?.isNotEmpty == true,
                        onTap: () => controller.openVideo(video),
                      ),
                    ),
                  )
                  .toList(),
            );
          }),
          const SizedBox(height: AppSpacing.xl),
          _PlatformSupportSection(controller: controller),
        ],
      ),
    );
  }
}

class _PlatformSupportSection extends StatelessWidget {
  const _PlatformSupportSection({required this.controller});

  final GuideController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final info = controller.platformInfo.value;

      if (controller.loadingPlatformInfo.value && info == null) {
        return const _SupportLoadingCard();
      }

      if (info == null || !info.hasContact) {
        return const SizedBox.shrink();
      }

      final socialLinks = <_SocialLinkData>[
        if (info.telegramUrl != null)
          _SocialLinkData(
            icon: IconsaxPlusLinear.send_2,
            label: 'guide_telegram_support'.tr,
            accent: const Color(0xFF2AA8E0),
            onTap: () => controller.openUrl(info.telegramUrl),
          ),
        if (info.facebookUrl != null)
          _SocialLinkData(
            icon: Icons.public,
            label: 'guide_facebook'.tr,
            accent: const Color(0xFF1877F2),
            onTap: () => controller.openUrl(info.facebookUrl),
          ),
        if (info.youtubeUrl != null)
          _SocialLinkData(
            icon: Icons.play_circle_outline,
            label: 'guide_youtube'.tr,
            accent: const Color(0xFFE53935),
            onTap: () => controller.openUrl(info.youtubeUrl),
          ),
        if (info.tiktokUrl != null)
          _SocialLinkData(
            icon: Icons.music_note_outlined,
            label: 'guide_tiktok'.tr,
            accent: const Color(0xFF111827),
            onTap: () => controller.openUrl(info.tiktokUrl),
          ),
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('guide_support'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          IconsaxPlusLinear.headphone,
                          color: theme.colorScheme.primary,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.name?.isNotEmpty == true
                                  ? info.name!
                                  : 'guide_support'.tr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'guide_platform_help'.tr,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (info.phone != null)
                    _ContactLine(
                      icon: IconsaxPlusLinear.call,
                      label: 'phone'.tr,
                      value: info.phone!,
                      onTap: () => controller.callPhone(info.phone),
                    ),
                  if (info.phone != null && info.email != null)
                    const SizedBox(height: AppSpacing.sm),
                  if (info.email != null)
                    _ContactLine(
                      icon: Icons.email_outlined,
                      label: 'email'.tr,
                      value: info.email!,
                      onTap: () => controller.email(info.email),
                    ),
                  if (info.address != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _AddressPanel(address: info.address!),
                  ],
                  if (socialLinks.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SocialLinkGrid(items: socialLinks),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 11,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
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

class _AddressPanel extends StatelessWidget {
  const _AddressPanel({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.location_on_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'guide_office_address'.tr,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  address,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
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

class _SocialLinkData {
  const _SocialLinkData({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
}

class _SocialLinkGrid extends StatelessWidget {
  const _SocialLinkGrid({required this.items});

  final List<_SocialLinkData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  height: 50,
                  child: _SocialLinkTile(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SocialLinkTile extends StatelessWidget {
  const _SocialLinkTile({required this.data});

  final _SocialLinkData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: data.accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(data.icon, size: 16, color: data.accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              Icon(
                IconsaxPlusLinear.arrow_right_3,
                size: 15,
                color: data.accent.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportLoadingCard extends StatelessWidget {
  const _SupportLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('guide_support_loading'.tr, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

String? _plainText(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final text = value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text.isEmpty ? null : text;
}

class _VideoCard extends StatefulWidget {
  const _VideoCard({
    required this.title,
    required this.onTap,
    required this.canOpen,
    this.description,
  });

  final String title;
  final String? description;
  final bool canOpen;
  final VoidCallback onTap;

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _expanded = false;

  bool get _canReadMore => (widget.description?.length ?? 0) > 140;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final readToggleLabel = _expanded
        ? 'guide_show_less'.tr
        : 'guide_read_more'.tr;

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.32),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: widget.canOpen ? widget.onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.canOpen
                      ? Icons.play_arrow_rounded
                      : IconsaxPlusLinear.document_text,
                  color: theme.colorScheme.primary,
                  size: widget.canOpen ? 28 : 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (widget.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.description!,
                        maxLines: _expanded ? null : 3,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (_canReadMore) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleExpanded,
                        child: Text(
                          readToggleLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    if (widget.canOpen) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            IconsaxPlusLinear.export_3,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'guide_open_video'.tr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!widget.canOpen && widget.description == null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'guide_text_only'.tr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.canOpen) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  IconsaxPlusLinear.arrow_right_3,
                  color: theme.colorScheme.outline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoLoadingCard extends StatelessWidget {
  const _VideoLoadingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('guide_videos_loading'.tr, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _VideoStateCard extends StatelessWidget {
  const _VideoStateCard({
    required this.icon,
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.outline),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
