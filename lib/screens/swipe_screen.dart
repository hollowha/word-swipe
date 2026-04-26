import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/word.dart';
import '../models/study_constants.dart';
import '../models/smart_deck.dart';
import '../providers/swipe_providers.dart';
import '../providers/word_providers.dart';
import '../theme.dart';
import '../widgets/daily_quests_panel.dart';
import '../widgets/swipe_buttons.dart';
import '../widgets/today_status_panel.dart';
import '../widgets/word_card_back.dart';
import '../widgets/word_card_face.dart';
import '../widgets/word_card_front.dart';

enum _SwipeDirection { left, right }
enum _SwipeInputSource { button, gesture }

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen> {
  final _cardAreaKey = GlobalKey<_CardAreaState>();

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(wordDeckProvider);
    final swipeState = ref.watch(swipeProvider);
    final studyMode = ref.watch(studyDeckModeProvider);
    final smartDeckAsync = ref.watch(smartDeckProvider);
    final gameProgress = ref.watch(gameProgressProvider);
    final showQuestPanel = MediaQuery.sizeOf(context).height >= 720;

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
                    studyMode: studyMode,
                    onReset: () {
                      if (studyMode == StudyDeckMode.reviewLeftSwiped) {
                        ref.read(studyDeckModeProvider.notifier).state =
                            StudyDeckMode.smart;
                      }
                      ref.read(swipeProvider.notifier).reset();
                      ref.invalidate(smartDeckProvider);
                      ref.invalidate(wordDeckProvider);
                    },
                  );
                }

                if (swipeState.isComplete ||
                    swipeState.currentIndex >= deck.length) {
                  return _CompletionView(
                    count: deck.length,
                    knowCount: swipeState.knowCount,
                    newCount: swipeState.newCount,
                    dueReviewCompleted: swipeState.dueReviewCompleted,
                    xpToday: gameProgress.xpToday,
                    streakCount: gameProgress.streakCount,
                    onReset: () {
                      ref.read(swipeProvider.notifier).reset();
                      ref.invalidate(smartDeckProvider);
                      ref.invalidate(wordDeckProvider);
                    },
                    onDashboard: () => context.push('/dashboard'),
                  );
                }

                return Column(
                  children: [
                    _TopBar(
                      studyMode: studyMode,
                      onDashboard: () => context.push('/dashboard'),
                    ),
                    if (studyMode == StudyDeckMode.smart)
                      TodayStatusPanel(
                        deckAsync: smartDeckAsync,
                        progress: gameProgress,
                      )
                    else
                      _LevelTabs(selected: ref.watch(selectedLevelProvider)),
                    if (studyMode == StudyDeckMode.smart && showQuestPanel)
                      DailyQuestsPanel(progress: gameProgress),
                    Expanded(
                      child: _CardArea(
                        key: _cardAreaKey,
                        deck: deck,
                        smartDeck: smartDeckAsync.valueOrNull,
                        currentIndex: swipeState.currentIndex,
                      ),
                    ),
                    _ProgressRow(
                      current: swipeState.currentIndex,
                      total: deck.length,
                      xpGained: swipeState.xpGained,
                    ),
                    const SizedBox(height: 16),
                    SwipeButtons(
                      onLeft: () =>
                          _cardAreaKey.currentState?.triggerSwipe(
                            _SwipeDirection.left,
                            inputSource: _SwipeInputSource.button,
                          ),
                      onRight: () =>
                          _cardAreaKey.currentState?.triggerSwipe(
                            _SwipeDirection.right,
                            inputSource: _SwipeInputSource.button,
                          ),
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

class _TopBar extends StatelessWidget {
  final StudyDeckMode studyMode;
  final VoidCallback onDashboard;

  const _TopBar({
    required this.studyMode,
    required this.onDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 4),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              if (studyMode == StudyDeckMode.reviewLeftSwiped)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.learning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Review: NEW words',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.learning,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              if (studyMode == StudyDeckMode.smart)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.know.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Today smart deck',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.know,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
            ],
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

class _LevelTabs extends ConsumerWidget {
  final String? selected;

  const _LevelTabs({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = [null, ...cefrLevels];
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
              ref.invalidate(smartDeckProvider);
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
                  color: isSelected ? AppTheme.ink : const Color(0xFFE5E5E3),
                  width: 1,
                ),
              ),
              child: Text(
                level ?? 'All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

class _CardArea extends ConsumerStatefulWidget {
  final List<Word> deck;
  final SmartDeck? smartDeck;
  final int currentIndex;

  const _CardArea({
    super.key,
    required this.deck,
    required this.smartDeck,
    required this.currentIndex,
  });

  @override
  ConsumerState<_CardArea> createState() => _CardAreaState();
}

class _CardAreaState extends ConsumerState<_CardArea>
    with SingleTickerProviderStateMixin {
  static const _cardPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  static const _swipeDecisionRatio = 0.24;
  static const _velocityThreshold = 950.0;

  late final AnimationController _motionController;
  Animation<Offset>? _motion;
  Offset _dragOffset = Offset.zero;
  Size _cardSize = const Size(320, 480);
  int _topIndex = 0;
  _SwipeDirection? _pendingDirection;
  _SwipeInputSource _pendingInputSource = _SwipeInputSource.gesture;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _topIndex = widget.currentIndex;
    _motionController = AnimationController(vsync: this)
      ..addListener(_handleMotionTick)
      ..addStatusListener(_handleMotionStatus);
  }

  @override
  void didUpdateWidget(covariant _CardArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    final deckChanged = oldWidget.deck != widget.deck;
    final resetRequested =
        oldWidget.currentIndex != widget.currentIndex && widget.currentIndex == 0;

    if (deckChanged || resetRequested) {
      _motionController.stop();
      _pendingDirection = null;
      _pendingInputSource = _SwipeInputSource.gesture;
      _isAnimating = false;
      _dragOffset = Offset.zero;
      _topIndex = widget.currentIndex;
      return;
    }

    if (!_isAnimating && widget.currentIndex != _topIndex) {
      _topIndex = widget.currentIndex;
    }
  }

  @override
  void dispose() {
    _motionController
      ..removeListener(_handleMotionTick)
      ..removeStatusListener(_handleMotionStatus)
      ..dispose();
    super.dispose();
  }

  void triggerSwipe(
    _SwipeDirection direction, {
    required _SwipeInputSource inputSource,
  }) {
    if (_isAnimating || _topIndex >= widget.deck.length) return;
    final width = _cardSize.width;
    final x = direction == _SwipeDirection.left ? -width * 1.35 : width * 1.35;
    _animateTo(
      Offset(x, _dragOffset.dy * 0.35),
      decision: direction,
      inputSource: inputSource,
      duration: const Duration(milliseconds: 220),
    );
  }

  void _handleMotionTick() {
    final animation = _motion;
    if (animation == null) return;
    setState(() {
      _dragOffset = animation.value;
    });
  }

  void _handleMotionStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;

    final decision = _pendingDirection;
    if (decision == null) {
      setState(() {
        _isAnimating = false;
        _dragOffset = Offset.zero;
      });
      return;
    }

    final previousIndex = _topIndex;
    final word = widget.deck[previousIndex];
    final inputSource = _pendingInputSource;
    if (decision == _SwipeDirection.right) {
      ref.read(hapticsServiceProvider).success();
      ref.read(swipeProvider.notifier).swipeRight(
            word,
            inputSource: inputSource.name,
          );
    } else {
      ref.read(hapticsServiceProvider).newWord();
      ref.read(swipeProvider.notifier).swipeLeft(
            word,
            inputSource: inputSource.name,
          );
    }
    ref.read(cardFlippedProvider(previousIndex).notifier).state = false;

    final nextIndex = previousIndex + 1;
    final finishedDeck = nextIndex >= widget.deck.length;

    setState(() {
      _topIndex = nextIndex;
      _dragOffset = Offset.zero;
      _pendingDirection = null;
      _pendingInputSource = _SwipeInputSource.gesture;
      _isAnimating = false;
    });

    if (finishedDeck) {
      ref.read(swipeProvider.notifier).markComplete();
    }
  }

  void _animateTo(
    Offset target, {
    _SwipeDirection? decision,
    _SwipeInputSource inputSource = _SwipeInputSource.gesture,
    required Duration duration,
  }) {
    _pendingDirection = decision;
    _pendingInputSource = inputSource;
    _isAnimating = true;
    _motionController.duration = duration;
    _motion = Tween(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _motionController, curve: Curves.easeOutCubic),
    );
    _motionController.forward(from: 0);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    setState(() {
      _dragOffset = Offset(
        _dragOffset.dx + details.delta.dx,
        (_dragOffset.dy + details.delta.dy * 0.35)
            .clamp(-56.0, 56.0)
            .toDouble(),
      );
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return;

    final width = math.max(_cardSize.width, 1);
    final velocityX = details.velocity.pixelsPerSecond.dx;
    final threshold = width * _swipeDecisionRatio;

    if (_dragOffset.dx.abs() > threshold || velocityX.abs() > _velocityThreshold) {
      final direction =
          (_dragOffset.dx + velocityX * 0.12) >= 0 ? _SwipeDirection.right : _SwipeDirection.left;
      triggerSwipe(direction, inputSource: _SwipeInputSource.gesture);
      return;
    }

    _animateTo(
      Offset.zero,
      duration: const Duration(milliseconds: 170),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeWord = _wordAt(_topIndex);
    final nextWord = _wordAt(_topIndex + 1);
    final queuedWord = _wordAt(_topIndex + 2);

    if (activeWord == null) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _cardSize = Size(
          constraints.maxWidth - _cardPadding.horizontal,
          constraints.maxHeight - _cardPadding.vertical,
        );

        final width = math.max(_cardSize.width, 1);
        final dragProgress = (_dragOffset.dx.abs() / (width * 0.38)).clamp(0.0, 1.0);
        final tilt = (_dragOffset.dx / width) * 0.085;
        final isRight = _dragOffset.dx >= 0;

        return Stack(
          children: [
            if (queuedWord != null)
              Positioned.fill(
                child: Padding(
                  padding: _cardPadding,
                  child: IgnorePointer(
                    child: _BackgroundCardLayer(
                      key: ValueKey('queued_${queuedWord.id}'),
                      word: queuedWord,
                      scale: 0.89 + dragProgress * 0.035,
                      translateY: 30 - dragProgress * 8,
                      opacity: 0.66 + dragProgress * 0.1,
                    ),
                  ),
                ),
              ),
            if (nextWord != null)
              Positioned.fill(
                child: Padding(
                  padding: _cardPadding,
                  child: IgnorePointer(
                    child: _BackgroundCardLayer(
                      key: ValueKey('next_${nextWord.id}'),
                      word: nextWord,
                      scale: 0.94 + dragProgress * 0.05,
                      translateY: 18 - dragProgress * 12,
                      opacity: 0.88 + dragProgress * 0.12,
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: _cardPadding,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onPanUpdate: _handlePanUpdate,
                  onPanEnd: _handlePanEnd,
                  child: Transform.translate(
                    offset: _dragOffset,
                    child: Transform.rotate(
                      angle: tilt,
                      alignment: Alignment.bottomCenter,
                      child: RepaintBoundary(
                        child: _ActiveWordCard(
                          key: ValueKey('active_${activeWord.id}'),
                          word: activeWord,
                          index: _topIndex,
                          overlayOpacity: dragProgress > 0.05 ? dragProgress : 0,
                          overlayLabel: isRight ? 'KNOW' : 'NEW',
                          overlayColor:
                              isRight ? AppTheme.know : AppTheme.learning,
                          reason: widget.smartDeck?.reasonFor(activeWord.id),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Word? _wordAt(int index) {
    if (index < 0 || index >= widget.deck.length) return null;
    return widget.deck[index];
  }
}

class _BackgroundCardLayer extends StatelessWidget {
  final Word word;
  final double scale;
  final double translateY;
  final double opacity;

  const _BackgroundCardLayer({
    super.key,
    required this.word,
    required this.scale,
    required this.translateY,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: RepaintBoundary(
            child: _PreviewCard(word: word),
          ),
        ),
      ),
    );
  }
}

class _ActiveWordCard extends ConsumerWidget {
  final Word word;
  final int index;
  final double overlayOpacity;
  final String overlayLabel;
  final Color overlayColor;
  final SmartDeckReason? reason;

  const _ActiveWordCard({
    super.key,
    required this.word,
    required this.index,
    required this.overlayOpacity,
    required this.overlayLabel,
    required this.overlayColor,
    this.reason,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlipped = ref.watch(cardFlippedProvider(index));

    return GestureDetector(
      onTap: () {
        ref.read(cardFlippedProvider(index).notifier).state = !isFlipped;
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween(begin: 0.965, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
                ),
                child: child,
              ),
            ),
            child: isFlipped
                ? WordCardBack(key: ValueKey('back_${word.id}'), word: word)
                : WordCardFront(key: ValueKey('front_${word.id}'), word: word),
          ),
          if (overlayOpacity > 0)
            Positioned(
              top: 28,
              left: overlayLabel == 'KNOW' ? 28 : null,
              right: overlayLabel == 'NEW' ? 28 : null,
              child: Opacity(
                opacity: overlayOpacity.clamp(0.0, 1.0),
                child: _SwipeOverlayLabel(
                  label: overlayLabel,
                  color: overlayColor,
                ),
              ),
            ),
          if (reason != null)
            Positioned(
              left: 18,
              bottom: 18,
              child: _ReasonChip(reason: reason!),
            ),
        ],
      ),
    );
  }
}

class _ReasonChip extends StatelessWidget {
  final SmartDeckReason reason;

  const _ReasonChip({required this.reason});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          reason.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Word word;

  const _PreviewCard({required this.word});

  @override
  Widget build(BuildContext context) {
    return WordCardFace(word: word);
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

class _ProgressRow extends StatelessWidget {
  final int current;
  final int total;
  final int xpGained;

  const _ProgressRow({
    required this.current,
    required this.total,
    required this.xpGained,
  });

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
            xpGained > 0 ? '$current / $total   +$xpGained XP' : '$current / $total',
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
  final StudyDeckMode studyMode;
  final VoidCallback onReset;

  const _EmptyView({
    required this.studyMode,
    required this.onReset,
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E5E3), width: 1.5),
              ),
              child: const Icon(
                Icons.layers_outlined,
                size: 32,
                color: AppTheme.inkMuted,
              ),
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
            Text(
              studyMode == StudyDeckMode.reviewLeftSwiped
                  ? 'No review words match this filter yet'
                  : 'Try selecting a different level',
              style: const TextStyle(fontSize: 14, color: AppTheme.inkSubtle),
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
  final int knowCount;
  final int newCount;
  final int dueReviewCompleted;
  final int xpToday;
  final int streakCount;
  final VoidCallback onReset;
  final VoidCallback onDashboard;

  const _CompletionView({
    required this.count,
    required this.knowCount,
    required this.newCount,
    required this.dueReviewCompleted,
    required this.xpToday,
    required this.streakCount,
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
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/generated/word-guide-celebrate.png',
                  fit: BoxFit.cover,
                ),
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
              'You studied $count words today',
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.inkSubtle,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _SessionPill(
                  label: 'KNOW',
                  value: knowCount,
                  color: AppTheme.know,
                ),
                const SizedBox(width: 8),
                _SessionPill(
                  label: 'NEW',
                  value: newCount,
                  color: AppTheme.learning,
                ),
                const SizedBox(width: 8),
                _SessionPill(
                  label: 'DUE DONE',
                  value: dueReviewCompleted,
                  color: AppTheme.ink,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _SessionPill(
                  label: 'XP TODAY',
                  value: xpToday,
                  color: AppTheme.know,
                ),
                const SizedBox(width: 8),
                _SessionPill(
                  label: 'STREAK',
                  value: streakCount,
                  color: AppTheme.cefrColor('B2'),
                ),
              ],
            ),
            const SizedBox(height: 36),
            _FilledButton(label: 'Start next smart deck', onTap: onReset),
            const SizedBox(height: 12),
            _TextButton(label: 'View progress', onTap: onDashboard),
          ],
        ),
      ),
    );
  }
}

class _SessionPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _SessionPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

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
