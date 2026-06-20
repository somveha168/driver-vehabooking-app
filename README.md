# Veha Driver App

Flutter app for transport drivers on the Veha Booking platform. A driver logs
in (phone **or** email), sees the Private/Airport bookings the **vendor assigned**
to them, navigates to the pickup, and advances each trip through the lifecycle:

**Start Now → Arrived → Meet Passenger → Drop Passenger** — with a
**"Can't find the passenger?"** escape hatch (couldn't-meet-passenger) at the
on-the-way / at-pickup stages. No "accept" step — the vendor pre-assigns.

> **Docs:** the backend **[DRIVER_OVERVIEW.md](../../Herd/vehabooking/modules/Taxi/docs/DRIVER_OVERVIEW.md)**
> is the master index + audit log for the whole driver feature; **DRIVER_APP_API.md**
> is the endpoint/field contract. This README is the **app-side** master — keep its
> [Audit Log](#audit-log) current. Design plan: [docs/ACTIVE_TRIP_REDESIGN.md](docs/ACTIVE_TRIP_REDESIGN.md).

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
      widgets/              # StatusChip, SwipeToConfirm, InfoRow, TripTimeline, state views
    data/
      models/               # AuthUser, BookingListItem, BookingDetail, DashboardSummary, Place
      repositories/         # AuthRepository, BookingRepository
      services/             # AuthService (session), SettingsService (locale/theme)
    modules/                # feature = controller + binding + view
      splash/ welcome/ auth/ home/ dashboard/ bookings/ booking_detail/ profile/
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

## Current features (app surface)

- **Home** — editorial hero, compact **status pill** (reflects `DriverStatusEnum`,
  read-only), **NOW** card (one trip: stage chip + mini progress + inline action),
  **UPCOMING** list, overview counts. Per-section modern **empty templates**.
- **Bookings** — pill segmented tabs (Assigned/Active/Completed) + live count
  badges + Today/Tomorrow/Later day grouping; stage-aware cards.
- **Active Trip** (booking detail) — vertical `TripTimeline` + bottom action dock
  (tap stages, swipe to drop) + **"Can't find the passenger?"** reason sheet.
- **Profile** — cover + avatar upload, inline-editable fields, documents view.
- Polling refresh (no FCM yet); EN + KM throughout.

## Audit Log

> App-side changelog. Newest first. Add a row on every shipped app change. The
> backend half is tracked in `DRIVER_OVERVIEW.md`; keep both honest.

| Date | Change | Files | Status |
|---|---|---|---|
| 2026-06-20 | **Fix: splash stuck** — `SplashView` never reads `controller`, so `lazyPut` never created it → navigation timer never fired. Switched to eager `Get.put` + scheduled nav in `onInit` | `splash_binding.dart`, `splash_controller.dart` | ✅ |
| 2026-06-20 | **Welcome → clean brand-only** — removed hero photo; soft teal/navy aurora glows on canvas, centered logo, gradient "Veha Driver" title, animated Start Now. (Replaced the photo hero) | `welcome_view.dart` | ✅ analyze + tests |
| 2026-06-20 | **Splash loading screen** — every launch: native splash now plain white → in-app `SplashView` plays the self-drawing logo (~1.5s) → routes to Welcome/Home/Login. Logo-draw widget moved to `core/widgets`; Welcome now uses a static logo (no double draw) | `modules/splash/*`, `core/widgets/veha_logo_{draw,paths}.dart`, `main.dart`, `app_pages.dart`, `app_routes.dart`, `welcome_view.dart`, `pubspec.yaml` | ✅ analyze + tests; **reinstall for native white splash** |
| 2026-06-20 | **Self-drawing logo** — logo strokes-on then fills (SVG paths via `path_drawing` + custom painter); splash image sizing fixed | `core/widgets/veha_logo_*`, `tool/generate_icons.dart` | ✅ |
| 2026-06-20 | **Welcome / onboarding** — first-run animated screen (logo + driving animation + EN/KM toggle + Start Now → Login); `seen_onboarding` flag gates it | `modules/welcome/*`, `main.dart`, `app_pages.dart`, `app_routes.dart`, `storage_service.dart`, `app_constants.dart`, i18n | ✅ analyze + tests |
| 2026-06-20 | **Branding** — real Veha logo as app icon + native splash (white + colored lockup, Android 12 + night + iOS). Icon re-centered: square/trimmed sources via `tool/generate_icons.dart` (icon.png 76%, icon_foreground.png 56%) so the mark sits centered in the round/adaptive mask | `pubspec.yaml`, `assets/branding/*`, `tool/generate_icons.dart`, generated android/ios res | ✅ generated + analyze + tests. **Needs full reinstall to see** |
| 2026-06-20 | README brought current; app-side audit log added | `README.md` | ✅ |
| 2026-06-20 | Home: per-section empty templates (NOW status-aware, UPCOMING) | `dashboard_view.dart` (`_EmptyCard`), i18n | ✅ analyze+tests |
| 2026-06-20 | Home redesign: header status pill (tinted), NOW card, UPCOMING list; dropped online toggle + accept alert | `dashboard_view.dart`, `dashboard_controller.dart`, `dashboard_summary.dart` | ✅ analyze+tests |
| 2026-06-20 | Status reflects `DriverStatusEnum` (read-only), `is_online` retired in UI | `dashboard_*`, i18n | ✅ |
| 2026-06-20 | "Couldn't meet passenger" — secondary link + reason bottom sheet + terminal display | `booking_detail_view.dart`, `booking_detail_controller.dart`, `booking_repository.dart`, `booking_detail.dart`, i18n | ✅ analyze+tests |
| 2026-06-20 | Bookings modernized: pill tabs + count badges + day grouping | `bookings_view.dart`, `bookings_controller.dart` | ✅ analyze+tests |
| 2026-06-20 | Active-Trip screen: `TripTimeline` + action dock; list-card progress + next-action hint; consistent stage wording | `booking_detail_view.dart`, `trip_timeline.dart`, `booking_card.dart`, i18n | ✅ analyze+tests |

### Keeping docs current (rule)
1. Shipped an app change? **Add an Audit Log row** above (date, change, files, status).
2. Endpoint/field changed? It's a **backend** contract — update `DRIVER_APP_API.md` too.
3. Big flow/feature? Note it in **Current features** and the backend `DRIVER_OVERVIEW.md`.
