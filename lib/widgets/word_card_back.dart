import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/morpheme_hint.dart';
import '../models/word.dart';
import '../models/word_insight.dart';
import '../providers/swipe_providers.dart';
import '../theme.dart';
import 'cefr_badge.dart';

class WordCardBack extends ConsumerWidget {
  final Word word;

  const WordCardBack({super.key, required this.word});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(wordInsightProvider(word.id));

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: _Content(word: word, insight: insight),
    );
  }
}

class _Content extends StatelessWidget {
  final Word word;
  final WordInsight insight;

  const _Content({required this.word, required this.insight});

  @override
  Widget build(BuildContext context) {
    final phonetic = insight.phonetic.isNotEmpty ? insight.phonetic : word.phonetic;
    final partOfSpeech =
        insight.partOfSpeech.isNotEmpty ? insight.partOfSpeech : word.partOfSpeech;
    final definition =
        insight.definition.isNotEmpty ? insight.definition : word.definition;
    final example = insight.example.isNotEmpty ? insight.example : word.example;
    final morphemes = insight.morphemes as List<MorphemeHint>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: word + badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                word.word,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Pronounce',
              onPressed: () {
                // The service no-ops on unsupported platforms.
                final container = ProviderScope.containerOf(context);
                final speech = container.read(speechServiceProvider);
                if (speech.isSupported) speech.speak(word.word);
              },
              icon: const Icon(Icons.volume_up_rounded, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: AppTheme.inkSubtle,
                backgroundColor: AppTheme.surfaceSubtle,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CefrBadge(level: word.cefrLevel),
          ],
        ),

        // Phonetic + part of speech
        if (phonetic.isNotEmpty || partOfSpeech.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              if (phonetic.isNotEmpty)
                Text(phonetic, style: AppTheme.phoneticStyle),
              if (phonetic.isNotEmpty && partOfSpeech.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 3,
                  height: 3,
                  decoration: const BoxDecoration(
                    color: AppTheme.inkMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              if (partOfSpeech.isNotEmpty)
                Text(
                  partOfSpeech,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkSubtle,
                    letterSpacing: 0.2,
                  ),
                ),
            ],
          ),
        ],

        const SizedBox(height: 20),
        const Divider(color: Color(0xFFEEEEEC), thickness: 1, height: 1),
        const SizedBox(height: 20),

        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (definition.isNotEmpty) ...[
                  Text('MEANING', style: AppTheme.labelSmall),
                  const SizedBox(height: 8),
                  Text(
                    definition,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.ink,
                      height: 1.6,
                    ),
                  ),
                  if (example.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('EXAMPLE', style: AppTheme.labelSmall),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(
                            color: AppTheme.cefrColor(word.cefrLevel),
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        '"$example"',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.inkSubtle,
                          height: 1.6,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppTheme.inkMuted,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Definition unavailable for this word, but word-building clues are still available below.',
                            style: TextStyle(
                              color: AppTheme.inkSubtle,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (morphemes.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('WORD BUILDING', style: AppTheme.labelSmall),
                  const SizedBox(height: 12),
                  ...morphemes.map(
                    (hint) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MorphemePanel(hint: hint),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom hint
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_rounded, size: 13, color: AppTheme.inkMuted),
            const SizedBox(width: 5),
            Text('Tap to flip back', style: AppTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

class _MorphemePanel extends StatelessWidget {
  final MorphemeHint hint;

  const _MorphemePanel({required this.hint});

  @override
  Widget build(BuildContext context) {
    final accent = switch (hint.kind) {
      'root' => AppTheme.cefrColor('B2'),
      'prefix' => AppTheme.cefrColor('A2'),
      'suffix' => AppTheme.cefrColor('C1'),
      _ => AppTheme.inkSubtle,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  hint.kind.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hint.form,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hint.meaning,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.ink,
              height: 1.5,
            ),
          ),
          if (hint.themeCategory.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              hint.themeCategory,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.inkSubtle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hint.relatedWords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              hint.relatedWords.take(4).join(' · '),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.inkSubtle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
