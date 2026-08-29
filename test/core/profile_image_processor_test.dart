import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:veha_driver_app/app/core/config/app_constants.dart';
import 'package:veha_driver_app/app/core/utils/profile_image_processor.dart';

void main() {
  test('normalizes and bounds a profile photo before upload', () {
    final source = img.Image(width: 2200, height: 1400);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        source.setPixelRgb(x, y, x % 256, y % 256, (x + y) % 256);
      }
    }

    final result = compressProfileImageBytes(
      Uint8List.fromList(img.encodePng(source)),
    );
    final decoded = img.decodeJpg(result);

    expect(decoded, isNotNull);
    expect(decoded!.width, lessThanOrEqualTo(AppConstants.avatarMaxDimension));
    expect(decoded.height, lessThanOrEqualTo(AppConstants.avatarMaxDimension));
    expect(result.length, lessThanOrEqualTo(AppConstants.avatarMaxUploadBytes));
  });

  test('rejects data that is not a supported image', () {
    expect(
      () => compressProfileImageBytes(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(isA<ProfileImageProcessingException>()),
    );
  });
}
