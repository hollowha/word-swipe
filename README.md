# WordSwipe

WordSwipe is a Flutter web app for learning English vocabulary through a smart swipe-card flow.
Swipe right for words you know, swipe left for words that are still new, and the app automatically builds the next deck around your current level and review schedule.

Live site: https://wordswipe-c7bfe.web.app

## 繁中摘要

WordSwipe 是一個 Flutter Web 英文字卡學習 App。主玩法是自動智慧滑卡：系統會根據你在不同 CEFR 等級的 `KNOW` / `NEW` 比率、近期答題狀態，以及間隔複習到期時間，產生今日最適合你的字卡。

## Features

- Smart Today deck that automatically chooses the right level.
- Swipe right for `KNOW`, swipe left for `NEW`.
- Spaced repetition for new words with 1, 3, 7, 14, and 30 day intervals.
- Tap cards to reveal definitions, phonetics, examples, and word-building hints.
- CEFR vocabulary coverage from `A1` to `C2`.
- Local-first progress storage with Hive on web.
- Offline word and insight assets bundled with the app.

## Stack

- Flutter 3 / Dart
- Riverpod for state management
- Hive for local persistence
- GoRouter for routing
- Python scripts for word and insight generation
- Firebase Hosting for deployment

## Quick Start

### Prerequisites

- Flutter SDK
- Python 3.10+ if you need to regenerate data assets
- Chrome or another browser supported by Flutter web

### Install

```bash
flutter pub get
python -m pip install -r scripts/requirements.txt
```

### Run Locally

```bash
flutter run -d chrome
```

### Validate Before Sharing

```bash
flutter test
flutter build web --release
```

Run the release build before opening a PR if you changed UI, routing, assets, or deployment behavior.

## Project Layout

```text
wordSwipe/
  lib/          Flutter app source
  assets/       Tracked study data used by the app
  scripts/      Python helpers for generating word and insight assets
  test/         Flutter and storage tests
  web/          Web entry assets and manifest
  firebase.json Firebase Hosting config
  pubspec.yaml  Flutter package manifest
```

## Data Pipeline

The app ships with generated JSON assets already committed in the repo. Most contributors do not need to regenerate them unless they are intentionally updating vocabulary data, filters, or morphology sources.

### Rebuild Word Assets

```bash
python scripts/generate_words.py
```

### Rebuild Insight Assets

```bash
python -u scripts/generate_insights.py --workers 8
```

Optional partial rebuild:

```bash
python -u scripts/generate_insights.py --levels B2 C1 C2 --workers 8
```

The insight generator reads:

- `assets/words/*.json`
- morphology spreadsheets under `scripts/data/morphology/`
- online dictionary sources at generation time

## Development Notes

- Generated assets in `assets/words/` and `assets/insights/` are source-controlled on purpose.
- If you regenerate those assets, review the diff carefully before committing.
- Avoid mixing feature work and large regenerated data changes in the same commit.
- Do not commit local caches, virtual environments, build output, debug logs, or Hive runtime data.
- The app is currently web-first.

## Testing

```bash
flutter test
flutter build web --release
```

The current automated coverage focuses on widget behavior, storage logic, smart deck selection, and spaced repetition scheduling.

## Deployment

Firebase Hosting is configured for the maintainer project in `.firebaserc`.

```bash
flutter build web --release
firebase deploy --only hosting
```

Collaborators should assume deployment is maintainer-only unless they configure their own Firebase project.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.
