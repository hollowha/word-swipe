import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/study_constants.dart';
import '../models/word.dart';
import '../models/swipe_record.dart';
import '../models/word_insight.dart';
import '../services/dictionary_service.dart';
import '../services/game_service.dart';
import '../services/haptics_service.dart';
import '../services/speech_service.dart';
import '../services/storage_service.dart';
import 'word_providers.dart';

// ── Swipe state ───────────────────────────────────────────────────────────────

class SwipeState {
  final int currentIndex;
  final bool isComplete;
  final int knowCount;
  final int newCount;
  final int dueReviewCompleted;
  final int xpGained;
  final List<String> completedQuestIds;
  final bool streakAdvanced;

  const SwipeState({
    this.currentIndex = 0,
    this.isComplete = false,
    this.knowCount = 0,
    this.newCount = 0,
    this.dueReviewCompleted = 0,
    this.xpGained = 0,
    this.completedQuestIds = const [],
    this.streakAdvanced = false,
  });

  SwipeState copyWith({
    int? currentIndex,
    bool? isComplete,
    int? knowCount,
    int? newCount,
    int? dueReviewCompleted,
    int? xpGained,
    List<String>? completedQuestIds,
    bool? streakAdvanced,
  }) => SwipeState(
        currentIndex: currentIndex ?? this.currentIndex,
        isComplete: isComplete ?? this.isComplete,
        knowCount: knowCount ?? this.knowCount,
        newCount: newCount ?? this.newCount,
        dueReviewCompleted: dueReviewCompleted ?? this.dueReviewCompleted,
        xpGained: xpGained ?? this.xpGained,
        completedQuestIds: completedQuestIds ?? this.completedQuestIds,
        streakAdvanced: streakAdvanced ?? this.streakAdvanced,
      );
}

class SwipeNotifier extends StateNotifier<SwipeState> {
  final StorageService _storage;
  final GameService _game;
  final Ref _ref;

  SwipeNotifier(this._storage, this._game, this._ref) : super(const SwipeState());

  Future<void> swipeRight(
    Word word, {
    required String inputSource,
  }) async {
    final wasDue = _storage.getOrCreateRecord(word.id).isDue(DateTime.now());
    final targetLevel = _storage.getTargetLevel();
    // Update immediately so the UI responds without waiting for Hive.
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      knowCount: state.knowCount + 1,
      dueReviewCompleted: state.dueReviewCompleted + (wasDue ? 1 : 0),
    );
    final result = await _game.recordSwipe(
      isKnow: true,
      wasDue: wasDue,
      targetLevel: targetLevel,
    );
    state = state.copyWith(
      xpGained: result.xpGained,
      completedQuestIds: result.completedQuestIds,
      streakAdvanced: result.streakAdvanced,
    );
    _ref.invalidate(gameProgressProvider);
    _storage.recordSwipe(
      word.id,
      swipeDirectionKnow,
      inputSource: inputSource,
    ); // fire-and-forget
  }

  Future<void> swipeLeft(
    Word word, {
    required String inputSource,
  }) async {
    final targetLevel = _storage.getTargetLevel();
    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      newCount: state.newCount + 1,
    );
    final result = await _game.recordSwipe(
      isKnow: false,
      wasDue: false,
      targetLevel: targetLevel,
    );
    state = state.copyWith(
      xpGained: result.xpGained,
      completedQuestIds: result.completedQuestIds,
      streakAdvanced: result.streakAdvanced,
    );
    _ref.invalidate(gameProgressProvider);
    _storage.recordSwipe(
      word.id,
      swipeDirectionNew,
      inputSource: inputSource,
    );
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
  final game = ref.read(gameServiceProvider);
  return SwipeNotifier(storage, game, ref);
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
final hapticsServiceProvider = Provider<HapticsService>((ref) => HapticsService());
final speechServiceProvider = Provider<SpeechService>((ref) => SpeechService());

final wordInsightProvider = Provider.family<WordInsight, String>((ref, wordId) {
  final storage = ref.read(storageServiceProvider);
  return storage.getInsight(wordId);
});

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
