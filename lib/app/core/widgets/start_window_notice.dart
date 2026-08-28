import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_spacing.dart';
import '../utils/formatters.dart';

/// Start is the driver's next step, but departure is still too far away.
///
/// Shown instead of hiding the control entirely: the trip *is* theirs, and the
/// driver needs to know that plus when it opens - an empty footer just looks
/// broken.
class StartWindowNotice extends StatelessWidget {
  const StartWindowNotice({super.key, required this.startAvailableAtIso});

  final String? startAvailableAtIso;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        // Deliberately disabled rather than absent.
        onPressed: null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.onSurfaceVariant,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        icon: const Icon(IconsaxPlusLinear.clock, size: 19),
        label: Text(
          'starts_at'.trParams({'time': Formatters.time(startAvailableAtIso)}),
        ),
      ),
    );
  }
}
