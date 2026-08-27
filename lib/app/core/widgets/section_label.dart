import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Section header used by the dashboard and profile lists.
///
/// Case and tracking are left untouched on purpose. `toUpperCase()` is a no-op
/// for Khmer, and positive `letterSpacing` pulls its stacked vowel/consonant
/// marks away from their base glyph - so both are avoided rather than applied
/// conditionally.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Brand navy reads well on the light canvas but disappears on a dark one,
    // so dark mode falls back to the scheme's own on-surface color.
    final titleColor = theme.brightness == Brightness.dark
        ? theme.colorScheme.onSurface
        : AppColors.secondary;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        height: 1.25,
        color: titleColor,
      ),
    );
  }
}
