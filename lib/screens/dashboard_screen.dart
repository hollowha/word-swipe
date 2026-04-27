import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/swipe_providers.dart';
import '../providers/word_providers.dart';
import '../models/smart_deck.dart';
import '../models/game_progress.dart';
import '../models/study_constants.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/smart_path_card.dart';

enum _DashboardTab { progress, history, review }
enum _HistoryViewMode { events, recentWords }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _DashboardTab _selectedTab = _DashboardTab.progress;
  _HistoryViewMode _historyViewMode = _HistoryViewMode.events;

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(storageServiceProvider);
    final selectedLevel = ref.watch(selectedLevelProvider);
    final stats = storage.getStats();
    final progressStats = storage.getProgressStats();
    final historyEvents = storage.getSwipeEventEntries(level: selectedLevel);
    final recentWords = storage.getRecentWordSummaries(level: selectedLevel);
    final reviewWords = storage.getReviewWordSummaries(level: selectedLevel);
    final smartStats = storage.getSmartStats();
    final gameProgress = ref.watch(gameProgressProvider);

    int totalFamiliar = 0;
    int totalSeen = 0;
    int totalWords = 0;
    for (final s in stats.values) {
      totalFamiliar += s['familiar'] as int;
      totalSeen += s['seen'] as int;
      totalWords += s['total'] as int;
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE5E5E3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 15,
                            color: AppTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _DashboardTabs(
                    selectedTab: _selectedTab,
                    onChanged: (tab) {
                      setState(() {
                        _selectedTab = tab;
                      });
                    },
                  ),
                ),
                if (_selectedTab != _DashboardTab.progress) ...[
                  const SizedBox(height: 14),
                  _LevelFilterBar(
                    selected: selectedLevel,
                    onChanged: (level) {
                      ref.read(selectedLevelProvider.notifier).state = level;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: switch (_selectedTab) {
                    _DashboardTab.progress => _ProgressTab(
                        stats: stats,
                        progressStats: progressStats,
                        smartStats: smartStats,
                        gameProgress: gameProgress,
                        totalFamiliar: totalFamiliar,
                        totalSeen: totalSeen,
                        totalWords: totalWords,
                        onStudyLevel: (level) {
                          ref.read(studyDeckModeProvider.notifier).state =
                              StudyDeckMode.normal;
                          ref.read(selectedLevelProvider.notifier).state = level;
                          ref.read(swipeProvider.notifier).reset();
                          ref.invalidate(wordDeckProvider);
                          context.pop();
                        },
                      ),
                    _DashboardTab.history => _HistoryTab(
                        selectedMode: _historyViewMode,
                        onModeChanged: (mode) {
                          setState(() {
                            _historyViewMode = mode;
                          });
                        },
                        historyEvents: historyEvents,
                        recentWords: recentWords,
                      ),
                    _DashboardTab.review => _ReviewTab(
                        reviewWords: reviewWords,
                        selectedLevel: selectedLevel,
                        onStartReview: () {
                          ref.read(studyDeckModeProvider.notifier).state =
                              StudyDeckMode.reviewLeftSwiped;
                          ref.read(swipeProvider.notifier).reset();
                          ref.invalidate(wordDeckProvider);
                          context.pop();
                        },
                      ),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardTabs extends StatelessWidget {
  final _DashboardTab selectedTab;
  final ValueChanged<_DashboardTab> onChanged;

  const _DashboardTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_DashboardTab>(
      showSelectedIcon: false,
      selected: {selectedTab},
      onSelectionChanged: (selection) => onChanged(selection.first),
      segments: const [
        ButtonSegment(
          value: _DashboardTab.progress,
          label: Text('Today'),
        ),
        ButtonSegment(
          value: _DashboardTab.review,
          label: Text('Path'),
        ),
        ButtonSegment(
          value: _DashboardTab.history,
          label: Text('History'),
        ),
      ],
      style: SegmentedButton.styleFrom(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.inkSubtle,
        selectedForegroundColor: Colors.white,
        selectedBackgroundColor: AppTheme.ink,
        side: const BorderSide(color: Color(0xFFE8E5E0)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}

class _LevelFilterBar extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _LevelFilterBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final levels = [null, 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final level = levels[index];
          final isSelected = selected == level;
          return GestureDetector(
            onTap: () => onChanged(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.ink : AppTheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected ? AppTheme.ink : const Color(0xFFE5E5E3),
                ),
              ),
              child: Text(
                level ?? 'All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.inkSubtle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  final Map<String, Map<String, int>> stats;
  final Map<String, LevelProgressStats> progressStats;
  final SmartDeckMetrics smartStats;
  final GameProgress gameProgress;
  final int totalFamiliar;
  final int totalSeen;
  final int totalWords;
  final ValueChanged<String?> onStudyLevel;

  const _ProgressTab({
    required this.stats,
    required this.progressStats,
    required this.smartStats,
    required this.gameProgress,
    required this.totalFamiliar,
    required this.totalSeen,
    required this.totalWords,
    required this.onStudyLevel,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        SmartPathCard(stats: smartStats),
        const SizedBox(height: 12),
        _WeeklySelfCard(progress: gameProgress),
        const SizedBox(height: 12),
        _HeroCard(
          familiar: totalFamiliar,
          seen: totalSeen,
          total: totalWords,
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 0, 12),
          child: Text(
            'BY LEVEL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...cefrLevels.map((level) {
          final s = stats[level] ?? {'total': 0, 'seen': 0, 'familiar': 0};
          final p = progressStats[level];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _LevelRow(
              level: level,
              total: s['total'] as int,
              seen: s['seen'] as int,
              familiar: s['familiar'] as int,
              newCount: p?.newCount ?? 0,
              due: p?.due ?? 0,
              unseen: p?.unseen ?? 0,
              mastered: p?.mastered ?? 0,
              onStudy: () => onStudyLevel(level),
            ),
          );
        }),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final _HistoryViewMode selectedMode;
  final ValueChanged<_HistoryViewMode> onModeChanged;
  final List<SwipeEventEntry> historyEvents;
  final List<RecentWordSummary> recentWords;

  const _HistoryTab({
    required this.selectedMode,
    required this.onModeChanged,
    required this.historyEvents,
    required this.recentWords,
  });

  @override
  Widget build(BuildContext context) {
    final isEvents = selectedMode == _HistoryViewMode.events;
    final itemCount = isEvents ? historyEvents.length : recentWords.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<_HistoryViewMode>(
            showSelectedIcon: false,
            selected: {selectedMode},
            onSelectionChanged: (selection) => onModeChanged(selection.first),
            segments: const [
              ButtonSegment(
                value: _HistoryViewMode.events,
                label: Text('Events'),
              ),
              ButtonSegment(
                value: _HistoryViewMode.recentWords,
                label: Text('Recent Words'),
              ),
            ],
            style: SegmentedButton.styleFrom(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.inkSubtle,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: AppTheme.ink,
              side: const BorderSide(color: Color(0xFFE8E5E0)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: itemCount == 0
              ? const _EmptyPanel(
                  title: 'No history yet',
                  subtitle: 'Swipe a few cards and your learning trail will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return isEvents
                        ? _HistoryEventCard(entry: historyEvents[index])
                        : _RecentWordCard(summary: recentWords[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _WeeklySelfCard extends StatelessWidget {
  final GameProgress progress;

  const _WeeklySelfCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final entries = progress.weeklyXpByDate.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final lastSeven = entries.length > 7
        ? entries.sublist(entries.length - 7)
        : entries;
    final maxXp = lastSeven.fold<int>(
      1,
      (max, entry) => entry.value > max ? entry.value : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly self league',
            style: TextStyle(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            progress.xpToday > 0 ? 'You showed up today.' : 'One card keeps the streak alive.',
            style: const TextStyle(color: AppTheme.inkSubtle, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final entry in lastSeven)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        Container(
                          height: 56 * (entry.value / maxXp).clamp(0.08, 1.0),
                          decoration: BoxDecoration(
                            color: AppTheme.know.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.key.substring(5),
                          style: const TextStyle(
                            color: AppTheme.inkMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (lastSeven.isEmpty)
                const Expanded(
                  child: Text(
                    'Your XP bars will appear after today’s deck.',
                    style: TextStyle(color: AppTheme.inkMuted, fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewTab extends StatelessWidget {
  final List<ReviewWordSummary> reviewWords;
  final String? selectedLevel;
  final VoidCallback onStartReview;

  const _ReviewTab({
    required this.reviewWords,
    required this.selectedLevel,
    required this.onStartReview,
  });

  @override
  Widget build(BuildContext context) {
    if (reviewWords.isEmpty) {
      return const _EmptyPanel(
        title: 'No NEW cards yet',
        subtitle: 'Words you swipe left will appear here for later review.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        _ReviewHero(
          count: reviewWords.length,
          selectedLevel: selectedLevel,
          onStartReview: onStartReview,
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 0, 12),
          child: Text(
            'LEFT-SWIPED WORDS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.inkMuted,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...reviewWords.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReviewWordCard(entry: entry),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int familiar;
  final int seen;
  final int total;

  const _HeroCard({
    required this.familiar,
    required this.seen,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : familiar / total;
    final pct = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$familiar',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '/ $total',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white54,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'words familiar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white60,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$pct% familiar',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              Text(
                '$seen seen',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String level;
  final int total;
  final int seen;
  final int familiar;
  final int newCount;
  final int due;
  final int unseen;
  final int mastered;
  final VoidCallback onStudy;

  const _LevelRow({
    required this.level,
    required this.total,
    required this.seen,
    required this.familiar,
    required this.newCount,
    required this.due,
    required this.unseen,
    required this.mastered,
    required this.onStudy,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : familiar / total;
    final color = AppTheme.cefrColor(level);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEC), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CefrBadge(level: level),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$familiar familiar / $mastered mastered',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onStudy,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Study',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.ink,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: AppTheme.inkSubtle,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFF0EFED),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$seen seen · $newCount new · $due due',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.inkMuted,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                '$unseen unseen',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.inkMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryEventCard extends StatelessWidget {
  final SwipeEventEntry entry;

  const _HistoryEventCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isLeft = entry.event.direction == 'left';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (isLeft ? AppTheme.learning : AppTheme.know)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLeft ? Icons.close_rounded : Icons.check_rounded,
              size: 20,
              color: isLeft ? AppTheme.learning : AppTheme.know,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.word.word,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    CefrBadge(level: entry.word.cefrLevel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${isLeft ? 'NEW' : 'KNOW'} · ${entry.event.inputSource} · ${_formatDateTime(entry.event.swipedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.inkSubtle,
                  ),
                ),
                if (entry.insight.definition.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    entry.insight.definition,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.inkSubtle,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentWordCard extends StatelessWidget {
  final RecentWordSummary summary;

  const _RecentWordCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        summary.word.word,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    CefrBadge(level: summary.word.cefrLevel),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${summary.record.lastDirection.toUpperCase()} · ${_formatDateTime(summary.record.lastSwipedAt!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.inkSubtle,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Right ${summary.record.rightCount} / Left ${summary.record.leftCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewHero extends StatelessWidget {
  final int count;
  final String? selectedLevel;
  final VoidCallback onStartReview;

  const _ReviewHero({
    required this.count,
    required this.selectedLevel,
    required this.onStartReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count words ready',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedLevel == null
                      ? 'Review every word you have ever marked as NEW.'
                      : 'Review left-swiped words filtered to $selectedLevel.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.inkSubtle,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            onPressed: onStartReview,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.ink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Start Review'),
          ),
        ],
      ),
    );
  }
}

class _ReviewWordCard extends StatelessWidget {
  final ReviewWordSummary entry;

  const _ReviewWordCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEC)),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              CefrBadge(level: entry.word.cefrLevel),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Last left swipe · ${_formatDateTime(entry.lastLeftSwipedAt)}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.learning,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Left ${entry.record.leftCount} / Right ${entry.record.rightCount}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.inkMuted,
            ),
          ),
          if (entry.insight.definition.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.insight.definition,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.inkSubtle,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E5E3)),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 28,
                color: AppTheme.inkMuted,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.inkSubtle,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  final hh = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$mm-$dd $hh:$min';
}
