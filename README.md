# Veha Driver App

Flutter app for transport drivers on the Veha Booking platform. A driver logs
in (phone **or** email), sees the Private/Airport bookings assigned to them,
views detail + navigates to the pickup, then **accepts → confirms pickup →
completes** the trip.

## Stack

- **Flutter 3.41 / Dart 3.11**, Material 3 (custom design system — no third-party UI kit)
- **GetX** for state management, DI, routing, i18n
- **Dio** for HTTP, `flutter_secure_storage` for the token, `url_launcher` for maps + calls
- Bilingual **English + Khmer**

## Architecture

```
lib/
  main.dart                 # bootstrap: services → GetMaterialApp
  app/
    core/
      config/               # Environment, AppConfig (base URLs), constants
      network/              # ApiClient (Dio) + ApiException
      storage/              # StorageService (secure token + prefs)
      theme/                # design tokens + M3 light/dark theme
      i18n/                 # AppTranslations + en/km
      routes/               # app_routes + app_pages
      utils/                # validators, formatters, snackbars, external launcher
      widgets/              # StatusChip, SwipeToConfirm, InfoRow, state views
    data/
      models/               # AuthUser, BookingListItem, BookingDetail, Place
      repositories/         # AuthRepository, BookingRepository
      services/             # AuthService (session), SettingsService (locale/theme)
    modules/                # feature = controller + binding + view
      auth/ home/ bookings/ booking_detail/ profile/
```

State: GetX controllers per feature; core services are permanent singletons
registered in `main()`. API calls live in repositories that return typed models;
every failure is normalized to an `ApiException` (`{message, statusCode, errorCode}`).

## Backend

Two API prefixes (see `modules/Taxi/docs/DRIVER_APP_API.md` in the backend repo):
- Identity: `{baseUrl}/api/driver/v1/auth/*`
- Bookings: `{baseUrl}/api/taxi/v1/driver/*`

## Running

The environment is selected at build time with `--dart-define=ENV`:

```bash
# Local dev (default) → http://vehabooking.test
flutter run --dart-define=ENV=dev

# Staging / prod (URLs are TODO in lib/app/core/config/app_config.dart)
flutter run --dart-define=ENV=staging
flutter run --dart-define=ENV=prod
```

### Local host resolution
The dev backend is `http://vehabooking.test` (Herd). The device/emulator must
resolve that host:

- **iOS Simulator** resolves the Mac's `/etc/hosts`, so `vehabooking.test` works directly.
- **Android emulator** cannot see `vehabooking.test`. Either map it to the host
  alias `10.0.2.2` (run the API on a port and point `AppConfig.baseUrl` at
  `http://10.0.2.2:<port>` for the `dev` case), or add a hosts entry.

Cleartext http is permitted **only** for the dev host (Android
`network_security_config.xml`, iOS ATS exception). Production traffic uses https.

## Tests

```bash
flutter analyze
flutter test
```
