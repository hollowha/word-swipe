import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/smart_deck.dart';
import '../models/study_constants.dart';
import '../models/study_mode.dart';
import '../models/progress_bucket.dart';
import '../models/word.dart';
import '../services/asset_service.dart';
import '../services/game_service.dart';
import '../services/storage_service.dart';

enum StudyDeckMode { smart, normal, reviewLeftSwiped }

final assetServiceProvider = Provider<AssetService>((ref) => AssetService());

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());
final gameServiceProvider = Provider<GameService>((ref) => GameService());

final gameProgressProvider = Provider((ref) {
  final game = ref.read(gameServiceProvider);
  return game.getProgress();
});

/// null = all levels
final selectedLevelProvider = StateProvider<String?>((ref) => 'A1');
final studyDeckModeProvider =
    StateProvider<StudyDeckMode>((ref) => StudyDeckMode.smart);
final selectedStudyModeProvider =
    StateProvider<StudyMode>((ref) => StudyMode.smartSwipe);
final libraryBucketProvider =
    StateProvider<ProgressBucket>((ref) => ProgressBucket.all);
final librarySearchProvider = StateProvider<String>((ref) => '');

/// Whether seeding is complete
final seedingProvider = FutureProvider<void>((ref) async {
  final storage = ref.read(storageServiceProvider);
  final assets = ref.read(assetServiceProvider);
  await storage.seedIfNeeded(assets);
});

final smartDeckProvider = FutureProvider<SmartDeck>((ref) async {
  await ref.watch(seedingProvider.future);
  final storage = ref.read(storageServiceProvider);
  return storage.getSmartDeck();
});

final placementDeckProvider = FutureProvider<List<Word>>((ref) async {
  await ref.watch(seedingProvider.future);
  final storage = ref.read(storageServiceProvider);
  return storage.getPlacementDeck();
});

final hasPlacementProvider = Provider<bool>((ref) {
  final storage = ref.read(storageServiceProvider);
  return storage.hasPlacement;
});

final progressStatsProvider = Provider((ref) {
  final storage = ref.read(storageServiceProvider);
  return storage.getProgressStats();
});

final libraryEntriesProvider = Provider((ref) {
  final storage = ref.read(storageServiceProvider);
  final level = ref.watch(selectedLevelProvider);
  final bucket = ref.watch(libraryBucketProvider);
  final query = ref.watch(librarySearchProvider);
  return storage.getLibraryEntries(
    level: level,
    bucket: bucket,
    query: query,
    limit: 500,
  );
});

final modeDeckProvider = FutureProvider<List<Word>>((ref) async {
  await ref.watch(seedingProvider.future);
  final storage = ref.read(storageServiceProvider);
  final mode = ref.watch(selectedStudyModeProvider);
  final level = ref.watch(selectedLevelProvider);
  if (mode == StudyMode.smartSwipe) return storage.getSmartDeck().words;
  return storage.getModeDeck(
    level: level,
    now: DateTime.now(),
    limit: mode == StudyMode.match ? 12 : 40,
  );
});

/// The current deck for the active study mode.
final wordDeckProvider = FutureProvider<List<Word>>((ref) async {
  await ref.watch(seedingProvider.future);
  final level = ref.watch(selectedLevelProvider);
  final mode = ref.watch(studyDeckModeProvider);
  final storage = ref.read(storageServiceProvider);
  if (mode == StudyDeckMode.smart) {
    return storage.getSmartDeck().words;
  }

  final words = mode == StudyDeckMode.reviewLeftSwiped
      ? storage.getReviewWordsByLevel(level)
      : storage.getModeDeck(level: level, now: DateTime.now());
  if (mode == StudyDeckMode.reviewLeftSwiped) {
    words.shuffle(Random());
  }
  return words.take(manualDeckSize).toList();
});
