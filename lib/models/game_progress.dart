import 'package:hive_flutter/hive_flutter.dart';

import 'study_constants.dart';

class DailyQuest {
  final String id;
  final String label;
  final int current;
  final int target;
  final bool completed;

  const DailyQuest({
    required this.id,
    required this.label,
    required this.current,
    required this.target,
    required this.completed,
  });

  double get progress => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);
}

class GameProgress extends HiveObject {
  int streakCount;
  DateTime? lastActiveDate;
  int streakFreezeCount;
  int xpToday;
  int totalXp;
  Map<String, int> weeklyXpByDate;
  Map<String, bool> dailyQuestStates;
  String currentTargetLevel;
  DateTime? lastQuestDate;
  int cardsToday;
  int knowStreakToday;
  int dueReviewsToday;

  GameProgress({
    this.streakCount = 0,
    this.lastActiveDate,
    this.streakFreezeCount = 1,
    this.xpToday = 0,
    this.totalXp = 0,
    Map<String, int>? weeklyXpByDate,
    Map<String, bool>? dailyQuestStates,
    this.currentTargetLevel = 'A1',
    this.lastQuestDate,
    this.cardsToday = 0,
    this.knowStreakToday = 0,
    this.dueReviewsToday = 0,
  })  : weeklyXpByDate = weeklyXpByDate ?? <String, int>{},
        dailyQuestStates = dailyQuestStates ?? <String, bool>{};

  List<DailyQuest> get quests => [
        DailyQuest(
          id: questSwipeCards,
          label: 'Swipe 10 cards',
          current: cardsToday,
          target: 10,
          completed: dailyQuestStates[questSwipeCards] == true,
        ),
        DailyQuest(
          id: questKnowStreak,
          label: 'Know streak 5',
          current: knowStreakToday,
          target: 5,
          completed: dailyQuestStates[questKnowStreak] == true,
        ),
        DailyQuest(
          id: questReviewDue,
          label: 'Clear due review',
          current: dueReviewsToday,
          target: 1,
          completed: dailyQuestStates[questReviewDue] == true,
        ),
      ];
}

class GameProgressAdapter extends TypeAdapter<GameProgress> {
  @override
  final int typeId = 4;

  @override
  GameProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameProgress(
      streakCount: fields[0] as int? ?? 0,
      lastActiveDate: fields[1] as DateTime?,
      streakFreezeCount: fields[2] as int? ?? 1,
      xpToday: fields[3] as int? ?? 0,
      totalXp: fields[4] as int? ?? 0,
      weeklyXpByDate: _intMap(fields[5]),
      dailyQuestStates: _boolMap(fields[6]),
      currentTargetLevel: fields[7] as String? ?? 'A1',
      lastQuestDate: fields[8] as DateTime?,
      cardsToday: fields[9] as int? ?? 0,
      knowStreakToday: fields[10] as int? ?? 0,
      dueReviewsToday: fields[11] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, GameProgress obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.streakCount)
      ..writeByte(1)
      ..write(obj.lastActiveDate)
      ..writeByte(2)
      ..write(obj.streakFreezeCount)
      ..writeByte(3)
      ..write(obj.xpToday)
      ..writeByte(4)
      ..write(obj.totalXp)
      ..writeByte(5)
      ..write(obj.weeklyXpByDate)
      ..writeByte(6)
      ..write(obj.dailyQuestStates)
      ..writeByte(7)
      ..write(obj.currentTargetLevel)
      ..writeByte(8)
      ..write(obj.lastQuestDate)
      ..writeByte(9)
      ..write(obj.cardsToday)
      ..writeByte(10)
      ..write(obj.knowStreakToday)
      ..writeByte(11)
      ..write(obj.dueReviewsToday);
  }

  static Map<String, int> _intMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', (val as num).toInt()));
    }
    return <String, int>{};
  }

  static Map<String, bool> _boolMap(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry('$key', val == true));
    }
    return <String, bool>{};
  }
}
