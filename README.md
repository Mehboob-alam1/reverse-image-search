# Deep Image Search

Flutter + Dart reverse image search app. The app calls SerpApi Google Lens directly — there is no custom backend.

## Features

- First-launch flow: Splash → Language → Pro → Home
- Gallery, camera, and image URL search
- Crop, rotate, flip, and zoom before searching
- Visual, exact, product, and about-this-image results
- History, favorites, settings, and dark mode
- Localized UI with a screenshot-style language picker
- Guest-only local history and favorites

## Requirements

- Flutter 3.35+ / Dart 3.9+
- Android SDK 24+
- A [SerpApi](https://serpapi.com/) key

## Setup

```bash
flutter pub get
flutter gen-l10n
```

## Environment

Pass the SerpApi key at compile time. Do not commit a real key.

| Define | Default | Purpose |
| --- | --- | --- |
| `SERPAPI_KEY` | empty | SerpApi Google Lens key |
| `FLAVOR` | `development` | `development`, `staging`, or `production` |

For local runs, copy `dart_defines.dev.json.example` to `dart_defines.dev.json` (gitignored), add your key, then use `--dart-define-from-file=dart_defines.dev.json`. VS Code/Cursor launch configs already use that file.

## Running the app

```bash
flutter run --dart-define-from-file=dart_defines.dev.json
```

Android emulator and physical devices both work with that command. Local files are hosted briefly on tmpfiles.org so Google Lens can read a public image URL.

## Building

```bash
flutter build apk --release --dart-define=FLAVOR=production --dart-define=SERPAPI_KEY=your_key
flutter build appbundle --release --dart-define=FLAVOR=production --dart-define=SERPAPI_KEY=your_key
flutter build ipa --release --dart-define=FLAVOR=production --dart-define=SERPAPI_KEY=your_key
```

## Accounts

The app does not use Firebase Authentication. Anyone can search without signing in. History and favorites stay on the device.

## Testing

```bash
flutter test
```

## Architecture

```text
Flutter app
  → tmpfiles.org (local photo hosting)
  → SerpApi Google Lens
```

State management is Riverpod. Navigation is go_router. Search calls go through `SerpApiService`.
