# Deep Image Search

Flutter reverse image search — primary **Railway reverse-image API** (web matches + AI analysis), with optional Apify / free Lens fallbacks.

## Features

- Gallery, camera, and image URL search
- **Open in Google Lens (free)** for full web matches
- **About** tab: AI image context (OpenAI and/or Qwen)
- History, favorites, subscriptions, AdMob (Android)

## Requirements

- Flutter 3.35+ / Dart 3.9+
- Railway API (no key for `/api/search`) — see `RailwaySearchConfig`
- Optional fallbacks: `APIFY_TOKEN`, `OPENAI_API_KEY`, `QWEN_API_KEY`

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
