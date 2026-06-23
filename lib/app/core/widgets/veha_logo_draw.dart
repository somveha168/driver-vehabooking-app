import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../theme/app_colors.dart';
import 'veha_logo_paths.dart';

/// The Veha mark that "draws itself": the cloud + road outlines stroke on, then
/// fill with brand color. A one-shot intro animation for the Welcome screen.
class VehaLogoDraw extends StatefulWidget {
  const VehaLogoDraw({
    super.key,
    this.height = 120,
    this.duration = const Duration(milliseconds: 2100),
  });

  final double height;
  final Duration duration;

  @override
  State<VehaLogoDraw> createState() => _VehaLogoDrawState();
}

class _VehaLogoDrawState extends State<VehaLogoDraw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..forward();

  late final Path _cloud = parseSvgPathData(VehaLogoPaths.cloud);
  late final Path _road = parseSvgPathData(VehaLogoPaths.road);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aspect = VehaLogoPaths.viewW / VehaLogoPaths.viewH;
    return SizedBox(
      width: widget.height * aspect,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) =>
            CustomPaint(painter: _LogoPainter(_c.value, _cloud, _road)),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.t, this.cloud, this.road);

  final double t;
  final Path cloud;
  final Path road;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / VehaLogoPaths.viewW;
    canvas.save();
    canvas.scale(scale);

    // Cloud leads slightly; road follows.
    _draw(canvas, cloud, AppColors.primary, lead: 0.0);
    _draw(canvas, road, AppColors.secondary, lead: 0.18);

    canvas.restore();
  }

  /// Stroke the outline progressively (0 → ~0.7), then fade the fill in.
  void _draw(Canvas canvas, Path path, Color color, {required double lead}) {
    final local = ((t - lead) / (1 - lead)).clamp(0.0, 1.0);
    final drawT = (local / 0.7).clamp(0.0, 1.0);
    final fillT = ((local - 0.6) / 0.4).clamp(0.0, 1.0);

    if (drawT > 0 && fillT < 1) {
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * drawT), stroke);
      }
    }

    if (fillT > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: fillT),
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.t != t;
}
