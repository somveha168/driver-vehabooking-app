// Normalizes the final Veha Driver icon artwork and derives Android adaptive
// foreground assets from the same source.
//
//   dart run tool/generate_icons.dart
//
// Produces:
//   assets/branding/icon.png            — full 1024px icon for iOS/legacy/web
//   assets/branding/icon_foreground.png — transparent Android adaptive fg
//   assets/branding/splash.png          — native splash bridge asset
import 'dart:io';

import 'package:image/image.dart' as img;

const _driverIconSource = 'assets/branding/driver_icon_source.png';
const _splashLogoSource = 'assets/branding/splash_logo.png';
const _size = 1024;

void main() {
  final source = img.decodePng(File(_driverIconSource).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not read $_driverIconSource');
    exit(1);
  }

  final icon = img.copyResizeCropSquare(
    _flatten(source, background: img.ColorRgb8(0, 177, 157)),
    size: _size,
    interpolation: img.Interpolation.cubic,
  );

  File('assets/branding/icon.png').writeAsBytesSync(img.encodePng(icon));
  File(
    'assets/branding/icon_foreground.png',
  ).writeAsBytesSync(img.encodePng(_adaptiveForeground(icon)));

  _generateSplash();

  stdout.writeln('✓ Generated icon.png, icon_foreground.png, splash.png');
}

img.Image _flatten(img.Image source, {required img.Color background}) {
  final canvas = img.Image(width: source.width, height: source.height);
  img.fill(canvas, color: background);
  img.compositeImage(canvas, source);

  return canvas;
}

img.Image _adaptiveForeground(img.Image icon) {
  final background = icon.getPixel(0, 0);
  final foreground = img.Image(width: _size, height: _size, numChannels: 4);
  img.fill(foreground, color: img.ColorRgba8(0, 0, 0, 0));

  for (final pixel in icon) {
    final distance = _colorDistance(pixel, background);
    if (distance < 36) {
      continue;
    }

    final alpha = distance < 120 ? ((distance - 36) / 84 * 255).round() : 255;
    foreground.setPixelRgba(
      pixel.x,
      pixel.y,
      255,
      255,
      255,
      alpha.clamp(0, 255),
    );
  }

  return foreground;
}

int _colorDistance(img.Pixel a, img.Pixel b) {
  final dr = (a.r - b.r).abs();
  final dg = (a.g - b.g).abs();
  final db = (a.b - b.b).abs();

  return (dr + dg + db).round();
}

void _generateSplash() {
  final lockup = img.decodePng(File(_splashLogoSource).readAsBytesSync());
  if (lockup == null) {
    return;
  }

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
