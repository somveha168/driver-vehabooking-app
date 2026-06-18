import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Editorial section header: an upper-cased, letter-spaced label followed by a
/// thin fading rule. Mirrors the "SERVICES / OVERVIEW" style of the web app.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.6,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.onSurface.withValues(alpha: 0.14),
                  scheme.onSurface.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
