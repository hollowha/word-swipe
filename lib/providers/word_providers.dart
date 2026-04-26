import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/smart_deck.dart';
import '../models/study_constants.dart';
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
      : storage.getStudyWordsByLevel(level);
  words.shuffle(Random());
  return words.take(manualDeckSize).toList();
});
