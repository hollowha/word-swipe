import 'package:hive_flutter/hive_flutter.dart';
import '../models/smart_deck.dart';
import '../models/study_constants.dart';
import '../models/progress_bucket.dart';
import '../models/word.dart';
import '../models/swipe_event.dart';
import '../models/swipe_record.dart';
import '../models/word_insight.dart';
import 'asset_service.dart';
import 'smart_deck_engine.dart';

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

class LevelProgressStats {
  final String level;
  final int total;
  final int unseen;
  final int newCount;
  final int learning;
  final int know;
  final int due;
  final int mastered;

  const LevelProgressStats({
    required this.level,
    required this.total,
    required this.unseen,
    required this.newCount,
    required this.learning,
    required this.know,
    required this.due,
    required this.mastered,
  });

  int get learned => total - unseen;

  Map<String, int> toMap() => {
        'total': total,
        'unseen': unseen,
        'new': newCount,
        'learning': learning,
        'know': know,
        'due': due,
        'mastered': mastered,
        'learned': learned,
      };
}

class LibraryWordEntry {
  final Word word;
  final SwipeRecord? record;
  final WordInsight insight;
  final ProgressBucket bucket;

  const LibraryWordEntry({
    required this.word,
    required this.record,
    required this.insight,
    required this.bucket,
  });
}

class StorageService {
  final SmartDeckEngine _smartDeckEngine;

  StorageService({SmartDeckEngine? smartDeckEngine})
      : _smartDeckEngine = smartDeckEngine ?? SmartDeckEngine();

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

  bool get hasPlacement => meta.get('placement_completed') == true;
  String? get placementLevel => meta.get('placement_level') as String?;

  Future<void> setPlacementLevel(String level) async {
    await Future.wait([
      meta.put('placement_level', level),
      meta.put('placement_completed', true),
    ]);
  }

  Future<void> resetPlacement() async {
    await Future.wait([
      meta.delete('placement_level'),
      meta.put('placement_completed', false),
    ]);
  }

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
    final allStudyWords = getStudyWordsByLevel(null);
    final records = {for (final record in swipes.values) record.wordId: record};
    final items = _smartDeckEngine.buildItems(
      studyWords: allStudyWords,
      records: records,
      targetLevel: targetLevel,
      now: today,
      limit: limit,
    );
    final nextIndex = (cefrLevels.indexOf(targetLevel) + 1)
        .clamp(0, cefrLevels.length - 1);
    final guidance = _smartDeckEngine.guidance(
      events: swipeEvents.values,
      wordsById: {for (final word in words.values) word.id: word},
      targetLevel: targetLevel,
    );

    final smartStats = getSmartStats(now: today);
    return SmartDeck(
      items: items,
      metrics: SmartDeckMetrics(
        targetLevel: targetLevel,
        nextLevel: cefrLevels[nextIndex],
        guidance: guidance,
        dueReviewCount: smartStats.dueReviewCount,
        learningCount: smartStats.learningCount,
        knowCount: smartStats.knowCount,
        newCount: smartStats.newCount,
        totalCount: items.length,
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
      nextLevel: _nextLevel(getTargetLevel(now: today)),
      guidance: _smartDeckEngine.guidance(
        events: swipeEvents.values,
        wordsById: {for (final word in words.values) word.id: word},
        targetLevel: getTargetLevel(now: today),
      ),
      dueReviewCount: dueCount,
      learningCount: learningCount,
      knowCount: knowCount,
      newCount: newCount,
      totalCount: words.length,
    );
  }

  String getTargetLevel({DateTime? now}) {
    return _smartDeckEngine.targetLevel(
      words: words.values,
      records: {for (final record in swipes.values) record.wordId: record},
      events: swipeEvents.values,
      fallbackLevel: placementLevel ?? 'A1',
    );
  }

  List<Word> getModeDeck({
    required String? level,
    required DateTime now,
    int limit = manualDeckSize,
  }) {
    final candidates = getStudyWordsByLevel(level);
    candidates.sort((a, b) => _dailyRank(a, now).compareTo(_dailyRank(b, now)));
    return candidates.take(limit).toList();
  }

  List<Word> getPlacementDeck({DateTime? now, int limit = 24}) {
    final today = now ?? DateTime.now();
    final samples = <Word>[];
    final perLevel = (limit / 5).ceil();
    for (final level in const ['A1', 'A2', 'B1', 'B2', 'C1']) {
      final levelWords = getStudyWordsByLevel(level)
        ..sort((a, b) => _dailyRank(a, today).compareTo(_dailyRank(b, today)));
      samples.addAll(levelWords.take(perLevel));
    }
    samples.sort((a, b) => _dailyRank(a, today.add(const Duration(days: 7)))
        .compareTo(_dailyRank(b, today.add(const Duration(days: 7)))));
    return samples.take(limit).toList();
  }

  String estimatePlacementLevel(Map<String, List<bool>> answersByLevel) {
    var selected = 'A1';
    for (final level in const ['A1', 'A2', 'B1', 'B2', 'C1']) {
      final answers = answersByLevel[level] ?? const <bool>[];
      if (answers.isEmpty) break;
      final knowRatio = answers.where((answer) => answer).length / answers.length;
      if (knowRatio >= 0.7) {
        selected = _nextLevel(level);
      } else if (knowRatio >= 0.45) {
        selected = level;
      } else {
        break;
      }
    }
    return selected;
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

  Map<String, LevelProgressStats> getProgressStats({DateTime? now}) {
    final today = now ?? DateTime.now();
    final result = <String, LevelProgressStats>{};
    for (final level in cefrLevels) {
      var total = 0;
      var unseen = 0;
      var newCount = 0;
      var learning = 0;
      var know = 0;
      var due = 0;
      var mastered = 0;

      for (final word in words.values.where((word) => word.cefrLevel == level)) {
        total++;
        final bucket = progressBucketFor(swipes.get(word.id), today);
        switch (bucket) {
          case ProgressBucket.unseen:
            unseen++;
            break;
          case ProgressBucket.newWord:
            newCount++;
            break;
          case ProgressBucket.learning:
            learning++;
            break;
          case ProgressBucket.know:
            know++;
            break;
          case ProgressBucket.due:
            due++;
            break;
          case ProgressBucket.mastered:
            mastered++;
            break;
          case ProgressBucket.all:
            break;
        }
      }

      result[level] = LevelProgressStats(
        level: level,
        total: total,
        unseen: unseen,
        newCount: newCount,
        learning: learning,
        know: know,
        due: due,
        mastered: mastered,
      );
    }
    return result;
  }

  List<LibraryWordEntry> getLibraryEntries({
    String? level,
    ProgressBucket bucket = ProgressBucket.all,
    String query = '',
    DateTime? now,
    int? limit,
  }) {
    final today = now ?? DateTime.now();
    final needle = query.trim().toLowerCase();
    final entries = <LibraryWordEntry>[];

    for (final word in words.values) {
      if (level != null && word.cefrLevel != level) continue;
      if (needle.isNotEmpty && !word.word.toLowerCase().contains(needle)) {
        final insight = getInsight(word.id);
        if (!insight.definition.toLowerCase().contains(needle)) continue;
      }
      final record = swipes.get(word.id);
      final entryBucket = progressBucketFor(record, today);
      if (bucket != ProgressBucket.all && entryBucket != bucket) continue;
      entries.add(
        LibraryWordEntry(
          word: word,
          record: record,
          insight: getInsight(word.id),
          bucket: entryBucket,
        ),
      );
    }

    entries.sort((a, b) {
      final levelCompare =
          cefrLevels.indexOf(a.word.cefrLevel).compareTo(cefrLevels.indexOf(b.word.cefrLevel));
      if (levelCompare != 0) return levelCompare;
      final rankA = a.word.frequencyRank <= 0 ? 999999 : a.word.frequencyRank;
      final rankB = b.word.frequencyRank <= 0 ? 999999 : b.word.frequencyRank;
      final rankCompare = rankA.compareTo(rankB);
      if (rankCompare != 0) return rankCompare;
      return a.word.word.compareTo(b.word.word);
    });

    if (limit != null && entries.length > limit) {
      return entries.take(limit).toList();
    }
    return entries;
  }

  String _nextLevel(String level) {
    final index = cefrLevels.indexOf(level);
    if (index < 0 || index >= cefrLevels.length - 1) return level;
    return cefrLevels[index + 1];
  }

  int _dailyRank(Word word, DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    var hash = day.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    for (final unit in word.id.codeUnits) {
      hash = ((hash << 5) - hash + unit) & 0x7fffffff;
    }
    return hash;
  }
}
