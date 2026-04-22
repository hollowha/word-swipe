import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:word_swipe/models/swipe_event.dart';
import 'package:word_swipe/models/swipe_record.dart';
import 'package:word_swipe/models/word.dart';
import 'package:word_swipe/models/word_insight.dart';
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
}
