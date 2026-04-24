import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:word_swipe/models/smart_deck.dart';
import 'package:word_swipe/models/word.dart';
import 'package:word_swipe/models/word_insight.dart';
import 'package:word_swipe/providers/swipe_providers.dart';
import 'package:word_swipe/providers/word_providers.dart';
import 'package:word_swipe/screens/dashboard_screen.dart';
import 'package:word_swipe/screens/swipe_screen.dart';
import 'package:word_swipe/services/haptics_service.dart';
import 'package:word_swipe/services/storage_service.dart';

void main() {
  testWidgets('home defaults to Today smart deck without level tabs', (
    tester,
  ) async {
    final deck = SmartDeck(
      words: [_alphaWord],
      metrics: const SmartDeckMetrics(
        targetLevel: 'A1',
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
          wordInsightProvider.overrideWith((ref, wordId) => WordInsight.empty(wordId)),
          hapticsServiceProvider.overrideWithValue(_NoopHapticsService()),
        ],
        child: const MaterialApp(home: SwipeScreen()),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Today smart deck'), findsOneWidget);
    expect(find.text('LEVEL'), findsOneWidget);
    expect(find.text('All'), findsNothing);
  });

  testWidgets('dashboard shows smart learning stats', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(_FakeStorageService()),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );

    expect(find.text('Smart path'), findsOneWidget);
    expect(find.text('Today is tuned around B1'), findsOneWidget);
    expect(find.text('Due'), findsOneWidget);
    expect(find.text('Learning'), findsOneWidget);
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
}

class _FakeStorageService implements StorageService {
  @override
  SmartDeckMetrics getSmartStats({DateTime? now}) {
    return const SmartDeckMetrics(
      targetLevel: 'B1',
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
