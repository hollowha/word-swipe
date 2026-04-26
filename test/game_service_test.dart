import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:word_swipe/models/game_progress.dart';
import 'package:word_swipe/services/game_service.dart';

void main() {
  late Directory tempDir;
  late GameService game;

  setUpAll(() {
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(GameProgressAdapter());
    }
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('word_swipe_game_test');
    Hive.init(tempDir.path);
    await Hive.openBox<GameProgress>(GameService.progressBoxName);
    game = GameService();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('first swipe extends streak and awards XP', () async {
    final now = DateTime(2026, 4, 25, 9);
    final result = await game.recordSwipe(
      isKnow: true,
      wasDue: false,
      targetLevel: 'A1',
      now: now,
    );

    expect(result.progress.streakCount, 1);
    expect(result.progress.xpToday, 10);
    expect(result.progress.totalXp, 10);
    expect(result.streakAdvanced, isTrue);
  });

  test('daily quests award bonus XP when completed', () async {
    final now = DateTime(2026, 4, 25, 9);
    for (var i = 0; i < 5; i++) {
      await game.recordSwipe(
        isKnow: true,
        wasDue: false,
        targetLevel: 'A1',
        now: now,
      );
    }

    final progress = game.getProgress(now: now);
    expect(progress.dailyQuestStates['know_streak'], isTrue);
    expect(progress.xpToday, 75);
  });

  test('streak freeze protects one missed day', () async {
    final firstDay = DateTime(2026, 4, 25, 9);
    await game.recordSwipe(
      isKnow: true,
      wasDue: false,
      targetLevel: 'A1',
      now: firstDay,
    );

    final progress = game.getProgress(now: firstDay.add(const Duration(days: 2)));
    expect(progress.streakCount, 1);
    expect(progress.streakFreezeCount, 0);
  });
}
