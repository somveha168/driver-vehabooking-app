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

class _SwipeToConfirmState extends State<SwipeToConfirm>
    with SingleTickerProviderStateMixin {
  static const double _height = 60;
  static const double _thumbWidth = 88;
  static const double _thumbHeight = 48;
  static const double _trackInset = 6;
  double _dx = 0;
  double _maxDx = 0;
  late final AnimationController _hintController;
  late final Animation<double> _hintProgress;

  double get _progress => _maxDx <= 0 ? 0.0 : (_dx / _maxDx).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
    _hintProgress = CurvedAnimation(
      parent: _hintController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        _maxDx = constraints.maxWidth - _thumbWidth - (_trackInset * 2);
        final progress = _progress;
        final fillWidth = (_thumbWidth + (_maxDx * progress)).clamp(
          _thumbWidth,
          constraints.maxWidth - (_trackInset * 2),
        );
        final showComplete = progress >= 0.82;
        final showHint = !widget.loading && progress == 0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: _height,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.10 + progress * 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.12 + progress * 0.10),
                blurRadius: 18 + progress * 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: _trackInset,
                top: _trackInset,
                bottom: _trackInset,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: fillWidth,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.92),
                        scheme.primary.withValues(alpha: 0.62),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  ),
                ),
              ),
              Positioned(
                left: _trackInset + 10,
                child: AnimatedBuilder(
                  animation: _hintProgress,
                  builder: (context, child) {
                    final wave = showHint ? _hintProgress.value : 0.0;
                    return IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 140),
                        opacity: showHint ? (0.35 * (1 - wave)) : 0,
                        child: Transform.translate(
                          offset: Offset(10 + (wave * 42), 0),
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      _SwipePulseDot(color: scheme.onPrimary, size: 32),
                      const SizedBox(width: 2),
                      _SwipePulseDot(color: scheme.onPrimary, size: 24),
                      const SizedBox(width: 2),
                      _SwipePulseDot(color: scheme.onPrimary, size: 16),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 22,
                child: AnimatedBuilder(
                  animation: _hintProgress,
                  builder: (context, child) {
                    final wave = showHint ? _hintProgress.value : 0.0;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 140),
                      opacity: showHint
                          ? (0.18 + (wave * 0.42)).clamp(0.18, 0.60)
                          : 0,
                      child: Transform.translate(
                        offset: Offset(wave * 9, 0),
                        child: child,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: scheme.primary.withValues(alpha: 0.44),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: scheme.primary.withValues(alpha: 0.30),
                      ),
                    ],
                  ),
                ),
              ),
              Opacity(
                opacity: (1 - progress).clamp(0.22, 1.0),
                child: Text(
                  widget.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Color.lerp(
                      scheme.primary,
                      scheme.onPrimary,
                      progress,
                    ),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _trackInset),
                  child: GestureDetector(
                    onHorizontalDragUpdate: widget.loading
                        ? null
                        : (d) => setState(
                            () => _dx = (_dx + d.delta.dx).clamp(0.0, _maxDx),
                          ),
                    onHorizontalDragEnd: widget.loading
                        ? null
                        : (_) => _onDragEnd(),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      scale: 1 + (progress * 0.05),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        transform: Matrix4.translationValues(_dx, 0, 0),
                        width: _thumbWidth,
                        height: _thumbHeight,
                        decoration: BoxDecoration(
                          color: scheme.onPrimary,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXl,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(
                                alpha: 0.22 + progress * 0.18,
                              ),
                              blurRadius: 16 + progress * 10,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: widget.loading
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              )
                            : _SwipeThumbIcon(
                                animation: _hintProgress,
                                showComplete: showComplete,
                                showHint: showHint,
                                primary: scheme.primary,
                                onPrimary: scheme.onPrimary,
                              ),
                      ),
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

class _SwipeThumbIcon extends StatelessWidget {
  const _SwipeThumbIcon({
    required this.animation,
    required this.showComplete,
    required this.showHint,
    required this.primary,
    required this.onPrimary,
  });

  final Animation<double> animation;
  final bool showComplete;
  final bool showHint;
  final Color primary;
  final Color onPrimary;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 140),
      child: showComplete
          ? Icon(
              IconsaxPlusBold.tick_circle,
              key: const ValueKey('complete'),
              color: primary,
              size: 26,
            )
          : AnimatedBuilder(
              key: const ValueKey('hint-arrow'),
              animation: animation,
              builder: (context, child) {
                final wave = showHint ? animation.value : 0.0;
                return Transform.translate(
                  offset: Offset(wave * 1.5, 0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 5; i++)
                        Transform.translate(
                          offset: Offset(wave * (i * 0.8), 0),
                          child: _ThumbChevron(
                            color: primary,
                            opacity: _chevronOpacity(i, wave, showHint),
                            size: 11 + i.clamp(0, 2).toDouble(),
                          ),
                        ),
                      Transform.translate(
                        offset: Offset(wave * 4, 0),
                        child: Opacity(
                          opacity: _chevronOpacity(5, wave, showHint),
                          child: child,
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: Icon(
                IconsaxPlusLinear.arrow_right_3,
                color: primary,
                size: 18,
              ),
            ),
    );
  }

  double _chevronOpacity(int index, double wave, bool animated) {
    final base = 0.18 + (index * 0.10);
    if (!animated) {
      return base.clamp(0.18, 0.82);
    }

    final pulse = (wave - (index * 0.10)).clamp(0.0, 1.0);
    return (base + (pulse * 0.28)).clamp(0.18, 1.0);
  }
}

class _ThumbChevron extends StatelessWidget {
  const _ThumbChevron({
    required this.color,
    required this.opacity,
    required this.size,
  });

  final Color color;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Icon(Icons.chevron_right_rounded, color: color, size: size),
    );
  }
}

class _SwipePulseDot extends StatelessWidget {
  const _SwipePulseDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
    );
  }
}
