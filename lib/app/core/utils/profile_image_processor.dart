import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../config/app_constants.dart';

class ProfileImageProcessingException implements Exception {
  const ProfileImageProcessingException();
}

/// Produces a correctly oriented, size-bounded JPEG in the picker cache.
/// Heavy decode/resize/encode work runs outside the UI isolate.
Future<File> prepareProfileImage(String sourcePath) async {
  final source = File(sourcePath);
  if (!await source.exists()) {
    throw const ProfileImageProcessingException();
  }

  final sourceBytes = await source.readAsBytes();
  final outputBytes = await compute(compressProfileImageBytes, sourceBytes);
  if (outputBytes.length > AppConstants.avatarMaxUploadBytes) {
    throw const ProfileImageProcessingException();
  }

  final output = File(
    '${source.parent.path}/veha_profile_'
    '${DateTime.now().microsecondsSinceEpoch}.jpg',
  );
  await output.writeAsBytes(outputBytes, flush: true);
  return output;
}

/// Public for deterministic unit testing; app callers should use
/// [prepareProfileImage] so processing happens on a background isolate.
Uint8List compressProfileImageBytes(Uint8List sourceBytes) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(sourceBytes);
  } catch (_) {
    throw const ProfileImageProcessingException();
  }
  if (decoded == null) {
    throw const ProfileImageProcessingException();
  }

  var image = img.bakeOrientation(decoded);
  image = _resizeToLimit(image, AppConstants.avatarMaxDimension);

  var smallest = Uint8List(0);
  for (final quality in const [82, 74, 66, 58, 50, 42]) {
    final encoded = img.encodeJpg(
      image,
      quality: quality,
      chroma: img.JpegChroma.yuv420,
    );
    smallest = encoded;
    if (encoded.length <= AppConstants.avatarTargetBytes) {
      return encoded;
    }
  }

  // Highly detailed images can remain large after lowering JPEG quality.
  // Reduce dimensions gradually, while keeping a useful avatar resolution.
  while (smallest.length > AppConstants.avatarMaxUploadBytes &&
      (image.width > 640 || image.height > 640)) {
    image = _resizeToLimit(
      image,
      (image.width > image.height ? image.width : image.height) * 4 ~/ 5,
    );
    smallest = img.encodeJpg(image, quality: 50, chroma: img.JpegChroma.yuv420);
  }

  if (smallest.length > AppConstants.avatarMaxUploadBytes) {
    throw const ProfileImageProcessingException();
  }
  return smallest;
}

img.Image _resizeToLimit(img.Image source, int maxDimension) {
  if (source.width <= maxDimension && source.height <= maxDimension) {
    return source;
  }

  return source.width >= source.height
      ? img.copyResize(
          source,
          width: maxDimension,
          interpolation: img.Interpolation.average,
        )
      : img.copyResize(
          source,
          height: maxDimension,
          interpolation: img.Interpolation.average,
        );
}
