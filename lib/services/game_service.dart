import 'package:hive_flutter/hive_flutter.dart';

import '../models/game_progress.dart';
import '../models/study_constants.dart';

class GameSwipeResult {
  final GameProgress progress;
  final int xpGained;
  final List<String> completedQuestIds;
  final bool streakAdvanced;

  const GameSwipeResult({
    required this.progress,
    required this.xpGained,
    required this.completedQuestIds,
    required this.streakAdvanced,
  });
}

class GameService {
  static const progressBoxName = 'game_progress';
  static const _progressKey = 'progress';

  Box<GameProgress> get progressBox => Hive.box<GameProgress>(progressBoxName);

  GameProgress getProgress({DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final progress = progressBox.get(_progressKey) ?? GameProgress();
    _rollDayIfNeeded(progress, today);
    progressBox.put(_progressKey, progress);
    return progress;
  }

  Future<GameSwipeResult> recordSwipe({
    required bool isKnow,
    required bool wasDue,
    required String targetLevel,
    DateTime? now,
  }) async {
    final today = _dateOnly(now ?? DateTime.now());
    final progress = getProgress(now: today);
    final completedBefore = Set<String>.from(
      progress.dailyQuestStates.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key),
    );

    var xp = isKnow ? xpForKnow : xpForNew;
    if (wasDue && isKnow) xp += xpForDueReview;

    progress.cardsToday++;
    progress.knowStreakToday = isKnow ? progress.knowStreakToday + 1 : 0;
    if (wasDue && isKnow) progress.dueReviewsToday++;
    progress.currentTargetLevel = targetLevel;

    final streakAdvanced = _advanceStreak(progress, today);
    _completeQuestIfReady(progress, questSwipeCards, progress.cardsToday >= 10);
    _completeQuestIfReady(
      progress,
      questKnowStreak,
      progress.knowStreakToday >= 5,
    );
    _completeQuestIfReady(
      progress,
      questReviewDue,
      progress.dueReviewsToday >= 1,
    );

    final completedAfter = progress.dailyQuestStates.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
    final newlyCompleted = completedAfter.difference(completedBefore).toList();
    xp += newlyCompleted.length * xpForQuest;

    progress.xpToday += xp;
    progress.totalXp += xp;
    progress.weeklyXpByDate[_dateKey(today)] =
        (progress.weeklyXpByDate[_dateKey(today)] ?? 0) + xp;

    await progressBox.put(_progressKey, progress);
    return GameSwipeResult(
      progress: progress,
      xpGained: xp,
      completedQuestIds: newlyCompleted,
      streakAdvanced: streakAdvanced,
    );
  }

  void _rollDayIfNeeded(GameProgress progress, DateTime today) {
    final lastQuestDate = progress.lastQuestDate == null
        ? null
        : _dateOnly(progress.lastQuestDate!);
    if (lastQuestDate == today) return;

    progress.xpToday = 0;
    progress.cardsToday = 0;
    progress.knowStreakToday = 0;
    progress.dueReviewsToday = 0;
    progress.dailyQuestStates = <String, bool>{};
    progress.lastQuestDate = today;

    final lastActiveDate = progress.lastActiveDate == null
        ? null
        : _dateOnly(progress.lastActiveDate!);
    if (lastActiveDate == null) return;
    final missedDays = today.difference(lastActiveDate).inDays;
    if (missedDays <= 1) return;
    if (progress.streakFreezeCount > 0) {
      progress.streakFreezeCount--;
      progress.lastActiveDate = today.subtract(const Duration(days: 1));
    } else {
      progress.streakCount = 0;
    }
  }

  bool _advanceStreak(GameProgress progress, DateTime today) {
    final lastActiveDate = progress.lastActiveDate == null
        ? null
        : _dateOnly(progress.lastActiveDate!);
    if (lastActiveDate == today) return false;
    if (lastActiveDate == today.subtract(const Duration(days: 1))) {
      progress.streakCount++;
    } else if (progress.streakCount == 0) {
      progress.streakCount = 1;
    } else {
      progress.streakCount = 1;
    }
    progress.lastActiveDate = today;
    return true;
  }

  void _completeQuestIfReady(
    GameProgress progress,
    String questId,
    bool isReady,
  ) {
    if (isReady) progress.dailyQuestStates[questId] = true;
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
