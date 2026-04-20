import 'package:hive_flutter/hive_flutter.dart';
import '../models/word.dart';
import '../models/swipe_record.dart';
import 'asset_service.dart';

class StorageService {
  static const _wordsBox = 'words';
  static const _swipeBox = 'swipe_records';
  static const _metaBox = 'meta';

  Box<Word> get words => Hive.box<Word>(_wordsBox);
  Box<SwipeRecord> get swipes => Hive.box<SwipeRecord>(_swipeBox);
  Box<dynamic> get meta => Hive.box<dynamic>(_metaBox);

  Future<void> seedIfNeeded(AssetService assetService,
      {void Function(double)? onProgress}) async {
    if (meta.get('words_seeded') == true) return;

    final allWords = await assetService.loadAll();
    final entries = <String, Word>{};
    for (final w in allWords) {
      entries[w.id] = w;
    }
    await words.putAll(entries);
    await meta.put('words_seeded', true);
    onProgress?.call(1.0);
  }

  List<Word> getWordsByLevel(String? level) {
    if (level == null) return words.values.toList();
    return words.values.where((w) => w.cefrLevel == level).toList();
  }

  SwipeRecord getOrCreateRecord(String wordId) {
    return swipes.get(wordId) ?? SwipeRecord(wordId: wordId);
  }

  Future<void> recordSwipe(String wordId, String direction) async {
    final record = getOrCreateRecord(wordId);
    if (direction == 'right') {
      record.rightCount++;
    } else {
      record.leftCount++;
    }
    record.lastDirection = direction;
    record.lastSwipedAt = DateTime.now();
    await swipes.put(wordId, record);
  }

  Map<String, dynamic> getStats() {
    final allWords = words.values.toList();
    final result = <String, Map<String, int>>{};
    for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']) {
      final levelWords = allWords.where((w) => w.cefrLevel == level).toList();
      int familiar = 0;
      int seen = 0;
      for (final w in levelWords) {
        final r = swipes.get(w.id);
        if (r != null && r.isSeen) {
          seen++;
          if (r.isFamiliar) familiar++;
        }
      }
      result[level] = {
        'total': levelWords.length,
        'seen': seen,
        'familiar': familiar,
      };
    }
    return result;
  }
}
