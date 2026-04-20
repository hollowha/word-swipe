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

  SwipeRecord({
    required this.wordId,
    this.rightCount = 0,
    this.leftCount = 0,
    this.lastSwipedAt,
    this.lastDirection = '',
  });

  int get totalSwipes => rightCount + leftCount;
  bool get isFamiliar => rightCount > leftCount && rightCount > 0;
  bool get isSeen => totalSwipes > 0;
  double get familiarityRatio =>
      totalSwipes == 0 ? 0.0 : rightCount / totalSwipes;
}
