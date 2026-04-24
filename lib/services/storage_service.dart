import 'package:hive_flutter/hive_flutter.dart';
import '../models/smart_deck.dart';
import '../models/study_constants.dart';
import '../models/word.dart';
import '../models/swipe_event.dart';
import '../models/swipe_record.dart';
import '../models/word_insight.dart';
import 'asset_service.dart';

class SwipeEventEntry {
  final SwipeEvent event;
  final Word word;
  final WordInsight insight;

  SwipeEventEntry({
    required this.event,
    required this.word,
    required this.insight,
  });
}

class RecentWordSummary {
  final Word word;
  final SwipeRecord record;
  final WordInsight insight;

  RecentWordSummary({
    required this.word,
    required this.record,
    required this.insight,
  });
}

class ReviewWordSummary {
  final Word word;
  final SwipeRecord record;
  final WordInsight insight;
  final DateTime lastLeftSwipedAt;

  ReviewWordSummary({
    required this.word,
    required this.record,
    required this.insight,
    required this.lastLeftSwipedAt,
  });
}

class StorageService {
  static const _wordsBox = 'words';
  static const _swipeBox = 'swipe_records';
  static const _swipeEventsBox = 'swipe_events';
  static const _metaBox = 'meta';
  static const _insightBox = 'word_insights';

  Box<Word> get words => Hive.box<Word>(_wordsBox);
  Box<SwipeRecord> get swipes => Hive.box<SwipeRecord>(_swipeBox);
  Box<SwipeEvent> get swipeEvents => Hive.box<SwipeEvent>(_swipeEventsBox);
  Box<dynamic> get meta => Hive.box<dynamic>(_metaBox);
  Box<WordInsight> get insights => Hive.box<WordInsight>(_insightBox);

  Future<void> seedIfNeeded(AssetService assetService,
      {void Function(double)? onProgress}) async {
    final currentWordVersion = meta.get('words_seed_version') as String?;
    if (meta.get('words_seeded') != true ||
        currentWordVersion != AssetService.wordSeedVersion) {
      final allWords = await assetService.loadAll();
      await seedWords(
        allWords,
        version: AssetService.wordSeedVersion,
      );
      await meta.put('words_seeded', true);
    }

    final currentInsightVersion = meta.get('insights_seed_version') as String?;
    if (currentInsightVersion != AssetService.insightSeedVersion) {
      final allInsights = await assetService.loadAllInsights();
      await seedInsights(
        allInsights,
        version: AssetService.insightSeedVersion,
      );
    }
    onProgress?.call(1.0);
  }

  Future<void> seedWords(
    Iterable<Word> allWords, {
    String? version,
  }) async {
    final entries = <String, Word>{};
    for (final w in allWords) {
      entries[w.id] = w;
    }
    await words.clear();
    await words.putAll(entries);
    if (version != null) {
      await meta.put('words_seed_version', version);
    }
  }

  Future<void> seedInsights(
    Iterable<WordInsight> allInsights, {
    required String version,
  }) async {
    final entries = <String, WordInsight>{};
    for (final insight in allInsights) {
      entries[insight.wordId] = insight;
    }
    await insights.clear();
    await insights.putAll(entries);
    await meta.put('insights_seed_version', version);
  }

  List<Word> getWordsByLevel(String? level) {
    if (level == null) return words.values.toList();
    return words.values.where((w) => w.cefrLevel == level).toList();
  }

  List<Word> getStudyWordsByLevel(String? level) {
    final candidates = getWordsByLevel(level);
    final withInsights = candidates.where((word) {
      final insight = insights.get(word.id);
      return insight?.hasInsight == true;
    }).toList();

    if (withInsights.isNotEmpty) {
      return withInsights;
    }
    return candidates;
  }

  List<Word> getReviewWordsByLevel(String? level) {
    return getReviewWordSummaries(level: level).map((entry) => entry.word).toList();
  }

  SmartDeck getSmartDeck({DateTime? now, int limit = smartDeckSize}) {
    final today = now ?? DateTime.now();
    final targetLevel = getTargetLevel(now: today);
    final targetIndex = cefrLevels.indexOf(targetLevel);
    final allStudyWords = getStudyWordsByLevel(null);

    final due = <Word>[];
    final currentNew = <Word>[];
    final easier = <Word>[];
    final challenge = <Word>[];

    for (final word in allStudyWords) {
      final record = swipes.get(word.id);
      final levelIndex = cefrLevels.indexOf(word.cefrLevel);
      if (record != null && record.isLearning && !record.isDue(today)) {
        continue;
      }
      if (record != null && record.isDue(today)) {
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

    due.sort(_byOldestDue);
    currentNew.sort(_byWordId);
    easier.sort(_byWordId);
    challenge.sort(_byWordId);

    final hasDue = due.isNotEmpty;
    final dueTarget = hasDue ? (limit * 0.60).round() : 0;
    final currentTarget = hasDue ? (limit * 0.30).round() : (limit * 0.70).round();
    final easierTarget = hasDue ? 0 : (limit * 0.20).round();
    final challengeTarget = limit - dueTarget - currentTarget - easierTarget;

    final selected = <Word>[];
    final selectedIds = <String>{};
    void addSome(List<Word> source, int count) {
      for (final word in source) {
        if (selected.length >= limit || count <= 0) break;
        if (selectedIds.add(word.id)) {
          selected.add(word);
          count--;
        }
      }
    }

    addSome(due, dueTarget);
    addSome(currentNew, currentTarget);
    addSome(easier.reversed.toList(), easierTarget);
    addSome(challenge, challengeTarget);
    addSome(due, limit - selected.length);
    addSome(currentNew, limit - selected.length);
    addSome(easier.reversed.toList(), limit - selected.length);
    addSome(challenge, limit - selected.length);

    final smartStats = getSmartStats(now: today);
    return SmartDeck(
      words: selected,
      metrics: SmartDeckMetrics(
        targetLevel: targetLevel,
        dueReviewCount: smartStats.dueReviewCount,
        learningCount: smartStats.learningCount,
        knowCount: smartStats.knowCount,
        newCount: smartStats.newCount,
        totalCount: selected.length,
      ),
    );
  }

  SmartDeckMetrics getSmartStats({DateTime? now}) {
    final today = now ?? DateTime.now();
    var dueCount = 0;
    var learningCount = 0;
    var knowCount = 0;
    var newCount = 0;

    for (final word in words.values) {
      final record = swipes.get(word.id);
      if (record == null || !record.isSeen) {
        newCount++;
        continue;
      }
      if (record.isFamiliar) knowCount++;
      if (record.isLearning) {
        learningCount++;
        if (record.isDue(today)) dueCount++;
      }
    }

    return SmartDeckMetrics(
      targetLevel: getTargetLevel(now: today),
      dueReviewCount: dueCount,
      learningCount: learningCount,
      knowCount: knowCount,
      newCount: newCount,
      totalCount: words.length,
    );
  }

  String getTargetLevel({DateTime? now}) {
    final recent = swipeEvents.values.toList()
      ..sort((a, b) => b.swipedAt.compareTo(a.swipedAt));
    final lastThirty = recent.take(30).toList();
    final recentLeftRatio = lastThirty.isEmpty
        ? 0.0
        : lastThirty.where((event) => event.direction == swipeDirectionNew).length /
            lastThirty.length;

    var levelIndex = 0;
    for (var i = 0; i < cefrLevels.length; i++) {
      final level = cefrLevels[i];
      final levelWords = words.values.where((word) => word.cefrLevel == level);
      var seen = 0;
      var right = 0;
      var totalSwipes = 0;
      for (final word in levelWords) {
        final record = swipes.get(word.id);
        if (record == null || !record.isSeen) continue;
        seen++;
        right += record.rightCount;
        totalSwipes += record.totalSwipes;
      }
      final ratio = totalSwipes == 0 ? 0.0 : right / totalSwipes;
      if (seen >= 30 && ratio >= 0.75 && i < cefrLevels.length - 1) {
        levelIndex = i + 1;
      }
    }

    if (recentLeftRatio >= 0.45 && levelIndex > 0) {
      levelIndex--;
    }
    return cefrLevels[levelIndex];
  }

  WordInsight getInsight(String wordId) {
    return insights.get(wordId) ?? WordInsight.empty(wordId);
  }

  SwipeRecord getOrCreateRecord(String wordId) {
    return swipes.get(wordId) ?? SwipeRecord(wordId: wordId);
  }

  Future<void> recordSwipe(
    String wordId,
    String direction, {
    required String inputSource,
    DateTime? swipedAt,
  }) async {
    final record = getOrCreateRecord(wordId);
    final eventTime = swipedAt ?? DateTime.now();
    if (direction == swipeDirectionKnow) {
      record.rightCount++;
      record.consecutiveKnowCount++;
      if (record.isLearning || record.dueAt != null) {
        record.srsStep = (record.srsStep + 1).clamp(1, srsIntervals.length);
        record.dueAt = eventTime.add(srsIntervals[record.srsStep - 1]);
      }
    } else {
      record.leftCount++;
      record.consecutiveKnowCount = 0;
      record.srsStep = 0;
      record.newMarkedAt ??= eventTime;
      record.dueAt = eventTime.add(srsIntervals.first);
    }
    record.lastDirection = direction;
    record.lastSwipedAt = eventTime;

    final event = SwipeEvent(
      id: '${eventTime.microsecondsSinceEpoch}_${wordId}_$direction',
      wordId: wordId,
      direction: direction,
      swipedAt: eventTime,
      inputSource: inputSource,
    );

    await Future.wait([
      swipes.put(wordId, record),
      swipeEvents.put(event.id, event),
    ]);
  }

  List<SwipeEventEntry> getSwipeEventEntries({
    String? level,
    int? limit,
  }) {
    final events = swipeEvents.values.toList()
      ..sort((a, b) => b.swipedAt.compareTo(a.swipedAt));

    final out = <SwipeEventEntry>[];
    for (final event in events) {
      final word = words.get(event.wordId);
      if (word == null) continue;
      if (level != null && word.cefrLevel != level) continue;
      out.add(
        SwipeEventEntry(
          event: event,
          word: word,
          insight: getInsight(word.id),
        ),
      );
      if (limit != null && out.length >= limit) break;
    }
    return out;
  }

  List<RecentWordSummary> getRecentWordSummaries({
    String? level,
    int? limit,
  }) {
    final records = swipes.values
        .where((record) => record.lastSwipedAt != null)
        .toList()
      ..sort(
        (a, b) => b.lastSwipedAt!.compareTo(a.lastSwipedAt!),
      );

    final out = <RecentWordSummary>[];
    for (final record in records) {
      final word = words.get(record.wordId);
      if (word == null) continue;
      if (level != null && word.cefrLevel != level) continue;
      out.add(
        RecentWordSummary(
          word: word,
          record: record,
          insight: getInsight(word.id),
        ),
      );
      if (limit != null && out.length >= limit) break;
    }
    return out;
  }

  List<ReviewWordSummary> getReviewWordSummaries({
    String? level,
    int? limit,
  }) {
    final latestLeftByWord = <String, DateTime>{};

    for (final event in swipeEvents.values) {
      if (event.direction != 'left') continue;
      final current = latestLeftByWord[event.wordId];
      if (current == null || event.swipedAt.isAfter(current)) {
        latestLeftByWord[event.wordId] = event.swipedAt;
      }
    }

    for (final record in swipes.values) {
      if (record.leftCount <= 0 || latestLeftByWord.containsKey(record.wordId)) {
        continue;
      }
      latestLeftByWord[record.wordId] =
          record.lastSwipedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    }

    final entries = <ReviewWordSummary>[];
    for (final item in latestLeftByWord.entries) {
      final word = words.get(item.key);
      final record = swipes.get(item.key);
      if (word == null || record == null) continue;
      if (level != null && word.cefrLevel != level) continue;
      entries.add(
        ReviewWordSummary(
          word: word,
          record: record,
          insight: getInsight(word.id),
          lastLeftSwipedAt: item.value,
        ),
      );
    }

    entries.sort((a, b) => b.lastLeftSwipedAt.compareTo(a.lastLeftSwipedAt));
    if (limit != null && entries.length > limit) {
      return entries.take(limit).toList();
    }
    return entries;
  }

  Map<String, Map<String, int>> getStats() {
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

  int _byOldestDue(Word a, Word b) {
    final aDue = swipes.get(a.id)?.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bDue = swipes.get(b.id)?.dueAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return aDue.compareTo(bDue);
  }

  int _byWordId(Word a, Word b) => a.id.compareTo(b.id);
}
