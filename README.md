# WordSwipe

Tinder-style English vocabulary learning web app built with Flutter.  
Swipe right = familiar, swipe left = still learning. 20,000 CEFR-classified words, offline-first, deployed on Firebase Hosting.

**Live:** https://wordswipe-c7bfe.web.app

---

## Features

- Swipe cards left / right (drag or tap buttons) to mark familiarity
- Tap any card to flip and see full definition, phonetic, part of speech, example sentence
- Definitions fetched on-demand from [Free Dictionary API](https://api.dictionaryapi.dev) with lemmatisation fallback (handles -ing / -ed / -s / -ly / -er / -tion forms)
- Definitions are prefetched for the next 5 cards silently — tap-to-flip is instant after first load
- Next card is always visible behind the active card, scales in as you drag
- 20,000 words split across 6 CEFR levels: A1 → A2 → B1 → B2 → C1 → C2
- Per-word swipe counts persisted in Hive (IndexedDB on web) — survives page refresh
- Progress dashboard: per-level familiar / seen / remaining
- Filter by CEFR level; each session serves up to 200 shuffled cards
- Flutter web only (no iOS / Android targets configured)

---

## Project Structure

```
wordSwipe/
├── lib/
│   ├── main.dart               # App entry: Hive init, register adapters, openBoxes, runApp
│   ├── app.dart                # MaterialApp.router + GoRouter (2 routes: / and /dashboard)
│   ├── theme.dart              # AppTheme — colours, typography constants, ThemeData
│   │
│   ├── models/
│   │   ├── word.dart           # Word (HiveType 0) + JSON serialisation
│   │   ├── word.g.dart         # ← generated (build_runner)
│   │   ├── swipe_record.dart   # SwipeRecord (HiveType 1)
│   │   └── swipe_record.g.dart # ← generated
│   │
│   ├── services/
│   │   ├── asset_service.dart      # Loads JSON assets from assets/words/ by CEFR level
│   │   ├── storage_service.dart    # Hive box access, first-run seeding, stats aggregation
│   │   └── dictionary_service.dart # Free Dictionary API + lemmatisation retry logic
│   │
│   ├── providers/
│   │   ├── word_providers.dart   # selectedLevelProvider, seedingProvider, wordDeckProvider
│   │   └── swipe_providers.dart  # swipeProvider, cardFlippedProvider, definitionProvider
│   │
│   ├── screens/
│   │   ├── swipe_screen.dart     # Main screen: level tabs, card stack, swipe buttons
│   │   └── dashboard_screen.dart # Progress screen: hero stat, per-level rows
│   │
│   └── widgets/
│       ├── cefr_badge.dart       # Coloured CEFR level pill
│       ├── word_card_front.dart  # Card front: word + phonetic + tap hint
│       ├── word_card_back.dart   # Card back: full definition (watches definitionProvider)
│       └── swipe_buttons.dart    # Animated ✕ / ✓ circle buttons
│
├── assets/
│   └── words/
│       ├── a1_words.json   # 1,500 words
│       ├── a2_words.json   # 2,500 words
│       ├── b1_words.json   # 4,000 words
│       ├── b2_words.json   # 5,000 words
│       ├── c1_words.json   # 4,000 words
│       └── c2_words.json   # 3,000 words
│
├── scripts/
│   └── generate_words.py   # One-time script to regenerate the word JSON files
│
├── web/
│   ├── index.html          # Sets bg colour #F1F0ED to avoid white flash on load
│   └── manifest.json
│
├── firebase.json           # Hosting config: public=build/web, SPA rewrite, cache headers
├── .firebaserc             # Firebase project: wordswipe-c7bfe
└── pubspec.yaml
```

---

## Architecture Notes

### State management — Riverpod

| Provider | Type | Purpose |
|---|---|---|
| `selectedLevelProvider` | `StateProvider<String?>` | Active CEFR filter (null = all) |
| `seedingProvider` | `FutureProvider<void>` | One-time Hive seeding from JSON assets |
| `wordDeckProvider` | `FutureProvider<List<Word>>` | Deck for current level, shuffled, max 200 |
| `swipeProvider` | `StateNotifierProvider<SwipeNotifier>` | Current card index, completion flag |
| `cardFlippedProvider` | `StateProvider.family<bool, int>` | Per-card flip state (autoDispose) |
| `definitionProvider` | `FutureProvider.family<Word, String>` | Lazy-fetch definition by wordId; **no autoDispose** so resolved futures stay cached for the session |

### Persistence — Hive

| Box | Key type | Value type | Notes |
|---|---|---|---|
| `words` | `String` (wordId) | `Word` | Seeded from JSON on first run; updated when definitions are fetched |
| `swipe_records` | `String` (wordId) | `SwipeRecord` | rightCount, leftCount, lastSwipedAt |
| `meta` | `String` | `dynamic` | `words_seeded: bool` flag |

First-run seeding loads all 6 JSON files in parallel, writes ~20k Word objects to Hive, then sets `meta['words_seeded'] = true`. Subsequent launches skip this step.

### Card stack design

The swipe experience uses a hybrid approach to avoid the `flutter_card_swiper` multi-card transition flicker:

- `CardSwiper` is configured with `numberOfCardsDisplayed: 1` (owns swipe physics only)
- A separate `_PreviewCard` widget is rendered in a `Stack` *behind* the swiper
- `ValueNotifier<double> _drag` is updated every frame from `cardBuilder`'s `percentX`
- `ValueListenableBuilder` drives `Transform.scale` (0.93→1.0) and `Transform.translate` (y: 18→0) on the preview card with `Curves.easeOut`
- On `onSwipe`, `setState(() => _topIndex++)` advances the preview word immediately

### Definition prefetch

`_CardAreaState` calls `ref.read(definitionProvider(id).future).ignore()` for the next 5 cards on `initState` and after each `onSwipe`. Since `definitionProvider` has no `autoDispose`, the resolved `Future` stays cached in the Riverpod container. When the user taps to flip a card, `ref.watch(definitionProvider(id))` returns `AsyncData` synchronously.

### Lemmatisation fallback

`DictionaryService._candidates(word)` generates up to 5 candidate forms tried in order:
1. Original word
2. `-ing` → base (dancing→dance, running→run)
3. `-ed` → base (played→play, danced→dance)
4. `-s/-es/-ies/-ves` → singular/base
5. `-ly` → adjective (quickly→quick)
6. `-er/-est` → positive (faster→fast)
7. `-tion/-ation` → verb (creation→create, action→act)

---

## Prerequisites

- Flutter SDK ≥ 3.4 ([install](https://docs.flutter.dev/get-started/install))
- Dart SDK ≥ 3.4 (bundled with Flutter)
- Firebase CLI (`npm install -g firebase-tools`) — only needed for deployment
- Python 3 + `pip install requests` — only needed to regenerate word lists

---

## Common Commands

### Development

```bash
# Run in Chrome (hot reload enabled)
flutter run -d chrome

# Run with a specific port
flutter run -d chrome --web-port 8080

# Static analysis
flutter analyze

# Run tests
flutter test
```

### Code generation

Run this whenever you modify `word.dart` or `swipe_record.dart` (Hive adapters + JSON serialisation):

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Production build

```bash
# Standard build (CanvasKit renderer, ~2 MB)
flutter build web --release

# WebAssembly build — faster runtime, larger initial load
flutter build web --release --wasm

# Build with a custom base path (e.g. subdirectory hosting)
flutter build web --release --base-href /app/
```

Build output lands in `build/web/`.

### Firebase Hosting

```bash
# One-time login (opens browser)
firebase login

# Preview locally before deploying (serves build/web on localhost:5000)
firebase serve --only hosting

# Deploy to production
firebase deploy --only hosting

# Deploy to a preview channel (shareable URL, auto-expires in 7 days)
firebase hosting:channel:deploy preview --expires 7d

# View deployment history
firebase hosting:releases:list
```

Live URL after deploy: **https://wordswipe-c7bfe.web.app**  
Firebase console: https://console.firebase.google.com/project/wordswipe-c7bfe/overview

### Regenerate word list

Only needed if you want to refresh the 20,000-word JSON files (e.g. update CEFR mappings):

```bash
cd scripts
pip install requests
python generate_words.py
# Outputs: ../assets/words/{a1,a2,b1,b2,c1,c2}_words.json
```

The script pulls from a public English frequency corpus and maps word ranks to CEFR levels. If Oxford 5000 CSV is available it overrides frequency-based labels.  
After regenerating, run `flutter build web --release` and redeploy.

---

## Key Files for Common Tasks

| Task | File(s) to edit |
|---|---|
| Change colour palette / typography | `lib/theme.dart` |
| Add a new screen | `lib/screens/`, then register route in `lib/app.dart` |
| Change how swipe counts are stored | `lib/services/storage_service.dart` |
| Add a new Word field | `lib/models/word.dart` → run `build_runner` → migrate Hive data if needed |
| Adjust definition fetch / retry logic | `lib/services/dictionary_service.dart` |
| Change which words are in the deck | `lib/providers/word_providers.dart` (`wordDeckProvider`) |
| Modify card UI | `lib/widgets/word_card_front.dart`, `lib/widgets/word_card_back.dart` |
| Modify swipe stack / preview animation | `lib/screens/swipe_screen.dart` (`_CardArea`, `_PreviewCard`) |

---

## Known Limitations

- **No user accounts** — progress is stored in the browser's IndexedDB (Hive web backend). Clearing browser data resets all progress.
- **Definition coverage** — the Free Dictionary API covers most common English words. Lemmatisation handles inflected forms but some rare words will show "Definition unavailable".
- **Web only** — `flutter build apk` / `flutter build ios` will fail; `android/` and `ios/` directories do not exist.
- **Hive migration** — if you add a new `@HiveField` to `Word` or `SwipeRecord`, bump the `typeId` or handle schema migration; existing users' IndexedDB data uses the old schema.
