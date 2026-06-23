import 'environment.dart';

/// Central, no-secrets application configuration resolved from [Environment].
///
/// API roots are derived from [baseUrl]:
///   - auth     → `{baseUrl}/api/driver/v1`   (Driver module)
///   - bookings → `{baseUrl}/api/taxi/v1/driver` (Taxi module)
class AppConfig {
  const AppConfig._();

  static const String appName = 'Veha Driver';

  /// Backend host per environment.
  static String get baseUrl {
    switch (Environment.current) {
      case Environment.dev:
        return 'http://vehabooking.test';
      case Environment.staging:
        return 'https://staging.vehabooking.com'; // TODO: confirm staging host
      case Environment.prod:
        return 'https://vehabooking.com'; // TODO: confirm prod host
    }
  }

  /// Driver-identity API root (login, profile, devices).
  static String get authApiUrl => '$baseUrl/api/driver/v1';

  /// Driver-facing bookings API root (Taxi module).
  static String get bookingsApiUrl => '$baseUrl/api/taxi/v1/driver';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// How often the bookings list silently refreshes while on screen.
  static const Duration bookingsPollInterval = Duration(seconds: 45);

  // Driver support channels (shown on the Guide tab).
  static const String supportPhone =
      '+85500000000'; // TODO: real dispatch hotline
  static const String supportTelegramUrl =
      'https://t.me/vehabooking'; // TODO: real support handle
}
