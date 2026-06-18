# Veha Driver App — Implementation Plan (v1)

> Status: **DRAFT — awaiting approval.** No code is written until this plan is confirmed.
> Last updated: 2026-06-18

## 1. Goal (v1 scope, locked)

A Flutter mobile app for **transport drivers** that lets a driver:

1. **Log in** with **phone _or_ email + password**.
2. See the list of **transport bookings assigned to them** (by admin or vendor).
3. Open a booking to see **full detail** (customer, pickup, time, vehicle, route).
4. **Navigate** to the pickup point (opens external Google/Apple Maps).
5. **Accept** an assigned booking (confirm pickup).
6. **Swipe to complete** once the passenger has been picked up / dropped.

Out of scope for v1 (noted for v2): in-app embedded map, real-time push (FCM), chat, earnings/wallet, ratings UI, document upload.

### Decisions locked with the user
| Topic | Decision |
|---|---|
| Backend work | **I build both** backend API + Flutter app |
| Directions | **Launch external maps app** (`url_launcher`), no Maps SDK/billing |
| Notifications | **Pull-to-refresh + light polling** (FCM deferred to v2) |
| Languages | **English + Khmer** (bilingual from day one) |

---

## 2. Reality check — why this is a two-track project

The Flutter app **cannot function** until backend endpoints exist. Current backend state in `modules/Driver`:

- ✅ Sanctum auth, device/FCM registration, vehicle (`wheel`) + GPS update.
- ✅ Booking↔Driver link exists in **Taxi** module: `taxi_booking_assignments.driver_id`.
- ✅ Core Actions exist: `ConfirmDriverPickupAction`, `MarkBookingAsCompletedAction`.
- ❌ Login is **email-only**; needs phone support.
- ❌ `driver` guard referenced in code but **not declared** in `config/auth.php` (latent bug).
- ❌ **No driver-facing booking API** (no list/detail/accept/complete).

So: **Track A (Laravel) ships first**, Track B (Flutter) builds against it.

---

## 3. TRACK A — Backend API (`modules/Driver` + `modules/Taxi`)

> Follows CLAUDE.md rules: Form Requests, Actions over services, `response()->jsonSuccess()/jsonError()`, API Resources, never break existing code, Pest tests, run `vendor/bin/pint --dirty`.

### A1. Fix the `driver` auth guard
- Add a `driver` guard + provider to `config/auth.php` (provider → `Modules\Driver\Models\Driver`).
- Keep `auth:sanctum` on protected routes (token auth unchanged); the guard fix makes `Auth::guard('driver')->attempt()` actually work.
- **Non-breaking**: purely additive to the guards/providers arrays.

### A2. Phone **or** email login
- `AuthController::login` accepts a single **`login`** field (phone or email) + `password` + `device_name`.
- Detect email vs phone (e.g. `filter_var(..., FILTER_VALIDATE_EMAIL)` or `@` presence), resolve driver by the matching column, then verify password via the `driver` guard.
- **Backward compatible**: if a legacy caller still sends `email`, accept it as the `login` value (no break).
- Return shape unchanged: `{ token, user, user_type }`.

### A2b. Audit & tidy existing `modules/Driver/routes/api/v1.php`
> User confirmed: existing Driver routes **may be adjusted, removed, or updated** as needed (not append-only). Still follows CLAUDE.md — anything actively used elsewhere is preserved; I'll flag each removal before doing it.

Current dead/stub weight to resolve:
- `GET auth/user_type` → `userType()` **not implemented**. Decision: implement (return `getMorphClass`) **or** remove. Recommend remove for v1 (login already returns `user_type`).
- `POST auth/update_profile` → `updateProfile()` **not implemented**. Recommend implement (v1 Profile screen needs it) — name/phone/email update.
- `POST auth/deactivate` → `deactivate()` **not implemented**. Recommend remove for v1 (out of scope) or stub clearly.
- `GET notifications` → `NotificationController@index` **empty**. Recommend remove for v1 (we use polling, no notifications screen) — re-add in v2 with FCM.
- Keep & verify: `login`, `register`, `logout`, `user`, `verify-token`, `change-password`, `devices`, `wheel*`, `stations*`.

Outcome: a clean, honest route file where every route maps to a working method.

### A3. Driver booking endpoints (new) — **lives in `modules/Taxi`**
Per decision: the driver booking API belongs in the **Taxi module** (that's where bookings, assignments, and the Actions already live), mirroring the existing `vendor`/`agent`/`customer` route structure.

- **New route file**: `modules/Taxi/routes/api/v1/driver.php`, `require`d from `modules/Taxi/routes/api.php` alongside the others, under the `taxi.` prefix.
- **Route group**: `['prefix' => 'v1/driver', 'middleware' => ['auth:sanctum']]` → full base path **`api/taxi/v1/driver/...`**.
- **Controllers**: `Modules\Taxi\Http\Controllers\Api\V1\Driver\BookingController` (CRUD-ish read) + `BookingStatusController` for accept/complete (Single Responsibility, mirroring the vendor `BookingStatusController` split).
- **Resources**: `Modules\Taxi\Transformers\Api\V1\Driver\*` (same namespace convention as vendor transformers).

**Driver lifecycle (3 driver actions — confirmed two-step model):**
`Assigned` (by admin/vendor) → **Accept** (driver acknowledges) → **Confirm Pickup** (passenger on board, near pickup time) → **Complete** (trip done).

| Method | URI (`api/taxi/...`) | Controller@method | Purpose |
|---|---|---|---|
| `GET` | `v1/driver/bookings` | `Driver\BookingController@index` | List bookings assigned to the authenticated driver. Filter by tab: `assigned` (accepted_at null), `accepted` (accepted, pickup pending), `on_trip` (pickup confirmed), `completed`. Pagination via `limit`. |
| `GET` | `v1/driver/bookings/{booking:uuid}` | `Driver\BookingController@show` | Full detail for one assigned booking (ownership-checked). |
| `POST` | `v1/driver/bookings/{booking:uuid}/accept` | `Driver\BookingStatusController@accept` | **Step 1**: driver acknowledges the assignment → `AcceptBookingAssignmentAction` stamps `accepted_at` on the driver's assignment. Does NOT change pickup/booking status. |
| `POST` | `v1/driver/bookings/{booking:uuid}/confirm-pickup` | `Driver\BookingStatusController@confirmPickup` | **Step 2**: passenger on board → `ConfirmDriverPickupAction` (sets `driver_pickup_status = CONFIRMED`, driver → on-duty). |
| `POST` | `v1/driver/bookings/{booking:uuid}/complete` | `Driver\BookingStatusController@complete` | **Step 3**: trip done → `MarkBookingAsCompletedAction` (the "swipe complete" action). |

> Auth/login stays in `modules/Driver` (`api/driver/v1/auth/login`). The app therefore talks to **two prefixes**: `api/driver/v1/auth/*` (identity) and `api/taxi/v1/driver/*` (bookings). This is intentional and matches module ownership.

#### A3a. Migration + Accept action (new, for the two-step flow)
- **Migration**: add `accepted_at` (nullable `timestamp`) to `taxi_booking_assignments` (currently: booking_id, assignment_order, trip_type, driver_id, driver_name, driver_phone, wheel_id, plate_number, timestamps — no acceptance field).
- **`AcceptBookingAssignmentAction`** (new, Taxi module): for the authenticated driver's assignment on a booking — guard ownership + not already accepted + booking still in an acceptable state → stamp `accepted_at`. Idempotent.
- **`DriverPickupStatusEnum` stays PENDING/CONFIRMED** — acceptance is tracked on the assignment (`accepted_at`), NOT shoehorned into pickup status. List "status" for the app is derived: `accepted_at == null` → *assigned*; accepted + pickup PENDING → *accepted*; pickup CONFIRMED → *on trip*; booking COMPLETED → *completed*.

#### A3b. "Near pickup time" alert (v1 = in-app, polling)
Since v1 uses polling (no FCM), the pickup reminder is an **in-app banner/highlight** shown when the app is open and `departure_datetime` is near and pickup not yet confirmed. Real push reminder = v2 (FCM). The backend already has reminder scaffolding (`vendor_driver_reminder_at`) we can later reuse — not touched in v1.

**Ownership rule (security-first):** every booking query/route is scoped to assignments where `driver_id = auth()->id()`. A driver must never see or act on another driver's booking → return `404`/`jsonError` if not owned. (Mirrors the existing vendor-ownership pattern.)

**Query source:** `BookingAssignment::where('driver_id', $driver->id)` → eager-load `booking` (+ customer, `privateTransferDetails`/`airportTransferDetails`, vehicle) to avoid N+1. **Scoped to `service_type IN (PRIVATE, AIRPORT)`** — drivers are not used for Bus/Ferry in v1.

### A4. API Resources (new) — in `Modules\Taxi\Transformers\Api\V1\Driver\`
- `DriverBookingListResource` — compact card data: uuid, status, customer name, pickup time, pickup short address, service type, trip_type (outbound/return).
- `DriverBookingDetailResource` — full: customer name + phone (tappable call), **pickup** `{address, latitude, longitude}` + **dropoff** `{address, latitude, longitude}`, departure datetime, passenger count, vehicle/plate, notes, `accepted_at`, `driver_pickup_status`, and a computed `allowed_actions` array (e.g. `["accept"]`, `["confirm_pickup"]`, `["complete"]`) so the app shows the right button without re-deriving rules.
- Sources pickup/drop from the Private/Airport transfer tables: `pickup_point` + `pickup_latitude`/`pickup_longitude` + `dropoff_point` + `dropoff_latitude`/`dropoff_longitude` (confirmed present). v1 handles only these two service types, so the resource stays simple.

### A5. Edge cases & guards
- Booking not in an acceptable state (e.g. already completed/cancelled) → clear `jsonError` with a stable `error_code`; the app owns the wording.
- Accept allowed only when booking is `CONFIRMED` and pickup `PENDING`.
- Complete allowed only when booking is `CONFIRMED` (reuse Action's existing guard).
- Inactive/blocked driver → rejected.

### A6. Tests (Pest, `DatabaseTransactions`)
- Login by phone; login by email; bad credentials.
- List returns only the driver's own assignments.
- Detail 404 for someone else's booking.
- Accept transitions pickup status; complete transitions booking status.
- Action-level tests for the two Taxi actions if not already covered.

### A7. Deliverable for Track B
A short **API contract doc** (`docs/DRIVER_APP_API.md`) listing each endpoint, request, and exact JSON response — the Flutter app codes against this.

---

## 4. TRACK B — Flutter app (`veha_driver_app`)

### B0. Environment & tooling
- Confirm Flutter/Dart toolchain (`flutter --version`, `flutter doctor`); project SDK is `^3.11.4`.
- Install **GetX CLI** (`dart pub global activate get_cli`) and scaffold features with `get create page:<name>` for a consistent structure.
- Set `applicationId` / bundle id, app name "Veha Driver", and app icons (later).

### B0a. Environment configuration (standard)
Clean, no-secrets-in-code, multi-environment setup:
- An `Environment` enum (`dev`, `staging`, `prod`) + an `AppConfig` class exposing `baseUrl`, `apiTimeout`, etc.
- Environment selected at build time via **`--dart-define=ENV=dev|staging|prod`** (no hardcoded switch shipped; defaults to `dev`).
- Base URLs:
  - `dev` → `http://vehabooking.test`
  - `staging` → _(to fill when staging URL is known)_
  - `prod` → _(to fill at release)_
- API roots derived from `baseUrl`: auth = `{baseUrl}/api/driver/v1`, bookings = `{baseUrl}/api/taxi/v1/driver`.
- Android note: `http://vehabooking.test` is plain HTTP + a `.test` host → dev build needs cleartext + the emulator/device must resolve `vehabooking.test` (host mapping). Documented in the run instructions.

### B1. Dependencies (`pubspec.yaml`)
**UI direction: custom design system built on first-party Material 3 — NO third-party UI component library.**

| Package | Role |
|---|---|
| `get` | State management + DI (bindings) + navigation + i18n |
| _(Material 3, built-in)_ | `useMaterial3: true` + our own custom design tokens & widgets — the UI foundation |
| `flutter_animate` | Modern micro-interactions / motion (lightweight, popular, stable) |
| `google_fonts` | Custom typography incl. a Khmer-capable font |
| `dio` | HTTP client (interceptors, typed errors) |
| `flutter_secure_storage` | Secure token storage (NOT localStorage-style plaintext) |
| `get_storage` | Lightweight non-sensitive cache (e.g. selected locale) |
| `url_launcher` | Open external maps + `tel:` for calling customer |
| `intl` | Date/time/number formatting |
| `connectivity_plus` | Offline detection (nice UX for drivers on the road) |
| `lottie` _(optional)_ | Empty/success-state animations |

**Why Material 3 + custom over a UI library (shadcn dropped):**
- First-party, deepest docs, most battle-tested — no third-party UI-lib version risk. Apps still on Material 2 look dated in 2026; M3 ("Material You") is the modern baseline.
- "Custom UI" = compose our own widgets on M3 primitives (composition over inheritance). Full control of the look, no fighting a library.
- Removes the earlier `ShadcnApp` vs `GetMaterialApp` conflict → we use **`GetMaterialApp` cleanly**.
- Researched alternatives rejected: **forui** (shadcn-style, what we're moving away from, younger), **Syncfusion** (commercial licensing, heavy).

### B2. Project structure (feature-first, GetX-CLI compatible)
```
lib/
  main.dart
  app/
    core/
      config/        # env, api base url, constants
      network/       # dio client, interceptors, api_result, exceptions
      storage/       # secure storage + get_storage wrappers
      theme/         # M3 theme, design tokens (colors, spacing, radius, typography)
      i18n/          # translations (en, km), AppTranslations
      bindings/      # global bindings (services)
      routes/        # app_pages.dart, app_routes.dart
      widgets/       # shared widgets (buttons, states, loaders)
      utils/         # formatters, validators, result helpers
    data/
      models/        # Booking, Driver, AuthResponse (fromJson/toJson)
      providers/     # raw API calls per resource (auth_provider, booking_provider)
      repositories/  # repositories the controllers depend on
    modules/
      auth/          # login: view, controller, binding
      home/          # shell / bottom nav (Bookings + Profile)
      bookings/      # list: view, controller, binding
      booking_detail/# detail + accept + swipe-complete
      profile/       # driver profile + logout + language switch
```

### B3. Core layer
- **Network**: a single `DioClient` with base URL, auth-token interceptor (injects `Bearer`), error interceptor → maps backend `{success, message, error_code}` into a typed `ApiResult`/`AppException`. Centralised error handling (matches the senior/exception-based expectation).
- **Storage**: token + user in `flutter_secure_storage`; locale in `get_storage`. No plaintext token storage.
- **Theme**: a custom Material 3 `ThemeData` (`useMaterial3: true`) driven by our own **design tokens** (color scheme, spacing scale, radii, typography); light + dark. Modern, clean, large tap targets (drivers use it one-handed, outdoors).
- **Custom component kit** (our design system, built on M3 + `flutter_animate`): `AppButton`, `AppCard`, `AppTextField`, `StatusChip`, `SwipeToConfirm`, `AppScaffold`, state widgets (loading/empty/error). These are the "custom UI" — reusable, themed, no external UI library.
- **App shell**: **`GetMaterialApp`** (clean — no ShadcnApp conflict anymore) with our custom M3 theme, GetX routes, and bilingual translations.

### B4. Auth feature
- Login screen: single "Phone or Email" field + password, language toggle, validation, loading state, error surfacing.
- `AuthController` (GetX): calls `AuthRepository.login()`, stores token+user, routes to Home.
- `AuthService` + route guard / middleware: unauthenticated → Login; token present → Home. Auto-attach token to Dio. Logout clears storage.

### B5. Bookings feature (the heart)
- **List** (`bookings`): cards grouped/filtered by status (Assigned / Accepted / Completed) via tabs or filter chips. Pull-to-refresh + light polling timer while screen is active. Empty/loading/error states with skeletons.
- **Detail** (`booking_detail`):
  - Customer name + **tap-to-call** (`tel:`), pickup time, pickup address, drop-off, passengers, vehicle/plate, notes.
  - **Navigate** button → `url_launcher` opens Google/Apple Maps to pickup lat/lng (fallback to address).
  - Action button driven by `allowed_actions` from the API: **Accept** (assigned) → **Confirm Pickup** (accepted; highlighted by an in-app banner when pickup time is near) → **Swipe-to-complete** (on trip) → `complete` endpoint. Optimistic UI + refetch after each.
- Controllers handle all state (loading/success/error); repositories isolate API.

### B6. Internationalisation (EN + KM)
- GetX `Translations` with `en` + `km` maps; `.tr` everywhere; locale persisted; in-app language switch in Profile.
- Khmer-capable font via `google_fonts` (e.g. Noto Sans Khmer) wired into the M3 text theme.

### B7. UI/UX (modern, on-trend)
- Clean card-based list, rounded corners, soft shadows, status color chips, bottom nav (Bookings / Profile), big primary actions, haptic feedback on accept/complete, skeleton loaders, friendly empty states. Dark mode supported.

### B8. Flutter tests
- Unit: model `fromJson`, repository (mocked Dio), auth/booking controller logic.
- Widget: login validation, booking card, swipe-to-complete triggers callback.

---

## 5. Build order (milestones)

1. **A1–A2** Backend: guard fix + phone/email login. _Test._
2. **A3–A4** Backend (Taxi): `accepted_at` migration + `AcceptBookingAssignmentAction` + booking list/detail/accept/confirm-pickup/complete + resources. _Test._
3. **A6–A7** Backend: Pest tests + API contract doc. ✅ Backend done.
4. **B0–B3** Flutter: tooling, deps, structure, core (network/storage/theme/i18n/routes).
5. **B4** Flutter: auth end-to-end against real API.
6. **B5** Flutter: bookings list → detail → navigate → accept → swipe-complete.
7. **B6–B8** Flutter: bilingual polish, UI pass, tests.
8. Manual end-to-end on a device/emulator with a seeded assigned booking.

---

## 6. Open questions / to confirm during review

1. ✅ **RESOLVED** — Single `login` field (accepts phone OR email) + `password` + `device_name`.
2. ✅ **RESOLVED** — Pickup/drop **lat/lng confirmed** on Private/Airport transfer tables. Navigate always uses precise coords.
3. ✅ **RESOLVED** — **v1 covers Private + Airport only.** Drivers are not used for Bus/Ferry. The booking query is scoped to `service_type IN (PRIVATE, AIRPORT)`; resource handles only these (both have `pickup_point` + coords). Simpler.
4. ✅ **RESOLVED** — **Two-step**: Accept (acknowledge, `accepted_at`) → Confirm Pickup (`ConfirmDriverPickupAction`) → Complete. "Near pickup" alert = in-app banner in v1 (FCM in v2).
5. ✅ **RESOLVED** — Local/dev base URL `http://vehabooking.test`. Multi-environment config standard defined in B0a below.

---

## 7. Risks

- Service-type data variance in Taxi bookings — mitigated by flattening in the API resource (A4).
- Pickup lat/lng availability — see open question §6.2; affects Navigate precision.
- (UI risk removed: no third-party UI library; Material 3 is first-party and stable.)
