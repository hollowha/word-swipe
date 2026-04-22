import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:word_swipe/models/word.dart';
import 'package:word_swipe/models/word_insight.dart';
import 'package:word_swipe/providers/swipe_providers.dart';
import 'package:word_swipe/widgets/swipe_buttons.dart';
import 'package:word_swipe/widgets/word_card_back.dart';
import 'package:word_swipe/widgets/word_card_front.dart';

void main() {
  testWidgets('word card back renders offline definition and morphemes', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildWithInsight(
        const WordInsight(
          wordId: 'alpha',
          phonetic: '/alfa/',
          partOfSpeech: 'noun',
          definition: 'the first letter in the Greek alphabet',
          example: 'Alpha usually marks the starting point.',
          source: 'test',
          hasInsight: true,
          morphemesRaw: [
            {
              'kind': 'root',
              'form': 'alph',
              'meaning': 'beginning; first',
              'themeCategory': 'Sequence',
              'matchedWord': 'alpha',
              'relatedWords': ['alphabet', 'alphabetical'],
            },
          ],
        ),
        child: WordCardBack(word: _alphaWord),
      ),
    );

    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('MEANING'), findsOneWidget);
    expect(find.textContaining('first letter'), findsOneWidget);
    expect(find.text('WORD BUILDING'), findsOneWidget);
    expect(find.text('alph'), findsOneWidget);
    expect(find.text('alphabet · alphabetical'), findsOneWidget);
  });

  testWidgets('word card front uses offline phonetic when available', (tester) async {
    await tester.pumpWidget(
      _buildWithInsight(
        const WordInsight(
          wordId: 'alpha',
          phonetic: '/alfa/',
          hasInsight: true,
        ),
        child: WordCardFront(word: _alphaWord),
      ),
    );

    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('/alfa/'), findsOneWidget);
  });

  testWidgets('swipe buttons trigger both callbacks', (tester) async {
    var leftTapped = 0;
    var rightTapped = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeButtons(
            onLeft: () => leftTapped++,
            onRight: () => rightTapped++,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump(const Duration(milliseconds: 200));

    expect(leftTapped, 1);
    expect(rightTapped, 1);
  });
}

Widget _buildWithInsight(WordInsight insight, {required Widget child}) {
  return ProviderScope(
    overrides: [
      wordInsightProvider.overrideWith((ref, wordId) {
        if (wordId == insight.wordId) return insight;
        return WordInsight.empty(wordId);
      }),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
}

final _alphaWord = Word(
  id: 'alpha',
  word: 'alpha',
  cefrLevel: 'A1',
);
