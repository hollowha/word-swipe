import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/word.dart';
import '../services/asset_service.dart';
import '../services/storage_service.dart';

final assetServiceProvider = Provider<AssetService>((ref) => AssetService());

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

/// null = all levels
final selectedLevelProvider = StateProvider<String?>((ref) => 'A1');

/// Whether seeding is complete
final seedingProvider = FutureProvider<void>((ref) async {
  final storage = ref.read(storageServiceProvider);
  final assets = ref.read(assetServiceProvider);
  await storage.seedIfNeeded(assets);
});

/// The current shuffled deck (up to 200 cards), depends on selected level
final wordDeckProvider = FutureProvider<List<Word>>((ref) async {
  await ref.watch(seedingProvider.future);
  final level = ref.watch(selectedLevelProvider);
  final storage = ref.read(storageServiceProvider);
  final words = storage.getWordsByLevel(level);
  words.shuffle(Random());
  return words.take(200).toList();
});
