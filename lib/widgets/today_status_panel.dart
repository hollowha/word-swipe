import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_progress.dart';
import '../models/smart_deck.dart';
import '../theme.dart';

class TodayStatusPanel extends StatelessWidget {
  final AsyncValue<SmartDeck> deckAsync;
  final GameProgress progress;

  const TodayStatusPanel({
    super.key,
    required this.deckAsync,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return deckAsync.when(
      loading: () => const SizedBox(height: 68),
      error: (_, __) => const SizedBox(height: 68),
      data: (deck) {
        final metrics = deck.metrics;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E5E0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/generated/word-guide-neutral.png',
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _TodayMetric(
                            label: 'STREAK',
                            value: '${progress.streakCount}',
                            color: AppTheme.cefrColor('B2'),
                          ),
                          _TodayMetric(
                            label: 'XP',
                            value: '${progress.xpToday}',
                            color: AppTheme.know,
                          ),
                          _TodayMetric(
                            label: 'DUE',
                            value: '${metrics.dueReviewCount}',
                            color: AppTheme.learning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              metrics.guidance,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _LevelChip(level: metrics.targetLevel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodayMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TodayMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  final String level;

  const _LevelChip({required this.level});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cefrColor(level).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          level,
          style: TextStyle(
            color: AppTheme.cefrColor(level),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
