# Deep Image Search

Flutter reverse image search — primary **Railway reverse-image API** (web matches + AI analysis), with optional Apify / free Lens fallbacks.

## Features

- Gallery, camera, and image URL search
- **Open in Google Lens (free)** for full web matches
- **About** tab: AI image context (OpenAI and/or Qwen)
- History, favorites, subscriptions
- **AdMob on Android only** — toggles + unit IDs from remote JSON (iOS never shows ads)

## Requirements

- Flutter 3.35+ / Dart 3.9+
- Railway API (no key for `/api/search`) — see `RailwaySearchConfig`
- Optional fallbacks: `APIFY_TOKEN`, `OPENAI_API_KEY`, `QWEN_API_KEY`
- **Firebase** (Analytics + FCM): run `flutterfire configure` and replace
  `android/app/google-services.json` + `lib/firebase_options.dart`
  (Realtime Database / Firestore are **not** required)

### Firebase / reviews / updates

| Feature | Package | Notes |
| --- | --- | --- |
| Analytics | `firebase_analytics` | Existing `AnalyticsService` events |
| Push (FCM) | `firebase_messaging` | Token + foreground/background handlers |
| In-app review | `in_app_review` | Drawer → Rate Us |
| In-app updates | `in_app_update` | Android Play flexible/immediate on splash |

## Setup

```bash
flutter pub get
flutter gen-l10n
```

Copy `dart_defines.dev.json.example` → `dart_defines.dev.json` (gitignored):

```json
{
  "FLAVOR": "development",
  "APIFY_TOKEN": "...",
  "OPENAI_API_KEY": "...",
  "QWEN_API_KEY": "..."
}
```

```bash
flutter run --dart-define-from-file=dart_defines.dev.json
```

Gallery photos get a **temporary public URL** (catbox / tmpfiles / 0x0.st) so **lens.google.com** can load them.

## Environment

| Define | Purpose |
| --- | --- |
| `APIFY_TOKEN` | Apify `johnvc/google-lens-api` — in-app match lists |
| `OPENAI_API_KEY` | GPT-4o mini — About tab, summaries |
| `QWEN_API_KEY` | Qwen-VL (DashScope) — multilingual / fallback |
| `FLAVOR` | `development` or `production` |
| `ADS_REMOTE_CONFIG_URL` | HTTPS JSON for ads + `api_base_url` (Railway API) |

### Remote config (no Firebase Database needed)

**Firebase Realtime Database / Firestore is not required.**  
Remote Config is a separate Firebase product. This app currently loads a **hosted flat JSON** URL (GitHub raw, Firebase Hosting, any CDN) — not the Firebase RC SDK — so you also don’t need the Firebase SDK unless you add it later.

**Host this file:** [`assets/ads/ads_remote_config.json`](assets/ads/ads_remote_config.json)

```bash
flutter run --dart-define=ADS_REMOTE_CONFIG_URL=https://your-cdn/ads_remote_config.json
```

Key fields:

| Key | Purpose |
| --- | --- |
| `api_base_url` | Railway (or other) reverse-image API root |
| `ads_enabled` | Master Android ads switch |
| `banner` / `interstitial` / `rewarded` / `app_open` / `native` | AdMob unit IDs |

**Ad strategy (defaults):**

| Format | When |
| --- | --- |
| App open | Once per session after splash |
| Interstitial | After a successful search |
| Collapsible banner | Bottom of main screens |
| Native | Every 4 result cards |
| Rewarded | User taps “watch ad” for +1 credit |

- `"ads_enabled": false` turns all Android ads off.
- iOS never shows ads; `api_base_url` still applies on all platforms.
- Splash re-fetches every launch (cache used offline).

## Architecture

```text
Flutter app
  → Railway POST /api/search (multipart file, web=true)
  → maps matches / similar_web / analysis / engines
  → optional Apify or free Lens fallback
```

## Testing

```bash
flutter test
```
