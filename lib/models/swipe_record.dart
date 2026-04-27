import 'package:hive_flutter/hive_flutter.dart';

part 'swipe_record.g.dart';

@HiveType(typeId: 1)
class SwipeRecord extends HiveObject {
  @HiveField(0)
  String wordId;

  @HiveField(1)
  int rightCount;

  @HiveField(2)
  int leftCount;

  @HiveField(3)
  DateTime? lastSwipedAt;

  @HiveField(4)
  String lastDirection;

  @HiveField(5, defaultValue: 0)
  int srsStep;

  @HiveField(6)
  DateTime? dueAt;

  @HiveField(7)
  DateTime? newMarkedAt;

  @HiveField(8, defaultValue: 0)
  int consecutiveKnowCount;

  SwipeRecord({
    required this.wordId,
    this.rightCount = 0,
    this.leftCount = 0,
    this.lastSwipedAt,
    this.lastDirection = '',
    this.srsStep = 0,
    this.dueAt,
    this.newMarkedAt,
    this.consecutiveKnowCount = 0,
  });

  int get totalSwipes => rightCount + leftCount;
  bool get isFamiliar => rightCount > leftCount && rightCount > 0;
  bool get isSeen => totalSwipes > 0;
  bool get isLearning => leftCount > 0 && srsStep < 5;
  bool get isMastered => srsStep >= 5 && consecutiveKnowCount >= 3;
  bool isDue(DateTime now) => dueAt != null && !dueAt!.isAfter(now);
  double get familiarityRatio =>
      totalSwipes == 0 ? 0.0 : rightCount / totalSwipes;
}
