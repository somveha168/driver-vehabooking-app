import 'package:flutter_test/flutter_test.dart';
import 'package:veha_driver_app/app/core/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConfig', () {
    setUpAll(() async {
      await AppConfig.load();
    });

    test('reads APP_URL from the bundled .env', () {
      expect(AppConfig.baseUrl, isNotEmpty);
      expect(AppConfig.baseUrl, startsWith('http'));
    });

    test('baseUrl carries no trailing slash', () {
      expect(AppConfig.baseUrl.endsWith('/'), isFalse);
    });

    test('baseUrl is a host only — it must not embed an /api prefix', () {
      expect(Uri.parse(AppConfig.baseUrl).path, anyOf('', '/'));
    });

    test('API roots hang off baseUrl with single slashes', () {
      final base = AppConfig.baseUrl;
      expect(AppConfig.authApiUrl, '$base/api/driver/v1');
      expect(AppConfig.bookingsApiUrl, '$base/api/taxi/v1/driver');
      expect(AppConfig.guideApiUrl, '$base/api/driver/v1/guideline');
      expect(AppConfig.platformInfoApiUrl, '$base/api/v1/platform/info');
      expect(AppConfig.authApiUrl, isNot(contains('//api')));
    });

    test('rewrites Herd media URLs to the configured API host', () {
      const path = '/storage/uploads/avatar.jpg';
      final resolved = Uri.parse(
        AppConfig.resolveBackendAssetUrl('http://vehabooking.test$path'),
      );
      final configured = Uri.parse(AppConfig.baseUrl);

      expect(resolved.scheme, configured.scheme);
      expect(resolved.host, configured.host);
      expect(resolved.hasPort, configured.hasPort);
      if (configured.hasPort) expect(resolved.port, configured.port);
      expect(resolved.path, path);
    });

    test('preserves external media URLs', () {
      const url = 'https://cdn.example.com/drivers/avatar.jpg';

      expect(AppConfig.resolveBackendAssetUrl(url), url);
    });
  });
}
