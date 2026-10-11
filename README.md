# Deep Image Search

Flutter reverse image search — **free Google Lens (web)** + **GPT-4o mini** / **Qwen-VL** insights. No SerpApi, no custom backend.

## Features

- Gallery, camera, and image URL search
- **Open in Google Lens (free)** for full web matches
- **About** tab: AI image context (OpenAI and/or Qwen)
- History, favorites, subscriptions, AdMob (Android)

## Requirements

- Flutter 3.35+ / Dart 3.9+
- Optional: `OPENAI_API_KEY` and/or `QWEN_API_KEY` for in-app About insights

## Setup

```bash
flutter pub get
flutter gen-l10n
```

Copy `dart_defines.dev.json.example` → `dart_defines.dev.json` (gitignored):

```json
{
  "FLAVOR": "development",
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
| `OPENAI_API_KEY` | GPT-4o mini — About tab, summaries |
| `QWEN_API_KEY` | Qwen-VL (DashScope) — multilingual / fallback |
| `FLAVOR` | `development` or `production` |

## Architecture

```text
Flutter app
  → temporary image host (gallery only)
  → Google Lens web (free) — user taps "Open in Google Lens"
  → GPT-4o mini / Qwen-VL — in-app About insights
```

## Testing

```bash
flutter test
```
