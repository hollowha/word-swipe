import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/smart_deck.dart';
import '../theme.dart';

class TodayStatusPanel extends StatelessWidget {
  final AsyncValue<SmartDeck> deckAsync;

  const TodayStatusPanel({super.key, required this.deckAsync});

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
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E5E0)),
            ),
            child: Row(
              children: [
                _TodayMetric(
                  label: 'LEVEL',
                  value: metrics.targetLevel,
                  color: AppTheme.cefrColor(metrics.targetLevel),
                ),
                const _MetricDivider(),
                _TodayMetric(
                  label: 'DUE',
                  value: '${metrics.dueReviewCount}',
                  color: AppTheme.learning,
                ),
                const _MetricDivider(),
                _TodayMetric(
                  label: 'LEARNING',
                  value: '${metrics.learningCount}',
                  color: AppTheme.ink,
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

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE8E5E0),
    );
  }
}
