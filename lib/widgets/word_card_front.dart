import 'package:flutter/material.dart';
import '../models/word.dart';
import '../theme.dart';
import 'cefr_badge.dart';

class WordCardFront extends StatelessWidget {
  final Word word;

  const WordCardFront({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: badge + spacer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              CefrBadge(level: word.cefrLevel),
            ],
          ),
          // Word — takes the center stage
          const Spacer(flex: 3),
          Text(
            word.word,
            style: AppTheme.wordDisplay,
          ),
          if (word.phonetic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(word.phonetic, style: AppTheme.phoneticStyle),
          ],
          const Spacer(flex: 4),
          // Subtle tap hint
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
