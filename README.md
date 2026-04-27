# WordSwipe

WordSwipe is a Flutter web app for learning English vocabulary through smart
cards, adaptive review, and multiple practice modes. Swipe right for words you
know, swipe left for words that are still new, and the app builds the next deck
around your current level and review schedule.

Live site: https://wordswipe-c7bfe.web.app

## Overview

WordSwipe is local-first and web-first. It tracks CEFR progress, records every
`KNOW` / `NEW` decision, schedules spaced reviews, and exposes the same learning
state across swipe cards, quizzes, typing practice, match games, tests, and the
word library.

## Features

- Smart Today deck that automatically chooses the right level.
- Deterministic daily shuffle so fresh decks do not always start alphabetically.
- First-run placement flow to estimate the right starting level.
- Swipe right for `KNOW`, swipe left for `NEW`.
- Practice modes: Smart Swipe, Flashcards, Learn Quiz, Type Answer, Match, and Test.
- Spaced repetition for new words with 1, 3, 7, 14, and 30 day intervals.
- Tap cards to reveal definitions, phonetics, examples, and word-building hints.
- Browser text-to-speech pronunciation where supported.
- Searchable word library with `Unseen`, `New`, `Learning`, `Know`, `Due`, and
  `Mastered` filters.
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
python scripts/validate_assets.py
flutter build web --release
```

Run the release build before opening a PR if you changed UI, routing, assets, or
deployment behavior.

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

The app ships with generated JSON assets already committed in the repo. Most
contributors do not need to regenerate them unless they are intentionally
updating vocabulary data, filters, scoring, or morphology sources.

Word generation is score-based: learner-core words are preferred, subtitle
frequency is treated as only one signal, and noisy tokens such as malformed
hyphen fragments, repeated interjections, truncated contractions, and known
proper-name noise are filtered before CEFR files are capped.

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

It rejects corrupted dictionary text, mojibake glyphs, empty definitions,
low-value inflection-only definitions, and examples with bad encoding.

### Validate Assets

```bash
python scripts/validate_assets.py
```

The validator checks duplicates, required metadata fields, insight coverage,
malformed tokens, mojibake, and writes `assets/quality_report.json` for review.

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

The current automated coverage focuses on widget behavior, storage logic, smart
deck selection, seeded deck randomness, progress buckets, practice mode entry
points, and spaced repetition scheduling.

## Deployment

Firebase Hosting is configured for the maintainer project in `.firebaserc`.

```bash
flutter build web --release
firebase deploy --only hosting
```

Collaborators should assume deployment is maintainer-only unless they configure
their own Firebase project.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.
