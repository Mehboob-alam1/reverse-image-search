# Deep Image Search

Flutter reverse image search — **Apify Google Lens** (in-app matches) + **GPT-4o mini** / **Qwen-VL** About insights + optional free Lens web link.

## Features

- Gallery, camera, and image URL search
- **Open in Google Lens (free)** for full web matches
- **About** tab: AI image context (OpenAI and/or Qwen)
- History, favorites, subscriptions, AdMob (Android)

## Requirements

- Flutter 3.35+ / Dart 3.9+
- `APIFY_TOKEN` for Visual / Exact / Products match lists
- Optional: `OPENAI_API_KEY` and/or `QWEN_API_KEY` for About insights

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
  → Apify Google Lens actor (visual / exact / products)
  → GPT-4o mini / Qwen-VL (About insights)
  → optional "Open in Google Lens" (free web)
```

## Testing

```bash
flutter test
```
