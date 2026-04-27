import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/study_mode.dart';
import '../providers/word_providers.dart';
import '../theme.dart';

class ModeHubScreen extends ConsumerWidget {
  const ModeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPlacement = ref.watch(hasPlacementProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Choose Practice',
                      style: TextStyle(
                        color: AppTheme.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Library',
                      onPressed: () => context.push('/library'),
                      icon: const Icon(Icons.manage_search_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _PlacementCard(
                  completed: hasPlacement,
                  onTap: () async {
                    if (hasPlacement) {
                      await ref.read(storageServiceProvider).resetPlacement();
                      ref.invalidate(hasPlacementProvider);
                    }
                    if (context.mounted) context.push('/placement');
                  },
                ),
                const SizedBox(height: 12),
                ...StudyMode.values.map(
                  (mode) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ModeCard(
                      mode: mode,
                      onTap: () {
                        ref.read(selectedStudyModeProvider.notifier).state = mode;
                        if (mode == StudyMode.smartSwipe) {
                          context.go('/');
                        } else {
                          context.go('/study/${mode.routeName}');
                        }
                      },
                    ),
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

class _PlacementCard extends StatelessWidget {
  final bool completed;
  final VoidCallback onTap;

  const _PlacementCard({
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.ink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                completed ? 'Retake placement' : 'Find my starting level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white70,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final StudyMode mode;
  final VoidCallback onTap;

  const _ModeCard({required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E5E0)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(mode.icon, color: AppTheme.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode.description,
                    style: const TextStyle(
                      color: AppTheme.inkSubtle,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ],
        ),
      ),
    );
  }
}
