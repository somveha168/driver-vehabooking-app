import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

String pickupIssueReasonLabel(String? key) => switch (key) {
  'passenger_no_show' => 'reason_passenger_no_show'.tr,
  'cant_reach_passenger' => 'reason_cant_reach_passenger'.tr,
  'passenger_cancelled_at_pickup' => 'reason_passenger_cancelled_at_pickup'.tr,
  'passenger_refused_ride' => 'reason_passenger_refused_ride'.tr,
  'wrong_passenger_or_booking' => 'reason_wrong_passenger_or_booking'.tr,
  'vehicle_or_driver_rejected' => 'reason_vehicle_or_driver_rejected'.tr,
  'capacity_or_luggage_issue' => 'reason_capacity_or_luggage_issue'.tr,
  _ => key ?? 'report_pickup_issue_title'.tr,
};

Future<void> showPickupIssueSheet({
  required BuildContext context,
  required Future<void> Function(String reason, String? note) onSubmit,
  List<String> reasonOptions = const [],
  int noteMaxLength = 500,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickupIssueSheet(
      onSubmit: onSubmit,
      reasonOptions: reasonOptions,
      noteMaxLength: noteMaxLength,
    ),
  );
}

class _PickupIssueSheet extends StatefulWidget {
  const _PickupIssueSheet({
    required this.onSubmit,
    required this.reasonOptions,
    required this.noteMaxLength,
  });

  final Future<void> Function(String reason, String? note) onSubmit;
  final List<String> reasonOptions;
  final int noteMaxLength;

  @override
  State<_PickupIssueSheet> createState() => _PickupIssueSheetState();
}

class _PickupIssueSheetState extends State<_PickupIssueSheet> {
  final _noteController = TextEditingController();
  String? _reason;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  List<String> _reasonOptions() {
    if (widget.reasonOptions.isNotEmpty) {
      return widget.reasonOptions;
    }

    return [
      'reason_passenger_no_show'.tr,
      'reason_cant_reach_passenger'.tr,
      'reason_passenger_cancelled_at_pickup'.tr,
      'reason_passenger_refused_ride'.tr,
      'reason_wrong_passenger_or_booking'.tr,
      'reason_vehicle_or_driver_rejected'.tr,
      'reason_capacity_or_luggage_issue'.tr,
    ];
  }

  void _selectReason(String reason) {
    final previousReason = _reason;
    final current = _noteController.text;
    final currentTrimmed = current.trim();
    final knownReasonSelected = _reasonOptions().contains(currentTrimmed);

    setState(() => _reason = reason);

    var nextText = reason;
    if (currentTrimmed.isEmpty || knownReasonSelected) {
      nextText = reason;
    } else if (previousReason != null && current.startsWith(previousReason)) {
      nextText = reason + current.substring(previousReason.length);
    } else {
      nextText = "\n";
    }

    if (nextText.length > widget.noteMaxLength) {
      nextText = nextText.substring(0, widget.noteMaxLength);
    }

    _noteController.text = nextText;
    _noteController.selection = TextSelection.collapsed(
      offset: _noteController.text.length,
    );
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null) return;

    Navigator.of(context).pop();
    await widget.onSubmit(reason, _noteController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 24),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outline.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        IconsaxPlusLinear.profile_delete,
                        color: AppColors.primary,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'report_pickup_issue_title'.tr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'report_pickup_issue_hint'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final reason in _reasonOptions())
                  _ReasonTile(
                    label: pickupIssueReasonLabel(reason),
                    selected: _reason == reason,
                    onTap: () => _selectReason(reason),
                  ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: widget.noteMaxLength,
                  decoration: InputDecoration(
                    hintText: 'add_note_optional'.tr,
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.38),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _reason == null ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text('submit_report'.tr),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.30)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? IconsaxPlusBold.tick_circle
                      : IconsaxPlusLinear.record,
                  color: selected
                      ? AppColors.primary
                      : theme.colorScheme.outline,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
