import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../theme/app_spacing.dart';

/// Slide-to-confirm control used for the final "complete trip" action — a
/// deliberate gesture that's hard to trigger by accident.
class SwipeToConfirm extends StatefulWidget {
  const SwipeToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.loading = false,
  });

  final String label;
  final Future<void> Function() onConfirmed;
  final bool loading;

  @override
  State<SwipeToConfirm> createState() => _SwipeToConfirmState();
}

class _SwipeToConfirmState extends State<SwipeToConfirm> {
  static const double _thumb = 56;
  double _dx = 0;
  double _maxDx = 0;

  double get _progress => _maxDx <= 0 ? 0.0 : (_dx / _maxDx).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDx = constraints.maxWidth - _thumb;
        final progress = _progress;

        return Container(
          height: _thumb,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - progress).clamp(0.3, 1.0),
                child: Text(
                  widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onHorizontalDragUpdate: widget.loading
                        ? null
                        : (d) => setState(
                              () => _dx = (_dx + d.delta.dx).clamp(0.0, _maxDx),
                            ),
                    onHorizontalDragEnd: widget.loading ? null : (_) => _onDragEnd(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      transform: Matrix4.translationValues(_dx, 0, 0),
                      width: _thumb - 4,
                      height: _thumb - 4,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: widget.loading
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(IconsaxPlusLinear.arrow_right_3, color: scheme.onPrimary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onDragEnd() async {
    if (_progress >= 0.85) {
      setState(() => _dx = _maxDx);
      await widget.onConfirmed();
      if (mounted) setState(() => _dx = 0); // reset for retry/next state
    } else {
      setState(() => _dx = 0);
    }
  }
}
