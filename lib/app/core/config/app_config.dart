import 'environment.dart';

/// Central, no-secrets application configuration resolved from [Environment].
///
/// API roots are derived from [baseUrl]:
///   - auth     → `{baseUrl}/api/driver/v1`   (Driver module)
///   - bookings → `{baseUrl}/api/taxi/v1/driver` (Taxi module)
class AppConfig {
  const AppConfig._();

  static const String appName = 'Veha Booking Driver';

  /// Backend host per environment.
  static String get baseUrl {
    switch (Environment.current) {
      case Environment.dev:
        return 'http://vehabooking.test';
      case Environment.staging:
        return 'https://staging.app.vehabooking.com';
      case Environment.prod:
        return 'https://app.vehabooking.com';
    }
  }

  /// Driver-identity API root (login, profile, devices).
  static String get authApiUrl => '$baseUrl/api/driver/v1';

  /// Driver-facing bookings API root (Taxi module).
  static String get bookingsApiUrl => '$baseUrl/api/taxi/v1/driver';

  /// Driver guide/help content API root (Blog module).
  static String get guideApiUrl => '$baseUrl/api/driver/v1/guideline';

  /// Public platform information API root (Core).
  static String get platformInfoApiUrl => '$baseUrl/api/v1/platform/info';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// How often the bookings list silently refreshes while on screen.
  static const Duration bookingsPollInterval = Duration(seconds: 45);
}
