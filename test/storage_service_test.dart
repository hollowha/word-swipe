import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:word_swipe/models/swipe_event.dart';
import 'package:word_swipe/models/swipe_record.dart';
import 'package:word_swipe/models/word.dart';
import 'package:word_swipe/models/word_insight.dart';
import 'package:word_swipe/models/progress_bucket.dart';
import 'package:word_swipe/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WordAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SwipeRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(WordInsightAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SwipeEventAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('word_swipe_storage_test');
    Hive.init(tempDir.path);
    await Future.wait([
      Hive.openBox<Word>('words'),
      Hive.openBox<SwipeRecord>('swipe_records'),
      Hive.openBox<SwipeEvent>('swipe_events'),
      Hive.openBox<WordInsight>('word_insights'),
      Hive.openBox<dynamic>('meta'),
    ]);
    storage = StorageService();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('seedInsights replaces existing insight data without touching words', () async {
    await storage.seedWords([
      Word(id: 'alpha', word: 'alpha', cefrLevel: 'A1'),
      Word(id: 'beta', word: 'beta', cefrLevel: 'A1'),
    ]);

    await storage.seedInsights(
      const [
        WordInsight(
          wordId: 'alpha',
          definition: 'old alpha definition',
          hasInsight: true,
        ),
      ],
      version: 'v0',
    );

    await storage.seedInsights(
      const [
        WordInsight(
          wordId: 'beta',
          definition: 'new beta definition',
          hasInsight: true,
        ),
      ],
      version: 'v1',
    );

    expect(storage.words.length, 2);
    expect(storage.insights.length, 1);
    expect(storage.getInsight('alpha').definition, isEmpty);
    expect(storage.getInsight('beta').definition, 'new beta definition');
    expect(storage.meta.get('insights_seed_version'), 'v1');
  });

  test('word insight sorts morphemes by root prefix suffix', () {
    final insight = WordInsight.fromJson({
      'wordId': 'compose',
      'hasInsight': true,
      'morphemes': [
        {
          'kind': 'suffix',
          'form': '-ose',
          'meaning': 'chemical compound',
          'themeCategory': 'Science',
          'matchedWord': 'compose',
        },
        {
          'kind': 'prefix',
          'form': 'com-',
          'meaning': 'with; together',
          'themeCategory': 'Connection',
          'matchedWord': 'compose',
        },
        {
          'kind': 'root',
          'form': 'pos',
          'meaning': 'put; place',
          'themeCategory': 'Action',
          'matchedWord': 'compose',
        },
      ],
    });

    expect(
      insight.morphemes.map((hint) => hint.kind).toList(),
      ['root', 'prefix', 'suffix'],
    );
  });

  test('getStudyWordsByLevel prefers words with offline insight', () async {
    await storage.seedWords([
      Word(id: 'alpha', word: 'alpha', cefrLevel: 'A1'),
      Word(id: 'beta', word: 'beta', cefrLevel: 'A1'),
      Word(id: 'gamma', word: 'gamma', cefrLevel: 'A1'),
    ]);

    await storage.seedInsights(
      const [
        WordInsight(
          wordId: 'alpha',
          definition: 'has definition',
          hasInsight: true,
        ),
        WordInsight(
          wordId: 'gamma',
          morphemesRaw: [
            {
              'kind': 'root',
              'form': 'gam',
              'meaning': 'marriage',
              'themeCategory': 'Social',
              'matchedWord': 'gamma',
            },
          ],
          hasInsight: true,
        ),
      ],
      version: 'v2',
    );

    final studyWords = storage.getStudyWordsByLevel('A1');
    expect(studyWords.map((word) => word.id).toSet(), {'alpha', 'gamma'});
  });

  test('recordSwipe stores events and keeps left-swiped words in review history', () async {
    await storage.seedWords([
      Word(id: 'alpha', word: 'alpha', cefrLevel: 'A1'),
      Word(id: 'beta', word: 'beta', cefrLevel: 'B1'),
    ]);

    await storage.seedInsights(
      const [
        WordInsight(
          wordId: 'alpha',
          definition: 'first letter',
          hasInsight: true,
        ),
        WordInsight(
          wordId: 'beta',
          definition: 'second test word',
          hasInsight: true,
        ),
      ],
      version: 'v3',
    );

    await storage.recordSwipe('alpha', 'left', inputSource: 'gesture');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await storage.recordSwipe('beta', 'right', inputSource: 'button');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await storage.recordSwipe('alpha', 'right', inputSource: 'button');

    final events = storage.getSwipeEventEntries();
    expect(events, hasLength(3));
    expect(events.first.word.id, 'alpha');
    expect(events.first.event.direction, 'right');
    expect(events.first.event.inputSource, 'button');
    expect(events.last.word.id, 'alpha');
    expect(events.last.event.direction, 'left');

    final recentWords = storage.getRecentWordSummaries();
    expect(recentWords, hasLength(2));
    expect(recentWords.first.word.id, 'alpha');
    expect(recentWords.first.record.lastDirection, 'right');
    expect(recentWords.first.record.leftCount, 1);
    expect(recentWords.first.record.rightCount, 1);
    expect(recentWords[1].word.id, 'beta');

    final reviewWords = storage.getReviewWordSummaries();
    expect(reviewWords, hasLength(1));
    expect(reviewWords.single.word.id, 'alpha');
    expect(reviewWords.single.record.leftCount, 1);
    expect(reviewWords.single.record.rightCount, 1);

    final reviewWordIds = storage.getReviewWordsByLevel('A1').map((word) => word.id);
    expect(reviewWordIds, ['alpha']);
    expect(storage.getReviewWordsByLevel('B1'), isEmpty);
  });

  test('left swipe schedules a new word for spaced repetition', () async {
    final now = DateTime(2026, 4, 25, 9);
    await storage.seedWords([
      Word(id: 'alpha', word: 'alpha', cefrLevel: 'A1'),
    ]);

    await storage.recordSwipe(
      'alpha',
      'left',
      inputSource: 'gesture',
      swipedAt: now,
    );

    final record = storage.getOrCreateRecord('alpha');
    expect(record.srsStep, 0);
    expect(record.newMarkedAt, now);
    expect(record.dueAt, now.add(const Duration(days: 1)));
  });

  test('smart deck prioritizes due reviews and skips learning words not due', () async {
    final now = DateTime(2026, 4, 25, 9);
    await storage.seedWords([
      Word(id: 'due', word: 'due', cefrLevel: 'A1'),
      Word(id: 'later', word: 'later', cefrLevel: 'A1'),
      Word(id: 'fresh', word: 'fresh', cefrLevel: 'A1'),
    ]);

    await storage.seedInsights(
      const [
        WordInsight(wordId: 'due', definition: 'ready', hasInsight: true),
        WordInsight(wordId: 'later', definition: 'wait', hasInsight: true),
        WordInsight(wordId: 'fresh', definition: 'new', hasInsight: true),
      ],
      version: 'smart-test',
    );

    await storage.recordSwipe(
      'due',
      'left',
      inputSource: 'gesture',
      swipedAt: now.subtract(const Duration(days: 2)),
    );
    await storage.recordSwipe(
      'later',
      'left',
      inputSource: 'gesture',
      swipedAt: now,
    );

    final smartDeck = storage.getSmartDeck(now: now, limit: 3);
    expect(smartDeck.words.first.id, 'due');
    expect(smartDeck.words.map((word) => word.id), isNot(contains('later')));
    expect(smartDeck.metrics.dueReviewCount, 1);
    expect(smartDeck.metrics.learningCount, 2);
  });

  test('smart deck fresh words use stable daily weighted shuffle', () async {
    final now = DateTime(2026, 4, 25, 9);
    final words = List.generate(
      16,
      (index) => Word(
        id: 'word_${index.toString().padLeft(2, '0')}',
        word: 'word${index.toString().padLeft(2, '0')}',
        cefrLevel: 'A1',
        frequencyRank: index + 1,
      ),
    );
    await storage.seedWords(words);
    await storage.seedInsights(
      [
        for (final word in words)
          WordInsight(wordId: word.id, definition: word.word, hasInsight: true),
      ],
      version: 'shuffle-test',
    );

    final first = storage.getSmartDeck(now: now, limit: 8).words.map((word) => word.id).toList();
    final second = storage.getSmartDeck(now: now, limit: 8).words.map((word) => word.id).toList();
    final tomorrow = storage
        .getSmartDeck(now: now.add(const Duration(days: 1)), limit: 8)
        .words
        .map((word) => word.id)
        .toList();

    expect(first, second);
    expect(first, isNot(words.take(8).map((word) => word.id).toList()));
    expect(first, isNot(tomorrow));
  });

  test('progress stats expose unseen new learning due know and mastered buckets', () async {
    final now = DateTime(2026, 4, 25, 9);
    await storage.seedWords([
      Word(id: 'unseen', word: 'unseen', cefrLevel: 'A1'),
      Word(id: 'new', word: 'new', cefrLevel: 'A1'),
      Word(id: 'learning', word: 'learning', cefrLevel: 'A1'),
      Word(id: 'due', word: 'due', cefrLevel: 'A1'),
      Word(id: 'know', word: 'know', cefrLevel: 'A1'),
      Word(id: 'mastered', word: 'mastered', cefrLevel: 'A1'),
    ]);

    await storage.swipes.putAll({
      'new': SwipeRecord(wordId: 'new', leftCount: 1, srsStep: 0),
      'learning': SwipeRecord(
        wordId: 'learning',
        leftCount: 1,
        srsStep: 1,
        dueAt: now.add(const Duration(days: 1)),
      ),
      'due': SwipeRecord(
        wordId: 'due',
        leftCount: 1,
        srsStep: 1,
        dueAt: now.subtract(const Duration(hours: 1)),
      ),
      'know': SwipeRecord(wordId: 'know', rightCount: 1),
      'mastered': SwipeRecord(
        wordId: 'mastered',
        rightCount: 5,
        srsStep: 5,
        consecutiveKnowCount: 3,
      ),
    });

    final stats = storage.getProgressStats(now: now)['A1']!;
    expect(stats.unseen, 1);
    expect(stats.newCount, 1);
    expect(stats.learning, 1);
    expect(stats.due, 1);
    expect(stats.know, 1);
    expect(stats.mastered, 1);

    final dueEntries = storage.getLibraryEntries(
      level: 'A1',
      bucket: ProgressBucket.due,
      now: now,
    );
    expect(dueEntries.map((entry) => entry.word.id), ['due']);
  });

  test('smart deck moves to the next level after enough strong A1 swipes', () async {
    final now = DateTime(2026, 4, 25, 9);
    final a1Words = List.generate(
      31,
      (index) => Word(id: 'a1_$index', word: 'a1_$index', cefrLevel: 'A1'),
    );
    final a2Words = List.generate(
      3,
      (index) => Word(id: 'a2_$index', word: 'a2_$index', cefrLevel: 'A2'),
    );
    await storage.seedWords([...a1Words, ...a2Words]);
    await storage.seedInsights(
      [
        for (final word in [...a1Words, ...a2Words])
          WordInsight(wordId: word.id, definition: word.word, hasInsight: true),
      ],
      version: 'promotion-test',
    );

    for (final word in a1Words) {
      await storage.recordSwipe(
        word.id,
        'right',
        inputSource: 'button',
        swipedAt: now,
      );
    }

    final smartDeck = storage.getSmartDeck(now: now, limit: 10);
    expect(smartDeck.metrics.targetLevel, 'A2');
    expect(smartDeck.words.map((word) => word.cefrLevel).toSet(), contains('A2'));
  });

  test('smart level promotes from A2 to B1 after rolling KNOW streak', () async {
    final now = DateTime(2026, 4, 25, 9);
    final a2Words = List.generate(
      12,
      (index) => Word(id: 'a2_roll_$index', word: 'a2_roll_$index', cefrLevel: 'A2'),
    );
    final b1Words = List.generate(
      4,
      (index) => Word(id: 'b1_roll_$index', word: 'b1_roll_$index', cefrLevel: 'B1'),
    );
    await storage.seedWords([
      ...List.generate(
        12,
        (index) => Word(id: 'a1_done_$index', word: 'a1_done_$index', cefrLevel: 'A1'),
      ),
      ...a2Words,
      ...b1Words,
    ]);
    await storage.seedInsights(
      [
        for (final word in storage.words.values)
          WordInsight(wordId: word.id, definition: word.word, hasInsight: true),
      ],
      version: 'rolling-test',
    );

    for (final word in storage.words.values.where((word) => word.cefrLevel == 'A1')) {
      await storage.recordSwipe(word.id, 'right', inputSource: 'button', swipedAt: now);
    }
    for (var i = 0; i < a2Words.length; i++) {
      await storage.recordSwipe(
        a2Words[i].id,
        i < 9 ? 'right' : 'left',
        inputSource: 'button',
        swipedAt: now.add(Duration(minutes: i)),
      );
    }

    final smartDeck = storage.getSmartDeck(now: now, limit: 8);
    expect(smartDeck.metrics.targetLevel, 'B1');
    expect(smartDeck.metrics.guidance, contains('B1'));
  });

  test('smart level backs off when recent NEW count is high', () async {
    final now = DateTime(2026, 4, 25, 9);
    final a1Words = List.generate(
      12,
      (index) => Word(id: 'a1_easy_$index', word: 'a1_easy_$index', cefrLevel: 'A1'),
    );
    final a2Words = List.generate(
      8,
      (index) => Word(id: 'a2_hard_$index', word: 'a2_hard_$index', cefrLevel: 'A2'),
    );
    await storage.seedWords([...a1Words, ...a2Words]);
    await storage.seedInsights(
      [
        for (final word in [...a1Words, ...a2Words])
          WordInsight(wordId: word.id, definition: word.word, hasInsight: true),
      ],
      version: 'backoff-test',
    );
    for (final word in a1Words) {
      await storage.recordSwipe(word.id, 'right', inputSource: 'button', swipedAt: now);
    }
    for (var i = 0; i < a2Words.length; i++) {
      await storage.recordSwipe(
        a2Words[i].id,
        i < 4 ? 'left' : 'right',
        inputSource: 'button',
        swipedAt: now.add(Duration(minutes: i)),
      );
    }

    expect(storage.getTargetLevel(now: now), 'A1');
  });
}
