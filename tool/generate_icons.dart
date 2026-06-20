// Generates square, trimmed, centered icon sources from the Veha mark so the
// launcher icon sits properly inside the round/adaptive mask.
//
//   dart run tool/generate_icons.dart
//
// Produces:
//   assets/branding/icon.png            — iOS + Android legacy (mark ~76% of canvas)
//   assets/branding/icon_foreground.png — Android adaptive fg  (mark ~56%, safe zone)
import 'dart:io';

import 'package:image/image.dart' as img;

const _source = 'assets/branding/app_icon.png'; // the Veha cloud+road mark
const _size = 1024;

void main() {
  final src = img.decodePng(File(_source).readAsBytesSync());
  if (src == null) {
    stderr.writeln('Could not read $_source');
    exit(1);
  }

  // Trim the transparent margins so we center the actual mark, not the canvas.
  final mark = img.trim(src);

  _build('assets/branding/icon.png', mark, 0.76);
  _build('assets/branding/icon_foreground.png', mark, 0.56);

  // Native splash: the full colored lockup, sized small enough that the native
  // splash (which centers it at ~source/4 dp) shows it at a sensible width
  // instead of overflowing the screen.
  final lockup = img.decodePng(File('assets/branding/splash_logo.png').readAsBytesSync());
  if (lockup != null) {
    final trimmed = img.trim(lockup);
    const width = 1040;
    final resized = img.copyResize(
      trimmed,
      width: width,
      height: (trimmed.height * (width / trimmed.width)).round(),
      interpolation: img.Interpolation.cubic,
    );
    File('assets/branding/splash.png').writeAsBytesSync(img.encodePng(resized));
  }

  stdout.writeln('✓ Generated icon.png, icon_foreground.png, splash.png');
}

/// Center [mark] on a transparent [_size]² canvas, scaled so its longer side is
/// [fill] × the canvas.
void _build(String out, img.Image mark, double fill) {
  final target = (_size * fill).round();
  final scale = target / (mark.width > mark.height ? mark.width : mark.height);
  final resized = img.copyResize(
    mark,
    width: (mark.width * scale).round(),
    height: (mark.height * scale).round(),
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0)); // transparent
  img.compositeImage(
    canvas,
    resized,
    dstX: (_size - resized.width) ~/ 2,
    dstY: (_size - resized.height) ~/ 2,
  );

  File(out).writeAsBytesSync(img.encodePng(canvas));
}
