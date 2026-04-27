import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/study_constants.dart';
import '../models/word.dart';
import '../providers/word_providers.dart';
import '../theme.dart';
import '../widgets/cefr_badge.dart';

class PlacementScreen extends ConsumerStatefulWidget {
  const PlacementScreen({super.key});

  @override
  ConsumerState<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends ConsumerState<PlacementScreen> {
  final _answersByLevel = <String, List<bool>>{
    for (final level in cefrLevels) level: <bool>[],
  };
  var _index = 0;
  String? _result;

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(placementDeckProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: deckAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.ink),
              ),
              error: (error, _) => Center(child: Text('$error')),
              data: (deck) {
                if (_result != null) return _ResultView(level: _result!);
                final done = _index >= deck.length;
                if (done) return _finish(deck);
                final word = deck[_index];
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Placement',
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: deck.isEmpty ? 0 : _index / deck.length,
                        color: AppTheme.ink,
                        backgroundColor: const Color(0xFFE0DDD9),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: CefrBadge(level: word.cefrLevel),
                            ),
                            const SizedBox(height: 64),
                            Text(word.word, style: AppTheme.wordDisplay),
                            const SizedBox(height: 64),
                            const Text(
                              'Do you know this word?',
                              style: TextStyle(
                                color: AppTheme.inkSubtle,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
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
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _finish(List<Word> deck) {
    final storage = ref.read(storageServiceProvider);
    final level = storage.estimatePlacementLevel(_answersByLevel);
    Future.microtask(() async {
      await storage.setPlacementLevel(level);
      if (mounted) {
        setState(() => _result = level);
        ref.invalidate(hasPlacementProvider);
        ref.invalidate(smartDeckProvider);
        ref.invalidate(modeDeckProvider);
      }
    });
    return const Center(child: CircularProgressIndicator(color: AppTheme.ink));
  }

  void _answer(Word word, bool know, List<Word> deck) {
    setState(() {
      _answersByLevel[word.cefrLevel]?.add(know);
      _index++;
    });
  }
}

class _ResultView extends StatelessWidget {
  final String level;

  const _ResultView({required this.level});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flag_rounded, size: 56, color: AppTheme.know),
          const SizedBox(height: 20),
          const Text(
            'Starting level set',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your smart deck will begin around $level.',
            style: const TextStyle(color: AppTheme.inkSubtle, fontSize: 16),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Start smart deck'),
          ),
        ],
      ),
    );
  }
}
