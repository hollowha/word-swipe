import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_swipe/models/smart_deck.dart';
import 'package:word_swipe/models/game_progress.dart';
import 'package:word_swipe/models/progress_bucket.dart';
import 'package:word_swipe/models/study_mode.dart';
import 'package:word_swipe/models/word.dart';
import 'package:word_swipe/models/word_insight.dart';
import 'package:word_swipe/screens/mode_hub_screen.dart';
import 'package:word_swipe/providers/swipe_providers.dart';
import 'package:word_swipe/providers/word_providers.dart';
import 'package:word_swipe/screens/dashboard_screen.dart';
import 'package:word_swipe/screens/study_mode_screen.dart';
import 'package:word_swipe/screens/swipe_screen.dart';
import 'package:word_swipe/screens/word_library_screen.dart';
import 'package:word_swipe/services/haptics_service.dart';
import 'package:word_swipe/services/storage_service.dart';

void main() {
  testWidgets('home defaults to Today smart deck without level tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final deck = SmartDeck(
      items: [
        SmartDeckItem(
          word: _alphaWord,
          reason: SmartDeckReason.currentLevel,
        ),
      ],
      metrics: const SmartDeckMetrics(
        targetLevel: 'A1',
        nextLevel: 'A2',
        guidance: 'Current path: A1',
        dueReviewCount: 0,
        learningCount: 0,
        knowCount: 0,
        newCount: 1,
        totalCount: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordDeckProvider.overrideWith((ref) async => deck.words),
          smartDeckProvider.overrideWith((ref) async => deck),
          gameProgressProvider.overrideWith((ref) => GameProgress()),
          wordInsightProvider.overrideWith((ref, wordId) => WordInsight.empty(wordId)),
          hapticsServiceProvider.overrideWithValue(_NoopHapticsService()),
        ],
        child: const MaterialApp(home: SwipeScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Today smart deck'), findsOneWidget);
    expect(find.text('STREAK'), findsOneWidget);
    expect(find.text('Swipe 10 cards'), findsOneWidget);
    expect(find.text('All'), findsNothing);
  });

  testWidgets('dashboard shows smart learning stats', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(_FakeStorageService()),
          gameProgressProvider.overrideWith((ref) => GameProgress()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    expect(find.text('Smart path'), findsOneWidget);
    expect(find.text('Today is tuned around B1'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
  });

  testWidgets('mode hub exposes core study modes', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hasPlacementProvider.overrideWithValue(false),
        ],
        child: const MaterialApp(home: ModeHubScreen()),
      ),
    );

    expect(find.text('Smart Swipe'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Learn Quiz'), findsOneWidget);
    expect(find.text('Type Answer'), findsOneWidget);
    expect(find.text('Match'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Test'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Test'), findsOneWidget);
  });

  testWidgets('flashcard mode renders a reusable study deck', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          modeDeckProvider.overrideWith((ref) async => [_alphaWord]),
          wordInsightProvider.overrideWith(
            (ref, wordId) => const WordInsight(
              wordId: 'alpha',
              phonetic: '/alfa/',
              definition: 'the first letter in the Greek alphabet',
              hasInsight: true,
            ),
          ),
        ],
        child: const MaterialApp(
          home: StudyModeScreen(mode: StudyMode.flashcards),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('KNOW'), findsOneWidget);
  });

  testWidgets('word library renders progress filters and entries', (tester) async {
    final stats = {
      for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
        level: LevelProgressStats(
          level: level,
          total: 1,
          unseen: level == 'A1' ? 0 : 1,
          newCount: 0,
          learning: 0,
          know: level == 'A1' ? 1 : 0,
          due: 0,
          mastered: 0,
        ),
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          progressStatsProvider.overrideWithValue(stats),
          libraryEntriesProvider.overrideWithValue([
            LibraryWordEntry(
              word: _alphaWord,
              record: null,
              insight: const WordInsight(
                wordId: 'alpha',
                definition: 'the first letter in the Greek alphabet',
                hasInsight: true,
              ),
              bucket: ProgressBucket.know,
            ),
          ]),
        ],
        child: const MaterialApp(home: WordLibraryScreen()),
      ),
    );

    expect(find.text('Word Library'), findsOneWidget);
    expect(find.text('Know'), findsWidgets);
    expect(find.text('alpha'), findsOneWidget);
  });
}

final _alphaWord = Word(
  id: 'alpha',
  word: 'alpha',
  cefrLevel: 'A1',
);

class _NoopHapticsService implements HapticsService {
  @override
  void vibrateLight() {}

  @override
  void success() {}

  @override
  void newWord() {}

  @override
  void combo() {}

  @override
  void levelUp() {}

  @override
  void questComplete() {}
}

class _FakeStorageService implements StorageService {
  @override
  SmartDeckMetrics getSmartStats({DateTime? now}) {
    return const SmartDeckMetrics(
      targetLevel: 'B1',
      nextLevel: 'B2',
      guidance: 'Current path: B1 -> B2',
      dueReviewCount: 2,
      learningCount: 5,
      knowCount: 12,
      newCount: 20,
      totalCount: 39,
    );
  }

  @override
  Map<String, Map<String, int>> getStats() {
    return {
      for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
        level: {'total': 10, 'seen': 2, 'familiar': 1},
    };
  }

  @override
  Map<String, LevelProgressStats> getProgressStats({DateTime? now}) {
    return {
      for (final level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
        level: LevelProgressStats(
          level: level,
          total: 10,
          unseen: 8,
          newCount: 1,
          learning: 0,
          know: 1,
          due: 0,
          mastered: 0,
        ),
    };
  }

  @override
  List<SwipeEventEntry> getSwipeEventEntries({String? level, int? limit}) => [];

  @override
  List<RecentWordSummary> getRecentWordSummaries({String? level, int? limit}) =>
      [];

  @override
  List<ReviewWordSummary> getReviewWordSummaries({String? level, int? limit}) =>
      [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
