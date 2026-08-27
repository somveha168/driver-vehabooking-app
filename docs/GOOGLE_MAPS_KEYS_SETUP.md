# Google Maps API Key Setup

How Google Maps keys are created and wired for the Veha Booking Driver app.

Do not commit real API key values into the repository.

## Model: one key per platform

The app has **no build flavors and no dev/prod variants**. There is one app id,
one bundle id, and therefore **one Maps key per platform**:

| Key name | Platform | Used by |
| --- | --- | --- |
| `Veha Booking Driver Android Maps Key` | Android | every Android build (debug and release) |
| `Veha Booking Driver iOS Maps Key` | iOS | every iOS build (Debug and Release) |

The `- Dev` keys are no longer used by this app. Leave them in the console if
other projects use them, otherwise delete them.

A Maps key is restricted by **app identity**, not by backend. It is read by
native code at startup from `AndroidManifest.xml` / `Info.plist`, before Dart
runs. It therefore cannot come from `.env` — and must not, since `.env` ships
in plaintext inside the app bundle.

Which backend the app talks to is a separate, unrelated switch: `APP_URL` in
the root `.env`. See the README.

## Google Cloud Project

```text
vehabooking-app
```

Open:

```text
Google Cloud Console > APIs & Services > Credentials
```

These APIs must be enabled:

```text
Maps SDK for Android
Maps SDK for iOS
```

## Android key restrictions

Restrict the Android key to the package name plus **every** signing certificate
that will run the app. One key, several package/SHA-1 pairs:

```text
Application restriction : Android apps
API restriction         : Maps SDK for Android

Package name : com.vehabooking.driver
SHA-1        : <debug keystore SHA-1>      (local flutter run)
SHA-1        : <upload keystore SHA-1>     (what you sign the release with)
SHA-1        : <Play App Signing SHA-1>    (from Play Console, if using Play)
```

All three entries are required. Miss one and that build shows **blank grey map
tiles** — no crash, no error message. That is the signature symptom of a key
restriction mismatch.

### Get the debug SHA-1

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey -storepass android -keypass android | grep SHA1
```

### Get the Play App Signing SHA-1

```text
Play Console > your app > Setup > App signing > App signing key certificate
```

## iOS key restrictions

iOS keys are restricted by bundle id only — no certificate involved:

```text
Application restriction : iOS apps
API restriction         : Maps SDK for iOS

Bundle ID : com.vehabooking.driver
```

Debug and Release share this bundle id, so one entry covers both.

## App identity

```text
Android applicationId    : com.vehabooking.driver
iOS bundle identifier    : com.vehabooking.driver
```

Both are set in one place each:
- Android — `applicationId` in `android/app/build.gradle.kts`
- iOS — `APP_BUNDLE_ID` in `ios/Flutter/Debug.xcconfig` and `Release.xcconfig`

## Where the key values live locally

Both files are gitignored. Never commit them.

### Android — `android/local.properties`

```text
VEHA_GOOGLE_MAPS_ANDROID_KEY=your_android_key_here
```

Read by `localOrEnv()` in `android/app/build.gradle.kts`, which falls back to a
Gradle property then an environment variable of the same name — so CI can supply
it without a file. Injected into the manifest as `${googleMapsApiKey}`.

### iOS — `ios/Flutter/MapsKeys.xcconfig`

Copy `MapsKeys.example.xcconfig` to `MapsKeys.xcconfig`, then set:

```text
GOOGLE_MAPS_API_KEY = your_ios_key_here
```

`Debug.xcconfig` and `Release.xcconfig` both `#include?` this file, and
`Info.plist` reads `$(GOOGLE_MAPS_API_KEY)`.

## Building

No flavor flags. The key is the same either way.

```bash
flutter run
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## What not to do

- Do not use unrestricted keys.
- Do not commit a key value into Git.
- Do not put a Maps key in `.env` — it is bundled in plaintext and read too late.
- Do not forget the Play App Signing SHA-1; the store-delivered app is re-signed
  by Google and will otherwise render grey tiles in production only.

## Driver app map behavior

```text
Android key -> AndroidManifest metadata
iOS key     -> Info.plist / GMSServices setup
```

The embedded booking map shows:

- driver current location when permission is allowed
- pickup marker
- drop-off marker
- active destination based on trip status
- route preview line
- button to open Google Maps for real turn-by-turn navigation

No Backend Routes key is used, so in-app route lines are visual guidance. Real
road navigation opens Google Maps through the Navigate button.
