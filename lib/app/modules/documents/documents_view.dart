import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/external_launcher.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/driver_document.dart';
import 'documents_controller.dart';

class DocumentsView extends GetView<DocumentsController> {
  const DocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('documents'.tr)),
      body: Obx(() {
        if (controller.isLoading.value) return const LoadingView();
        if (controller.error.value != null) {
          return ErrorView(
            message: controller.error.value!,
            onRetry: controller.load,
          );
        }
        if (controller.docs.isEmpty) {
          return EmptyView(
            title: 'no_documents'.tr,
            icon: IconsaxPlusLinear.document_text,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Row(
                children: [
                  Icon(
                    IconsaxPlusLinear.lock_1,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'documents_note'.tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              ...controller.docs.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _DocumentCard(doc: d),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc});

  final DriverDocument doc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: softCardDecoration(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  doc.isLicense
                      ? IconsaxPlusLinear.driving
                      : IconsaxPlusLinear.personalcard,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  doc.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusBadge(status: doc.status, label: doc.statusLabel),
            ],
          ),
          if (doc.cardNumber != null && doc.cardNumber!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _row(theme, 'card_number'.tr, doc.cardNumber!),
          ],
          if (doc.issuedAt != null) _row(theme, 'issued'.tr, doc.issuedAt!),
          if (doc.expiredAt != null) _row(theme, 'expires'.tr, doc.expiredAt!),
          if (doc.rejectionReason != null &&
              doc.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              doc.rejectionReason!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (doc.files.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: doc.files.map((f) => _FileTile(file: f)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Image files show a tappable thumbnail (opens a full-screen viewer);
/// other files open externally.
class _FileTile extends StatelessWidget {
  const _FileTile({required this.file});

  final DocFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (file.isImage) {
      return GestureDetector(
        onTap: () => _openImage(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Image.network(
            file.url,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(theme),
            loadingBuilder: (c, child, p) =>
                p == null ? child : _fallback(theme, loading: true),
          ),
        ),
      );
    }
    return ActionChip(
      avatar: const Icon(IconsaxPlusLinear.document_text, size: 16),
      label: Text('view_file'.tr),
      onPressed: () => ExternalLauncher.openUrl(file.url),
    );
  }

  Widget _fallback(ThemeData theme, {bool loading = false}) => Container(
    width: 92,
    height: 92,
    color: theme.colorScheme.surfaceContainerHighest,
    child: Center(
      child: loading
          ? const CircularProgressIndicator(strokeWidth: 2)
          : Icon(
              IconsaxPlusLinear.gallery_slash,
              color: theme.colorScheme.outline,
            ),
    ),
  );

  void _openImage(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        child: Stack(
          children: [
            InteractiveViewer(child: Center(child: Image.network(file.url))),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(
                  IconsaxPlusLinear.close_circle,
                  color: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.label});

  final String? status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => AppColors.completed,
      'pending' => AppColors.assigned,
      'rejected' => AppColors.cancelled,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Text(
        label ?? status ?? '—',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
