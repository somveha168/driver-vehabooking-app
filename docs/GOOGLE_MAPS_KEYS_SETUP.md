# Google Maps API Key Setup

This guide documents how to create Google Maps keys for the Veha Booking Driver app.

Do not commit real API key values into the repository.

## Required Keys

Create separate keys for each platform and environment:

| Key name | Platform | Environment | Used by |
| --- | --- | --- | --- |
| `Veha Booking Driver Android Maps Key` | Android | Production | Play Store / release app |
| `Veha Booking Driver Android Maps Key - Dev` | Android | Development | Local APK / debug testing |
| `Veha Booking Driver iOS Maps Key` | iOS | Production | App Store / TestFlight production bundle |
| `Veha Booking Driver iOS Maps Key - Dev` | iOS | Development | iOS simulator/dev bundle |

Backend Routes key is intentionally skipped for now. Create it later only if Laravel needs to call Google Routes API server-side for official route distance, ETA, pricing, or reporting.

## Google Cloud Project

Use the Veha Booking Google Cloud project:

```text
vehabooking-app
```

Open:

```text
Google Cloud Console > APIs & Services > Credentials
```

Before creating keys, make sure these APIs are enabled:

```text
Maps SDK for Android
Maps SDK for iOS
```

## Android Dev Key

Create an API key:

```text
Name:
Veha Booking Driver Android Maps Key - Dev
```

Set API restrictions:

```text
Maps SDK for Android
```

Leave this unchecked:

```text
Authenticate API calls through a service account
```

Set application restrictions:

```text
Android apps
```

Add Android app restriction:

```text
Package name:
com.vehabooking.driver.dev

SHA-1 certificate fingerprint:
62:6E:E0:EE:A4:93:B1:46:8F:03:EC:F8:58:4E:7A:3E:D9:90:EA:4C
```

Click `Done`, then `Create`.

This key is used by development APK builds.

## Android Production Key

Create or keep this API key:

```text
Name:
Veha Booking Driver Android Maps Key
```

Set API restrictions:

```text
Maps SDK for Android
```

Leave this unchecked:

```text
Authenticate API calls through a service account
```

Set application restrictions:

```text
Android apps
```

Add Android app restriction:

```text
Package name:
com.vehabooking.driver

SHA-1 certificate fingerprint:
<release-signing-sha1>
```

Use the real release signing SHA-1 before publishing to Play Store. Do not use the debug SHA-1 for production.

## iOS Dev Key

Create an API key:

```text
Name:
Veha Booking Driver iOS Maps Key - Dev
```

Set API restrictions:

```text
Maps SDK for iOS
```

Set application restrictions:

```text
iOS apps
```

Add iOS app restriction:

```text
Bundle ID:
com.vehabooking.driver.dev
```

This key is used by development iOS builds once the iOS dev bundle is configured.

## iOS Production Key

Create or keep this API key:

```text
Name:
Veha Booking Driver iOS Maps Key
```

Set API restrictions:

```text
Maps SDK for iOS
```

Set application restrictions:

```text
iOS apps
```

Add iOS app restriction:

```text
Bundle ID:
com.vehabooking.driver
```

## App Package And Bundle IDs

Current Android setup:

```text
Dev package:
com.vehabooking.driver.dev

Production package:
com.vehabooking.driver
```

Target iOS setup:

```text
Dev bundle:
com.vehabooking.driver.dev

Production bundle:
com.vehabooking.driver
```

## Get Android SHA-1 Again

From the Flutter app Android folder:

```bash
cd android
./gradlew signingReport
```

Look for:

```text
Variant: devDebug
SHA1: ...
```

For production, use the release signing SHA-1 from the real release keystore or Play App Signing certificate.

## What Not To Do

- Do not use unrestricted keys.
- Do not share one key across every environment unless it is temporary.
- Do not commit the key value into Git.
- Do not use the Android debug SHA-1 for production.
- Do not create the Backend Routes key yet unless Laravel needs server-side route calculations.

## Next App Step

After the keys are ready, wire them into the Flutter app.

## Local Android Key Values

Put local Android key values in `android/local.properties`.

This file is ignored by Git.

```properties
VEHA_GOOGLE_MAPS_ANDROID_DEV_KEY=your_android_dev_key_here
VEHA_GOOGLE_MAPS_ANDROID_PROD_KEY=your_android_prod_key_here
```

Android flavor mapping:

```text
dev flavor  -> VEHA_GOOGLE_MAPS_ANDROID_DEV_KEY  -> com.vehabooking.driver.dev
prod flavor -> VEHA_GOOGLE_MAPS_ANDROID_PROD_KEY -> com.vehabooking.driver
```

Run development APK:

```bash
flutter run --flavor dev --dart-define=ENV=dev
```

Build production app bundle later:

```bash
flutter build appbundle --release --flavor prod --dart-define=ENV=prod
```

## Local iOS Key Values

Copy:

```bash
cp ios/Flutter/MapsKeys.example.xcconfig ios/Flutter/MapsKeys.xcconfig
```

Then fill:

```xcconfig
GOOGLE_MAPS_API_KEY_DEV = your_ios_dev_key_here
GOOGLE_MAPS_API_KEY_PROD = your_ios_prod_key_here
```

`MapsKeys.xcconfig` is ignored by Git.

iOS build config mapping:

```text
Debug   -> GOOGLE_MAPS_API_KEY_DEV  -> com.vehabooking.driver.dev
Release -> GOOGLE_MAPS_API_KEY_PROD -> com.vehabooking.driver
```

Run iOS debug:

```bash
flutter run --dart-define=ENV=dev
```

Build iOS release later:

```bash
flutter build ios --release --dart-define=ENV=prod
```

## Driver App Map Behavior

The driver app uses the native Google Maps SDK keys directly:

```text
Android key -> AndroidManifest metadata
iOS key     -> AppDelegate GMSServices setup
```

The embedded booking map shows:

- driver current location when permission is allowed
- pickup marker
- drop-off marker
- active destination based on trip status
- route preview line
- button to open Google Maps for real turn-by-turn navigation

Because Backend Routes key is skipped for now, in-app route lines are visual guidance. Real road navigation still opens Google Maps through the Navigate button.
