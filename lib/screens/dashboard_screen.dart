import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/word_providers.dart';
import '../providers/swipe_providers.dart';
import '../theme.dart';
import '../widgets/cefr_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.read(storageServiceProvider);
    final stats = storage.getStats();

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
                // Top bar
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
                        'Progress',
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

                const SizedBox(height: 24),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Hero stat
                      _HeroCard(
                        familiar: totalFamiliar,
                        seen: totalSeen,
                        total: totalWords,
                      ),
                      const SizedBox(height: 16),

                      // Section label
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

                      // Per-level cards
                      ...['A1', 'A2', 'B1', 'B2', 'C1', 'C2'].map((level) {
                        final s = stats[level] ??
                            {'total': 0, 'seen': 0, 'familiar': 0};
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LevelRow(
                            level: level,
                            total: s['total'] as int,
                            seen: s['seen'] as int,
                            familiar: s['familiar'] as int,
                            onStudy: () {
                              ref.read(selectedLevelProvider.notifier).state =
                                  level;
                              ref.read(swipeProvider.notifier).reset();
                              ref.invalidate(wordDeckProvider);
                              context.pop();
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
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

// ── Hero stat card ─────────────────────────────────────────────────────────────

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
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
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

// ── Per-level row ──────────────────────────────────────────────────────────────

class _LevelRow extends StatelessWidget {
  final String level;
  final int total;
  final int seen;
  final int familiar;
  final VoidCallback onStudy;

  const _LevelRow({
    required this.level,
    required this.total,
    required this.seen,
    required this.familiar,
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
                  '$familiar familiar',
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
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: AppTheme.inkSubtle),
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
                '$seen of $total seen',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.inkMuted,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                '${total - seen} remaining',
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
