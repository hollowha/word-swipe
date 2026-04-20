import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../models/swipe_record.dart';
import '../services/dictionary_service.dart';
import '../services/storage_service.dart';
import 'word_providers.dart';

// ── Swipe state ───────────────────────────────────────────────────────────────

class SwipeState {
  final int currentIndex;
  final bool isComplete;

  const SwipeState({this.currentIndex = 0, this.isComplete = false});

  SwipeState copyWith({int? currentIndex, bool? isComplete}) => SwipeState(
        currentIndex: currentIndex ?? this.currentIndex,
        isComplete: isComplete ?? this.isComplete,
      );
}

class SwipeNotifier extends StateNotifier<SwipeState> {
  final StorageService _storage;

  SwipeNotifier(this._storage) : super(const SwipeState());

  Future<void> swipeRight(Word word) async {
    // Update index immediately so the UI responds without waiting for Hive
    state = state.copyWith(currentIndex: state.currentIndex + 1);
    _storage.recordSwipe(word.id, 'right'); // fire-and-forget
  }

  Future<void> swipeLeft(Word word) async {
    state = state.copyWith(currentIndex: state.currentIndex + 1);
    _storage.recordSwipe(word.id, 'left');
  }

  void markComplete() {
    state = state.copyWith(isComplete: true);
  }

  void reset() {
    state = const SwipeState();
  }
}

final swipeProvider =
    StateNotifierProvider.autoDispose<SwipeNotifier, SwipeState>((ref) {
  final storage = ref.read(storageServiceProvider);
  return SwipeNotifier(storage);
});

// ── Per-card flip state ───────────────────────────────────────────────────────

final cardFlippedProvider =
    StateProvider.autoDispose.family<bool, int>((ref, index) => false);

// ── Swipe record for a word ───────────────────────────────────────────────────

final swipeRecordProvider = Provider.family<SwipeRecord, String>((ref, wordId) {
  final storage = ref.read(storageServiceProvider);
  return storage.getOrCreateRecord(wordId);
});

// ── Dictionary definition ─────────────────────────────────────────────────────
// Key: wordId (String). No autoDispose so resolved futures stay cached
// in the provider container for the session — instant on tap after prefetch.

final dictionaryServiceProvider =
    Provider<DictionaryService>((ref) => DictionaryService());

final definitionProvider =
    FutureProvider.family<Word, String>((ref, wordId) async {
  final storage = ref.read(storageServiceProvider);

  // Read fresh from Hive — may already be populated by a prior prefetch
  final word = storage.words.get(wordId);
  if (word == null) throw Exception('Word $wordId not found');
  if (word.definitionLoaded) return word;

  final dict = ref.read(dictionaryServiceProvider);
  final def = await dict.fetchDefinition(word.word);

  if (def == null) {
    final updated = word.copyWith(definitionLoaded: true);
    storage.words.put(word.id, updated);
    return updated;
  }

  final updated = word.copyWith(
    phonetic: def.phonetic,
    partOfSpeech: def.partOfSpeech,
    definition: def.definition,
    example: def.example,
    definitionLoaded: true,
  );
  storage.words.put(word.id, updated);
  return updated;
});
