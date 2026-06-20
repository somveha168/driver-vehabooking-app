/// Static keys and small constants used across the app.
class AppConstants {
  const AppConstants._();

  // Secure storage keys (sensitive).
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  // GetStorage keys (non-sensitive).
  static const String localeKey = 'locale';
  static const String themeModeKey = 'theme_mode';

  // A stable per-install device name sent with login/logout.
  static const String deviceNameKey = 'device_name';

  // First-run welcome/onboarding seen flag.
  static const String onboardingSeenKey = 'onboarding_seen';

  // Default list page size (backend honours `limit`).
  static const int pageSize = 20;
}
