import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/progress_bucket.dart';
import '../models/study_constants.dart';
import '../providers/word_providers.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/cefr_badge.dart';

class WordLibraryScreen extends ConsumerWidget {
  const WordLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLevel = ref.watch(selectedLevelProvider);
    final selectedBucket = ref.watch(libraryBucketProvider);
    final stats = ref.watch(progressStatsProvider);
    final entries = ref.watch(libraryEntriesProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Word Library',
                          style: TextStyle(
                            color: AppTheme.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _LevelTabs(
                  selected: selectedLevel,
                  onChanged: (level) {
                    ref.read(selectedLevelProvider.notifier).state = level;
                  },
                ),
                _BucketTabs(
                  selected: selectedBucket,
                  onChanged: (bucket) {
                    ref.read(libraryBucketProvider.notifier).state = bucket;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: TextField(
                    onChanged: (value) {
                      ref.read(librarySearchProvider.notifier).state = value;
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: 'Search words or definitions',
                      filled: true,
                      fillColor: AppTheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE8E5E0)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      if (selectedLevel == null)
                        ...cefrLevels.map(
                          (level) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _StatsCard(stats: stats[level]!),
                          ),
                        )
                      else
                        _StatsCard(stats: stats[selectedLevel]!),
                      const SizedBox(height: 12),
                      if (entries.isEmpty)
                        const _EmptyLibrary()
                      else
                        ...entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _WordEntryCard(entry: entry),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelTabs extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _LevelTabs({required this.selected, required this.onChanged});

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
          return ChoiceChip(
            label: Text(level ?? 'All'),
            selected: selected == level,
            showCheckmark: false,
            onSelected: (_) => onChanged(level),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: levels.length,
      ),
    );
  }
}

class _BucketTabs extends StatelessWidget {
  final ProgressBucket selected;
  final ValueChanged<ProgressBucket> onChanged;

  const _BucketTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final bucket = ProgressBucket.values[index];
          return FilterChip(
            label: Text(bucket.label),
            selected: selected == bucket,
            showCheckmark: false,
            onSelected: (_) => onChanged(bucket),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: ProgressBucket.values.length,
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final LevelProgressStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final progress = stats.total == 0 ? 0.0 : stats.learned / stats.total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E5E0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CefrBadge(level: stats.level),
              const SizedBox(width: 10),
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  color: AppTheme.cefrColor(stats.level),
                  backgroundColor: const Color(0xFFE8E5E0),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${stats.learned}/${stats.total}',
                style: const TextStyle(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniStat(label: 'Know', value: stats.know + stats.mastered),
              _MiniStat(label: 'New', value: stats.newCount),
              _MiniStat(label: 'Learning', value: stats.learning),
              _MiniStat(label: 'Due', value: stats.due),
              _MiniStat(label: 'Unseen', value: stats.unseen),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppTheme.inkSubtle,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WordEntryCard extends StatelessWidget {
  final LibraryWordEntry entry;

  const _WordEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final definition = entry.insight.definition.isNotEmpty
        ? entry.insight.definition
        : entry.word.definition;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E5E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.word.word,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _BucketPill(bucket: entry.bucket),
              const SizedBox(width: 8),
              CefrBadge(level: entry.word.cefrLevel),
            ],
          ),
          if (definition.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              definition,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.inkSubtle,
                height: 1.4,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BucketPill extends StatelessWidget {
  final ProgressBucket bucket;

  const _BucketPill({required this.bucket});

  @override
  Widget build(BuildContext context) {
    final color = switch (bucket) {
      ProgressBucket.know || ProgressBucket.mastered => AppTheme.know,
      ProgressBucket.newWord || ProgressBucket.due => AppTheme.learning,
      _ => AppTheme.inkSubtle,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        bucket.label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Text(
          'No words match this view.',
          style: TextStyle(color: AppTheme.inkSubtle),
        ),
      ),
    );
  }
}
