import '../models/smart_deck.dart';
import '../models/study_constants.dart';
import '../models/swipe_event.dart';
import '../models/swipe_record.dart';
import '../models/word.dart';

class SmartDeckEngine {
  String targetLevel({
    required Iterable<Word> words,
    required Map<String, SwipeRecord> records,
    required Iterable<SwipeEvent> events,
    String fallbackLevel = 'A1',
  }) {
    final byId = {for (final word in words) word.id: word};
    var levelIndex = cefrLevels.indexOf(fallbackLevel);
    if (levelIndex < 0) levelIndex = 0;

    for (var i = 0; i < cefrLevels.length - 1; i++) {
      final level = cefrLevels[i];
      final recent = _recentForLevel(events, byId, level, 12);
      final recentKnow = recent
          .where((event) => event.direction == swipeDirectionKnow)
          .length;
      final seenCount = words.where((word) {
        final record = records[word.id];
        return word.cefrLevel == level && record != null && record.isSeen;
      }).length;
      final levelSwipes = words.fold<int>(0, (sum, word) {
        final record = records[word.id];
        if (word.cefrLevel != level || record == null) return sum;
        return sum + record.totalSwipes;
      });
      final levelKnow = words.fold<int>(0, (sum, word) {
        final record = records[word.id];
        if (word.cefrLevel != level || record == null) return sum;
        return sum + record.rightCount;
      });
      final ratio = levelSwipes == 0 ? 0.0 : levelKnow / levelSwipes;
      final shouldPromote =
          (recent.length >= 12 && recentKnow >= 9) || (seenCount >= 12 && ratio >= 0.78);
      if (shouldPromote) {
        levelIndex = i + 1;
      }
    }

    final currentLevel = cefrLevels[levelIndex];
    final recentCurrent = _recentForLevel(events, byId, currentLevel, 8);
    final recentNew = recentCurrent
        .where((event) => event.direction == swipeDirectionNew)
        .length;
    if (recentCurrent.length >= 8 && recentNew >= 4 && levelIndex > 0) {
      levelIndex--;
    }
    return cefrLevels[levelIndex];
  }

  String guidance({
    required Iterable<SwipeEvent> events,
    required Map<String, Word> wordsById,
    required String targetLevel,
  }) {
    final recent = _recentForLevel(events, wordsById, targetLevel, 8);
    final newCount =
        recent.where((event) => event.direction == swipeDirectionNew).length;
    final knowCount =
        recent.where((event) => event.direction == swipeDirectionKnow).length;
    if (recent.length >= 8 && newCount >= 4) return 'Adjusting easier';
    if (recent.length >= 8 && knowCount >= 6) {
      final nextIndex = cefrLevels.indexOf(targetLevel) + 1;
      if (nextIndex < cefrLevels.length) {
        return 'Current path: $targetLevel -> ${cefrLevels[nextIndex]}';
      }
    }
    return 'Current path: $targetLevel';
  }

  List<SmartDeckItem> buildItems({
    required List<Word> studyWords,
    required Map<String, SwipeRecord> records,
    required String targetLevel,
    required DateTime now,
    int limit = smartDeckSize,
  }) {
    final targetIndex = cefrLevels.indexOf(targetLevel);
    final due = <Word>[];
    final currentNew = <Word>[];
    final easier = <Word>[];
    final challenge = <Word>[];

    for (final word in studyWords) {
      final record = records[word.id];
      final levelIndex = cefrLevels.indexOf(word.cefrLevel);
      if (record != null && record.isLearning && !record.isDue(now)) continue;
      if (record != null && record.isDue(now)) {
        due.add(word);
        continue;
      }
      if (record?.isSeen == true) continue;
      if (levelIndex == targetIndex) {
        currentNew.add(word);
      } else if (levelIndex >= 0 && levelIndex < targetIndex) {
        easier.add(word);
      } else if (levelIndex == targetIndex + 1) {
        challenge.add(word);
      }
    }

    due.sort((a, b) => _dueAt(records, a).compareTo(_dueAt(records, b)));
    currentNew.sort(_byWordId);
    easier.sort(_byWordId);
    challenge.sort(_byWordId);

    final items = <SmartDeckItem>[];
    final ids = <String>{};
    void addSome(List<Word> source, int count, SmartDeckReason reason) {
      for (final word in source) {
        if (items.length >= limit || count <= 0) break;
        if (ids.add(word.id)) {
          items.add(SmartDeckItem(word: word, reason: reason));
          count--;
        }
      }
    }

    addSome(due, 4, SmartDeckReason.dueReview);
    addSome(currentNew, 5, SmartDeckReason.currentLevel);
    addSome(challenge, 2, SmartDeckReason.challenge);
    addSome(easier.reversed.toList(), 1, SmartDeckReason.warmUp);
    addSome(due, limit - items.length, SmartDeckReason.dueReview);
    addSome(currentNew, limit - items.length, SmartDeckReason.currentLevel);
    addSome(challenge, limit - items.length, SmartDeckReason.challenge);
    addSome(easier.reversed.toList(), limit - items.length, SmartDeckReason.warmUp);
    return items;
  }

  List<SwipeEvent> _recentForLevel(
    Iterable<SwipeEvent> events,
    Map<String, Word> wordsById,
    String level,
    int limit,
  ) {
    final sorted = events.where((event) {
      final word = wordsById[event.wordId];
      return word?.cefrLevel == level;
    }).toList()
      ..sort((a, b) => b.swipedAt.compareTo(a.swipedAt));
    return sorted.take(limit).toList();
  }

  DateTime _dueAt(Map<String, SwipeRecord> records, Word word) =>
      records[word.id]?.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  int _byWordId(Word a, Word b) => a.id.compareTo(b.id);
}
