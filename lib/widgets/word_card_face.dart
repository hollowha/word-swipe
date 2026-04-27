import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word.dart';
import '../providers/swipe_providers.dart';
import '../theme.dart';
import 'cefr_badge.dart';

class WordCardFace extends ConsumerWidget {
  final Word word;
  final bool showTapHint;

  const WordCardFace({
    super.key,
    required this.word,
    this.showTapHint = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = ref.watch(wordInsightProvider(word.id));
    final phonetic = insight.phonetic.isNotEmpty ? insight.phonetic : word.phonetic;

    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SpeakerButton(word: word.word),
              CefrBadge(level: word.cefrLevel),
            ],
          ),
          const Spacer(flex: 3),
          Text(word.word, style: AppTheme.wordDisplay),
          if (phonetic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(phonetic, style: AppTheme.phoneticStyle),
          ],
          const Spacer(flex: 4),
          if (showTapHint)
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 15,
                    color: AppTheme.inkMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Tap to see definition', style: AppTheme.labelSmall),
              ],
            ),
        ],
      ),
    );
  }
}

class _SpeakerButton extends ConsumerWidget {
  final String word;

  const _SpeakerButton({required this.word});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speech = ref.watch(speechServiceProvider);
    return IconButton(
      tooltip: 'Pronounce',
      onPressed: speech.isSupported ? () => speech.speak(word) : null,
      icon: const Icon(Icons.volume_up_rounded, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: AppTheme.inkSubtle,
        backgroundColor: AppTheme.surfaceSubtle,
        disabledForegroundColor: AppTheme.inkMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
