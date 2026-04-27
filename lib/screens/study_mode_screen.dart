import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/study_constants.dart';
import '../models/study_mode.dart';
import '../models/word.dart';
import '../models/word_insight.dart';
import '../providers/swipe_providers.dart';
import '../providers/word_providers.dart';
import '../theme.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/word_card_back.dart';
import '../widgets/word_card_face.dart';

class StudyModeScreen extends ConsumerStatefulWidget {
  final StudyMode mode;

  const StudyModeScreen({super.key, required this.mode});

  @override
  ConsumerState<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends ConsumerState<StudyModeScreen> {
  var _index = 0;
  var _flipped = false;
  var _score = 0;
  var _answered = 0;
  var _selected = '';
  final _typedController = TextEditingController();
  final _matched = <String>{};
  String? _firstMatchId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(selectedStudyModeProvider.notifier).state = widget.mode;
    });
  }

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(modeDeckProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _TopBar(
                  mode: widget.mode,
                  onBack: () => context.go('/modes'),
                  onLibrary: () => context.push('/library'),
                ),
                _LevelBar(
                  selected: ref.watch(selectedLevelProvider),
                  onChanged: (level) {
                    ref.read(selectedLevelProvider.notifier).state = level;
                    ref.invalidate(modeDeckProvider);
                    _resetSession();
                  },
                ),
                Expanded(
                  child: deckAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppTheme.ink),
                    ),
                    error: (error, _) => Center(child: Text('$error')),
                    data: (deck) {
                      if (deck.isEmpty) {
                        return const _EmptyMode();
                      }
                      return switch (widget.mode) {
                        StudyMode.flashcards => _buildFlashcards(deck),
                        StudyMode.learnQuiz => _buildQuiz(deck, isTest: false),
                        StudyMode.typeAnswer => _buildTypeAnswer(deck),
                        StudyMode.match => _buildMatch(deck),
                        StudyMode.test => _buildQuiz(deck, isTest: true),
                        StudyMode.smartSwipe => _buildFlashcards(deck),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFlashcards(List<Word> deck) {
    final word = deck[_index.clamp(0, deck.length - 1)];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: _flipped
                  ? WordCardBack(word: word)
                  : WordCardFace(word: word),
            ),
          ),
          const SizedBox(height: 14),
          _SessionProgress(
            current: _index + 1,
            total: math.min(deck.length, 40),
            score: _score,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _answer(word, false, deck),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('NEW'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _answer(word, true, deck),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('KNOW'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz(List<Word> deck, {required bool isTest}) {
    final limit = isTest ? math.min(deck.length, 10) : math.min(deck.length, 40);
    if (_answered >= limit) {
      return _CompleteMode(
        title: isTest ? 'Test complete' : 'Quiz complete',
        score: _score,
        total: limit,
        onRestart: _resetSession,
      );
    }

    final word = deck[_index % deck.length];
    final options = _optionsFor(deck, word);
    final insight = ref.watch(wordInsightProvider(word.id));
    final prompt = _definitionFor(word, insight);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _QuestionHeader(
          title: isTest ? 'Question ${_answered + 1} of $limit' : 'Choose the word',
          subtitle: prompt,
        ),
        const SizedBox(height: 16),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AnswerButton(
              label: option.word,
              selected: _selected == option.id,
              onTap: _selected.isEmpty
                  ? () {
                      final correct = option.id == word.id;
                      setState(() => _selected = option.id);
                      Future<void>.delayed(const Duration(milliseconds: 450), () {
                        if (mounted) _answer(word, correct, deck, limit: limit);
                      });
                    }
                  : null,
            ),
          ),
        const SizedBox(height: 8),
        _SessionProgress(current: _answered, total: limit, score: _score),
      ],
    );
  }

  Widget _buildTypeAnswer(List<Word> deck) {
    final limit = math.min(deck.length, 30);
    if (_answered >= limit) {
      return _CompleteMode(
        title: 'Typing complete',
        score: _score,
        total: limit,
        onRestart: _resetSession,
      );
    }

    final word = deck[_index % deck.length];
    final insight = ref.watch(wordInsightProvider(word.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _QuestionHeader(
          title: 'Type the word',
          subtitle: _definitionFor(word, insight),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _typedController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitTyped(word, deck, limit),
          decoration: InputDecoration(
            hintText: 'Your answer',
            filled: true,
            fillColor: AppTheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE8E5E0)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _submitTyped(word, deck, limit),
          icon: const Icon(Icons.keyboard_return_rounded),
          label: const Text('Check'),
        ),
        const SizedBox(height: 16),
        _SessionProgress(current: _answered, total: limit, score: _score),
      ],
    );
  }

  Widget _buildMatch(List<Word> deck) {
    final words = deck.take(6).toList();
    final cards = <_MatchCard>[
      for (final word in words) _MatchCard(word.id, word.word, true),
      for (final word in words)
        _MatchCard(
          word.id,
          _definitionFor(word, ref.watch(wordInsightProvider(word.id))),
          false,
        ),
    ]..sort((a, b) => a.label.length.compareTo(b.label.length));

    if (_matched.length == words.length) {
      return _CompleteMode(
        title: 'Match complete',
        score: _score,
        total: words.length,
        onRestart: _resetSession,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const _QuestionHeader(
          title: 'Match words and meanings',
          subtitle: 'Tap a word, then tap its matching definition.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final card in cards)
              if (!_matched.contains(card.id))
                _MatchTile(
                  card: card,
                  selected: _firstMatchId == '${card.id}_${card.isWord}',
                  onTap: () => _handleMatchTap(card, words),
                ),
          ],
        ),
        const SizedBox(height: 18),
        _SessionProgress(
          current: _matched.length,
          total: words.length,
          score: _score,
        ),
      ],
    );
  }

  void _submitTyped(Word word, List<Word> deck, int limit) {
    final correct = _typedController.text.trim().toLowerCase() ==
        word.word.trim().toLowerCase();
    _answer(word, correct, deck, limit: limit);
  }

  void _handleMatchTap(_MatchCard card, List<Word> words) {
    final key = '${card.id}_${card.isWord}';
    final first = _firstMatchId;
    if (first == null) {
      setState(() => _firstMatchId = key);
      return;
    }
    final firstParts = first.split('_');
    final firstId = firstParts.first;
    final firstIsWord = firstParts.last == 'true';
    final correct = firstId == card.id && firstIsWord != card.isWord;
    final word = words.firstWhere((item) => item.id == card.id);
    setState(() {
      _firstMatchId = null;
      _answered++;
      if (correct) {
        _score++;
        _matched.add(card.id);
      }
    });
    _record(word, correct);
  }

  List<Word> _optionsFor(List<Word> deck, Word answer) {
    final options = <Word>[answer];
    for (final word in deck) {
      if (options.length >= 4) break;
      if (word.id != answer.id) options.add(word);
    }
    options.sort((a, b) => a.word.length.compareTo(b.word.length));
    return options;
  }

  void _answer(Word word, bool correct, List<Word> deck, {int? limit}) {
    _record(word, correct);
    final maxItems = limit ?? math.min(deck.length, 40);
    setState(() {
      if (correct) _score++;
      _answered++;
      _index = (_index + 1) % deck.length;
      _flipped = false;
      _selected = '';
      _typedController.clear();
      if (_answered >= maxItems) _index = 0;
    });
  }

  Future<void> _record(Word word, bool correct) async {
    final storage = ref.read(storageServiceProvider);
    final game = ref.read(gameServiceProvider);
    final now = DateTime.now();
    final wasDue = storage.getOrCreateRecord(word.id).isDue(now);
    final targetLevel = storage.getTargetLevel(now: now);
    await storage.recordSwipe(
      word.id,
      correct ? swipeDirectionKnow : swipeDirectionNew,
      inputSource: widget.mode.routeName,
      swipedAt: now,
    );
    await game.recordSwipe(
      isKnow: correct,
      wasDue: wasDue && correct,
      targetLevel: targetLevel,
      now: now,
    );
    ref.invalidate(gameProgressProvider);
    ref.invalidate(progressStatsProvider);
    ref.invalidate(libraryEntriesProvider);
  }

  void _resetSession() {
    setState(() {
      _index = 0;
      _flipped = false;
      _score = 0;
      _answered = 0;
      _selected = '';
      _matched.clear();
      _firstMatchId = null;
      _typedController.clear();
    });
  }

  String _definitionFor(Word word, WordInsight insight) {
    final definition = insight.definition.isNotEmpty
        ? insight.definition
        : word.definition;
    if (definition.isNotEmpty) return definition;
    return 'Recall this word from your deck.';
  }
}

class _TopBar extends StatelessWidget {
  final StudyMode mode;
  final VoidCallback onBack;
  final VoidCallback onLibrary;

  const _TopBar({
    required this.mode,
    required this.onBack,
    required this.onLibrary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          const SizedBox(width: 4),
          Icon(mode.icon, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mode.label,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Library',
            onPressed: onLibrary,
            icon: const Icon(Icons.manage_search_rounded),
          ),
        ],
      ),
    );
  }
}

class _LevelBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _LevelBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final levels = [null, ...cefrLevels];
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = selected == level;
          return ChoiceChip(
            label: Text(level ?? 'All'),
            selected: isSelected,
            onSelected: (_) => onChanged(level),
            showCheckmark: false,
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: levels.length,
      ),
    );
  }
}

class _QuestionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _QuestionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E5E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.labelSmall),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 18,
              height: 1.45,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.all(16),
        backgroundColor: selected ? AppTheme.ink : AppTheme.surface,
        foregroundColor: selected ? Colors.white : AppTheme.ink,
        side: const BorderSide(color: Color(0xFFE8E5E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _MatchTile extends StatelessWidget {
  final _MatchCard card;
  final bool selected;
  final VoidCallback onTap;

  const _MatchTile({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: card.isWord ? 150 : 320,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.ink : AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE8E5E0)),
          ),
          child: Text(
            card.label,
            maxLines: card.isWord ? 1 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.ink,
              fontWeight: card.isWord ? FontWeight.w800 : FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard {
  final String id;
  final String label;
  final bool isWord;

  const _MatchCard(this.id, this.label, this.isWord);
}

class _SessionProgress extends StatelessWidget {
  final int current;
  final int total;
  final int score;

  const _SessionProgress({
    required this.current,
    required this.total,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: total == 0 ? 0 : current / total,
            color: AppTheme.ink,
            backgroundColor: const Color(0xFFE0DDD9),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$score / $total',
          style: const TextStyle(
            color: AppTheme.inkSubtle,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CompleteMode extends StatelessWidget {
  final String title;
  final int score;
  final int total;
  final VoidCallback onRestart;

  const _CompleteMode({
    required this.title,
    required this.score,
    required this.total,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, size: 56, color: AppTheme.know),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Score $score / $total',
              style: const TextStyle(color: AppTheme.inkSubtle, fontSize: 16),
            ),
            const SizedBox(height: 22),
            FilledButton(onPressed: onRestart, child: const Text('Practice again')),
          ],
        ),
      ),
    );
  }
}

class _EmptyMode extends StatelessWidget {
  const _EmptyMode();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No study words match this filter.',
        style: TextStyle(color: AppTheme.inkSubtle),
      ),
    );
  }
}
