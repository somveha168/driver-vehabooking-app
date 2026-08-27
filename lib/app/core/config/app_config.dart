import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  const AppConfig._();

  static const String appName = 'Veha Driver';

  static const String envFileName = '.env';

  static Future<void> load() async {
    await dotenv.load(fileName: envFileName);
    if (_rawBaseUrl.isEmpty) {
      throw StateError(
        'APP_URL is missing or empty in $envFileName. '
        'Set it to the backend host, e.g. https://staging.app.vehabooking.com',
      );
    }
  }

  static String get _rawBaseUrl => dotenv.env['APP_URL']?.trim() ?? '';

  static String get baseUrl {
    var url = _rawBaseUrl;
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String get authApiUrl => '$baseUrl/api/driver/v1';

  static String get bookingsApiUrl => '$baseUrl/api/taxi/v1/driver';

  static String get guideApiUrl => '$baseUrl/api/driver/v1/guideline';

  static String get platformInfoApiUrl => '$baseUrl/api/v1/platform/info';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  static const Duration bookingsPollInterval = Duration(seconds: 45);
}
