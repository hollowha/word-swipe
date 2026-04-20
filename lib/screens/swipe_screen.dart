import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/word.dart';
import '../providers/word_providers.dart';
import '../providers/swipe_providers.dart';
import '../theme.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/word_card_front.dart';
import '../widgets/word_card_back.dart';
import '../widgets/swipe_buttons.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  late CardSwiperController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CardSwiperController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(wordDeckProvider);
    final swipeState = ref.watch(swipeProvider);
    final selectedLevel = ref.watch(selectedLevelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: deckAsync.when(
              loading: () => const _SeedingView(),
              error: (e, _) => Center(child: Text('$e')),
              data: (deck) {
                if (deck.isEmpty) {
                  return _EmptyView(
                    onReset: () {
                      ref.read(swipeProvider.notifier).reset();
                      ref.invalidate(wordDeckProvider);
                    },
                  );
                }
                if (swipeState.isComplete ||
                    swipeState.currentIndex >= deck.length) {
                  return _CompletionView(
                    count: deck.length,
                    onReset: () {
                      ref.read(swipeProvider.notifier).reset();
                      ref.invalidate(wordDeckProvider);
                    },
                    onDashboard: () => context.push('/dashboard'),
                  );
                }

                return Column(
                  children: [
                    _TopBar(onDashboard: () => context.push('/dashboard')),
                    _LevelTabs(selected: selectedLevel),
                    Expanded(
                      child: _CardArea(
                        deck: deck,
                        controller: _controller,
                        currentIndex: swipeState.currentIndex,
                      ),
                    ),
                    _ProgressRow(
                      current: swipeState.currentIndex,
                      total: deck.length,
                    ),
                    const SizedBox(height: 16),
                    SwipeButtons(
                      onLeft: () =>
                          _controller.swipe(CardSwiperDirection.left),
                      onRight: () =>
                          _controller.swipe(CardSwiperDirection.right),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final VoidCallback onDashboard;
  const _TopBar({required this.onDashboard});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
      child: Row(
        children: [
          const Text(
            'WordSwipe',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onDashboard,
            icon: const Icon(Icons.bar_chart_rounded, size: 24),
            style: IconButton.styleFrom(
              foregroundColor: AppTheme.inkSubtle,
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Level tabs ─────────────────────────────────────────────────────────────────

class _LevelTabs extends ConsumerWidget {
  final String? selected;
  const _LevelTabs({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = [null, 'A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: levels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final level = levels[i];
          final isSelected = selected == level;
          return GestureDetector(
            onTap: () {
              ref.read(selectedLevelProvider.notifier).state = level;
              ref.read(swipeProvider.notifier).reset();
              ref.invalidate(wordDeckProvider);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.ink : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.ink
                      : const Color(0xFFE5E5E3),
                  width: 1,
                ),
              ),
              child: Text(
                level ?? 'All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppTheme.inkSubtle,
                  letterSpacing: isSelected ? 0.2 : 0,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Card area ──────────────────────────────────────────────────────────────────

class _CardArea extends ConsumerStatefulWidget {
  final List<Word> deck;
  final CardSwiperController controller;
  final int currentIndex;

  const _CardArea({
    required this.deck,
    required this.controller,
    required this.currentIndex,
  });

  @override
  ConsumerState<_CardArea> createState() => _CardAreaState();
}

class _CardAreaState extends ConsumerState<_CardArea> {
  /// Tracks horizontal drag progress (0.0 → 1.0) for the preview card animation.
  /// ValueNotifier avoids rebuilding _CardArea on every drag frame.
  final _drag = ValueNotifier<double>(0.0);

  /// Local top-card index so the preview word updates immediately on swipe
  /// without waiting for the async Riverpod state to propagate.
  int _topIndex = 0;

  final Set<String> _prefetched = {};

  @override
  void initState() {
    super.initState();
    _topIndex = widget.currentIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefetch(0));
  }

  @override
  void didUpdateWidget(_CardArea old) {
    super.didUpdateWidget(old);
    if (old.deck != widget.deck) {
      _prefetched.clear();
      _topIndex = 0;
      _drag.value = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefetch(0));
    }
  }

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _prefetch(int from) {
    if (!mounted) return;
    final end = (from + 5).clamp(0, widget.deck.length);
    for (int i = from; i < end; i++) {
      final id = widget.deck[i].id;
      if (_prefetched.contains(id)) continue;
      _prefetched.add(id);
      ref.read(definitionProvider(id).future).ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    final previewIdx = _topIndex + 1;
    final hasPreview = previewIdx < deck.length;

    return Stack(
      children: [
        // ── Preview card: sits behind the swiper, scales up as the user drags ──
        if (hasPreview)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ValueListenableBuilder<double>(
                valueListenable: _drag,
                builder: (_, raw, child) {
                  final eased =
                      Curves.easeOut.transform(raw.clamp(0.0, 1.0));
                  return Transform.translate(
                    offset: Offset(0, 18.0 * (1.0 - eased)),
                    child: Transform.scale(
                      scale: 0.93 + eased * 0.07,
                      child: child!,
                    ),
                  );
                },
                child: _PreviewCard(word: deck[previewIdx]),
              ),
            ),
          ),

        // ── Active swiper: single card, owns the swipe physics ──
        CardSwiper(
          controller: widget.controller,
          cardsCount: deck.length,
          numberOfCardsDisplayed: 1,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          isLoop: false,
          allowedSwipeDirection:
              const AllowedSwipeDirection.only(left: true, right: true),
          cardBuilder: (context, index, percentX, percentY) {
            // Drive the preview card animation each frame
            _drag.value = percentX.abs().clamp(0.0, 1.0).toDouble();

            final word = deck[index];
            final isFlipped = ref.watch(cardFlippedProvider(index));
            final absX = percentX.abs();
            final isRight = percentX > 0;

            return GestureDetector(
              onTap: () {
                ref.read(cardFlippedProvider(index).notifier).state =
                    !isFlipped;
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Card face — flip animation (front ↔ back)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale: Tween(begin: 0.94, end: 1.0).animate(
                          CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic),
                        ),
                        child: child,
                      ),
                    ),
                    child: isFlipped
                        ? WordCardBack(
                            key: ValueKey('back_$index'), word: word)
                        : WordCardFront(
                            key: ValueKey('front_$index'), word: word),
                  ),
                  // Tinder KNOW / NEW overlay
                  if (absX > 0.05)
                    Positioned(
                      top: 28,
                      left: isRight ? 28 : null,
                      right: isRight ? null : 28,
                      child: Opacity(
                        opacity: (absX * 2.5).clamp(0.0, 1.0),
                        child: _SwipeOverlayLabel(
                          label: isRight ? 'KNOW' : 'NEW',
                          color:
                              isRight ? AppTheme.know : AppTheme.learning,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          onSwipe: (prevIndex, _, direction) {
            final word = deck[prevIndex];
            if (direction == CardSwiperDirection.right) {
              ref.read(swipeProvider.notifier).swipeRight(word);
            } else if (direction == CardSwiperDirection.left) {
              ref.read(swipeProvider.notifier).swipeLeft(word);
            }
            ref.read(cardFlippedProvider(prevIndex).notifier).state = false;
            // Advance preview to the new next card
            setState(() => _topIndex = prevIndex + 1);
            _drag.value = 0.0;
            _prefetch(prevIndex + 1);
            return true;
          },
          onEnd: () => ref.read(swipeProvider.notifier).markComplete(),
        ),
      ],
    );
  }
}

// ── Preview card (non-interactive, sits behind the active card) ────────────────

class _PreviewCard extends StatelessWidget {
  final Word word;
  const _PreviewCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CefrBadge(level: word.cefrLevel),
          ),
          const Spacer(flex: 3),
          Text(word.word, style: AppTheme.wordDisplay),
          if (word.phonetic.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(word.phonetic, style: AppTheme.phoneticStyle),
          ],
          const Spacer(flex: 4),
        ],
      ),
    );
  }
}

class _SwipeOverlayLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SwipeOverlayLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
        ),
      ),
    );
  }
}

// ── Progress row ───────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressRow({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 2,
              backgroundColor: const Color(0xFFE0DDD9),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.ink),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$current / $total',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.inkMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty states ───────────────────────────────────────────────────────────────

class _SeedingView extends StatelessWidget {
  const _SeedingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.ink,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading word list',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.ink,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'First launch may take a moment',
            style: TextStyle(fontSize: 13, color: AppTheme.inkSubtle),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyView({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFFE5E5E3), width: 1.5),
              ),
              child: const Icon(Icons.layers_outlined,
                  size: 32, color: AppTheme.inkMuted),
            ),
            const SizedBox(height: 20),
            const Text(
              'No words found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try selecting a different level',
              style: TextStyle(fontSize: 14, color: AppTheme.inkSubtle),
            ),
            const SizedBox(height: 28),
            _TextButton(label: 'Go back', onTap: onReset),
          ],
        ),
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  final int count;
  final VoidCallback onReset;
  final VoidCallback onDashboard;

  const _CompletionView({
    required this.count,
    required this.onReset,
    required this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.know.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: AppTheme.know,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Session complete',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You reviewed $count words',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.inkSubtle,
              ),
            ),
            const SizedBox(height: 36),
            _FilledButton(label: 'Review again', onTap: onReset),
            const SizedBox(height: 12),
            _TextButton(label: 'View progress', onTap: onDashboard),
          ],
        ),
      ),
    );
  }
}

// ── Shared button widgets ──────────────────────────────────────────────────────

class _FilledButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FilledButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.ink,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.inkSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
